"""Do the demos still compile?

gd-chime. MIT licensed; see the LICENCE file at the root of this folder.

Runs demos_compile.gd, which loads every demo script without running it, and
fails on anything the engine says about them. Two signals must agree: the
loader said how many it loaded, and nothing in the output is a complaint.

The count is needed because loading nothing proves nothing. The complaint is
needed because load() cannot be asked - measured on 4.6.2, it hands back a
script object even for one that failed to parse, and reports the failure only
by printing it.

The demos are the one part of the folder nothing else touches. The tests run
only tests/test_*.gd, both lints read text without compiling it, and the
installation check runs one small app, and the tests are the tests. So a demo can rot
until somebody opens it - which is not hypothetical: a NOTIFICATION_SORT_CHILDREN
in a plain Control never parsed, and every other check passed on it.
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

# the flag that spawns the engine without a console window; absent, and nothing, off Windows
NO_WINDOW = getattr(subprocess, "CREATE_NO_WINDOW", 0)

# what the engine prints when a script did not compile; the call itself says nothing
FAILURE_MARKS = ("Parse Error", "Compile Error", "SCRIPT ERROR", "Failed to load")


def main() -> int:
    root, engine = Path(sys.argv[1]), Path(sys.argv[2])
    loader = Path(__file__).parent / "demos_compile.gd"

    run = subprocess.run(
        [str(engine), "--headless", "--path", str(root), "--script", str(loader.resolve())],
        capture_output=True,
        text=True,
        # no console window for the engine: run from a scheduler, it would open one
        creationflags=NO_WINDOW,
    )
    said = run.stdout + run.stderr
    # every line the engine complained on, so the report names the file rather than the count
    complaints = [line for line in said.splitlines() if any(mark in line for mark in FAILURE_MARKS)]

    # every complaint, on a line of its own
    for line in complaints:
        print(line.strip(), file=sys.stderr)
    print(said.splitlines()[-1].strip() if said else "the loader said nothing", file=sys.stderr)
    return 1 if complaints or run.returncode != 0 else 0


if __name__ == "__main__":
    sys.exit(main())
