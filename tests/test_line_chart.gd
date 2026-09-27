extends SceneTree

## What must be true of the line chart: the extent, where a point lands,
## the numbers marked along an axis, that two series are told apart
## without hue, and that a point appended repaints the plot.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_line_chart.gd
##
## The geometry is pure, so most of this is checked with no window at all:
## only the last two properties build anything.

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Canvas := preload("res://addons/gd_chime/components/primitives/canvas.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const LineChart := preload("res://addons/gd_chime/components/recipes/line_chart.gd")
const ChartAxes := preload("res://addons/gd_chime/components/recipes/chart_axes.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Verdict := preload("res://tests/verdict.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")

var _verdict := Verdict.new()


## A model holding a chart: the series, and what the axes are.
class Charted extends Fixture.Model:
	func get_chart() -> Variant:
		return of(&"chart").read()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(600, 400)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_the_extent_holds_every_point_of_every_series_and_a_flat_one_still_has_a_middle)
	await _verdict.states(_a_point_lands_across_for_its_time_and_up_for_its_value_inside_the_margin)
	await _verdict.states(_the_numbers_marked_along_an_axis_are_round_and_inside_the_range)
	await _verdict.states(_two_series_are_told_apart_by_dash_and_by_marker_and_the_legend_names_both_with_theirs)
	await _verdict.states(_a_point_appended_repaints_the_plot_and_the_extent_grows_to_hold_it)
	await _verdict.states(_a_line_is_drawn_as_far_as_it_has_been_reached_the_last_part_of_the_way)
	await _verdict.states(_a_span_the_model_gives_is_drawn_over_as_given_and_a_value_past_it_stays_on_the_plot)
	await _verdict.states(_an_area_is_its_line_and_back_along_its_lower_edge_and_is_filled_under_the_line)
	await _verdict.states(_a_series_named_in_words_is_named_so_in_the_legend)
	await _verdict.states(_a_chart_of_one_series_names_no_marker_beside_it)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


func _texts(node: Node) -> Array[String]:
	var found: Array[String] = []
	for child: Node in node.get_children():
		if child is Text:
			found.append((child as Text).get_text())
		found.append_array(_texts(child))
	return found


func _canvases(node: Node) -> Array:
	return node.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Canvas)


func _the_extent_holds_every_point_of_every_series_and_a_flat_one_still_has_a_middle() -> void:
	var series := [{"name": "a", "points": [Vector2(0.0, 1.0), Vector2(2.0, 7.0)]}, {"name": "b", "points": [Vector2(-1.0, 3.0), Vector2(5.0, 2.0)]}]
	var span := ChartAxes.extent(series)
	var holds := true
	# every point of both series, which the one box must hold
	for one: Dictionary in series:
		for point: Vector2 in one["points"]:
			holds = holds and span.encloses(Rect2(point, Vector2.ZERO))
	_verdict.check(holds and span == Rect2(-1.0, 1.0, 6.0, 6.0), "the extent reaches the lowest and highest of both series: %s" % [span])
	_verdict.check(ChartAxes.extent([{"name": "a", "points": [Vector2(0.0, 4.0), Vector2(3.0, 4.0)]}]) == Rect2(0.0, 3.5, 3.0, 1.0), "a flat series is padded, so it has a middle to sit on rather than no height")
	_verdict.check(ChartAxes.extent([{"name": "a", "points": [Vector2(2.0, 2.0)]}]).size == Vector2(1.0, 1.0), "a single point is padded on both axes")


