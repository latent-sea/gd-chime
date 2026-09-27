extends "controller.gd"

const Commands := preload("commands.gd")
const Narrowing := preload("narrowing.gd")
const PackedRows := preload("packed_rows.gd")
const RowQuery := preload("row_query.gd")
const QueriedRows := preload("queried_rows.gd")
const QueryPacing := preload("query_pacing.gd")
const Motion := preload("motion.gd")
const FilterSet := preload("components/recipes/filter_set.gd")

## The filters a reader builds over a queried view (queried_rows.gd): the
## model the filter-set recipe (filter_set.gd) reads and presses, each chip
## on becoming a clause of the view's query (row_query.gd).
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE PROPERTIES are the columns a reader may filter by, [{name, type}],
## the type the filter-set's: a number, a date, a list - its values the
## words its column holds - or a find, letters within them. A chip is
## {id, words, on}; its words say the rule, the property and the value data
## and the comparison a phrase. Every chip on is one clause; the clauses go
## to the view at once, as a chip is built, turned or removed, and the view
## answers the query off the frame. The count is the rows the view keeps.
##
## A value being typed is asked too, beside the chips, but at the pace of
## the typing (query_pacing.gd): the line is kept at every keystroke and its
## query goes once the typing settles; Enter, a pick, a turn or a removal
## sends at once whatever was waiting. A line not yet its property's kind -
## "19" on the way to a date - is left out of the query rather than refused.
##
## It answers the filter-set's actions under its own names: NARROWS_PROPERTIES
## and NARROWS_VALUES are its two narrowings' typing, each narrowing in a
## region of its own; PICKS_PROPERTY, PICKS_COMPARISON, PICKS_VALUE and
## SETS_VALUE build a filter, the last refused when the line is not the
## property's kind; TYPES_LINE is the value's line typed; TOGGLES and
## REMOVES turn and take away a chip by id.
##
## Deliberately absent: editing a chip in place - removed and built again -
## and an OR between chips.

const NARROWS_PROPERTIES := &"narrows_the_properties"
const PICKS_PROPERTY := &"picks_a_property"
const PICKS_COMPARISON := &"picks_a_comparison"
const NARROWS_VALUES := &"narrows_the_values"
const PICKS_VALUE := &"picks_a_value"
const SETS_VALUE := &"sets_the_value"
const TYPES_LINE := &"types_the_line"
const TOGGLES := &"toggles_a_filter"
const REMOVES := &"removes_a_filter"
## The filter-set's names for these actions, as its recipe asks for them.
const ACTIONS := {"types_property": NARROWS_PROPERTIES, "picks_property": PICKS_PROPERTY, "picks_comparison": PICKS_COMPARISON, "types_value": NARROWS_VALUES, "picks_value": PICKS_VALUE, "sets_value": SETS_VALUE, "types_line": TYPES_LINE, "toggles": TOGGLES, "removes": REMOVES}
## Each comparison's test, by the filter-set's words for it.
const TESTS := {"is over": RowQuery.OVER, "is under": RowQuery.UNDER, "is exactly": RowQuery.EXACTLY, "is before": RowQuery.UNDER, "is after": RowQuery.OVER, "is": RowQuery.IS, "is not": RowQuery.IS_NOT, "includes": RowQuery.INCLUDES, "does not include": RowQuery.EXCLUDES}

var _view: QueriedRows
var _properties := value([])  # {name, type}, in the order offered
var _chips := value([])  # {id, words, on, clause}
var _building := value(null)  # {property, comparison, line typed} so far, or none
var _next_id: int = 1
var _by_property: Narrowing
var _by_value: Narrowing
var _pacing: QueryPacing


func _init(chimes: Chimes, view: QueriedRows, properties: Array, motion: Motion) -> void:
	super(chimes)
	_view = view
	_properties.set_value(properties)
	_by_property = Narrowing.new(chimes, Bound.new(get_property_options))
	_by_value = Narrowing.new(chimes, Bound.new(get_value_options))
	_pacing = QueryPacing.new(chimes, view, motion)
	add_child(_by_property)
	add_child(_by_value)
	add_child(_pacing)


func get_properties() -> Array:
	return _properties.read()


func get_chips() -> Array:
	return _chips.read().map(func(chip: Dictionary) -> Dictionary: return {"id": chip["id"], "words": chip["words"], "on": chip["on"]})


func get_building() -> Variant:
	return _building.read()


## How many rows the view keeps.
func get_count() -> Variant:
	return _view.get_kept()


func get_property_narrowing() -> Object:
	return _by_property


