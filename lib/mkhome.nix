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

  _platform = pkgs.stdenv.hostPlatform;

  host = {
    isDarwin = _platform.isDarwin;
    isLinux = _platform.isLinux && !(machine.nixos or false);
    isNixos = machine.nixos or false;
    isWsl = machine.wsl or false;
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
