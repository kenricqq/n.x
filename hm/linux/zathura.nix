{ paths, ... }:

let
  inherit (paths)
    home
    ;
in
{
  programs.zathura = {
    enable = true;
    options.scroll-step = 100;
    options.selection-clipboard = "clipboard";
  };
}
