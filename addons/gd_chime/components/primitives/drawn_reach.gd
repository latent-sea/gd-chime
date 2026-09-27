extends RefCounted

const PaintedBox := preload("../../painted_box.gd")

## How far a part draws past its own edges: the shadow and the expand margin
## of the box it wears, and of whatever it holds at that edge, read from the
## look's own numbers - so a line can keep that room clear of its neighbour.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## NOTHING IS DRAWN OVER ANYTHING ELSE, a shadow over words included: a
## raised box's light cast up over the line above it shaves the foot of its
## letters, and its dark cast down over the name under it the same. So a
## line (flex.gd) leaves between two parts room for what each draws past its
## edge toward the other WHERE IT WOULD FALL ACROSS THE OTHER'S WORDS, as was
## ruled (2026-09-19): a shadow passing beside the words, or over another
## box, takes no room. The room is what the shadow reaches past the edge
## less how deep in the words stand, and never less than the line's own gap
## - wherever the look's gap already covers a shadow, nothing moves.
##
## A PART'S REACH is the most of: its own box's, and each thing it holds's
## less how far that stands in from the part's edge. A part that clips draws
## nothing of what it holds past itself, so only its own box counts. A line
## answers for itself (get_reach), from where it placed its parts, and so
## does a face, from the box it stays in and where it placed its content:
## each works its reach out once, as it places what it holds, and tells the
## line holding it when that changed - so a line placing its parts again,
## a hundred times as a pane is dragged, asks and walks nothing.
## The box read is the one a part stays drawn in: a face's for its lasting
## state (face.gd), since the room kept must not move as a pointer passes
## over it; anything else's panel, else normal.
##
## It holds nothing and draws nothing.

## The boxes a part may wear at rest, the first it has being the one it draws.
const WORN: Array[StringName] = [&"panel", &"normal"]


## How far this part draws past each of its edges, by side (SIDE_LEFT,
## SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM), in the pixels it is laid out in.
static func of(part: Control) -> Array[float]:
	if part.has_method(&"get_reach"):
		return [part.get_reach(SIDE_LEFT), part.get_reach(SIDE_TOP), part.get_reach(SIDE_RIGHT), part.get_reach(SIDE_BOTTOM)]
	return walked(part, worn(part))


## Every part's reach, in order, as of() answers it: what a line asks once
## as it measures or places, for its gaps and for what it draws past itself.
static func of_each(parts: Array[Control]) -> Array:
	return parts.map(func(part: Control) -> Array[float]: return of(part))


## How far this part draws past each of its edges, worked out from the box
## it stays drawn in (worn(), or null for none) and what it holds as they
## stand - what a part answering for itself works out once, as what it
## holds is placed, with the box it already knows it is in.
static func walked(part: Control, box: StyleBox) -> Array[float]:
	var reach: Array[float] = [0.0, 0.0, 0.0, 0.0]
	# every side its box reaches past
	for side: int in (4 if box != null else 0):
		reach[side] = PaintedBox.reach_of(box, side)
	if part.clip_contents:
		return reach
	# every shown thing it holds, reaching past this part's edge by its own reach less how far in it stands
	for held: Node in part.get_children():
		if held is Control and (held as Control).visible:
			var its := of(held)
			# every side, the held thing's reach less how far in from that edge it stands
			for side: int in 4:
				reach[side] = maxf(reach[side], its[side] - inset(part, held, side))
	return reach


## The box a part stays drawn in, if it draws one: a face says which
## (get_drawn_box); anything else, the first box it wears at rest.
static func worn(part: Control) -> StyleBox:
	if part.has_method(&"get_drawn_box"):
		return part.get_drawn_box()
	# every box a part may wear at rest, for the first it has, which is the one it draws
	for name: StringName in WORN:
		if part.has_theme_stylebox(name):
			return part.get_theme_stylebox(name)
	return null


## How far in from the holder's edge on this side a thing it holds stands:
## none for a thing standing past the edge, since what hangs past a holder
## is its overflow, not anything drawn past its box - held apart here, or
## a line giving room to an overflow would squeeze its parts into more.
static func inset(holder: Control, held: Control, side: int) -> float:
	var room: float = [held.position.x, held.position.y, holder.size.x - held.position.x - held.size.x, holder.size.y - held.position.y - held.size.y][side]
	return maxf(0.0, room)


