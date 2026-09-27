extends SceneTree

## What must be true of the pace a filter's query goes at, and of what the
## query reads: ten characters typed quickly send one query, of the line as
## it stood at the last, once the wait has passed on the one clock
## (motion.gd) - stepped here by hand, never by real time; Enter sends at
## once, and nothing waits after it; a
## query with nothing written since the last copies nothing and reads the
## last snapshot again; a write while a query is out never reaches what
## that query reads.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_query_pacing.gd

const Themes := preload("res://addons/gd_chime/theme.gd")
const Fixture := preload("res://tests/fixture.gd")
const FrameBudget := preload("res://addons/gd_chime/frame_budget.gd")
const Jobs := preload("res://addons/gd_chime/jobs.gd")
const PackedRows := preload("res://addons/gd_chime/packed_rows.gd")
const QueriedRows := preload("res://addons/gd_chime/queried_rows.gd")
const RowFilters := preload("res://addons/gd_chime/row_filters.gd")
const QueryPacing := preload("res://addons/gd_chime/query_pacing.gd")
const FilterSet := preload("res://addons/gd_chime/components/recipes/filter_set.gd")
const Verdict := preload("res://tests/verdict.gd")

const REGION := &"pipes"
## A date typed a character at a time: ten characters, the first of them already a whole year.
const TYPED := "1970-01-01"
## The most frames a query is given to land: a job runs one a frame, so a handful is plenty.
const PATIENCE := 120

var _verdict := Verdict.new()


func _init() -> void:
	# the look on the window, so the wait the typing rests for is the look's
	root.theme = Themes.new(Themes.NEUTRAL)
	await _verdict.states(_ten_characters_typed_quickly_send_one_query)
	await _verdict.states(_enter_sends_at_once_and_nothing_waits_after_it)
	await _verdict.states(_a_query_with_nothing_written_since_copies_nothing)
	await _verdict.states(_a_write_while_a_query_is_out_never_reaches_it)
	quit(_verdict.deliver(get_script()))


## Two hundred pipes, a view, and filters by risk and the day laid; the pool
## runs its jobs on the main thread, one a frame, so a job is out for a frame.
func _made(made: Fixture) -> RowFilters:
	var rows := PackedRows.new({&"risk": PackedRows.NUMBER, &"laid": PackedRows.DATE})
	# every pipe, its risk and year spread
	for row: int in 200:
		rows.add([float((row * 37) % 100), PackedRows.day_of(str(1900 + (row * 7) % 120))])
	var budget := FrameBudget.new(made.chimes, 16.0, 0.9, 3)
	var pool := Jobs.new(made.chimes, budget, 1, 4, true)
	var view := QueriedRows.new(made.chimes, rows, pool)
	made.commands.stand(REGION, view)
	var properties := [{"name": &"risk", "type": FilterSet.A_NUMBER}, {"name": &"laid", "type": FilterSet.A_DATE}]
	var filters := RowFilters.new(made.chimes, view, properties, made.ui.motion)
	made.commands.stand(REGION, filters)
	for node: Node in [budget, pool, view, filters]:
		root.add_child(node)
	return filters


func _do(made: Fixture, action: StringName, payload: Dictionary = {}) -> void:
	made.commands.dispatch(REGION, action, payload)


## Frames until the view has landed and nothing waits to go - or patience
## runs out, so a wait never stepped fails the checks after it rather than
## holding the run for ever.
func _landed(filters: RowFilters) -> void:
	var frames := 0
	# a frame at a time until nothing is out or waiting, or patience runs out
	while (filters._view.get_busy() or filters.get_pacing().get_waiting()) and frames < PATIENCE:
		await process_frame
		frames += 1


## Frames for at least this long.
func _frames_for(ms: int) -> void:
	var until := Time.get_ticks_msec() + ms
	# a frame at a time until the time has passed
	while Time.get_ticks_msec() < until:
		await process_frame


## The rows the view must keep for "laid is before" this date, by a pass over every row.
func _before(filters: RowFilters, date: String) -> Array:
	var rows := filters._view.get_rows()
	return range(rows.count()).filter(func(row: int) -> bool: return rows.value_at(row, &"laid") < PackedRows.day_of(date))


