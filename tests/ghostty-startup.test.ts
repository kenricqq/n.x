import { expect, test } from "bun:test";
import { mkdirSync, mkdtempSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";

const config = await Bun.file(new URL("../dots/ghostty/config", import.meta.url)).text();
interface Startup {
  text: string;
  target: string;
  executable: string;
  configHome: string;
  symlinkSource: string;
  configDirs: string[];
}

const profiles: Record<string, Startup> = {};
for (const [platform, attribute] of Object.entries({
  darwin: "darwinConfigurations.m0nix.config.home-manager.users.kenrictee",
  linux: "homeConfigurations.meridian.config",
})) {
  const evaluation = Bun.spawnSync(
    [
      "nix",
      "eval",
      "--json",
      "--no-write-lock-file",
      `${new URL("../", import.meta.url).pathname}#${attribute}`,
      "--apply",
      `c:
      let files = builtins.attrValues c.home.file;
      in {
        text = c.xdg.configFile."ghostty-nix.conf".text;
        target = c.xdg.configFile."ghostty-nix.conf".target;
        executable = "\${c.programs.nushell.package}/bin/nu";
        configHome = c.xdg.configHome;
        symlinkSource = toString (builtins.head (builtins.filter
          (file: file.target == ".config/ghostty") files)).source;
        configDirs = builtins.filter (path: builtins.any (file: file.target == path) files) [
          ".config/ghostty"
          "Library/Application Support/com.mitchellh.ghostty"
        ];
      }`,
    ],
    { timeout: 120_000 },
  );
  if (evaluation.exitCode !== 0) {
    throw new Error(`${platform} Home Manager evaluation failed: ${evaluation.stderr}`);
  }
  profiles[platform] = JSON.parse(evaluation.stdout.toString());
}

function checkStartup(profile: Startup, integration = false) {
  const home = mkdtempSync(join(tmpdir(), "ghostty-nu-"));
  try {
    const bin = join(home, "bin");
    mkdirSync(bin);
    writeFileSync(join(bin, "nu"), '#!/bin/sh\nprintf "ARG=%s\\n" "$@"\n', { mode: 0o755 });

    // Includes load after their parent, overriding the pre-activation fallback.
    const effectiveConfig = `${config}\n${profile.text}`;
    const command = [...effectiveConfig.matchAll(/^command\s*=\s*(.+)$/gm)].at(-1)?.[1];
    expect(command).toStartWith(`${profile.executable} --login`);
    // Replace only the evaluated executable; Linux binaries cannot run on macOS.
    let shellCommand = command!.replace(profile.executable, join(bin, "nu"));
    if (integration) {
      // Ghostty 1.3.1 groups double-quoted arguments, strips their quotes,
      // then inserts --execute immediately after the executable.
      const [executable, ...args] = shellCommand
        .match(/"[^"]*"|\S+/g)!
        .map((arg) => arg.replaceAll('"', ""));
      shellCommand = `${executable} --execute 'use ghostty *' ${args.join(" ")}`;
    }
    const result = Bun.spawnSync(["/bin/sh", "-c", shellCommand], {
      env: {
        HOME: home,
        PATH: "/usr/bin:/bin",
        // The managed config directory must win over the inherited environment.
        XDG_CONFIG_HOME: join(home, "unmanaged-config"),
      },
      timeout: 5000,
    });
    expect(result.exitCode, result.stderr.toString()).toBe(0);
    expect(result.stdout.toString()).toBe(
      (integration ? "ARG=--execute\nARG=use ghostty *\n" : "") +
        `ARG=--login\nARG=--config-home\nARG=${profile.configHome}/nushell\n`,
    );
  } finally {
    rmSync(home, { recursive: true, force: true });
  }
}

test("includes generated startup without replacing the live Ghostty directory", () => {
  expect(config).toMatch(/^config-file = \?~\/\.config\/ghostty-nix\.conf$/m);
  expect(config).toMatch(/^command = nu --login$/m);
  expect(config).toMatch(/^shell-integration = nushell$/m);
  expect(config).not.toMatch(/^env\s*=\s*(PATH|XDG_CONFIG_HOME)=/m);
  for (const profile of Object.values(profiles)) {
    expect(profile.target).toBe(".config/ghostty-nix.conf");
    expect(profile.executable).toMatch(/^\/nix\/store\/[^/]+-nushell-[^/]+\/bin\/nu$/);
    expect(profile.symlinkSource).toMatch(/^\/nix\/store\/[^/]+-hm_ghostty$/);
  }
});

const ghostty = Bun.which("ghostty");
for (const [platform, profile] of Object.entries(profiles)) {
  test.skipIf(!ghostty)(
    `${platform}: loads configured paths together without an include cycle`,
    () => {
      const home = mkdtempSync(join(tmpdir(), "ghostty-includes-"));
      try {
        const live = join(home, "repo/ghostty");
        mkdirSync(live, { recursive: true });
        writeFileSync(join(live, "config"), config);
        symlinkSync(
          new URL("../dots/ghostty/themes", import.meta.url).pathname,
          join(live, "themes"),
        );
        for (const dir of profile.configDirs) {
          const target = join(home, dir);
          mkdirSync(dirname(target), { recursive: true });
          symlinkSync(live, target);
        }
        writeFileSync(join(home, profile.target), profile.text);
        const root = join(home, "config");
        // Load all configured default locations in one pass, as the macOS GUI does.
        writeFileSync(
          root,
          profile.configDirs.map((dir) => `config-file = ${join(home, dir, "config")}\n`).join(""),
        );
        const result = Bun.spawnSync([ghostty!, "+validate-config", `--config-file=${root}`], {
          env: { HOME: home, PATH: "/usr/bin:/bin" },
          timeout: 5000,
        });
        const diagnostics = result.stdout.toString() + result.stderr.toString();
        expect(diagnostics).not.toContain("cycle detected");
        expect(result.exitCode, diagnostics).toBe(0);
      } finally {
        rmSync(home, { recursive: true, force: true });
      }
    },
  );

  test(`${platform}: launches generated login command with minimal PATH and managed config`, () => {
    checkStartup(profile);
  });

  test(`${platform}: forwards Nushell integration arguments`, () => {
    checkStartup(profile, true);
  });
}
