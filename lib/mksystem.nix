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

  _platform = nixpkgs.lib.systems.elaborate system;

  host = {
    isDarwin = _platform.isDarwin;
    isLinux = _platform.isLinux && !machine.nixos;
    isNixos = machine.nixos or false;
    isWsl = machine.wsl or false;
  };

  # The config files for this system.
  machineHMConfig = ../machines/${name}/home.nix;
  machineOSConfig = ../machines/${name}/${if host.isDarwin then "darwin" else "nixos"}.nix;
  # userOSConfig = ../users/${user}/${if host.isDarwin then "darwin" else "nixos"}.nix;
  # userHMConfig = ../users/${user}/home-manager.nix;

  # NixOS vs cachyos vs nix-darwin functions
  systemFunc = if host.isDarwin then inputs.darwin.lib.darwinSystem else nixpkgs.lib.nixosSystem;
  home-manager =
    if host.isDarwin then inputs.home-manager.darwinModules else inputs.home-manager.nixosModules;

  inherit (nixpkgs.lib) optionals;
in
systemFunc rec {
  inherit system;

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
  ++ optionals host.isDarwin [
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

      security.pam.services.sudo_local = {
        touchIdAuth = true;
      };
      system = {
        primaryUser = user;
        stateVersion = 6;
      };
    }

    # We expose some extra arguments so that our modules can parameterize
    # better based on these values.
    {
      config._module.args = {
        inherit inputs machine host;

        currentSystem = system;
        currentSystemName = name;
        currentSystemUser = user;
        isWSL = host.isWsl;
      };
    }
  ];
}
