# Helix cleanup

Review of `hm/helix.nix`, 2026-09-27. Line numbers refer to this snapshot. Recommendations only; config unchanged.

**Worth salvaging**

| Lines | Idea | Recommendation |
| --- | --- | --- |
| 550–571 | `nixd` option completion | Strongest keep. Target intended profile instead of selecting first Darwin configuration. [Docs](https://github.com/nix-community/nixd/blob/main/nixd/docs/configuration.md#options-options). |
| 121 | `sqruff` LSP | Consider SQL lint feedback alongside `sqls`; current formatter only runs `sqruff fix`. [Docs](https://github.com/quarylabs/sqruff#editor-integrations). |
| 58–61 | Shader diagnostics companion | Keep if current GLSL setup misses compiler errors. Package declaration also disabled. |
| 1671–1675 | `shfmt` | Consider if shell formatting missing. Absent from reviewed shell PATH; Bash LSP already supports it, so explicit formatter may be unnecessary. [Docs](https://github.com/bash-lsp/bash-language-server#shfmt-integration). |

**Delete**

- **1244–1918:** 675-line archive after salvaging useful ideas above. Copied Vim emulation, duplicate bindings, old theme, package wrapper, obsolete `ncfg` wiring.
- **27–41:** Empty `extraPackages`, placeholder language example, unused config-file alternative.
- **195:** Duplicate `auto-format`.
- **279–282:** Svelte comment tokens already match [pinned Helix defaults](https://github.com/helix-editor/helix/blob/079a789e8cb08ead67f19e1971a1b7438b37354b/languages.toml#L1568).
- **1012–1015:** Unsupported `keys.picker`; [remapping supports normal, insert, select](https://docs.helix-editor.com/remapping.html).
- Theme shopping lists, alternate statuslines/whitespace glyphs, opposite inlay-hint setting. Current preferences and toggles already cover these.

**Keep only for a concrete need**

- **98–110, 142–148, 291–299:** Old SQL/Taplo/Prettier formatters only for known formatting problems. [Oxfmt supports TOML and Svelte](https://oxc.rs/docs/guide/usage/formatter/language-support); Svelte requires its package and option enabled.
- **256–269:** Markdown roots/server alternatives only for a missing workflow.
- **1256–1260:** Syntax-selection commands useful, custom bindings unnecessary. [Defaults already provide them](https://docs.helix-editor.com/master/keymap.html); proposed `C-j`/`C-k` conflict with current line movement.

Keep explanatory comments that document intent or non-obvious behavior.
