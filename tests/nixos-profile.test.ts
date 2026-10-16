import { expect, test } from "bun:test";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const repo = fileURLToPath(new URL("../", import.meta.url)).replace(/\/$/, "");

function runJSON(command: string[]) {
  const result = Bun.spawnSync(command, { timeout: 120_000 });
  expect(result.exitCode, result.stderr.toString()).toBe(0);
  return JSON.parse(result.stdout.toString());
}

function evaluate(expression: string, attribute = "nixosConfigurations.laurentii.config") {
  return runJSON([
    "nix", "eval", "--json", "--offline", "--no-write-lock-file",
    "--option", "allow-import-from-derivation", "false",
    "--option", "max-jobs", "0", "--option", "builders", "",
    `${repo}#${attribute}`, "--apply", expression,
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
  expect(config.groups).toContain("jellyfin");
}, 120_000);

test("jescan sends authenticated requests and reports failures", async () => {
  const { drvPath, apiKeyPath } = evaluate(`c: {
    drvPath = (builtins.head (builtins.filter
      (p: (p.pname or p.name or "") == "jescan") c.environment.systemPackages)).drvPath;
    apiKeyPath = c.home-manager.users.kenrict.sops.secrets.JELLYFIN_API_KEY.path;
  }`);
  const result = runJSON(["nix", "derivation", "show", drvPath]);
  const derivations: Record<string, { env: { text: string }; structuredAttrs?: { text: string } }> =
    result.derivations ?? result;
  const derivation = Object.values(derivations)[0];
  const script = (derivation.structuredAttrs ?? derivation.env).text;
  expect(script).toContain(apiKeyPath);
  const dir = mkdtempSync(join(tmpdir(), "jescan-"));
  const keyFile = join(dir, "api-key");
  const token = "0123456789abcdef0123456789abcdef";
  const requests: { method: string; path: string; authorization: string | null; body: string }[] = [];
  let responseStatus = 204;
  const server = Bun.serve({
    hostname: "127.0.0.1",
    port: 0,
    async fetch(request) {
      requests.push({
        method: request.method,
        path: new URL(request.url).pathname,
        authorization: request.headers.get("Authorization"),
        body: await request.text(),
      });
      return new Response(null, { status: responseStatus });
    },
  });
  try {
    const fixture = script
      .replace(apiKeyPath, keyFile)
      .replace("http://127.0.0.1:8096", `http://127.0.0.1:${server.port}`)
      .replace(/^export PATH=.*$/m, 'export PATH="$RESCAN_TEST_PATH"');
    expect(fixture).not.toContain(apiKeyPath);
    expect(fixture).not.toContain("http://127.0.0.1:8096");
    const run = async () => {
      const process = Bun.spawn([Bun.which("bash")!, "-c", fixture], {
        env: { RESCAN_TEST_PATH: Bun.env.PATH! },
        stdout: "pipe", stderr: "pipe", timeout: 5_000,
      });
      const [exitCode, stdout, stderr] = await Promise.all([
        process.exited, new Response(process.stdout).text(), new Response(process.stderr).text(),
      ]);
      expect(stdout + stderr).not.toContain(token);
      return { exitCode, stdout, stderr };
    };
    const missing = await run();
    expect(missing.exitCode).toBe(1);
    expect(missing.stderr).toContain("Missing or empty SOPS secret JELLYFIN_API_KEY");
    expect(requests).toHaveLength(0);
    writeFileSync(keyFile, "", { mode: 0o600 });
    expect((await run()).exitCode).toBe(1);
    expect(requests).toHaveLength(0);
    writeFileSync(keyFile, `${token}\n`, { mode: 0o600 });
    const success = await run();
    expect(success.exitCode, success.stderr).toBe(0);
    expect(success.stdout).toBe("Jellyfin library scan requested.\n");
    expect(requests).toEqual([{
      method: "POST", path: "/Library/Refresh", body: "",
      authorization: `MediaBrowser Token="${token}"`,
    }]);
    for (responseStatus of [401, 500]) {
      const failure = await run();
      expect(failure.exitCode).toBe(22);
      expect(failure.stdout).not.toContain("scan requested");
    }
  } finally {
    server.stop(true);
    rmSync(dir, { recursive: true, force: true });
  }
}, 120_000);

test("media refresh commands use SSH on Mac and Meridian and run locally on Laurentii", () => {
  for (const [attribute, remote] of [
    ["nixosConfigurations.laurentii.config.home-manager.users.kenrict", false],
    ["darwinConfigurations.m0nix.config.home-manager.users.kenrictee", true],
    ["homeConfigurations.meridian.config", true],
  ] as const) {
    const aliases = evaluate(`c: map (shell: let a = c.programs.\${shell}.shellAliases; in {
      jescan = a.jescan or null;
      yt-refresh = a.yt-refresh or null;
      inherit (a) yta ytv;
    })
      [ "bash" "zsh" "nushell" ]`, attribute);
    expect(aliases).toEqual(Array(3).fill({
      jescan: remote ? "ssh -t kenrict@laurentii /run/current-system/sw/bin/jescan" : null,
      "yt-refresh": remote ? "ssh -t kenrict@laurentii /run/current-system/sw/bin/yt-refresh" : null,
      yta: "yt-audio",
      ytv: "yt-video",
    }));
  }
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
