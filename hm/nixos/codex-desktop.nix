{ config, paths, pkgs, ... }:

let
  inherit (paths)
    home
  ;
in
{
  programs.codexDesktopLinux = {
    enable = true;
    computerUseUi.enable = true;
    remoteMobileControl.enable = true;
    linuxFeatures = [ "codex-micro" ];
  };
}
