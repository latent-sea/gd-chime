extends RefCounted

const Themes := preload("../../theme.gd")
const Ui := preload("../primitives/ui.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const TypeAhead := preload("type_ahead.gd")
const Chip := preload("chip.gd")
const Phrase := preload("../../phrase.gd")

## Filters: filters the reader BUILDS over a long list, each becoming a
## toggle - a BUILDER of property, comparison and value with a live match
## count, CHIPS (chip.gd) each toggling on its body and removing on its X, and a
## MATCH COUNT. The property's type decides the rest: a number offers is
## over / is under / is exactly and takes a value; a date is before / is
## after and takes one written year-month-day; a list offers is / is not
## and picks from the values there are; a find offers includes / does not
## include over names; a boolean offers its two words and no value.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A filter selects; it is not the rule. The filters are a MODEL's: it
## reads the chips, [{id, words, on}], the building - {property,
## comparison} so far - and the count; it holds the two NARROWINGS the
## pickers type against, one over the properties and one over the values
## of the property being built; it answers PICKS_PROPERTY {value},
## PICKS_COMPARISON {comparison}, PICKS_VALUE {value}, SETS_VALUE {line},
## TOGGLES {id} and REMOVES {id}; and it refuses what the type does not
## offer. There is no editing: a filter is removed and rebuilt.
##
## The property and the list's values are TYPE-AHEAD pickers (type_ahead.gd),
## never a row of every option and never a drop-down, because a long list
## is filtered on dozens of properties whose values run to hundreds. The
## comparisons stay a row: a type offers two or three, and they are the
## words of the rule, read together. Nothing here holds an option: both
## pickers read the narrowings' sources. A comparison goes in English both
## to the text, which says it in the language on as it draws, and to the
## model, for which the English is its key. Being words of the rule, said
## between its property and its value - "risk is over 1000" - they are
## written lowercase, said only within it (phrase.gd).

const A_NUMBER := &"number"
const A_DATE := &"date"
const A_LIST := &"list"
const A_FIND := &"find"
const A_BOOLEAN := &"boolean"
const COMPARISON_WORDS_WITHIN := {A_NUMBER: ["is over", "is under", "is exactly"], A_DATE: ["is before", "is after"], A_LIST: ["is", "is not"], A_FIND: ["includes", "does not include"], A_BOOLEAN: ["is true", "is false"]}


## The filter-set over this model's actions, named as {types_property,
## picks_property, picks_comparison, types_value, picks_value, sets_value,
## toggles, removes}, and types_line for a model that follows the value's
## line as it is typed (row_filters.gd): the builder over the chips.
static func make(ui: Ui, filters: Object, actions: Dictionary, style: StringName = &"FilterSet") -> Desc:
	return ui.column([builder(ui, filters, actions), chips(ui, filters, actions)], style)


## The builder alone: the property, its comparisons and its value - for a
## screen that raises it apart from the chips, where it has the room.
static func builder(ui: Ui, filters: Object, actions: Dictionary) -> Desc:
	var building: Bound = ui.bound(filters.get_building)
	var properties := TypeAhead.make(ui, filters.get_property_narrowing(), actions["types_property"], actions["picks_property"])
	var comparisons := ui.each_across(building.map(func(so_far: Variant) -> Array: return _comparisons(filters, so_far)), func(comparison: Bound) -> Desc: return _picker(ui, actions["picks_comparison"], comparison), func(comparison: String) -> String: return comparison)
	# the value's line: Enter sets it; each keystroke is told too when the model follows the typing
	var line := ui.field(actions["sets_value"], &"Field", {"changes": actions.get("types_line", &"")})
	var typed := ui.when(building.map(func(so_far: Variant) -> bool: return _asked(filters, so_far) in [A_NUMBER, A_DATE, A_FIND]), ui.row([line.grow()]))
	var picked := ui.when(building.map(func(so_far: Variant) -> bool: return _asked(filters, so_far) == A_LIST), TypeAhead.make(ui, filters.get_value_narrowing(), actions["types_value"], actions["picks_value"]))
	return ui.row([properties.grow(), comparisons.grow(), ui.column([typed, picked]).grow()], &"Builder")


## The chips alone, each toggled and removed, and how many match.
static func chips(ui: Ui, filters: Object, actions: Dictionary) -> Desc:
	var laid := ui.each_across(ui.bound(filters.get_chips), func(chip: Bound) -> Desc: return _chip(ui, actions, chip), func(chip: Dictionary) -> Variant: return chip["id"], &"Chips")
	var count := ui.text(ui.bound(filters.get_count).map(func(matched: Variant) -> Variant: return "" if matched == null else TypeAhead.counted(matched)), Themes.REASON)
	return ui.row([laid.grow(4.0), count.grow()], &"Chips")


## One comparison to pick: a pressable carrying the words it picks.
static func _picker(ui: Ui, action: StringName, words: Bound) -> Desc:
	var carried: Bound = words.map(func(word: Variant) -> Dictionary: return {} if word == null else {"comparison": word})
	return ui.pressable(action, carried, [ui.text(words.map(func(word: Variant) -> Variant: return "" if word == null else Phrase.within(word)), Themes.REASON)], &"Chip")


## A filter's chip (chip.gd): its words, on or off, toggled on its body and
## removed on its x, each press carrying which filter.
static func _chip(ui: Ui, actions: Dictionary, chip: Bound) -> Desc:
	var id: Bound = chip.map(func(item: Variant) -> Dictionary: return {"id": item["id"] if item != null else null})
	return Chip.make(ui, chip.field("words"), chip.field("on"), id, {toggles = actions["toggles"], removes = actions["removes"]})


## The comparisons the property picked so far offers.
static func _comparisons(filters: Object, so_far: Variant) -> Array:
	if so_far == null or so_far.get("property", "") == "":
		return []
	return COMPARISON_WORDS_WITHIN.get(_type_of(filters, so_far), [])


## The type whose value is being asked for now: none until a comparison is
## picked, and none for a boolean, which asks for no value at all.
static func _asked(filters: Object, so_far: Variant) -> StringName:
	if so_far == null or so_far.get("comparison", "") == "":
		return &""
	var type := _type_of(filters, so_far)
	return &"" if type == A_BOOLEAN else type


static func _type_of(filters: Object, so_far: Dictionary) -> StringName:
	var properties: Array = filters.get_properties()
	for property: Dictionary in properties:
		if property["name"] == so_far["property"]:
			return property["type"]
	return &""
