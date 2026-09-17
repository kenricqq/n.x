# m0nix | meridian | laurentii

Shared configuration for NixOS, standalone Home Manager on Linux, and
nix-darwin on macOS. All three targets are supported.

## setup

- to use lefthook for checking leaked secrets, make sure to `lefthook install`
- change hostname and username in `flake.nix`

### profiles

| Target | Flake output | Machine configuration |
| --- | --- | --- |
| nix-darwin + Home Manager | `darwinConfigurations.m0nix` | `machines/m0nix/{darwin,home}.nix` for `kenrictee` |
| Standalone Home Manager on Linux (CachyOS) | `homeConfigurations.meridian` | `machines/meridian/home.nix` for `kenrict` |
| NixOS + Home Manager | `nixosConfigurations.laurentii` | `machines/laurentii/{nixos,home,hardware}.nix` for `kenrict` |

`lib/mksystem.nix` selects the NixOS or nix-darwin system builder and its matching
Home Manager integration. `lib/mkhome.nix` builds the standalone Home Manager
profile. Shared user configuration lives in `hm/`; platform-specific system
options and machine overrides stay in their respective modules.

Every profile defaults to a checkout at `~/<machine-name>`. The optional `repo`
field in `flake.nix` sets a different home-relative checkout path for both system
and Home Manager modules. Laurentii uses `~/laurentii`; m0nix and Meridian
keep `~/m0nix` and `~/meridian`.

### profile commands

| Target | `home-profile activate` (`hms`) | `home-profile switch` (`ndr`, `dhm`) |
| --- | --- | --- |
| nix-darwin | Activate only its integrated Home Manager profile | Switch the full nix-darwin system |
| Standalone Home Manager | Activate its Home Manager profile | Switch its Home Manager profile with `nh home` |
| NixOS | Switch the full NixOS system | Switch the full NixOS system |

NixOS installs Home Manager's user packages through its system generation, so
both commands switch that generation to keep packages and configuration together.
The standalone Home Manager and nix-darwin activation paths remain available.
`home-profile update` updates flake inputs and switches the selected target;
Homebrew and Determinate Nix updates run only for nix-darwin profiles.

### Arch / CachyOS Nix caches

`arch-install` writes `os/shared/nix-caches.nix` to
`/etc/nix/shared-caches.conf`, includes it once from the existing `nix.conf`, and
restarts the running Nix daemon. After changing the cache list, apply Home
Manager and rerun `arch-install` to refresh it.

### build from existing flake.nix

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

## home-manager

- symlink setup, centralized dotfiles, no rebuild needed
- module variable
