# MISTAKES.md

## zsh/bash/nushell

- Do not probe flake branch aliases with non-existent Nix attrs.
  - Mistake: used `darwinConfigurations.$host.config.system.name` to decide whether to build the Darwin Home Manager activation package.
  - Result: the Darwin probe always failed, so the alias fell through to the Linux `homeConfigurations.$USER@$host` path on macOS.
  - Fix: probe an existing scalar attr such as `darwinConfigurations.$host.config.system.primaryUser`, then build `darwinConfigurations.$host.config.home-manager.users.$USER.home.activationPackage`.
  - Check: `nix eval --raw .#darwinConfigurations.$host.config.system.primaryUser` succeeds before the alias enters the Darwin branch. Use explicit output attrs in evaluation probes: `nix eval .# --apply ...` selects the default package, not the root output set.

- Do not embed escaped attr quotes in zsh-abbr-managed Nix aliases unless required.
  - Mistake: wrote flake refs as `.#darwinConfigurations.\"$host\"...` and `.#homeConfigurations.\"$USER@$host\"...` inside an abbreviation.
  - Result: zsh-abbr expansion preserved protective backslashes, so runtime variables became literal strings like `\$USER` and Nix looked for `homeConfigurations.$USER@...`.
  - Fix: for this repo's simple host/user names, use unquoted variable-expanded flake refs: `.#darwinConfigurations.$host...` and `.#homeConfigurations.$USER@$host.activationPackage`.
  - Check: expanding `hms` via zsh-abbr must not contain `\$USER`, `\$host`, or `\.activationPackage`.

- Do not use shell special parameters as local variable names.
  - Mistake: used `local ... status` and then `status=$?` inside a zsh ZLE widget.
  - Result: zsh raised `read-only variable: status`, aborting before saved editor contents were read back into `BUFFER`.
  - Fix: use a non-special name such as `hx_status`.
  - Check: when writing shell widgets, test suspicious names with `zsh -fc 'f(){ emulate -L zsh; local name; name=0; }; f'`.

- Do not source zsh-async from a relative path in prompt config.
  - Mistake: used `source ./async.zsh` inside `.p10k.zsh`.
  - Result: shells started outside the plugin directory raised `no such file or directory: ./async.zsh`, then `async_init: command not found`.
  - Fix: source zsh-async from a stable Home Manager-managed path such as `$HOME/.config/zsh/async.zsh`, never `./async.zsh`.
  - Check: start `zsh` from a non-config directory and confirm `.p10k.zsh` emits no async errors.

- Do not assume a prompt's async worker survives for the lifetime of the shell.
  - Mistake: started `_my_jj_worker` only when `.p10k.zsh` loaded, then submitted jobs without checking the worker.
  - Result: after the worker and callback were removed, each JJ prompt printed `async_job: no such async worker: _my_jj_worker`.
  - Fix: check the worker before submitting a job; clear stale state, restart it, and register its callback again. Skip submission if startup fails.
  - Check: stop `_my_jj_worker` in an isolated shell, render the JJ prompt, and confirm the replacement worker delivers a callback without errors.

## Codex config profiles

- Do not make live out-of-store hooks depend on a new, not-yet-activated Home Manager package.
  - Mistake: changed `hooks.json` to call a new `codex-agent` profile binary while adding that binary in the same unapplied Home Manager generation.
  - Result: the hook edit became live immediately through `mkOutOfStoreSymlink`, but the binary did not exist, so every matching hook exited `127`.
  - Fix: invoke an already-installed runtime directly, or make the hook tolerate a missing executable until activation.
  - Check: resolve every hook command before activation and execute it once from the live hook environment.

- Do not use transport-less MCP stubs in named profile files.
  - Mistake: added only `enabled = false` under `[mcp_servers.<id>]` in `agent.config.toml`, expecting the base config's transport to merge first.
  - Result: Codex rejected the profile with `invalid transport` before applying it over `config.toml`.
  - Fix: repeat the server's `command`/`args` or `url` in the profile, even when that server is disabled.
  - Check: copy each profile to a temporary `config.toml` and run `codex app-server --strict-config --listen stdio:// </dev/null`; also load the real overlay with its profile-aware runtime command.

