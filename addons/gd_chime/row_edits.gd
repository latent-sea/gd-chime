extends "controller.gd"

const Commands := preload("commands.gd")
const PackedRows := preload("packed_rows.gd")

## Edits to rows held column by column (packed_rows.gd): a typed line
## written as a value of its column's kind, many rows given one value at
## once, and the last change taken back.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A VALUE IS WRITTEN BY COMMAND: WRITES {row, column, line}, the line read
## as the column's kind - a number, a date written year-month-day or a year
## alone, a word - and refused, in words the reader is shown, when it is
## not one, or when the column's own CHECK refuses the value: a function
## from the value to a phrase, or null for none, handed in as this is built
## for the columns a rule of the application's governs. A row is written in
## place and nothing re-sorts (queried_rows.gd).
##
## MANY ROWS ARE WRITTEN BY A MODEL OF THE APPLICATION'S with write_many()
## - a bulk action, assigning three hundred rows at once - since what it
## writes is that model's rule, not a line typed. Either way the rows
## written - a value (value.gd) - are set once, and whatever follows them
## reads the rows again; get_written() says which rows they were, so a view
## can tell it is behind them (view_behind.gd).
##
## THE LAST CHANGE CAN BE TAKEN BACK: UNDOES puts back what the rows held
## before it - one cell or three hundred - and is refused with nothing to
## take back. get_undoable() says what would be taken back, for the control
## that does it; a change taken back is gone, and a new one replaces it.
##
## Deliberately absent: more than one change taken back, and doing again.

const WRITES := &"writes_a_value"
const UNDOES := &"undoes_the_last_change"
## Every action this is told.
const COMMANDS: Array[StringName] = [WRITES, UNDOES]

var _rows: PackedRows
var _checks: Dictionary  # column -> its check of a value about to be written
var _last := value({})  # the last change: {rows, column, before - each row's value before it, words}, or none
var _written := value(PackedInt32Array())  # the rows written in the frame of the last write or taking back
var _written_in: int = -1  # the frame those rows were written in


func _init(chimes: Chimes, rows: PackedRows, checks: Dictionary) -> void:
	super(chimes)
	_rows = rows
	_checks = checks


## What taking back the last change would take back, in words, or none.
func get_undoable() -> Phrase:
	var last: Dictionary = _last.read()
	return null if last.is_empty() else last["words"]


## The rows written, or given back what they held, in the frame of the last
## write: a follower hears once a frame, so every write in it is its to read.
func get_written() -> PackedInt32Array:
	return _written.read()


## These rows written: added to the frame's, or the first of a new frame's.
func _wrote(rows: PackedInt32Array) -> void:
	var now := Engine.get_process_frames()
	_written.set_value(_written.read() + rows if now == _written_in else rows)
	_written_in = now


## Many rows given one value, said in these words should it be taken back.
func write_many(rows: PackedInt32Array, column: StringName, value: Variant, words: Phrase) -> void:
	var before: Array = []
	# every row given, what it held kept, then the value written over it
	for row: int in rows:
		before.append(_rows.value_at(row, column))
		_rows.set_value(row, column, value)
	_last.set_value({"rows": rows, "column": column, "before": before, "words": words})
	_wrote(rows)


## Other rows in place of these: the last change forgotten, since the rows
## it would put back are gone, and none of them written.
func replace(rows: PackedRows) -> void:
	_rows = rows
	_last.set_value({})
	_written.set_value(PackedInt32Array())


## A line not of the column's kind, one the column's check refuses, or
## taking back with nothing changed, is refused.
func would(action: StringName, payload: Dictionary) -> Phrase:
	if action == UNDOES:
		return Phrase.of("Nothing has changed to take back") if _last.read().is_empty() else null
	var kind := _rows.kind_of(payload["column"])
	var line: String = String(payload["line"]).strip_edges()
	if kind == PackedRows.NUMBER and not line.is_valid_float():
		return Phrase.with("%s is not a number", [line])
	if kind == PackedRows.DATE and not PackedRows.is_date(line):
		return Phrase.with("%s is not a date written year-month-day", [line])
	if kind == PackedRows.WORDS and line == "":
		return Phrase.of("A word is needed here")
	return _checks[payload["column"]].call(read(kind, line)) if _checks.has(payload["column"]) else null


func told(action: StringName, payload: Dictionary) -> Phrase:
	if action == UNDOES:
		var last: Dictionary = _last.read()
		# every row of the last change, given back what it held
		for at: int in last["rows"].size():
			_rows.set_value(last["rows"][at], last["column"], last["before"][at])
		_wrote(last["rows"])
		_last.set_value({})
		return null
	var column: StringName = payload["column"]
	var value: Variant = read(_rows.kind_of(column), String(payload["line"]).strip_edges())
	write_many(PackedInt32Array([payload["row"]]), column, value, Phrase.with("The change to %s", [column]))
	return null


## A line as a value of a column's kind: a number, a day, or the word itself.
static func read(kind: StringName, line: String) -> Variant:
	if kind == PackedRows.NUMBER:
		return line.to_float()
	return PackedRows.day_of(line) if kind == PackedRows.DATE else line


## Every action this model is told.
func answers() -> Array[StringName]:
	return COMMANDS
