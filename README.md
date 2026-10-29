# Goose for Zed

Zed support for the [Goose language](https://github.com/aardappel/goose).

The Goose compiler is its own language server: `goose lsp` speaks the Language
Server Protocol on stdin and stdout. This extension gives Zed a Goose language
(treesitter grammar, highlighting, brackets, indentation, outline, snippets)
and starts that server for diagnostics, hover, go to definition, references,
rename, symbols, completion, signature help, inlay hints and folding.

## Features

- Syntax highlighting for `.goose` files, including nested `/* */` comments,
  escapes, multi-line `"""` raw strings, namespaces and builtins.
- Bracket matching, auto-closing, comment toggling (line and block),
  indentation, folding and document/workspace outline.
- Diagnostics as you type, hover, go to definition, find references, rename,
  document and workspace symbols, completion, signature help, inlay hints.
- Snippets: `main`, `fn`, `struct`, `enum`, `for`, `guard`, `match`, …
- Tasks: `goose run`, `goose check`, `goose build` (task runner), and a run
  button above `fn main`.
- The Goose LSP's semantic tokens, when enabled in Zed with
  `"semantic_tokens": "combined"`.

## Requirements

A Goose compiler that has `goose lsp` (run `goose lsp --help` to check). The
extension looks for it in this order:

1. `lsp.goose.binary.path` from Zed settings;
2. `goose` on `$PATH` (Zed uses your login shell's `PATH`);
3. the latest prebuilt release from
   [aardappel/goose releases](https://github.com/aardappel/goose/releases),
   downloaded and cached by Zed.

Prebuilt archives exist for macOS arm64/x86-64, Linux x86-64 and Windows
x86-64. On other platforms, install Goose yourself and put `goose` on `PATH`.

## Install as a dev extension

1. Install Rust with rustup if you have not already; Zed adds the
   `wasm32-wasip2` target when it builds the extension.
2. In Zed, open the command palette and run **zed: install dev extension**,
   then choose this `zed/` directory.
3. Open a `.goose` file. The language server starts automatically.

The first build also downloads wasi-sdk 34 (~180 MB) from GitHub to
`~/Library/Application Support/Zed/extensions/build/`, because that is what
compiles the C parser to WebAssembly. On a slow connection the build appears to
hang at `downloading wasi-sdk`. Either wait, or fetch
`wasi-sdk-34.0-arm64-macos.tar.gz` (adjust the platform) from the
[wasi-sdk releases](https://github.com/WebAssembly/wasi-sdk/releases/tag/wasi-sdk-34)
yourself, extract it so that `bin/clang` sits directly in
`extensions/build/wasi-sdk/`, then install the dev extension again.

The grammar in `tree-sitter-goose/` is checked in already generated
(`src/parser.c`), because Zed compiles the parser and does not run
`tree-sitter generate` itself. `extension.toml` points Zed at this directory
with a `file://` URL, since Zed only loads grammars from a git repository;
this directory is already one. If you move or copy it, update the
`repository` URL in `extension.toml` (or point it at a published grammar
repository) and install the dev extension again.

If you change `grammar.js`, regenerate the parser from `tree-sitter-goose/`:

```sh
npm install                 # installs the pinned tree-sitter CLI
npx tree-sitter generate    # writes src/parser.c and friends
npx tree-sitter test        # runs the corpus
```

Then install the dev extension again so Zed rebuilds the grammar, and update
`rev` in `extension.toml` if you are distributing the extension.

## Settings

Everything lives under `lsp.goose` in Zed's `settings.json`:

```jsonc
{
  "lsp": {
    "goose": {
      // Optional: a compiler outside $PATH.
      "binary": {
        "path": "/Users/me/goose-v2026.3-macos-arm64/goose",
        // Optional: defaults to ["lsp"]. Use e.g. ["lsp", "--stdlib", "/path/to/stdlib"].
        "arguments": ["lsp"],
        "env": { "GOOSE_STDLIB": "/path/to/goose/stdlib" }
      },
      // Optional: the programs to analyze. Each open file is analyzed as its
      // own program when this is absent, so imported modules only get their
      // own errors. With entry files, every file shows the program's errors.
      "initialization_options": {
        "entryFiles": ["/Users/me/project/main.goose"]
      }
    }
  },
  "languages": {
    "Goose": {
      "tab_size": 4
    }
  }
}
```

Note that `binary.arguments` *replaces* the default `["lsp"]`; keep `"lsp"`
as the first argument.

The tasks use `goose` from `$PATH`. If the compiler is not on `PATH`, edit
`languages/goose/tasks.json` (or define your own tasks) to use its full path.

## What Zed supports

| Feature | Zed | Notes |
|---|---|---|
| Diagnostics | yes | as you type, across the program's files |
| Hover / definition / references / rename | yes | |
| Document and workspace symbols | yes | |
| Completion and signature help | yes | |
| Inlay hints | yes | enable in Zed settings if off |
| Folding | yes | tree-sitter, plus the server's ranges |
| Semantic tokens | yes | `"semantic_tokens": "combined"` |
| Code lenses | partial | with `"code_lens": "on"`, the server's instantiation counts appear; its `Run` lens needs a client command that Zed extensions cannot register, so it is not offered |
| Debugging | no | Goose's server does not implement DAP |

## Publishing

This directory is laid out as a standalone extension repository, with the
grammar vendored in `tree-sitter-goose/`. To publish it:

1. Put this directory in its own Git repository (or keep it under the Goose
   repository, as the VS Code extension is) and push it.
2. Set `repository` in `extension.toml` to that URL, and `rev` to a commit SHA
   that contains the generated `src/parser.c`.
3. Open a PR against
   [zed-industries/extensions](https://github.com/zed-industries/extensions)
   adding a submodule for the repository.

The grammar is derived from `aardappel/goose`'s `tree-sitter/` directory and
is Apache-2.0, like Goose itself.
