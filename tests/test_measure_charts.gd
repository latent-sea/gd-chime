extends SceneTree

## What must be true of a dashboard's charts of its figures: a day is
## placed by how many days it is before the last, a day of nothing left
## out and a spread's day by the part asked for; a trend is an area of its
## stretch, the stretch before laid over it only while comparing, called
## what the caller calls it; a band is the middle half as an area and the
## middle as a line; and each says the caller's words while its figure has
## nothing in any day. Loading is loaded_or_empty.gd's, held by the KPI
## card's and the bar chart's tests, which can hold a figure unlanded.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_measure_charts.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const FrameBudget := preload("res://addons/gd_chime/frame_budget.gd")
const Jobs := preload("res://addons/gd_chime/jobs.gd")
const PackedRows := preload("res://addons/gd_chime/packed_rows.gd")
const Rollup := preload("res://addons/gd_chime/rollup.gd")
const Filters := preload("res://addons/gd_chime/filters.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Measures := preload("res://addons/gd_chime/measures.gd")
const LineChart := preload("res://addons/gd_chime/components/recipes/line_chart.gd")
const MeasureCharts := preload("res://addons/gd_chime/components/recipes/measure_charts.gd")
const Canvas := preload("res://addons/gd_chime/components/primitives/canvas.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Verdict := preload("res://tests/verdict.gd")

const BOARD := &"board"
const NOW := 1000.0 * 24.0 + 12.0
const SPEC := {"figures": {&"reported": {"how": Rollup.COUNT, "when": &"reported"}, &"repair": {"how": Rollup.SPREAD, "of": &"repair", "when": &"restored"}}}
const PATIENCE := 600

var _verdict := Verdict.new()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(1200, 800)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_a_day_is_placed_back_from_the_last_and_a_day_of_nothing_is_left_out)
	await _verdict.states(_a_trend_lays_the_stretch_before_over_it_only_while_comparing)
	await _verdict.states(_a_band_is_the_middle_half_as_an_area_and_the_middle_as_a_line)
	await _verdict.states(_each_says_so_when_nothing_is_in_any_day)
	quit(_verdict.deliver(get_script()))


func _a_day_is_placed_back_from_the_last_and_a_day_of_nothing_is_left_out() -> void:
	_verdict.check(MeasureCharts.days_series([4.0, null, 6.0]) == [Vector2(-2.0, 4.0), Vector2(0.0, 6.0)], "the last day is 0 and each before it one less; a day of nothing is left out: %s" % [MeasureCharts.days_series([4.0, null, 6.0])])
	_verdict.check(MeasureCharts.days_series([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]], 2) == [Vector2(-1.0, 3.0), Vector2(0.0, 6.0)], "a spread's day by the part asked for: its high quarter")


## Incidents over forty days up to now, so many a day as asked; and repairs to go with them.
func _incidents(each_day: int) -> PackedRows:
	var rows := PackedRows.new({&"reported": PackedRows.NUMBER, &"restored": PackedRows.NUMBER, &"repair": PackedRows.NUMBER, &"region": PackedRows.WORDS})
	# every hour of forty days back, an incident every so many hours
	for hour: int in range(0, 40 * 24, 24 / maxi(each_day, 1)):
		if each_day > 0:
			rows.add([NOW - hour - 1.0, NOW - hour + 1.0 + (hour % 7), 2.0 + (hour % 7), "Wales"])
	return rows


## Measures over these rows and a chart of them built: [made, comparing, measures, the chart's holder].
func _charted(rows: PackedRows, band: bool, compares: bool = true) -> Array:
	var made := Fixture.new(root)
	var ui := made.ui
	var budget := FrameBudget.new(made.chimes, 16.0, 0.9, 3)
	var pool := Jobs.new(made.chimes, budget, 2, 8, false)
	var presets: Array = [{"value": &"week", "words": Phrase.of("7 days"), "days": 7}]
	var filters := Filters.new(made.chimes, {one_of = &"region", dates = {column = &"reported", now = NOW, presets = presets, starts = &"week"}})
	made.commands.stand(BOARD, filters)
	for node: Node in [budget, pool, filters]:
		root.add_child(node)
	var measures := Measures.new(made.chimes, rows, Bound.new(filters.get_rollup), pool, SPEC, {"opens": &"reported", "closes": &"restored"})
	root.add_child(measures)
	# whether the dashboard compares, and what it calls the stretch before: the caller's, as a card's and a bar's are
	var comparing := ui.local(false)
	var before := ui.bound(func() -> Phrase: return Phrase.of("The 7 days before"))
	var said := {says = Phrase.of("incidents"), x_words = "days", y_words = "incidents", says_empty = Phrase.of("no incidents")}
	if compares:
		said.merge({comparing = comparing, before_words = before})
	var chart := MeasureCharts.band(ui, measures, &"repair", {says_middle = Phrase.of("the middle repair"), says_half = Phrase.of("the middle half"), x_words = "days", y_words = "hours", says_empty = Phrase.of("nothing was repaired")}) if band else MeasureCharts.trend(ui, measures, &"reported", said)
	ui.start(ui.app(&"app", [ui.column([chart.grow()]).named(&"chart")]))
	return [made, comparing, measures, ui.node_named(&"chart")]


