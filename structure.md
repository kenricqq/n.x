
1. Machine name is where the repo root will be.
  - m0nix :-> /Users/kenrict/m0nix
  - meridian :-> /Users/kenrict/meridian
  - aegis :-> /Users/kenrict/aegis

dotfiles/
├── flake.nix
├── flake.lock
│
├── home-manager/
│   ├── modules/
│   │   ├── fish.nix
│   │   ├── git.nix
│   │   ├── cli-tools.nix
│   │   ├── dev-tools.nix
│   │   ├── neovim.nix
│   │   ├── terminal.nix
│   │   ├── fonts.nix
│   │   └── linux/
│   │       ├── noctalia.nix
│   │       └── hyprland.nix
│   │
│   └── profiles/
│       ├── base.nix
│       ├── dev.nix
│       ├── linux-desktop.nix
│       └── mac-desktop.nix
│
├── darwin/
│   ├── modules/
│   │   ├── homebrew.nix
│   │   ├── services.nix
│   │   └── system.nix
│   └── profiles/
│       └── workstation.nix
│
├── nixos/
│   ├── modules/
│   └── profiles/
│
├── machines/
│   ├── cachyos/
│   │   └── home.nix
│   ├── macbook/
│   │   ├── home.nix
│   │   └── darwin.nix
│   └── desktop/
│       ├── home.nix
│       └── nixos.nix
│
└── files/
