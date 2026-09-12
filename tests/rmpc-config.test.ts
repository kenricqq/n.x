import { expect, test } from "bun:test";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const rmpc = Bun.which("rmpc");

for (const [platform, attribute] of Object.entries({
  darwin: "darwinConfigurations.m0nix.config.home-manager.users.kenrictee",
  linux: "homeConfigurations.meridian.config",
})) {
  test.skipIf(!rmpc)(`${platform}: generated rmpc config loads without fallback`, () => {
    const evaluation = Bun.spawnSync(
      [
        "nix",
        "eval",
        "--raw",
        "--no-write-lock-file",
        `${new URL("../", import.meta.url).pathname}#${attribute}.xdg.configFile.\"rmpc/config.ron\".text`,
      ],
      { timeout: 120_000 },
    );
    expect(evaluation.exitCode, evaluation.stderr.toString()).toBe(0);

    const directory = mkdtempSync(join(tmpdir(), "rmpc-config-"));
    try {
      const config = join(directory, "config.ron");
      writeFileSync(config, evaluation.stdout);
      const result = Bun.spawnSync(
        // A missing local socket keeps this parser check independent of a running MPD.
        [rmpc!, "-c", config, "-a", join(directory, "mpd.sock"), "debuginfo"],
        { timeout: 15_000 },
      );
      const diagnostics = result.stdout.toString() + result.stderr.toString();
      // rmpc exits successfully even when parsing fails and defaults are used.
      expect(diagnostics).not.toContain("Failed to read config");
      expect(diagnostics).not.toContain("Using the default values");
      expect(diagnostics).toMatch(/Config path\s+Some\(/);
      expect(result.exitCode, diagnostics).toBe(0);
    } finally {
      rmSync(directory, { recursive: true, force: true });
    }
  }, 150_000);
}
