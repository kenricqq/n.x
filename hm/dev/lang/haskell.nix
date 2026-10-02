{
  pkgs,
  ...
}:
let
  hp = pkgs.haskell.packages.ghc912;
in
{
  home.packages = with pkgs; [
    stack
    hp.ghc
    (hp.elsa.override {
      dequeue = haskell.lib.compose.dontCheck hp.dequeue;
    })
  ];
}