func _ten_characters_typed_quickly_send_one_query() -> void:
	var made := Fixture.new(root)
	var filters := _made(made)
	var pacing := filters.get_pacing()
	var motion := made.ui.motion
	motion.by_hand = true
	var settles := motion.get_token(QueryPacing.SETTLES) / 1000.0
	_do(made, RowFilters.PICKS_PROPERTY, {"value": &"laid"})
	_do(made, RowFilters.PICKS_COMPARISON, {"comparison": "is before"})
	var sent := pacing.get_sent()
	# every character, typed a fifth of the wait after the last, the line as it stands told
	for typed: int in TYPED.length():
		_do(made, RowFilters.TYPES_LINE, {"line": TYPED.left(typed + 1)})
		motion.step(settles / 5.0)
	var while_typing := pacing.get_sent() - sent
	var waited := pacing.get_waiting()
	await _frames_for(roundi(settles * 2000.0))
	var by_frames := pacing.get_sent() - sent
	motion.step(settles * 0.7)
	var short_of_it := pacing.get_sent() - sent
	motion.step(settles * 0.2)
	await _landed(filters)
	var kept := Array(filters._view.get_order())
	_verdict.check(settles > 0.0 and while_typing == 0 and waited, "while ten characters are typed a fifth of the wait apart on the clock - twice the wait in all - no query goes, and one waits: %d sent" % while_typing)
	_verdict.check(by_frames == 0 and short_of_it == 0, "the wait is the clock's alone: twice the wait of real frames sends nothing, nor the clock short of the wait since the last key: %d, %d sent" % [by_frames, short_of_it])
	_verdict.check(pacing.get_sent() - sent == 1 and kept == _before(filters, TYPED), "the clock stepped past the wait since the last key, one query goes, of the line as it stood at the last: %d sent, %d rows kept" % [pacing.get_sent() - sent, kept.size()])
	made.done()


func _enter_sends_at_once_and_nothing_waits_after_it() -> void:
	var made := Fixture.new(root)
	var filters := _made(made)
	var pacing := filters.get_pacing()
	var motion := made.ui.motion
	motion.by_hand = true
	_do(made, RowFilters.PICKS_PROPERTY, {"value": &"laid"})
	_do(made, RowFilters.PICKS_COMPARISON, {"comparison": "is before"})
	_do(made, RowFilters.TYPES_LINE, {"line": "1950"})
	var sent := pacing.get_sent()
	_do(made, RowFilters.SETS_VALUE, {"line": "1950"})
	var at_once := pacing.get_sent() - sent
	_verdict.check(at_once == 1 and not pacing.get_waiting() and filters._view.get_busy(), "Enter sends the query in the same call, and nothing is left waiting: %d sent" % at_once)
	motion.step(motion.get_token(QueryPacing.SETTLES) / 1000.0 * 2.0)
	await _landed(filters)
	_verdict.check(pacing.get_sent() - sent == 1 and Array(filters._view.get_order()) == _before(filters, "1950"), "no second query follows once the wait would have run out, and the view keeps what the chip keeps: %d sent" % [pacing.get_sent() - sent])
	made.done()


func _a_query_with_nothing_written_since_copies_nothing() -> void:
	var made := Fixture.new(root)
	var filters := _made(made)
	var rows := filters._view.get_rows()
	_do(made, RowFilters.PICKS_PROPERTY, {"value": &"risk"})
	_do(made, RowFilters.PICKS_COMPARISON, {"comparison": "is over"})
	_do(made, RowFilters.SETS_VALUE, {"line": "50"})
	await _landed(filters)
	var first: PackedRows = rows.snapshot()
	var copied := rows.get_copied()
	_do(made, RowFilters.TOGGLES, {"id": filters.get_chips()[0]["id"]})
	await _landed(filters)
	_do(made, RowFilters.TOGGLES, {"id": filters.get_chips()[0]["id"]})
	await _landed(filters)
	_verdict.check(rows.snapshot() == first and rows.get_copied() == copied, "two more queries with nothing written read the same snapshot, and nothing is copied: %d arrays copied" % [rows.get_copied() - copied])
	made.done()


func _a_write_while_a_query_is_out_never_reaches_it() -> void:
	var made := Fixture.new(root)
	var filters := _made(made)
	var view: QueriedRows = filters._view
	var rows := view.get_rows()
	var version := rows.get_version()
	var over := func() -> Array: return range(rows.count()).filter(func(row: int) -> bool: return rows.value_at(row, &"risk") > 50.0)
	var asked: Array = over.call()
	var outside: int = range(rows.count()).filter(func(row: int) -> bool: return not asked.has(row))[0]
	_do(made, RowFilters.PICKS_PROPERTY, {"value": &"risk"})
	_do(made, RowFilters.PICKS_COMPARISON, {"comparison": "is over"})
	_do(made, RowFilters.SETS_VALUE, {"line": "50"})
	# the query is out: a row it keeps written out of it, and one it leaves written into it
	rows.set_value(asked[0], &"risk", 1.0)
	rows.set_value(outside, &"risk", 99.0)
	await _landed(filters)
	var kept := Array(view.get_order())
	_verdict.check(kept == asked and view.get_shown()["version"] == version, "the query reads the rows as they stood when it was asked: the %d rows over 50 then, the two written after left as they were: %s" % [asked.size(), kept.size()])
	_verdict.check(rows.value_at(asked[0], &"risk") == 1.0 and over.call().has(outside), "and the rows hold both writes: %s, %s" % [rows.value_at(asked[0], &"risk"), rows.value_at(outside, &"risk")])
	made.done()
