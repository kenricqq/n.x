# m0nix | meridian | laurentii

Shared configuration for NixOS, standalone Home Manager on Linux, and
nix-darwin on macOS. All three targets are supported.

## Repository layout

```text
.
├── flake.nix       # Inputs, machine definitions, and outputs
├── flake.lock      # Pinned dependency revisions
├── machines/       # Per-machine Home Manager, OS, and hardware settings
├── lib/            # Profile builders, platform flags, and peer helpers
├── hm/             # Shared Home Manager config and Linux/macOS modules
├── os/             # NixOS and nix-darwin system modules
├── dots/           # Application config sources, often linked live
├── secrets/        # Encrypted secrets; private keys stay untracked
├── scripts/        # User command sources and maintenance scripts
├── tests/          # Regression checks
├── qmk/            # Keyboard keymaps and firmware tooling
├── extensions/     # Browser extensions and related tools
├── prompts/        # Reusable prompts
├── docs/           # Topic guides, research, and deferred work
└── justfile        # Repository setup and check commands
```

A **machine** is a named computer profile with a platform and primary user.
`host` refers to the capability flags from [`lib/host.nix`](lib/host.nix):
`isDarwin`, `isLinux` (standalone Linux), and `isNixos`.
**Machine paths** come from [`hm/paths.nix`](hm/paths.nix), shared with system
modules; they apply to every platform.

Only modules reached through imports are active. A file's presence in the tree
does not mean it is enabled. Live dotfile edits can take effect immediately;
Nix-generated files and package changes require profile activation.

## Setup

Machine names, users, platforms, peers, and optional checkout paths are declared
in [`flake.nix`](flake.nix). For a new machine, also review its modules under
`machines/`, hardware settings, and private-key provisioning in
[`hm/security.nix`](hm/security.nix).

### Profiles

| Target                                     | Flake output                    | Machine configuration                                        |
| ------------------------------------------ | ------------------------------- | ------------------------------------------------------------ |
| nix-darwin + Home Manager                  | `darwinConfigurations.m0nix`    | `machines/m0nix/{darwin,home}.nix` for `kenrictee`           |
| Standalone Home Manager on Linux (CachyOS) | `homeConfigurations.meridian`   | `machines/meridian/home.nix` for `kenrict`                   |
| NixOS + Home Manager                       | `nixosConfigurations.laurentii` | `machines/laurentii/{nixos,home,hardware}.nix` for `kenrict` |

`lib/mksystem.nix` selects the NixOS or nix-darwin system builder and its matching
Home Manager integration. `lib/mkhome.nix` builds the standalone Home Manager
profile. Shared user configuration lives in `hm/`; platform-specific system
options and machine overrides stay in their respective modules.

Every profile defaults to a checkout at `~/<machine-name>`. The optional `repo`
field in `flake.nix` sets a different home-relative checkout path for both system
and Home Manager modules. Laurentii uses `~/laurentii`; m0nix and Meridian
keep `~/m0nix` and `~/meridian`.

### Profile commands

| Target                  | `home-profile activate` (`hms`)                   | `home-profile switch` (`ndr`, `dhm`)           |
| ----------------------- | ------------------------------------------------- | ---------------------------------------------- |
| nix-darwin              | Activate only its integrated Home Manager profile | Switch the full nix-darwin system              |
| Standalone Home Manager | Activate its Home Manager profile                 | Switch its Home Manager profile with `nh home` |
| NixOS                   | Switch the full NixOS system                      | Switch the full NixOS system                   |

NixOS installs Home Manager's user packages through its system generation, so
both commands switch that generation to keep packages and configuration together.
The standalone Home Manager and nix-darwin activation paths remain available.
`home-profile update` updates flake inputs and switches the selected target;
Homebrew and Determinate Nix updates run only for nix-darwin profiles.

### Arch / CachyOS Nix caches

`arch-install` writes `machines/nix-caches.nix` to
`/etc/nix/shared-caches.conf`, includes it once from the existing `nix.conf`, and
restarts the running Nix daemon. After changing the cache list, apply Home
Manager and rerun `arch-install` to refresh it.

### Build from existing flake.nix

Run the commands for the intended target from its checkout:

```sh
# nix-darwin system and Home Manager
nix --extra-experimental-features "nix-command flakes" build .#darwinConfigurations.m0nix.system
./result/sw/bin/darwin-rebuild switch --flake .#m0nix

# Standalone Linux Home Manager
nix build '.#homeConfigurations.meridian.activationPackage'
./result/activate

# NixOS system and Home Manager (also available through Laurentii's run alias)
sudo nixos-rebuild switch --flake .#laurentii
```

## Checks and secrets

[`justfile`](justfile) exposes `just check-paths` for installed service paths and
`just test` for Bun tests with Nix builds and import-from-derivation disabled.
Tests can be narrowed, for example `just test tests/machine-paths.test.ts`.
These checks do not establish that a configuration has been activated.

[`hm/security.nix`](hm/security.nix) declares sops-nix secrets.
`.sops.yaml` contains public recipients and creation rules; private age
identities and decrypted values stay untracked. The private identity path is
`secrets/keys.txt` under the configured checkout.

`just setup` only runs `lefthook install`. [`lefthook.yml`](lefthook.yml)
currently contains commented examples, so installation alone provides no secret
check. JJ pushes bypass Git hooks. Before publishing, inspect the selected
revision's ancestry as well as its current files; deleting or ignoring a file
does not remove historical copies.

## Documentation

- [macOS preferences and retained nix-darwin settings](docs/nix-plist-manager.md)
- [Helix cleanup candidates](docs/helix-cleanup.md)
- [Service follow-ups](docs/service-cleanup-plan.md) (dated findings; recheck runtime)
- [User command sources and usage](scripts/README.md)
- [Contributor instructions](AGENTS.md) and [known mistakes](MISTAKES.md)
