{ pkgs, ... }:

{
  programs = {
    # python lsp (by astral)
    ty = {
      enable = true;
      settings = {
        rules.index-out-of-bounds = "ignore";
      };
    };

    # python linter + code formatter
    ruff = {
      enable = true;
      settings = {
        line-length = 100;
        format = {
          indent-style = "space";
        };
        lint = {
          per-file-ignores = {
            "__init__.py" = [
              "F401"
              "E402"
            ];
          };
          select = [
            "E4"
            "E7"
            "E9"
            "F"
            "B"
            "Q"
          ];
          unfixable = [ "B" ];
          ignore = [ ];
          fixable = [ "ALL" ];
        };
      };
    };

    # python package/env manager
    uv = {
      enable = true;
      python = {
        default = [
          "3.14"
          "pypy@3.11"
        ];
        versions = [
          "3.14"
          "3.13"
          "pypy@3.11"
        ];
        prune = true;
      };
      settings = {
        # python-downloads = "never";
        # python-preference = "only-system";
        # pip.index-url = "https://test.pypi.org/simple";
      };
      tool = {
        packages = [
          # "ruff"
        ];
        prune = true;
      };
    };
  };

  home.packages = with pkgs; [
    python314
  ];
}
