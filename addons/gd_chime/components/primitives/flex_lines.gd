extends RefCounted

## Which parts of a flex layout stand on which line.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## CSS Flexible Box Layout Level 1, § 9.3 Collect flex items into flex lines:
## the parts in order, each line taking the next part while it fits along
## with the gap before it, and always taking one, so a part longer than the
## room stands on a line of its own rather than on none. Not wrapping, every
## part is on the one line, whatever it overflows.
##
## The parts are first put in their order, § 9.1 and the order fact: the
## shown children, by the order each was given, and where they sit where
## two were given the same. Collecting them is then arithmetic over what
## each part wants and the gap before it - no rect, no engine; the layout
## (flex.gd) decides what a part wants and how wide each gap is, and places
## the parts on the lines this gives back. How long each part then is on its
## line is flex_line.gd's.
##
## HOW THICK EACH OF THEM IS ACROSS, § 9.4: the thickest part on the line -
## and where the lines SHARE the room (align-content: stretch, § 8.4), and
## every line fits across at that with the gaps between them, an even share
## of what is left over besides, so rows of cards fill a screen they fit.
## Where they do not all fit, each line is its thickest and the layout asks
## for them all, for whatever holds it to scroll.


## The parts a line lays out, in order: every shown control among these
## children, by the order fact given for it, and where it sits among equals.
static func ordered(children: Array, facts: Dictionary) -> Array[Control]:
	var parts: Array[Control] = []
	var given := false
	# every child that is a shown control, since anything else is not laid out; and whether any was given an order
	for child: Node in children:
		if child is Control and (child as Control).visible:
			parts.append(child)
			given = given or facts[child].has("order")
	# none given an order, the children's own order is the line's, with nothing to sort
	if not given:
		return parts
	# the engine's sort does not keep equal parts as they were, so where they sit decides
	parts.sort_custom(func(a: Control, b: Control) -> bool:
		var first: float = facts[a].get("order", 0.0)
		var second: float = facts[b].get("order", 0.0)
		return a.get_index() < b.get_index() if first == second else first < second)
	return parts


## The parts on each line, in order, each named by where it stands among
## them: every part is what it wants along the line and the gap before it -
## the first's is never taken, since no line breaks before it.
static func collect(wants: Array, gaps: Array, room: float, wrapping: bool) -> Array:
	var lines: Array = []
	var line: Array = []
	var taken := 0.0
	# the parts in turn: a line takes the next while it fits, and always takes one
	for at: int in wants.size():
		if wrapping and not line.is_empty() and taken + gaps[at] + wants[at] > room:
			lines.append(line)
			line = []
			taken = 0.0
		taken += wants[at] + (gaps[at] if not line.is_empty() else 0.0)
		line.append(at)
	lines.append(line)
	return lines


## How thick each line is across, the lines given by where their parts
## stand and each part's least across beside: its thickest part's - and,
## sharing, an even share of the room left once every line has that and its
## gap, where any is left.
static func thicknesses(lines: Array, across: Array, room: float, gap: float, sharing: bool) -> Array:
	# every line, for the thickest of the parts standing on it
	var thick: Array = lines.map(func(line: Array) -> float: return line.map(func(at: int) -> float: return across[at]).max())
	# the room left across once every line stands at its thickest, with a gap between each two
	var spare: float = room - thick.reduce(func(sum: float, one: float) -> float: return sum + one, 0.0) - gap * (lines.size() - 1)
	if not sharing or spare <= 0.0:
		return thick
	return thick.map(func(one: float) -> float: return one + spare / thick.size())
