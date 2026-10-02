{
  inputs,
  lib,
  machine,
  ...
}:

{
  imports = [
  ]
  ++ (map (profile: ../../hm + "/${profile}") [
    "paths.nix"
    "_base.nix"
    "_dev.nix"
    "nixcord.nix"
    "macos/system-settings.nix"
  ]);

  home = {
    username = machine.user;
    homeDirectory = "/Users/${machine.user}";
    stateVersion = "26.11";
  };

  programs.home-manager.enable = true;

  targets.darwin.copyApps.enableChecks = false;

  xdg.enable = true;
}
