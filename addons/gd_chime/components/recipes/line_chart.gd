extends RefCounted

const Themes := preload("../../theme.gd")
const Ui := preload("../primitives/ui.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Language := preload("../../language.gd")
const Phrase := preload("../../phrase.gd")
const ChartAxes := preload("chart_axes.gd")

## A line chart: values over time, one or more series over the same two
## axes, so a trend, a plateau and a crossing read at a glance while the
## series are still being extended - and an AREA, a series filled down to a
## lower edge: a band between two lines, or the ground under one.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The chart is the MODEL's: {series: [{name, points}], x_words, y_words},
## a point a Vector2 of time against value, already in the order and the
## unit it wants shown. A series may carry "under", the points of its lower
## edge at the same times, and the room between is filled in the style's
## "fill"; and the chart may carry "span", a Rect2 in the data's units, to
## be drawn over as given (chart_axes.gd) - a live chart's model widens it
## in steps, so its axes stand still while its values move. This reads that
## bound value and draws it; a point appended and the bell rung repaints.
## NO SERIES IS TOLD APART BY HUE: each carries its own dash pattern and
## its own point marker, and the legend names it beside the same marker,
## so the chart reads in one ink and to a reader who sees no colour at
## all. How thick a line is and how big a marker, the look says under the
## style: "line_width" and "marker_radius".
##
## A MARKER IS NAMED ONLY WHERE TWO OR MORE SERIES SHARE THE CHART. The
## word tells one series from another; beside a chart of one it names
## nothing - "Circle" is then a word the reader must read to learn that
## there is nothing to tell apart. So a lone series keeps its sample and
## its name and is given no marker word.

## The dash patterns and the point markers, one per series in turn: a dash
## is a length drawn then a length skipped, and no gap is a solid line.
const DASHES := [[10.0, 0.0], [9.0, 6.0], [2.0, 5.0], [16.0, 6.0]]
const MARKER_WORDS: Array[StringName] = [&"Circle", &"Square", &"Diamond", &"Triangle"]
## A legend's sample of a line: the chart's inks, and none of the least height a plot is given.
const SAMPLE := &"LineChartSample"


## The chart over a bound {series, x_words, y_words}: the plot filling the
## room it is given, and under it a legend naming every series beside the
## mark it is drawn with, breaking onto more lines where it is narrow.
static func make(ui: Ui, chart: Bound, style: StringName = &"LineChart") -> Desc:
	var legend: Bound = chart.field("series").map(_marked)
	var entry := func(one: Bound) -> Desc: return ui.row([ui.canvas(_paint_sample, one, SAMPLE).basis(0.06), ui.text(one.field("name"), Themes.REASON), ui.text(one.map(func(mark: Variant) -> Variant: return null if mark == null or not mark["tells_apart"] else Phrase.of(mark["marker"])), Themes.REASON)])
	var by_name := func(one: Dictionary) -> String: return str(one["name"])
	# how far along its points the longest series is drawn: eased, so a point added is reached, not there at once
	var reach: Bound = ui.eased(chart.map(_longest))
	# drawn again when the language changes, since its numbers are written in it
	var drawn: Bound = Bound.all([chart, reach, Language.on()], func(all: Variant, so_far: Variant, _language: StringName) -> Variant: return null if all == null else {"chart": all, "reach": so_far})
	return ui.surface(style, [ui.column([ui.canvas(_paint, drawn, style).grow(), ui.each_across(legend, entry, by_name, Themes.TILES)])])


## How many points the longest series has, as a number to go smoothly to.
static func _longest(chart: Variant) -> Variant:
	if chart == null or chart["series"].is_empty():
		return null
	return float(chart["series"].map(func(one: Dictionary) -> int: return one["points"].size()).max())


## The points of a line as far as it has been reached: whole ones, and the
## last a part of the way along its segment.
static func reached(places: PackedVector2Array, reach: float) -> PackedVector2Array:
	var whole := mini(floori(reach), places.size())
	var so_far := places.slice(0, whole)
	if whole >= 1 and whole < places.size() and reach > whole:
		so_far.append(places[whole - 1].lerp(places[whole], reach - whole))
	return so_far


## The dash pattern a series is drawn with, by its place in the set.
static func dash_of(index: int) -> Array[float]:
	var pattern: Array[float] = []
	pattern.assign(DASHES[index % DASHES.size()])
	return pattern


## The marker its points are drawn with, by its place in the set.
static func marker_of(index: int) -> StringName:
	return MARKER_WORDS[index % MARKER_WORDS.size()]


## The room an area fills: along its line as far as it is reached, and back
## along its lower edge as far - one closed shape, drawn as one.
static func area(line: PackedVector2Array, under: PackedVector2Array) -> PackedVector2Array:
	var edge := under.slice(0, line.size())
	edge.reverse()
	return line + edge


## The legend's entries: one per series, in the order they are drawn, so
## the index that gives the dash and the marker is the same index - and the
## marker named only where there is another series to tell it from.
static func _marked(series: Variant) -> Array:
	var marks: Array = []
	var count: int = 0 if series == null else series.size()
	# one entry per series, carrying the marks it is drawn with
	for index: int in range(count):
		marks.append({"name": series[index]["name"], "marker": marker_of(index), "tells_apart": count > 1, "dash": dash_of(index), "fills": series[index].has("under")})
	return marks


## The plot: the axes with their numbers and their words, then every
## series - its area filled first where it has one - as its own dashed line
## with its own marker at each point.
static func _paint(control: Control, drawn: Variant) -> void:
	if drawn == null:
		return
	var chart: Dictionary = drawn["chart"]
	var margin := ChartAxes.margin_of(control, chart)
	var span := ChartAxes.span_of(chart)
	var ink := control.get_theme_color(&"line")
	ChartAxes.draw(control, chart, span, margin)
	# each series in the order given, so its place in the set is its dash and its marker
	for index: int in range(chart["series"].size()):
		var one: Dictionary = chart["series"][index]
		var places := reached(_placed(one["points"], span, control.size, margin), drawn["reach"])
		if one.has("under") and places.size() >= 2:
			control.draw_colored_polygon(area(places, _placed(one["under"], span, control.size, margin)), control.get_theme_color(&"fill"))
		_dashed(control, places, dash_of(index), ink)
		# a marker at every point reached
		for at: Vector2 in places:
			_marker(control, at, marker_of(index), ink)


## Points of the data where they land on this canvas.
static func _placed(points: Array, span: Rect2, size: Vector2, margin: Vector4) -> PackedVector2Array:
	var places := PackedVector2Array()
	# every point, landed inside the margin
	for point: Vector2 in points:
		places.append(ChartAxes.to_canvas(point, span, size, margin))
	return places


## The legend's mark for one series: a sample of its line with its marker
## on it, the same as the plot draws, over a sample of its area if it fills.
static func _paint_sample(control: Control, mark: Variant) -> void:
	if mark == null:
		return
	var middle := control.size.y / 2.0
	var ink := control.get_theme_color(&"line")
	if mark["fills"]:
		control.draw_rect(Rect2(0.0, middle, control.size.x, middle), control.get_theme_color(&"fill"))
	var pattern: Array[float] = []
	pattern.assign(mark["dash"])
	_dashed(control, PackedVector2Array([Vector2(0.0, middle), Vector2(control.size.x, middle)]), pattern, ink)
	_marker(control, Vector2(control.size.x * 0.5, middle), mark["marker"], ink)


## A run of points joined in this pattern: unbroken where the pattern has
## no gap, else dash by dash. One point alone is no line at all.
static func _dashed(control: Control, places: PackedVector2Array, pattern: Array[float], ink: Color) -> void:
	if places.size() < 2:
		return
	var width := float(control.get_theme_constant(&"line_width"))
	if pattern[1] == 0.0:
		control.draw_polyline(places, ink, width)
		return
	# each leg of the run, the pattern starting again at every corner
	for index: int in range(places.size() - 1):
		_dash(control, places[index], places[index + 1], pattern, ink, width)


## One leg drawn in the pattern: a dash, a gap, on to the end of it.
static func _dash(control: Control, from: Vector2, to: Vector2, pattern: Array[float], ink: Color, width: float) -> void:
	var span := from.distance_to(to)
	# two readings at the same place: no direction to walk, and nothing to draw
	if span == 0.0:
		return
	var way := (to - from) / span
	var at := 0.0
	# along the leg, a dash then a gap, until its end
	while at < span:
		var end := minf(at + pattern[0], span)
		control.draw_line(from + way * at, from + way * end, ink, width)
		at = end + pattern[1]


## A series' marker at a point: a shape, so it tells its series apart
## where a colour cannot.
static func _marker(control: Control, at: Vector2, marker: StringName, ink: Color) -> void:
	var radius := float(control.get_theme_constant(&"marker_radius"))
	var wide := radius * 1.3
	match marker:
		&"Square": control.draw_rect(Rect2(at - Vector2(radius, radius), Vector2(radius, radius) * 2.0), ink)
		&"Diamond": control.draw_colored_polygon(PackedVector2Array([at + Vector2(0.0, -wide), at + Vector2(wide, 0.0), at + Vector2(0.0, wide), at + Vector2(-wide, 0.0)]), ink)
		&"Triangle": control.draw_colored_polygon(PackedVector2Array([at + Vector2(0.0, -wide), at + Vector2(wide, radius), at + Vector2(-wide, radius)]), ink)
		_: control.draw_circle(at, radius, ink)