func _a_point_lands_across_for_its_time_and_up_for_its_value_inside_the_margin() -> void:
	var span := Rect2(0.0, 0.0, 10.0, 100.0)
	var size := Vector2(300.0, 200.0)
	var margin := Vector4(50.0, 20.0, 50.0, 20.0)
	var low := ChartAxes.to_canvas(span.position, span, size, margin)
	var high := ChartAxes.to_canvas(span.end, span, size, margin)
	_verdict.check(low == Vector2(50.0, 180.0) and high == Vector2(250.0, 20.0), "the extent's corners land on the plot's corners, inside the margin: %s to %s" % [low, high])
	_verdict.check(ChartAxes.to_canvas(Vector2(5.0, 50.0), span, size, margin) == Vector2(150.0, 100.0), "the middle of the data lands in the middle of the plot")
	_verdict.check(ChartAxes.to_canvas(Vector2(0.0, 75.0), span, size, margin).y < ChartAxes.to_canvas(Vector2(0.0, 25.0), span, size, margin).y, "a greater value is drawn higher up: the value axis runs upward")
	var canvas := Control.new()
	root.add_child(canvas)
	var line := canvas.get_theme_default_font().get_height()
	var margins := ChartAxes.margin_of(canvas, {"x_words": "days", "y_words": "hours"})
	var bare := ChartAxes.margin_of(canvas, {"x_words": "", "y_words": ""})
	_verdict.check(margins.w >= line * 2.0 + ChartAxes.TICK, "under the plot there is room for a tick, a line of the time axis's numbers and a line of its words, one under the other, never over each other: %s for lines of %s" % [margins.w, line])
	_verdict.check(margins.y >= line * 1.5 and margins.y < margins.w, "over it, a line for the value axis's words and half a line under them for the top number, which stands across the plot's edge - and no more, so the plot keeps the room: %s" % margins.y)
	_verdict.check(bare.y >= line * 0.5 and bare.y < margins.y - line and bare.w >= line + ChartAxes.TICK and bare.w < margins.w - line, "a chart whose axes say nothing gives their lines to the plot, keeping room for half the top number and the time axis's numbers: %s against %s" % [bare, margins])
	var lopsided := ChartAxes.to_canvas(Vector2(10.0, 0.0), span, size, Vector4(40.0, 10.0, 20.0, 30.0))
	_verdict.check(lopsided == Vector2(280.0, 170.0), "each margin is its own side's: the plot's far corner stands in from the right and up from the bottom by theirs: %s" % [lopsided])
	canvas.free()


func _the_numbers_marked_along_an_axis_are_round_and_inside_the_range() -> void:
	var tens := ChartAxes.ticks(0.0, 10.0, 4)
	_verdict.check(tens == [0.0, 5.0, 10.0], "zero to ten marked about four times: round fives: %s" % [tens])
	var odd := ChartAxes.ticks(3.0, 27.0, 4)
	var inside := true
	# every number marked, which must be a number the reader would have chosen
	for mark: float in odd:
		inside = inside and mark >= 3.0 and mark <= 27.0 and is_equal_approx(mark, roundf(mark / 10.0) * 10.0)
	_verdict.check(inside and odd == [10.0, 20.0], "an awkward range is marked in round numbers, none outside it: %s" % [odd])
	_verdict.check(ChartAxes.fitting(40.0, 20.0) == 1 and ChartAxes.fitting(90.0, 20.0) == 3 and ChartAxes.fitting(900.0, 20.0) == ChartAxes.TICKS, "a short axis marks only the numbers it has room for, a line and a half each, and a long one no more than TICKS")
	var small := ChartAxes.ticks(-1.0, 1.0, 4)
	_verdict.check(small == [-1.0, -0.5, 0.0, 0.5, 1.0], "below zero and under one, the round numbers are halves: %s" % [small])


func _two_series_are_told_apart_by_dash_and_by_marker_and_the_legend_names_both_with_theirs() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var model := Charted.new(made.chimes, &"app")
	model.set_value(&"chart", _two_series())
	ui.start(ui.app(&"app", [LineChart.make(ui, Bound.new(model.get_chart)).named(&"chart")]))
	await _a_frame_passes()
	_verdict.check(LineChart.dash_of(0) != LineChart.dash_of(1) and LineChart.marker_of(0) != LineChart.marker_of(1), "the first two series are drawn with different dashes and different markers: %s and %s" % [LineChart.dash_of(1), LineChart.marker_of(1)])
	_verdict.check(LineChart.dash_of(0)[1] == 0.0 and LineChart.dash_of(1)[1] > 0.0, "the first is unbroken and the second is broken, so the pattern carries the difference on its own")
	var words := _texts(ui.node_named(&"chart"))
	_verdict.check(words.has("alpha") and words.has("beta") and words.has(str(LineChart.marker_of(0))) and words.has(str(LineChart.marker_of(1))), "the legend names both series, each beside the marker it is drawn with: %s" % [words])
	_verdict.check(_canvases(ui.node_named(&"chart")).size() == 3, "one plot and a sample drawn for each series")
	var drawn: Array = _canvases(ui.node_named(&"chart"))
	var least: int = (drawn[0] as Control).get_theme_constant(&"least_height", &"LineChart")
	_verdict.check(least > 0 and (drawn[0] as Control).get_combined_minimum_size().y >= least and (drawn[1] as Control).get_combined_minimum_size().y < least, "the plot is never less tall than the look's least height for it, and a legend's sample is not held so tall: %s and %s" % [(drawn[0] as Control).get_combined_minimum_size().y, (drawn[1] as Control).get_combined_minimum_size().y])
	model.free()
	made.done()


