"""Run every check, and say which ones ran.

gd-chime. MIT licensed; see the LICENCE file at the root of this folder.

Ten checks, each answering a different claim this folder makes: it says no
word from the world above it, nothing in it wires itself up by hand, every
English phrase it says is in a translators' template and in sentence case,
the vocabulary page says what the code says, its tests actually run, its
demos still compile, every stall demo does everything, the gallery does
everything in every look, the addon installs alone into another project, and
it is no slower than the baseline it recorded. This runs all ten and fails if
any of them fails.

A missing check is a FAILURE, not a skip. A check that has been renamed,
deleted or moved is the state this whole file exists to notice - a run that
quietly does two of three and reports green is worse than no run at all, and it
is what silently happens to a chain of commands in a script.

Every check that ran is named in the report. Green here means ten specific
things passed, not that nothing complained.

Deliberately absent: no way to run a subset, and no continue-on-failure.
Choosing which to skip is how one stops being run, so a quicker run calls the
checks it wants itself, and this one always answers for all ten.
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

EXIT_CLEAN = 0
EXIT_FAILED = 1
EXIT_MISSING = 2


def main() -> int:
    root, terms, engine = Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3])
    here = Path(__file__).parent

    checks = [
        ("no word from above", [here / "boundary_lint.py", root, terms]),
        ("nothing wires itself up", [here / "convention_lint.py", root]),
        ("every phrase is in its template, in sentence case", [here / "words_template.py", root, "--check"]),
        ("the vocabulary page says what the code says", [here / "vocabulary_page.py", root, "--check"]),
        ("its tests run", [here / "run_tests.py", root, engine]),
        ("its demos still compile", [here / "demos_compile.py", root, engine]),
        ("every stall demo does everything", [here / "stalls_probe.py", root, engine]),
        ("the gallery does everything in every look", [here / "looks_probe.py", root, engine]),
        ("the addon installs alone", [here / "installation_test.py", root, engine]),
        ("it is no slower than its baseline", [here / "speed_meter.py", root, engine]),
    ]

    # a check that is not on disk is the thing this file exists to notice, so it is fatal before anything runs
    missing = [str(step[1][0]) for step in checks if not step[1][0].is_file()]
    if missing:
        print("check missing: " + ", ".join(missing), file=sys.stderr)
        return EXIT_MISSING

    failed: list[str] = []
    # every check in turn, each in its own process, for the ones that failed
    for claim, command in checks:
        run = subprocess.run([sys.executable, *[str(part) for part in command]], capture_output=True, text=True)
        print(f"{'PASS' if run.returncode == 0 else 'FAIL'}  {claim}")
        if run.returncode != 0:
            failed.append(claim)
            print((run.stdout + run.stderr).strip(), file=sys.stderr)

    print(f"{len(checks) - len(failed)} of {len(checks)} checks passed", file=sys.stderr)
    return EXIT_FAILED if failed else EXIT_CLEAN


if __name__ == "__main__":
    sys.exit(main())
