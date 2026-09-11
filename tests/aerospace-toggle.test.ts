import { expect, test } from "bun:test";
import {
  chmodSync,
  lstatSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  symlinkSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const repo = fileURLToPath(new URL("../", import.meta.url));

function configuredTogglePackages(attribute: string): string[] {
  const result = Bun.spawnSync(
    [
      "nix",
      "eval",
      "--json",
      "--no-write-lock-file",
      `path:${repo}#${attribute}.home.packages`,
      "--apply",
      'ps: map (p: p.name) (builtins.filter (p: (p.name or "") == "toggle-sketchybar-gap") ps)',
    ],
    { timeout: 120_000 },
  );
  if (result.exitCode !== 0) {
    throw new Error(`Home Manager evaluation failed: ${result.stderr.toString()}`);
  }
  return JSON.parse(result.stdout.toString());
}

test("Darwin declares the gap toggle command exactly once", () => {
  expect(
    configuredTogglePackages("darwinConfigurations.m0nix.config.home-manager.users.kenrictee"),
  ).toEqual(["toggle-sketchybar-gap"]);
}, 120_000);

test("Linux excludes the Darwin-only gap toggle command", () => {
  expect(configuredTogglePackages("homeConfigurations.meridian.config")).toEqual([]);
}, 120_000);

const initialConfig = "[gaps]\nouter.top = 30\nouter.left = 7\n";

function createFixture() {
  const python = Bun.which("python3");
  if (!python) throw new Error("Toggle tests require python3 on PATH");

  const home = mkdtempSync(join(tmpdir(), "aerospace toggle "));
  const bin = join(home, "bin");
  const backing = join(home, "editable.toml");
  const config = join(home, "linked.toml");
  const calls = join(home, "bar-calls");
  const observed = join(home, "config-seen-by-bar");
  mkdirSync(bin);
  symlinkSync(python, join(bin, "python3"));
  writeFileSync(backing, initialConfig);
  symlinkSync(backing, config);
  writeFileSync(calls, "");
  writeFileSync(
    join(bin, "sketchybar"),
    '#!/bin/sh\nprintf "%s\\n" "$*" >> "$BAR_CALLS"\n/bin/cat "$OBSERVE_CONFIG" > "$BAR_OBSERVED"\nexit "${BAR_EXIT:-0}"\n',
    { mode: 0o755 },
  );

  return {
    home,
    backing,
    config,
    calls,
    observed,
    run(args: string[] = [], environment: Record<string, string> = {}) {
      return Bun.spawnSync(["/bin/bash", join(repo, "scripts/toggle-sketchybar-gap.sh"), ...args], {
        env: {
          HOME: home,
          PATH: `${bin}:/usr/bin:/bin`,
          AEROSPACE_CONFIG: config,
          BAR_CALLS: calls,
          OBSERVE_CONFIG: config,
          BAR_OBSERVED: observed,
          ...environment,
        },
        timeout: 5000,
      });
    },
  };
}

function withFixture(check: (fixture: ReturnType<typeof createFixture>) => void) {
  const fixture = createFixture();
  try {
    check(fixture);
  } finally {
    rmSync(fixture.home, { recursive: true, force: true });
  }
}

test("toggle persists the gap before updating the bar and preserves linked config", () => {
  withFixture((fixture) => {
    const hidden = fixture.run();
    expect(hidden.exitCode, hidden.stderr.toString()).toBe(0);
    expect(readFileSync(fixture.backing, "utf8")).toBe("[gaps]\nouter.top = 0\nouter.left = 7\n");
    expect(readFileSync(fixture.observed, "utf8")).toContain("outer.top = 0");

    const visible = fixture.run(["--toggle"]);
    expect(visible.exitCode, visible.stderr.toString()).toBe(0);
    expect(readFileSync(fixture.backing, "utf8")).toBe(initialConfig);
    expect(readFileSync(fixture.observed, "utf8")).toContain("outer.top = 30");
    expect(readFileSync(fixture.calls, "utf8")).toBe("--bar hidden=on\n--bar hidden=off\n");
    expect(lstatSync(fixture.config).isSymbolicLink()).toBe(true);
  });
});

for (const { gap, barCall } of [
  { gap: 0, barCall: "--bar hidden=on\n" },
  { gap: 30, barCall: "--bar hidden=off\n" },
]) {
  test(`sync preserves gap ${gap} across repeated calls`, () => {
    withFixture((fixture) => {
      const config = `[gaps]\nouter.top = ${gap}\n`;
      writeFileSync(fixture.backing, config);
      const first = fixture.run(["--sync"]);
      const second = fixture.run(["--sync"]);
      expect(first.exitCode, first.stderr.toString()).toBe(0);
      expect(second.exitCode, second.stderr.toString()).toBe(0);
      expect(readFileSync(fixture.backing, "utf8")).toBe(config);
      expect(readFileSync(fixture.calls, "utf8")).toBe(barCall + barCall);
    });
  });
}

test("bar failure does not undo the requested gap or fail the toggle", () => {
  withFixture((fixture) => {
    const result = fixture.run([], { BAR_EXIT: "19" });
    expect(result.exitCode, result.stderr.toString()).toBe(0);
    expect(readFileSync(fixture.backing, "utf8")).toContain("outer.top = 0");
    expect(readFileSync(fixture.calls, "utf8")).toBe("--bar hidden=on\n");
  });
});

test("invalid mode leaves configuration and bar unchanged", () => {
  withFixture((fixture) => {
    const result = fixture.run(["--invalid"]);
    expect(result.exitCode).toBe(1);
    expect(result.stderr.toString()).toContain("Usage:");
    expect(readFileSync(fixture.backing, "utf8")).toBe(initialConfig);
    expect(readFileSync(fixture.calls, "utf8")).toBe("");
  });
});

test("missing gap setting fails before changing configuration or bar", () => {
  withFixture((fixture) => {
    const config = "[gaps]\nouter.left = 7\n";
    writeFileSync(fixture.backing, config);
    const result = fixture.run();
    expect(result.exitCode).not.toBe(0);
    expect(result.stderr.toString()).toContain("Could not find outer.top in config");
    expect(readFileSync(fixture.backing, "utf8")).toBe(config);
    expect(readFileSync(fixture.calls, "utf8")).toBe("");
  });
});

// Root bypasses Unix write permissions, so it cannot exercise this failure mode.
test.skipIf(process.getuid?.() === 0)(
  "unwritable configuration fails before updating the bar",
  () => {
    withFixture((fixture) => {
      chmodSync(fixture.backing, 0o444);
      const result = fixture.run();
      expect(result.exitCode).not.toBe(0);
      expect(readFileSync(fixture.backing, "utf8")).toBe(initialConfig);
      expect(readFileSync(fixture.calls, "utf8")).toBe("");
    });
  },
);

test("default config is found under HOME without an explicit override", () => {
  withFixture((fixture) => {
    const directory = join(fixture.home, ".config/aerospace");
    mkdirSync(directory, { recursive: true });
    symlinkSync(fixture.backing, join(directory, "aerospace.toml"));
    const result = fixture.run([], { AEROSPACE_CONFIG: "" });
    expect(result.exitCode, result.stderr.toString()).toBe(0);
    expect(readFileSync(fixture.backing, "utf8")).toContain("outer.top = 0");
    expect(readFileSync(fixture.calls, "utf8")).toBe("--bar hidden=on\n");
  });
});
