extends "long_list.gd"

const Throttle := preload("throttle.gd")

## A feed: entries arriving at the end of a long list, looked at by rows
## (virtual_list.gd) - following the newest while the reader stands there,
## holding still while they have scrolled away or are on an entry.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A ROW IS AN ENTRY'S SERIAL, NEVER ITS PLACE: the first entry ever taken is
## row 0 and each after it the next, so what the reader is looking at keeps
## its rows as entries arrive and nothing under them moves. Past the
## capacity the oldest are let go: their rows hold nothing, the look is
## never before the oldest held, and the reader standing there is carried
## to it. Every entry is numbered as it is taken, under SERIAL.
##
## FOLLOWING is standing at the newest: the look is the last rows, and an
## entry taken moves it on. Scrolling away - the wheel, the keys, the pad -
## stops following, and every entry taken meanwhile is counted as UNSEEN;
## scrolling back to the end, or FOLLOWS, follows again and the count is
## gone. The CURSOR - the row the reader is on, moved by the keys and the
## pad (MOVES {by}), a press (PRESSES {at}) and let go (LETS_GO) - holds the
## feed still while it is on a row: a reader reading an entry is never
## carried off it. The focus is the list's own, so no append takes it.
##
## Its bells are gathered: whatever arrives in a frame moves the look and
## the rows once at its end (throttle.gd); the count unseen, the following
## and the cursor, the reader's own, are values (value.gd).
##
## Deliberately absent: an entry changed after it is taken, a filter, and
## asking a source for rows - a feed holds what it was given.

const FOLLOWS := &"follows_the_newest"
const MOVES := &"moves_along_the_feed"
const PRESSES := &"presses_an_entry"
const LETS_GO := &"lets_go_of_the_entry"
## Every action a feed is told beyond a long list's own.
const FOLLOWING: Array[StringName] = [FOLLOWS, MOVES, PRESSES, LETS_GO]
## The key every entry is numbered under as it is taken.
const SERIAL := &"serial"

var _capacity: int
var _entries: Array = []  # the entries held, oldest first
var _gone: int = 0  # how many were let go: the row of the oldest held
var _following := value(true)
var _unseen := value(0)  # entries taken since the reader stopped following
var _at := value(-1)  # the row the cursor is on, or -1 for none
var _arrivals: Throttle
var _look_moved: bool = false  # whether the look moved since the rows were last rung


func _init(chimes: Chimes, capacity: int, showing: int) -> void:
	# a feed holds what it was given: nothing under it moves its rows
	super(chimes, Callable(), 1, 1, showing, Bound.new(func() -> Variant: return null))
	_capacity = capacity
	_arrivals = Throttle.new(_ring)
	add_child(_arrivals)


## These entries taken at the end, oldest first, each numbered.
func append(entries: Array) -> void:
	# every entry, numbered with its row
	for entry: Dictionary in entries:
		entry[SERIAL] = count()
		_entries.append(entry)
	var over := _entries.size() - _capacity
	if over > 0:
		_entries = _entries.slice(over)
		_gone += over
		if _at.read() >= 0:
			_at.set_value(maxi(_at.read(), _gone))
	if _following.read() and _at.read() < 0:
		_move_to(_last_first())
	else:
		_unseen.set_value(_unseen.read() + entries.size())
		_move_to(_first)
	_arrivals.ask()


## Every row there has ever been: the serial the next entry will take.
func count() -> int:
	Reads.note(region, PAGE_LANDED)
	return _gone + _entries.size()


func has(index: int) -> bool:
	return index >= _gone and index < count()


func has_failed(_index: int) -> bool:
	return false


func get_item(index: int) -> Variant:
	return _entries[index - _gone] if has(index) else null


func get_following() -> bool:
	return _following.read() and _at.read() < 0


## How many entries arrived since the reader stopped following.
func get_unseen() -> int:
	return _unseen.read()


## The row the cursor is on, or -1.
func get_at() -> int:
	return _at.read()


## The entry the cursor is on, or null.
func get_entry() -> Variant:
	return get_item(_at.read())


## The row a list with a cursor keeps in view (list_cursor.gd): the
## cursor's, or with none the first shown, so letting go moves nothing.
func get_in_view() -> int:
	return _at.read() if _at.read() >= 0 else get_first()


## Nothing held and nothing to follow to or move along is refused; the rest a long list's.
func would(action: StringName, payload: Dictionary) -> Phrase:
	match action:
		FOLLOWS: return Phrase.of("Already following the newest") if get_following() else null
		MOVES, PRESSES: return Phrase.of("Nothing has arrived yet") if count() == _gone else null
		LETS_GO: return Phrase.of("On no entry") if _at.read() < 0 else null
	return super(action, payload)


func told(action: StringName, payload: Dictionary) -> Phrase:
	var at: int = _at.read()
	match action:
		FOLLOWS:
			_at.set_value(-1)
			_move_to(_last_first())
		# on no entry yet, the first move lands on the lowest row shown; after, it moves by the rows asked
		MOVES: _at.set_value(clampi(at + payload["by"], _gone, count() - 1) if at >= 0 else mini(_first + _showing, count()) - 1)
		PRESSES: _at.set_value(payload["at"])
		LETS_GO: _at.set_value(-1)
		SHOWS:
			_showing = payload["count"]
			_move_to(_last_first() if get_following() else _first)
			strike(region, LOOK_MOVED)
		_: return super(action, payload)
	return null


## The look held within the entries held, never before the oldest; standing
## at the last rows, following, and the count of unseen gone.
func _move_to(first: int) -> void:
	var was := _first
	_first = clampi(first, _gone, maxi(_last_first(), _gone))
	var following := _first >= _last_first()
	if following != _following.read():
		_following.set_value(following)
	if following and _unseen.read() > 0:
		_unseen.set_value(0)
	if _first != was:
		_look_moved = true
		_arrivals.ask()


## The first row of the look that shows the newest.
func _last_first() -> int:
	return maxi(count() - _showing, _gone)


## The frame's end: the rows, and the look if it moved, rung once.
func _ring() -> void:
	if _look_moved:
		_look_moved = false
		strike(region, LOOK_MOVED)
	strike(region, PAGE_LANDED)


## Every action this model is told.
func answers() -> Array[StringName]:
	return super() + FOLLOWING
