import { isDeepStrictEqual } from "node:util";

type Check = { domain: string; key: string; expected: unknown };
type EffectiveValue = { actual: unknown; forced: boolean };
type Profile = {
  PayloadType: string;
  PayloadContent: {
    PayloadType: string;
    PayloadContent?: Record<string, {
      Forced: { mcx_preference_settings: Record<string, unknown> }[];
    }>;
    [key: string]: unknown;
  }[];
};

export function profileChecks(profile: Profile): Check[] {
  if (profile.PayloadType !== "Configuration" || !Array.isArray(profile.PayloadContent)) {
    throw new Error("Expected a configuration profile");
  }
  const checks: Check[] = [];
  const add = (domain: string, settings: Record<string, unknown>) => {
    for (const [key, expected] of Object.entries(settings)) {
      checks.push({ domain, key, expected });
    }
  };
  for (const payload of profile.PayloadContent) {
    if (payload.PayloadType === "com.apple.applicationaccess") {
      add(payload.PayloadType, Object.fromEntries(
        Object.entries(payload).filter(([key]) => !key.startsWith("Payload")),
      ));
    } else if (payload.PayloadType === "com.apple.ManagedClient.preferences") {
      const domains = Object.entries(payload.PayloadContent ?? {});
      if (domains.length !== 1) {
        throw new Error("Each managed-preferences payload must contain exactly one domain");
      }
      const [domain, content] = domains[0];
      if (!Array.isArray(content.Forced) || content.Forced.length === 0) {
        throw new Error(`${domain}: expected Forced preferences`);
      }
      for (const entry of content.Forced) add(domain, entry.mcx_preference_settings);
    } else {
      throw new Error(`Unsupported payload: ${payload.PayloadType}`);
    }
  }
  if (checks.length === 0) throw new Error("Profile contains no settings to check");
  return checks;
}

export function isApplied(check: Check, live: EffectiveValue): boolean {
  return live.forced === true && isDeepStrictEqual(live.actual, check.expected);
}

function run(command: string[]): string {
  const result = Bun.spawnSync(command);
  if (result.exitCode !== 0) {
    throw new Error(`${command[0]}: ${result.stderr.toString().trim() || `exit ${result.exitCode}`}`);
  }
  return result.stdout.toString();
}

function main(): number {
  if (process.platform !== "darwin") throw new Error("This check requires macOS");
  if (Bun.argv.length > 3) throw new Error("Usage: bun privacy-check.ts [profile.mobileconfig]");
  const path = Bun.argv[2] ?? "/etc/nix-darwin/privacy-restrictions.mobileconfig";
  const checks = profileChecks(JSON.parse(run(["/usr/bin/plutil", "-convert", "json", "-o", "-", path])));
  // Read effective managed values; `defaults read` can miss profile restrictions.
  const live: EffectiveValue[] = JSON.parse(run([
    "/usr/bin/osascript", "-l", "JavaScript", "-e", `
      ObjC.import("Foundation");
      ObjC.import("CoreFoundation");
      function run(argv) {
        return JSON.stringify(JSON.parse(argv[0]).map(function(check) {
          var domain = $(check.domain), key = $(check.key);
          $.CFPreferencesAppSynchronize(domain);
          var value = $.CFPreferencesCopyAppValue(key, domain);
          var actual = ObjC.deepUnwrap(ObjC.castRefToObject(value));
          return {
            actual: typeof actual === "undefined" ? null : actual,
            forced: !!$.CFPreferencesAppValueIsForced(key, domain)
          };
        }));
      }
    `, JSON.stringify(checks),
  ]));
  if (live.length !== checks.length) throw new Error("Incomplete preference read");
  console.log(`Profile: ${path}`);
  let applied = 0;
  checks.forEach((check, index) => {
    const value = live[index];
    const ok = isApplied(check, value);
    if (ok) applied++;
    const actual = value.actual === null ? "missing" : JSON.stringify(value.actual);
    console.log(`${ok ? "PASS" : "FAIL"} ${check.domain} / ${check.key}: `
      + `expected=${JSON.stringify(check.expected)}, actual=${actual}, enforced=${value.forced}`);
  });
  console.log(`\n${applied}/${checks.length} profile settings applied and enforced.`);
  if (applied === checks.length) return 0;
  console.log("Run just privacy-setup, approve Install/Replace in Device Management, then rerun just privacy-check.");
  return 1;
}

if (import.meta.main) {
  try {
    process.exitCode = main();
  } catch (error) {
    console.error(error instanceof Error ? error.message : error);
    process.exitCode = 2;
  }
}
