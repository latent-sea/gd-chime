"""Phrases in code - every English phrase a GDScript script says, found by reading its text.

gd-chime. MIT licensed; see the LICENCE file at the root of this folder.

The reading half of the translators' template (words_template.py, which
writes and checks the templates from what this finds). It never runs a
script: a phrase is what a scanner can see as English in the text -
- the English in a call of Phrase.of, Phrase.within, Phrase.with (its
  pattern, never its data) and Phrase.counted (one, many, and the words for
  none);
- the register's words, in the one table an action is declared in,
  declare_all({ACTION: ["Words", keys(KEY_L)]}) - written there, held by a
  constant the call names, or returned by a function of the same script the
  call names, which is where a table with inputs in it has to live, since a
  constant may not call keys();
- a way of writing - Language.word or Language.written with a context - its
  English under the context it is kept under;
- every string in a constant whose name ends in _WORDS - MARKER_WORDS,
  STATUS_WORDS: English kept as data until a text says it - or in
  _WORDS_WITHIN - COMPARISON_WORDS_WITHIN: the same, said only inside
  another phrase. A name is the marking because a constant may not call a
  function, so no marker call can stand inside one; and so a constant that
  holds anything else is never named so.
Each phrase is found with whether it is said only WITHIN another phrase -
Phrase.within, or a constant named _WORDS_WITHIN - the one kind whose
English may start lowercase (phrase.gd).
In each, a string is written in place or is a constant the call names, in
its own file or through a preload. A comment is never read: a phrase in one
is an example. A string that is a key - a dictionary's, {"words": ...}, or a
subscript's, facts["count"] - is no phrase.

What reaches a text any other way - a string handed through a variable from
a constant not named so - is not seen, and is the one way a phrase escapes
the template: such a constant is named for its words instead.
"""

from __future__ import annotations

import re
from pathlib import Path

# the end of a constant's name that says its values are English phrases, and the end that says they are said only within another
PHRASES_SUFFIX = "_WORDS"
WITHIN_SUFFIX = "_WORDS_WITHIN"
# Phrase.of( Phrase.within( Phrase.with( Phrase.counted( - and which of their arguments are English
PHRASE_CALL = re.compile(r"\bPhrase\.(of|within|with|counted)\(")
ENGLISH_ARGUMENTS = {"of": (0,), "within": (0,), "with": (0,), "counted": (0, 1, 3)}
# actions.declare_all(table) - the register's words, the first of each entry of its one argument
DECLARE_CALL = re.compile(r"\.declare_all\(")
# a function this script defines, and where the next one begins - for a table a call names rather than writes
DEFINES = "^(?:static )?func {}\\("
NEXT_DEFINITION = re.compile(r"^(?:static )?func |^class ", re.M)
# where a table entry's list opens: written in the table, ACTION: [...], or put in one, table[action] = [...]
ENTRY = re.compile(r"(?::|\]\s*=)\s*\[")
# Language.word( or Language.written(, or written( inside language.gd itself - never Phrase.written(
WRITING_CALL = re.compile(r"(?:\bLanguage\.|(?<![\w.]))(word|written)\(")
# "..." but not &"..." or ^"...", which are names and paths
STRING = re.compile(r'(?<![&^\w])"((?:[^"\\\n]|\\.)*)"')
# "...", wherever it stands - to step over a string whole
QUOTED = re.compile(r'"(?:[^"\\\n]|\\.)*"')
# &"...", a StringName: read only inside a constant
NAME_STRING = re.compile(r'&"((?:[^"\\\n]|\\.)*)"')
# SCREAMING or Alias.SCREAMING - a constant an argument names
CONSTANT = re.compile(r"\b(?:([A-Z]\w*)\.)?([A-Z][A-Z0-9_]+)\b")
# const NAME := or const NAME: Type = - where a constant's value starts, an inner class's too
DECLARES_CONSTANT = re.compile(r"^[ \t]*const\s+([A-Z][A-Z0-9_]*)\b[^=\n]*?:?=\s*", re.M)
# const Alias := preload(a script's path) - a script whose constants are read through its alias
PRELOADS = re.compile(r'^const\s+(\w+)\s*:?=\s*preload\("([^"]+)"\)', re.M)
# what a path from the project root begins with; anything else is relative to the script saying it
FROM_ROOT = "res:" + "//"
OPENS = "([{"
CLOSES = ")]}"