func _a_point_appended_repaints_the_plot_and_the_extent_grows_to_hold_it() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var model := Charted.new(made.chimes, &"app")
	model.set_value(&"chart", _two_series())
	ui.start(ui.app(&"app", [LineChart.make(ui, Bound.new(model.get_chart)).named(&"chart")]))
	await _a_frame_passes()
	var plot: Control = _canvases(ui.node_named(&"chart"))[0]
	var drawn := [0]
	plot.draw.connect(func() -> void: drawn[0] += 1)
	var before := ChartAxes.extent(model.of(&"chart").read()["series"])
	var extended: Dictionary = model.of(&"chart").read().duplicate(true)
	extended["series"][0]["points"].append(Vector2(9.0, 40.0))
	model.set_value(&"chart", extended)
	await _a_frame_passes()
	_verdict.check(drawn[0] > 0, "a point appended and the bell rung, the plot is painted again: %d" % drawn[0])
	var after := ChartAxes.extent(extended["series"])
	_verdict.check(after.size.x > before.size.x and after.size.y > before.size.y and after.encloses(Rect2(Vector2(9.0, 40.0), Vector2.ZERO)), "and the axes grow to hold the new point: %s from %s" % [after, before])
	model.free()
	made.done()


## A series' name is English words, so a phrase: the legend keeps its entry
## by the phrase's English and says it in the language on.
func _a_series_named_in_words_is_named_so_in_the_legend() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var model := Charted.new(made.chimes, &"app")
	model.set_value(&"chart", {"series": [{"name": Phrase.of("average round trip"), "points": [Vector2(0.0, 1.0), Vector2(1.0, 2.0)]}, {"name": Phrase.of("slowest"), "points": [Vector2(0.0, 3.0), Vector2(1.0, 4.0)]}], "x_words": "seconds", "y_words": "ms"})
	ui.start(ui.app(&"app", [LineChart.make(ui, Bound.new(model.get_chart)).named(&"chart")]))
	await _a_frame_passes()
	var words := _texts(ui.node_named(&"chart"))
	_verdict.check(words.has("average round trip") and words.has("slowest"), "each series named in words is named so in the legend: %s" % [words])
	var chart: Control = ui.node_named(&"chart")
	var samples: Array = _canvases(chart).slice(1)
	var entries: float = samples.map(func(sample: Control) -> float: return sample.get_parent().get_combined_minimum_size().x).reduce(func(sum: float, one: float) -> float: return sum + one, 0.0)
	_verdict.check(chart.get_combined_minimum_size().x < entries, "the legend breaks onto more lines where it is narrow, so the chart needs less across than its entries side by side: %s against %s" % [chart.get_combined_minimum_size().x, entries])
	model.free()
	made.done()


## A marker word tells one series from another, so a chart of one series
## has nothing to tell apart: its legend keeps the series' name and its
## sample, and says no marker.
func _a_chart_of_one_series_names_no_marker_beside_it() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var model := Charted.new(made.chimes, &"app")
	model.set_value(&"chart", {"series": [{"name": "alpha", "points": [Vector2(0.0, 1.0), Vector2(1.0, 5.0)]}], "x_words": "rounds", "y_words": "measure"})
	ui.start(ui.app(&"app", [LineChart.make(ui, Bound.new(model.get_chart)).named(&"chart")]))
	await _a_frame_passes()
	var alone := _texts(ui.node_named(&"chart"))
	_verdict.check(alone.has("alpha") and not alone.has(str(LineChart.marker_of(0))), "one series is named in the legend and its marker is not: %s" % [alone])
	_verdict.check(_canvases(ui.node_named(&"chart")).size() == 2, "and it still has its plot and its own sample, which is what tells it from the axes")
	model.set_value(&"chart", _two_series())
	await _a_frame_passes()
	var both := _texts(ui.node_named(&"chart"))
	_verdict.check(both.has(str(LineChart.marker_of(0))) and both.has(str(LineChart.marker_of(1))), "a second series arriving, both markers are named: %s" % [both])
	model.free()
	made.done()


