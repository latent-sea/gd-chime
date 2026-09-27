"""The vocabulary page, written from the addon's own files: docs/vocabulary.md.

gd-chime. MIT licensed; see the LICENCE file at the root of this folder.

Three lists, each read off the file that is the truth of it, so the page cannot
drift from the code: the KINDS a description may be, from the builder's table
(floor_kinds.gd), grouped as that table groups them; the RECIPES, from the
facade's lazy list (gd_chime_recipes.gd), grouped by the family of the look
each dresses under - the theme_*.gd it preloads first, or none; and the
MODELS and the rest of the floor, from the facade's two other files, grouped
by their section comments. Every name carries the first paragraph of its own
script's header, which is what that script says it is.

Run with the folder alone it writes the page; with --check it writes nothing
and fails if the page on disk is not what it would write, naming the page:
a page that has fallen behind the code is written again, never patched.

Deliberately absent: anything about a name's functions or arguments. The
page is the index by name; a name's own file is where the reader goes next,
and a page that copied signatures would be a second place they live.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ADDON = "addons/gd_chime"
PAGE = "docs/vocabulary.md"
KINDS = "components/primitives/floor_kinds.gd"
RECIPES = "gd_chime_recipes.gd"
# the eager facade and the lazy floor list, whose section comments group the floor
FLOOR_LISTS = ("gd_chime.gd", "gd_chime_floor.gd")
# &"text": preload("text.gd"), - one kind and its script
KIND = re.compile(r'^\t&"(\w+)": preload\("([^"]+)"\)')
# a bare comment line in the kinds table, which heads the kinds under it
KIND_GROUP = re.compile(r"^\t# (.+)$")
# static var Card: GDScript: / get: return _at("...") - a lazy name and its script
LAZY = re.compile(r'^static var (\w+): GDScript:\n\tget: return _at\("([^"]+)"\)', re.M)
# const Card := preload("...") - an eager name and its script
EAGER = re.compile(r'^const (\w+) := preload\("([^"]+)"\)', re.M)
# ## --- a section --- in a facade file
SECTION = re.compile(r"^## --- (.+?) ---$", re.M)
# const Fields := preload("../../theme_fields.gd") - the family a recipe dresses under
FAMILY = re.compile(r'preload\("(?:\.\./)*theme_(\w+)\.gd"\)')


def header(script: Path) -> str:
    """The first paragraph of a script's ## header, as one line."""
    lines: list[str] = []
    # every line of the file, for the first run of ## lines up to a bare ## or a blank
    for line in script.read_text(encoding="utf-8").splitlines():
        if line.startswith("## "):
            lines.append(line[3:].strip())
        elif lines:
            break
    return " ".join(lines)


def kinds(addon: Path) -> list[tuple[str, list[tuple[str, str]]]]:
    """The kinds by group, each with what its script says."""
    groups: list[tuple[str, list[tuple[str, str]]]] = [("the kinds", [])]
    # every line of the builder's table: a comment heads a group, a kind joins the current one
    for line in (addon / KINDS).read_text(encoding="utf-8").splitlines():
        heading = KIND_GROUP.match(line)
        if heading:
            groups.append((heading.group(1), []))
        kind = KIND.match(line)
        if kind:
            groups[-1][1].append((kind.group(1), header(addon / "components/primitives" / kind.group(2))))
    return [group for group in groups if group[1]]


def recipes(addon: Path) -> dict[str, list[tuple[str, str]]]:
    """The recipes by the family of the look each dresses under."""
    by_family: dict[str, list[tuple[str, str]]] = {}
    # every lazy name in the recipes list, its script read for the first theme family it preloads
    for name, path in LAZY.findall((addon / RECIPES).read_text(encoding="utf-8")):
        script = addon / path
        family = FAMILY.search(script.read_text(encoding="utf-8"))
        by_family.setdefault(family.group(1) if family else "the look's own types", []).append((name, header(script)))
    return dict(sorted(by_family.items()))


def floor(addon: Path) -> list[tuple[str, list[tuple[str, str]]]]:
    """The eager names and the lazy floor names, by the section each is written under."""
    sections: list[tuple[str, list[tuple[str, str]]]] = []
    # both facade files, each cut at its section comments, every name under one read with its script's header
    for listing in FLOOR_LISTS:
        text = (addon / listing).read_text(encoding="utf-8")
        starts = list(SECTION.finditer(text))
        for at, section in enumerate(starts):
            body = text[section.end():starts[at + 1].start() if at + 1 < len(starts) else len(text)]
            named = [(name, header(addon / path)) for name, path in EAGER.findall(body) + LAZY.findall(body) if not name.startswith("_")]
            if named:
                sections.append((section.group(1), named))
    return sections


def written(root: Path) -> str:
    """The whole page."""
    addon = root / ADDON
    lines = [
        "# The vocabulary",
        "",
        "Every name an application may use, by family, each with what its own file says it is.",
        "Written from the code by `checks/vocabulary_page.py`, never by hand; `GdChime.<Name>` is how an application reads one.",
        "",
        "## The kinds a description may be",
        "",
        "What `ui.<kind>(...)` describes and the builder turns into a node (`floor_kinds.gd`).",
        "",
    ]
    for group, named in kinds(addon):
        lines += [f"### {group}", ""] + [f"- `{name}` - {said}" for name, said in named] + [""]
    lines += ["## The recipes, by the family of the look they dress under", ""]
    for family, named in recipes(addon).items():
        lines += [f"### {family}", ""] + [f"- `{name}` - {said}" for name, said in named] + [""]
    lines += ["## The floor and the models", ""]
    for section, named in floor(addon):
        lines += [f"### {section}", ""] + [f"- `{name}` - {said}" for name, said in named] + [""]
    return "\n".join(lines)


def main() -> int:
    root = Path(sys.argv[1])
    page = root / PAGE
    fresh = written(root)
    if "--check" in sys.argv[2:]:
        held = page.read_text(encoding="utf-8") if page.is_file() else ""
        if held != fresh:
            print(f"{PAGE} is not what the code says; write it again: python checks/vocabulary_page.py <this folder>", file=sys.stderr)
            return 1
        print(f"{PAGE} says what the code says ({fresh.count(chr(10))} lines)", file=sys.stderr)
        return 0
    page.parent.mkdir(parents=True, exist_ok=True)
    page.write_text(fresh, encoding="utf-8", newline="\n")
    print(f"{PAGE}: {fresh.count(chr(10))} lines")
    return 0


if __name__ == "__main__":
    sys.exit(main())
