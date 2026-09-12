{
  inputs,
  machine,
  ...
}:

let
  gpuVersion = "610.57.04";
in
{
  imports = [
  ]
  ++ (map (profile: ../../hm + "/${profile}") [
    "paths.nix"
    "_base.nix"
    "_dev.nix"
    "_linux-desktop.nix"
    "nixcord.nix"
  ]);

  home = {
    username = machine.user;
    homeDirectory = "/home/${machine.user}";
    stateVersion = "26.11";

    packages = [
      inputs.blender-cuda.packages.${machine.system}.blender-with-cuda-unstable
    ];
  };

  programs.home-manager.enable = true;

  nixpkgs.config = {
    # cudaSupport = true;
    nvidia.acceptLicense = true;
  };

  targets.genericLinux = {
    enable = true;
    gpu = {
      enable = true;
      nvidia = {
        enable = true;
        version = "610.57.04";
        sha256 = "sha256-suk1xmuDuwDAyFe8jg7g/VLekoa0DJzB7sKafOfrEW0=";
      };
    };
  };
  xdg.enable = true;
}
