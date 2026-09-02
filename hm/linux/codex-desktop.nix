{
  config,
  paths,
  pkgs,
  ...
}:

let
  inherit (paths)
    home
    ;
in
{
  programs.codexDesktopLinux = {
    enable = true;
    computerUseUi.enable = false;
    remoteMobileControl.enable = true;
    linuxFeatures = [
      "read-aloud"
      "ui-tweaks"
    ];
  };
}
