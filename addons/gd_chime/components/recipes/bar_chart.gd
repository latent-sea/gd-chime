extends RefCounted

const Themes := preload("../../theme.gd")
const Ui := preload("../primitives/ui.gd")
const Options := preload("../primitives/options.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Formats := preload("../../formats.gd")
const LoadedOrEmpty := preload("loaded_or_empty.gd")

## A bar chart: one bar a thing - a region, a cause - its length its value
## against the longest, its name before it and its figure after, so the
## largest reads at a glance and every figure can still be read exactly.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE BARS are a model's bound array, [{key, now, before}] (measures.gd's
## splits), kept by key: a filter moving changes their lengths, never the
## pieces, so the focus stays on the bar the reader is on. Each fills to
## its new length rather than jumping (eased.gd).
##
## EVERY BAR IS A PRESS of the action given, carrying {"picked": its key} -
## the payload a region pressed on a map carries too, so a bar and the map
## filter a collection alike (filters.gd, picks_of) - walked by the keys and
## the pad like any column of presses, and drawn CURRENT while its key is
## the one picked, a look's shape and never a hue alone. Given actions to
## offer, each bar opens a context menu of them on its key (menu_target):
## the rows behind it, say.
##
## THE STRETCH BEFORE, while the dashboard compares, is a tick across each
## bar at the length it had then - a shape in the chart's "link" ink, over
## the bar's "line" - and a key under the bars says what the tick is.
##
## Loading until the bars land, and the caller's words when every bar is
## nothing (loaded_or_empty.gd).

const BARS := &"BarChart"
## One bar's press, its drawing, and its words: its name and its figure.
const BAR := &"BarChartBar"
const TRACK := &"BarChartTrack"
const TEXT := &"BarChartWords"
## The share of a bar's line its name takes.
const NAME_SHARE := 0.3
## Which of a bar's figures are drawn: its now alone, or its now beside the stretch before while the chart compares.
const NOW: Array[String] = ["now"]
const NOW_AND_BEFORE: Array[String] = ["now", "before"]


## The chart over a bound [{key, now, before}]: a bar per thing, each a
## press of the action carrying its key. Its options: picked, a bound value
## the bar of whose key is drawn current; comparing, while which the
## stretch before is ticked, and before_words, what that stretch is called;
## unit, the function writing a figure in its unit; says_empty, the words
## over nothing; offers, the actions a bar's context menu holds; places,
## the decimal places a figure is written to; and style.
const OPTIONS: Array[String] = ["picked", "comparing", "before_words", "unit", Options.SAYS_EMPTY, "offers", Options.PLACES, Options.STYLE]

static func make(ui: Ui, action: StringName, bars: Bound, options: Dictionary = {}) -> Desc:
	Options.checked("a bar chart", options, OPTIONS)
	var picked: Bound = options["picked"]
	var comparing: Bound = options["comparing"]
	var before_words: Bound = options["before_words"]
	var unit: Callable = options["unit"]
	var says_empty: Variant = options[Options.SAYS_EMPTY]
	var offers: Array = options.get("offers", [])
	var places: int = options.get(Options.PLACES, 0)
	var style: StringName = options.get(Options.STYLE, BARS)
	var longest: Bound = Bound.both(bars, comparing, func(all: Variant, compares: Variant) -> float: return longest(all, NOW_AND_BEFORE if compares else NOW))
	var bar := func(item: Bound) -> Desc: return _bar(ui, action, item, longest, picked, comparing, unit, offers, places)
	var laid := ui.column([ui.each(bars, bar, func(one: Dictionary) -> Variant: return one["key"], style), ui.when(comparing, ui.row([ui.canvas(_paint_key, null, TRACK).basis(0.06), ui.text(before_words, Themes.REASON)]))])
	var landed: Bound = bars.map(func(all: Variant) -> bool: return all != null)
	var empty: Bound = bars.map(func(all: Variant) -> bool: return all != null and all.all(func(one: Dictionary) -> bool: return one["now"] == 0.0))
	return LoadedOrEmpty.over(ui, landed, empty, laid, {says_empty = says_empty})


## The longest a bar is drawn against: the most any bar reaches in these of
## its figures - NOW alone, or NOW_AND_BEFORE while the chart compares -
## never nothing.
static func longest(all: Variant, figures: Array) -> float:
	var most := 0.0
	# every bar, for the most any reaches in the figures measured
	for one: Dictionary in ([] if all == null else all):
		# each figure of this bar that is drawn
		for figure: String in figures:
			most = maxf(most, one[figure])
	return maxf(most, 1.0)


## A bar's lengths as shares of the longest: {now, before, compares}, said
## in the same figures the longest was measured in.
static func shares(one: Variant, longest: float, figures: Array) -> Variant:
	if one == null:
		return null
	return {"now": one["now"] / longest, "before": one["before"] / longest, "compares": figures.has("before")}


## One bar: its name, its length drawn, its figure; a press of its key.
static func _bar(ui: Ui, action: StringName, item: Bound, longest: Bound, picked: Bound, comparing: Bound, unit: Callable, offers: Array, places: int) -> Desc:
	var key: Bound = item.map(func(one: Variant) -> Variant: return null if one == null else one["key"])
	var drawn: Bound = Bound.all([item, longest, comparing], func(one: Variant, most: float, compares: Variant) -> Variant: return shares(one, most, NOW_AND_BEFORE if compares else NOW))
	var now: Bound = ui.eased(drawn.map(func(lengths: Variant) -> float: return 0.0 if lengths == null else lengths["now"]))
	var painted: Bound = Bound.both(drawn, now, func(lengths: Variant, reached: float) -> Variant: return null if lengths == null else {"now": reached, "before": lengths["before"], "compares": lengths["compares"]})
	var figure: Bound = Formats.quantity(item.map(func(one: Variant) -> Variant: return null if one == null else one["now"]), unit, places)
	var line := ui.row([ui.text(key, TEXT).basis(NAME_SHARE), ui.canvas(_paint_bar, painted, TRACK).grow(), ui.text(figure, TEXT)])
	var payload: Bound = key.map(func(named: Variant) -> Dictionary: return {"picked": named})
	var pressed := ui.pressable(action, payload, [line], BAR).current_while(Bound.both(key, picked, func(named: Variant, chosen: Variant) -> bool: return named != null and named == chosen))
	return pressed if offers.is_empty() else ui.menu_target(offers, payload, [pressed])


## A bar: its length filled in the line's ink along the middle of its
## track, as thick as the look's share of it, and, comparing, a tick
## across it where the stretch before reached.
static func _paint_bar(control: Control, lengths: Variant) -> void:
	if lengths == null:
		return
	var thick := control.size.y * control.get_theme_constant(&"thickness") / 1000.0
	var top := (control.size.y - thick) / 2.0
	control.draw_rect(Rect2(0.0, top, control.size.x * lengths["now"], thick), control.get_theme_color(&"line"))
	if lengths["compares"]:
		var at: float = control.size.x * lengths["before"]
		control.draw_line(Vector2(at, 0.0), Vector2(at, control.size.y), control.get_theme_color(&"link"), float(control.get_theme_constant(&"tick_width")))


## The key's sample of the tick: what the stretch before is drawn as.
static func _paint_key(control: Control, _nothing: Variant) -> void:
	var at := control.size.x / 2.0
	control.draw_line(Vector2(at, 0.0), Vector2(at, control.size.y), control.get_theme_color(&"link"), float(control.get_theme_constant(&"tick_width")))
