{ pkgs, paths, ... }:

{
  home.packages = with pkgs; [
    cachix

    nurl # nix fetcher generator

    (pkgs.writeShellApplication {
      name = "ns";
      runtimeInputs = with pkgs; [
        fzf
        nix-search-tv
      ];
      text = builtins.readFile "${pkgs.nix-search-tv.src}/nixpkgs.sh";
    })
  ];

  programs = {
    nh = {
      enable = true;
      clean = {
        enable = true;
        extraArgs = "--keep-since 4d --keep 2";
      };
      flake = "${paths.nixrt}/flake.nix";
    };

    nix-search-tv = {
      enable = true;
      enableTelevisionIntegration = true;
      settings = {
        indexes = [
          "nixpkgs"
          "home-manager"
          "darwin"
        ];

        experimental = {
          render_docs_indexes = {
            nvf = "https://notashelf.github.io/nvf/options.html";
          };
        };
      };
    };
  };
}
