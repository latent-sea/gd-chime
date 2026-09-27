extends SceneTree

## What must be true of a rolling series: its points are the last whole
## buckets, by the values' own time, the one filling left out; a mean is the
## average of its bucket and a gap where nothing fell, a rate per minute its
## total scaled to a minute; a value older than the window is let go; it
## rings as buckets are filled, once a frame, and never for the bucket still
## filling; its span holds the time axis still and its value axis at a
## round ceiling; and the floor's line chart draws it as it is.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_rolling_series.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const RollingSeries := preload("res://addons/gd_chime/rolling_series.gd")
const LineChart := preload("res://addons/gd_chime/components/recipes/line_chart.gd")
const Verdict := preload("res://tests/verdict.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")

const POINTS := 5

var _verdict := Verdict.new()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	await _verdict.states(_its_points_are_the_last_whole_buckets_by_the_values_own_time)
	await _verdict.states(_it_rings_as_buckets_fill_once_a_frame_and_never_for_the_one_filling)
	await _verdict.states(_the_floor_s_line_chart_draws_it_as_it_is)
	quit(_verdict.deliver(get_script()))


func _made(made: Fixture) -> RollingSeries:
	var series := RollingSeries.new(made.chimes, [{"name": "wait", "kind": RollingSeries.MEAN}, {"name": "faults", "kind": RollingSeries.PER_MINUTE}], 2.0, POINTS, "seconds", "value")
	root.add_child(series)
	return series


func _its_points_are_the_last_whole_buckets_by_the_values_own_time() -> void:
	var made := Fixture.new(root)
	var series := _made(made)
	# two seconds a bucket: values in buckets 0 to 7, none in bucket 4, the last in bucket 8 still filling
	for at: float in [0.5, 1.5, 2.5, 4.0, 6.1, 10.0, 12.2, 14.0, 16.5]:
		series.take(0, at, at * 10.0)
		series.take(1, at, 1.0)
	var chart := series.get_chart()
	var wait: PackedVector2Array = chart["series"][0]["points"]
	var faults: PackedVector2Array = chart["series"][1]["points"]
	var expected := PackedVector2Array([Vector2(-8.0, 61.0), Vector2(-4.0, 100.0), Vector2(-2.0, 122.0), Vector2(0.0, 140.0)])
	_verdict.check(wait == expected, "the mean of each of the last five whole buckets, a gap where nothing fell, the one filling left out: %s" % [wait])
	_verdict.check(faults.size() == POINTS and faults[0] == Vector2(-8.0, 30.0) and faults[1] == Vector2(-6.0, 0.0), "a rate per minute is its bucket's total scaled to a minute, an empty bucket nought: %s" % [faults])
	series.take(0, 1.0, 999.0)
	_verdict.check(series.get_chart()["series"][0]["points"] == expected, "a value older than the window is let go")
	var span: Rect2 = chart["span"]
	_verdict.check(span.position.x == -8.0 and span.end.x == 0.0 and span.position.y == 0.0 and span.end.y == 200.0, "the span runs the window's seconds to nought and from nought to a round ceiling: %s" % span)
	_verdict.check(RollingSeries.ceiling(37.0) == 50.0 and RollingSeries.ceiling(100.0) == 100.0 and RollingSeries.ceiling(101.0) == 200.0 and RollingSeries.ceiling(0.0) == 1.0, "the ceiling is the first 1, 2 or 5 of a power of ten at or over the value")
	made.done()


func _it_rings_as_buckets_fill_once_a_frame_and_never_for_the_one_filling() -> void:
	var made := Fixture.new(root)
	var series := _made(made)
	var ears := Fixture.Heard.new(made.chimes, series.get_chart)
	root.add_child(ears)
	series.take(0, 0.1, 1.0)
	series.take(0, 0.2, 1.0)
	await process_frame
	_verdict.check(ears.rung == 0, "values in the bucket still filling ring nothing: %d" % ears.rung)
	# four buckets filled in one frame
	for at: float in [2.1, 4.1, 6.1, 8.1]:
		series.take(0, at, 1.0)
	await process_frame
	_verdict.check(ears.rung == 1, "four buckets filled in a frame ring once: %d" % ears.rung)
	made.done()


func _the_floor_s_line_chart_draws_it_as_it_is() -> void:
	var made := Fixture.new(root)
	var series := _made(made)
	# a value a second for twenty seconds
	for at: int in 20:
		series.take(0, float(at), float(at))
	var ui := made.ui
	ui.start(ui.app(&"app", [LineChart.make(ui, Bound.new(series.get_chart)).named(&"chart")]))
	await process_frame
	await process_frame
	var legend: Array = []
	_collect_words(ui.node_named(&"chart"), legend)
	_verdict.check(legend.has("wait") and legend.has("faults"), "the line chart draws the series and names both in its legend: %s" % [legend])
	made.done()


## Every label's words under this node.
static func _collect_words(node: Node, into: Array) -> void:
	# every child, its words taken and searched within
	for child: Node in node.get_children():
		if child is Label:
			into.append((child as Label).text)
		_collect_words(child, into)
