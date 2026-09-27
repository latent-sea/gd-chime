"""Run every test in this folder and refuse to report green unless it ran.

gd-chime. MIT licensed; see the LICENCE file at the root of this folder.

Finds tests/test_*.gd, runs each as its own engine process, and requires THREE
things to agree before calling one passed: the process exited 0, the test said
PASSED and named itself, and nothing in its output is the engine complaining.

Each catches something the others miss. Measured on 4.6.2, a file that will not
parse does exit 1 - but a test that runs, asserts nothing and quits cleanly
also exits 0, and only the named line catches that.

A suite deliberately triggers push_error on every refusal it proves, and
push_warning where a warning is what it proves, so neither an ERROR: nor a
WARNING: line can simply be counted as a failure. Each call prints its own name
in the "at:" line directly below the message and the engine's own complaints do
not, which is the difference this reads: a bad disconnect or a freed instance
reports ERROR: and exits 0, and nothing else would notice.

The engine's warnings are complaints too. Measured on 4.6.2: a control left
unfreed prints WARNING: lines as the process ends - a leaked RID, instances
leaked at exit - after the test has said PASSED, and the process still exits 0;
so does a size set, before it is ready, on a control its anchors will resize.

Each test is a separate process because a class declared in one script is not
registered when another is run bare, so tests sharing a process do not resolve
the same way as tests run alone.

Deliberately absent: no timing, no filtering, no parallel running, and no
retries. A flaky test is a defect to find, not a thing to run twice.
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

# the flag that spawns the engine without a console window; absent, and nothing, off Windows
NO_WINDOW = getattr(subprocess, "CREATE_NO_WINDOW", 0)

# lines the engine prints when a script failed rather than ran; an exit code alone misses these
FAILURE_MARKS = ("SCRIPT ERROR", "Parse Error", "Failed to load", "Cannot open file")


def complaints(said: str) -> list[str]:
    """The engine's own errors and warnings, without the push_error and push_warning calls a suite makes."""
    lines = said.splitlines()
    found = []
    # every line, taking an ERROR: or WARNING: whose "at:" underneath does not name the call a suite would have made
    for number, line in enumerate(lines):
        below = lines[number + 1] if number + 1 < len(lines) else ""
        if line.startswith("ERROR: ") and "at: push_error" not in below:
            found.append(line)
        if line.startswith("WARNING: ") and "at: push_warning" not in below:
            found.append(line)
    return found


def main() -> int:
    root, engine = Path(sys.argv[1]), Path(sys.argv[2])
    tests = sorted((root / "tests").glob("test_*.gd"))

    print(f"{len(tests)} test(s) found")
    if not tests:
        print("no tests found, so nothing was proved", file=sys.stderr)
        return 1

    failed: list[str] = []
    # one process each, so a test cannot be affected by what another declared
    for test in tests:
        run = subprocess.run(
            [str(engine), "--headless", "--path", str(root), "--script", str(test.resolve())],
            capture_output=True,
            text=True,
            # no console window for the engine: run from a scheduler, it would open one per test
            creationflags=NO_WINDOW,
        )
        said = run.stdout + run.stderr
        complained = complaints(said)
        errored = any(mark in said for mark in FAILURE_MARKS) or complained
        passed = run.returncode == 0 and f"PASSED {test.stem}" in said and not errored

        print(f"{'PASS' if passed else 'FAIL'}  {test.stem}")
        if not passed:
            failed.append(test.stem)
            # every engine complaint, named first, since it is the easiest one to miss in the noise
            for line in complained:
                print(f"  the engine complained: {line}", file=sys.stderr)
            print(said.strip(), file=sys.stderr)

    print(f"{len(tests) - len(failed)} of {len(tests)} passed", file=sys.stderr)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