## Nix / Home Manager file sources

- Verify which checkout the installed activation command actually uses.
  - Mistake: validated `~/KTQQ/m0nix` and recommended `hms`, but installed `home-profile` rebuilt `~/m0nix`, whose rmpc config still contained the bug.
  - Result: activation regenerated the same invalid config, so the runtime error persisted.
  - Fix: inspect the live alias, activation command's repository path, and resolved config symlink before choosing a source to patch.
  - Check: after applying the change, run the app against its default live config, not only a fixture from the current checkout.

- Do not leave Nix path interpolations pointing at old locations after moving repo files.
  - Mistake: moved `home-manager/services/vite-public-paths` to `home-manager/scripts/vite-public-paths` but left `${./services/vite-public-paths/bin/vite-public-paths.js}` in `home-manager/home.nix`.
  - Result: `nix build git+file://...` failed during evaluation because the path did not exist in the Git-tracked flake source.
  - Fix: update the interpolation to the new tracked path.
  - Check: `jj file list | rg '^home-manager/scripts/vite-public-paths/bin/vite-public-paths.js$'` and evaluate the flake.

## Nix / Home Manager module wiring

- Do not assume explicit imports inherit Nix module arguments or Home Manager's argument scope.
  - Mistake: Darwin Homebrew and launchd imported `helpers.nix` with only `lib` and `pkgs`, although the helper required `machine`; Homebrew also declared `paths`, whose provider existed only inside Home Manager.
  - Result: Darwin activation evaluation failed with `called without required argument 'machine'`; syntax checks and tests selecting only Home Manager outputs passed.
  - Fix: construct shared paths and launch helpers once in the Darwin machine module, pass required dependencies explicitly, and expose resolved values through that evaluation's `_module.args`. Keep Home Manager's XDG and symlink adapter separate.
  - Check: run `bun test tests/machine-paths.test.ts` and `nix eval --raw .#darwinConfigurations.m0nix.system.drvPath`; the tests must force Homebrew and launchd activation plus generated launch-script paths.

- Gate platform-specific packages and completions at their registration sites.
  - Mistake: removed the Darwin implementation of `lg-input` but kept it in unconditional `home.packages`.
  - Result: Darwin system evaluation forced its unsupported-platform branch and failed.
  - Fix: use `lib.optionals host.isLinux` for the package and `lib.optionalString host.isLinux` for its Nushell completion.
  - Check: evaluate the Darwin system derivation and confirm `lg-input` is absent on Darwin and present on Linux.

- Declare every flake input reference in the module's function arguments.
  - Mistake: `_base.nix` imported `inputs.nixcord.homeModules.nixcord` without accepting an `inputs` argument.
  - Result: Nix rejected the module with `undefined variable 'inputs'`, before package evaluation.
  - Fix: accept `inputs` in the module arguments; the host already supplies it through `extraSpecialArgs`.
  - Check: run `nix-instantiate --parse hm/_base.nix` from the repo root before evaluating either host profile.

- Terminate package-list assignments with `];`.
  - Mistake: `hm/dev/lang/go.nix` ended `home.packages` with `]` only.
  - Result: profile evaluation failed at the following `programs.go` assignment.
  - Fix: restore the terminating semicolon.
  - Check: run `nix-instantiate --parse` on edited Nix modules before evaluating profiles.

- Replace copied language-module content before importing the module.
  - Mistake: `markdown.nix` was an unused copy of `js_ts.nix`, including Bun settings and JS/TS packages.
  - Result: the file supplied no Markdown tools and would repeat the JS/TS configuration if imported.
  - Fix: give the Markdown module its own packages, remove their old declarations, and import it once.
  - Check: evaluate both profiles and confirm each moved package appears exactly once.

## Nix / derivation inspection

