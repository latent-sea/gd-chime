"""Convention lint - does anything in a folder wire itself up by hand?

gd-chime. MIT licensed; see the LICENCE file at the root of this folder.

Scans every .gd file under a root for the conventions a reader cannot check
by reading one file: only a bell declares a signal, only the belfry makes one,
only the chimes connect one or take one out of the belfry, and only the theme
file names a colour.

One connection is not wiring: a script connecting a signal of a part it builds
itself - a member made with .new() in that same file - such as a text field
hearing its own LineEdit. The part is freed with the node that built it, so
the connection can neither outlive an end nor cross a region, and nothing
needs to record it. A member built later - declared at the top and made with
.new() inside a method, as a surface that builds its parts only when it is first
opened does - is a part as well, since the same node holds it and frees it. A
local built inside a function is not a part: it can be handed anywhere.

One more is about screens. A screen asks the look for a colour in
refresh() and nowhere else: a colour taken in a
constructor is painted once and never again, so the screen is woken by a
theme change, redraws, and puts back the colour it already had.

A colour written where it is used is the LOOK baked into the framework, which
is the thing D-122 control 9 keeps out: this ships a neutral palette as the
engine's own Theme, and the look belongs to whoever uses it. A colour picked at
the point of use also cannot follow a scheme the player chose.

The console is the exception and names its own colours, because it is read when
the look is the thing that is wrong - and in a build with no look set at all. A
surface that borrowed the theme to report on the theme would go dark with it.

Read-only. Reports how many files it looked at: a run over nothing proves
nothing.

at() is the one route by which anything could get hold of a bell it does not
own, which is what makes it the thing to watch. A bell carries nothing, so
holding one buys nothing but the ability to ring it behind the record's back.

The permitted files are named below because they are this folder's own
structure. Pointed at a folder that uses gd-chime rather than at gd-chime
itself, no path matches them, so nothing there may emit, connect anything but
its own parts, make a bell or reach into the belfry at all - which is the case
this is really for.

One exclusion, tests/, resolved rather than spelled: a test stands in for
whatever composes an application, so it holds the belfry and wires bells by
hand deliberately. A convention broken inside a test is therefore not seen
here, and is caught by the same reading as everything else in a test.

INTERFACE IS DESCRIBED, NOT BUILT BY HAND: the primitives (components/primitives/)
are the only engine code in interface code. Interface code is a component or
a recipe (components/) and a demo file that describes - one that names the
builder or a description; a model and the floor's machinery are not. In
interface code, anchors, nodes added by hand, mouse filters, size flags,
theme overrides, colour rects, labels built and deferred calls are reported:
a screen is a description the builder turns into nodes.

A COMPONENT (components/) has to work in any project, so nothing in one may
name a palette colour, name a type only a demo styles, set a layout number -
an anchor, an offset, a position, a size - or a font size. Its look is the
Theme's, under its own type; it asks for it by state.

A SCRIPT IS 250 LINES AT MOST, AND OPENS WITH ITS HEADER (D-259): over the
cap, the design wants splitting; a script says what it is in a ## header
near its top. Tests are exempt, as above. Checked here, at the commit, and
not as each edit is made - a question in the middle of the work stops it
for nothing that cannot wait for the commit.

A PROBE IS EXEMPT FROM THE CAP TOO, for a test's reason: its length counts
the claims its demo makes, and splitting one to fit scatters the claims of
one walk across files that exist for no other reason - which is what
pipes_timing.gd was. A probe is demo/**/probe.gd or demo/**/*_probe.gd, and
its header is still checked, as everything else here still is.

AN APPLICATION USES WHAT THE FACADE EXPORTS AND NOTHING ELSE (CONSTITUTION.md,
the promise): a script outside the addon - a demo, an app, a check - that
preloads or extends a file of the addon by its path may name only a file the
three facade files re-export, the facade itself, or ChimeApp. The exported
paths are read off the facade files themselves, so a name added there is
allowed here the same day, and a file reached past the facade is reported
with what to write instead. application.gd, the main loop a --script demo or
probe is run through, is not in the promise: it is allowed from demo/ and
checks/ alone, and anywhere else reported with ChimeApp to write instead.

Deliberately absent: it does not check that a listener was given addresses
rather than belfry, nor that a screen was handed a model rather than reaching
for one. A reference passed at run time is not in the text, so a scanner
claiming either would be trusted for something it cannot see.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

# where the floor lives in a project: the addon, whose files these names are relative to
FLOOR = "addons/gd_chime/"
EMITTERS = (FLOOR + "bell.gd",)
MAKERS = (FLOOR + "belfry.gd",)
# the chimes: the door that decides, and the record that holds the wires and so makes and cuts them
WIRERS = (FLOOR + "chimes.gd", FLOOR + "wires.gd")
# the one file that listens to the engine itself: the frame budget, on the rendering server's own signal
ENGINE_LISTENERS = (FLOOR + "frame_budget.gd",)
PAINTERS = tuple(FLOOR + name for name in ("theme.gd", "console.gd", "look.gd", "look_boxes.gd"))
# a look, under a looks folder, is a theme: it names its colours
LOOKS = "/looks/"
# extends "presentation.gd" or "../../presentation.gd": a screen, wherever in the addon it sits
SCREEN = re.compile(r'^extends "(?:\.\./)*presentation\.gd"', re.M)

DECLARES_SIGNAL = re.compile(r"^\s*signal\s+\w")
# connect( and disconnect(, but not is_connected( or get_connections(
WIRES = re.compile(r"\b(?:dis)?connect\s*\(")
# var _line := LineEdit.new() - a member the script builds itself, typed or not
BUILDS_A_PART = re.compile(r"^var\s+(\w+)\s*(?::\s*[\w.]*\s*)?=\s*[\w.]+\.new\s*\(")
# var _tabs: TabBar - a member, which may be built later than it is declared
DECLARES_A_MEMBER = re.compile(r"^var\s+(\w+)")
# _tabs = TabBar.new() - a member built inside a method, still the script's own part
BUILDS_A_PART_LATER = re.compile(r"^\s+(\w+)\s*=\s*[\w.]+\.new\s*\(")
# _line.text_submitted.connect( - a signal of the member named first, being connected
CONNECTS_A_MEMBER = re.compile(r"\b(\w+)\.\w+\.connect\s*\(")
# .at( - the belfry handing back the bell itself
TAKES_A_BELL = re.compile(r"\.at\s*\(")
# the bell script itself, which only the belfry may load - by any path to it, own_bell.gd being another script
MAKES_A_BELL = re.compile(r"\"(?:[\w./]*/)?bell\.gd\"")
# get_colour( - asking the look for a colour, which is only ever right while drawing
ASKS_THE_LOOK = re.compile(r"\bget_colour\(")
# the name of whatever function a line is inside, so a rule can be about where
IN_FUNCTION = re.compile(r"^func\s+(\w+)")
# Color(...) or a #rrggbb literal - the look, written where it is used
NAMES_A_COLOUR = re.compile(r"\bColor[8N]?\s*\(")
# the folder whose files are components, and what none of them may say
COMPONENTS = FLOOR + "components/"
# &"ground" and the rest of the palette by name
NAMES_A_PALETTE_COLOUR = re.compile(r"&\"(?:ground|raised|lit|ink|ink_soft|accent|shade)\"")
# a kind of words only a demo styles, by constant or by name; a title and a number are the floor's now (theme.gd)
NAMES_A_DEMO_TYPE = re.compile(r"\b(?:READOUT|LINE)\b|&\"(?:Readout|Line)\"")
# anchor_left = 0.15, offset_top = -8, position = Vector2(4, 4): a layout number
SETS_A_LAYOUT_NUMBER = re.compile(r"\b(?:anchor_\w+|offset_\w+|position|size|custom_minimum_size|border_width\w*|separation)\s*=\s*(?:-?\d|Vector2\s*\(\s*-?\d)")
# a font size, set or overridden - never one read from the look, which a primitive shaping its own words asks for
SETS_A_FONT_SIZE = re.compile(r"set_font_size|font_size_override|\bfont_size\s*=(?!=)")
# the primitives: the only engine code; outside them, interface is described
PRIMITIVES = FLOOR + "components/primitives/"
DEMOS = "demo/"
# a file that describes: it names the builder or a description
DESCRIBES = re.compile(r"primitives/(?:ui|desc)\.gd\"|-> Desc\b|\bUi\b")
LINE_CAP = 250
# the three facade files, whose re-exports are the promise, and the node an app file may name beside them
FACADE = ("gd_chime.gd", "gd_chime_recipes.gd", "gd_chime_floor.gd")
ENTRY_POINTS = ("chime_app.gd",)
# the demos' and probes' main loop, and the folders it may be named from
MAIN_LOOP = "application.gd"
LOOP_NAMED_FROM = (DEMOS, "checks/")
# preload("card.gd") or _at("components/recipes/card.gd") in a facade file: a path it exports, from the addon's root
EXPORTS = re.compile(r'(?:preload|_at)\("([^"]+)"\)')
# a quoted absolute path into the addon, preloaded or extended from outside it: what follows the addon's folder is the file reached
INTO_ADDON = re.compile(r'"res:/{2}' + FLOOR + r'([^"]+)"')
# anchors, nodes added, mouse filters, size flags, theme overrides, a rect, a label built, a deferred call: engine code
ENGINE_CODE = re.compile(r"\banchor_\w+\b|set_anchors_preset|\badd_child\s*\(|mouse_filter|size_flags|add_theme_\w+_override|theme_type_variation|\bColorRect\b|\bLabel\.new\b|call_deferred")


def exported(root: Path) -> set[str]:
    """Every path the facade re-exports, from the addon's root, with the facade files and the entry points."""
    paths = set(FACADE) | set(ENTRY_POINTS)
    # every facade file, for every path it preloads or fetches on first use
    for listing in FACADE:
        paths |= set(EXPORTS.findall((root / FLOOR / listing).read_text(encoding="utf-8")))
    return paths


