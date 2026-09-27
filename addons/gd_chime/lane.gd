extends "controller.gd"

const Carried := preload("carried.gd")

## A lane: one list of a board - a column of cards - as the reader sees it:
## its items in order, and the thing being carried shown where it would
## land.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE ORDER IS THE SOURCE'S, a bound value handed in - a model's items for
## this lane - and never a copy kept here to change. WHICH ITEMS ARE SHOWN
## IS ANOTHER BOUND VALUE, a test of an item, moving as what it read does: an
## item it turns away - narrowed by a search or a filter - is kept, its piece
## built once and only hidden (lanes.gd), since building a board's cards
## again on every keystroke would stall it; it is not counted and takes no
## place, a place being among the items shown. A search moves the test,
## never an item, so no card's own words are read again for it.
##
## While something is carried (carried.gd), it is taken out of the
## lane it came from and put in the lane it is over, at the place it is
## over: so a list target's keyed each builds it where it would land, the
## pieces after it make room, and the room it left closes - the live gap of
## a board. Set down, the source's order is shown again; a drop has moved
## the thing there in the model already (drop_target.gd), so nothing moves.
##
## IT IS SET ONLY WHEN WHAT IT SHOWS CHANGED. Every lane follows every move
## of the carry and every change of the source, and works out its items
## once; the items shown, a value (value.gd), are set only for a lane whose
## items are not what they were, so a pointer crossing one column wakes
## that column and the one it left, and never the other four - nor the words
## of every card in them.
##
## Deliberately absent: an order of its own, a narrowing of its own, and any
## memory of where the thing carried came from - the source still has it.

var _carried: Carried
var _source: Bound
var _shows: Bound  # reads a Callable: whether an item is shown
var _into: Variant  # the lane this is, as a list target names it
var _key: Callable  # an item to its identity
var _shown := value([])  # the items as they are shown now


func _init(chimes: Chimes, carried: Carried, source: Bound, shows: Bound, into: Variant, key: Callable) -> void:
	super(chimes, [], StringName("lane %s" % [into]))
	_carried = carried
	_source = source
	_shows = shows
	_into = into
	_key = key
	follow(&"shown", _worked_out)


## The items as the reader sees them now, those turned away among them.
func get_items() -> Array:
	return _shown.read()


## The test of whether an item is shown.
func get_shows() -> Callable:
	return _shows.read()


## How many items are shown, those turned away not counted.
func get_count() -> int:
	return _shown.read().filter(_shows.read()).size()


## The lane this is.
func get_into() -> Variant:
	return _into


## The source, the test and the carry read, so they are followed: the items
## worked out again, and set only if they changed.
func _worked_out() -> void:
	var now := shown(_source.read(), _key, _carried.get_payload() if _carried.is_carrying() else {}, _carried.get_over(), _into, _shows.read())
	if now != _shown.read():
		_shown.set_value(now)


## A lane's items as shown: the thing carried, if any, taken out wherever it
## stands, and put in at the place it is over when that is this lane -
## before the item shown at that place, those turned away stepped over, or
## after the last shown.
static func shown(items: Array, key: Callable, carried: Dictionary, over: Dictionary, into: Variant, shows: Callable) -> Array:
	if carried.is_empty():
		return items
	var carried_key: Variant = key.call(carried)
	var left: Array = items.filter(func(item: Dictionary) -> bool: return key.call(item) != carried_key)
	if over.get("into") != into:
		return left
	var seen := 0
	var at := 0
	# every item, for the one shown at the place it is over; past the last shown, just after it
	for index: int in left.size():
		if not shows.call(left[index]):
			continue
		if seen == over["at"]:
			at = index
			break
		seen += 1
		at = index + 1
	left.insert(at, carried)
	return left
