extends "controller.gd"

const Commands := preload("commands.gd")
const QueriedRows := preload("queried_rows.gd")
const PackedRows := preload("packed_rows.gd")

## Which rows of a queried view (queried_rows.gd) are picked, and where the
## reader is: the CURSOR, the place of the row they are on, and MOVES_ACROSS, the
## column in it - so the keys, the pad and the pointer all move one thing,
## and whatever acts on "this row" asks here which it is.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A PICK IS BY ROW, NOT BY PLACE: a flag per row the rows hold, so a pick
## survives a sort, a filter and a regrouping, and a row filtered out and
## back is picked still. How many are picked is counted as they change,
## never by looking. The cursor is a place in the view, held within it as
## the view moves; the ANCHOR is where a run of picks began.
##
## THE COMMANDS, every one of them the keys', the pad's and the pointer's
## alike. MOVES {by} or {to} - to -1 is the last place - moves the cursor
## and sets the anchor there. EXTENDS the same, picking every row from the
## anchor to where the cursor lands. MOVES_ACROSS {by} moves the column, within
## those shown. PICKS {at} is a press on a place: that row alone picked;
## with "adds", its pick turned and the rest left; with "extends", the run
## from the anchor to it; with "across", the column pressed. TOGGLES turns
## the pick of the row at the cursor - on a group's heading, the whole
## group's: all picked, unless all were. PICKS_EVERY_ROW_KEPT picks every row the view
## keeps, shut groups' too; CLEARS every pick.
##
## WHAT IS ACTED ON (get_acted_on): the rows picked, or, with none picked,
## the row at the cursor - so an action is the same press whether the
## reader picked three hundred rows or is simply on one.
##
## Deliberately absent: a pick of a column or of a single cell, and a run
## of picks taken away again by a second extending.

const MOVES := &"moves_the_cursor"
const EXTENDS := &"extends_the_picks"
const MOVES_ACROSS := &"moves_across"
const PICKS := &"picks_a_row"
const TOGGLES := &"toggles_the_pick"
const PICKS_EVERY_ROW_KEPT := &"picks_every_row_kept"
const CLEARS := &"clears_the_picks"
const COMMANDS: Array[StringName] = [MOVES, EXTENDS, MOVES_ACROSS, PICKS, TOGGLES, PICKS_EVERY_ROW_KEPT, CLEARS]

var _view: QueriedRows
var _columns: Callable  # how many columns are shown, asked as the column moves
var _picked := value(PackedByteArray())  # a flag per row: 1 picked
var _count := value(0)  # how many rows are picked, counted as the flags change
var _cursor := value(0)  # the place the reader is on, as last moved - read held within the view
var _anchor: int = 0  # where a run of picks began, held within the view as it is used
var _across := value(0)


func _init(chimes: Chimes, view: QueriedRows, columns: Callable) -> void:
	super(chimes)
	_view = view
	_columns = columns
	var picked := PackedByteArray()
	picked.resize(view.get_rows().count())
	_picked.set_value(picked)


## The place the reader is on, held within the view as it is now: the view
## moving never leaves it past the last place, and nothing has to hear it move.
func get_cursor() -> int:
	return mini(_cursor.read(), maxi(_view.get_count() - 1, 0))


func get_across() -> int:
	return _across.read()


## How many rows are picked.
func get_count() -> int:
	return _count.read()


func is_picked(row: int) -> bool:
	return _picked.read()[row] == 1


## The rows an action acts on: those picked, else the row at the cursor, else none.
func get_acted_on() -> PackedInt32Array:
	var rows := PackedInt32Array()
	if _count.read() == 0:
		var here := _view.row_at(get_cursor()) if _view.get_count() > 0 else -1
		return rows if here < 0 else PackedInt32Array([here])
	var picked: PackedByteArray = _picked.read()
	var at := picked.find(1)
	# every picked row, found by the engine from the one before
	while at >= 0:
		rows.append(at)
		at = picked.find(1, at + 1)
	return rows


