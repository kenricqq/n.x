{
  inputs,
  machine,
  pkgs,
  ...
}:
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
    inputs.fenix.packages.${machine.system}.rust-analyzer
    # rust-analyzer-nightly
  ];
}
