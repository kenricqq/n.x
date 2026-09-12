{
  config,
  lib,
  pkgs,
  paths,
  ...
}:

let
  inherit (paths)
    home
    ;
in
{
  ## -- MPD -- ##

  services = {
    mpd = {
      enable = true;
      musicDirectory = "${home}/Music/mpd";
      # dataDir = "${home}/.mpd"; # Default: "$XDG_DATA_HOME/mpd"
      # dbFile = "${home}/.mpd/database";
      playlistDirectory = "${home}/Music/mpd/playlists";
      extraArgs = [
        "--stderr"
        "--verbose"
      ];
      network = {
        listenAddress = "127.0.0.1";
        port = 6600;
      };
      extraConfig = ''
        auto_update             "yes"
        auto_update_depth       "2"
        follow_outside_symlinks "yes"
        follow_inside_symlinks  "yes"

        decoder {
          plugin                "mp4ff"
          enabled               "no"
        }


        ${lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
          audio_output {
            type       "osx"
            name       "CoreAudio"
            mixer_type "software"
          }
        ''}

        ${lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
          audio_output {
            type       "pipewire"
            name       "PipeWire"
            mixer_type "software"
          }
        ''}
      '';
      # playlistDirectory = ""; # Default: "\${dataDir}/playlists"
    };
  };

  xdg.configFile."mpd/mpd.conf".text = config.services.mpd.generatedConfig;

  home.file = {
    ".mpd/.keep".text = "";
  } // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
    "Library/Logs/mpd/.keep".text = "";
  };

  launchd.agents.mpd.config.StandardErrorPath = "${config.services.mpd.dataDir}/log.txt";

  ## -- *** -- ##

  programs = {
    rmpc = {
      enable = true;
      config = ''
        (
            address: "127.0.0.1:6600",
            password: None,
            theme: None,
            cache_dir: None,
            on_song_change: None,
            volume_step: 5,
            max_fps: 30,
            scrolloff: 0,
            wrap_navigation: false,
            enable_mouse: true,
            enable_config_hot_reload: true,
            status_update_interval_ms: Some(1000),
            select_current_song_on_change: false,
            browser_song_sort: [Disc, Track, Artist, Title],
        )
      '';
    };

    rtorrent = {
      enable = true;
      extraConfig = "";
    };

    yt-dlp = {
      # enable = true;
      extraConfig = ''
        --update
        -F
      '';
      settings = {
        color = [
          "stdout:no_color"
          "stderr:always"
        ];
        downloader = "aria2c";
        downloader-args = "aria2c:'-c -x8 -s8 -k1M'";
        embed-subs = true;
        embed-thumbnail = true;
        sub-langs = "all";
      };
    };

    # mpv = {
    #   enable = true;
    # };

  };

  home.packages = with pkgs; [
    mpc # mpd cli interface
    ffmpeg # vid processing
    mediainfo # vid metadata
    imagemagick # img transform
    upscayl # img upscaler
    termshot # terminal screenshots
  ];
}
