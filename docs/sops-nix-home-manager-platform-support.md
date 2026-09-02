# Research: sops-nix Home Manager platform support

Verified against official source on 2026-09-09. Sops-nix: `13616fff713a9f94055c66f15687ebdc17a335df`; Home Manager: Meridian's locked `2c0350c759688177331b8f5242311fae8877bdb3`.

## Summary and support table

**Yes: Home Manager officially supports standalone use and nix-darwin integration, and the inspected sops-nix revision implements Home Manager support for both non-NixOS Linux and Darwin.** NixOS is not required. See the official [standalone setup][hmstandalone] and [nix-darwin module][hmdarwinsetup] guides. Darwin secret support is explicit in source, despite the sops-nix README’s systemd-only wording; actual operation with Meridian’s pinned Home Manager still needs testing.

| Target | Implementation | Prerequisites |
|---|---|---|
| Arch/CachyOS | HM `sops-nix.service`, systemd user oneshot | Nix/HM, enabled and reachable systemd user manager, valid user `XDG_RUNTIME_DIR`, decryption identity |
| macOS / nix-darwin | HM LaunchAgent `org.nix-community.home.sops-nix` | Nix/HM, launchd enabled, logged-in GUI domain, decryption identity; successful secret-filesystem setup |
| Linux without systemd/user | No supplied automatic lifecycle | Custom integration would be required |

**Support:** direct evidence, high confidence for implementation; unverified runtime compatibility. Sources: [HM sops module][sops], [HM systemd][systemd], [HM launchd][launchd].

## Recommended Meridian wiring

The inspected `flake.nix` exposes standalone `homeConfigurations.meridian` through `lib/mkhome.nix`, and embedded `darwinConfigurations.m0nix` through `lib/mksystem.nix`. Both pass `inputs` into HM and both machine home modules import `hm/_base.nix`. Their explicit home directories are already correct. No sops-nix input currently appears in the inspected flake.

Recommended future changes—not applied here:

```nix
# flake.nix inputs
sops-nix = {
  url = "github:Mic92/sops-nix/13616fff713a9f94055c66f15687ebdc17a335df";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Import one proposed shared HM module, `./sops.nix`, from `hm/_base.nix`:

```nix
# proposed hm/sops.nix
{ config, inputs, ... }: {
  imports = [ inputs.sops-nix.homeManagerModules.sops ];
  sops = {
    defaultSopsFile = ../secrets/secrets.yaml; # encrypted file to migrate
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
    secrets.example = {}; # must match an encrypted YAML key
  };
  home.sessionVariables.SOPS_AGE_KEY_FILE = config.sops.age.keyFile;
}
```

This imports the **HM** module in the correct scope on both hosts. Alternatively, standalone wiring can add it to `homeManagerConfiguration.modules`; embedded wiring can use `home-manager.sharedModules = [ inputs.sops-nix.homeManagerModules.sops ];`. Choose one route. **Neither `nixosModules.sops` nor a system Darwin sops module is necessary for user secrets.** [README][readme], [HM common module][common]

Replace, rather than duplicate, the existing `_base.nix` `SOPS_AGE_KEY_FILE` assignment. It currently references bare `${nixrt}`, although the inspected scope provides `paths.nixrt`, not `nixrt`: an apparent independent evaluation blocker. `hm/paths.nix` also places that old key location under the configuration checkout. A shell environment variable alone does not configure the HM service’s identity source.

## Lifecycle, paths, and consumers

1. **Activation is runtime, not evaluation-time decryption.** With nonempty `sops.secrets`, Linux enables the service under `default.target` for age; `gnupg.home` changes this to `graphical-session-pre.target`. HM activation restarts it if the user manager reports `running` or `degraded`; otherwise it skips. On Arch, verify the manager/session and, if necessary, set `systemd.user.systemctlPath = "/usr/bin/systemctl"`. [sops][sops], [systemd][systemd] **Direct evidence; high confidence.**

2. **Darwin uses launchd, not systemd.** The agent has `RunAtLoad = true`, `KeepAlive = false`; activation bootouts/bootstraps it in `gui/<uid>`. Embedded HM activation runs as the user during nix-darwin post-activation. Headless activation is not established. Keep the GUI domain: changing HM’s agent domain alone would leave sops’ hard-coded GUI activation unchanged. Logs target `~/Library/Logs/SopsNix/{stdout,stderr}`. [sops][sops], [Darwin integration][darwinhm] **Direct evidence; high confidence.**

3. **Default paths:** generations live in `%r/secrets.d`; `%r` is `$XDG_RUNTIME_DIR` on Linux and `getconf DARWIN_USER_TEMP_DIR` on Darwin. The stable link is `${config.xdg.configHome}/sops-nix/secrets`; use `config.sops.secrets.example.path` in consumers. Secret mode defaults to `0400`, retention to one generation. Templates use runtime placeholders and default to `…/secrets/rendered/<name>`. [sops][sops], [templates][templates], [installer][main] **Direct evidence; high confidence.**

4. **Ordering:** Linux consumers should specify `Unit.After = [ "sops-nix.service" ];`; add `Unit.Requires` for a mandatory startup dependency. `After` alone does not pull in the service. For activation consumers, order their DAG entry after `sops-nix`, but do not assume Darwin bootstrap waits for decryption. Recommendation/inference: Darwin consumers should wait with a bounded timeout for a readable secret and fail closed. Secret rotation does not automatically restart HM consumers; schedule reload/restart explicitly. [README][readme], [installer][main] **Mixed direct evidence and operational inference; medium confidence.**

## Security and contradictions

**The pinned Darwin code contradicts a simple “HM cannot mount RAM storage” explanation.** Linux user mode only creates a directory; its storage properties depend on the runtime filesystem, with no module-enforced no-swap guarantee. Darwin instead attempts a 64-MiB RAM disk using `hdiutil`, `newfs_hfs`, and `mount`, even in user mode. `main.go` calls this before decryption and aborts on failure; no disk fallback is shown. Existing `sops-nix-secretfs` marker detection skips setup without validating the mount. Thus do not promise either ordinary disk-temp storage or guaranteed memory-only security on macOS: verify the resulting mount and privileges. [Linux implementation][linux], [Darwin implementation][darwingo], [installer][main] **Direct evidence; high confidence.**

Provision a dedicated, unencrypted age identity outside Git/Nix store, with directory mode `0700`, file mode `0600`, and protected backup. Never embed private keys/plaintext through Nix strings, `home.file.text`, or store-backed sources. Commit only ciphertext and public recipients; encrypt for each required host identity before switching. `generateKey` defaults false; enabling it does not re-encrypt existing secrets. The installer also writes an identity copy to `secrets.d/age-keys.txt` without explicit removal in the inspected flow. [sops][sops], [installer][main] **Direct evidence plus security recommendations; high confidence.**

## Verification limits and next steps

Primary sources were supplied locally; no web search or registered `source_check` was available. Source inspection replaced automated validation. No builds, switches, mount tests, or decryption tests were run. README blanket systemd/no-ramfs wording was deprioritized where contradicted by executable source. Test both locked configurations, first activation and fresh login, mount identity, secret permissions, consumer readiness, and rotation before rollout. Only this research note was added to the repository; no configuration changes were applied.

[hmstandalone]: https://github.com/nix-community/home-manager/blob/2c0350c759688177331b8f5242311fae8877bdb3/docs/manual/nix-flakes/standalone.md
[hmdarwinsetup]: https://github.com/nix-community/home-manager/blob/2c0350c759688177331b8f5242311fae8877bdb3/docs/manual/nix-flakes/nix-darwin.md
[sops]: https://github.com/Mic92/sops-nix/blob/13616fff713a9f94055c66f15687ebdc17a335df/modules/home-manager/sops.nix
[templates]: https://github.com/Mic92/sops-nix/blob/13616fff713a9f94055c66f15687ebdc17a335df/modules/home-manager/templates.nix
[readme]: https://github.com/Mic92/sops-nix/blob/13616fff713a9f94055c66f15687ebdc17a335df/README.md#use-with-home-manager
[main]: https://github.com/Mic92/sops-nix/blob/13616fff713a9f94055c66f15687ebdc17a335df/pkgs/sops-install-secrets/main.go
[linux]: https://github.com/Mic92/sops-nix/blob/13616fff713a9f94055c66f15687ebdc17a335df/pkgs/sops-install-secrets/linux.go
[darwingo]: https://github.com/Mic92/sops-nix/blob/13616fff713a9f94055c66f15687ebdc17a335df/pkgs/sops-install-secrets/darwin.go
[systemd]: https://github.com/nix-community/home-manager/blob/2c0350c759688177331b8f5242311fae8877bdb3/modules/systemd.nix
[launchd]: https://github.com/nix-community/home-manager/blob/2c0350c759688177331b8f5242311fae8877bdb3/modules/launchd/default.nix
[common]: https://github.com/nix-community/home-manager/blob/2c0350c759688177331b8f5242311fae8877bdb3/nixos/common.nix
[darwinhm]: https://github.com/nix-community/home-manager/blob/2c0350c759688177331b8f5242311fae8877bdb3/nix-darwin/default.nix
