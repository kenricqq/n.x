# ytdl-sub on Laurentii

Configuration reviewed 2026-10-15; earlier research included read-only SSH checks and primary upstream sources. Integration is declared in the repository; deployment and real downloads remain unverified. Jellyfin's configured library paths/UI remain uninspected.

## Recommendation

Feed the **existing Jellyfin server** using NixOS `services.ytdl-sub.instances` and Jellyfin presets. The locked nixpkgs already packages `ytdl-sub` **2026.08.26.post1**, matching the latest upstream release observed during research. No new flake input, container engine, or web port is needed. [Pinned package](https://github.com/NixOS/nixpkgs/blob/b6c8664de9b6cc07fe5666a29f91884ba81197c4/pkgs/by-name/yt/ytdl-sub/package.nix), [upstream release](https://github.com/jmbannon/ytdl-sub/releases/tag/2026.08.26.post1), [pinned module](https://github.com/NixOS/nixpkgs/blob/b6c8664de9b6cc07fe5666a29f91884ba81197c4/nixos/modules/services/misc/ytdl-sub.nix).

## Existing host configuration

- Laurentii is `x86_64-linux` NixOS, user `kenrict`. Its machine module imports the shared Jellyfin module. [Profile](../flake.nix), [machine configuration](../machines/laurentii/nixos.nix).
- `/mnt/library` is Btrfs with `nofail`; Jellyfin requires its mount and exposes HTTP to Tailscale plus one LAN client. Existing QSV playback settings can serve the new videos. [Machine configuration](../machines/laurentii/nixos.nix), [Jellyfin configuration](../os/nixos/jellyfin.nix).
- Earlier SSH checks confirmed `/mnt/library` mounted read/write from `/dev/sda1`, Jellyfin active as `jellyfin:jellyfin`, and `/mnt/library/jellyfin` owned by `kenrict:users`, mode `0755`, containing `lin-alg`. Parent directories allow traversal, but the downloader needs its output root provisioned by root.
- No Docker, Podman, or OCI service deployment was found in Laurentii's declared configuration; live unit listings also showed no ytdl-sub/Docker/Podman units. The shared Home Manager Docker CLI entry is disabled. [Machine configuration](../machines/laurentii/nixos.nix), [development tools](../hm/_dev.nix).

## Installation choices

| Approach | Verified behavior | Fit for Laurentii |
|---|---|---|
| Native NixOS module | Generates YAML, service accounts, instance services, and optional timers. | Recommended: already available in the lock. |
| Headless Docker | `ghcr.io/jmbannon/ytdl-sub:latest`; persistent `/config` plus media volume; no web port. | Useful if independently updated container dependencies become necessary; adds a runtime here. |
| Docker GUI | `ghcr.io/jmbannon/ytdl-sub-gui:latest`; code-server/VS Code in a browser, port 8443. | Choose only for browser-based YAML editing and terminal access; it is not a dedicated subscription dashboard. |

Sources: [pinned NixOS module](https://github.com/NixOS/nixpkgs/blob/b6c8664de9b6cc07fe5666a29f91884ba81197c4/nixos/modules/services/misc/ytdl-sub.nix), [upstream Docker guide](https://ytdl-sub.readthedocs.io/en/latest/guides/install/docker.html).

## Declared native integration

[`os/nixos/jellyfin.nix`](../os/nixos/jellyfin.nix), imported only by Laurentii, configures one instance, `acayt` (academic YouTube), for both 3Blue1Brown and Zero to Hero:

- `acayt` starts in the background on activation or boot through `multi-user.target`. Its `schedule = "0/6:0"` also checks both subscriptions at 00:00, 06:00, 12:00, and 18:00 in the host timezone. Each subscription's existing download archive skips fetched videos; later runs can retry unfinished downloads and fetch new uploads or lessons. There is no separate completion flag.
- Service user `ytdl-sub`, group `jellyfin`; output `/mnt/library/jellyfin/yt` and scratch `/mnt/library/.ytdl-sub-tmp` are provisioned with owner `ytdl-sub:jellyfin`, mode `0750`.
- The downloader and its directory setup service require `/mnt/library` mounted. Directory setup runs as root before the downloader starts.
- `config.configuration.working_directory = lib.mkForce workDir` replaces the instance's `/run/ytdl-sub/<instance>` directory with disk staging on the media filesystem.
- Both directories are in `readWritePaths`; the service uses `ProtectSystem=strict`. Application `umask = "027"` produces group-readable output.
- The module generates YAML from `.config` and `.subscriptions`. Keep cookies out of these store files except for a reference to their runtime path.

State directory: `/var/lib/ytdl-sub/acayt`. Subscription names and media paths are unchanged, preserving existing download archives. Sources: [pinned module](https://github.com/NixOS/nixpkgs/blob/b6c8664de9b6cc07fe5666a29f91884ba81197c4/nixos/modules/services/misc/ytdl-sub.nix), [configuration reference](https://ytdl-sub.readthedocs.io/en/latest/config_reference/config_yaml.html), [upstream staging guidance](https://github.com/jmbannon/ytdl-sub/blob/2026.08.26.post1/docker/root/defaults/config.yaml).

After activation, optionally run `yt-refresh` to check both subscriptions immediately and follow download logs. Laurentii runs it locally; Mac and Meridian use SSH with a terminal for sudo, targeting Laurentii through their `ytHost` profile. Ctrl-C stops log viewing; the downloader continues. This does not trigger a Jellyfin library scan.

Run `jescan` to request a scan of all configured Jellyfin libraries. It runs locally on Laurentii; Mac and Meridian SSH into Laurentii using the same `ytHost` routing. Success means the scan request was accepted, not that scanning has finished. [Scan endpoint](https://github.com/jellyfin/jellyfin/blob/master/Jellyfin.Api/Controllers/LibraryController.cs).

One-time setup: create an API key named `jescan` in Jellyfin's Dashboard → API Keys, then use `sec` to save it as `JELLYFIN_API_KEY` in encrypted `secrets/secrets.yaml`. Home Manager declares the secret in `hm/security.nix`; activate Laurentii's configuration to install the command and provision the secret. The command reads the evaluated SOPS secret path at runtime. Remote commands use Laurentii's secret. Authentication uses Jellyfin's current `Authorization: MediaBrowser` header, passed to curl through stdin. [Authorization format](https://gist.github.com/nielsvanvelzen/ea047d9028f676185832e51ffaf12a6f).

Neither subscription needs an initial command. Follow automatic downloads on Laurentii:

```sh
sudo journalctl -fu ytdl-sub-acayt.service
```

## Weaving it into existing Jellyfin

Add a **YouTube** library to the same server, content type **Shows**, pointing to `/mnt/library/jellyfin/yt`. The channel uses upload years as seasons; the course uses one season with playlist positions as episode numbers. Inspect current roots first: if an existing library scans `/mnt/library/jellyfin`, choose a separate nonoverlapping output path or deliberately adjust that library. Its definitions require access unavailable to the SSH user. [Jellyfin Shows](https://jellyfin.org/docs/general/server/media/shows/), [ytdl-sub TV presets](https://ytdl-sub.readthedocs.io/en/latest/prebuilt_presets/tv_shows.html).

Recommendation: disable remote metadata/image providers for this library, since ytdl-sub supplies titles, NFO files, and artwork. Leave **Nfo saver** off; Jellyfin reads NFO automatically and prioritizes local metadata, while that option enables writing NFO. Enable real-time monitoring; Jellyfin uses Linux inotify for added/changed files. Verify a sample appears automatically before adding any scan API hook. [NFO behavior](https://jellyfin.org/docs/general/server/metadata/nfo/), [monitoring behavior](https://jellyfin.org/docs/general/administration/troubleshooting.html/#real-time-monitoring).

## Subscriptions and validation

The [Nix configuration](../os/nixos/jellyfin.nix) is the subscription source of truth:

| Subscription | Layout | Fixed cutoff |
|---|---|---|
| 3Blue1Brown regular uploads | TV Show by Date | `20260913` |
| Neural Networks - Zero to Hero | TV Show Collection, season `Lessons`, playlist-index ordering | `19700101` (entire playlist) |

Both use `Max 2160p`, preserve archived downloads, remove all removable SponsorBlock categories while retaining highlight markers, and save English SRT subtitles with autogenerated captions as fallback. The playlist scans past archived entries to find additions; removals or reordering require manual reconciliation of episode numbers. [TV presets](https://ytdl-sub.readthedocs.io/en/latest/prebuilt_presets/tv_shows.html), [quality presets](https://ytdl-sub.readthedocs.io/en/latest/prebuilt_presets/media_quality.html), [plugin reference](https://ytdl-sub.readthedocs.io/en/latest/config_reference/plugins.html).

After installation, obtain the executable and generated YAML paths from `systemctl cat ytdl-sub-acayt.service`. Preview under the service account using those paths (uppercase names below are placeholders):

```sh
YTDL_SUB_PATH --dry-run --config CONFIG_PATH --match="3Blue1Brown" sub SUBSCRIPTIONS_PATH -o '--ytdl_options.max_downloads 3'
```

The dry run fetches metadata but does not download videos or write the output directories. Repeat without `--dry-run` for up to three real entries, then inspect files and Jellyfin metadata. This end-to-end validation has not been run. [CLI reference](https://ytdl-sub.readthedocs.io/en/latest/usage.html), [upstream validation workflow](https://ytdl-sub.readthedocs.io/en/latest/guides/getting_started/downloading.html).

## State, updates, and YouTube requirements

The download archive is a hidden `.ytdl-sub-...-download-archive.json` in each subscription's output directory. Preserve it with the media; application state is not confined to `/var/lib` or Docker `/config`. [Archive behavior](https://ytdl-sub.readthedocs.io/en/latest/faq/index.html#force-ytdl-sub-to-re-download-a-file).

The pinned package supplies FFmpeg/FFprobe and the pinned yt-dlp package includes `yt-dlp-ejs`, with Deno's absolute path patched into Python runtime discovery. This matters because ytdl-sub calls yt-dlp's Python API. No additional JavaScript runtime installation is indicated by the inspected source; a real YouTube download remains necessary to verify runtime behavior. Update through the repository's nixpkgs lock when extractor fixes are needed. [ytdl-sub package](https://github.com/NixOS/nixpkgs/blob/b6c8664de9b6cc07fe5666a29f91884ba81197c4/pkgs/by-name/yt/ytdl-sub/package.nix), [yt-dlp package](https://github.com/NixOS/nixpkgs/blob/b6c8664de9b6cc07fe5666a29f91884ba81197c4/pkgs/by-name/yt/yt-dlp/package.nix), [Python API use](https://github.com/jmbannon/ytdl-sub/blob/2026.08.26.post1/src/ytdl_sub/downloaders/ytdlp.py).

YouTube needs an external JavaScript runtime plus matching EJS scripts; upstream recommends Deno. Start without cookies; restricted content or authentication challenges may require them. If needed, set `ytdl_options.cookiefile` to a protected runtime file; do not put cookie contents in Git or the Nix store. Some YouTube formats may additionally require PO tokens; add that machinery only for an observed failure. [EJS requirements](https://github.com/yt-dlp/yt-dlp/wiki/EJS), [YouTube extractor guidance](https://github.com/yt-dlp/yt-dlp/wiki/Extractors), [ytdl-sub cookie option](https://ytdl-sub.readthedocs.io/en/latest/faq/index.html#download-age-restricted-youtube-videos).

## Docker fallback details

Headless uses `/config`; GUI uses `/config/ytdl-sub-configs` for YAML and cron. Set `PUID`/`PGID` to IDs with media access, and mount persistent configuration plus output. Both upstream images install Deno and EJS. [Docker guide](https://ytdl-sub.readthedocs.io/en/latest/guides/install/docker.html), [headless source](https://github.com/jmbannon/ytdl-sub/blob/2026.08.26.post1/docker/Dockerfile), [GUI source](https://github.com/jmbannon/ytdl-sub/blob/2026.08.26.post1/docker/Dockerfile.gui).

`CRON_SCHEDULE="0 */6 * * *"` enables cron, but the generated `cron` script initially only prints a warning: explicitly configure it to run `ytdl-sub sub`. Leave `CRON_RUN_ON_START` unset/false to avoid extra runs on restarts. [Automation guide](https://ytdl-sub.readthedocs.io/en/latest/guides/getting_started/automating_downloads.html), [default cron script](https://github.com/jmbannon/ytdl-sub/blob/2026.08.26.post1/docker/root/defaults/cron).

`UPDATE_YT_DLP_ON_START=stable|nightly|master` updates yt-dlp and default dependencies at startup; unset uses packaged versions. This can deliver extractor fixes independently of ytdl-sub, but makes dependency versions vary between starts. Pin the image digest and leave this unset when reproducibility matters. [Startup implementation](https://github.com/jmbannon/ytdl-sub/blob/2026.08.26.post1/docker/root/custom-cont-init.d/defaults).

## Remaining deployment checks

Inspect actual Jellyfin library roots, deploy the declared configuration, and validate a sample download and library scan. Repository instructions require explicit approval before any build or activation; none was attempted during this cleanup.
