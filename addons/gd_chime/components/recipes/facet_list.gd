extends RefCounted

const Themes := preload("../../theme.gd")
const Ui := preload("../primitives/ui.gd")
const Options := preload("../primitives/options.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Filters := preload("../../filters.gd")
const FilterSet := preload("filter_set.gd")

## The facets of a collection drawn: each column its title over its values,
## each value a press showing how many it would keep; the stretch a range
## slider; and the chips of what narrows it. It is a VIEW over the one
## filter model (filters.gd) and holds nothing itself.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A VALUE is a press of the filters' TOGGLES carrying {column, value},
## drawn picked while it is - a mark of shape the look gives it, never a hue
## alone - and inert with the reason on its face where it would keep
## nothing, which the filters refuse. Its count stands beside its words, and
## says nothing before the counts land. A column may give each value a mark
## before its words - a colour's swatch - a template of the caller's handed
## a bound value of the value.
##
## The values of a column wrap onto more lines where they do not fit, so a
## narrow drawer holds them as a wide rail does. Nothing here holds a value:
## all of it reads the filters.
##
## Deliberately absent: a column's values folded away past so many.

## A column's column, its values' wrapping row, a value's press and its look while picked.
const FACET := &"Facet"
const VALUES := &"FacetValues"
const VALUE := &"FacetValue"
const PICKED := &"FacetPicked"
## The words of a value's count.
const COUNT := &"FacetCount"
## A value's mark drawn as a picture - a colour's swatch - a lazy picture of this style.
const SWATCH := &"FacetSwatch"
## A column's ground, and its title's words.
const CELL := &"FacetCell"
const HEADING := &"FacetTitle"


## Every column titled, in the order the titles are given - {column: phrase}
## - each value marked where marks gives a template - {column: Callable(bound
## value of the value) -> Desc}.
static func make(ui: Ui, filters: Filters, titles: Dictionary, marks: Dictionary = {}) -> Array:
	return titles.keys().map(func(column: StringName) -> Desc: return one(ui, filters, column, {title = titles[column], mark = marks.get(column)}))


## One column: its title over its values. Its options: title, the words
## over the values, and mark, a template drawing one value's own mark.
const ONE_OPTIONS: Array[String] = ["title", "mark"]

static func one(ui: Ui, filters: Filters, column: StringName, options: Dictionary = {}) -> Desc:
	Options.checked("a facet", options, ONE_OPTIONS)
	var title: Variant = options["title"]
	var mark: Variant = options.get("mark")
	var values: Bound = ui.bound(func() -> Array: return filters.get_values(column))
	var option := func(value: Bound) -> Desc: return _value(ui, column, value, mark)
	return ui.surface(CELL, [ui.column([ui.text(title, HEADING), ui.each_across(values, option, func(value: Dictionary) -> String: return value["value"], VALUES)], FACET)])


## The stretch: its title over a range slider across the filters' bounds, by
## this step, its stretch said by the caller's words. Its options: step, how
## far one move of an end goes, and words, which writes a stretch's two ends.
const RANGE_OPTIONS: Array[String] = ["step", "words"]

static func range_of(ui: Ui, filters: Filters, title: Variant, options: Dictionary = {}) -> Desc:
	Options.checked("a range facet", options, RANGE_OPTIONS)
	var step: float = options["step"]
	var words: Callable = options["words"]
	var bounds := filters.get_bounds()
	return ui.surface(CELL, [ui.column([ui.text(title, HEADING), ui.range_slider(Filters.SETS_RANGE, ui.bound(filters.get_range), {minimum = bounds.x, maximum = bounds.y, step = step, words = words})], FACET)])


## The chips of what narrows it, each turned off on its body and taken away on its x, and how many it keeps.
static func chips(ui: Ui, filters: Filters) -> Desc:
	return FilterSet.chips(ui, filters, {"toggles": Filters.TURNS, "removes": Filters.REMOVES})


## A value's press: its mark, its words and its count, drawn picked while it is.
static func _value(ui: Ui, column: StringName, value: Bound, mark: Variant) -> Desc:
	var carried: Bound = value.map(func(one_value: Variant) -> Dictionary: return {} if one_value == null else {"column": column, "value": one_value["value"]})
	var words := ui.text(value.map(func(one_value: Variant) -> String: return "" if one_value == null else one_value["value"]), Themes.FACE)
	var count := ui.text(value.map(func(one_value: Variant) -> String: return "" if one_value == null or one_value["count"] == null else str(one_value["count"])), COUNT).hides_empty()
	var worn: Bound = value.map(func(one_value: Variant) -> StringName: return PICKED if one_value != null and one_value["picked"] else VALUE)
	return ui.pressable(Filters.TOGGLES, carried, [ui.column([ui.row(([(mark as Callable).call(value)] if mark != null else []) + [words, count]), ui.reason(Themes.REASON)])], worn)