## Other rows, before the view is given them (queried_rows.gd, replace), so
## no row it shows is ever asked after that has no flag: a flag for each of
## them and none picked, the cursor, the anchor and the column at the first.
func replace(rows: PackedRows) -> void:
	var picked := PackedByteArray()
	picked.resize(rows.count())
	_picked.set_value(picked)
	_count.set_value(0)
	_cursor.set_value(0)
	_anchor = 0
	_across.set_value(0)


func would(action: StringName, payload: Dictionary) -> Phrase:
	if action == CLEARS:
		return Phrase.of("Nothing is picked") if _count.read() == 0 else null
	if _view.get_count() == 0:
		return Phrase.of("No rows are shown")
	if action in [MOVES, EXTENDS] and payload.has("by") and get_cursor() + payload["by"] < 0:
		return Phrase.of("Already at the first row")
	if action in [MOVES, EXTENDS] and payload.has("by") and get_cursor() + payload["by"] >= _view.get_count():
		return Phrase.of("Already at the last row")
	return null


func told(action: StringName, payload: Dictionary) -> Phrase:
	match action:
		MOVES, EXTENDS:
			var to: int = payload["to"] if payload.has("to") else get_cursor() + payload["by"]
			_move(_view.get_count() - 1 if to < 0 else to, action == EXTENDS)
		MOVES_ACROSS:
			_across.set_value(clampi(_across.read() + payload["by"], 0, _columns.call() - 1))
		PICKS:
			if payload.has("across"):
				_across.set_value(payload["across"])
			if payload.get("extends", false):
				_move(payload["at"], true)
				return null
			if not payload.get("adds", false):
				_set_all(0)
			_move(payload["at"], false)
			# a heading pressed is the cursor put on it: it holds no row to pick
			if _view.row_at(get_cursor()) >= 0:
				_turn(PackedInt32Array([_view.row_at(get_cursor())]))
		TOGGLES:
			_turn(_rows_at_cursor())
		PICKS_EVERY_ROW_KEPT:
			_set_rows(_view.get_order(), 1)
		CLEARS:
			_set_all(0)
	return null


## The cursor to a place in the view; extending, every row from the anchor
## to it picked, else the anchor set there.
func _move(to: int, extending: bool) -> void:
	var cursor := clampi(to, 0, _view.get_count() - 1)
	_cursor.set_value(cursor)
	if not extending:
		_anchor = cursor
		return
	var anchor := mini(_anchor, _view.get_count() - 1)
	var run := PackedInt32Array()
	# every place from the anchor to the cursor, its row kept - a heading has none
	for place: int in range(mini(anchor, cursor), maxi(anchor, cursor) + 1):
		if _view.row_at(place) >= 0:
			run.append(_view.row_at(place))
	_set_rows(run, 1)


## The row at the cursor, or, on a group's heading, every row of the group.
func _rows_at_cursor() -> PackedInt32Array:
	var row := _view.row_at(get_cursor())
	if row >= 0:
		return PackedInt32Array([row])
	var group := _view.get_group_of(_view.group_at(get_cursor()))
	return _view.get_order().slice(group["first"], group["first"] + group["count"])


## These rows' picks turned: all picked, unless all already were.
func _turn(rows: PackedInt32Array) -> void:
	var all := true
	# every row, for one not picked
	for row: int in rows:
		all = all and is_picked(row)
	_set_rows(rows, 0 if all else 1)


## These rows set picked (1) or not (0), the count kept as they change.
func _set_rows(rows: PackedInt32Array, flag: int) -> void:
	var picked: PackedByteArray = _picked.read()
	var count: int = _count.read()
	# every row, counted only where its flag changes
	for row: int in rows:
		if picked[row] != flag:
			picked[row] = flag
			count += 1 if flag == 1 else -1
	_picked.set_value(picked)
	_count.set_value(count)


## Every row set picked or not at once, by the engine.
func _set_all(flag: int) -> void:
	var picked: PackedByteArray = _picked.read()
	picked.fill(flag)
	_picked.set_value(picked)
	_count.set_value(picked.size() * flag)


## Every action this model is told.
func answers() -> Array[StringName]:
	return COMMANDS
