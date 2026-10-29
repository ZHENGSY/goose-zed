# tree-sitter-goose

The tree-sitter grammar for [Goose](https://github.com/aardappel/goose), taken
from that repository's `tree-sitter/` directory (Apache-2.0) and vendored here
with the generated parser checked in, because Zed compiles `src/parser.c` and
does not run `tree-sitter generate` itself.

| Path | |
|---|---|
| `grammar.js` | The grammar. |
| `src/scanner.c` | Hand-written external scanner for nesting `/* */` comments. |
| `src/parser.c` | Generated from `grammar.js` (checked in for Zed). |
| `queries/highlights.scm` | The grammar's own nvim-style highlight query; the Zed extension uses `../../languages/goose/highlights.scm` instead. |
| `test/corpus/` | `tree-sitter test` cases. |

To change the grammar:

```sh
npm install                 # the tree-sitter CLI version pinned in package.json
npx tree-sitter generate
npx tree-sitter test
```

Then reinstall the Zed dev extension so it rebuilds the grammar, and update
`rev` in `../extension.toml` to a commit that contains the new parser.
