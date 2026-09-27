extends SceneTree

## What must be true of a dashboard's measures: nothing has landed until
## the first rollup does, then every figure is the rollup's; what they are
## taken over moving leaves the last figures shown while the next is worked out, and
## a move while one is out is asked once it lands, the stale answer never
## shown; a figure's clauses keep the rows it counted; and fifty thousand
## rows are rolled up with the frame kept.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_measures.gd

const Fixture := preload("res://tests/fixture.gd")
const FrameBudget := preload("res://addons/gd_chime/frame_budget.gd")
const Jobs := preload("res://addons/gd_chime/jobs.gd")
const PackedRows := preload("res://addons/gd_chime/packed_rows.gd")
const RowQuery := preload("res://addons/gd_chime/row_query.gd")
const Rollup := preload("res://addons/gd_chime/rollup.gd")
const Filters := preload("res://addons/gd_chime/filters.gd")
const Stretch := preload("res://addons/gd_chime/stretch.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Measures := preload("res://addons/gd_chime/measures.gd")
const Verdict := preload("res://tests/verdict.gd")

const REGION := &"board"
const TIMES := {"opens": &"reported", "closes": &"restored"}
const REGIONS := ["Wales", "London", "East", "Scotland"]
## Noon on day 1,000, in hours.
const NOW := 1000.0 * 24.0 + 12.0
const SPEC := {"figures": {&"reported": {"how": Rollup.COUNT, "when": &"reported"}, &"out": {"how": Rollup.SUM, "of": &"customers", "when": Rollup.OPEN}}, "splits": {&"regions": {"how": Rollup.COUNT, "when": &"reported", "by": &"region"}}}
const PATIENCE := 600

var _verdict := Verdict.new()


func _init() -> void:
	await _verdict.states(_nothing_has_landed_until_the_first_rollup_and_then_every_figure_is_its)
	await _verdict.states(_a_filter_moving_leaves_the_last_figures_shown_and_the_stale_answer_is_never_shown)
	await _verdict.states(_a_figures_clauses_keep_the_rows_it_counted)
	await _verdict.states(_fifty_thousand_rows_are_rolled_up_with_the_frame_kept)
	quit(_verdict.deliver(get_script()))


## Incidents over the forty days up to now, the same every run.
func _incidents(count: int) -> PackedRows:
	var rows := PackedRows.new({&"region": PackedRows.WORDS, &"reported": PackedRows.NUMBER, &"restored": PackedRows.NUMBER, &"customers": PackedRows.NUMBER})
	var draws := RandomNumberGenerator.new()
	draws.seed = 11
	# every incident, drawn in turn
	for at: int in count:
		var reported := NOW - draws.randf_range(0.0, 40.0 * 24.0)
		rows.add([REGIONS[draws.randi() % REGIONS.size()], reported, reported + draws.randf_range(1.0, 30.0), float(draws.randi_range(10, 900))])
	return rows


## The filters and the measures over these rows, on the engine's threads, all in the tree.
func _made(made: Fixture, rows: PackedRows) -> Array:
	var budget := FrameBudget.new(made.chimes, 16.0, 0.9, 3)
	var pool := Jobs.new(made.chimes, budget, 2, 4, false)
	var presets: Array = [{"value": &"week", "words": Phrase.of("7 days"), "days": 7}, {"value": &"month", "words": Phrase.of("30 days"), "days": 30}]
	var filters := Filters.new(made.chimes, {one_of = &"region", on_a_drawing = &"region", dates = {column = &"reported", now = NOW, presets = presets, starts = &"week"}})
	made.commands.stand(REGION, filters)
	for node: Node in [budget, pool, filters]:
		root.add_child(node)
	var measures := Measures.new(made.chimes, rows, Bound.new(filters.get_rollup), pool, SPEC, TIMES)
	root.add_child(measures)
	return [filters, measures]


## Frames until nothing is out: how many it took.
func _landed(measures: Measures) -> int:
	var frames := 0
	# a frame at a time until the rollup lands, or patience runs out
	while measures.get_busy() and frames < PATIENCE:
		await process_frame
		frames += 1
	return frames


func _nothing_has_landed_until_the_first_rollup_and_then_every_figure_is_its() -> void:
	var made := Fixture.new(root)
	var rows := _incidents(2000)
	var both := _made(made, rows)
	var filters: Filters = both[0]
	var measures: Measures = both[1]
	_verdict.check(not measures.get_landed() and measures.get_figures() == null and measures.get_busy(), "as it is made, a rollup is out and nothing has landed: no figure at all")
	var frames := await _landed(measures)
	var direct := Rollup.run(rows, SPEC, [], filters.stretch.get_stretches(), TIMES)
	_verdict.check(frames > 0 and measures.get_landed() and measures.get_figures() == direct["figures"] and measures.get_splits() == direct["splits"], "a frame or more later it lands, every figure and split the rollup's own: %s" % [measures.get_figures()])
	made.done()


func _a_filter_moving_leaves_the_last_figures_shown_and_the_stale_answer_is_never_shown() -> void:
	var made := Fixture.new(root)
	var rows := _incidents(3000)
	var both := _made(made, rows)
	var filters: Filters = both[0]
	var measures: Measures = both[1]
	await _landed(measures)
	var everywhere: float = measures.get_figures()[&"reported"]["now"]
	made.commands.dispatch(REGION, Filters.picks_of(&"region"), {"picked": "Wales"})
	await process_frame
	_verdict.check(measures.get_busy() and measures.get_figures()[&"reported"]["now"] == everywhere, "a region pressed: a rollup is out as the filters ring, and the last figures are still shown meanwhile")
	made.commands.dispatch(REGION, Filters.picks_of(&"region"), {"picked": "London"})
	var seen: Array = []
	# a frame at a time until nothing is out, every count shown on the way noted
	while measures.get_busy():
		seen.append(measures.get_figures()[&"reported"]["now"])
		await process_frame
	var wales: float = Rollup.run(rows, SPEC, [{"column": &"region", "test": RowQuery.IS, "value": ["Wales"]}], filters.stretch.get_stretches(), TIMES)["figures"][&"reported"]["now"]
	var london: float = Rollup.run(rows, SPEC, filters.get_rollup()["clauses"], filters.stretch.get_stretches(), TIMES)["figures"][&"reported"]["now"]
	_verdict.check(measures.get_figures()[&"reported"]["now"] == london and london < everywhere and not seen.has(wales), "London pressed while Wales was out: London's is what lands, and Wales's is never shown: %s, never %s" % [london, wales])
	made.done()


func _a_figures_clauses_keep_the_rows_it_counted() -> void:
	var made := Fixture.new(root)
	var rows := _incidents(2000)
	var both := _made(made, rows)
	var measures: Measures = both[1]
	made.commands.dispatch(REGION, Filters.picks_of(&"region"), {"picked": "East"})
	await _landed(measures)
	# every figure, the rows its clauses keep against what it counts
	for name: StringName in [&"reported", &"out"]:
		var kept: PackedInt32Array = RowQuery.run(rows, measures.clauses_of(name), {}, &"")["order"]
		var counted: float = kept.size() if name == &"reported" else Array(kept).reduce(func(sum: float, row: int) -> float: return sum + rows.value_at(row, &"customers"), 0.0)
		_verdict.check(kept.size() > 0 and counted == measures.get_figures()[name]["now"] and Array(kept).all(func(row: int) -> bool: return rows.value_at(row, &"region") == "East"), "the %s figure's clauses keep the Eastern rows it stands for: %s" % [name, counted])
	var wales: PackedInt32Array = RowQuery.run(rows, measures.clauses_of(&"regions", "Wales"), {}, &"")["order"]
	var bar: Dictionary = measures.get_splits()[&"regions"].filter(func(one: Dictionary) -> bool: return one["key"] == "Wales")[0]
	_verdict.check(wales.size() > 0 and float(wales.size()) == bar["now"] and Array(wales).all(func(row: int) -> bool: return rows.value_at(row, &"region") == "Wales"), "a split's Welsh bar, with the East filtered, keeps the Welsh rows it counted: %d" % wales.size())
	made.done()


func _fifty_thousand_rows_are_rolled_up_with_the_frame_kept() -> void:
	var made := Fixture.new(root)
	var both := _made(made, _incidents(50000))
	var measures: Measures = both[1]
	await _landed(measures)
	made.commands.dispatch(REGION, Stretch.PICKS, {"value": &"month"})
	var longest := 0
	var last := Time.get_ticks_usec()
	# a frame at a time until the rollup lands, the longest gap between frames kept
	while true:
		await process_frame
		var now := Time.get_ticks_usec()
		longest = maxi(longest, now - last)
		last = now
		if not measures.get_busy():
			break
	_verdict.check(measures.get_took_ms() > longest / 1000.0, "fifty thousand rows rolled up in %.0f ms, the longest frame meanwhile %.1f ms: the work was not the frame's" % [measures.get_took_ms(), longest / 1000.0])
	made.done()