- Do not assume `nix derivation show` keys are absolute store paths across Nix versions.
  - Mistake: indexed the returned derivations by the full `.drv` path supplied to the command.
  - Result: the regression test crashed because versioned output nests entries under `derivations` and keys them by basename.
  - Fix: normalize the versioned and legacy JSON shapes; for a single requested derivation, assert exactly one entry and inspect its value.
  - Check: run `bun test tests/machine-paths.test.ts`; generated script inspection must succeed without building or running the programs.

## Nix / Rust toolchains

- Do not assume `rust.cachix.org` covers Fenix toolchains.
  - Mistake: enabling `nix-community/fenix` after adding only the `rust` Cachix cache.
  - Result: Rust toolchain setup misses Fenix substitutes and can compile or fetch much more during the first switch.
  - Fix: add `https://fenix.cachix.org` with `fenix.cachix.org-1:ecJhr+RdYEdcVgUkjruiYhjbBloIEGov7bos90cZi0Q=` when using Fenix, and prefer `inputs.fenix.packages.${system}` directly for cache-friendly packages.
  - Check: generated `nix.custom.conf` lists `fenix.cachix.org`; `nix build .#darwinConfigurations.<host>.system --dry-run --extra-substituters https://fenix.cachix.org --extra-trusted-public-keys 'fenix.cachix.org-1:ecJhr+RdYEdcVgUkjruiYhjbBloIEGov7bos90cZi0Q='` should fetch Fenix Rust paths instead of building Rust Analyzer from source.

## Nix / Bun packages

- Do not put Bun global-bin paths before Home Manager profile paths when adding Home Manager wrappers for the same command.
  - Mistake: kept `~/.cache/.bun/bin` before `/etc/profiles/per-user/$USER/bin` while adding a Home Manager `pi` wrapper.
  - Result: the old Bun global shim won `PATH`, so the Nix-managed wrapper never ran.
  - Fix: put Home Manager profile paths before `~/.bun/bin` / `~/.cache/.bun/bin`, or remove the stale global shim.
  - Check: `which -a <command>` must show the Home Manager profile path before Bun global-bin paths.

- Do not use plain `bunx <pkg>@latest` for wrappers expected to refresh latest on each run.
  - Mistake: used `bunx --bun -p <pkg>@latest <bin>`, which can reuse Bun's cached install.
  - Result: commands may stay on the previously cached package version.
  - Fix: use `bun --prefer-latest x --bun -p <pkg>@latest <bin>` so Bun checks the registry.
  - Check: run the wrapper and confirm it resolves/checks when a newer package exists.

- Do not assume a renamed npm package's old scope receives new releases.
  - Mistake: used `@mariozechner/pi-coding-agent@latest` for Pi after the package moved to `@earendil-works/pi-coding-agent`.
  - Result: Bun correctly installed npm `latest`, but that old package's `latest` was stale.
  - Fix: verify the current package name from the upstream package metadata or Nix expression before writing wrapper.
  - Check: compare `curl https://registry.npmjs.org/<encoded-package>/latest` with upstream release tags.

## Nix / pnpm packages

- Do not put Determinate Nix custom cache settings in generated `/etc/nix/nix.conf` or inert `nix.settings` while `nix.enable = false`.
  - Mistake: configured Cachix keys/substituters under nix-darwin `nix.settings` even though Determinate Nix owned the daemon and `/etc/nix/nix.conf`.
  - Result: Helix Cachix was present as a key but not as an active substituter, so Helix source builds compiled instead of fetching binaries.
  - Fix: keep `nix.enable = false`, manage `/etc/nix/nix.custom.conf` with `environment.etc."nix/nix.custom.conf"`, and let Determinate Nix include it.
  - Check: `nix config show | rg 'substituters|trusted-public-keys'` must show the cache URL and key; `nix build github:helix-editor/helix --dry-run` should say paths will be fetched, not built.