def phrases(root: Path, path: Path) -> list[tuple[tuple[str, str, str], str, bool]]:
    """Every phrase a script says, as ((context, English, plural), file:line, whether it is said only within another phrase)."""
    text = _uncommented(path.read_text(encoding="utf-8"))
    rel = path.relative_to(root).as_posix()
    beside = path.parent  # where a preload of this script's is measured from, the addon's being relative
    said: list[tuple[tuple[str, str, str], str, bool]] = []
    # every call of Phrase, its English written in the call or named by it
    for call in PHRASE_CALL.finditer(text):
        at = f"{rel}:{text.count(chr(10), 0, call.start()) + 1}"
        arguments = _arguments(text, call.end())
        english = [_strings(root, beside, text, arguments[index]) if index < len(arguments) else [] for index in ENGLISH_ARGUMENTS[call.group(1)]]
        if call.group(1) == "counted":
            # one and many together; the words for none a key of their own
            said += [(("", one, many), at, within) for (one, within), (many, _) in zip(english[0], english[1])]
            said += [(("", none, ""), at, within) for none, within in english[2]]
        else:
            said += [(("", words, ""), at, within or call.group(1) == "within") for words, within in english[0]]
    # every table of actions declared, its words written in it, in a constant it names or in a function of this script it names
    for call in DECLARE_CALL.finditer(text):
        at = f"{rel}:{text.count(chr(10), 0, call.start()) + 1}"
        table = _arguments(text, call.end())[0]
        whole = "\n".join([table, _constants(root, beside, text, table), _bodies(text, table)])
        said += [(("", words, ""), at, within) for words, within in _strings(root, beside, text, _table_words(whole))]
    # every way of writing looked up under a context - never the line that defines the lookup
    for call in WRITING_CALL.finditer(text):
        if "func " in text[text.rfind("\n", 0, call.start()) + 1:call.start()]:
            continue
        at = f"{rel}:{text.count(chr(10), 0, call.start()) + 1}"
        arguments = _arguments(text, call.end())
        contexts = _strings(root, beside, text, arguments[1]) if len(arguments) > 1 else [("", False)]
        if len(contexts) == 1:
            said += [((contexts[0][0], words, ""), at, within) for words, within in _strings(root, beside, text, arguments[0])]
    # every constant named for the English it holds as data
    for constant in DECLARES_CONSTANT.finditer(text):
        if constant.group(1).endswith((PHRASES_SUFFIX, WITHIN_SUFFIX)):
            at = f"{rel}:{text.count(chr(10), 0, constant.start()) + 1}"
            said += [(("", words, ""), at, constant.group(1).endswith(WITHIN_SUFFIX)) for words in _literals(_value(text, constant.end()))]
    return said


def unescaped(written: str) -> str:
    """A string's text as GDScript and a PO file both write it, its escapes read."""
    # \n, \t, \", \\ and \uXXXX, each the character it stands for
    return re.sub(r"\\(u[0-9a-fA-F]{4}|.)", lambda match: chr(int(match.group(1)[1:], 16)) if match.group(1).startswith("u") else {"n": "\n", "t": "\t"}.get(match.group(1), match.group(1)), written)


def _skip_string(text: str, at: int) -> int:
    """Where the string opening at this quote ends."""
    string = QUOTED.match(text, at)
    return string.end() if string else at + 1


def _uncommented(text: str) -> str:
    """A script with every comment blanked out, its lines where they were: a phrase in a comment is an example, never said."""
    kept = list(text)
    at = 0
    # each character, strings skipped whole, a # outside one blanking to its line's end
    while at < len(text):
        if text[at] == '"':
            at = _skip_string(text, at)
            continue
        if text[at] == "#":
            end = text.find("\n", at)
            end = len(text) if end == -1 else end
            kept[at:end] = " " * (end - at)
            at = end
        at += 1
    return "".join(kept)


def _arguments(text: str, start: int) -> list[str]:
    """A call's arguments as written, from just inside its open bracket to its close."""
    arguments: list[str] = []
    depth = 0
    at = start
    begun = start
    # each character to the call's close, strings skipped whole, split at the call's own commas
    while at < len(text):
        character = text[at]
        if character == '"':
            at = _skip_string(text, at)
            continue
        if character in CLOSES and depth == 0:
            arguments.append(text[begun:at])
            return arguments
        if character == "," and depth == 0:
            arguments.append(text[begun:at])
            begun = at + 1
        depth += 1 if character in OPENS else -1 if character in CLOSES else 0
        at += 1
    return arguments


