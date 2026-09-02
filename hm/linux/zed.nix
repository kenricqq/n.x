{ pkgs, config, ... }:

let
  home = config.home.homeDirectory;
in
{
  programs.zed-editor = {
    enable = true;
    enableMcpIntegration = true;
    # defaultEditor = true;
    extensions = [
      "nix"
      "postgres-language-server"
    ];
    extraPackages = with pkgs; [
      nixd
    ];
    # installRemoteServer = true;
    # matchBlocks = {
    #   "github.com" = {
    #     hostname = "github.com";
    #     user = "kenricqq";
    #     identityFile = "${home}/.ssh/id_kenricqq";
    #   };
    #   "gitlab.com" = {
    #     hostname = "gitlab.com";
    #     user = "ketee";
    #     identityFile = "${home}/.ssh/id_gitlab";
    #   };
    #   "*" = {
    #     addKeysToAgent = "yes";
    #     serverAliveInterval = 25;
    #     forwardAgent = true;
    #   };
    # };
  };
}
