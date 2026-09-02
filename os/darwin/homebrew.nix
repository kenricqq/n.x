{
  machine,
  ...
}:

let
  userHome = "/Users/${machine.user}";
in
{
  homebrew = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    onActivation = {
      autoUpdate = false;
      # Homebrew deprecated `--cleanup`; `--force-cleanup` still triggers cleanup.
      cleanup = "none";
      extraEnv = {
        XDG_CONFIG_HOME = "${userHome}/.config";
      };
      extraFlags = [ "--force-cleanup" ];
      upgrade = false;
    };
    global.brewfile = true;
    masApps = {
      # Vimari = 1480933944;
      # DaVinci = 571213070;
      # Launchy = 6739782043;
    };
    taps = [
      {
        name = "LizardByte/homebrew"; # sunshine
        trusted = true;
      }
      {
        name = "mikker/tap";
        trusted = true;
      }
      {
        name = "hatchet-dev/hatchet";
        trusted = true;
      }
      {
        name = "Franvy/gtab";
        trusted = true;
      }
      {
        name = "neurosnap/tap";
        trusted = true;
      }
      {
        name = "manaflow-ai/cmux";
        trusted = true;
      }
      # "rockorager/tap"
    ];
    brews = [
      "sunshine" # display streaming

      "pandoc"
      "zsh-async"

      "odin"
      "ols"
      "odinfmt"

      "oxfmt"
      "oxlint"

      "switchaudio-osx"
      "gtab"
      "clamav"
      "smartmontools"

      # "rustup"

      # "worktrunk"
      "aoe" # agent of empires

      "libheif"
      # "lsr"
      # "flow-control"
      # "zmx"
      # "prise"
      "humanlog"
      "python@3.14"
      "neonctl" # neondb

      # {
      #   name = "postgresql@18";
      #   restart_service = "changed";
      #   link = true;
      # }
      # "eilmeldung"

      # "podman"
      # "kanata"
      # "docker-compose"
      # "pnpm"
      {
        name = "deno";
        args = [ "HEAD" ];
      }
      {
        name = "uv";
        args = [ "HEAD" ];
      }
      # "tgpt"
      # "espeak-ng" # for kokoro stt
      "sevenzip"
      "gnupg"
      # "fisher"
      "container"

      # "sketchybar"
      "lua"
      # "borders"
      "mole" # deep clean

      "cocoapods" # for building ios apps
      # "switchaudio-osx"
      # "nowplaying-cli"
      "choose-gui"
      "terminal-notifier"
      # "llvm"

      "yt-dlp"
      "mpv"
      "ffmpeg"
      # {
      #   name = "yt-dlp";
      #   args = [ "HEAD" ];
      # }
      # "localai" # run local llms

      # "surreal"
      # "aws-shell"

      # "ghc"
      # "ghcup"
      # "haskell-stack"
    ];
    casks = [
      # "betterdisplay"
      "lunar" # brightness

      "moonlight"

      "notion"
      "notion-calendar"

      ## Dev Testing
      "beekeeper-studio" # sql editor
      "yaak" # api client
      # "dbeaver-community" # sql editor
      # "amazon-q"

      "hatchet"

      ## Dev Software
      "ghostty"
      # "ghostty@tip"
      # "rio"
      "zed@preview"
      "orbstack" # lightweight docker containers
      # "cursor"
      # "docker-desktop"
      "cmux"
      "conductor"

      ## Productivity
      "blender"
      "superhuman"
      "linear"
      "superwhisper"

      ## Notes
      "obsidian"
      # "excalidrawz"
      "todoist-app"

      ### Utils
      "shottr" # screenshot tool
      "bettercapture" # screen recorder, privacy-first
      "numi"

      ## TOOLS
      "rectangle"
      "tailscale-app"
      # "tuna"
      # "alt-tab" # app switcher w/ screenshot preview
      "raycast" # app launcher
      "activitywatch"
      # "zoom"
      # "loom"
      # "secretive" # Store SSH keys in the Secure Enclave
      # "karabiner-elements"
      "iina" # open-source media player
      # "obs" # screen recording
      # "background-music"
      # "keycastr"
      # "markedit"

      # "google-drive"
      # "syncthing" # secure file sync
      # "multipass"

      # MISC
      # "ngrok"
      # "glide"
      "legcord" # discord desktop client

      # "celestia" # 3D Space Simulator

      ## Browsers
      # "google-chrome"
      # "thebrowsercompany-dia"
      # "chatgpt-atlas"
      # "tor-browser"
      "helium-browser"
      "zen"

      ## Menu Bar
      "stats"
      # "thaw@beta" # hidden menu bar

      ## Privacy / Security
      "protonvpn"
      "proton-pass"
      "lulu" # firewall
      # "oversight" # mic / webcam monitor
      # "reikey" # key tap monitor

      # FONTS

      # "font-sf-mono"

      # serif fonts
      # "font-ibarra-real-nova" # text
      # "font-dm-serif-display" # title / headings

      "sf-symbols" # apple icons

      "font-hack-nerd-font"
      "font-meslo-lg-nerd-font"
      "font-jetbrains-mono"
      "font-sf-pro"

      # cool non-coding fontss
      "font-gilda-display"

      # fun
      # "roblox"
    ];
    # cargoPackages = [ "clippy" ];
  };
}
