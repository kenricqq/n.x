import { expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { isApplied, profileChecks } from "../scripts/privacy-check";

const restrictions = {
  PayloadType: "com.apple.applicationaccess",
  PayloadIdentifier: "test.restrictions",
  PayloadVersion: 1,
  allowWritingTools: false,
};
const managed = (domain: string, settings: Record<string, unknown>) => ({
  PayloadType: "com.apple.ManagedClient.preferences",
  PayloadContent: { [domain]: { Forced: [{ mcx_preference_settings: settings }] } },
});

test("extracts restriction and managed keys, including additions, without metadata", () => {
  expect(profileChecks({
    PayloadType: "Configuration",
    PayloadContent: [restrictions, managed("group.com.apple.mail", {
      DisableAutomaticMessageSummarization: true,
      PersonalizedSmartReplies: false,
      FutureSetting: 2,
    })],
  })).toEqual([
    { domain: "com.apple.applicationaccess", key: "allowWritingTools", expected: false },
    { domain: "group.com.apple.mail", key: "DisableAutomaticMessageSummarization", expected: true },
    { domain: "group.com.apple.mail", key: "PersonalizedSmartReplies", expected: false },
    { domain: "group.com.apple.mail", key: "FutureSetting", expected: 2 },
  ]);
});

test("rejects the multi-domain payload macOS silently failed to apply", () => {
  expect(() => profileChecks({
    PayloadType: "Configuration",
    PayloadContent: [{
      PayloadType: "com.apple.ManagedClient.preferences",
      PayloadContent: {
        ...managed("com.apple.MobileSMS", { messageSummarizationEnabled: false }).PayloadContent,
        ...managed("group.com.apple.usernoted", { summarize_previews: false }).PayloadContent,
      },
    }],
  })).toThrow("exactly one domain");
});

test("empty and unsupported profiles cannot report success", () => {
  for (const PayloadContent of [[], [{ PayloadType: "unsupported" }]]) {
    expect(() => profileChecks({ PayloadType: "Configuration", PayloadContent })).toThrow();
  }
});

test("success requires both the expected value and profile enforcement", () => {
  const check = { domain: "com.apple.applicationaccess", key: "allowWritingTools", expected: false };
  expect(isApplied(check, { actual: false, forced: true })).toBe(true);
  expect(isApplied(check, { actual: false, forced: false })).toBe(false);
  expect(isApplied(check, { actual: true, forced: true })).toBe(false);
  expect(isApplied(check, { actual: null, forced: false })).toBe(false);
  expect(isApplied(check, { actual: 0, forced: true })).toBe(false);
});

test.skipIf(process.platform !== "darwin")("Nix exports separate managed domains and maps the checker", () => {
  const repo = fileURLToPath(new URL("../", import.meta.url)).replace(/\/$/, "");
  const evaluation = Bun.spawnSync([
    "nix", "eval", "--json", "--offline", "--no-write-lock-file",
    "--option", "allow-import-from-derivation", "false",
    "--option", "max-jobs", "0", "--option", "builders", "",
    `path:${repo}#darwinConfigurations.m0nix.config.environment.etc`,
    "--apply", `etc: {
      profile = etc."nix-darwin/privacy-restrictions.mobileconfig".text;
      checker = builtins.readFile etc."nix-darwin/privacy-check.ts".source;
    }`,
  ], { timeout: 120_000 });
  expect(evaluation.exitCode, evaluation.stderr.toString()).toBe(0);
  const config = JSON.parse(evaluation.stdout.toString());
  expect(config.checker).toBe(readFileSync(`${repo}/scripts/privacy-check.ts`, "utf8"));
  const parsed = Bun.spawnSync(["/usr/bin/plutil", "-convert", "json", "-o", "-", "-"], {
    stdin: Buffer.from(config.profile),
  });
  expect(parsed.exitCode, parsed.stderr.toString()).toBe(0);
  const profile = JSON.parse(parsed.stdout.toString());
  const checks = profileChecks(profile);
  expect(checks).toContainEqual({
    domain: ".GlobalPreferences", key: "NSAutomaticInlinePredictionEnabled", expected: false,
  });
  expect(checks).toContainEqual({
    domain: "group.com.apple.usernoted", key: "summarize_previews", expected: false,
  });
  const payloads = [profile, ...profile.PayloadContent];
  for (const key of ["PayloadIdentifier", "PayloadUUID"]) {
    expect(new Set(payloads.map(payload => payload[key])).size).toBe(payloads.length);
  }
}, 120_000);
