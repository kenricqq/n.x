{ inputs, pkgs, ... }:

{
  imports = [ inputs.nixcord.homeModules.nixcord ];

  programs.nixcord.enable = true;
  programs.nixcord.discord.enable = false;

  programs.nixcord.legcord = {
    enable = true;
    # macOS installs Legcord through Homebrew; Nixpkgs packages it for Linux only.
    installPackage = pkgs.stdenv.hostPlatform.isLinux;

    # Optionally bundle Vencord or Equicord (also installs userPlugins)
    vencord.enable = true;
    # equicord.enable = true;

    settings = {
      channel = "stable";
      tray = "dynamic";
      minimizeToTray = true;
      mods = [ "vencord" ];
      doneSetup = true;
    };
  };
}
