# Goose for Zed

Zed support for the [Goose language](https://github.com/aardappel/goose).

The Goose compiler is its own language server: `goose lsp` speaks the Language
Server Protocol on stdin and stdout. This extension gives Zed a Goose language
(treesitter grammar, highlighting, brackets, indentation, outline, snippets)
and starts that server for diagnostics, hover, go to definition, references,
rename, symbols, completion, signature help, inlay hints, folding and
formatting. The grammar is the one upstream ships in `tree-sitter/`, pinned by
`rev`: `defer`, `root` structs, `const if`, variant constants, numeric
separators and `extern "lib" { … }` blocks bound from a shared library all
parse and highlight.

## Features

- Syntax highlighting for `.goose` files, including nested `/* */` comments,
  escapes, multi-line `"""` raw strings, namespaces and builtins.
- Bracket matching, auto-closing, comment toggling (line and block),
  indentation, folding and document/workspace outline.
- Diagnostics as you type, hover, go to definition, find references, rename,
  document and workspace symbols, completion, signature help, inlay hints.
- Formatting through the server, with `goose format`'s semantics.
- Snippets: `main`, `fn`, `struct`, `enum`, `for`, `match`, `guard`,
  `loop`, `let`, `const`, `defer`, `extern "lib"` blocks, the full array
  family (`T[k]`, `T[]`, `T[..]`, `T[..k]`, `T[>..]` grow-only, `T[>..<]`
  grow-shrink, `reusable` — deprecated in v2026.4), and the v2026.4
  `slot_pool`/`slice_pool` replacements.
- Tasks: `goose run`, `goose check`, `goose build` (task runner), and a run
  button above `fn main`.
- The Goose LSP's semantic tokens, when enabled in Zed with
  `"semantic_tokens": "combined"`.

## Requirements

A Goose compiler that has `goose lsp` (run `goose lsp --help` to check) —
v2026.4 or newer for the grammar and the formatting this extension ships with.
The extension looks for it in this order:

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

### Troubleshooting: "already exists, but is not a git clone of ..."

Zed caches each grammar as a git clone under `grammars/goose/` inside the
extension directory, and only reuses that clone when its `origin` matches the
`repository` URL in `extension.toml`. Version 0.2.1 moved the grammar from
this repository to upstream's, now that upstream checks in the generated
parser, so the stale clone fails the check and installation aborts with:

```text
Failed to install dev extension: compiling grammar 'goose'
    grammar directory ".../zed/grammars/goose" already exists,
    but is not a git clone of 'https://github.com/aardappel/goose'
```

The clone is a disposable build artifact: delete `grammars/goose/` and install
the dev extension again, and Zed will clone the repository fresh.

### Grammar and queries

Zed compiles a grammar from a git checkout; it does not run `tree-sitter
generate`. Since [aardappel/goose#320](https://github.com/aardappel/goose/pull/320),
upstream checks in the generated `tree-sitter/src/parser.c` and
`tree-sitter/src/tree_sitter/parser.h`, so `extension.toml` points straight at
upstream:

```toml
[grammars.goose]
repository = "https://github.com/aardappel/goose"
rev = "9412b80f52d833c4697cffdbbf1f4eeb5195cd41"
path = "tree-sitter"
```

To follow a newer grammar, set `rev` to a commit on upstream `master` whose
`tree-sitter/src/parser.c` is current with `grammar.js` (upstream's
`python tree-sitter/build.py` regenerates and checks it). Nothing is vendored
in this repository any more, so there is no parser to regenerate here.

Zed does not read the query files that live next to a grammar; it looks in
`languages/goose/`. `languages/goose/highlights.scm` is therefore a manual copy
of upstream's `tree-sitter/queries/highlights.scm`, adapted to Zed's capture
names (`@module` → `@namespace`, `@variable.builtin` → `@variable.special`,
`@character` → `@string`, `@escape` → `@string.escape`; the file's header lists
them all, and the builtins-in-call-position rule is added here). When you bump
`rev`, copy that revision's `highlights.scm` over and reapply the adaptations.
The other queries — `brackets`, `indents`, `outline`, `overrides`, `runnables`,
`textobjects` — are Zed-specific and have no upstream counterpart; upstream's
`queries/helix/` and `queries/tags.scm` are for Helix and are not used here.

## Settings

Everything lives under `lsp.goose` in Zed's `settings.json`:

```jsonc
{
  "lsp": {
    "goose": {
      // Optional: a compiler outside $PATH.
      "binary": {
        "path": "/Users/me/goose-v2026.4-macos-arm64/goose",
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
| Formatting | yes | the server formats as `goose format` does |
| Semantic tokens | yes | `"semantic_tokens": "combined"` |
| Code lenses | partial | with `"code_lens": "on"`, the server's instantiation counts appear; its `Run` lens needs a client command that Zed extensions cannot register, so it is not offered |
| Debugging | no | Goose's server does not implement DAP |

## Publishing

This directory is laid out as a standalone extension repository at
[github.com/ZHENGSY/goose-zed](https://github.com/ZHENGSY/goose-zed).
`extension.toml` points its own `repository` at that URL and its grammar at
upstream's `tree-sitter/` directory, with `rev` set to a commit that contains
the generated `src/parser.c`.

To publish to the Zed extension registry, open a PR against
[zed-industries/extensions](https://github.com/zed-industries/extensions)
adding this repository as a submodule under `extensions/goose`:

```sh
git submodule add https://github.com/ZHENGSY/goose-zed extensions/goose
```

and add a matching entry to that repo's top-level `extensions.toml`. After a
grammar change, bump the grammar's `rev` and sync `languages/goose/highlights.scm`
from the same upstream revision before submitting.

The grammar belongs to `aardappel/goose` and is Apache-2.0, like Goose itself;
this extension only ships the Zed-specific queries and configuration.