- Do not keep stale custom pins for npm/pnpm packages when nixpkgs already carries the desired version.
  - Mistake: pinned `svelte-language-server` to `0.17.29` while locked nixpkgs provided newer `0.18.0`.
  - Result: Home Manager built the old override and failed inside `pnpmConfigHook` due stale pnpm-deps output layout.
  - Fix: prefer deleting the override; if a custom override is still needed, align `fetchPnpmDeps.pnpm`, `fetcherVersion`, and hash.
  - Check: eval the package version and build the package derivation directly.

## Nix / Python packages

- Do not install Python plugin packages beside wrapped Python applications and expect runtime imports to work.
  - Mistake: installed `dooit-extras` and `dooit` as separate Home Manager packages while `dooit/config.py` imported `dooit_extras`.
  - Result: `dooit` wrapper ran with its own site-packages and `PYTHONNOUSERSITE=true`, so startup crashed with `ModuleNotFoundError: dooit_extras`.
  - Fix: pass the plugin package through the app wrapper, e.g. `(dooit.override { extraPackages = [ dooit-extras ]; })`.
  - Check: inspect the generated wrapped script for the plugin site-packages path or run the app startup/import path.

## nix-darwin Homebrew

- Do not rely on nix-darwin `homebrew.onActivation.cleanup = "uninstall"` after Homebrew deprecates `brew bundle install --cleanup`.
  - Mistake: let nix-darwin generate `brew bundle ... --cleanup --force-cleanup`.
  - Result: Homebrew warns `Calling the --cleanup switch is deprecated! There is no replacement.` during activation; older configs without force also abort waiting for cleanup confirmation.
  - Fix: set `homebrew.onActivation.cleanup = "none"` and keep `homebrew.onActivation.extraFlags = [ "--force-cleanup" ];`; current Homebrew Bundle still treats `--force-cleanup` as a cleanup request.
  - Check: eval `config.homebrew.onActivation.brewBundleCmd` and confirm `--force-cleanup` is present and `--cleanup` is absent.

- Do not let nix-darwin Homebrew activation depend on shell-only Homebrew/XDG state or bulk upgrades.
  - Mistake: trusted `hatchet-dev/hatchet` while `$XDG_CONFIG_HOME` was set, writing `~/.config/homebrew/trust.json`; activation runs `sudo --user ... --set-home env brew bundle` without `XDG_CONFIG_HOME`. Also `homebrew.onActivation.autoUpdate = true` and `upgrade = true` made every switch fetch many outdated casks/formulae.
  - Result: activation still saw the tap as untrusted and/or failed on unrelated cask downloads, aborting the whole Nix switch.
  - Fix: set `homebrew.onActivation.extraEnv.XDG_CONFIG_HOME = "/Users/kenrictee/.config"` and keep activation upgrades disabled; run `brew update && brew upgrade` manually when desired.
  - Check: eval `config.homebrew.onActivation.brewBundleCmd` and confirm `XDG_CONFIG_HOME=...`, `HOMEBREW_NO_AUTO_UPDATE=1`, and `--no-upgrade`.

## launchd / Home Manager

- Update service secret consumers when migrating to sops-nix, and verify the configured identity can decrypt.
  - Mistake: Glance still sourced removed `~/.cache/zsh/secrets.env`, while sops-nix pointed at an older age identity that did not match the encrypted file.
  - Result: sops-nix failed decryption and Glance exited before binding port 8080.
  - Fix: reference the existing matching identity with a runtime string path and read `RAINDROP_TOKEN` from the evaluated Home Manager `sops.secrets.RAINDROP_TOKEN.path`. Keep private keys untracked and out of Nix file sources; let launchd KeepAlive retry until the secret is readable.
  - Check: decrypt with the evaluated `sops.age.keyFile` to `/dev/null`, run `bun test tests/machine-paths.test.ts` (including missing-secret and custom-path cases), and check `curl -I http://127.0.0.1:8080/` after switching.

