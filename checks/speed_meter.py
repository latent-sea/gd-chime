"""Has the cost of a draw, the page-a-frame p50, or start-to-first-frame moved?

gd-chime. MIT licensed; see the LICENCE file at the root of this folder.

Round 2 made the framework right and slow, and nothing in the suite said so:
a draw cost 70% more, launch was 4 s longer on every app, and every check was
green. This is the meter round 3 asked for. Two measuring halves run headless
through the engine given - draw_meter.gd (the pipes, a page a frame: the p50
frame and the cost of one draw) and launch_meter.gd (the workspace, engine
start to its first frame) - and their three numbers are held against
speed_baseline.json beside this file. A number more than 15% SLOWER than its
baseline fails, naming the number, the baseline and the change. A number more
than 15% faster is said too, and passes: a large improvement is worth
re-recording the baseline, never a failure.

NOISE. Headless timings on this machine, which other agents' engines share,
move run to run. Measured 2026-09-20, sequential runs beside another agent's
engine: over eleven runs the draw p50 ranged 54 to 79 ms - 45% end to end -
while the LOWEST of each batch of five ran 54 and 58 (6% apart) and the median
of each 66 and 73 (11% apart); over eleven launches, 3.6 to 4.7 s, the lowest
of a quiet five was 3.64 s and of a five run under another agent's engine
4.08 s (12% apart). Load only ever adds time, so the lowest of N runs is the
one the machine interfered with least, and a change in the CODE moves every
run, the lowest included. So each meter runs RUNS times and its lowest stands
for it, on both sides: the baseline is recorded the same way, by this file
with --record. Seven, because on the draw runs measured the lowest of five
still lands 15% high about one time in twenty, and the lowest of seven about
one in three hundred; a true 15% move is caught either way. The launch is the
thinner margin: a machine loaded for the whole of a run lifts even its lowest
by about 12%, so a launch FAIL of under 20% is read beside the machine's
state before it is believed, and a re-run on a quiet machine settles it.

--record writes the baseline as it stands now, with the commit and the date it
was taken at, and says the numbers. It is the ONLY way the file is written, so
what is in it was made the way it is judged. Update it only in a commit that
says why.

Not in the pre-commit quick checks: it starts the engine fourteen times and
takes about three minutes, against the two seconds the quick checks take on
every commit. It runs with the slow set in verify.py, once a day.

Chosen against: the median, which moved 11% batch to batch against the
lowest's 6%; tuning the 15% to the noise, which the lowest of seven keeps
without; more frames in one run, which does not help when the load is another
process; judging the app's own build alone, which misses the compile round 2
found; a baseline written by hand, whose numbers would not have been made the
way they are judged.
"""

from __future__ import annotations

import datetime
import json
import re
import subprocess
import sys
from pathlib import Path

NO_WINDOW = getattr(subprocess, "CREATE_NO_WINDOW", 0)
RUNS = 7
ALLOWED = 0.15
# how long one run may take, in seconds - generous, since an engine given as a queue (a wrapper that waits its turn) counts its wait too
RUN_AT_MOST = 1800
BASELINE = "speed_baseline.json"
# each measuring half, and the numbers on its METER line that are judged, each with its words
METERS = {
    "draw_meter.gd": {"draw_us": "the cost of a draw, us", "page_ms_p50": "a page a frame, the p50 frame, ms", "idle_ms_p50": "the app standing idle on its easel, the p50 frame, ms"},
    "launch_meter.gd": {"launch_ms": "engine start to the workspace's first frame, ms"},
}
# one number on a METER line: draw_us=70.7
SAID = re.compile(r"(\w+)=([\d.]+)")


def measure(root: Path, engine: Path, meter: Path) -> dict[str, float]:
    """The lowest of RUNS runs of one meter, number by number."""
    runs: list[dict[str, float]] = []
    # the meter run RUNS times, each its own engine, for the numbers on each run's METER line
    for run in range(RUNS):
        ran = subprocess.run(
            [str(engine), "--headless", "--path", str(root), "--script", str(meter.resolve())],
            capture_output=True, text=True, timeout=RUN_AT_MOST, creationflags=NO_WINDOW,
        )
        said = ran.stdout + ran.stderr
        lines = said.splitlines()
        # a script error is a fault in the code however the run ends, and a run with no METER line measured nothing
        broken = [line for line in lines if line.startswith("SCRIPT ERROR")]
        metered = [line for line in lines if line.startswith("METER ")]
        if ran.returncode != 0 or broken or not metered:
            raise SystemExit(f"{meter.name} run {run + 1} of {RUNS} measured nothing (exit {ran.returncode}):\n" + "\n".join(broken or lines[-20:]))
        runs.append({name: float(value) for name, value in SAID.findall(metered[0])})
    return {name: min(run[name] for run in runs) for name in runs[0]}


def main() -> int:
    root, engine = Path(sys.argv[1]), Path(sys.argv[2])
    record = "--record" in sys.argv[3:]
    here = Path(__file__).parent
    kept = here / BASELINE
    if not record and not kept.is_file():
        print(f"no baseline at {kept}: record one with --record, in a commit that says why", file=sys.stderr)
        return 1

    measured: dict[str, float] = {}
    # each meter measured, keeping only the numbers judged
    for meter, numbers in METERS.items():
        found = measure(root, engine, here / meter)
        measured.update({name: found[name] for name in numbers})

    if record:
        commit = subprocess.run(["git", "-C", str(root), "rev-parse", "--short", "HEAD"], capture_output=True, text=True, check=True).stdout.strip()
        taken = {"commit": commit, "date": f"{datetime.date.today():%Y-%m-%d}", "runs": RUNS, "of": "the lowest of the runs"}
        kept.write_text(json.dumps({"taken": taken, "numbers": measured}, indent=2) + "\n", encoding="utf-8")
        print(f"baseline recorded at {kept}, taken at {commit} on {taken['date']}, the lowest of {RUNS} runs: {measured}")
        return 0

    baseline = json.loads(kept.read_text(encoding="utf-8"))
    failed: list[str] = []
    # every judged number against its baseline, in the meters' order
    for numbers in METERS.values():
        for name, words in numbers.items():
            was, now = baseline["numbers"][name], measured[name]
            change = (now - was) / was
            slower = change > ALLOWED
            print(f"{'FAIL' if slower else 'PASS'}  {words}: {now:g} against a baseline of {was:g} ({change:+.0%})")
            if slower:
                failed.append(name)
            elif change < -ALLOWED:
                print(f"      a large improvement: worth re-recording the baseline, in a commit that says why")
    print(f"{len(measured) - len(failed)} of {len(measured)} numbers within {ALLOWED:.0%} of the baseline taken at {baseline['taken']['commit']} on {baseline['taken']['date']}", file=sys.stderr)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
