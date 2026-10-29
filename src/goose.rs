//! Zed language extension for Goose (<https://github.com/aardappel/goose>).
//!
//! The Goose compiler is its own language server: `goose lsp` speaks the
//! Language Server Protocol on stdin/stdout. This adapter finds the compiler,
//! starts it with `lsp`, and forwards the user's `lsp.goose` settings.

use std::fs;

use zed_extension_api::{
    self as zed, serde_json, settings::LspSettings, LanguageServerId,
    LanguageServerInstallationStatus, Result, Worktree,
};

const LANGUAGE_SERVER_ID: &str = "goose";
const GOOSE_REPOSITORY: &str = "aardappel/goose";

struct GooseExtension {
    cached_binary_path: Option<String>,
}

struct GooseBinary {
    path: String,
    args: Vec<String>,
    env: Vec<(String, String)>,
}

impl GooseExtension {
    /// The compiler to start, the arguments to pass it, and the environment.
    ///
    /// The order is: the user's `lsp.goose.binary.path`, then `goose` on
    /// `$PATH`, then a prebuilt release downloaded from GitHub. Any of those
    /// can be overridden with `lsp.goose.binary.{path,arguments,env}` in Zed's
    /// settings.
    fn binary(
        &mut self,
        language_server_id: &LanguageServerId,
        worktree: &Worktree,
    ) -> Result<GooseBinary> {
        let mut arguments = None;
        let mut env_overrides = None;

        if let Ok(settings) = LspSettings::for_worktree(LANGUAGE_SERVER_ID, worktree) {
            if let Some(binary) = settings.binary {
                arguments = binary.arguments;
                env_overrides = binary.env;
                if let Some(path) = binary.path {
                    return Ok(GooseBinary {
                        path,
                        args: arguments.unwrap_or_else(default_arguments),
                        env: base_environment(worktree, env_overrides),
                    });
                }
            }
        }

        let path = if let Some(path) = worktree.which("goose") {
            path
        } else if let Some(path) = self
            .cached_binary_path
            .as_ref()
            .filter(|path| fs::metadata(path).is_ok_and(|metadata| metadata.is_file()))
        {
            path.clone()
        } else {
            self.download_binary(language_server_id)?
        };

        Ok(GooseBinary {
            path,
            args: arguments.unwrap_or_else(default_arguments),
            env: base_environment(worktree, env_overrides),
        })
    }

    /// Downloads the prebuilt compiler for this platform from the latest
    /// Goose release, and returns the path to the executable.
    fn download_binary(&mut self, language_server_id: &LanguageServerId) -> Result<String> {
        let (platform, arch) = zed::current_platform();

        let target = match (platform, arch) {
            (zed::Os::Mac, zed::Architecture::Aarch64) => "macos-arm64",
            (zed::Os::Mac, zed::Architecture::X8664) => "macos-x64",
            (zed::Os::Linux, zed::Architecture::X8664) => "linux-x64",
            (zed::Os::Windows, zed::Architecture::X8664) => "windows-x64",
            _ => {
                return Err(
                    "There is no prebuilt Goose compiler for this platform. Install Goose and \
                     put `goose` on your PATH, or set `lsp.goose.binary.path` in Zed's settings."
                        .to_string(),
                );
            }
        };

        let executable = if matches!(platform, zed::Os::Windows) {
            "goose.exe"
        } else {
            "goose"
        };
        let archive_type = if matches!(platform, zed::Os::Windows) {
            zed::DownloadedFileType::Zip
        } else {
            zed::DownloadedFileType::GzipTar
        };
        let extension = if matches!(platform, zed::Os::Windows) {
            "zip"
        } else {
            "tar.gz"
        };

        zed::set_language_server_installation_status(
            language_server_id,
            &LanguageServerInstallationStatus::CheckingForUpdate,
        );

        let release = zed::latest_github_release(
            GOOSE_REPOSITORY,
            zed::GithubReleaseOptions {
                require_assets: true,
                pre_release: false,
            },
        )?;

        let asset_name = format!("goose-{}-{}.{}", release.version, target, extension);
        let asset = release
            .assets
            .iter()
            .find(|asset| asset.name == asset_name)
            .ok_or_else(|| {
                format!(
                    "The latest Goose release ({}) has no asset named {asset_name}. Install Goose \
                     and put `goose` on your PATH, or set `lsp.goose.binary.path` in Zed's settings.",
                    release.version
                )
            })?;

        let version_dir = format!("goose-{}", release.version);
        let binary_path = format!("{version_dir}/{executable}");

        if !fs::metadata(&binary_path).is_ok_and(|metadata| metadata.is_file()) {
            zed::set_language_server_installation_status(
                language_server_id,
                &LanguageServerInstallationStatus::Downloading,
            );

            zed::download_file(&asset.download_url, &version_dir, archive_type)
                .map_err(|error| format!("failed to download {asset_name}: {error}"))?;

            // The release archives contain a top-level directory, so the
            // executable is not at `version_dir` itself. Move it there, so the
            // next startup finds it without unpacking or searching again.
            let extracted = find_file(&version_dir, executable).ok_or_else(|| {
                format!("{asset_name} was downloaded, but it contains no {executable}")
            })?;
            if extracted != binary_path {
                fs::rename(&extracted, &binary_path).map_err(|error| {
                    format!("failed to move {extracted} to {binary_path}: {error}")
                })?;
            }
            zed::make_file_executable(&binary_path)?;
        }

        self.cached_binary_path = Some(binary_path.clone());
        Ok(binary_path)
    }
}

