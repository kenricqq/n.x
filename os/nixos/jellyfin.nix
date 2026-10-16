{
  config,
  lib,
  machine,
  pkgs,
  utils,
  ...
}:

let
  libDir = "/mnt/library";
  mediaDir = "${libDir}/jellyfin/yt";
  # temporary download staging directory
  workDir = "${libDir}/.ytdl-sub-tmp";
  acaytUnit = "ytdl-sub-${utils.escapeSystemdPath "acayt"}";
in
{
  services.jellyfin = {
    enable = true;
    openFirewall = false;
    hardwareAcceleration = {
      enable = true;
      type = "qsv";
      device = "/dev/dri/renderD128";
    };
    forceEncodingConfig = true;
    transcoding = {
      enableHardwareEncoding = true;
      hardwareDecodingCodecs = {
        h264 = true;
        hevc = true;
        hevc10bit = true;
        mpeg2 = true;
        vp8 = true;
        vp9 = true;
        av1 = true;
      };
      hardwareEncodingCodecs = {
        hevc = true;
        av1 = true;
      };
    };
  };

  # yt-dlp manager for jellyfin
  services.ytdl-sub = {
    group = "jellyfin";
    # subscription docs: https://ytdl-sub.readthedocs.io/en/latest/config_reference/subscription_yaml.html
    instances = {
      acayt = {
        enable = true;
        # allow sandboxed downloader to write media and tmp files
        readWritePaths = [
          mediaDir
          workDir
        ];
        config.configuration = {
          working_directory = lib.mkForce workDir;
          umask = "027";
        };
        # check every 6 hrs
        schedule = "0/6:0";
        subscriptions = {
          # Each source supplies a fixed YYYYMMDD cutoff so downtime cannot skip videos.
          # No retention/pruning settings: downloaded videos stay on disk.
          __preset__ = {
            overrides.tv_show_directory = mediaDir;
            date_range.after = "{download_since}";
            # cut out all removable SponsorBlock categories
            chapters = {
              sponsorblock_categories = [ "all" ];
              remove_sponsorblock_categories = [ "all" ];
            };
            subtitles = {
              subtitles_name = "{episode_file_path}.{lang}.{subtitles_ext}";
              subtitles_type = "srt";
              languages = [ "en" ];
              allow_auto_generated_subtitles = true;
            };
          };
          # "|" combines Jellyfin metadata/date-based episodes with the best quality up to 4K.
          # Layout: https://ytdl-sub.readthedocs.io/en/latest/prebuilt_presets/tv_shows.html
          # Quality: https://ytdl-sub.readthedocs.io/en/latest/prebuilt_presets/media_quality.html
          "Jellyfin TV Show by Date | Max 2160p" = {
            # "~" shorthand for overrides; is stripped from the displayed title
            "~3Blue1Brown" = {
              # sub to new uploads, excluding shorts/livestream
              url = "https://www.youtube.com/@3blue1brown/videos";
              # initial backfill; keep cutoff fixed
              download_since = "20260913";
            };
          };
          # playlist positions become episode numbers in filenames and NFOs
          # if YouTube removes/reorders lessons, archived numbering needs manual reconciliation
          "Jellyfin TV Show Collection | Max 2160p" = {
            "Neural Networks - Zero to Hero" = {
              # scan past archived entries to find additions anywhere in the playlist
              ytdl_options.break_on_existing = false;
              overrides = {
                s01_url = "https://www.youtube.com/playlist?list=PLAqhIrjkxbuWI23v9cThsA9GvCAUhRvKZ";
                s01_name = "Neural Networks: Zero to Hero";
                # Mixed-channel playlists can otherwise use a guest uploader's avatar.
                tv_show_poster_file_name = "";
                tv_show_collection_episode_ordering = "playlist-index";
                # 01/01/1970
                download_since = "19700101";
              };
            };
          };
        };
      };
    };
  };

  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "jescan";
      runtimeInputs = [ pkgs.curl ];
      text = ''
        api_key_file=${lib.escapeShellArg config.home-manager.users.${machine.user}.sops.secrets.JELLYFIN_API_KEY.path}
        if ! api_key="$(< "$api_key_file")" || [[ -z "$api_key" ]]; then
          printf 'Missing or empty SOPS secret JELLYFIN_API_KEY at %s. Activate Home Manager secrets.\n' "$api_key_file" >&2
          exit 1
        fi
        printf 'Authorization: MediaBrowser Token="%s"\n' "$api_key" |
          curl -q --fail --silent --show-error --data "" --header @- \
            http://127.0.0.1:8096/Library/Refresh
        printf 'Jellyfin library scan requested.\n'
      '';
    })
    (pkgs.writeShellApplication {
      name = "yt-refresh";
      runtimeInputs = [ pkgs.systemd ];
      text = ''
        sudo systemctl start '${acaytUnit}.service'
        exec sudo journalctl -fu '${acaytUnit}.service'
      '';
    })
  ];

  # create directories as root after mounting the library, before starting downloader
  systemd.services.ytdl-sub-directories = {
    requiredBy = [ "${acaytUnit}.service" ];
    before = [ "${acaytUnit}.service" ];
    unitConfig.RequiresMountsFor = [ libDir ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.coreutils}/bin/install -d -m 0750 -o ytdl-sub -g jellyfin \
        ${mediaDir} \
        ${workDir}
    '';
  };

  # Require the media disk so downloads cannot land on the root filesystem if it is absent.
  systemd.services.${acaytUnit} = {
    # Start on activation/boot as well as the timer; archives skip fetched videos.
    wantedBy = [ "multi-user.target" ];
    unitConfig.RequiresMountsFor = [ libDir ];
  };

  systemd.services.jellyfin.serviceConfig.SupplementaryGroups = [ "render" ];
  systemd.services.jellyfin.unitConfig.RequiresMountsFor = [ "${libDir}/jellyfin" ];

  networking.firewall = {
    interfaces.tailscale0.allowedTCPPorts = [ 8096 ];
    # Keep the LAN exception scoped to Jellyfin's HTTP port.
    extraCommands = ''
      iptables -A nixos-fw -p tcp -s 10.0.0.185/32 --dport 8096 -j nixos-fw-accept
    '';
  };
}
