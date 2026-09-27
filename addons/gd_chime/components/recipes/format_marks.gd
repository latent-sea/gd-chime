extends RefCounted

## The rule that meaning never rests on hue alone, as something that runs:
## a conditional format must mark what it singles out.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A table's format (table.gd) dresses a cell by its value - a mark after the
## words, the kind the words are in, and the ground they sit on. The kind and
## the ground are how a look says "this one is different", and a look says it
## in colour. A reader who cannot see that colour is told nothing, unless the
## mark says it too.
##
## So: TWO DRESSES THAT LOOK DIFFERENT MUST BE MARKED DIFFERENTLY. Neither is
## "the plain one" - the first value a table happens to show may as well be
## the one singled out - so the rule has no sides: a different kind or a
## different ground under the same mark is two things told apart by hue
## alone. That is what alike_but_for_hue() answers of a pair, and clashes()
## of a dress against every one its format has given before; the table
## reports it out loud in a developer's build - where it can be fixed - once
## for each new dress, and never in a shipped one.
##
## It cannot be decided from a format alone: a format is a function, and what
## it does at a value nobody has is not knowable. So it is decided from the
## dresses that actually happen, which is every dress the reader ever sees.

static var _given: Dictionary = {}  # a format -> every different dress it has given, as [kind, style, mark]


## Whether two dresses look different and are marked the same.
static func alike_but_for_hue(one: Dictionary, other: Dictionary) -> bool:
	return one["mark"] == other["mark"] and (one["kind"] != other["kind"] or one["style"] != other["style"])


## A dress this format has not given before, kept, and whether it looks
## different from one given before under the same mark.
static func clashes(format: int, dress: Dictionary) -> bool:
	var given: Array = _given.get_or_add(format, [])
	var worn: Array = [dress["kind"], dress["style"], dress["mark"]]
	if given.has(worn):
		return false
	given.append(worn)
	return given.any(func(before: Array) -> bool: return alike_but_for_hue(dress, {"kind": before[0], "style": before[1], "mark": before[2]}))
