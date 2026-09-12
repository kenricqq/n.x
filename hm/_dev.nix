{
  lib,
  pkgs,
  machine,
  ...
}:

let
  isDarwin = false;
in
{
  imports = [
    ./dev/lang/go.nix
    ./dev/lang/python.nix
    ./dev/lang/js_ts.nix
    ./dev/lang/markdown.nix
    ./dev/lang/rust.nix
    ./dev/lang/typst.nix
    ./dev/lang/zig.nix

    ./dev/devenv.nix
    ./dev/lsp.nix
    ./dev/pi.nix
    ./dev/vcs.nix
    ./dev/ollama.nix
  ];

  home = {
    packages = with pkgs; [
      lua

      hunk # diff viewer

      buf # for protobuf apis
      protobuf_33

      process-compose
      entr # run commands when files change

      dep-tree # visualize complexities of a codebase
      just # project-level command runner

      # kubernetes-helm # package manager for kubernetes
      # minikube
      clang-tools
      lldb_19

      docker-sbx

      # docker
      # dive # explore layer in docker image
      # ctop # top-like interface for containers

      # dev tools
      # protobuf_32
      # icu76 # unicode/globalization
      # cloudflared
      # n8n
      # k6 # load testing
    ];
  };

  programs = {
    docker-cli = {
      enable = false;
      # settings = {
      #   "proxies" = {
      #     "default" = {
      #       "httpProxy" = "http://proxy.example.org:3128";
      #       "httpsProxy" = "http://proxy.example.org:3128";
      #       "noProxy" = "localhost";
      #     };
      #   };
      # };
    };
    lazydocker = {
      # enable = true;
      settings = {
        gui.theme = {
          activeBorderColor = [
            "red"
            "bold"
          ];
          inactiveBorderColor = [ "blue" ];
        };
        commandTemplates.dockerCompose = "docker compose compose -f docker-compose.yml";
      };
    };

    # k9s = {
    #   enable = true;
    #   aliases = {
    #     # Use pp as an alias for Pod
    #     pp = "v1/pods";
    #   };
    #   hotKeys = {
    #     shift-0 = {
    #       shortCut = "Shift-0";
    #       description = "Viewing pods";
    #       command = "pods";
    #     };
    #   };
    #   plugins = {
    #     # Defines a plugin to provide a `ctrl-l` shortcut to
    #     # tail the logs while in pod view.
    #     fred = {
    #       shortCut = "Ctrl-L";
    #       description = "Pod logs";
    #       scopes = [ "po" ];
    #       command = "kubectl";
    #       background = false;
    #       args = [
    #         "logs"
    #         "-f"
    #         "$NAME"
    #         "-n"
    #         "$NAMESPACE"
    #         "--context"
    #         "$CLUSTER"
    #       ];
    #     };
    #   };
    #   settings = {
    #     k9s = {
    #       refreshRate = 2;
    #     };
    #   };
    # };

    # environment switcher
    direnv = {
      enable = true;
      enableZshIntegration = true;
      enableNushellIntegration = true;
      # mise.enable = true;
      nix-direnv.enable = true;
      silent = true;
    };
    # mise = {
    #   enable = true;
    #   globalConfig = {
    #     settings = {
    #       disable_tools = [ "node" ];
    #       experimental = true;
    #       verbose = false;
    #     };

    #     tasks = {
    #       dev = "bun run dev";
    #       # Global: [tasks.test] = "npm test"
    #       # Project: [tasks.test] = "yarn test"
    #     };

    #     tool_alias = {
    #       node.versions = {
    #         my_custom_node = "20";
    #       };
    #     };

    #     tools = {
    #       node = "lts";
    #       python = [
    #         "3.10"
    #         "3.11"
    #       ];
    #     };
    #   };
    # };
  };
}
