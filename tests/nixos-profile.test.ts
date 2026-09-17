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
  expect(config.ly).toBe(true);
  expect(config.user).toBe("kenrict");
  expect(config.repo).toBe("/home/kenrict/laurentii");
  expect(config.dots).toBe(`${config.repo}/dots`);
  expect(config.sessionPath).toContain("/etc/profiles/per-user/kenrict/opt/codex-desktop/resources/cua_node/bin");
  expect(config.run).toContain(`${config.repo}#laurentii`);
  expect(config.genericLinux).toBe(false);
  expect(config.globalPackages).toBe(true);
  expect(config.userPackages).toBe(true);
  expect(config.systemCleanup).toBe(true);
  expect(config.homeCleanup).toBe(false);
  expect(config.nhFlake).toBe(`${config.repo}#laurentii`);
  expect(config.helix && config.direnv && config.ghostty).toBe(true);
}, 120_000);
