{
  host,
  lib,
  pkgs,
  ...
}:
let
  inherit (host)
    isDarwin
    ;
in
{
  programs = {
    # resource monitor / process manager
    btop = {
      enable = true;
      settings = {
        color_theme = "Default";
        theme_background = false;
        # default "cpu:1:default,proc:0:default cpu:0:default,mem:0:default,net:0:default cpu:0:block,net:0:tty"
        presets = "cpu:1:default,proc:0:default cpu:0:default,mem:0:default,net:0:default cpu:0:block,net:0:tty";
        vim_keys = true;
      };
    };
  };
  home.packages =
    (with pkgs; [
      dust
      dysk
      duf
      # dua # disk usage manager tui

      watch
      toolong # view, tail, merge, and search logs (tl)

      hyperfine # cli benchmarking tool
      tokei # code stats
    ])
    ++ lib.optionals isDarwin (
      with pkgs;
      [
        macmon # apple silicon perf monitor
      ]
    );
}
