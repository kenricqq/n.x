{
  inputs,
  machine,
  paths,
  pkgs,
  ...
}:

let
  inherit (machine)
    system
    ;
  # system = pkgs.stdenv.hostPlatform.system;
  dooitWithExtras = inputs.dooit.packages.${system}.default.override {
    extraPackages = [
      inputs.dooit-extras.packages.${system}.default
    ];
  };
in
{
  xdg.dataFile."memos" = paths.mkDotFile "memos";

  home.packages = with pkgs; [
    # (dooit.override { extraPackages = [ dooit-extras ]; })
    dooitWithExtras

    golink # private shortlink service for tailnet
    memos # memo hub
    glance # browser dashboard

    # miniflux # rss backend

    graphify # codebase to knowledge graph

    # zk # note-taking assistant
    # nb # cli local note-taking
    # bmm # cli bookmark manager
    # texliveFull # comprehensive latex system, pdf engine
    # jrnl # collect thoughts and notes in terminal
    # todoist

    # circumflex # browse hacker news
    # graphviz # graph visualization tool
  ];

  programs = {
    eilmeldung = {
      enable = false;
      settings = {
        # after_sync_commands = [
        #   "query lastsync"
        #   "tag rust title:\"rust\""
        #   "read title:/^Advertisement/"
        #   "refresh"
        # ];
        # audio_enclosure_command = "mpv --no-audio {url}";
        # feed_list = [
        #   "query: \"Marked\" marked"
        #   "query: \"Reviews\" #reviews"
        #   "feeds"
        #   "* categories"
        #   "tags"
        # ];
        # input_config = {
        #   mappings = {
        #     "; i" = [
        #       "cmd hintshare feh"
        #     ];
        #     y = [
        #       "confirm in articles read all"
        #       "nextunread"
        #     ];
        #   };
        # };
        # mouse_support = true;
        # share_targets = [
        #   "clipboard"
        #   "feh feh \"{url}\""
        # ];
        # startup_commands = [
        #   "sync"
        # ];
        # video_enclosure_command = "mpv {url}";
      };
    };
  };
}
