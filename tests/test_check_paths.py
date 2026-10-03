from pathlib import Path
import plistlib
import runpy
import tempfile
import unittest


audit = runpy.run_path(Path(__file__).resolve().parents[1] / "scripts/check-paths.py")["audit"]


class CheckPathsTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="service paths ")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.home = self.root / "home"
        self.repo = self.root / "repo"
        self.config = self.home / "custom config"
        self.state = self.home / "custom state"
        self.music = self.home / "Music/custom library"
        self.playlists = self.music / "saved playlists"
        self.put(self.music / "song.mp3")
        self.put(self.playlists / "mix.m3u")
        self.put(
            self.config / "mpd/mpd.conf",
            f"""
music_directory "{self.music}"
playlist_directory "{self.playlists}"
db_file "{self.state}/mpd/database"
log_file "{self.state}/mpd/log"
""",
        )
        self.put(self.state / "mpd/log", "")
        self.put(self.repo / "secrets/keys.txt")
        self.sync = self.state / "syncthing"
        self.put(self.sync / "cert.pem")
        self.put(self.sync / "key.pem")
        self.put(
            self.sync / "config.xml",
            """<configuration>
<folder id="sync" path="~/Sync"><markerName>.marker</markerName></folder>
<folder id="paused" path="/absent"><paused>true</paused></folder>
</configuration>""",
        )
        self.put(self.home / "Sync/note.txt")
        (self.home / "Sync/.marker").mkdir()
        self.put(self.home / ".hermes/.env")
        self.put(self.home / ".local/bin/hermes", "#!/bin/sh\nexit 0\n", executable=True)

    def put(self, path, text="content\n", *, executable=False):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
        if executable:
            path.chmod(0o755)
        return path

    def issues(self, platform="linux"):
        _, issues = audit(self.home, self.repo, platform, self.config, self.state)
        return "\n".join(issues)

    def test_valid_paths_allow_empty_logs_absent_generated_database_and_empty_marker(self):
        self.assertEqual(self.issues(), "")

    def test_missing_configured_playlist_directory(self):
        (self.playlists / "mix.m3u").unlink()
        self.playlists.rmdir()
        issues = self.issues()
        self.assertIn(f"ERROR MPD playlist_directory: {self.playlists} — missing", issues)

    def test_placeholder_only_playlist_directory_warns(self):
        (self.playlists / "mix.m3u").unlink()
        self.put(self.playlists / ".keep", "")
        self.put(self.playlists / ".DS_Store")
        self.assertIn(
            f"WARN MPD playlist_directory: {self.playlists} — empty directory", self.issues()
        )

    def test_broken_config_symlink_and_empty_secret_are_errors(self):
        config = self.config / "mpd/mpd.conf"
        config.unlink()
        config.symlink_to(self.root / "missing.conf")
        self.put(self.repo / "secrets/keys.txt", "")
        issues = self.issues()
        self.assertIn("broken symlink", issues)
        self.assertIn("keys.txt — empty file", issues)

    def test_output_parent_must_be_directory_and_writable(self):
        (self.state / "mpd/log").unlink()
        (self.state / "mpd").rmdir()
        self.put(self.state / "mpd")
        self.assertIn("expected directory", self.issues())
        (self.state / "mpd").unlink()
        (self.state / "mpd").mkdir(mode=0o555)
        self.addCleanup(lambda: (self.state / "mpd").chmod(0o755))
        self.assertIn("insufficient read/search/write permissions", self.issues())

    def test_syncthing_marker_missing_and_bad_xml_report_errors(self):
        (self.home / "Sync/.marker").rmdir()
        self.assertIn("Syncthing sync marker", self.issues())
        self.put(self.sync / "config.xml", "<invalid")
        self.assertIn("cannot read/parse (ParseError)", self.issues())

    def darwin_agents(self):
        destination = self.home / "Library/Application Support/Syncthing"
        destination.parent.mkdir(parents=True)
        self.sync.rename(destination)
        self.secret = self.put(self.root / "runtime secrets/token", "secret-not-for-output")
        self.glance_config = self.put(self.root / "service configs/glance.yml")
        miniflux_config = self.put(self.root / "service configs/miniflux.env")
        glance = self.put(
            self.root / "bin/glance",
            f"""#!/bin/sh
raindrop_token_file='{self.secret}'
exec '/unused/glance' -config '{self.glance_config}'
""",
            executable=True,
        )
        miniflux = self.put(
            self.root / "bin/miniflux",
            f"""#!/bin/sh
exec '/unused/miniflux' -c '{miniflux_config}'
""",
            executable=True,
        )
        programs = {
            "dev.glance": glance,
            "eilmeldung.miniflux": miniflux,
            "dev.memos": glance,
            "dev.golink": glance,
        }
        self.logs = self.home / "Library/Logs/service"
        self.logs.mkdir(parents=True)
        for name, program in programs.items():
            path = self.home / f"Library/LaunchAgents/{name}.plist"
            path.parent.mkdir(parents=True, exist_ok=True)
            with path.open("wb") as stream:
                plistlib.dump(
                    {
                        "Label": name,
                        "ProgramArguments": [str(program)],
                        "WorkingDirectory": str(self.repo),
                        "StandardErrorPath": str(self.logs / "error.log"),
                    },
                    stream,
                )

    def test_launchd_log_parents_and_evaluated_config_and_secret_paths(self):
        self.darwin_agents()
        self.assertEqual(self.issues("darwin"), "")
        self.logs.rmdir()
        self.glance_config.unlink()
        self.secret.write_text("")
        issues = self.issues("darwin")
        self.assertIn("dev.glance StandardErrorPath parent", issues)
        self.assertIn(f"dev.glance config: {self.glance_config} — missing", issues)
        self.assertIn(f"dev.glance secret: {self.secret} — empty file", issues)
        self.assertNotIn("secret-not-for-output", issues)

    def test_postgresql_data_path_comes_from_installed_agent(self):
        self.darwin_agents()
        path = self.home / "Library/LaunchAgents/org.nixos.postgresql.plist"
        pgdata = self.root / "missing database"
        with path.open("wb") as stream:
            plistlib.dump({"EnvironmentVariables": {"PGDATA": str(pgdata)}}, stream)
        self.assertIn(f"org.nixos.postgresql data: {pgdata} — missing", self.issues("darwin"))

    def test_removed_or_disabled_agents_do_not_require_paths(self):
        self.darwin_agents()
        agents = self.home / "Library/LaunchAgents"
        (agents / "dev.golink.plist").unlink()
        with (agents / "dev.memos.plist").open("wb") as stream:
            plistlib.dump({"Disabled": True, "WorkingDirectory": "/absent"}, stream)
        self.assertEqual(self.issues("darwin"), "")


if __name__ == "__main__":
    unittest.main()
