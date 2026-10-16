import { expect, test } from "bun:test";
import { fileURLToPath } from "node:url";

const repo = fileURLToPath(new URL("../", import.meta.url)).replace(/\/$/, "");

function runJSON(command: string[]) {
  const result = Bun.spawnSync(command, { timeout: 120_000 });
  expect(result.exitCode, result.stderr.toString()).toBe(0);
  return JSON.parse(result.stdout.toString());
}

function evaluate(expression: string) {
  return runJSON([
    "nix", "eval", "--json", "--offline", "--no-write-lock-file",
    "--option", "allow-import-from-derivation", "false",
    "--option", "max-jobs", "0", "--option", "builders", "",
    `${repo}#nixosConfigurations.laurentii.config`, "--apply", expression,
  ]);
}

test("Laurentii preserves its installation and uses the shared NixOS home", () => {
  const config = evaluate(`c:
    let hm = c.home-manager.users.kenrict; in {
      failures = map (a: a.message) (builtins.filter (a: !a.assertion) c.assertions);
      hostname = c.networking.hostName;
      systemState = c.system.stateVersion;
      homeState = hm.home.stateVersion;
      rootDevice = c.fileSystems."/".device;
      bootDevice = c.fileSystems."/boot".device;
      homeSubvolume = c.fileSystems."/home".options;
      nixSubvolume = c.fileSystems."/nix".options;
      npu = c.hardware.cpu.intel.npu.enable;
      session = c.services.displayManager.defaultSession;
      thunderbolt = (c.systemd.services.network-addresses-thunderbolt0 or {}).script or "";
      ly = c.services.displayManager.ly.enable;
      user = hm.home.username;
      repo = hm.home.sessionVariables.NX;
      dots = hm.home.sessionVariables.DOT;
      sessionPath = hm.home.sessionPath;
      run = hm.programs.bash.shellAliases.run;
      genericLinux = hm.targets.genericLinux.enable;
      globalPackages = c.home-manager.useGlobalPkgs;
      userPackages = c.home-manager.useUserPackages;
      systemCleanup = c.programs.nh.clean.enable;
      homeCleanup = hm.programs.nh.clean.enable;
      nhFlake = c.programs.nh.flake;
      helix = hm.programs.helix.enable;
      direnv = hm.programs.direnv.enable;
      ghostty = hm.programs.ghostty.enable;
      lgInput = builtins.any (p: (p.pname or p.name or "") == "lg-input") hm.home.packages;
      lgCompletion = builtins.match ".*nu-complete lg-input.*" hm.programs.nushell.extraConfig != null;
      ddcutil = builtins.any (p: (p.pname or p.name or "") == "ddcutil") c.environment.systemPackages;
      i2c = c.hardware.i2c.enable;
      groups = c.users.users.kenrict.extraGroups;
    }`);

  expect(config.failures).toEqual([]);
  expect(config.hostname).toBe("nixos");
  expect(config.systemState).toBe("26.05");
  expect(config.homeState).toBe("26.11");
  expect(config.rootDevice).toBe("/dev/disk/by-uuid/67bc2e8d-192d-40c2-ba12-0602e079b0fb");
  expect(config.bootDevice).toBe("/dev/disk/by-uuid/5D38-460D");
  expect(config.homeSubvolume).toContain("subvol=home");
  expect(config.nixSubvolume).toContain("subvol=nix");
  expect(config.npu).toBe(true);
  expect(config.session).toBe("niri");
  expect(config.thunderbolt).toContain("10.10.10.4/24");
  expect(config.ly).toBe(true);
  expect(config.user).toBe("kenrict");
  expect(config.repo).toBe("/home/kenrict/laurentii");
  expect(config.dots).toBe(`${config.repo}/dots`);
  expect(config.sessionPath).toContain("/etc/profiles/per-user/kenrict/opt/codex-desktop/resources/cua_node/bin");
  expect(config.run).toContain(`${config.repo}#laurentii`);
  expect(config.genericLinux).toBe(false);
  expect(config.globalPackages).toBe(true);
  expect(config.userPackages).toBe(true);
  expect(config.systemCleanup).toBe(false);
  expect(config.homeCleanup).toBe(false);
  expect(config.nhFlake).toBe(`${config.repo}#laurentii`);
  expect(config.helix && config.direnv && config.ghostty).toBe(true);
  expect(config.lgInput && config.lgCompletion).toBe(true);
  expect(config.ddcutil && config.i2c).toBe(true);
  expect(config.groups).toContain("i2c");
}, 120_000);

test("Jellyfin uses one automatic downloader for channels and courses", () => {
  const config = evaluate(`c:
    let
      names = builtins.filter (n: builtins.match "ytdl-sub.*" n != null) (builtins.attrNames c.systemd.services);
      feed = c.systemd.services.ytdl-sub-acayt;
      directories = c.systemd.services.ytdl-sub-directories;
    in {
      inherit names;
      inherit (directories) requiredBy before;
      instances = builtins.attrNames c.services.ytdl-sub.instances;
      subscriptions = c.services.ytdl-sub.instances.acayt.subscriptions;
      start = feed.serviceConfig.ExecStart;
      mounts = feed.unitConfig.RequiresMountsFor;
      wantedBy = feed.wantedBy;
      condition = feed.unitConfig.ConditionPathExists or null;
      postStop = feed.postStop;
      timer = c.systemd.timers.ytdl-sub-acayt.timerConfig.OnCalendar;
    }`);

  const unit = "ytdl-sub-acayt";
  expect(config.instances).toEqual(["acayt"]);
  expect(config.names).toEqual([unit, "ytdl-sub-directories"]);
  expect(config.requiredBy).toEqual([`${unit}.service`]);
  expect(config.before).toEqual(config.requiredBy);
  expect(config.start).toContain("/bin/ytdl-sub --config ");
  expect(config.mounts).toEqual(["/mnt/library"]);
  expect(config.wantedBy).toContain("multi-user.target");
  expect(config.timer).toEqual(["0/6:0"]);
  expect(config.condition).toBeNull();
  expect(config.postStop).toBe("");
  expect(config.subscriptions.__preset__.overrides.tv_show_directory).toBe("/mnt/library/jellyfin/yt");
  const channel = config.subscriptions["Jellyfin TV Show by Date | Max 2160p"]["~3Blue1Brown"];
  const course = config.subscriptions["Jellyfin TV Show Collection | Max 2160p"]["Neural Networks - Zero to Hero"];
  expect(channel.download_since).toBe("20260913");
  expect(course.overrides.download_since).toBe("19700101");
  expect(course.overrides.tv_show_collection_episode_ordering).toBe("playlist-index");
  expect(course.ytdl_options.break_on_existing).toBe(false);
}, 120_000);
