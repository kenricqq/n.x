{ pkgs, ... }:

{
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
