{
  lib,
  machine,
  paths,
  ...
}:

{
  imports = [
    ../../hm/paths.nix
    ../../hm/_base.nix
    ../../hm/_dev.nix
    ../../hm/_linux-desktop.nix
    ../../hm/nixcord.nix
  ];

  home = {
    username = machine.user;
    homeDirectory = "/home/${machine.user}";
    stateVersion = "26.11";
  };

  programs = {
    home-manager.enable = true;
    git.enable = true;
    bash = {
      enable = true;
      shellAliases = {
        btw = "echo i use nixos, btw";
        run = "sudo nixos-rebuild switch --flake ${lib.escapeShellArg "${paths.nixrt}#${machine.name}"}";
      };
    };
    # Laurentii's NixOS module owns nh and cleanup. Shared HM defaults stay
    # enabled for standalone Home Manager and nix-darwin machines.
    nh.enable = lib.mkForce false;
    nh.clean.enable = lib.mkForce false;
  };

  xdg.enable = true;
}
