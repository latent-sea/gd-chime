"""Does the gallery still do everything, and cut and cover nothing, in every look?

gd-chime. MIT licensed; see the LICENCE file at the root of this folder.

The gallery (demo/gallery/gallery.gd) is walked with --probe in its own
placeholder look by stalls_probe.py. A look changes every size on the
screen - its gaps, its padding, its type, its shadows - and how long every
move lasts, so a claim that holds in one look can fail in another: words
pushed off a window on its end by a roomier look, a value eased quicker
than the probe steps. So the gallery is walked here once in each of its
other looks, forced on with --look=<name>, and every PROBE line of a look
that fails is printed.

The looks are read from looks.gd's NAMES, the list the gallery's own
buttons are made from, so a look added there is walked here with no change.
They run a few at a time, each its own engine, since each takes half a
minute and none shares anything with another.
"""

from __future__ import annotations

import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

NO_WINDOW = getattr(subprocess, "CREATE_NO_WINDOW", 0)
GALLERY = "res:" + "//demo/gallery/gallery.gd"
LOOKS = "demo/gallery/looks/looks.gd"
# the one walked by stalls_probe.py already
WORN = "placeholder"
AT_ONCE = 4
# how long one walk may take, in seconds - generous, since an engine given as a queue (a wrapper that waits its turn) counts its wait too
WALK_AT_MOST = 1800


def names(root: Path) -> list[str]:
    """Every look's name, as looks.gd's NAMES lists them."""
    listed = re.search(r"const NAMES: Array\[StringName\] = \[(.*?)\]", (root / LOOKS).read_text(encoding="utf-8"))
    if listed is None:
        raise SystemExit(f"no NAMES list in {LOOKS}")
    return [name for name in re.findall(r'&"(\w+)"', listed.group(1)) if name != WORN]


def walk(root: Path, engine: Path, look: str) -> tuple[str, bool, list[str], str]:
    """The gallery walked in one look: whether it said PROBE OK, its PROBE lines, and its tail if it said none."""
    run = subprocess.run(
        [str(engine), "--headless", "--path", str(root), "--script", GALLERY, "--", "--probe", "--look=" + look],
        capture_output=True, text=True, timeout=WALK_AT_MOST, creationflags=NO_WINDOW,
    )
    lines = [line for line in run.stdout.splitlines() if line.startswith("PROBE")]
    return look, run.returncode == 0 and "PROBE OK" in lines, lines, (run.stdout + run.stderr)[-2000:]


def main() -> int:
    root, engine = Path(sys.argv[1]), Path(sys.argv[2])
    looks = names(root)
    with ThreadPoolExecutor(max_workers=AT_ONCE) as pool:
        walked = list(pool.map(lambda look: walk(root, engine, look), looks))
    failed = [look for look, ok, _, _ in walked if not ok]
    # every look in turn, with what a failing one said
    for look, ok, lines, tail in walked:
        print(f"{'PASS' if ok else 'FAIL'}  gallery in {look}")
        if not ok:
            print("\n".join(lines) or tail, file=sys.stderr)
    print(f"{len(looks) - len(failed)} of {len(looks)} looks walk the gallery whole")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
