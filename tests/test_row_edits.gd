extends SceneTree

## What must be true of edits to packed rows: a line is written as its
## column's kind, and one that is not that kind, or that the column's check
## refuses, is refused in words and writes nothing; many rows take one value
## at once; and the last change - one cell or many - is taken back whole.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_row_edits.gd

const Fixture := preload("res://tests/fixture.gd")
const PackedRows := preload("res://addons/gd_chime/packed_rows.gd")
const RowEdits := preload("res://addons/gd_chime/row_edits.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Verdict := preload("res://tests/verdict.gd")

const REGION := &"pipes"

var _verdict := Verdict.new()


func _init() -> void:
	await _verdict.states(_a_line_is_written_as_its_column_s_kind)
	await _verdict.states(_a_line_not_of_the_kind_or_refused_by_the_check_writes_nothing)
	await _verdict.states(_many_rows_take_one_value_and_the_last_change_is_taken_back_whole)
	quit(_verdict.deliver(get_script()))


## Four pipes, a check on the size, and the edits over them.
func _made(made: Fixture) -> RowEdits:
	var rows := PackedRows.new({&"size": PackedRows.NUMBER, &"laid": PackedRows.DATE, &"programme": PackedRows.WORDS})
	# four pipes, none in a programme yet
	for row: int in 4:
		rows.add([100.0 + row, PackedRows.day_of("1960"), "none"])
	var positive := func(size: float) -> Phrase: return Phrase.of("a pipe is wider than nothing") if size <= 0.0 else null
	var edits := RowEdits.new(made.chimes, rows, {&"size": positive})
	made.commands.stand(REGION, edits)
	root.add_child(edits)
	return edits


func _rows_of(edits: RowEdits) -> PackedRows:
	return edits._rows


func _a_line_is_written_as_its_column_s_kind() -> void:
	var made := Fixture.new(root)
	var edits := _made(made)
	var rows := _rows_of(edits)
	var said: Array = [made.commands.dispatch(REGION, RowEdits.WRITES, {"row": 1, "column": &"size", "line": " 150 "}), made.commands.dispatch(REGION, RowEdits.WRITES, {"row": 2, "column": &"laid", "line": "1971-07-01"}), made.commands.dispatch(REGION, RowEdits.WRITES, {"row": 3, "column": &"programme", "line": "R-2027"})]
	_verdict.check(said == [null, null, null], "three lines, each its column's kind, are written: %s" % [said])
	_verdict.check(rows.value_at(1, &"size") == 150.0 and PackedRows.date_of(rows.value_at(2, &"laid")) == "1971-07-01" and rows.value_at(3, &"programme") == "R-2027", "each read as its kind - a number, a day, a word: %s" % [[rows.value_at(1, &"size"), rows.value_at(2, &"laid"), rows.value_at(3, &"programme")]])
	_verdict.check(rows.value_at(0, &"size") == 100.0 and rows.value_at(3, &"size") == 103.0, "and no other row moves")
	made.done()


func _a_line_not_of_the_kind_or_refused_by_the_check_writes_nothing() -> void:
	var made := Fixture.new(root)
	var edits := _made(made)
	var rows := _rows_of(edits)
	var wide := made.commands.dispatch(REGION, RowEdits.WRITES, {"row": 0, "column": &"size", "line": "wide"})
	var soon := made.commands.dispatch(REGION, RowEdits.WRITES, {"row": 0, "column": &"laid", "line": "soon"})
	var empty := made.commands.dispatch(REGION, RowEdits.WRITES, {"row": 0, "column": &"programme", "line": "  "})
	var nothing := made.commands.dispatch(REGION, RowEdits.WRITES, {"row": 0, "column": &"size", "line": "0"})
	_verdict.check(str(wide) == "wide is not a number" and str(soon) == "soon is not a date written year-month-day" and str(empty) == "A word is needed here", "a line not of its column's kind is refused in words: %s / %s / %s" % [wide, soon, empty])
	_verdict.check(str(nothing) == "a pipe is wider than nothing", "a number the column's own check refuses is refused in its words: %s" % nothing)
	_verdict.check(rows.row_at(0) == {"id": 0, &"size": 100.0, &"laid": PackedRows.day_of("1960"), &"programme": "none"} and edits.get_undoable() == null, "nothing refused was written, and there is nothing to take back: %s" % [rows.row_at(0)])
	made.done()


func _many_rows_take_one_value_and_the_last_change_is_taken_back_whole() -> void:
	var made := Fixture.new(root)
	var edits := _made(made)
	var rows := _rows_of(edits)
	made.commands.dispatch(REGION, RowEdits.WRITES, {"row": 0, "column": &"programme", "line": "R-2026"})
	edits.write_many(PackedInt32Array([0, 2, 3]), &"programme", "R-2027", Phrase.of("three pipes assigned"))
	var assigned: Array = range(4).map(func(row: int) -> String: return rows.value_at(row, &"programme"))
	_verdict.check(assigned == ["R-2027", "none", "R-2027", "R-2027"] and str(edits.get_undoable()) == "three pipes assigned", "three rows take one value at once, and what would be taken back says so: %s" % [assigned])
	made.commands.dispatch(REGION, RowEdits.UNDOES, {})
	assigned = range(4).map(func(row: int) -> String: return rows.value_at(row, &"programme"))
	_verdict.check(assigned == ["R-2026", "none", "none", "none"], "taken back, every row holds what it held before - the one written first, its own: %s" % [assigned])
	var again := made.commands.dispatch(REGION, RowEdits.UNDOES, {})
	_verdict.check(str(again) == "Nothing has changed to take back" and rows.value_at(0, &"programme") == "R-2026", "a change taken back is gone: a second is refused: %s" % again)
	made.done()
