{ pkgs, ... }:

{
  home.packages = with pkgs; [
    markdown-oxide
    mpls # live preview

    markdownlint-cli # style checks
    lychee # check links in docs/sites
  ];
}
