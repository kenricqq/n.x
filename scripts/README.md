# User commands

This directory contains readable command sources. Home Manager packages shared
commands in `hm/shell-commands.nix` and platform-specific commands in their owning
feature modules. `writeShellApplication` supplies the interpreter and runtime
dependencies and runs ShellCheck during the build.

## Commands

- `hx-history` owns Helix's XDG-backed recent-file history. The public entry
  points are `hx-open`, `hx-last`, and `hx-recent`; interactive shells shorten
  those to `hx`, `hxl`, and `hxr`.
- `jjw` manages Jujutsu workspaces. Its filesystem and Jujutsu behavior is
  shared; Nushell and Zsh only wrap the `cd` and `new` cases because a child
  process cannot change its parent shell's directory.
- `yt-music` and `yt-video` are portable `yt-dlp` frontends. `ytm` and `ytv` are
  optional interactive aliases.
- `toggle-sketchybar-gap` is a Darwin-only command packaged by
  `hm/macos/aerospace.nix` from `toggle-sketchybar-gap.sh`, with Python and the
  configured SketchyBar package as runtime dependencies.

## AeroSpace gap toggle

The command supports no arguments or `--toggle` to toggle the gap, and `--sync`
to apply bar visibility from the configured gap without toggling. It reads
`AEROSPACE_CONFIG`, defaulting to `$HOME/.config/aerospace/aerospace.toml`.

The writable configuration is the source of truth: gap `0` hides the bar, and
`30` shows it. The gap is written before the best-effort SketchyBar call; a bar
failure does not undo the requested gap. Keep the configuration live and
writable rather than replacing it with an immutable Nix-store file. The
command itself does not reload AeroSpace.

### Activate before changing the live binding

The current binding deliberately keeps invoking the source script until the
packaged command is installed. Editing a live dotfile and activating a Nix
package are separate operations:

1. Build/activate the Home Manager generation containing the command, leaving
   the existing binding unchanged.
2. Check command resolution with AeroSpace's execution PATH, not a login shell:

   ```sh
   app_path="$(aerospace list-exec-env-vars | sed -n 's/^PATH=//p')"
   /usr/bin/env PATH="$app_path" /bin/sh -c \
     'command -v toggle-sketchybar-gap && command -v aerospace'
   ```

3. Only after that succeeds, change the live binding to:

   ```toml
   alt-ctrl-shift-b = 'exec-and-forget toggle-sketchybar-gap && aerospace reload-config'
   ```

4. Reload when ready and verify two toggles return the gap/bar to their starting
   state. Do not remove `SCRIPTS`: other bindings still depend on it.

For rollback, restore the direct-script binding before rolling back/removing
its packaged replacement. A generation rollback does not restore live TOML
edits. Keep the source script available during this transition.

### Tests

Run `bun test tests/aerospace-toggle.test.ts` from the repository root. It
requires Bun, Nix with the locked inputs available, Python 3, and `/bin/bash`.
Tests evaluate Darwin/Linux command registration and run the real source
script with temporary HOME/configuration and fake SketchyBar. They do not
reload AeroSpace or change the real bar. The write-permission test is skipped
when running as root, which bypasses ordinary Unix write permissions.

These fixtures exercise source behavior, not a built Nix wrapper. Package-level
fixtures must substitute the SketchyBar dependency when constructing the
package: `writeShellApplication` prepends its runtime inputs, so a caller's
PATH stub alone does not reliably intercept the packaged command.

## Conventions

- Use kebab-case for executable names and keep machine names out of them.
- Put argument parsing, pipelines, and persistent state here.
- Declare every non-shell dependency in the command's `runtimeInputs`.
- Keep aliases declarative in `hm/alias.nix` and limited to short, simple
  expansions.
- Keep parent-shell mutations in small native functions in `hm/nushell.nix` or
  `hm/zsh.nix`.
- Put platform-only commands behind Nix platform conditions instead of runtime
  machine-name checks.
