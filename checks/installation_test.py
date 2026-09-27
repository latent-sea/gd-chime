"""Prove the addon installs: copied alone into another project, it builds a screen, refuses a press and shows the words.

gd-chime. MIT licensed; see the LICENCE file at the root of this folder.

The project is checks/installed/ - its own project.godot, the README's first
screen (stall.gd) in a scene whose root is that ChimeApp (stall.tscn), as the
README tells an author to make it, and check.gd, which adds the scene to its
window, presses its button, reads the words and switches the language once.
This copies that project to a temporary directory, copies addons/gd_chime/ in
beside it and NOTHING ELSE of this folder, imports the copy - GdChime and
ChimeApp are global names, which the engine registers only when its scan
writes the global class cache - and runs check.gd headless. The check passes
when the run exits zero, says INSTALLED OK, and the engine said no error at
all: any ERROR: line fails it, since an error the addon provokes in a game's
project is one the game's author reads.

Before any of that it reads every file under the copied addon and refuses one
that mentions an absolute resource path, demo/, tests/ or checks/: the addon
may sit anywhere in a project, and nothing it ships may reach for what stayed
behind here. The words are matched as text, comments and all, since a comment
that names the folder left behind is a promise the folder is still there.

The engine's import cache is NOT copied, for the reason the extraction check
this replaces gave: a copied cache can satisfy a reference that a genuinely
fresh open would fail on, which is the one way this could pass while the thing
it is named for is false.

Deliberately absent: running the tests in the copy. The tests are the
folder's, run by run_tests.py; what installs is the addon, and what proves it
is a project that never saw the tests.
"""

from __future__ import annotations

import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ADDON = "addons/gd_chime"
INSTALLED = "checks/installed"
# what a shipped file may not say: an absolute resource path, or a folder that stays behind
FORBIDDEN = ("res:" + "//", "demo/", "tests/", "checks/")
NOT_COPIED = shutil.ignore_patterns(".godot", "*.import", "__pycache__")
NO_WINDOW = getattr(subprocess, "CREATE_NO_WINDOW", 0)
RUN_AT_MOST = 1800
FAILURE_MARKS = ("ERROR:", "Parse Error", "Failed to load", "Cannot open file")


def mentions(addon: Path) -> list[str]:
    """Every line of every file under the addon that says a forbidden word, as file:line: word."""
    found: list[str] = []
    # every file under the addon, in a fixed order, read as text
    for path in sorted(addon.rglob("*")):
        if not path.is_file():
            continue
        # every line, for a forbidden word in it
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
            for word in FORBIDDEN:
                if word in line:
                    found.append(f"{path.relative_to(addon).as_posix()}:{number}: {word}")
    return found


def run(engine: Path, project: Path, *arguments: str) -> tuple[int, str]:
    """The engine run headless on the project with these arguments: its exit code and everything it said."""
    ran = subprocess.run([str(engine), "--headless", "--path", str(project), *arguments], capture_output=True, text=True, timeout=RUN_AT_MOST, creationflags=NO_WINDOW, errors="replace")
    return ran.returncode, ran.stdout + ran.stderr


def main() -> int:
    root, engine = Path(sys.argv[1]).resolve(), Path(sys.argv[2])

    with tempfile.TemporaryDirectory() as scratch:
        project = Path(scratch) / "installed"
        shutil.copytree(root / INSTALLED, project, ignore=NOT_COPIED)
        shutil.copytree(root / ADDON, project / ADDON, ignore=NOT_COPIED)
        print(f"copied {INSTALLED} and {ADDON} alone to {project}")

        said = mentions(project / ADDON)
        if said:
            print("\n".join(said), file=sys.stderr)
            print(f"{len(said)} line(s) of the addon reach for what stays behind", file=sys.stderr)
            return 1

        imported, importing = run(engine, project, "--import")
        if imported != 0 or any(mark in importing for mark in FAILURE_MARKS):
            print(importing.strip(), file=sys.stderr)
            print("the copy does not import", file=sys.stderr)
            return 1

        checked, checking = run(engine, project, "--script", "res:" + "//check.gd")
        print(checking.strip())
        if checked != 0 or "INSTALLED OK" not in checking or any(mark in checking for mark in FAILURE_MARKS):
            print("the addon does not install", file=sys.stderr)
            return 1

    print("installs alone", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
