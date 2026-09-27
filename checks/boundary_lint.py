"""Boundary lint - does anything in this folder mention the world outside it?

gd-chime. MIT licensed; see the LICENCE file at the root of this folder.

Scans every file under a root for a term from a supplied list - in the content
or in the path - and for a res:// reference to something not in the root.
Read-only. Reports how many files it looked at: a run over nothing proves
nothing.

It also reports a res:// path ANYWHERE inside the addon. A res:// path is
measured from the project root, so a file saying one has decided where the
addon was installed; a project that puts it somewhere else, or a game that
vendors it under a folder of its own, would find nothing there. Inside the
addon every path is relative to the file saying it, and every path built from
a string is resolved from the script's own resource_path. The rule is written
against the addon's folder rather than the root it is pointed at, so it holds
just as well run over a project that installed gd-chime.

And it reports the addon's LICENCE differing by a byte from the LICENCE at the
root of the folder this file is in. There are two because only the addon
ships: every header in it says "see the LICENCE file at the root of this
folder", and installed, the addon's folder is the only root it has. Two copies
drift unless something holds them together, and this is what does. The root's
is found from this file rather than from the root given, so pointed at a
project that installed gd-chime it says whether the licence there is still ours.

It ships NO terms. A file in here listing the consumer's vocabulary is the
thing this exists to catch, and would match itself on every run.

One structural exclusion: this file, which holds the words it searches for.
Resolved rather than spelled, so it is one path wide and cannot drift.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

RESOURCE_REF = re.compile(r"res://([^\"'\s)\]]*)")
# the addon: what ships, and so what may not say where it was installed
ADDON = "addons/gd_chime/"
# the licence's file name, at the root of this folder and again at the addon's
LICENCE = "LICENCE"
# split at a lowercase/digit-to-uppercase seam, so getLizardRow reads as three words
CAMEL_SEAM = re.compile(r"(?<=[a-z0-9])(?=[A-Z])")


def compile_terms(path: Path) -> list[tuple[str, re.Pattern[str]]]:
    """Turn the supplied word list into (term, regex) pairs."""
    raw = json.loads(path.read_text(encoding="utf-8"))

    # stem: 'breed' also finds breeding; boundary is [A-Za-z0-9] so count_lizard hits
    stems = [(t, rf"(?<![A-Za-z0-9]){re.escape(t)}[A-Za-z0-9]*") for t in raw["stem_terms"]]
    # exact: 'sim' finds sim but not simple, for terms that are also English.
    exact = [(t, rf"(?<![A-Za-z0-9]){re.escape(t)}(?![A-Za-z0-9])") for t in raw["exact_terms"]]

    return [(term, re.compile(pattern, re.I)) for term, pattern in stems + exact]


def compile_allowed(path: Path) -> list[str]:
    """The engine's own names that contain a term, taken out of a line before matching."""
    return list(json.loads(path.read_text(encoding="utf-8")).get("allowed", []))


def main() -> int:
    root, term_file = Path(sys.argv[1]), Path(sys.argv[2])
    terms = compile_terms(term_file)
    allowed = compile_allowed(term_file)
    myself = Path(__file__).resolve()

    hits = 0
    scanned = 0
    ours, shipped = myself.parent.parent / LICENCE, root / ADDON / LICENCE
    # bytes, not text: a line ending changed is a licence changed, to whoever compares them
    if not shipped.is_file() or ours.read_bytes() != shipped.read_bytes():
        print(f"{ADDON}{LICENCE} is not byte for byte {ours.as_posix()}: the two licence files must stay identical, so change both or neither")
        hits += 1
    # every file under the root, in a stable order so two runs report alike
    for path in sorted(root.rglob("*")):
        if not path.is_file():
            continue
        scanned += 1
        rel = path.relative_to(root).as_posix()

        # the name itself: a file called after the consumer leaks it whatever is inside
        split_path = CAMEL_SEAM.sub(" ", rel)
        # every banned word, against the path read as words
        for term, pattern in terms:
            if pattern.search(split_path):
                print(f"{rel}: {term!r} in the path")
                hits += 1

        if path.resolve() == myself:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue  # a binary: its path was scanned, its bytes are not text

        # the content, line by line, so a hit can be pointed at
        for number, line in enumerate(text.splitlines(), start=1):
            # a banned word anywhere in the line, comments and strings included
            split_line = CAMEL_SEAM.sub(" ", line)
            # the engine's own names taken out, so its word is not counted as ours
            for name in allowed:
                split_line = split_line.replace(name, "")
            # every banned word, against the line read as words
            for term, pattern in terms:
                if pattern.search(split_line):
                    print(f"{rel}:{number}: {term!r}")
                    hits += 1
            # a res:// path that does not land on anything inside this folder, and any at all inside the addon
            for ref in RESOURCE_REF.finditer(line):
                if rel.startswith(ADDON):
                    print(f"{rel}:{number}: {ref.group(0)} says where the addon was installed; name it relative to this file")
                    hits += 1
                elif not (root / ref.group(1)).exists():
                    print(f"{rel}:{number}: {ref.group(0)} is outside this folder")
                    hits += 1

    print(f"{scanned} file(s) scanned, {hits} hit(s)", file=sys.stderr)
    return 1 if hits or not scanned else 0


if __name__ == "__main__":
    sys.exit(main())
