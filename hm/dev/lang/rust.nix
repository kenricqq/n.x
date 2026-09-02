{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # fenix.stable if want stable
    (fenix.complete.withComponents [
      "cargo"
      "clippy"
      "rust-src"
      "rustc"
      "rustfmt"
      "llvm-tools-preview"
    ])
    rust-analyzer-nightly
  ];
}