## The gap before each part of a line, in order: room for the shadow of
## the part before where it falls across this one's words, and for this
## one's where it falls across the words of the part before; never less
## than the line's own gap - nothing before the first. Each part's reach
## is given, as of() answers it, so a line asks it once for both uses.
static func gaps(parts: Array, reaches: Array, gap: float, across: bool) -> Array:
	var near := SIDE_LEFT if across else SIDE_TOP
	var far := SIDE_RIGHT if across else SIDE_BOTTOM
	var before: Array = [0.0]
	# every part after the first, against the one before it
	for at: int in range(1, parts.size()):
		var room := gap
		# a shadow reaching no further than the gap falls on nothing, so only a longer one is looked at closely
		if reaches[at - 1][far] > gap:
			room = maxf(room, _over_words(parts[at - 1], far, parts[at], near, across))
		if reaches[at][near] > gap:
			room = maxf(room, _over_words(parts[at], near, parts[at - 1], far, across))
		before.append(room)
	return before


## The room a shadow cast past this side of one part needs from the words
## of the part facing it: for every box reaching past, and every set of
## words that part holds within that reach of its facing edge, standing
## across the line where the shadow falls, the reach less how deep they are.
static func _over_words(casting: Control, side: int, facing: Control, facing_side: int, across: bool) -> float:
	var room := 0.0
	# every box drawing past the edge, against every set of words within its reach of the facing edge
	for shadow: Array in _shadows(casting, side, across):
		for words: Array in _words(facing, facing_side, shadow[2], across):
			if shadow[0] < words[1] and words[0] < shadow[1]:
				room = maxf(room, shadow[2] - words[2])
	return room


## Every box in this part drawing past its edge on this side: where it
## spans across the line, on the canvas, and how far past the edge it reaches.
static func _shadows(part: Control, side: int, across: bool) -> Array:
	var found: Array = []
	var box := worn(part)
	if box != null and PaintedBox.reach_of(box, side) > 0.0:
		var sides: Array = [SIDE_TOP, SIDE_BOTTOM] if across else [SIDE_LEFT, SIDE_RIGHT]
		var rect := part.get_global_rect()
		var from: float = (rect.position.y if across else rect.position.x) - PaintedBox.reach_of(box, sides[0])
		var to: float = (rect.end.y if across else rect.end.x) + PaintedBox.reach_of(box, sides[1])
		found.append([from, to, PaintedBox.reach_of(box, side)])
	if part.clip_contents:
		return found
	# every shown thing it holds, its shadows reaching past this part's edge by their reach less how far in it stands
	for held: Node in part.get_children():
		if held is Control and (held as Control).visible:
			var deep := inset(part, held, side)
			found.append_array(_shadows(held, side, across).map(func(shadow: Array) -> Array: return [shadow[0], shadow[1], shadow[2] - deep]).filter(func(shadow: Array) -> bool: return shadow[2] > 0.0))
	return found


## Every set of words in this part standing within this depth of its edge
## on this side: where the words themselves span across the line, on the
## canvas - the letters, not the box they are set in - and how deep they are.
static func _words(part: Control, side: int, within: float, across: bool) -> Array:
	var found: Array = []
	if part is Label and (part as Label).text.strip_edges() != "":
		var label := part as Label
		var rect := label.get_global_rect()
		if across:
			return [[rect.position.y, rect.end.y, 0.0]]
		# as wide as a line of them needs, which is the least a label asks for; words that wrap are taken as wide as their box
		var wide: float = label.get_minimum_size().x if label.autowrap_mode == TextServer.AUTOWRAP_OFF else rect.size.x
		# where the letters start: at the left, the middle, or the right of the words' box, as they are set
		var start: float = rect.position.x + [0.0, (rect.size.x - wide) / 2.0, rect.size.x - wide, 0.0][label.horizontal_alignment]
		return [[start, start + minf(wide, rect.size.x), 0.0]]
	# every shown thing it holds within the depth, its words that much deeper again
	for held: Node in part.get_children():
		if held is Control and (held as Control).visible:
			var deep := inset(part, held, side)
			if deep < within:
				found.append_array(_words(held, side, within - deep, across).map(func(words: Array) -> Array: return [words[0], words[1], words[2] + deep]))
	return found


## How far these parts, as placed in their holder, draw past each of its
## edges, by side - each part's reach given, as of() answers it.
static func past(holder: Control, parts: Array, reaches: Array) -> Array[float]:
	var reach: Array[float] = [0.0, 0.0, 0.0, 0.0]
	# every part and every side, for the furthest any part draws past the holder's edge there
	for at: int in parts.size():
		for side: int in 4:
			reach[side] = maxf(reach[side], reaches[at][side] - inset(holder, parts[at], side))
	return reach


## What a line or a face draws past its edges has changed: the nearest
## holding it that answers for its own reach, if any, measures again - the
## gaps it needs are part of the room it asks for - and places what it holds
## again, leaving the room that now needs, and tells its own holder in turn.
static func tell_holder(line: Control) -> void:
	var holder := line.get_parent()
	# up through what holds it to the first that answers for its reach
	while holder != null and not holder.has_method(&"get_reach"):
		holder = holder.get_parent()
	if holder != null:
		(holder as Container).update_minimum_size()
		(holder as Container).queue_sort()
