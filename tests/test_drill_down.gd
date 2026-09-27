extends SceneTree

## What must be true of a drill-down: a figure pressed raises the grid of
## the very rows it counted, said over it; a split's word pressed shows that
## word's rows, whatever the dashboard filters; a filter built on the grid
## narrows within those rows and never past them; and the way back lowers it.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_drill_down.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const FrameBudget := preload("res://addons/gd_chime/frame_budget.gd")
const Jobs := preload("res://addons/gd_chime/jobs.gd")
const PackedRows := preload("res://addons/gd_chime/packed_rows.gd")
const TableModels := preload("res://addons/gd_chime/table_models.gd")
const RowFilters := preload("res://addons/gd_chime/row_filters.gd")
const Rollup := preload("res://addons/gd_chime/rollup.gd")
const Filters := preload("res://addons/gd_chime/filters.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Measures := preload("res://addons/gd_chime/measures.gd")
const Drills := preload("res://addons/gd_chime/drills.gd")
const DataGrid := preload("res://addons/gd_chime/components/recipes/data_grid.gd")
const DrillDown := preload("res://addons/gd_chime/components/recipes/drill_down.gd")
const FilterSet := preload("res://addons/gd_chime/components/recipes/filter_set.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Verdict := preload("res://tests/verdict.gd")

const BOARD := &"board"

const REGIONS := ["Wales", "London", "East"]
const NOW := 1000.0 * 24.0 + 12.0
const SPEC := {"figures": {&"reported": {"how": Rollup.COUNT, "when": &"reported"}}, "splits": {&"regions": {"how": Rollup.COUNT, "when": &"reported", "by": &"region"}}}
const WORDS := {&"reported": "incidents reported", &"regions": "incidents"}
const PATIENCE := 600

var _verdict := Verdict.new()
var _behind: StringName  # the drill-down's pop-up, named by the builder



func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(1600, 900)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_a_figure_pressed_raises_the_grid_of_the_rows_it_counted_and_back_lowers_it)
	await _verdict.states(_a_splits_word_shows_its_rows_and_a_filter_on_the_grid_narrows_within_them)
	quit(_verdict.deliver(get_script()))


## Incidents over the forty days up to now, the same every run.
func _incidents() -> PackedRows:
	var rows := PackedRows.new({&"region": PackedRows.WORDS, &"reported": PackedRows.NUMBER, &"restored": PackedRows.NUMBER, &"customers": PackedRows.NUMBER})
	var draws := RandomNumberGenerator.new()
	draws.seed = 5
	# every incident, drawn in turn
	for at: int in 900:
		var reported := NOW - draws.randf_range(0.0, 40.0 * 24.0)
		rows.add([REGIONS[draws.randi() % REGIONS.size()], reported, reported + draws.randf_range(1.0, 30.0), float(draws.randi_range(10, 900))])
	return rows


## The dashboard behind a card, the drill's pop-up beside it, started: {made, rows, filters, measures, models, drills}.
func _built() -> Dictionary:
	var made := Fixture.new(root)
	DrillDown.declare(made.actions)
	var ui := made.ui
	var budget := FrameBudget.new(made.chimes, 16.0, 0.9, 3)
	var pool := Jobs.new(made.chimes, budget, 2, 8, false)
	var rows := _incidents()
	var presets: Array = [{"value": &"week", "words": Phrase.of("7 days"), "days": 7}]
	var filters := Filters.new(made.chimes, {one_of = &"region", on_a_drawing = &"region", dates = {column = &"reported", now = NOW, presets = presets, starts = &"week"}})
	made.commands.stand(BOARD, filters)
	for node: Node in [budget, pool, filters]:
		root.add_child(node)
	var measures := Measures.new(made.chimes, rows, Bound.new(filters.get_rollup), pool, SPEC, {"opens": &"reported", "closes": &"restored"})
	root.add_child(measures)
	var columns := [{"name": &"region", "words": Phrase.of("region"), "share": 0.3, "filters": FilterSet.A_LIST}, {"name": &"reported", "words": Phrase.of("reported"), "share": 0.3}, {"name": &"restored", "words": Phrase.of("restored"), "share": 0.2}, {"name": &"customers", "words": Phrase.of("customers"), "share": 0.2, "filters": FilterSet.A_NUMBER}]
	var models := TableModels.new(ui, rows, columns, {}, pool, 12)
	var drills := Drills.new(made.chimes, measures, models, WORDS, &"regions")
	made.commands.stand(BOARD, drills)
	root.add_child(drills)
	var drill := DrillDown.make(ui, drills, models)
	_behind = drill.get_place()
	var card: Desc = ui.pressable(Drills.SHOWS_ROWS_BEHIND, {"figure": &"reported"}, [ui.text("reported")], &"Pressable").opens(drill).named(&"card")
	ui.start(ui.app(&"app", [ui.screen(BOARD, [card])]))
	await _frames(4)
	return {"made": made, "rows": rows, "filters": filters, "measures": measures, "models": models, "drills": drills}


func _frames(count: int) -> void:
	# as many frames as asked
	for waited: int in count:
		await process_frame


## Frames until neither the measures nor the grid's view has anything out.
func _landed(built: Dictionary) -> void:
	var frames := 0
	# a frame at a time, at least one, until nothing is out
	while frames < PATIENCE:
		await process_frame
		frames += 1
		if not (built["measures"] as Measures).get_busy() and not (built["models"] as TableModels).view.get_busy():
			return


func _title(built: Dictionary) -> String:
	return str((built["drills"] as Drills).get_title())


func _a_figure_pressed_raises_the_grid_of_the_rows_it_counted_and_back_lowers_it() -> void:
	var built: Dictionary = await _built()
	var made: Fixture = built["made"]
	await _landed(built)
	(made.ui.node_named(&"card") as Pressable).pressed()
	await _landed(built)
	var counted: float = (built["measures"] as Measures).get_figures()[&"reported"]["now"]
	_verdict.check(made.driver.get_top().has(_behind), "pressed, the figure's rows stand over the dashboard: %s" % [made.driver.get_top()])
	_verdict.check(counted > 0.0 and float((built["models"] as TableModels).view.get_kept()) == counted and _title(built) == "incidents reported", "the grid keeps the very %s rows the figure counted, said over them: %s" % [counted, _title(built)])
	made.commands.dispatch(Chimes.GLOBAL, Driver.GOES_BACK, {})
	await _frames(2)
	_verdict.check(not made.driver.get_top().has(_behind), "the way back lowers it: %s" % [made.driver.get_top()])
	made.done()


func _a_splits_word_shows_its_rows_and_a_filter_on_the_grid_narrows_within_them() -> void:
	var built: Dictionary = await _built()
	var made: Fixture = built["made"]
	var rows: PackedRows = built["rows"]
	var models: TableModels = built["models"]
	made.commands.dispatch(BOARD, Filters.picks_of(&"region"), {"picked": "East"})
	await _landed(built)
	made.commands.dispatch(BOARD, Drills.SHOWS_ROWS_BEHIND, {"picked": "Wales"})
	await _landed(built)
	var bar: Dictionary = (built["measures"] as Measures).get_splits()[&"regions"].filter(func(one: Dictionary) -> bool: return one["key"] == "Wales")[0]
	var kept: Array = Array(models.view.get_order())
	_verdict.check(float(kept.size()) == bar["now"] and kept.all(func(row: int) -> bool: return rows.value_at(row, &"region") == "Wales") and _title(built) == "incidents in Wales", "Wales's bar drilled with the East filtered: its %s Welsh rows, said so: %s" % [bar["now"], _title(built)])
	made.commands.dispatch(_behind, RowFilters.PICKS_PROPERTY, {"value": &"customers"})
	made.commands.dispatch(_behind, RowFilters.PICKS_COMPARISON, {"comparison": "is over"})
	made.commands.dispatch(_behind, RowFilters.SETS_VALUE, {"line": "500"})
	await _landed(built)
	var narrowed: Array = Array(models.view.get_order())
	_verdict.check(not narrowed.is_empty() and narrowed.size() < kept.size() and narrowed.all(func(row: int) -> bool: return rows.value_at(row, &"region") == "Wales" and rows.value_at(row, &"customers") > 500.0), "a filter built on the grid narrows within the Welsh rows, never past them: %d of %d" % [narrowed.size(), kept.size()])
	made.done()