## Two series over the same rounds, crossing in the middle.
func _two_series() -> Dictionary:
	return {"series": [{"name": "alpha", "points": [Vector2(0.0, 1.0), Vector2(1.0, 5.0), Vector2(2.0, 9.0)]}, {"name": "beta", "points": [Vector2(0.0, 9.0), Vector2(1.0, 5.0), Vector2(2.0, 1.0)]}], "x_words": "rounds", "y_words": "measure"}


## A series extending is reached, not there at once: the whole points so
## far, and the last a part of the way along its segment.
func _a_line_is_drawn_as_far_as_it_has_been_reached_the_last_part_of_the_way() -> void:
	var places := PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(10, 20)])
	_verdict.check(LineChart.reached(places, 3.0) == places, "reached to its end, it is every point")
	_verdict.check(LineChart.reached(places, 2.5) == PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(10, 10)]), "half way to a new point, the line ends half way along the segment: %s" % [LineChart.reached(places, 2.5)])
	_verdict.check(LineChart.reached(places, 2.0) == PackedVector2Array([Vector2(0, 0), Vector2(10, 0)]), "not yet set off, it ends at the point before")
	_verdict.check(LineChart.reached(places, 0.0).is_empty(), "and nothing reached draws nothing")


## A live chart's model gives the span, so its axes stand still while its
## values wander inside it.
func _a_span_the_model_gives_is_drawn_over_as_given_and_a_value_past_it_stays_on_the_plot() -> void:
	var given := Rect2(-59.0, 0.0, 59.0, 200.0)
	var chart := {"series": [{"name": "a", "points": [Vector2(-59.0, 10.0), Vector2(0.0, 12.0)]}], "span": given, "x_words": "", "y_words": ""}
	_verdict.check(ChartAxes.span_of(chart) == given, "a chart carrying a span is drawn over that span, not its points' own: %s" % [ChartAxes.span_of(chart)])
	chart.erase("span")
	_verdict.check(ChartAxes.span_of(chart) == ChartAxes.extent(chart["series"]), "one carrying none is fitted to its points")
	var size := Vector2(300.0, 200.0)
	var margin := Vector4(50.0, 20.0, 50.0, 20.0)
	var past := ChartAxes.to_canvas(Vector2(0.0, 500.0), given, size, margin)
	_verdict.check(past == Vector2(250.0, 20.0), "a value past the span's top is drawn on the plot's top edge, never in the margin or off the canvas: %s" % [past])


## A band: a line filled down to a lower edge at the same times.
func _an_area_is_its_line_and_back_along_its_lower_edge_and_is_filled_under_the_line() -> void:
	var line := PackedVector2Array([Vector2(0, 10), Vector2(10, 5), Vector2(20, 8)])
	var under := PackedVector2Array([Vector2(0, 20), Vector2(10, 20), Vector2(20, 20)])
	var shape := LineChart.area(line, under)
	_verdict.check(shape == PackedVector2Array([Vector2(0, 10), Vector2(10, 5), Vector2(20, 8), Vector2(20, 20), Vector2(10, 20), Vector2(0, 20)]), "an area runs along its line and back along its lower edge, one closed shape: %s" % [shape])
	_verdict.check(LineChart.area(line.slice(0, 2), under).size() == 4, "reached only part of the way, the area is only as long as its line")
	var banded := [{"name": "a", "points": [Vector2(0.0, 5.0), Vector2(1.0, 6.0)], "under": [Vector2(0.0, 1.0), Vector2(1.0, 2.0)]}]
	_verdict.check(ChartAxes.extent(banded) == Rect2(0.0, 1.0, 1.0, 5.0), "the extent holds the lower edge too: %s" % [ChartAxes.extent(banded)])
	var made := Fixture.new(root)
	var ui := made.ui
	var model := Charted.new(made.chimes, &"app")
	model.set_value(&"chart", {"series": banded, "x_words": "days", "y_words": "hours"})
	ui.start(ui.app(&"app", [LineChart.make(ui, Bound.new(model.get_chart)).named(&"chart")]))
	await _a_frame_passes()
	var plot: Control = _canvases(ui.node_named(&"chart"))[0]
	var fill := plot.get_theme_color(&"fill")
	_verdict.check(fill.a > 0.0 and fill.a < plot.get_theme_color(&"line").a, "the look fills an area fainter than the line over it, so the line still reads: %s" % [fill])
	_verdict.check(_canvases(ui.node_named(&"chart")).size() == 2, "a filled series has its plot and its legend's sample, drawn with no complaint")
	model.free()
	made.done()
