# Helix cleanup candidates

Checked against [hm/helix.nix](../hm/helix.nix) on 2026-10-12.
These are deferred edits; the configuration has not been changed by this review.

## Useful ideas to consider before pruning

- The commented `nixd` option-completion setup chooses the first Darwin profile.
  If enabled, select the intended machine and platform explicitly. The active
  `nixd` configuration currently sets formatting only.
- SQL uses `sqls` with `sqruff fix` for formatting. A `sqruff` language-server
  declaration exists, but SQL's server list leaves it commented out. Enable it
  only if additional SQL diagnostics are wanted.
- GLSL uses `glsl_analyzer`; the diagnostics-only `shader-ls` companion is
  commented out. Establish a missing diagnostic before adding another server.
- Bash uses `bash-language-server` with no explicit formatter. The trailing
  archive contains a `shfmt` example; check actual formatting behavior and
  command availability before restoring it.

## Pruning candidates

- The commented archive after the closing Nix module repeats old keymaps,
  themes, language settings, package wrapping, and obsolete `ncfg` wiring.
  Preserve any selected ideas above, then remove the archive.
- Remove empty `extraPackages`, the placeholder language example, unused
  `extraConfig` alternative, commented duplicate `auto-format`, and abandoned
  `keys.picker` experiment.
- Remove unused formatter alternatives, theme shopping lists, alternate
  statuslines/whitespace glyphs, and commented opposite preference values
  unless they explain a current requirement.
- Keep comments that explain active behavior. Keep current keybindings when
  pruning old examples; suggestions from the archive may conflict with them.
