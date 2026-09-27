"""Does every stall demo still do everything the stall does?

gd-chime. MIT licensed; see the LICENCE file at the root of this folder.

Ten demos arrange the same functionality in ten design languages. Each is
run headless with --probe, which walks that functionality (stall.gd) and
prints PROBE OK or PROBE FAILED: every place stands, a note survives a
detour and Back, another crate starts fresh, the act runs to its moment
with the glow walking. A demo that arranged something away fails here.

So does one that cuts its words off: every place, every pop-up and the
moment are looked at in a 1920x1080, a 1280x800 and a 720x1280 window - a
window on its end judged like the other two - for words drawn past the
window or past a parent that clips them (clipped_text.gd), each such set of
words printed as a PROBE CLIPPED line naming them.

Every application under demo/apps is probed the same way: the script named
for its folder - demo/apps/workspace/workspace.gd - run with --probe.

A walk that prints a SCRIPT ERROR fails too, whatever it says at the end:
the engine's complaint about our code is never something a probe provokes
on purpose, and a PROBE OK over a thousand of them is the fault this is
here to catch.
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

NO_WINDOW = getattr(subprocess, "CREATE_NO_WINDOW", 0)
# how long one walk may take, in seconds - generous, since an engine given as a queue (a wrapper that waits its turn) counts its wait too
WALK_AT_MOST = 1800
GALLERY = "demo/gallery/gallery.gd"
STALLS = "demo/stalls"
APPS = "demo/apps"


def main() -> int:
    root, engine = Path(sys.argv[1]), Path(sys.argv[2])
    demos = [GALLERY] + sorted(f"{STALLS}/{path.name}" for path in (root / STALLS).glob("*.gd"))
    # every application under demo/apps, by the script named for its folder; a folder without one yet is not a demo
    demos += sorted(f"{APPS}/{folder.name}/{folder.name}.gd" for folder in (root / APPS).glob("*") if (folder / f"{folder.name}.gd").is_file())
    failed: list[str] = []
    for demo in demos:
        run = subprocess.run(
            [str(engine), "--headless", "--path", str(root), "--script", "res:" + "//" + demo, "--", "--probe"],
            capture_output=True, text=True, timeout=WALK_AT_MOST, creationflags=NO_WINDOW,
        )
        lines = [line for line in run.stdout.splitlines() if line.startswith("PROBE")]
        # a script error is a fault in the code however the walk ends, never a refusal a probe provokes
        broken = [line for line in (run.stdout + run.stderr).splitlines() if line.startswith("SCRIPT ERROR")]
        lines += broken[:5]
        ok = run.returncode == 0 and "PROBE OK" in lines and not broken
        print(f"{'PASS' if ok else 'FAIL'}  {demo}")
        if not ok:
            failed.append(demo)
            print("\n".join(lines) or (run.stdout + run.stderr)[-2000:], file=sys.stderr)
    print(f"{len(demos) - len(failed)} of {len(demos)} stall demos do everything")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
