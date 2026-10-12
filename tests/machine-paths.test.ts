import { expect, test } from "bun:test";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const repo = fileURLToPath(new URL("../", import.meta.url));

function runJSON(command: string[]) {
  const result = Bun.spawnSync(command, { timeout: 120_000 });
  expect(result.exitCode, result.stderr.toString()).toBe(0);
  return JSON.parse(result.stdout.toString());
}

function evaluate(attribute: string, expression: string) {
  return runJSON([
    "nix",
    "eval",
    "--json",
    "--no-write-lock-file",
    "--option",
    "allow-import-from-derivation",
    "false",
    `${repo}#${attribute}`,
    "--apply",
    expression,
  ]);
}

const darwinPaths = `c:
  let
    hm = c.home-manager.users.kenrictee;
    agents = builtins.listToAttrs (map (name: {
      inherit name;
      value = c.launchd.user.agents.\${name}.serviceConfig;
    }) [ "glance" "memos" "golink" ]);
  in {
    home = c.users.users.kenrictee.home;
    stateVersion = c.system.stateVersion;
    primaryUser = c.system.primaryUser;
    touchId = c.security.pam.services.sudo_local.touchIdAuth;
    hmHome = hm.home.homeDirectory;
    configHome = hm.xdg.configHome;
    ageKeyFile = hm.sops.age.keyFile;
    shellAgeKeyFile = hm.home.sessionVariables.SOPS_AGE_KEY_FILE;
    raindropTokenPath = hm.sops.secrets.RAINDROP_TOKEN.path;
    tsAuthKeyPath = hm.sops.secrets.TS_AUTHKEY.path;
    minifluxEnabled = c.launchd.user.agents ? miniflux;
    postgresDataDir = c.services.postgresql.dataDir;
    postgresAgentDataDir = c.launchd.user.agents.postgresql.serviceConfig.EnvironmentVariables.PGDATA;
    repo = hm.home.sessionVariables.NX;
    dots = hm.home.sessionVariables.DOT;
    brewConfigHome = c.homebrew.onActivation.extraEnv.XDG_CONFIG_HOME;
    brewActivation = c.system.activationScripts.homebrew.text;
    launchdActivation = c.system.activationScripts.launchd.text;
    inherit agents;
    launcherDrvs = builtins.mapAttrs (_: agent:
      builtins.attrNames (builtins.getContext (builtins.head agent.ProgramArguments))
    ) { inherit (agents) glance golink; };
  }`;

function expectDarwinPaths(config: ReturnType<typeof evaluate>, checkout = "m0nix") {
  expect(config.stateVersion).toBe(6);
  expect(config.primaryUser).toBe("kenrictee");
  expect(config.touchId).toBe(true);
  expect(config.hmHome).toBe(config.home);
  expect(config.repo).toBe(`${config.home}/${checkout}`);
  expect(config.dots).toBe(`${config.repo}/dots`);
  expect(config.ageKeyFile).toBe(`${config.repo}/secrets/keys.txt`);
  expect(config.shellAgeKeyFile).toBe(config.ageKeyFile);
  expect(config.brewConfigHome).toBe(config.configHome);
  expect(config.brewActivation).toContain(`XDG_CONFIG_HOME=${config.configHome}`);
  expect(config.brewActivation).toContain("HOMEBREW_NO_AUTO_UPDATE=1");
  expect(config.brewActivation).toContain("--no-upgrade");
  expect(config.launchdActivation.length).toBeGreaterThan(0);
  expect(config.minifluxEnabled).toBe(false);
  expect(config.postgresDataDir).toBe(`${config.repo}/extensions/postgresql/18`);
  expect(config.postgresAgentDataDir).toBe(config.postgresDataDir);

  for (const name of ["glance", "memos", "golink"]) {
    const agent = config.agents[name];
    expect(agent.EnvironmentVariables.HOME).toBe(config.home);
    expect(agent.WorkingDirectory).toBe(
      `${config.repo}/${name === "golink" ? "extensions/golink" : "hm"}`,
    );
  }

  // Inspect generated scripts without building packages or launching anything.
  for (const name of ["glance", "golink"]) {
    const paths: string[] = config.launcherDrvs[name];
    expect(paths).toHaveLength(1);
    const result = runJSON(["nix", "derivation", "show", ...paths]);
    // Nix versions use either absolute paths or basenames as derivation keys.
    const derivations: Record<string, {
      env: { text: string };
      structuredAttrs?: { text: string };
    }> = result.derivations ?? result;
    expect(Object.keys(derivations)).toHaveLength(1);
    const derivation = Object.values(derivations)[0];
    const script = (derivation.structuredAttrs ?? derivation.env).text;
    expect(script).not.toContain(`${config.repo}/hm/dots/`);
    if (name === "glance") {
      expect(script).toContain(`${config.dots}/glance/glance.yml`);
      expect(script).not.toContain(".cache/zsh/secrets.env");
    } else {
      expect(script).toContain(`--sqlitedb '${config.repo}/extensions/golink/golinks.sqlite'`);
    }
    const secretPath = name === "glance" ? config.raindropTokenPath : config.tsAuthKeyPath;
    expect(script).toContain(secretPath);
    expect(config.agents[name].KeepAlive).toBe(true);
    expectSecretLoading(script, secretPath, name === "glance" ? "RAINDROP_TOKEN" : "TS_AUTHKEY");
  }
}

