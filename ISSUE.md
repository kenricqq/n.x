# Current unresolved issues

Verified 2026-05-09 against current tracked files and working tree. Resolved/stale findings removed.

## What repo is

Nix Darwin + Home Manager setup:

- host config in `flake.nix`
- Darwin system config in `darwin/`
- Home Manager modules in `home-manager/`
- encrypted secrets in `secrets/secrets.yaml`

`nix eval .#darwinConfigurations.Kenrics-MacBook-Air.system.drvPath --raw` resolves successfully. Only warning seen: uncommitted working-copy changes.

## 1. Secret environment generation still drifts

Evidence:

- `home-manager/zsh.nix` reads secret names from `secrets/secrets.list`.
- `home-manager/zsh.nix` decrypts values during activation into:
  - `~/.config/zsh/secrets/<NAME>`
  - `${XDG_CACHE_HOME}/zsh/secrets.env`
- `secrets/secrets.yaml` contains `FLAKEHUB_TOKEN`.
- `secrets/secrets.list` does not contain `FLAKEHUB_TOKEN`.

Diagnosis:

- secret names are declared twice and can silently diverge
- shell env misses secrets not listed in `secrets.list`
- decrypted secrets persist as plain files outside declarative `sops-nix` secret outputs

Improve:

- replace `secrets.list` flow with declarative `sops-nix` secrets
- declare each secret once
- avoid persistent ad-hoc plaintext secret copies where possible

## 2. Docs drift from code

Evidence:

- `README.md` says to change hostname and username in `flake.nix` only.
- hardcoded host/user/path values also exist in:
  - `darwin/configuration.nix`
  - `home-manager/paths.nix`
  - several files under `home-manager/dotfiles/`
- `backup-instr/setup.md` lists Nix, Lix, and Determinate installers while `darwin/configuration.nix` has `nix.enable = false`.
- `backup-instr/Workflow.md` is old tool notes, not current module/workflow docs.

Diagnosis:

- bootstrap path unclear
- source of truth for host/user/path values unclear
- new-machine migration needs edits not documented by README

Improve:

- document one supported bootstrap path
- document all host-specific values
- add active module map and archived/legacy module notes
- document secret bootstrap flow

## 3. Hardcoded machine state limits portability

Evidence:

- `flake.nix` hardcodes `Kenrics-MacBook-Air`.
- `flake.nix` hardcodes `users.kenrictee.imports` and `primaryUser = "kenrictee"`.
- `darwin/configuration.nix` hardcodes `users.users.kenrictee.home = "/Users/kenrictee"`.
- `home-manager/paths.nix` hardcodes:
  - `home = "/Users/kenrictee"`
  - `nixrt = "${home}/KTQQ/m0nix"`
- multiple dotfiles contain `/Users/kenrictee/...` paths.

Diagnosis:

- hostname rename, username change, or repo move requires scattered edits
- README currently underreports migration work

Improve:

- centralize `username`, `hostname`, `homeDirectory`, and repo root
- pass shared values through `specialArgs` / Home Manager args
- replace literal paths where practical

## 4. Dead modules still in tree

Evidence:

- `darwin/services/default.nix` exists and imports `./sketchybar`.
- `darwin/configuration.nix` imports only `./homebrew.nix` and `./fonts.nix`.
- no active import of `darwin/services/default.nix` found.
- `home-manager/ssh.nix` exists but is not listed in the Home Manager import list in `flake.nix`.

Diagnosis:

- some config files look active but do not apply
- SSH/service behavior may be assumed managed when it is not

Improve:

- import active modules or archive/delete inactive ones
- document active vs archived modules

## 5. Runtime or mutable state remains tracked

Evidence from `jj file list`:

- `memos_dev.db`
- `home-manager/dotfiles/codex/config.toml`
- `home-manager/dotfiles/pi/agent/settings.json`

Current working copy also has local edits to mutable dotfiles, including `home-manager/dotfiles/pi/agent/settings.json`.

Diagnosis:

- repo mixes declarative config with local app/runtime state
- working tree can become dirty from normal app usage

Improve:

- move runtime DB/state to XDG state/cache locations
- untrack local-only app state
- keep repo for declarative source and stable dotfiles only

## 6. Validation/checking still weak

Evidence:

- `flake.nix` exports `darwinConfigurations` but no `checks` attr.
- `justfile` only defines:
  - `setup`
  - `update_bun`
- no repo-level `just check`, `just build`, `just fmt`, or `just switch` task exists.

Improve:

- add flake checks for formatting/eval where practical
- add `just` tasks for `fmt`, `check`, `build`, `switch`, and `update`
- consider `deadnix`, `statix`, and `nixfmt` checks

## 7. PostgreSQL logging defaults are noisy

Evidence in `darwin/configuration.nix`:

- `log_statement = "all"`
- `log_connections = true`
- `log_disconnections = true`
- `logging_collector = true`

Diagnosis:

- useful for debugging
- noisy and potentially privacy-sensitive as a default workstation config

Improve:

- gate verbose logging behind a debug flag
- default to quieter PostgreSQL logging

## Priority order

1. Replace `secrets.list` flow with declarative `sops-nix` secrets.
2. Remove or relocate tracked runtime/mutable state.
3. Import or archive inactive modules.
4. Centralize host/user/path values.
5. Rewrite setup docs around the actual bootstrap and module map.
6. Add flake checks and useful `just` tasks.
7. Gate noisy PostgreSQL logging behind debug config.
