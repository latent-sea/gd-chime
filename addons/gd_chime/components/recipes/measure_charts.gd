extends RefCounted

const Ui := preload("../primitives/ui.gd")
const Options := preload("../primitives/options.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Measures := preload("../../measures.gd")
const LineChart := preload("line_chart.gd")
const LoadedOrEmpty := preload("loaded_or_empty.gd")

## A dashboard's figures over its days as charts: a figure's TREND - its
## days as an area, the stretch before laid over it while the dashboard
## compares - and a spread's BAND - the middle half of each day's values as
## an area, their middle as a line through it. Each is a line chart
## (line_chart.gd) over a figure of the measures (measures.gd), with its
## loading and empty states (loaded_or_empty.gd).
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A day is placed by how many days it is before the stretch's last - the
## last is 0, the one before -1 - so a stretch and the one before it, laid
## on the same axis, line up day by day. A day with nothing, a mean or
## spread of no rows, is left out of its line rather than drawn as none.
##
## Every word is the caller's, and so is whether the dashboard compares:
## what the figure is, what the axes are, what an empty chart says, and what
## the stretch before is called are all bound values handed in, as a KPI
## card and a bar chart take them (kpi_card.gd, bar_chart.gd). Nothing here
## reads a filter.

const TREND := &"LineChart"


## A figure's days as an area over its stretch, and, while comparing, the
## stretch before as a line over it.
## Its options, the first four required, since a chart says what it shows:
## says, what the chart is called; x_words and y_words, what the axes are
## called; says_empty, the words over nothing; comparing, a bound value
## while which the stretch before is drawn - given none, it never is - and
## before_words, a bound value of what that stretch is called.
const OPTIONS: Array[String] = ["says", "x_words", "y_words", Options.SAYS_EMPTY, "comparing", "before_words"]

static func trend(ui: Ui, measures: Measures, figure: StringName, options: Dictionary) -> Desc:
	Options.checked("a trend chart", options, OPTIONS)
	var says: Variant = options["says"]
	var x_words: Variant = options["x_words"]
	var y_words: Variant = options["y_words"]
	var says_empty: Variant = options[Options.SAYS_EMPTY]
	var comparing: Bound = options.get("comparing", Bound.constant(false))
	var drawn: Bound = Bound.all([ui.bound(measures.get_figures), comparing, options.get("before_words", Bound.constant(null))], func(figures: Variant, compared: bool, before: Variant) -> Variant: return null if figures == null else _trend(figures[figure], compared, says, before, x_words, y_words))
	return _stated(ui, measures, figure, drawn, says_empty)


## A spread's days as its middle half, an area, and its middle, a line.
## Its options, every one required: says_middle and says_half, what the two
## lines are called; x_words and y_words, what the axes are called; and
## says_empty.
const BAND_OPTIONS: Array[String] = ["says_middle", "says_half", "x_words", "y_words", Options.SAYS_EMPTY]

static func band(ui: Ui, measures: Measures, figure: StringName, options: Dictionary) -> Desc:
	Options.checked("a band chart", options, BAND_OPTIONS)
	var says_middle: Variant = options["says_middle"]
	var says_half: Variant = options["says_half"]
	var x_words: Variant = options["x_words"]
	var y_words: Variant = options["y_words"]
	var says_empty: Variant = options[Options.SAYS_EMPTY]
	var drawn: Bound = ui.bound(measures.get_figures).map(func(figures: Variant) -> Variant: return null if figures == null else {"series": [{"name": says_half, "points": days_series(figures[figure]["days"], 2), "under": days_series(figures[figure]["days"], 0)}, {"name": says_middle, "points": days_series(figures[figure]["days"], 1)}], "x_words": x_words, "y_words": y_words})
	return _stated(ui, measures, figure, drawn, says_empty)


## A figure's days as points: each day's value - or, given a part, that part
## of a spread's day - at how many days it is before the last; a day of
## nothing left out.
static func days_series(days: Array, part: int = -1) -> Array:
	var points: Array = []
	# every day, placed back from the last
	for at: int in days.size():
		if days[at] != null:
			points.append(Vector2(at - days.size() + 1, days[at][part] if part >= 0 else days[at]))
	return points


## A trend's chart: the stretch as an area down to nothing, and, comparing, the stretch before.
static func _trend(taken: Dictionary, comparing: bool, says: Variant, before: Variant, x_words: Variant, y_words: Variant) -> Dictionary:
	var now := days_series(taken["days"])
	var series: Array = [{"name": says, "points": now, "under": now.map(func(point: Vector2) -> Vector2: return Vector2(point.x, 0.0))}]
	if comparing:
		series.append({"name": before, "points": days_series(taken["days_before"])})
	return {"series": series, "x_words": x_words, "y_words": y_words}


## A chart with its states: loading until the figures land, and the words
## given while the figure has no day with anything in it.
static func _stated(ui: Ui, measures: Measures, figure: StringName, drawn: Bound, says_empty: Variant) -> Desc:
	var empty: Bound = ui.bound(measures.get_figures).map(func(figures: Variant) -> bool: return figures != null and not figures[figure]["days"].any(func(day: Variant) -> bool: return day != null and (day is Array or day > 0.0)))
	return LoadedOrEmpty.over(ui, ui.bound(measures.get_landed), empty, LineChart.make(ui, drawn, TREND), {says_empty = says_empty})
