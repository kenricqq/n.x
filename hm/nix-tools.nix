{ pkgs, paths, ... }:

{
  home.packages = with pkgs; [
    cachix

    nix-converter # yaml <-> nix <-> toml
    nurl # nix fetcher generator

    nixd # Nix
    nixfmt # nix official

    (pkgs.writeShellApplication {
      name = "ns";
      runtimeInputs = with pkgs; [
        fzf
        nix-search-tv
      ];
      text = ''
        exec ${pkgs.bash}/bin/bash ${pkgs.nix-search-tv.src}/nixpkgs.sh "$@"
      '';
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
