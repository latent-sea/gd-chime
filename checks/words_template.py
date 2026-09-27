"""Words template - the translators' template of every English phrase, written from the code, and checked.

gd-chime. MIT licensed; see the LICENCE file at the root of this folder.

English is the source and lives in the code: a word's key is its English
(language.gd), so there is no English catalogue. A translator starts from a
TEMPLATE instead - a gettext .pot, every English phrase once, with no
translation - and this writes two from the code: words/gd-chime.pot for the
floor (every script outside demo/, tests/ and checks/) and
demo/words/demo.pot for the demos. Each entry is a msgid, a count's two forms
as msgid and msgid_plural, a way of writing under its msgctxt, and a #:
file:line comment for every place it is said. What a phrase is, and how it is
found, is phrases_in_code.py's.

Run with --check, it writes nothing and fails, naming each, BOTH ways: on
any phrase the code says that its template does not hold - so a phrase added
without writing the template again is caught at the commit - and on any
phrase its template holds that the code no longer says. The second way
costs a translator a word they no longer need, which on its own would not
be worth a failure; it is here because it is the only thing that can see the
scanner going blind. Phrases are found by reading the text, following the
preloads a script names (phrases_in_code.py), so a change in how a script
reaches another - a constant becoming a lazy accessor, a preload becoming a
load - can silently stop a whole subtree of English being seen, and a check
that only failed the first way would report green over it. Either way the
remedy is the same: write the templates again and read what moved.

With --check it fails too, naming each, on any phrase whose English starts
with a lowercase letter and is not said only within another phrase
(Phrase.within, or a constant named _WORDS_WITHIN; phrase.gd): a phrase
shown on its own is in sentence case - "Save", "There is nothing to go
back to" - and the capital is written in the English where it is written,
never added as a text draws. One starting with a number, a mark or a
placeholder - "%d rows", "#%d, %s" - passes as it is.

Deliberately absent: the console and the dev commands whose answers it
prints, whose words are data and never translated, since only a developer
reads them; the names of keys and pad buttons - the engine's, and the pad's
own few in input_map.gd - which a catalogue translates under a context of
their own only where its language writes one otherwise; and the tests,
whose words are their own.

Read-only with --check. Reports how many phrases it found: a run over
nothing proves nothing.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

from phrases_in_code import phrases, unescaped

DATA_ONLY = ("console.gd", "dev_commands.gd")
# where the floor lives in a project, and so where its scripts and its template are
FLOOR = "addons/gd_chime/"
FLOOR_TEMPLATE = FLOOR + "words/gd-chime.pot"
DEMO_TEMPLATE = "demo/words/demo.pot"
DEMOS = "demo/"


def main() -> int:
    root = Path(sys.argv[1])
    checking = "--check" in sys.argv[2:]
    found = 0
    missing = 0
    stale = 0
    lowercase = 0
    # the floor's template, then the demos', each over its own scripts
    for template, scripts in ((FLOOR_TEMPLATE, _floor(root)), (DEMO_TEMPLATE, sorted((root / DEMOS).rglob("*.gd")))):
        entries: dict[tuple[str, str, str], list[str]] = {}
        # every script in a fixed order, so two runs write alike
        for path in scripts:
            # every phrase the script says, with where, and whether it is said only within another
            for key, reference, within in phrases(root, path):
                entries.setdefault(key, []).append(reference)
                # its English and a count's form for many, each for a first letter lowercase and unmarked
                for words in (key[1], key[2]):
                    if checking and words[:1].islower() and not within:
                        print(f"{reference}: \"{words}\" starts lowercase; a phrase shown on its own is in sentence case, and words said only inside another phrase are Phrase.within (phrase.gd)")
                        lowercase += 1
        found += len(entries)
        if not checking:
            (root / template).parent.mkdir(parents=True, exist_ok=True)
            (root / template).write_text(_written(template, entries), encoding="utf-8", newline="\n")
            print(f"{template}: {len(entries)} phrase(s)")
            continue
        held = _held(root / template)
        # every phrase the code says, for one its template lacks
        for key, references in entries.items():
            if key not in held:
                under = f" under \"{key[0]}\"" if key[0] else ""
                print(f"{references[0]}: \"{key[1]}\"{under} is not in {template}; write the templates again: python checks/words_template.py <this folder>")
                missing += 1
        # every phrase the template holds, for one the code no longer says: the scanner has stopped seeing it, or it has gone
        for key in held - set(entries):
            under = f" under \"{key[0]}\"" if key[0] else ""
            print(f"{template}: \"{key[1]}\"{under} is held, but nothing says it any more; if it was not deliberately removed the scanner has stopped seeing it, so find out which before writing the templates again")
            stale += 1
    print(f"{found} phrase(s) found, {missing} missing from their template, {stale} held but unsaid, {lowercase} starting lowercase unmarked", file=sys.stderr)
    return 1 if missing or stale or lowercase or not found else 0


def _floor(root: Path) -> list[Path]:
    """Every floor script: the addon's own, and not the console's."""
    return [path for path in sorted(root.rglob("*.gd")) if path.relative_to(root).as_posix().startswith(FLOOR) and path.name not in DATA_ONLY]


def _po(words: str) -> str:
    """Words as a PO string."""
    return '"' + words.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n").replace("\t", "\\t") + '"'


def _written(template: str, entries: dict[tuple[str, str, str], list[str]]) -> str:
    """A whole template: its header, then every entry under the places it is said."""
    lines = [
        "# gd-chime. MIT licensed; see the LICENCE file at the root of this folder.",
        "#",
        f"# {template}: every English phrase, for a translator to start a catalogue",
        "# from. Written from the code, never by hand: write it again whenever a",
        "# phrase is added - the commit's check says so.",
        "#, fuzzy",
        'msgid ""',
        'msgstr ""',
        '"Project-Id-Version: gd-chime\\n"',
        '"MIME-Version: 1.0\\n"',
        '"Content-Type: text/plain; charset=UTF-8\\n"',
        '"Content-Transfer-Encoding: 8bit\\n"',
        '"Plural-Forms: nplurals=INTEGER; plural=EXPRESSION;\\n"',
    ]
    # every entry, in the order it is first said
    for (context, english, plural), references in entries.items():
        lines.append("")
        lines += [f"#: {reference}" for reference in dict.fromkeys(references)]
        lines += [f"msgctxt {_po(context)}"] if context else []
        lines.append(f"msgid {_po(english)}")
        lines += [f"msgid_plural {_po(plural)}", 'msgstr[0] ""', 'msgstr[1] ""'] if plural else ['msgstr ""']
    return "\n".join(lines) + "\n"


def _held(template: Path) -> set[tuple[str, str, str]]:
    """Every (context, English, plural) a template holds; none, said, where there is no template."""
    if not template.is_file():
        print(f"{template}: no template; write it: python checks/words_template.py <this folder>")
        return set()
    held: set[tuple[str, str, str]] = set()
    fields = {"msgctxt": "", "msgid": "", "msgid_plural": ""}
    # each line: a field of the entry being read, until its first msgstr ends it
    for line in template.read_text(encoding="utf-8").splitlines():
        field = re.match(r'^(msgctxt|msgid_plural|msgid|msgstr(?:\[0\])?)\s+"(.*)"$', line)
        if field is None:
            continue
        if field.group(1) in fields:
            fields[field.group(1)] = unescaped(field.group(2))
            continue
        if fields["msgid"] != "":
            held.add((fields["msgctxt"], fields["msgid"], fields["msgid_plural"]))
        fields = {"msgctxt": "", "msgid": "", "msgid_plural": ""}
    return held


if __name__ == "__main__":
    sys.exit(main())