def _value(text: str, start: int) -> str:
    """A constant's value: from after its = to the end of its line, brackets spanning lines taken whole."""
    depth = 0
    at = start
    # each character to the first line end outside every bracket, strings skipped whole
    while at < len(text) and not (text[at] == "\n" and depth == 0):
        if text[at] == '"':
            at = _skip_string(text, at)
            continue
        depth += 1 if text[at] in OPENS else -1 if text[at] in CLOSES else 0
        at += 1
    return text[start:at]


def _keyed(written: str, match: re.Match[str]) -> bool:
    """Whether a string is a key rather than words: a dictionary's, "is over": ..., or a subscript's, facts["count"]."""
    # a colon after it, not :=
    if re.match(r"\s*:(?!=)", written[match.end():]):
        return True
    # a bracket after a name, a call or another subscript before it, and its close after it
    return re.search(r"[\w\])]\[\s*&?$", written[:match.start()]) is not None and re.match(r"\s*\]", written[match.end():]) is not None


def _literals(written: str) -> list[str]:
    """The strings and StringNames written in an expression, in order, never a key."""
    found = [(match.start(), match.group(1)) for pattern in (STRING, NAME_STRING) for match in pattern.finditer(written) if not _keyed(written, match)]
    return [unescaped(words) for _, words in sorted(found)]


def _table_words(written: str) -> str:
    """The words of every entry of an action table: what stands first inside its brackets, never the action or the inputs after it."""
    found: list[str] = []
    # every entry's list, for the words it opens with
    for entry in ENTRY.finditer(written):
        arguments = _arguments(written, entry.end())
        if arguments:
            found.append(arguments[0])
    return "\n".join(found)


def _constants(root: Path, beside: Path, text: str, written: str) -> str:
    """The values of the constants an expression names, as written, in this script or one it preloads."""
    found: list[str] = []
    # every constant named in the expression, for the value it holds
    for named in CONSTANT.finditer(written):
        source = text if named.group(1) is None else _preloaded(root, beside, text, named.group(1))
        declared = None if source is None else re.search(rf"^[ \t]*const\s+{named.group(2)}\b[^=\n]*?:?=\s*", source, re.M)
        if declared is not None:
            found.append(_value(source, declared.end()))
    return "\n".join(found)


def _bodies(text: str, written: str) -> str:
    """The bodies of this script's functions an expression calls, run together."""
    found: list[str] = []
    # every name called in the expression, for the ones this script defines
    for called in re.finditer(r"\b([a-z_]\w*)\(", written):
        defined = re.search(DEFINES.format(re.escape(called.group(1))), text, re.M)
        if defined is None:
            continue
        ends = NEXT_DEFINITION.search(text, defined.end())
        found.append(text[defined.end():ends.start() if ends else len(text)])
    return "\n".join(found)


def _strings(root: Path, beside: Path, text: str, written: str) -> list[tuple[str, bool]]:
    """The English an argument holds, each with whether a constant named _WORDS_WITHIN holds it: the strings written in it, then those of each constant it names."""
    strings = [(unescaped(match.group(1)), False) for match in STRING.finditer(written) if not _keyed(written, match)]
    # every constant named in it, in this script or one it preloads
    for named in CONSTANT.finditer(written):
        source = text if named.group(1) is None else _preloaded(root, beside, text, named.group(1))
        declared = None if source is None else re.search(rf"^[ \t]*const\s+{named.group(2)}\b[^=\n]*?:?=\s*", source, re.M)
        if declared is not None:
            strings += [(words, named.group(2).endswith(WITHIN_SUFFIX)) for words in _literals(_value(source, declared.end()))]
    return strings


def _preloaded(root: Path, beside: Path, text: str, alias: str) -> str | None:
    """The text of the script preloaded under this alias; nothing where the alias names no preload."""
    # every preload in the script, for the one under this alias
    for preload in PRELOADS.finditer(text):
        if preload.group(1) == alias:
            named = preload.group(2)
            # a path from the project root, or - inside the addon, which never says where it sits - one relative to the script saying it
            return _uncommented((root / named[len(FROM_ROOT):] if named.startswith(FROM_ROOT) else beside / named).read_text(encoding="utf-8"))
    return None
