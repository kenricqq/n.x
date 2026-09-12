{
  description = "Temporary QMK build environment for the wired RP2040 Corne";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          qmk
          just
          git
          gcc-arm-embedded
          gnumake
          python3
          diffutils
        ];
        # QMK builds freestanding firmware, not a hardened host executable.
        hardeningDisable = [ "all" ];
      };
    };
}