function expectSecretLoading(script: string, secretPath: string, variable: "RAINDROP_TOKEN" | "TS_AUTHKEY") {
  const dir = mkdtempSync(join(tmpdir(), "service-secrets-"));
  const bash = Bun.which("bash")!;
  try {
    const tokenPath = join(dir, "token");
    // Exercise the generated loader; replace only its input path and final app.
    const fixture = script.replaceAll(secretPath, tokenPath).replace(
      /^\s*exec .*$/m,
      `exec ${bash} -c '[[ "$${variable}" == "$EXPECTED_TOKEN" ]]'`,
    );
    expect(fixture).not.toBe(script);
    const run = () => Bun.spawnSync([bash, "-c", fixture], {
      env: { HOME: dir, PATH: "/usr/bin:/bin", EXPECTED_TOKEN: "fixture $value 'quoted'" },
      timeout: 5_000,
    });
    // launchd may start the service before sops-nix. Fail so KeepAlive retries.
    const missing = run();
    expect(missing.exitCode).toBe(1);
    expect(missing.stderr.toString()).toContain(tokenPath);
    writeFileSync(tokenPath, "fixture $value 'quoted'\n", { mode: 0o600 });
    const ready = run();
    expect(ready.exitCode, ready.stderr.toString()).toBe(0);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

test("Darwin activation and launch scripts use the machine paths", () => {
  expectDarwinPaths(evaluate("darwinConfigurations.m0nix.config", darwinPaths));
}, 120_000);

test("Darwin paths follow configured home and Home Manager XDG overrides", () => {
  const config = evaluate(
    "darwinConfigurations.m0nix",
    `d:
      let
        changed = d.extendModules {
          modules = [ ({ lib, ... }: {
            users.users.kenrictee.home = lib.mkForce "/Users/path-check";
            home-manager.users.kenrictee = {
              home.homeDirectory = lib.mkForce "/Users/path-check";
              xdg.configHome = lib.mkForce "/Users/path-check/custom-config";
              sops.secrets.RAINDROP_TOKEN.path = lib.mkForce "/Users/path-check/custom-secrets/raindrop";
              sops.secrets.TS_AUTHKEY.path = lib.mkForce "/Users/path-check/custom-secrets/golink";
            };
          }) ];
        };
      in (${darwinPaths}) changed.config`,
  );
  expect(config.home).toBe("/Users/path-check");
  expect(config.configHome).toBe("/Users/path-check/custom-config");
  expectDarwinPaths(config);
}, 120_000);

test("Darwin system and Home Manager paths share a custom checkout", () => {
  const config = evaluate(
    "darwinConfigurations.m0nix",
    `d:
      let
        machine = d.config.home-manager.extraSpecialArgs.machine // {
          repo = "custom/checkout";
        };
        changed = d.extendModules {
          modules = [ ({ lib, ... }: {
            _module.args.machine = lib.mkForce machine;
            home-manager.extraSpecialArgs = lib.mkForce (
              d.config.home-manager.extraSpecialArgs // { inherit machine; }
            );
          }) ];
        };
      in (${darwinPaths}) changed.config`,
  );
  expectDarwinPaths(config, "custom/checkout");
}, 120_000);

test("standalone Linux Home Manager retains its machine layout", () => {
  const config = evaluate(
    "homeConfigurations.meridian.config",
    `c: {
      home = c.home.homeDirectory;
      inherit (c.home.sessionVariables) NX HM DW DOT SCRIPTS SNIPPETS_PATH SOPS_AGE_KEY_FILE;
      ageKeyFile = c.sops.age.keyFile;
      # Checking names avoids forcing every package's store path and dependencies.
      nvidiaSyncPackages = map (package: package.name) (
        builtins.filter (package: package.name == "nvidia-sync") c.home.packages
      );
      nvidiaSyncCondition = c.systemd.user.services.nvidia-home-manager-reminder.Unit.ConditionPathExists;
      nvidiaSyncNotification = builtins.head c.systemd.user.services.nvidia-home-manager-reminder.Service.ExecStart;
      nvidiaSyncTimer = c.systemd.user.timers.nvidia-home-manager-reminder.Timer.OnCalendar;
    }`,
  );
  const root = `${config.home}/meridian`;
  expect(config.NX).toBe(root);
  expect(config.ageKeyFile).toBe(`${root}/secrets/keys.txt`);
  expect(config.SOPS_AGE_KEY_FILE).toBe(config.ageKeyFile);
  expect(config.HM).toBe(`${root}/hm`);
  expect(config.DW).toBe(`${root}/os/darwin`);
  expect(config.DOT).toBe(`${root}/dots`);
  expect(config.SCRIPTS).toBe(`${root}/scripts`);
  expect(config.SNIPPETS_PATH).toBe(`${root}/hm/snippets`);
  expect(config.nvidiaSyncPackages).toEqual(["nvidia-sync"]);
  expect(config.nvidiaSyncCondition).toContain("/var/lib/nvidia-home-manager-sync-required");
  expect(config.nvidiaSyncNotification).toContain("notify-send");
  expect(config.nvidiaSyncNotification).toContain("nvidia-sync");
  expect(config.nvidiaSyncTimer).toBe("*:0/30");
}, 120_000);
