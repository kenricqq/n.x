{ pkgs, ... }:

{
  # programs.bun = {
  #   enable = true;
  # };

  home.packages = with pkgs; [
    typst

    tinymist # typst
    typstyle
  ];
}
