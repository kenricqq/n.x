{ pkgs, ... }:

{
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";

    fcitx5 = {
      waylandFrontend = true;

      addons = with pkgs; [
        fcitx5-chinese-addons
        fcitx5-gtk
      ];
    };
  };

  home.packages = with pkgs; [
    fcitx5-configtool
  ];

  home.sessionVariables = {
    QT_IM_MODULES = "wayland;fcitx;ibus";
  };
}
