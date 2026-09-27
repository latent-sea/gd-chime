extends "controller.gd"

const Commands := preload("commands.gd")
const QueriedRows := preload("queried_rows.gd")
const RowSelection := preload("row_selection.gd")
const RowEdits := preload("row_edits.gd")
const TableColumns := preload("table_columns.gd")
const Reads := preload("reads.gd")

## The cell being edited: the one the cursor is on (row_selection.gd),
## opened for a line to be typed into, until the line is written or given
## up - so a table is edited where it is read, one cell at a time.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## EDITS opens the cursor's cell - the row at the cursor, in the column
## across - when that column edits (table_columns.gd); a column that does
## not, or no row, is refused in words. On a group's heading it opens or
## shuts the group instead, which is what pressing into a heading means.
## ENDS gives the edit up. The line typed is written by the edits
## (row_edits.gd, WRITES), not here, and a value written ends the edit;
## a line refused leaves the cell open, so the reader corrects it where
## they typed it. The cursor moving ends it too: an edit belongs to the
## cell, never to the slot a list re-points.
##
## get_editing() is {row, column}, or empty while nothing is being edited:
## what a cell asks to know whether to show its field or its words.
##
## RESIZES_THIS_COLUMN {by} moves the edge of the column the cursor is across, as
## the columns' own RESIZES would and refused as it would be - the keys'
## way to widen and narrow a column, beside the grip a pointer drags.
##
## Deliberately absent: more than one cell open at once.

const EDITS := &"edits_the_cell"
const ENDS := &"ends_the_edit"
const RESIZES_THIS_COLUMN := &"resizes_this_column"
## Every action this is told.
const COMMANDS: Array[StringName] = [EDITS, ENDS, RESIZES_THIS_COLUMN]

var _view: QueriedRows
var _picks: RowSelection
var _columns: TableColumns
var _edits: RowEdits
var _editing := value({})  # {row, column} of the cell open, or empty
var _cursor: int = -1  # the cursor's place as last followed
var _begun: bool = false  # whether both are followed: the first reads are only reads


func _init(chimes: Chimes, view: QueriedRows, picks: RowSelection, columns: TableColumns, edits: RowEdits) -> void:
	super(chimes)
	_view = view
	_picks = picks
	_columns = columns
	_edits = edits
	follow(&"cursor", _cursor_moved)
	follow(&"written", _written)
	_begun = true


func get_editing() -> Dictionary:
	return _editing.read()


## The cursor's place read, so it is followed: moved, the edit is over.
func _cursor_moved() -> void:
	var cursor := _picks.get_cursor()
	if cursor != _cursor:
		_cursor = cursor
		_end()


## The rows written read, so they are followed: a value written, the edit is over.
func _written() -> void:
	_edits.get_written()
	_end()


## Once both are followed, the edit ended, if one is open - apart from
## what is followed, so the edit this closes is not among it (reads.gd).
func _end() -> void:
	if _begun:
		Reads.apart(func() -> void:
			if not _editing.read().is_empty():
				_editing.set_value({}))


## Opening with no rows, or in a column that does not edit, and giving up
## with nothing open, are refused.
func would(action: StringName, payload: Dictionary) -> Phrase:
	if action == ENDS:
		return Phrase.of("Nothing is being changed") if _editing.read().is_empty() else null
	if action == RESIZES_THIS_COLUMN:
		return _columns.would(TableColumns.RESIZES, {"column": _column()["name"], "by": payload["by"]})
	if _view.get_count() == 0:
		return Phrase.of("No rows are shown")
	if _view.row_at(_picks.get_cursor()) >= 0 and not _column()["edits"]:
		return Phrase.with("%s is not changed here", [_column()["words"]])
	return null


func told(action: StringName, payload: Dictionary) -> Phrase:
	if action == RESIZES_THIS_COLUMN:
		_columns.resize(_column()["name"], payload["by"])
		return null
	var row := _view.row_at(_picks.get_cursor())
	if action == ENDS:
		_editing.set_value({})
	elif row < 0:
		_view.turn_group(_view.get_group_of(_view.group_at(_picks.get_cursor()))["code"])
	else:
		# the cursor taken as it is now, so its move this frame - the press that put it here - ends nothing
		_cursor = _picks.get_cursor()
		_editing.set_value({"row": row, "column": _column()["name"]})
	return null


## The column the cursor is across, held to those shown.
func _column() -> Dictionary:
	var shown := _columns.get_shown()
	return shown[mini(_picks.get_across(), shown.size() - 1)]


## Every action this model is told.
func answers() -> Array[StringName]:
	return COMMANDS
