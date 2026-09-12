{
  description = "Nix Systems :-: MacOS, CachyOS, NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    # nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helium = {
      url = "github:schembriaiden/helium-browser-nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zig.url = "github:mitchellh/zig-overlay";
    zls.url = "github:zigtools/zls";

    dooit.url = "github:dooit-org/dooit";
    dooit-extras = {
      url = "github:dooit-org/dooit-extras";
      inputs.dooit.follows = "dooit";
      inputs.nixpkgs.follows = "dooit/nixpkgs";
    };

    helix = {
      url = "github:helix-editor/helix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    jujutsu = {
      url = "github:martinvonz/jj";
      # inputs.nixpkgs.follows = "nixpkgs";
    };

    # non flakes

    codex-desktop-linux = {
      url = "github:ilysenko/codex-desktop-linux";
    };

    blender-cuda.url = "github:adithyagenie/blender-cuda-nixos";

    nixcord.url = "github:4evy/nixcord";
  };

  outputs =
    { nixpkgs, ... }@inputs:
    let
      # Overlays is the list of overlays we want to apply from flake inputs.
      overlays = [
        ## Dooit is used directly
        # inputs.dooit.overlays.default
        # inputs.dooit-extras.overlay

        # inputs.jujutsu.overlays.default
        inputs.fenix.overlays.default
        inputs.zig.overlays.default

        (
          _final: prev:
          let
            system = prev.stdenv.hostPlatform.system;
            unstable = import inputs.nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };
          in
          {

            # Want the latest version of these
            codex = unstable.codex;
            nushell = unstable.nushell;
            ghostty = unstable.ghostty;
            gh = unstable.gh;
          }
        )
      ];

      mkSystem = import ./lib/mksystem.nix {
        inherit
          overlays
          nixpkgs
          inputs
          ;
      };

      mkHome = import ./lib/mkhome.nix {
        inherit
          overlays
          nixpkgs
          inputs
          ;
      };

      profile = {
        mba = {
          name = "m0nix";
          system = "aarch64-darwin";
          user = "kenrictee";

          sync = {
            id = "2UDHDAW-YWVLSHK-NTFHRL5-XJJJ44N-DCPQEQT-3AYPPA4-3RFBNBD-BXHMTQ7";
            tb = "10.10.10.2";
            tailscale = "100.79.126.103";
          };

          peers = with profile; [
            meridian
          ];
        };

        meridian = {
          name = "meridian";
          system = "x86_64-linux";
          user = "kenrict";

          sync = {
            id = "DC7NXSI-JZ65WRZ-7B3MMHQ-QNJGZM5-6UM5C3F-NSWAHBM-YBOJLDJ-ZZXR7QR";
            tb = "10.10.10.3";
            tailscale = "100.100.44.94";
          };

          peers = with profile; [
            mba
          ];
        };

        vm-agents = {
          name = "vm-agents";
          system = "x86_64-linux";
          user = "kenrict";
          nixos = true;

          sync = {
            tb = "10.10.10.4";
          };
        };
      };
    in
    {

      darwinConfigurations.${profile.mba.name} = mkSystem profile.mba;

      homeConfigurations.${profile.meridian.name} = mkHome profile.meridian;

      nixosConfigurations.${profile.vm-agents.name} = mkSystem profile.vm-agents;

      # nixosConfigurations.wsl = mkSystem "wsl" {
      #   system = "x86_64-linux";
      #   user = "kenrict";
      #   wsl = true;
      # };
    };
}
