{
  lib,
  machine,
  paths,
  pkgs,
}:

let
  edit = target: "hx-open ${lib.escapeShellArg target}";
  enter = target: "cd ${lib.escapeShellArg target}";

  coreAliases = {
    ask = "pi -p";
    cl = "clear";
    co = "codex";
    comfy = "nix run github:utensils/comfyui-nix#cuda --disable-xformers --use-pytorch-cross-attention";
    df = "duf";
    du = "dust";
    du1 = "dust -d 1 .";
    e = "exit";
    ff = "fastfetch";
    hx = "hx-open";
    hxl = "hx-last";
    hxr = "hx-recent";
    ip4 = "dig -4 +short TXT o-o.myaddr.l.google.com @ns1.google.com";
    ip6 = "dig -6 +short TXT o-o.myaddr.l.google.com @ns1.google.com";
    j = "just";
    jh = "just --help";
    lj = "lazyjj";
    ll = "eza -l";
    ls = "eza";
    lst = "eza -T -L=2 -l --icons --git";
    lt = "eza -T -L=2 --icons --git-ignore --group-directories-first -a -I '.git|.jj' --color=always";
    nso = "nix store optimise";
    py = "python3";
    python = "python3";
    skup = "bunx --bun skills@latest update";
    todo = "dooit";
    whtr = "curl wttr.in/Santa+Cruz";
    ytm = "yt-music";
    ytv = "yt-video";
    zoa = "zoxide add";
  };

  navigationAliases = {
    ".." = "cd ..";
    "..." = "cd ../..";
    "...." = "cd ../../..";
    "....." = "cd ../../../..";

    desk = enter "${paths.home}/Desktop";
    hm = enter paths.hm;
    nx = enter paths.nixrt;
  };

  workflowAliases = {
    dhm = "home-profile switch";
    hms = "home-profile activate";
    nca = "home-profile clean";
    ndr = "home-profile switch";
    nfu = "home-profile update";
    nsh = "home-profile shell";
    port = "list-ports";
    sec = "home-profile secrets";
  };

  repoFiles = {
    flake = "flake.nix";
  };

  machineFiles = {
    home = "machines/${machine.name}/home.nix";
  };

  hmFiles = {
    baseco = "_base.nix";
    devco = "_dev.nix";
    linuxco = "_linux-desktop.nix";

    alco = "alias.nix";
    fico = "file-tools.nix";
    hco = "helix.nix";
    knco = "knowledge-tools.nix";
    meco = "media.nix";
    navco = "navigation.nix";
    nuco = "nushell.nix";
    paco = "paths.nix";
    secco = "security.nix";
    shco = "ssh.nix";
    synco = "sync.nix";
    yzco = "yazi.nix";
    zco = "zsh.nix";
  };

  osFiles = {
    bco = "darwin/homebrew.nix";
    foco = "darwin/fonts.nix";
    sysco = "darwin/system.nix";
    ssco = "darwin/sshd.nix";
  };

  dotFiles = {
    aco = "aerospace/aerospace.toml";
    aico = "AI";
    cco = "codex";
    ghco = "ghostty/config";
    glco = "glance/glance.yml";
    rco = "rio/config.toml";
    sbco = "sketchybar";
    wsco = "nushell/zellij-workspaces.toml";
    zelco = "zellij";
    zkco = "zk/config.toml";
  };

  mkEditorAliases = basePath: files: builtins.mapAttrs (_: file: edit "${basePath}/${file}") files;

  mkToolAliases =
    toolGroups:
    builtins.foldl' (
      aliases: tool: aliases // builtins.mapAttrs (_: command: "${tool} ${command}") toolGroups.${tool}
    ) { } (builtins.attrNames toolGroups);

  toolAliases = mkToolAliases {
    bun = {
      ba = "add";
      bb = "run build";
      bd = "run dev";
      bf = "run format";
      bi = "install";
      big = "install -g";
      bigt = "install -g --trust";
      bl = "pm list";
      bp = "run preview";
      br = "run";
      bt = "test";
      bu = "update";
    };

    codex = {
      col = "exec -c model_reasoning_effort=low";
      cor = "resume";
    };

    git = {
      ga = "add";
      gc = "commit -m";
      gdiff = "diff HEAD";
      gl = "pull";
      glog = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      gp = "push";
      ig = "status --ignored";
      stat = "status";
      vdiff = "difftool HEAD";
    };

    go = {
      gb = "build";
      gr = "run";
      gt = "test";
      gta = "test ./...";
      gtb = "test -bench=.";
    };

    hunk = {
      hd = "diff";
      hdw = "diff --watch";
    };

    jj = {
      ja = "abandon";
      jb = "bookmark";
      jbl = "bookmark list";
      jbr = "bookmark rename";
      jbs = "bookmark set";
      jbt = "bookmark track";
      jc = "commit -m";
      jd = "desc";
      jdm = "describe -m";
      jdf = "diff";
      je = "edit";
      jeu = "config edit --user";
      jf = "file";
      jft = "file track";
      jgf = "git fetch";
      jgi = "git init --colocate";
      jgp = "git push";
      jl = "log";
      jla = "log -r ::";
      jn = "new";
      jop = "op";
      jopr = "op restore";
      jrb = "rebase";
      jrs = "resolve";
      jsp = "split";
      jsq = "squash";
      jst = "status";
      ju = "undo";
      jw = "workspace";
      jwa = "workspace add";
      jwu = "workspace update-stale";
    };

    pi = {
      pu = "update";
    };

    uv = {
      uva = "add";
      uve = "venv";
      uvi = "init";
      uvr = "run";
      uvs = "sync";
      uvt = "tree";
      uvu = "sync --upgrade";
      uvx = "tool run";
    };
  };

  platformAliases =
    lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
      afk = "lock-screen";
      airport = "/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport";
      clip = "pbcopy";
      localip = "ipconfig getifaddr en0";
      lg-input = "ssh ${(builtins.head machine.peers).name} lg-input";
    }
    // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
      clip = "wl-copy";
    };

  common =
    coreAliases
    // navigationAliases
    // workflowAliases
    // platformAliases
    // mkEditorAliases paths.nixrt repoFiles
    // mkEditorAliases paths.nixrt machineFiles
    // mkEditorAliases paths.hm hmFiles
    // mkEditorAliases paths.os osFiles
    // mkEditorAliases paths.dots dotFiles
    // toolAliases;
in
{
  inherit common;

  nushell = {
    cdi = "zi";
    yy = "y";
  };

  zsh = {
    cdi = "zi";
    yy = "y";
  };
}
