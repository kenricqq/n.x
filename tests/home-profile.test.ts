import { expect, test } from "bun:test";
import { mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const repo = fileURLToPath(new URL("../", import.meta.url)).replace(/\/$/, "");
const evaluationOptions = [
  "--offline", "--no-write-lock-file",
  "--option", "allow-import-from-derivation", "false",
  "--option", "max-jobs", "0", "--option", "builders", "",
  "--option", "eval-cache", "false",
];

function runJSON(command: string[]) {
  const result = Bun.spawnSync(command, { timeout: 120_000 });
  expect(result.exitCode, result.stderr.toString()).toBe(0);
  return JSON.parse(result.stdout.toString());
}

const profiles = [
  {
    label: "NixOS",
    attribute: "nixosConfigurations.laurentii.config.home-manager.users.kenrict",
    repo: "/home/kenrict/laurentii",
    switchArgs: ["os", "switch", "/home/kenrict/laurentii#laurentii"],
    activationAttribute: null,
    homeManagerOwnsNh: false,
  },
  {
    label: "nix-darwin",
    attribute: "darwinConfigurations.m0nix.config.home-manager.users.kenrictee",
    repo: "/Users/kenrictee/m0nix",
    switchArgs: ["darwin", "switch", "/Users/kenrictee/m0nix#m0nix"],
    activationAttribute: "darwinConfigurations.m0nix.config.home-manager.users.kenrictee.home.activationPackage",
    homeManagerOwnsNh: true,
  },
  {
    label: "standalone Home Manager",
    attribute: "homeConfigurations.meridian.config",
    repo: "/home/kenrict/meridian",
    switchArgs: ["home", "switch", "/home/kenrict/meridian", "--configuration", "meridian"],
    activationAttribute: "homeConfigurations.meridian.activationPackage",
    homeManagerOwnsNh: true,
  },
];

for (const profile of profiles) {
  test(`${profile.label} home-profile preserves activate, switch, update, and clean routing`, () => {
    // Evaluate only the generated wrapper; forbid builds and import-from-derivation.
    const config = runJSON([
      "nix", "eval", "--json", ...evaluationOptions,
      `${repo}#${profile.attribute}`, "--apply", `c: {
        repo = c.home.sessionVariables.NX;
        nhEnabled = c.programs.nh.enable;
        cleanupEnabled = c.programs.nh.clean.enable;
        drvPath = (builtins.head (builtins.filter
          (p: (p.pname or p.name or "") == "home-profile")
          c.home.packages)).drvPath;
      }`,
    ]);
    expect(config.repo).toBe(profile.repo);
    // NH ownership differs by profile; automatic cleanup stays disabled everywhere.
    expect(config.nhEnabled).toBe(profile.homeManagerOwnsNh);
    expect(config.cleanupEnabled).toBe(false);
    const result = runJSON(["nix", "derivation", "show", ...evaluationOptions, config.drvPath]);
    // Support legacy and versioned Nix JSON, including structured derivations.
    const derivations: Record<string, {
      env: { text: string };
      structuredAttrs?: { text: string };
    }> = result.derivations ?? result;
    expect(Object.keys(derivations)).toHaveLength(1);
    const derivation = Object.values(derivations)[0];
    const script = (derivation.structuredAttrs ?? derivation.env).text;
    expect(typeof script).toBe("string");
    const runtimePath = script.match(/^export PATH="([^"]+)"$/m);
    expect(runtimePath).not.toBeNull();
    expect(/\/nix\/store\/[^/:]+-nix-[0-9][^/:]*\/bin(?=:|$)/.test(runtimePath![1]))
      .toBe(profile.label !== "nix-darwin");
    const isolatedScript = script.replace(/^export PATH=.*$/m, 'export PATH="$PROFILE_TEST_PATH"');
    expect(isolatedScript).not.toBe(script);

    const dir = mkdtempSync(join(tmpdir(), "home-profile-"));
    try {
      const calls = join(dir, "calls");
      const activation = join(dir, "activation");
      mkdirSync(activation);
      const stub = (path: string, body: string) =>
        writeFileSync(path, `#!/bin/sh\n${body}\n`, { mode: 0o755 });
      for (const command of ["nh", "brew", "determinate-nixd", "sudo", "mole"]) {
        stub(join(dir, command), `printf "%s\\n" ${command} "$@" >> "$PROFILE_TEST_CALLS"`);
      }
      stub(join(dir, "nix"), [
        'printf "%s\\n" nix "$@" >> "$PROFILE_TEST_CALLS"',
        'if [ "$1" = build ]; then printf "%s\\n" "$PROFILE_TEST_ACTIVATION"; fi',
      ].join("\n"));
      stub(join(dir, "uname"), 'printf "%s\\n" "$PROFILE_TEST_KERNEL"');
      stub(join(activation, "activate"), 'printf "%s\\n" activate "$@" >> "$PROFILE_TEST_CALLS"');

      const bash = Bun.which("bash")!;
      if (profile.label === "nix-darwin") {
        // Keep the real wrapper PATH: Darwin must preserve the caller's Nix.
        const resolution = Bun.spawnSync([bash, "-c", `${runtimePath![0]}\ncommand -v nix`], {
          env: { PATH: dir },
          timeout: 5_000,
        });
        expect(resolution.exitCode, resolution.stderr.toString()).toBe(0);
        expect(resolution.stdout.toString().trim()).toBe(join(dir, "nix"));
      }
      // Check cd's destination without requiring the other machine's home directory.
      // PATH contains only recording stubs; sudo never executes its arguments.
      const fixture = 'cd() { [[ $# == 1 && $1 == "$PROFILE_TEST_REPO" ]]; }\n' + isolatedScript;
      for (const kernel of ["Linux", "Darwin"]) {
        for (const action of ["activate", "switch", "update", "clean"]) {
          writeFileSync(calls, "");
          const run = Bun.spawnSync([bash, "-c", fixture, "home-profile", action], {
            env: {
              PATH: dir,
              PROFILE_TEST_PATH: dir,
              PROFILE_TEST_CALLS: calls,
              PROFILE_TEST_REPO: profile.repo,
              PROFILE_TEST_ACTIVATION: activation,
              PROFILE_TEST_KERNEL: kernel,
            },
            timeout: 5_000,
          });
          expect(run.exitCode, `${action} with uname=${kernel}: ${run.stderr.toString()}`).toBe(0);
          // Routing follows the configured profile, even when inspected on another OS.
          const expected = action === "clean"
            ? [
              "nh", "clean", "all",
              ...(profile.label === "nix-darwin"
                ? ["--keep", "2", "--keep-one"]
                : ["mole", "clean"]),
            ]
            : action === "activate" && profile.activationAttribute
            ? [
              "nix", "build", "--no-link", "--print-out-paths",
              `${profile.repo}#${profile.activationAttribute}`, "activate",
            ]
            : ["nh", ...profile.switchArgs];
          if (action === "update") {
            expected.unshift("nix", "flake", "update");
            if (profile.label === "nix-darwin") {
              expected.push("brew", "update", "brew", "upgrade", "sudo", "determinate-nixd", "upgrade");
            }
          }
          expect(readFileSync(calls, "utf8").trim().split("\n"), `${action} with uname=${kernel}`).toEqual(expected);
        }
      }
    } finally {
      rmSync(dir, { recursive: true, force: true });
    }
  }, 120_000);
}
