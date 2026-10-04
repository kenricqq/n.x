{ pkgs, ... }:

{
  home.packages = with pkgs; [
    typst

    tinymist # typst
    typstyle
  ];
}
