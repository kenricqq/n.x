# binary-cache settings for NixOS, nix-darwin, and Home Manager
{
  substituters = [
    "https://devenv.cachix.org"
    "https://helix.cachix.org"
    "https://fenix.cachix.org"

    "https://comfyui.cachix.org"
    "https://nix-community.cachix.org"
    "https://cache.nixos-cuda.org"
    "https://adithyagenie.cachix.org" # blender cuda

    "https://zig-overlay.cachix.org"
    "https://zigtools.cachix.org"
    "https://codex-desktop-linux.cachix.org"
    "https://oxalica.cachix.org"
  ];
  trusted-public-keys = [
    "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
    "fenix.cachix.org-1:ecJhr+RdYEdcVgUkjruiYhjbBloIEGov7bos90cZi0Q="

    "comfyui.cachix.org-1:33mf9VzoIjzVbp0zwj+fT51HG0y31ZTK3nzYZAX0rec="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
    "adithyagenie.cachix.org-1:h6BSMboeVfxyrULWuRQqAyweo4AJRATekb88xotfQwc="

    "zig-overlay.cachix.org-1:MCS36+WBxE8vqfE4j5BnCAx0Gse9EnTLSukAvP8JwtA="
    "zigtools.cachix.org-1:USl8MDuq1Jyx4pET+Q8siEIf1Nfja7hyXr9NuOf12PU="
    "codex-desktop-linux.cachix.org-1:nX/xy6AdK9hQE24A8ALGjkCKj2ObFmcnemiL5Cid4nk="
    "oxalica.cachix.org-1:h0iRBw6tQD8+51ZvnNEBPbwLR58UD7klauDBWzBdugQ="
  ];
}