def main() -> int:
    root = Path(sys.argv[1])
    tests = root / "tests"
    promised = exported(root)

    hits = 0
    scanned = 0
    # every script under the root, in a fixed order so two runs report alike
    for path in sorted(root.rglob("*.gd")):
        if tests in path.parents:
            continue
        scanned += 1
        rel = path.relative_to(root).as_posix()
        text = path.read_text(encoding="utf-8")
        # a probe's length counts the claims its demo makes, as a test's counts its properties
        probe = rel.startswith(DEMOS) and (path.name == "probe.gd" or path.name.endswith("_probe.gd"))
        if not probe and len(text.splitlines()) > LINE_CAP:
            print(f"{rel}: {len(text.splitlines())} lines, over the {LINE_CAP}-line cap; the design wants splitting")
            hits += 1
        # the header: a ## line among the first forty
        if not any(line.startswith("##") for line in text.splitlines()[:40]):
            print(f"{rel}: no ## header near its top; a script says what it is, what it must never do, what was chosen against")
            hits += 1

        screen = SCREEN.search(text) is not None
        # interface code: a component, or a demo file that describes
        interface = rel.startswith(COMPONENTS) or (rel.startswith(DEMOS) and DESCRIBES.search(text) is not None)
        members = {declared.group(1) for declared in map(DECLARES_A_MEMBER.match, text.splitlines()) if declared}
        # the members this script builds itself, whose own signals it may connect - where declared, or later
        parts = {built.group(1) for built in map(BUILDS_A_PART.match, text.splitlines()) if built}
        # a member built inside a method counts, and a local of the same shape does not
        parts |= {built.group(1) for built in map(BUILDS_A_PART_LATER.match, text.splitlines()) if built and built.group(1) in members}
        inside = ""
        # the content, line by line, so a hit can be pointed at
        for number, line in enumerate(text.splitlines(), start=1):
            named = IN_FUNCTION.match(line)
            if named:
                inside = named.group(1)
            if screen and inside != "refresh" and ASKS_THE_LOOK.search(line):
                print(f"{rel}:{number}: ask for the look in refresh(), or it is painted once and never again")
                hits += 1
            # a path into the addon from outside it, for one the facade does not export
            for reached in INTO_ADDON.findall(line) if not rel.startswith(FLOOR) else []:
                if reached == MAIN_LOOP and not rel.startswith(LOOP_NAMED_FROM):
                    print(f"{rel}:{number}: {MAIN_LOOP} is the demos' and probes' main loop, named from {' and '.join(LOOP_NAMED_FROM)} alone; a game extends ChimeApp")
                    hits += 1
                elif reached not in promised and reached != MAIN_LOOP:
                    print(f"{rel}:{number}: {reached} is not what the facade exports; an application uses GdChime.<Name> and ChimeApp, and nothing past them")
                    hits += 1
            if DECLARES_SIGNAL.match(line) and rel not in EMITTERS:
                print(f"{rel}:{number}: only a bell may declare a signal")
                hits += 1
            if MAKES_A_BELL.search(line) and rel not in MAKERS:
                print(f"{rel}:{number}: only the belfry may make a bell")
                hits += 1
            connected = CONNECTS_A_MEMBER.search(line)
            # connecting a signal of a part the script built itself is not wiring
            to_its_own_part = connected is not None and connected.group(1) in parts
            if WIRES.search(line) and rel not in WIRERS and rel not in ENGINE_LISTENERS and not to_its_own_part:
                print(f"{rel}:{number}: only the chimes may connect a signal, beyond a part a script builds itself")
                hits += 1
            if TAKES_A_BELL.search(line) and rel not in WIRERS:
                print(f"{rel}:{number}: only the chimes may take a bell out of the belfry")
                hits += 1
            if NAMES_A_COLOUR.search(line) and rel not in PAINTERS and LOOKS not in rel:
                print(f"{rel}:{number}: a colour belongs in the scheme; ask for it by name")
                hits += 1
            if interface and not rel.startswith(PRIMITIVES) and ENGINE_CODE.search(line.split("#")[0]):
                print(f"{rel}:{number}: engine code belongs in a primitive; describe the interface instead")
                hits += 1
            if rel.startswith(COMPONENTS):
                if NAMES_A_PALETTE_COLOUR.search(line):
                    print(f"{rel}:{number}: a component names no palette colour; its look is its theme type's")
                    hits += 1
                if NAMES_A_DEMO_TYPE.search(line):
                    print(f"{rel}:{number}: a component names no demo type")
                    hits += 1
                if SETS_A_LAYOUT_NUMBER.search(line):
                    print(f"{rel}:{number}: a component sets no layout number; its parts are placed by the container and the theme")
                    hits += 1
                if SETS_A_FONT_SIZE.search(line):
                    print(f"{rel}:{number}: a component sets no font size; the theme does")
                    hits += 1

    print(f"{scanned} script(s) scanned, {hits} hit(s)", file=sys.stderr)
    return 1 if hits or not scanned else 0


if __name__ == "__main__":
    sys.exit(main())
