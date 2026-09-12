# MISTAKES.md

## Zsh

- Avoid shell special parameters such as read-only `status` for local variables; use names such as `hx_status`.
  - Check suspicious names in an isolated `zsh -fc` function before using them in widgets.

- Source zsh-async from the Home Manager-managed config path, never `./async.zsh`. Check `_my_jj_worker` before submitting jobs; restart missing workers and re-register callbacks.
  - Check: start Zsh outside the config directory, stop the worker, and confirm the next JJ prompt recovers without async errors.

- Preserve the custom ZLE external-editor selection contract. Native `edit-command-line` can omit the final character after `x` selects a full line in `vicmd`.
  - Check: in a PTY, test Ctrl-O after `x` on a multiline buffer, insert/command modes, partial selections, and Helix row/column. Inspect both editor input and restored buffer.

## Nix / Home Manager sources and modules

- Verify the checkout used by the installed activation command and resolved config symlink before patching. `hms` calls `home-profile activate`; its repository path comes from `paths.nixrt` in `hm/shell-commands.nix`.
  - Check the installed command's path, then test the app against its default live config after activation.

- Update Nix path references when moving files; files used by Git-backed flakes must be tracked.
  - Check the destination with `jj file list` and evaluate the affected flake output.

- Live out-of-store config edits take effect before a new Home Manager generation is activated. Do not make them depend on an executable that is not installed yet.
  - Check every new command resolves in the live consumer's environment before activation.

- Pass dependencies explicitly to imported helpers. Darwin and Home Manager have separate module argument scopes; construct Darwin `paths` and `dlaunch` in `machines/m0nix/darwin.nix` and expose them through `_module.args`.
  - Check: `bun test tests/machine-paths.test.ts` and `nix eval --raw .#darwinConfigurations.m0nix.system.drvPath`. Home Manager-only evaluation misses Darwin Homebrew and launchd failures.

- Pass inputs used in module `imports` through system `specialArgs`, not `_module.args`; imports are resolved before module configuration, so the latter can cause infinite recursion.
  - Check: `nix eval --raw .#darwinConfigurations.m0nix.system.drvPath` after moving an input-backed Darwin import into a machine module.

- Gate platform-specific packages and completions where they are registered, as `hm/display.nix` does for Linux-only `lg-input`.
  - Check both profiles: the package and completion must be absent on Darwin and present on Linux.

- Handle both legacy and versioned `nix derivation show` JSON. Versioned output nests entries under `derivations`; keys may be basenames rather than full store paths.
  - Check: `bun test tests/machine-paths.test.ts` must inspect generated scripts without building or running them.

## Packages and caches

- Pass one repository per `skills add` invocation; additional positional repositories are not processed. Keep Impeccable under one installer and its matching update command.
  - Check the generated setup commands with stubbed `bun`/`bunx`: each skill repository must be installed once, and Impeccable must use the requested scope without a duplicate skills entry.

- Determinate Nix owns `/etc/nix/nix.conf`. With `nix.enable = false`, manage caches through `environment.etc."nix/nix.custom.conf"` in `machines/m0nix/darwin.nix`.
  - Check: `nix config show` includes each cache URL and key. Fenix uses `fenix.cachix.org`; inspect a dry run of the actual toolchain derivation before assuming cache coverage.

- Install Python plugins through the application's wrapper, not as separate Home Manager packages. Keep `dooit-extras` in `dooit`'s `extraPackages`, as in `hm/knowledge-tools.nix`.
  - Check the generated wrapper includes the plugin's site-packages or verify the app's startup import path.

- Do not install `fcitx5-configtool` separately when Home Manager's `i18n.inputMethod.fcitx5` already produces `fcitx5-with-addons`; it can conflict on `bin/fcitx5-config-qt` across package scopes/versions.
  - Check `home-manager-path` build logs for duplicate `fcitx5-config-qt`, then keep the config tool only via the fcitx wrapper/addons.

## Homebrew / launchd

- Homebrew activation needs explicit XDG state and must not depend on bulk upgrades. Keep `extraEnv.XDG_CONFIG_HOME = paths.configHome`, `autoUpdate = false`, and `upgrade = false` in `os/darwin/homebrew.nix`.
  - Check the evaluated `homebrew.onActivation.brewBundleCmd` includes `XDG_CONFIG_HOME`, `HOMEBREW_NO_AUTO_UPDATE=1`, and `--no-upgrade`.

- Service secret consumers must use evaluated sops paths and a matching decryption identity. Glance reads `sops.secrets.RAINDROP_TOKEN.path`; KeepAlive retries until it is readable. Keep private keys untracked and out of Nix file sources.
  - Check decryption with the evaluated `sops.age.keyFile` to `/dev/null`, run `bun test tests/machine-paths.test.ts`, and check Glance on port 8080 after switching.

