{ pkgs, ... }:

{
  programs.bun = {
    enable = true;
    settings = {
      install = {
        # lockfile = {
        #   print = "yarn";
        # };
      };
      smol = true;
      telemetry = false;
      test = {
        coverage = true;
        coverageThreshold = 0.9;
      };
    };
  };

  home.packages = with pkgs; [
    typescript
    tsgolint
    vtsls

    oxfmt
    oxlint

    prettier
    # uwu-colors # color swatches

    svelte-check
    svelte-language-server
  ];
}
