# standalone home-manager, no os rebuild
# nixos or nix-darwin use mksystem.nix

{
  inputs,
  nixpkgs,
  overlays,
  ...
}:

machine:

let
  inherit (machine) name;

  pkgs = import nixpkgs {
    inherit (machine) system;
  };

  host = import ./host.nix {
    inherit (nixpkgs) lib;
    inherit machine;
  };
in

inputs.home-manager.lib.homeManagerConfiguration {
  inherit pkgs;

  extraSpecialArgs = {
    inherit inputs host machine;
  };

  modules = [
    { nixpkgs.overlays = overlays; }

    { nixpkgs.config.allowUnfree = true; }

    ../machines/${name}/home.nix
  ];
}
