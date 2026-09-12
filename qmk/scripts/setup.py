#!/usr/bin/env python3
"""Recreate the pinned QMK checkout and link the local keymap into it."""

from pathlib import Path
import os
import subprocess


ROOT = Path(__file__).resolve().parent.parent
FIRMWARE = ROOT / "firmware"
KEYMAP = ROOT / "keymaps" / "miryoku_callum"
LINK = FIRMWARE / "keyboards/crkbd/keymaps/miryoku_callum"
REVISION = (ROOT / "qmk-revision").read_text().strip()


def git(*args, capture=False):
    return subprocess.run(
        ["git", *args], check=True, text=True,
        stdout=subprocess.PIPE if capture else None,
    ).stdout


def main():
    if not (KEYMAP / "keymap.c").is_file():
        raise SystemExit(f"Missing custom source: {KEYMAP}")

    if not FIRMWARE.exists():
        git("clone", "--no-checkout", "--depth", "1",
            "https://github.com/qmk/qmk_firmware.git", str(FIRMWARE))
        git("-C", str(FIRMWARE), "fetch", "--depth", "1", "origin", REVISION)
        git("-C", str(FIRMWARE), "checkout", "--detach", REVISION)

    # Never switch an existing checkout or overwrite a different keymap.
    checkout = git("-C", str(FIRMWARE), "rev-parse", "--show-toplevel", capture=True).strip()
    if Path(checkout).resolve() != FIRMWARE.resolve():
        raise SystemExit(f"Not a QMK checkout: {FIRMWARE}")
    actual = git("-C", str(FIRMWARE), "rev-parse", "HEAD", capture=True).strip()
    if actual != REVISION:
        raise SystemExit(f"QMK is at {actual}; expected {REVISION}. Existing checkout left unchanged.")
    if LINK.is_symlink():
        if LINK.resolve() != KEYMAP.resolve():
            raise SystemExit(f"Different symlink already exists: {LINK}")
    elif LINK.exists():
        raise SystemExit(f"A real keymap already exists at {LINK}; preserve it before replacing it.")

    git("-C", str(FIRMWARE), "submodule", "update", "--init", "--depth", "1",
        "lib/chibios", "lib/chibios-contrib", "lib/pico-sdk", "lib/printf",
        "lib/lufa", "lib/googletest")
    if not LINK.is_symlink():
        LINK.symlink_to(os.path.relpath(KEYMAP, LINK.parent), target_is_directory=True)
    print(f"Ready: {LINK.relative_to(ROOT)} -> {os.readlink(LINK)}")


if __name__ == "__main__":
    main()