- Check service flags when upgrading packages. Memos previously crash-looped because its CLI no longer accepted `--mode=prod`.
  - Check every configured flag against the installed executable's help, then verify the service responds after switching.

- Use nix-darwin `launchd.user.agents` when macOS Background Items need distinct service names. Home Manager's shell wrapper can make them appear as `sh`.
  - Check the installed plist's `ProgramArguments[0]` is the service-specific executable.

## MPD / rmpc

- Use explicit RON options unless `implicit_some` is enabled: `status_update_interval_ms: Some(1000)`. rmpc can reject config and fall back to defaults despite exiting successfully.
  - Check: `bun test tests/rmpc-config.test.ts`; after activation, `rmpc debuginfo` must show a populated config path without fallback warnings.

- Keep MPD's `--stderr` flag and route launchd `StandardErrorPath` under `services.mpd.dataDir`; otherwise a missing `~/Library/Logs/mpd` can prevent socket startup. Retain its `.keep` for manual runs.
  - Check the evaluated launch agent and confirm foreground startup with `--stderr` gets past log initialization even without that log directory.

- Share `services.mpd.generatedConfig` with manual MPD runs, as in `hm/media.nix`; a minimal standalone config can fall back to missing cache paths.
  - Check manual config uses the evaluated service state paths, not a hard-coded `~/.mpd`.

## Ghostty / Nushell

- Generate Nu's absolute executable and `--config-home` in `ghostty-nix.conf`, outside the live Ghostty directory symlink. Include it optionally for unapplied generations; keep Nu first so Ghostty can insert its `--execute` argument.
  - Check: `bun test tests/ghostty-startup.test.ts` covers both profiles and minimal PATH. Test real login startup in a PTY because `GPG_TTY = (tty)` fails in non-TTY probes.

- Keep only the XDG Ghostty config mapping on macOS. Linking the same config under Application Support too can load includes twice and report `cycle detected`.
  - Check all evaluated default config paths together through Ghostty, not each in isolation.

- A temporary `HOME` does not isolate macOS Application Support discovery. Use `+validate-config --config-file=<fixture>` for temporary configs.
  - Check an intentionally invalid fixture fails, then passes after correction.

## Displays / AeroSpace / SketchyBar

- BetterDisplay mirroring needs explicit source and target selectors. Use `BetterDisplay help`, not `--help`, and verify names with `get --identifier=name`.
  - Check `hm/display.nix` emits the intended source and `--targetNameLike` for both mirror directions.

- Resolve scripts from AeroSpace's loaded binding and execution environment before diagnosing missing paths.
  - Check `aerospace config --get mode.main.binding.alt-ctrl-shift-b` and `aerospace list-exec-env-vars`, then inspect the resolved script without toggling the desktop.

- For edge-to-edge SketchyBar coverage with zero margin, keep the global bar radius at `0`; rounded item radii are independent.
  - Check screenshot edge pixels for wallpaper showing through the bar.

- Use configured AeroSpace `outer.top` as the bar toggle state; process/query failures must not leave an empty gap. Treat `sketchybar --bar hidden=...` as best effort.
  - Check: `bun test tests/aerospace-toggle.test.ts`; after deployment, two toggles must hide and restore both bar and gap.

- AeroSpace gaps affect tiled windows, not floating ones. Keep normal app windows tiled when they need clearance from SketchyBar.
  - Check `aerospace list-windows --focused --format '%{window-layout}'` reports `tiling` for those windows.

## QMK / Corne

- Keep custom keymaps outside the ignored firmware checkout. Meridian's broad `**/*key*` ignore rule also hides `keymaps/` and `keymap.c` unless explicitly excepted.
  - Check `git check-ignore -v` and `git status --short --untracked-files=all` after moving sources; verify setup can recreate the checkout and relative symlink.

- Resolve keyboard targets from the checkout, not only its README: current Corne documentation still mentions `crkbd/rev4`, while definitions use `crkbd/rev4_0/standard` and `crkbd/rev4_1/standard` with different split wiring.
  - Check the physical PCB revision and QMK's target definitions before choosing an artifact; use the same revision-specific firmware on both halves.

- Compare explicit alpha diagrams against Miryoku source. Its current default `COLEMAKDH` and alternative `COLEMAKDHK` swap K and M; the name alone is insufficient.
  - Check all 30 positions against the requested diagram before implementing.

- RP2040 QMK builds also require LUFA's shared USB descriptor headers, even though the MCU is not AVR.
  - Initialize `lib/lufa` alongside ChibiOS, ChibiOS-Contrib, pico-sdk, and printf before compiling.

- Miryoku's upstream branch can use keycodes removed from current QMK (for example `KC_MS_L`, `KC_BTN1`).
  - Check imported feature keycodes against `quantum/keycodes.h`; current mouse codes use `MS_LEFT`, `MS_BTN1`, etc. Do not assume upstream Miryoku targets the installed QMK API.
