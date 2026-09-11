{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # go
    # go-swag # API docs
    # delve # go debugger
    # envsubst # env var substitution
    # air # live reload for go
    # pkgsite # generate docs for go
    # errcheck # checks unchecked erros in go
    # sqlc # generate type-safe code from SQL
    # goose # db migration tool

    # ghc
    # ghcid
    # stack # stack has own version of ghc?
    # haskell-language-server
    # hlint
    # haskellPackages.cabal-install

    # elixir_1_18
  ]

  programs.go = {
    enable = true;
    packages = {
      # "golang.org/x/text" = builtins.fetchGit "https://go.googlesource.com/text";
      # "golang.org/x/time" = builtins.fetchGit "https://go.googlesource.com/time";
    };
    env = {
      # GOPATH = [
      #   "${config.home.homeDirectory}/mygo"
      #   "/another/go"
      #   "/yet/another/go"
      # ];

      # GOPRIVATE = [
      #   "*.corp.example.com"
      #   "rsc.io/private"
      # ];

      # CXX = "g++";
      # GCCGO = "gccgo";
      # GOAMD64 = "v1";
      # GOARCH = "amd64";
      # GOAUTH = "netrc";
    };
    telemetry.mode = "off";
  };
}