- Do not carry stale service flags across package upgrades.
  - Mistake: kept `memos --mode=prod` after nixpkgs moved to Memos `0.29.0`, whose CLI no longer supports `--mode`.
  - Result: launchd kept restarting `dev.memos`; `localhost:8082` refused connections while logs repeated `Error: unknown flag: --mode`.
  - Fix: remove `--mode=prod`; run Memos directly with supported flags like `--data` and `--port`.
  - Check: `memos --help` must list every configured flag; `curl -I http://127.0.0.1:<port>/` should return `200 OK`.

- Do not use Home Manager `launchd.agents` for macOS Background Items that need distinct names.
  - Mistake: moved user services to Home Manager `launchd.agents` and expected `ProgramArguments[0]` to remain the service binary.
  - Result: Home Manager rewrote plists to `/bin/sh -c "/bin/wait4path /nix/store && exec ..."`, so macOS Settings listed many indistinguishable `sh` background items.
  - Fix: use nix-darwin `launchd.user.agents.<name>.serviceConfig` for those services, or install unmanaged plists yourself.
  - Check: `plutil -p ~/Library/LaunchAgents/<label>.plist | rg -A8 ProgramArguments` must show the service-specific executable at index `0`, not `/bin/sh`.

## MPD / Home Manager

- Use explicit RON option syntax unless the config enables `implicit_some`.
  - Mistake: configured `status_update_interval_ms: 1000` without `#![enable(implicit_some)]`.
  - Result: rmpc 0.11 rejected the config with `status_update_interval_ms: Expected option` and silently fell back to defaults despite exiting successfully.
  - Fix: use `status_update_interval_ms: Some(1000)`.
  - Check: run `bun test tests/rmpc-config.test.ts`, then check live `rmpc debuginfo` for a populated config path and no fallback warning; exit status alone is insufficient.

- Do not let launchd MPD depend on a removable `~/Library/Logs/mpd` directory.
  - Mistake: started Home Manager's generated Darwin config without `--stderr`, so MPD had to open its hard-coded `log_file` before binding its socket.
  - Result: when the log directory disappeared, MPD crash-looped with exit code `1` and both `rmpc` and `mpc` reported `Connection refused`.
  - Fix: pass `--stderr` and route launchd's `StandardErrorPath` to `${services.mpd.dataDir}/log.txt`; retain the `Library/Logs/mpd/.keep` file for plain manual MPD runs.
  - Check: the evaluated launch agent must contain `--stderr` and a `StandardErrorPath` under `services.mpd.dataDir`; with `~/Library/Logs/mpd` absent, a foreground launch using `--stderr` must get past log initialization.

- Do not expose a minimal manual MPD config without explicit state paths.
  - Mistake: linked `~/.config/mpd/mpd.conf` with `music_directory` only and no `db_file`, `state_file`, or `sticker_file`.
  - Result: plain `mpd` defaulted its database to `~/Library/Caches/mpd/db`, which failed when that directory did not exist and diverged from `services.mpd.dataDir = "~/.mpd"`.
  - Fix: keep manual config state files pointed at `~/.mpd`.
  - Check: run `mpd --no-daemon /path/to/mpd.conf --stderr --verbose` on an alternate port and confirm it gets past database loading.

## Ghostty / Nushell

- Generate Ghostty's Nushell startup paths with Home Manager, rather than relying on GUI session PATH or one host's profile layout.
  - Mistake: shared Ghostty config used `/etc/profiles/per-user/$USER/bin/nu` and `/Users/kenrictee/.config`, which do not match standalone Linux Home Manager; plain `nu --login` also fails when GUI PATH lacks Nix binaries.
  - Result: startup could not find Nu or used the wrong configuration directory. `home.sessionPath` inside Nu cannot help find the initial executable.
  - Fix: generate `~/.config/ghostty-nix.conf` with `lib.getExe config.programs.nushell.package` and explicit `--config-home`. Keep it outside the live Ghostty directory symlink. Include it optionally so an unapplied generation adds no missing-file error; it overrides the existing fallback after activation. Keep Nu first: Ghostty inserts its `--execute` integration argument immediately after the executable.
  - Check: run `bun test tests/ghostty-startup.test.ts` to evaluate both profiles and test generated commands with minimal PATH, then validate Ghostty's config with and without the include. Test real login startup in a PTY: this profile's `GPG_TTY = (tty)` initialization exits in a non-TTY probe.

