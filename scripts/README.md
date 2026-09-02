# User commands

This directory contains the readable source for commands packaged by
`hm/shell-commands.nix`. Home Manager turns each command body into an executable
with `writeShellApplication`, runs ShellCheck during the build, and supplies its
runtime dependencies.

## Commands

- `hx-history` owns Helix's XDG-backed recent-file history. The public entry
  points are `hx-open`, `hx-last`, and `hx-recent`; interactive shells shorten
  those to `hx`, `hxl`, and `hxr`.
- `jjw` manages Jujutsu workspaces. Its filesystem and Jujutsu behavior is
  shared; Nushell and Zsh only wrap the `cd` and `new` cases because a child
  process cannot change its parent shell's directory.
- `yt-music` and `yt-video` are portable `yt-dlp` frontends. `ytm` and `ytv` are
  optional interactive aliases.

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
