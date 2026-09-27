extends SceneTree

## What must be true of a view behind its rows: an edit that breaks the
## filter marks its row stale and the view behind; asking again takes the
## row away and clears both; an edit that breaks nothing marks no row but
## the view is behind until asked again; a row written out of its sorted
## place is stale, and written back is not; asking again is refused while
## nothing is behind; and a write while the query is out keeps the view
## behind once it lands.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_view_behind.gd

const Fixture := preload("res://tests/fixture.gd")
const FrameBudget := preload("res://addons/gd_chime/frame_budget.gd")
const Jobs := preload("res://addons/gd_chime/jobs.gd")
const PackedRows := preload("res://addons/gd_chime/packed_rows.gd")
const RowQuery := preload("res://addons/gd_chime/row_query.gd")
const QueriedRows := preload("res://addons/gd_chime/queried_rows.gd")
const RowEdits := preload("res://addons/gd_chime/row_edits.gd")
const ViewBehind := preload("res://addons/gd_chime/view_behind.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Verdict := preload("res://tests/verdict.gd")

const REGION := &"pipes"
## The filter every view here is asked: risk over 50.
const OVER_50 := [{"column": &"risk", "test": RowQuery.OVER, "value": 50.0}]

var _verdict := Verdict.new()


func _init() -> void:
	await _verdict.states(_an_edit_that_breaks_the_filter_marks_its_row_and_asking_again_clears_it)
	await _verdict.states(_an_edit_that_breaks_nothing_marks_no_row_but_the_view_is_behind)
	await _verdict.states(_a_row_written_out_of_its_sorted_place_is_stale_until_written_back)
	await _verdict.states(_a_write_while_the_query_is_out_keeps_the_view_behind)
	await _verdict.states(_a_row_written_into_another_group_and_many_rows_written_at_once_are_judged)
	quit(_verdict.deliver(get_script()))


## Two hundred pipes, a view of them, their edits, and whether the view is behind them.
func _made(made: Fixture) -> ViewBehind:
	var rows := PackedRows.new({&"risk": PackedRows.NUMBER, &"town": PackedRows.WORDS})
	# every pipe, its risk spread and one of three towns
	for row: int in 200:
		rows.add([float((row * 37) % 100), ["ashby", "cole", "dale"][row % 3]])
	var budget := FrameBudget.new(made.chimes, 16.0, 0.9, 3)
	var pool := Jobs.new(made.chimes, budget, 1, 4, true)
	var view := QueriedRows.new(made.chimes, rows, pool)
	made.commands.stand(REGION, view)
	var edits := RowEdits.new(made.chimes, rows, {})
	made.commands.stand(REGION, edits)
	var behind := ViewBehind.new(made.chimes, view, edits)
	made.commands.stand(REGION, behind)
	for node: Node in [budget, pool, view, edits, behind]:
		root.add_child(node)
	return behind


func _do(made: Fixture, action: StringName, payload: Dictionary = {}) -> Phrase:
	return made.commands.dispatch(REGION, action, payload)


## Frames until the view has landed, and one more for what follows it to hear.
func _landed(behind: ViewBehind) -> void:
	# a frame at a time until no query is out
	while behind._view.get_busy():
		await process_frame
	await process_frame


## A row's risk written as a reader types it into its cell, and a frame for what follows the writes to hear.
func _write(made: Fixture, row: int, risk: float) -> void:
	_do(made, RowEdits.WRITES, {"row": row, "column": &"risk", "line": str(risk)})
	await process_frame


func _an_edit_that_breaks_the_filter_marks_its_row_and_asking_again_clears_it() -> void:
	var made := Fixture.new(root)
	var behind := _made(made)
	var view: QueriedRows = behind._view
	view.ask(OVER_50)
	await _landed(behind)
	var refused := _do(made, ViewBehind.REAPPLIES)
	var row: int = view.get_order()[3]
	await _write(made, row, 10.0)
	_verdict.check(str(refused) == "The view is up to date" and behind.get_behind() and behind.get_stale().keys() == [row] and view.get_order().has(row), "asking again is refused while up to date (%s); a kept row written under the filter is marked, the view behind, and the row still shown" % refused)
	_do(made, ViewBehind.REAPPLIES)
	await _landed(behind)
	_verdict.check(not view.get_order().has(row) and view.get_kept() == 97 and not behind.get_behind() and behind.get_stale().is_empty(), "asked again, the row is gone, and neither the view nor the row is marked: %d kept, stale %s" % [view.get_kept(), behind.get_stale()])
	made.done()


func _an_edit_that_breaks_nothing_marks_no_row_but_the_view_is_behind() -> void:
	var made := Fixture.new(root)
	var behind := _made(made)
	var view: QueriedRows = behind._view
	view.ask(OVER_50)
	await _landed(behind)
	var row: int = view.get_order()[3]
	await _write(made, row, 75.0)
	_verdict.check(behind.get_behind() and behind.get_stale().is_empty(), "a kept row written still over 50 marks no row, and the view is behind all the same: stale %s" % [behind.get_stale()])
	_do(made, ViewBehind.REAPPLIES)
	await _landed(behind)
	_verdict.check(not behind.get_behind() and view.get_order().has(row), "asked again, the view is up to date, the row still kept")
	made.done()


func _a_row_written_out_of_its_sorted_place_is_stale_until_written_back() -> void:
	var made := Fixture.new(root)
	var behind := _made(made)
	var view: QueriedRows = behind._view
	view.ask(OVER_50)
	_do(made, QueriedRows.SORTS, {"column": &"risk"})
	await _landed(behind)
	var first: int = view.get_order()[0]
	var was: float = view.get_rows().value_at(first, &"risk")
	await _write(made, first, 99.0)
	var moved: bool = behind.get_stale().has(first)
	_do(made, RowEdits.UNDOES)
	await process_frame
	_verdict.check(moved and behind.get_stale().is_empty() and behind.get_behind() and view.get_rows().value_at(first, &"risk") == was, "the least risk written to 99 sits out of its sorted place, stale; taken back, it is not, and the view stays behind until asked again")
	made.done()


func _a_write_while_the_query_is_out_keeps_the_view_behind() -> void:
	var made := Fixture.new(root)
	var behind := _made(made)
	var view: QueriedRows = behind._view
	view.ask(OVER_50)
	await _landed(behind)
	var row: int = view.get_order()[0]
	await _write(made, row, 10.0)
	_do(made, ViewBehind.REAPPLIES)
	var other: int = view.get_order()[1]
	# written at once, while the query is out
	_do(made, RowEdits.WRITES, {"row": other, "column": &"risk", "line": "20.0"})
	await _landed(behind)
	_verdict.check(not view.get_order().has(row) and view.get_order().has(other) and behind.get_behind() and behind.get_stale().keys() == [other], "the answer asked before a write lets go the row written before it and keeps the one written after it, stale, the view behind: stale %s" % [behind.get_stale()])
	made.done()


func _a_row_written_into_another_group_and_many_rows_written_at_once_are_judged() -> void:
	var made := Fixture.new(root)
	var behind := _made(made)
	var view: QueriedRows = behind._view
	var rows := view.get_rows()
	view.ask(OVER_50)
	_do(made, QueriedRows.GROUPS_BY, {"value": &"town"})
	await _landed(behind)
	var ashby: int = view.get_order()[1]
	var within: int = view.get_order()[2]
	# both written in one frame: what follows the writes hears them together
	_do(made, RowEdits.WRITES, {"row": ashby, "column": &"town", "line": "dale"})
	_do(made, RowEdits.WRITES, {"row": within, "column": &"risk", "line": "60"})
	await process_frame
	_verdict.check(behind.get_stale().keys() == [ashby], "grouped by town, a row written into another town is stale, and one written within its group, unsorted, is not: stale %s" % [behind.get_stale()])
	var every: PackedInt32Array = view.get_order()
	behind._edits.write_many(every, &"risk", 10.0, Phrase.of("every risk"))
	await process_frame
	_verdict.check(behind.get_stale().size() == every.size() and every.size() == 98, "every row shown written under the filter at once, every one is stale: %d of %d" % [behind.get_stale().size(), every.size()])
	_do(made, RowEdits.UNDOES)
	await process_frame
	_verdict.check(behind.get_stale().keys() == [ashby] and rows.value_at(within, &"risk") == 60.0, "taken back, only the row in another town is stale again: %s" % [behind.get_stale()])
	made.done()
