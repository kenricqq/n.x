{
  host,
  lib,
  machine,
  paths,
  pkgs,
  ...
}:

let
  mkScriptCommand =
    {
      name,
      runtimeInputs ? [ ],
      source ? name,
    }:
    pkgs.writeShellApplication {
      inherit name runtimeInputs;
      text = builtins.readFile (../scripts + "/${source}");
    };

  helixHistory = mkScriptCommand {
    name = "hx-history";
    runtimeInputs = with pkgs; [
      coreutils
      fzf
      gawk
    ];
  };

  mkHelixHistoryCommand =
    name: action:
    pkgs.writeShellApplication {
      inherit name;
      text = ''
        exec ${lib.getExe helixHistory} ${action} "$@"
      '';
    };

  hxOpen = mkHelixHistoryCommand "hx-open" "open";
  hxLast = mkHelixHistoryCommand "hx-last" "last";
  hxRecent = mkHelixHistoryCommand "hx-recent" "recent";

  jjWorkspace = mkScriptCommand {
    name = "jjw";
    runtimeInputs = with pkgs; [
      coreutils
      findutils
      fzf
      gawk
      jq
      jujutsu
    ];
  };

  youtubeRuntimeInputs = with pkgs; [
    ffmpeg
    yt-dlp
  ];

  ytAudio = mkScriptCommand {
    name = "yt-audio";
    runtimeInputs = youtubeRuntimeInputs;
  };

  ytVideo = mkScriptCommand {
    name = "yt-video";
    runtimeInputs = youtubeRuntimeInputs;
  };

  # One interface for standalone Home Manager, NixOS, and nix-darwin.
  # The configured profile determines routing, including when inspected on another OS.
  homeProfile = pkgs.writeShellApplication {
    name = "home-profile";
    # Darwin uses the installed Determinate Nix from the caller's PATH.
    runtimeInputs =
      with pkgs;
      [
        nh
        sops
      ]
      ++ lib.optional (!host.isDarwin) nix;
    text = ''
      repo=${lib.escapeShellArg paths.nixrt}
      profile=${lib.escapeShellArg machine.name}
      user=${lib.escapeShellArg machine.user}
      profile_kind=${
        lib.escapeShellArg (
          if host.isNixos then
            "nixos"
          else if host.isDarwin then
            "darwin"
          else
            "home"
        )
      }
      flake="$repo"

      usage() {
        printf '%s\n' \
          'Usage: home-profile <activate|switch|update|clean|shell|secrets> [args...]' \
          "" \
          '  activate  Activate Home Manager (switch the full system on NixOS)' \
          '  switch    Switch the full system or standalone Home Manager profile' \
          '  update    Update flake inputs, switch, and update platform tools' \
          '  clean     Clean old Home Manager/Nix generations' \
          '  shell     Open nixpkgs packages (for example: home-profile shell ripgrep)' \
          "  secrets   Edit the repository's encrypted secrets file"
      }

      notify() {
        local message=$1
        if command -v terminal-notifier >/dev/null 2>&1; then
          terminal-notifier -message "$message" || true
        elif command -v notify-send >/dev/null 2>&1; then
          notify-send "Home Manager" "$message" || true
        fi
      }

      activate_home() {
        local activation
        cd "$repo"

        # NixOS owns user packages through its system generation, so activate
        # must switch that generation too. Standalone HM and nix-darwin retain
        # their Home Manager-only activation paths below.
        if [[ $profile_kind == nixos ]]; then
          switch_profile
          return
        fi

        if [[ $profile_kind == darwin ]]; then
          activation=$(nix build --no-link --print-out-paths \
            "$flake#darwinConfigurations.$profile.config.home-manager.users.$user.home.activationPackage")
        else
          activation=$(nix build --no-link --print-out-paths \
            "$flake#homeConfigurations.$profile.activationPackage")
        fi

        "$activation/activate"
      }

      switch_profile() {
        cd "$repo"
        # Each output keeps its own backend: NixOS, nix-darwin, or standalone HM.
        if [[ $profile_kind == nixos ]]; then
          nh os switch "$flake#$profile"
        elif [[ $profile_kind == darwin ]]; then
          nh darwin switch "$flake#$profile"
        else
          nh home switch "$flake" --configuration "$profile"
        fi
      }

      action=''${1:-}
      [[ -n $action ]] || {
        usage >&2
        exit 2
      }
      shift

      case "$action" in
        activate)
          [[ $# -eq 0 ]] || {
            usage >&2
            exit 2
          }
          activate_home
          notify "Home Manager activated"
          ;;
        switch)
          [[ $# -eq 0 ]] || {
            usage >&2
            exit 2
          }
          switch_profile
          notify "Profile switched"
          ;;
        update)
          [[ $# -eq 0 ]] || {
            usage >&2
            exit 2
          }
          cd "$repo"
          nix flake update
          switch_profile
          if [[ $profile_kind == darwin ]] && command -v brew >/dev/null 2>&1; then
            brew update
            brew upgrade
          fi
          if [[ $profile_kind == darwin ]] && command -v determinate-nixd >/dev/null 2>&1; then
            sudo determinate-nixd upgrade || true
          fi
          notify "System inputs updated"
          ;;
        clean)
          [[ $# -eq 0 ]] || {
            usage >&2
            exit 2
          }
          if [[ $profile_kind == darwin ]]; then
            # prune + GC here; dedupe separately via `nso`.
            nh clean all --keep 2 --keep-one
          else
            nh clean all
            if command -v mole >/dev/null 2>&1; then
              mole clean
            fi
          fi
          ;;
        shell)
          packages=()
          for package in "$@"; do
            if [[ $package == *'#'* || $package == .* || $package == /* ]]; then
              packages+=("$package")
            else
              packages+=("nixpkgs#$package")
            fi
          done
          exec nix shell "''${packages[@]}"
          ;;
        secrets)
          secret_file="$repo/secrets/secrets.yaml"
          [[ -f $secret_file ]] || {
            printf 'No secrets file at %s\n' "$secret_file" >&2
            exit 1
          }
          command -v sops >/dev/null 2>&1 || {
            printf 'sops is not installed\n' >&2
            exit 127
          }
          exec sops "$secret_file" "$@"
          ;;
        -h|--help|help)
          usage
          ;;
        *)
          printf 'Unknown action: %s\n' "$action" >&2
          usage >&2
          exit 2
          ;;
      esac
    '';
  };

  cachix-conf = pkgs.writeShellApplication {
    name = "cachix-conf";
    runtimeInputs = [
      pkgs.curl
      pkgs.jq
    ];
    text = ''
      if [[ $# -ne 1 ]]; then
        printf 'Usage: cachix-conf CACHE\n' >&2
        exit 2
      fi

      curl --fail --silent --show-error "https://cachix.org/api/v1/cache/$1" \
        | jq -r '"extra-substituters = \(.uri)\nextra-trusted-public-keys = \(.publicSigningKeys[0])"'
    '';
  };

  list-ports = pkgs.writeShellApplication {
    name = "list-ports";
    runtimeInputs = [
      pkgs.lsof
      pkgs.ripgrep
    ];
    text = ''
      if [[ $# -eq 0 ]]; then
        exec lsof -nP -i -sTCP:LISTEN
      fi

      if [[ $# -ne 1 ]]; then
        printf 'Usage: list-ports [PATTERN]\n' >&2
        exit 2
      fi

      lsof -nP -i -sTCP:LISTEN | rg -- "$1"
    '';
  };

  mergepdf = pkgs.writeShellApplication {
    name = "mergepdf";
    runtimeInputs = [ pkgs.ghostscript ];
    text = ''
      output=_merged.pdf
      if [[ ''${1:-} == -o || ''${1:-} == --output ]]; then
        [[ $# -ge 3 ]] || {
          printf 'Usage: mergepdf [-o OUTPUT.pdf] INPUT.pdf...\n' >&2
          exit 2
        }
        output=$2
        shift 2
      fi

      [[ $# -gt 0 ]] || {
        printf 'Usage: mergepdf [-o OUTPUT.pdf] INPUT.pdf...\n' >&2
        exit 2
      }

      exec gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile="$output" "$@"
    '';
  };

  remoteOpenrgb = pkgs.writeShellApplication {
    name = "openrgb";
    text = ''
      printf -v remoteCommand '%q ' openrgb "$@"
      exec ssh "${(builtins.head machine.allowIncoming).name}" "$remoteCommand"
    '';
  };

  emptyTrash = pkgs.writeShellApplication {
    name = "emptytrash";
    runtimeInputs = with pkgs; [
      coreutils
      findutils
      sqlite
    ];
    text = ''
      find "$HOME/.Trash" -mindepth 1 -maxdepth 1 -exec rm -rfv -- {} +
      quarantine="$HOME/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV2"
      if [[ -f "$quarantine" ]]; then
        sqlite3 "$quarantine" 'delete from LSQuarantineEvent; vacuum'
      fi
    '';
  };

  restartMpd = pkgs.writeShellApplication {
    name = "restart-mpd";
    text = ''
      exec /bin/launchctl kickstart -k "gui/$(/usr/bin/id -u)/org.nix-community.home.mpd"
    '';
  };

  lockScreen = pkgs.writeShellApplication {
    name = "lock-screen";
    text = ''
      exec '/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession' -suspend
    '';
  };
in
{
  home.packages = [
    cachix-conf
    helixHistory
    homeProfile
    hxLast
    hxOpen
    hxRecent
    jjWorkspace
    list-ports
    mergepdf
    ytAudio
    ytVideo
  ]
  ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
    emptyTrash
    lockScreen
    remoteOpenrgb
    restartMpd
  ]
  ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.wl-clipboard ];
}
