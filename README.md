# m0nix

Nix setup w/ Darwin + Home Manager

## setup

- to use lefthook for checking leaked secrets, make sure to `lefthook install`
- change hostname and username in `flake.nix`

### profiles

- `Kenrics-MacBook-Air`: full desktop Darwin profile for `kenrictee`.
- `davinci@m0nix-server`: lightweight Home Manager profile for a Linux x86 compute node.

### build from existing flake.nix

nix --extra-experimental-features "nix-command flakes" build .#darwinConfigurations.$(hostname -s).system
./result/sw/bin/darwin-rebuild switch --flake .#$(hostname -s)

# explicit Linux compute Home Manager profile
nix build '.#homeConfigurations."davinci@m0nix-server".activationPackage'
./result/activate

## home-manager

- symlink setup, centralized dotfiles, no rebuild needed
- module variable
