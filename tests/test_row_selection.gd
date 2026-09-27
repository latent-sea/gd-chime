extends SceneTree

## What must be true of picked rows and the cursor: the cursor moves within
## the view and refuses to pass its ends; a pick is of a row, so it
## survives a sort; a run is picked from the anchor; a press picks one, adds
## one or runs to one; a heading turns its whole group; every kept row is
## picked at once; and what is acted on is the picks, else the cursor's row.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_row_selection.gd

const Fixture := preload("res://tests/fixture.gd")
const FrameBudget := preload("res://addons/gd_chime/frame_budget.gd")
const Jobs := preload("res://addons/gd_chime/jobs.gd")
const PackedRows := preload("res://addons/gd_chime/packed_rows.gd")
const RowQuery := preload("res://addons/gd_chime/row_query.gd")
const QueriedRows := preload("res://addons/gd_chime/queried_rows.gd")
const RowSelection := preload("res://addons/gd_chime/row_selection.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Verdict := preload("res://tests/verdict.gd")

const REGION := &"pipes"
const MATERIALS := ["cast iron", "PVC", "steel"]

var _verdict := Verdict.new()


func _init() -> void:
	await _verdict.states(_the_cursor_moves_within_the_view)
	await _verdict.states(_a_pick_is_of_a_row_and_survives_a_sort)
	await _verdict.states(_a_press_picks_one_adds_one_or_runs_to_one)
	await _verdict.states(_a_heading_turns_its_group_and_every_kept_row_is_picked_at_once)
	await _verdict.states(_what_is_acted_on_is_the_picks_else_the_cursor_s_row)
	quit(_verdict.deliver(get_script()))


## Nine pipes over a view, and the picks over it, all in the tree.
func _made(made: Fixture, count: int = 9) -> RowSelection:
	var rows := PackedRows.new({&"risk": PackedRows.NUMBER, &"material": PackedRows.WORDS})
	# every pipe, a risk falling as the rows go on, and a material in turn
	for row: int in count:
		rows.add([float(count - row), MATERIALS[row % MATERIALS.size()]])
	var budget := FrameBudget.new(made.chimes, 16.0, 0.9, 3)
	var pool := Jobs.new(made.chimes, budget, 1, 4, true)
	var view := QueriedRows.new(made.chimes, rows, pool)
	made.commands.stand(REGION, view)
	var picks := RowSelection.new(made.chimes, view, func() -> int: return 4)
	made.commands.stand(REGION, picks)
	for node: Node in [budget, pool, view, picks]:
		root.add_child(node)
	return picks


func _view_of(picks: RowSelection) -> QueriedRows:
	return picks._view


func _do(made: Fixture, action: StringName, payload: Dictionary = {}) -> Phrase:
	return made.commands.dispatch(REGION, action, payload)


## Frames until the view has landed.
func _landed(view: QueriedRows) -> void:
	# a frame at a time until nothing is out
	while view.get_busy():
		await process_frame


func _the_cursor_moves_within_the_view() -> void:
	var made := Fixture.new(root)
	var picks := _made(made)
	var up := _do(made, RowSelection.MOVES, {"by": -1})
	_do(made, RowSelection.MOVES, {"by": 3})
	var three := picks.get_cursor()
	_do(made, RowSelection.MOVES, {"to": -1})
	var down := _do(made, RowSelection.MOVES, {"by": 1})
	_verdict.check(str(up) == "Already at the first row" and three == 3 and picks.get_cursor() == 8 and str(down) == "Already at the last row", "the cursor moves by and to, -1 is the last, and it refuses to pass either end: %s, %d, %d, %s" % [up, three, picks.get_cursor(), down])
	_do(made, RowSelection.MOVES_ACROSS, {"by": 10})
	var right := picks.get_across()
	_do(made, RowSelection.MOVES_ACROSS, {"by": -10})
	_verdict.check(right == 3 and picks.get_across() == 0, "across is held within the columns shown: %d, %d" % [right, picks.get_across()])
	_view_of(picks).ask([{"column": &"material", "test": RowQuery.IS, "value": ["PVC"]}])
	await _landed(_view_of(picks))
	_verdict.check(picks.get_cursor() == 2, "the view shrinking to three rows, the cursor is held within it: %d" % picks.get_cursor())
	made.done()


func _a_pick_is_of_a_row_and_survives_a_sort() -> void:
	var made := Fixture.new(root)
	var picks := _made(made)
	_do(made, RowSelection.MOVES, {"to": 1})
	_do(made, RowSelection.EXTENDS, {"by": 2})
	_verdict.check(picks.get_count() == 3 and picks.is_picked(1) and picks.is_picked(3) and not picks.is_picked(0) and not picks.is_picked(4), "extending from the second row by two picks the three rows from the anchor: %d" % picks.get_count())
	made.commands.dispatch(REGION, QueriedRows.SORTS, {"column": &"risk"})
	await _landed(_view_of(picks))
	_verdict.check(_view_of(picks).row_at(0) == 8 and picks.is_picked(1) and picks.is_picked(3) and picks.get_count() == 3, "sorted, the rows move and the same three are picked")
	made.done()


func _a_press_picks_one_adds_one_or_runs_to_one() -> void:
	var made := Fixture.new(root)
	var picks := _made(made)
	_do(made, RowSelection.PICKS, {"at": 2, "across": 1})
	_do(made, RowSelection.PICKS, {"at": 5, "adds": true})
	var added := [picks.get_count(), picks.is_picked(2), picks.is_picked(5), picks.get_across()]
	_do(made, RowSelection.PICKS, {"at": 7, "extends": true})
	var ran := picks.get_count()
	_do(made, RowSelection.PICKS, {"at": 4})
	_verdict.check(added == [2, true, true, 1] and ran == 4 and picks.get_count() == 1 and picks.is_picked(4) and picks.get_cursor() == 4, "a press picks one and puts the column where pressed, one with adds adds it, one with extends runs from the last pressed, a plain one picks it alone: %s, %d, %d" % [added, ran, picks.get_count()])
	_do(made, RowSelection.PICKS, {"at": 4, "adds": true})
	var none := picks.get_count()
	var cleared := _do(made, RowSelection.CLEARS)
	_verdict.check(none == 0 and str(cleared) == "Nothing is picked", "a pick added again is taken away, and with nothing picked clearing is refused: %s" % cleared)
	made.done()


func _a_heading_turns_its_group_and_every_kept_row_is_picked_at_once() -> void:
	var made := Fixture.new(root)
	var picks := _made(made)
	made.commands.dispatch(REGION, QueriedRows.GROUPS_BY, {"value": &"material"})
	await _landed(_view_of(picks))
	_do(made, RowSelection.MOVES, {"to": 4})
	_do(made, RowSelection.TOGGLES)
	var group := [picks.get_count(), picks.is_picked(1), picks.is_picked(4), picks.is_picked(7)]
	_do(made, RowSelection.TOGGLES)
	_verdict.check(group == [3, true, true, true] and picks.get_count() == 0, "on PVC's heading, the whole group is picked, and turned again, none of it: %s" % [group])
	_do(made, RowSelection.PICKS, {"at": 4})
	_verdict.check(picks.get_count() == 0 and picks.get_cursor() == 4, "a heading pressed puts the cursor on it and picks nothing")
	_view_of(picks).ask([{"column": &"risk", "test": RowQuery.OVER, "value": 3.0}])
	await _landed(_view_of(picks))
	_do(made, RowSelection.PICKS_EVERY_ROW_KEPT)
	_verdict.check(picks.get_count() == 6 and not picks.is_picked(7), "every row the view keeps is picked at once, and none it filters out: %d" % picks.get_count())
	made.done()


func _what_is_acted_on_is_the_picks_else_the_cursor_s_row() -> void:
	var made := Fixture.new(root)
	var picks := _made(made, 100000)
	_do(made, RowSelection.MOVES, {"to": 5})
	var one := picks.get_acted_on()
	var began := Time.get_ticks_usec()
	_do(made, RowSelection.PICKS_EVERY_ROW_KEPT)
	var all_ms := (Time.get_ticks_usec() - began) / 1000.0
	_do(made, RowSelection.CLEARS)
	_do(made, RowSelection.PICKS, {"at": 10})
	_do(made, RowSelection.PICKS, {"at": 99990, "adds": true})
	_do(made, RowSelection.PICKS, {"at": 50000, "adds": true})
	_verdict.check(one == PackedInt32Array([5]) and picks.get_acted_on() == PackedInt32Array([10, 50000, 99990]), "with none picked, the cursor's row; with three picked, those three by row: %s (every one of 100,000 picked in %.1f ms)" % [picks.get_acted_on(), all_ms])
	made.done()