impl zed::Extension for GooseExtension {
    fn new() -> Self {
        Self {
            cached_binary_path: None,
        }
    }

    fn language_server_command(
        &mut self,
        language_server_id: &LanguageServerId,
        worktree: &Worktree,
    ) -> Result<zed::Command> {
        let binary = self.binary(language_server_id, worktree)?;
        Ok(zed::Command {
            command: binary.path,
            args: binary.args,
            env: binary.env,
        })
    }

    /// `entryFiles` (absolute paths) tells the server which programs to analyze,
    /// so imported modules get the errors of the program that imports them. The
    /// user sets it in `lsp.goose.initialization_options`; with none, the server
    /// analyzes each open file as a program of its own.
    fn language_server_initialization_options(
        &mut self,
        _language_server_id: &LanguageServerId,
        worktree: &Worktree,
    ) -> Result<Option<serde_json::Value>> {
        let options = LspSettings::for_worktree(LANGUAGE_SERVER_ID, worktree)
            .ok()
            .and_then(|settings| settings.initialization_options)
            .unwrap_or_else(|| serde_json::json!({}));
        Ok(Some(options))
    }
}

fn default_arguments() -> Vec<String> {
    vec!["lsp".to_string()]
}

/// The shell environment (so `GOOSE_HOME`, `GOOSE_STDLIB` and `PATH` from the
/// user's shell reach the server), with the user's own `binary.env` on top.
fn base_environment(
    worktree: &Worktree,
    overrides: Option<std::collections::HashMap<String, String>>,
) -> Vec<(String, String)> {
    let mut env = match zed::current_platform().0 {
        zed::Os::Mac | zed::Os::Linux => worktree.shell_env(),
        zed::Os::Windows => Vec::new(),
    };

    if let Some(overrides) = overrides {
        for (key, value) in overrides {
            if let Some(entry) = env.iter_mut().find(|(name, _)| name == &key) {
                entry.1 = value;
            } else {
                env.push((key, value));
            }
        }
    }

    env
}

/// Searches `directory` and its subdirectories for a file with `name`.
fn find_file(directory: &str, name: &str) -> Option<String> {
    let mut pending = vec![directory.to_string()];

    while let Some(directory) = pending.pop() {
        if let Ok(entries) = fs::read_dir(&directory) {
            for entry in entries.flatten() {
                let path = entry.path();
                if path.is_dir() {
                    pending.push(path.to_string_lossy().into_owned());
                } else if path.file_name().and_then(|file_name| file_name.to_str()) == Some(name) {
                    return Some(path.to_string_lossy().into_owned());
                }
            }
        }
    }

    None
}

zed::register_extension!(GooseExtension);