- Load the shared Ghostty config from only one default location on macOS.
  - Mistake: linked both `~/.config/ghostty` and `~/Library/Application Support/com.mitchellh.ghostty` to the same directory, then added a `config-file` include.
  - Result: the GUI loaded the include twice and reported `cycle detected`. Validating each config path separately missed the duplicate load.
  - Fix: keep the XDG directory symlink and remove the redundant Application Support mapping. Home Manager removes the obsolete link on the next switch; the repository directory stays intact.
  - Check: `bun test tests/ghostty-startup.test.ts` must load all evaluated config paths together through Ghostty, not validate each in isolation.

- Validate temporary macOS Ghostty configs using an explicit file path.
  - Mistake: used a temporary `HOME` with `+show-config` to check edits through a fixture symlink.
  - Result: macOS Application Support discovery still found the real user's config, which overrode fixture settings.
  - Fix: use `+validate-config --config-file=<fixture>` for isolated loader checks; `HOME` alone does not isolate macOS default config discovery.
  - Check: an invalid setting added to the fixture must fail validation through each symlink, then pass after correction.

## BetterDisplay

- Do not infer mirror direction from a single display selector or guess CLI flags.
  - Mistake: simplified mirroring to `--namelike=LG --mirror=on` without an explicit target, then tried `--help` instead of the app's `help` command.
  - Result: mirror direction was unspecified and the help probe hung instead of verifying the command.
  - Fix: use `BetterDisplay help`, verify names with `get --identifier=name`, and provide source and target selectors explicitly when enabling mirroring.
  - Check: inspect emitted arguments for both mirror directions; the selected source is mirrored onto `--targetNameLike`.

## AeroSpace / SketchyBar

- Resolve command paths from AeroSpace's own execution environment before diagnosing moved scripts.
  - Mistake: assumed `$SCRIPTS` came from the current Home Manager configuration and reported a broken toggle because its script was absent from the new checkout.
  - Result: the audit missed `[exec.env-vars]`, which still pointed to a working script in the old checkout.
  - Fix: inspect the loaded binding and AeroSpace's effective environment, then check the resolved target. Distinguish a legacy-checkout dependency from a runtime failure.
  - Check: query `aerospace config --get mode.main.binding.alt-ctrl-shift-b` and `aerospace list-exec-env-vars`; verify the resulting script or command path without toggling the desktop.

- Do not use rounded global SketchyBar corners with zero margin when edge-to-edge coverage is intended.
  - Mistake: combined `margin = 0` with a large global bar `corner_radius`.
  - Result: the rounded path left transparent pixels at both display edges, exposing wallpaper behind the bar.
  - Fix: set the global bar radius to `0`; keep item or frame radii independent when rounded modules are still desired.
  - Check: in a Retina screenshot, the first and last pixel columns through the bar midpoint must contain bar pixels, not wallpaper.

- Do not use SketchyBar process/query state as the source of truth for paired bar visibility and AeroSpace gaps.
  - Mistake: used `pgrep` / `sketchybar --query bar` to decide whether the next toggle should show or hide the bar.
  - Result: query/process-check failures can leave AeroSpace `outer.top` visible while the bar is hidden, creating an empty top gap.
  - Fix: derive toggle state from the configured `outer.top` gap and send `sketchybar --bar hidden=...` as a best-effort side effect.
  - Check: run the toggle twice and confirm `outer.top` flips to `0`, then back to the visible gap.

- Do not assume AeroSpace `outer.top` protects floating windows from SketchyBar.
  - Mistake: left a normal app window in `floating` layout while debugging top gap behavior.
  - Result: the visible SketchyBar overlays that window because workspace gaps only affect tiled layout.
  - Fix: force normal app windows to `layout tiling`; keep only intentional PiP/utility windows floating.
  - Check: `aerospace list-windows --focused --format '%{window-layout}'` should print `tiling` for normal windows.
