# nixos or nix-darwin with home-manager
# standalone hm use mkhome.nix

{
  nixpkgs,
  overlays,
  inputs,

  ...
}:

machine:

let
  inherit (machine)
    name
    system
    user
    ;

  host = import ./host.nix {
    inherit (nixpkgs) lib;
    inherit machine;
  };

  # The config files for this system.
  machineHMConfig = ../machines/${name}/home.nix;
  machineOSConfig = ../machines/${name}/${if host.isDarwin then "darwin" else "nixos"}.nix;
  # userOSConfig = ../users/${user}/${if host.isDarwin then "darwin" else "nixos"}.nix;
  # userHMConfig = ../users/${user}/home-manager.nix;

  systemFunc = if host.isDarwin then inputs.darwin.lib.darwinSystem else nixpkgs.lib.nixosSystem;
  home-manager =
    if host.isDarwin then inputs.home-manager.darwinModules else inputs.home-manager.nixosModules;

  inherit (nixpkgs.lib) optionals;
in
systemFunc rec {
  inherit system;

  # Inputs must be available while resolving machine module imports.
  specialArgs = { inherit inputs; };

  modules = [
    # Apply our overlays. Overlays are keyed by system type so we have
    # to go through and apply our system type. We do this first so
    # the overlays are available globally.
    { nixpkgs.overlays = overlays; }

    # Allow unfree packages.
    { nixpkgs.config.allowUnfree = true; }
  ]
  ++ optionals host.isWsl [
    inputs.nixos-wsl.nixosModules.wsl
  ]
  ++ optionals host.isLinux [
    # inputs.nix-snapd.nixosModules.default
  ]
  ++ [
    machineOSConfig
    home-manager.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.extraSpecialArgs = {
        inherit inputs machine host;
      };
      home-manager.users.${user}.imports = [ machineHMConfig ];
      home-manager.backupFileExtension = "backup";
    }

    # We expose some extra arguments so that our modules can parameterize
    # better based on these values.
    {
      config._module.args = {
        inherit machine host;

        currentSystem = system;
        currentSystemName = name;
        currentSystemUser = user;
        isWSL = host.isWsl;
      };
    }
  ]
  ++ optionals host.isDarwin [
    {
      security.pam.services.sudo_local.touchIdAuth = true;
      system = {
        primaryUser = user;
        stateVersion = 6;
      };
    }
  ];
}
