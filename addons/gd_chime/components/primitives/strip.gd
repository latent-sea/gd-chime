extends RefCounted

## A strip at rest: a scroll across (scroll.gd) that shows whole things
## only, and says where more lies beyond an end.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A THING SPLIT AT THE END OF A STRIP IS WORDS LOST, whether or not the
## strip moves (clipped_text.gd), so a strip rests only where every thing
## it shows is whole. It rests with a thing's start at its near edge - at
## its far end, with the last thing's end at its far edge - and the room
## left over beside the whole things shown is covered. It moves a whole
## thing at a time, never part of one: however far a wheel, a drag or the
## pad asked, it goes on to the next thing that way, or back to the one
## before.
##
## WHERE MORE LIES BEYOND AN END, A COVER SAYS SO: the look's more_before or
## more_after box under Scroll, over that end, at least the look's more_room
## wide - the room is kept for it - and whatever of a thing lies under it is
## neither seen nor pressed. The floor's placeholder is a plain ground ruled
## on the side that faces the things; a look draws its own fade or arrow.
##
## THE THING THAT MUST BE SEEN IS SEEN: the one given (the flap of the place
## the reader is on) as it is given, and the one the focus has come to as it
## comes - each once, so a wheel may then move on from it.
##
## IT RESTS AGAIN ONCE WHAT IT HOLDS IS PLACED. Placed anew - its holder
## narrowed or widened - the strip rests on where its things stood before
## their row was laid out at the new width, since the row places its things
## after the strip is placed; so it rests once more when that is done, and a
## flap grown to share a wide strip is never left cut at the edge of a
## narrow one.
##
## It draws nothing itself and holds no look: the covers are the scroll's own
## internal children, drawn over what it scrolls and never laid out by it.

const TYPE := &"Scroll"

## A cover over one end of a strip, drawing the look's box for that end.
class Cover extends Control:
	var box: StringName  # the look's name for the box drawn: more_before or more_after

	func _draw() -> void:
		draw_style_box(get_theme_stylebox(box, TYPE), Rect2(Vector2.ZERO, size))


var shown: Rect2  # the part of the strip showing whole things, in its own coordinates
var _scroll: ScrollContainer
var _before := Cover.new()
var _after := Cover.new()
var _first: int = 0  # the thing it rests on at its near edge
var _keep: int = -1  # a thing given to be brought into view, until it has been
var _focused: Control = null  # the thing the focus was last seen in
var _resting_again: bool = false  # whether a second rest is waiting on the row being placed


func _init(scroll: ScrollContainer) -> void:
	_scroll = scroll
	_before.box = &"more_before"
	_after.box = &"more_after"
	# every cover drawn over what the strip holds, and taking the presses meant for what lies under it
	for cover: Cover in [_before, _after]:
		cover.mouse_filter = Control.MOUSE_FILTER_STOP
		cover.visible = false
		scroll.add_child(cover, false, Node.INTERNAL_MODE_BACK)


## This thing, one of what the strip holds, to be brought into view.
func keep(piece: Control) -> void:
	_keep = _things().find(piece)
	_scroll.queue_sort()


## The strip laid out again: rested on whole things, the covers put over its
## ends. Rests on the offset asked for now, if it moved, else where it was.
func rest() -> void:
	var things := _things()
	if things.is_empty():
		return
	var room := _scroll.size.x
	var starts: Array[float] = []
	var ends: Array[float] = []
	var focus := _scroll.get_viewport().gui_get_focus_owner()
	var holding: Control = null
	# every thing's extent along what is scrolled, and the one the focus is in, if any
	for thing: Control in things:
		starts.append(thing.position.x)
		ends.append(thing.position.x + thing.size.x)
		if focus != null and (thing == focus or thing.is_ancestor_of(focus)):
			holding = thing
	var keeping := _keep
	if holding != null and holding != _focused:
		keeping = things.find(holding)
	_focused = holding
	_keep = -1
	var at := resting(starts, ends, room, float(_scroll.get_theme_constant(&"more_room", TYPE)), _scroll.get_h_scroll_bar().value, _first, keeping)
	_first = at["first"]
	shown = Rect2(at["shown_from"], 0.0, at["shown_to"] - at["shown_from"], _scroll.size.y)
	_before.visible = at["before"]
	_before.position = Vector2.ZERO
	_before.size = Vector2(at["shown_from"], _scroll.size.y)
	_after.visible = at["after"]
	_after.position = Vector2(at["shown_to"], 0.0)
	_after.size = Vector2(room - at["shown_to"], _scroll.size.y)
	if not is_equal_approx(_scroll.get_h_scroll_bar().value, at["offset"]):
		_scroll.get_h_scroll_bar().value = at["offset"]
	# rested on where the things stood: once more when their row has placed them at this width
	if not _resting_again:
		_resting_again = true
		_rest_again.call_deferred()


## The second rest, after what the strip holds has been placed.
func _rest_again() -> void:
	rest()
	_resting_again = false


## What the strip holds, in order: the shown things of the one row it scrolls.
func _things() -> Array[Control]:
	var things: Array[Control] = []
	# every child of the row, the scroll's one piece, that is a shown thing
	for child: Node in _scroll.get_child(0).get_children():
		if child is Control and (child as Control).visible:
			things.append(child)
	return things


## Where a strip of things - each from its start to its end along what is
## scrolled - rests in this much room: the thing first in view, the offset
## that puts it at the near edge past any cover, the part of the room that
## shows whole things, and whether each end is covered with more beyond it.
## From the thing it rested on it moves a whole thing at least, the way the
## offset asked moved; a thing to keep in view is brought into it.
static func resting(starts: Array[float], ends: Array[float], room: float, mark: float, asked: float, rested: int, keeping: int) -> Dictionary:
	var count := starts.size()
	var near := func(first: int) -> float: return mark if first > 0 else 0.0
	# the offset resting on this first thing: its start past the cover, but no further than the end of the things can come to the far edge, as far as the engine scrolls
	var offset_of := func(first: int) -> float: return minf(starts[first] - near.call(first), maxf(0.0, ends[count - 1] - room))
	# the last thing shown whole from this first: one past it needs a cover's room after it, the last of all none
	var last_from := func(first: int) -> int:
		var last := first
		# every thing past the first, for the furthest that fits
		for at: int in range(first + 1, count):
			if ends[at] - starts[first] <= room - near.call(first) - (mark if at < count - 1 else 0.0):
				last = at
		return last
	var latest := 0
	# the earliest first thing from which every thing to the end is shown: none rests later
	while latest < count - 1 and last_from.call(latest) < count - 1:
		latest += 1
	var first := clampi(rested, 0, latest)
	var from: float = offset_of.call(first)
	# asked on, on to the first thing at least that far; asked back, back to the last thing at most that far
	if asked > from + 0.5:
		first += 1
		while first < latest and offset_of.call(first) < asked:
			first += 1
	elif asked < from - 0.5:
		first -= 1
		while first > 0 and offset_of.call(first) > asked:
			first -= 1
	first = clampi(first, 0, latest)
	if keeping >= 0 and keeping < first:
		first = keeping
	# a thing to keep lying past the last shown: on a thing at a time until it is shown
	while keeping > last_from.call(first) and first < latest:
		first += 1
	var last: int = last_from.call(first)
	var offset: float = offset_of.call(first)
	var from_x: float = starts[first] - offset
	return {"first": first, "offset": offset, "shown_from": from_x, "shown_to": from_x + ends[last] - starts[first], "before": first > 0, "after": last < count - 1}
