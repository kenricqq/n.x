{
  config,
  machine,
  ...
}:

let
  paths =
    (import ../lib/paths.nix {
      home = config.home.homeDirectory;
      inherit (machine) name;
      repo = machine.repo or machine.name;
    })
    // {
      configHome = config.xdg.configHome;
      cache = config.xdg.cacheHome;
      share = "${paths.home}/.local/state/nix/profiles/home-manager/home-path/share";

      mkDotFile = subpath: {
        source = config.lib.file.mkOutOfStoreSymlink "${paths.dots}/${subpath}";
      };
    };
in
{
  _module.args = {
    inherit paths;
  };
}
