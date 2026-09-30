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
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-plist-manager = {
      url = "github:sushydev/nix-plist-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
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
    zig-flake = {
      url = "github:silversquirl/zig-flake";
      inputs.nixpkgs.follows = "zls/nixpkgs";
    };
    zls = {
      url = "github:zigtools/zls";
      inputs.zig-flake.follows = "zig-flake";
    };

    dooit.url = "github:dooit-org/dooit";
    dooit-extras = {
      url = "github:dooit-org/dooit-extras";
      inputs.dooit.follows = "dooit";
      inputs.nixpkgs.follows = "dooit/nixpkgs";
    };

    helix = {
      url = "github:helix-editor/helix";
      # inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
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

      mkSyncAddresses = network: [
        "tcp://${network.tailscale}:22000"
        "tcp://${network.tb}:22000"
        "dynamic"
      ];

      syncthing = {
        devices = {
          m0nix = {
            id = "2UDHDAW-YWVLSHK-NTFHRL5-XJJJ44N-DCPQEQT-3AYPPA4-3RFBNBD-BXHMTQ7";
            addresses = mkSyncAddresses profile.mba.network;
          };
          meridian = {
            id = "DC7NXSI-JZ65WRZ-7B3MMHQ-QNJGZM5-6UM5C3F-NSWAHBM-YBOJLDJ-ZZXR7QR";
            addresses = mkSyncAddresses profile.meridian.network;
          };
          laurentii = {
            id = "EKJVIR6-JU62KRJ-J3V2PED-XVYHOBD-K532VXE-AXVZJHP-RA64EIM-3MLEXQ4";
            addresses = mkSyncAddresses profile.laurentii.network;
          };

          i17p =
            let
              tailscale_ip = "100.96.80.45";
            in
            {
              id = "TIKN6GA-V2JYS65-SRSH45S-NIB5D65-7L5KPJA-GDQGQMW-XMKGOSR-J2FFVQB";
              addresses = [ "tcp://${tailscale_ip}:22000" ];
              allowedNetworks = [ "${tailscale_ip}/32" ]; # also restrict incoming connections
            };
        };

        folders = {
          sync = {
            path = "~/Sync";
            devices = [
              "m0nix"
              "meridian"
              "laurentii"
            ];
          };
          docs = {
            path = "~/Docs";
            devices = [
              "m0nix"
              "meridian"
              "i17p"
            ];
          };
          # projects = { path = "~/Projects"; devices = [ "m0nix" "meridian" ]; };
        };
      };

      profile = {
        mba = {
          inherit syncthing;
          name = "m0nix";
          system = "aarch64-darwin";
          user = "kenrictee";

          network = {
            tb = "10.10.10.2";
            tailscale = "100.79.126.103";
          };

          # allowIncoming lists machines allowed to SSH into me
          # first peer on mac is used for switching monitor input (reg usbc hub don't work)
          allowIncoming = with profile; [
            meridian
          ];
        };

        meridian = {
          inherit syncthing;
          name = "meridian";
          system = "x86_64-linux";
          user = "kenrict";

          network = {
            tb = "10.10.10.3";
            tailscale = "100.100.44.94";
          };

          allowIncoming = with profile; [
            mba
          ];
        };

        laurentii = {
          inherit syncthing;
          name = "laurentii";
          system = "x86_64-linux";
          user = "kenrict";
          nixos = true;

          network = {
            tb = "10.10.10.4";
            tailscale = "100.112.47.42";
          };

          allowIncoming = with profile; [
            mba
            meridian
          ];
        };
      };
    in
    {

      darwinConfigurations.${profile.mba.name} = mkSystem profile.mba;

      homeConfigurations.${profile.meridian.name} = mkHome profile.meridian;

      nixosConfigurations.${profile.laurentii.name} = mkSystem profile.laurentii;

      # nixosConfigurations.wsl = mkSystem "wsl" {
      #   system = "x86_64-linux";
      #   user = "kenrict";
      #   wsl = true;
      # };
    };
}
