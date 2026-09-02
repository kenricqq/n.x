{
  config,
  machine,
  ...
}:

let
  paths = rec {
    home = config.home.homeDirectory;

    nixrt = "${home}/${machine.name}";
    hm = "${nixrt}/hm";
    os = "${nixrt}/os";

    cache = config.xdg.cacheHome;

    dots = "${nixrt}/dots";
    darwin = "${nixrt}/os/darwin";
    scripts = "${nixrt}/scripts";
    snippets = "${hm}/snippets";

    share = "${home}/.local/state/nix/profiles/home-manager/home-path/share";

    mkDotFile = subpath: {
      source = config.lib.file.mkOutOfStoreSymlink "${dots}/${subpath}";
    };
  };
in
{
  _module.args = {
    inherit paths;
  };
}
