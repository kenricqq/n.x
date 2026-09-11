{ pkgs, ... }:

let
  # shader_language_server = pkgs.rustPlatform.buildRustPackage rec {
  #   pname = "shader-language-server";
  #   version = "1.3.2";

  #   src = pkgs.fetchCrate {
  #     pname = "shader_language_server";
  #     inherit version;
  #     hash = "sha256-FjSErDWkkO+bAgFZGzNfgHM92vbl7eKZbEGs+Q9hGLk=";
  #   };

  #   cargoHash = "sha256-nKKPvS+A/NXdH0TMI1tk80ffikKZqWNbENaS4FfdHGU=";

  #   doCheck = false;
  # };
in
{
  home.packages = with pkgs; [
    ### Language Servers

    # Python
    # python314Packages.pylsp-mypy
    # python314Packages.python-lsp-server

    ## Shell
    bash-language-server
    fish-lsp
    zsh-completions
    zk

    ## Markup & Config
    iwe
    # marksman               # Markdown LSP
    taplo # TOML
    simple-completion-language-server # snippets
    kdlfmt # kdl (config for zellij)
    # starpls # starlark
    yaml-language-server

    ## Programming Languages
    # beamMinimal27Packages.elixir-ls # Elixir

    # glsl
    glsl_analyzer
    # shader_language_server

    protols

    ## Systems Lang
    zlint

    lua-language-server
    sqls # SQL
    sqruff # SQL formatter
    python313Packages.sqlparse
    # haskellPackages.fourmolu # haskell
    # stylish-haskell # haskell (alt)

    ## Web & Front‑end
    superhtml
    emmet-language-server
    astro-language-server
    # typescript-language-server
    tailwindcss-language-server
    vscode-langservers-extracted # HTML / CSS / JSON / ESLint
    # efm-langserver # Formatter (wraps Prettier)

    # grammar / spellcheck
    harper
    ltex-ls-plus # for md / tex
    typos-lsp

    # ai
    # lsp-ai
  ];
}
