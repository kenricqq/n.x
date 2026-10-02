{ ... }:

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
