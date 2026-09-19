{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # occasionally useful, not core deps
    crates-tui # browse crates.io in terminal
    gping # compare latency with live graphs
    kondo # clean project deps + build artifacts
    lychee # link check for docs/sites
    ttyper # typing practice

    # dev/doc tools
    cargo-binstall # prebuilt Rust binaries
    cargo-update # update Cargo-installed executables
    espflash # flash Espressif devices
    mdbook # publish books from Markdown
    mdbook-linkcheck2 # check links in mdBook projects

    # service binaries only; no daemons/DNS changes enabled
    # qui # alt web UI for existing qBittorrent instance
    telegram-bot-api # self-hosted Telegram Bot API server
    dnscrypt-proxy # encrypted DNS proxy

    # finance/spreadsheets
    puffin # dashboard for an existing hledger setup
    bagels # terminal expense tracking
    ticker # stock quotes and portfolio tracking
    sc-im # terminal spreadsheet

    # Visual tools that explain, present, or demonstrate real work.
    chafa # preview images and GIFs in the terminal
    onefetch # repository summary with language artwork
    presenterm # present Markdown slides in the terminal
    silicon # render source code as an image
    vhs # generate repeatable terminal demo GIFs

    # procs
    # gum
    # unzip
  ];
}
