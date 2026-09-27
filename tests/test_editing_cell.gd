extends SceneTree

## What must be true of the cell being edited: the cursor's cell opens
## where its column edits and is refused in words where it does not; a
## value written ends the edit and a line refused leaves it open; the
## cursor moving ends it; and on a group's heading, opening turns the group.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_editing_cell.gd

const Fixture := preload("res://tests/fixture.gd")
const FrameBudget := preload("res://addons/gd_chime/frame_budget.gd")
const Jobs := preload("res://addons/gd_chime/jobs.gd")
const PackedRows := preload("res://addons/gd_chime/packed_rows.gd")
const QueriedRows := preload("res://addons/gd_chime/queried_rows.gd")
const RowSelection := preload("res://addons/gd_chime/row_selection.gd")
const RowEdits := preload("res://addons/gd_chime/row_edits.gd")
const TableColumns := preload("res://addons/gd_chime/table_columns.gd")
const EditingCell := preload("res://addons/gd_chime/editing_cell.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Verdict := preload("res://tests/verdict.gd")

const REGION := &"pipes"

var _verdict := Verdict.new()


func _init() -> void:
	await _verdict.states(_a_cell_opens_where_its_column_edits_and_a_write_ends_it)
	await _verdict.states(_the_cursor_moving_ends_it_and_a_heading_turns_its_group)
	await _verdict.states(_the_keys_resize_the_column_the_cursor_is_across)
	quit(_verdict.deliver(get_script()))


## Six pipes, the view, picks, columns - the size edits, the material does not - edits, and the editing.
func _made(made: Fixture) -> EditingCell:
	var rows := PackedRows.new({&"size": PackedRows.NUMBER, &"material": PackedRows.WORDS})
	# six pipes, two materials in turn
	for row: int in 6:
		rows.add([100.0 + row, ["iron", "steel"][row % 2]])
	var budget := FrameBudget.new(made.chimes, 16.0, 0.9, 3)
	var pool := Jobs.new(made.chimes, budget, 1, 4, true)
	var view := QueriedRows.new(made.chimes, rows, pool)
	made.commands.stand(REGION, view)
	var columns := TableColumns.new(made.chimes, [{"name": &"size", "words": Phrase.of("size"), "share": 0.4, "edits": true}, {"name": &"material", "words": Phrase.of("material"), "share": 0.3}, {"name": &"note", "words": Phrase.of("note"), "share": 0.3}], 0.05)
	made.commands.stand(REGION, columns)
	var picks := RowSelection.new(made.chimes, view, func() -> int: return 3)
	made.commands.stand(REGION, picks)
	var edits := RowEdits.new(made.chimes, rows, {})
	made.commands.stand(REGION, edits)
	var editing := EditingCell.new(made.chimes, view, picks, columns, edits)
	made.commands.stand(REGION, editing)
	for node: Node in [budget, pool, view, columns, picks, edits, editing]:
		root.add_child(node)
	return editing


func _do(made: Fixture, action: StringName, payload: Dictionary = {}) -> Phrase:
	return made.commands.dispatch(REGION, action, payload)


func _a_cell_opens_where_its_column_edits_and_a_write_ends_it() -> void:
	var made := Fixture.new(root)
	var editing := _made(made)
	_do(made, RowSelection.MOVES, {"to": 2})
	_do(made, RowSelection.MOVES_ACROSS, {"by": 1})
	var refused := _do(made, EditingCell.EDITS)
	_verdict.check(str(refused) == "material is not changed here" and editing.get_editing().is_empty(), "across on the material, which does not edit, opening is refused in words: %s" % refused)
	_do(made, RowSelection.MOVES_ACROSS, {"by": -1})
	_do(made, EditingCell.EDITS)
	_verdict.check(editing.get_editing() == {"row": 2, "column": &"size"}, "on the size, the cursor's cell opens: %s" % [editing.get_editing()])
	var wrong := _do(made, RowEdits.WRITES, {"row": 2, "column": &"size", "line": "wide"})
	_verdict.check(wrong != null and not editing.get_editing().is_empty(), "a line refused leaves the cell open to be corrected: %s" % wrong)
	_do(made, RowEdits.WRITES, {"row": 2, "column": &"size", "line": "180"})
	await process_frame
	_verdict.check(editing.get_editing().is_empty() and str(_do(made, EditingCell.ENDS)) == "Nothing is being changed", "a value written ends the edit, and nothing is left to give up")
	made.done()


func _the_cursor_moving_ends_it_and_a_heading_turns_its_group() -> void:
	var made := Fixture.new(root)
	var editing := _made(made)
	_do(made, EditingCell.EDITS)
	var opened := not editing.get_editing().is_empty()
	_do(made, RowSelection.MOVES, {"by": 1})
	await process_frame
	_verdict.check(opened and editing.get_editing().is_empty(), "the cursor moving on ends the edit: an edit belongs to its cell")
	var view: QueriedRows = editing._view
	_do(made, QueriedRows.GROUPS_BY, {"value": &"material"})
	# frames until the grouped view lands
	while view.get_busy():
		await process_frame
	_do(made, RowSelection.MOVES, {"to": 0})
	_do(made, EditingCell.EDITS)
	_verdict.check(view.get_count() == 5 and editing.get_editing().is_empty(), "on iron's heading, opening shuts iron instead, and nothing is edited: %d places" % view.get_count())
	made.done()


func _the_keys_resize_the_column_the_cursor_is_across() -> void:
	var made := Fixture.new(root)
	var editing := _made(made)
	var columns: TableColumns = editing._columns
	_do(made, RowSelection.MOVES_ACROSS, {"by": 1})
	_do(made, EditingCell.RESIZES_THIS_COLUMN, {"by": 0.1})
	var shares: Array = columns.get_shown().map(func(column: Dictionary) -> float: return snappedf(column["share"], 0.001))
	_do(made, RowSelection.MOVES_ACROSS, {"by": 1})
	var last := _do(made, EditingCell.RESIZES_THIS_COLUMN, {"by": 0.1})
	_verdict.check(shares == [0.4, 0.4, 0.2] and str(last) == "The last column has no edge to move", "across the material, the material widens and the note gives; across the last, refused as the columns refuse it: %s, %s" % [shares, last])
	made.done()
