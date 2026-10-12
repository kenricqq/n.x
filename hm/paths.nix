{
  config,
  machine,
  ...
}:

let
  paths = rec {
    home = config.home.homeDirectory;

    # Checkout path is relative to home; defaults to the machine name.
    nixrt = "${home}/${machine.repo or machine.name}";
    hm = "${nixrt}/hm";
    os = "${nixrt}/os";
    dots = "${nixrt}/dots";
    darwin = "${os}/darwin";
    scripts = "${nixrt}/scripts";
    snippets = "${hm}/snippets";

    inherit (config.xdg) configHome dataHome;
    cache = config.xdg.cacheHome;
    share = "${home}/.local/state/nix/profiles/home-manager/home-path/share";

    mkDotFile = subpath: {
      source = config.lib.file.mkOutOfStoreSymlink "${dots}/${subpath}";
    };
  };
in
{
  lib.paths = paths;
  _module.args.paths = paths;
}