func _landed(measures: Measures) -> void:
	var frames := 0
	# a frame at a time, at least two, until nothing is out
	while frames < PATIENCE:
		await process_frame
		frames += 1
		if frames > 2 and not measures.get_busy():
			break
	# the landing rings at the frame's end and is drawn on the frame after
	await process_frame
	await process_frame


## What the chart's plot is drawn from now.
func _plot(holder: Node) -> Variant:
	var canvases: Array = holder.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Canvas and part.is_visible_in_tree())
	return null if canvases.is_empty() else (canvases[0] as Canvas)._content.read()


func _shown(node: Node) -> Array[String]:
	var found: Array[String] = []
	# every text under it that is drawn
	for text: Node in node.find_children("*", "Control", true, false):
		if text is Text and (text as Text).is_visible_in_tree() and (text as Text).get_text() != "":
			found.append((text as Text).get_text())
	return found


func _a_trend_lays_the_stretch_before_over_it_only_while_comparing() -> void:
	var built: Array = _charted(_incidents(4), false)
	await _landed(built[2])
	var drawn: Dictionary = _plot(built[3])["chart"]
	var one: Dictionary = drawn["series"][0]
	_verdict.check(drawn["series"].size() == 1 and one["points"].size() == 7 and one["points"][-1].x == 0.0 and one["under"].all(func(point: Vector2) -> bool: return point.y == 0.0), "a week's trend is one area of seven days down to nothing, the last day at 0: %s" % [one["points"]])
	built[1].set_value(true)
	await _landed(built[2])
	drawn = _plot(built[3])["chart"]
	var laid: Variant = drawn["series"][1] if drawn["series"].size() > 1 else null
	_verdict.check(laid != null and str(laid["name"]) == "The 7 days before" and laid["points"].size() == 7 and not laid.has("under"), "comparing, the stretch before is laid over it as a line, called as the caller calls it: %s" % [drawn["series"]])
	(built[0] as Fixture).done()
	var alone: Array = _charted(_incidents(4), false, false)
	await _landed(alone[2])
	var plotted: Variant = _plot(alone[3])
	_verdict.check(plotted != null and plotted["chart"]["series"].size() == 1, "given nothing to compare by, a trend is its own stretch alone: %s" % [plotted])
	(alone[0] as Fixture).done()


func _a_band_is_the_middle_half_as_an_area_and_the_middle_as_a_line() -> void:
	var built: Array = _charted(_incidents(4), true)
	await _landed(built[2])
	var drawn: Dictionary = _plot(built[3])["chart"]
	var half: Dictionary = drawn["series"][0]
	var middle: Dictionary = drawn["series"][1]
	var inside := true
	# every day, its middle between its quarters
	for at: int in middle["points"].size():
		inside = inside and half["under"][at].y <= middle["points"][at].y and middle["points"][at].y <= half["points"][at].y
	_verdict.check(half.has("under") and not middle.has("under") and inside and middle["points"].size() > 0, "the middle half is an area from its low quarter to its high, and the middle a line inside it")
	(built[0] as Fixture).done()


func _each_says_so_when_nothing_is_in_any_day() -> void:
	var none: Array = _charted(_incidents(0), false)
	await _landed(none[2])
	_verdict.check(_shown(none[3]) == ["no incidents"] and _plot(none[3]) == null, "landed with nothing in any day, it says so and draws no plot: %s" % [_shown(none[3])])
	(none[0] as Fixture).done()