func get_value_narrowing() -> Object:
	return _by_value


## The pace its queries go at: whether one waits for the typing to settle.
func get_pacing() -> QueryPacing:
	return _pacing


## Every property, by name, to type against.
func get_property_options() -> Array:
	return _properties.read().map(func(property: Dictionary) -> Dictionary: return {"value": property["name"], "words": String(property["name"])})


## The words the list property being built holds, to type against; none until one is.
func get_value_options() -> Array:
	if _building.read() == null or _type() != FilterSet.A_LIST:
		return []
	return Array(_view.get_rows().words(_building.read()["property"])).map(func(word: String) -> Dictionary: return {"value": word, "words": word})


## A line that is not a number for a number, or a date for a date, is refused.
func would(action: StringName, payload: Dictionary) -> Phrase:
	if action != SETS_VALUE or _building.read() == null:
		return null
	return _refused(String(payload["line"]).strip_edges())


## Why a line typed for the property being built is not its kind, or nothing.
func _refused(line: String) -> Phrase:
	if _type() == FilterSet.A_NUMBER and not line.is_valid_float():
		return Phrase.with("%s is not a number", [line])
	if _type() == FilterSet.A_DATE and not PackedRows.is_date(line):
		return Phrase.with("%s is not a date written year-month-day", [line])
	return null


func told(action: StringName, payload: Dictionary) -> Phrase:
	match action:
		NARROWS_PROPERTIES: return _by_property.told(action, payload)
		NARROWS_VALUES: return _by_value.told(action, payload)
		PICKS_PROPERTY: _building.set_value({"property": StringName(payload["value"])})
		PICKS_COMPARISON: _building.set_value(_building.read().merged({"comparison": payload["comparison"]}, true))
		PICKS_VALUE: _built(payload["value"])
		SETS_VALUE: _built(String(payload["line"]).strip_edges())
		TYPES_LINE: _typed(String(payload["line"]).strip_edges())
		TOGGLES:
			# every chip, the one pressed turned
			for chip: Dictionary in _chips.read():
				if chip["id"] == payload["id"]:
					chip["on"] = not chip["on"]
			_chips.set_value(_chips.read())
			_pacing.ask_now(_on())
		REMOVES:
			_chips.set_value(_chips.read().filter(func(chip: Dictionary) -> bool: return chip["id"] != payload["id"]))
			_pacing.ask_now(_on())
	return null


## Other properties to filter by - other rows' columns - every chip and
## the filter being built let go, and nothing typed left waiting to be asked.
func replace(properties: Array) -> void:
	_properties.set_value(properties)
	_chips.set_value([])
	_building.set_value(null)
	_pacing.forget()


## The filter built so far finished with its value: a chip, on, its clause asked at once.
func _built(value: String) -> void:
	var property: StringName = _building.read()["property"]
	var comparison: String = _building.read()["comparison"]
	var words := Phrase.joined([String(property), " ", Phrase.within(comparison), " ", value])
	_chips.set_value(_chips.read() + [{"id": _next_id, "words": words, "on": true, "clause": _clause(value)}])
	_next_id += 1
	_building.set_value(null)
	_pacing.ask_now(_on())


## A line typed for the filter being built, as it stands: kept, and its
## clause asked beside the chips once the typing settles - left out while
## the line is not yet the property's kind, or holds nothing.
func _typed(line: String) -> void:
	_building.set_value(_building.read().merged({"line": line}, true))
	var trying: Array = [] if line == "" or _refused(line) != null else [_clause(line)]
	_pacing.ask_soon(_on() + trying)


## The clause the property being built makes with this value.
func _clause(value: String) -> Dictionary:
	var read: Variant = [value] if _type() == FilterSet.A_LIST else value if _type() == FilterSet.A_FIND else PackedRows.day_of(value) if _type() == FilterSet.A_DATE else value.to_float()
	return {"column": _building.read()["property"], "test": TESTS[_building.read()["comparison"]], "value": read}


## Every chip on, as a clause.
func _on() -> Array:
	return _chips.read().filter(func(chip: Dictionary) -> bool: return chip["on"]).map(func(chip: Dictionary) -> Dictionary: return chip["clause"])


## The type of the property being built.
func _type() -> StringName:
	return _properties.read().filter(func(property: Dictionary) -> bool: return property["name"] == _building.read()["property"])[0]["type"]


## Every action this model is told: the filter-set's, by the names its recipe asks.
func answers() -> Array[StringName]:
	var told: Array[StringName] = []
	told.assign(ACTIONS.values())
	return told
