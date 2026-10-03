"""Read-only checks for filesystem prerequisites of this repo's services."""

import os
from pathlib import Path
import plistlib
import shlex
import sys
import xml.etree.ElementTree as ET


def audit(home, repo, platform, config_home, state_home):
    issues = []
    checked = 0

    def issue(level, label, path, reason):
        issues.append(f"{level} {label}: {path} — {reason}")

    def check(label, path, *, directory=False, nonempty=True, writable=False):
        nonlocal checked
        checked += 1
        path = Path(path)
        try:
            info = path.stat()
            if path.is_dir() != directory or (not directory and not path.is_file()):
                issue("ERROR", label, path, "expected directory" if directory else "expected file")
                return False
            mode = os.R_OK | (os.X_OK if directory else 0) | (os.W_OK if writable else 0)
            if not os.access(path, mode):
                issue(
                    "ERROR",
                    label,
                    path,
                    "insufficient read/search/write permissions"
                    if writable
                    else "not readable/searchable",
                )
                return False
            if nonempty:
                if directory:
                    # Placeholders and sync metadata are not user content.
                    ignored = {".keep", ".DS_Store", ".stfolder", ".stversions"}
                    if not any(child.name not in ignored for child in path.iterdir()):
                        issue(
                            "WARN",
                            label,
                            path,
                            "empty directory (not necessarily a startup failure)",
                        )
                elif info.st_size == 0:
                    issue("ERROR", label, path, "empty file")
                    return False
            return True
        except FileNotFoundError:
            issue("ERROR", label, path, "broken symlink" if path.is_symlink() else "missing")
        except OSError as error:
            issue("ERROR", label, path, error.strerror)
        return False

    def output(label, path):
        path = Path(path)
        check(label + " parent", path.parent, directory=True, nonempty=False, writable=True)
        # Daemons create output files; only their parent must already exist.
        if path.exists() or path.is_symlink():
            check(label, path, nonempty=False, writable=True)

    def expand(path):
        return home / path[2:] if path.startswith("~/") else Path(path)

    # hm/media.nix shares this generated configuration with the service.
    mpd_config = config_home / "mpd/mpd.conf"
    if check("MPD config", mpd_config):
        try:
            settings = {}
            for line in mpd_config.read_text().splitlines():
                words = shlex.split(line, comments=True)
                if len(words) == 2:
                    settings[words[0]] = words[1]
            for key in ("music_directory", "playlist_directory"):
                if not settings.get(key):
                    issue("ERROR", "MPD", mpd_config, f"missing {key}")
                else:
                    check(
                        "MPD " + key,
                        expand(settings[key]),
                        directory=True,
                        writable=key == "playlist_directory",
                    )
            for key in ("db_file", "state_file", "sticker_file", "log_file"):
                if settings.get(key) and settings[key] != "syslog":
                    output("MPD " + key, expand(settings[key]))
        except (OSError, ValueError) as error:
            issue("ERROR", "MPD config", mpd_config, f"cannot read/parse ({type(error).__name__})")

    # hm/security.nix: metadata only; never print or decrypt secret contents.
    check("sops age identity", repo / "secrets/keys.txt")

    # hm/sync.nix / flake.nix: inspect actual folders, including per-host enablement.
    if platform == "darwin":
        sync_dir = home / "Library/Application Support/Syncthing"
    else:
        sync_dir = state_home / "syncthing"
        if not sync_dir.exists() and (config_home / "syncthing").exists():
            sync_dir = config_home / "syncthing"
    sync_config = sync_dir / "config.xml"
    for key in ("cert.pem", "key.pem"):
        check("Syncthing identity", sync_dir / key)
    if check("Syncthing config", sync_config):
        try:
            for folder in ET.parse(sync_config).getroot().findall("folder"):
                if folder.findtext("paused") == "true":
                    continue
                label = "Syncthing " + folder.get("id", "folder")
                if not folder.get("path"):
                    issue("ERROR", label, sync_config, "missing folder path")
                    continue
                path = expand(folder.get("path"))
                check(label, path, directory=True, writable=True)
                marker = path / (folder.findtext("markerName") or ".stfolder")
                check(label + " marker", marker, directory=marker.is_dir(), nonempty=False)
        except (OSError, ET.ParseError) as error:
            issue(
                "ERROR",
                "Syncthing config",
                sync_config,
                f"cannot read/parse ({type(error).__name__})",
            )

    if platform == "darwin":
        # os/darwin/launchd.nix, Home Manager and nix-darwin generated agents.
        agents_dir = home / "Library/LaunchAgents"
        custom = {"dev.glance", "dev.memos", "dev.golink", "eilmeldung.miniflux"}
        if check("launchd agents", agents_dir, directory=True):
            names = {
                path.stem
                for path in agents_dir.glob("*.plist")
                if path.stem in custom
                or path.name.startswith(("org.nix-community.home.", "org.nixos."))
            }
            for name in sorted(names):
                path = agents_dir / f"{name}.plist"
                if not check(name + " plist", path):
                    continue
                try:
                    with path.open("rb") as stream:
                        agent = plistlib.load(stream)
                    if agent.get("Disabled"):
                        continue
                    if agent.get("WorkingDirectory"):
                        check(
                            name + " working directory", agent["WorkingDirectory"], directory=True
                        )
                    for key in ("StandardOutPath", "StandardErrorPath"):
                        if agent.get(key):
                            output(name + " " + key, agent[key])
                    args = agent.get("ProgramArguments", [])
                    program = agent.get("Program") or (args[0] if args else None)
                    if (
                        program
                        and check(name + " executable", program)
                        and not os.access(program, os.X_OK)
                    ):
                        issue("ERROR", name, program, "not executable")
                    pgdata = agent.get("EnvironmentVariables", {}).get("PGDATA")
                    if pgdata and check(name + " data", pgdata, directory=True, writable=True):
                        check(name + " database version", Path(pgdata) / "PG_VERSION")
                    for index, arg in enumerate(args):
                        if arg.startswith("--data="):
                            check(
                                name + " data",
                                arg.split("=", 1)[1],
                                directory=True,
                                nonempty=False,
                                writable=True,
                            )
                        if arg == "--sqlitedb" and index + 1 < len(args):
                            output(name + " database", args[index + 1])
                    # Read the generated wrappers for evaluated secret/config paths.
                    if name in {"dev.glance", "eilmeldung.miniflux"} and program:
                        for line in Path(program).read_text().splitlines():
                            words = shlex.split(line, comments=True)
                            if words and words[0].startswith("raindrop_token_file="):
                                check(name + " secret", words[0].split("=", 1)[1])
                            if words and words[0] == "exec":
                                for index, word in enumerate(words[:-1]):
                                    if word in {"-config", "-c"}:
                                        check(name + " config", words[index + 1])
                    if name == "org.nix-community.home.sketchybar":
                        check("SketchyBar config", config_home / "sketchybar/sketchybarrc")
                except (OSError, ValueError, plistlib.InvalidFileException) as error:
                    issue(
                        "ERROR",
                        name,
                        path,
                        f"cannot read/parse agent or wrapper ({type(error).__name__})",
                    )
    elif platform == "linux":
        # hm/linux/hermes.nix is imported by both Linux desktop profiles.
        check("Hermes working directory", home / ".hermes", directory=True, writable=True)
        check("Signal/Hermes environment", home / ".hermes/.env")
        hermes = home / ".local/bin/hermes"
        if check("Hermes executable", hermes) and not os.access(hermes, os.X_OK):
            issue("ERROR", "Hermes", hermes, "not executable")

    return checked, issues


if __name__ == "__main__":
    home = Path.home()
    checked, issues = audit(
        home,
        Path(__file__).resolve().parent.parent,
        sys.platform,
        Path(os.environ.get("XDG_CONFIG_HOME") or home / ".config"),
        Path(os.environ.get("XDG_STATE_HOME") or home / ".local/state"),
    )
    for message in issues:
        print(message)
    print(f"Checked {checked} paths; {len(issues)} issue(s). Read-only; service health not tested.")
    sys.exit(1 if issues else 0)
