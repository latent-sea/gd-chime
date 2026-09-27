extends "controller.gd"

const Facets := preload("facets.gd")
const FilterQuery := preload("filter_query.gd")
const Stretch := preload("stretch.gd")
const Options := preload("components/primitives/options.gd")

## The one filter model: what a reader has narrowed a collection to, over
## packed rows (packed_rows.gd) and over ordinary items alike, declared
## once as a spec.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE SPEC NAMES THE COLUMNS AND WHAT MAY BE DONE WITH EACH:
##
##     Filters.new(chimes, {search = [&"title", &"person"], one_of = &"person", any_of = &"labels"})
##
## search, the columns a line of letters is looked for in, SEARCHES {line};
## one_of, a column at most one value is picked from, PICKS {column, value}
## - nothing picked for an empty value; any_of, a column any number are
## picked from, TOGGLES {column, value}; between, {column, bounds, words}, a
## number column held within a stretch, SETS_RANGE {value}; dates, {column,
## now, presets, starts}, a column of hours held within a stretch of days,
## which stretch.gd holds and answers for; on_a_drawing, the columns whose
## value is picked by a press carrying the value and nothing else - a map's
## region, a chart's bar ({picked}, pinned.gd) - each answering an action of
## its own, picks_of(column), which toggles that value as TOGGLES does. The
## first three take one column or several. OVER PACKED ROWS, search names
## ONE column: clauses narrow each other, so a search across two would be an
## AND where a reader means an OR.
##
## IT IS READ TWO WAYS, and they say the same thing, because one file says
## what the spec means (filter_query.gd): get_clauses(), the query over
## packed rows, handed as the filters move to whatever asks - the view's own
## ask, or the pace a reader types at - given here as asks; and keeps(item),
## the test over ordinary items, read through get_keeps() as a value, so a
## lane follows the filters and no card of it is built again (lane.gd). A
## ROLLUP IS HANDED THE STRETCH APART (get_rollup), because each measure of
## a dashboard takes its own column of time within it (rollup.gd).
##
## CHIPS say what narrows it: each value picked, the stretch once narrowed,
## the line once typed - each turned off on its body, TURNS {id}, kept but
## applied to nothing, and taken away on its x, REMOVES {id}. CLEARS takes them all, refused while there is nothing to take.
##
## THE COUNTS ARE A VIEW OVER IT (facets.gd), made here from over, the rows,
## and on, the pool: how many things each value of each column would keep,
## worked out off the frame as the filters move. A value that would keep
## nothing is refused while it is not picked, "Nothing would match", so a
## press of it is inert with the reason on its face; before the first land, a count is null and whoever draws it says nothing.
##
## Deliberately absent: an OR between columns, more than one stretch of
## each kind, and any hold on the things - the rows are handed in to be
## counted and read for a column's values, never kept up to date.

const SEARCHES := &"searches_for"
const PICKS := &"picks_a_value"
const TOGGLES := &"toggles_a_value"
const SETS_RANGE := &"sets_the_range"
const TURNS := &"turns_a_chip"
const REMOVES := &"removes_a_chip"
const CLEARS := &"clears_the_filters"
const COMMANDS: Array[StringName] = [SEARCHES, PICKS, TOGGLES, SETS_RANGE, TURNS, REMOVES, CLEARS]
## What a spec may declare, and what a filters takes beside it.
const SPEC: Array[String] = ["search", "one_of", "any_of", "between", "dates", "on_a_drawing"]
const OPTIONS: Array[String] = ["over", "on", "asks"]

## The counts beside each value, or none where no rows were given to count.
var facets: Facets
## The stretch of days the date column stands in, or none where no dates were declared.
var stretch: Stretch
var _spec: Dictionary  # the spec sorted out: searched, one_of, any_of, between, dates
var _asks: Callable  # what the clauses go to as they move, or nothing
var _picks: Dictionary  # the action a column picked on a drawing answers -> that column
var _picked := value({})  # column -> the values picked, in the order picked
var _off := value({})  # the ids of the chips turned off, used as a set
var _range := value(Vector2.ZERO)
var _line := value("")


## The spec, and where its answers go: over, the rows counted and read for
## a column's values; on, the pool the counts run off the frame on; asks,
## what a query's clauses go to as the filters move.
func _init(chimes: Chimes, spec: Dictionary, options: Dictionary = {}) -> void:
	super(chimes)
	Options.checked("a filters spec", spec, SPEC)
	Options.checked("a filters", options, OPTIONS)
	_spec = {"searched": _named(spec, "search"), "one_of": _named(spec, "one_of"), "any_of": _named(spec, "any_of"), "between": spec.get("between", {}), "dates": spec.get("dates", {})}
	_asks = options.get("asks", Callable())
	stretch = Stretch.new(spec["dates"], value) if spec.has("dates") else null
	# every column picked on a drawing, under the action of its own it answers
	for column: StringName in _named(spec, "on_a_drawing"):
		_picks[picks_of(column)] = column
	if options.has("on"):
		facets = Facets.new(chimes, options["over"], options["on"])
		add_child(facets)
	_range.set_value(get_bounds())
	_moved()


## The columns a spec names under a word: one, several, or none.
static func _named(spec: Dictionary, word: String) -> Array:
	var said: Variant = spec.get(word)
	return [] if said == null else (said if said is Array else [said])


## The action a column picked on a drawing answers, named after the column.
static func picks_of(column: StringName) -> StringName:
	return StringName("picks_a_%s" % column)


## Every value of a column with its count and whether it is picked (facets.gd); asked only of a filters given rows to count.
func get_values(column: StringName) -> Array:
	return facets.get_values(column, _picked.read().get(column, []))


## The values picked in a column, in the order picked.
func get_picked(column: StringName) -> Array:
	return _picked.read().get(column, [])


## The one value picked in a column, or nothing picked at all.
func get_chosen(column: StringName) -> String:
	var picked: Array = _picked.read().get(column, [])
	return "" if picked.is_empty() else picked[0]


## How many things every filter keeps: nothing before the first counts land, and nothing at all where no rows were given to count - a dashboard counts in its figures, not beside its chips.
func get_count() -> Variant:
	return facets.get_kept() if facets != null else null


func get_range() -> Vector2:
	return _range.read()


func get_bounds() -> Vector2:
	return _spec["between"]["bounds"] if not _spec["between"].is_empty() else Vector2.ZERO


func get_line() -> String:
	return _line.read()


## What narrows it, as chips: {id, words, on} (filter_query.gd).
func get_chips() -> Array:
	return FilterQuery.chips(_spec, _set_by())


## The test of whether a thing is kept, as a value whoever reads it follows:
## what the test reads is read here, so a search moves the test, not a thing (lane.gd).
func get_keeps() -> Callable:
	_set_by()
	return keeps


## Whether an ordinary item is kept under the filters as they stand.
func keeps(item: Dictionary) -> bool:
	return FilterQuery.keeps(_spec, _set_by(), item)


## The query these filters are, as row_query.gd reads it.
func get_clauses() -> Array:
	return FilterQuery.clauses(_spec, _set_by())


## What a rollup is taken over as the filters stand (measures.gd): the clauses keeping the rows without the dates, and the stretch with the one before it.
func get_rollup() -> Dictionary:
	return {"clauses": FilterQuery.apart_from_dates(_spec, _set_by()), "stretches": stretch.get_stretches()}


func would(action: StringName, payload: Dictionary) -> Phrase:
	if Stretch.COMMANDS.has(action):
		return stretch.would(action, payload)
	if action == CLEARS:
		return null if not get_chips().is_empty() else Phrase.of("No filters are on")
	var counted: Dictionary = facets.get_counts() if facets != null else {}
	if action != TOGGLES or counted.is_empty() or _picked.read().get(payload["column"], []).has(payload["value"]):
		return null
	return Phrase.of("Nothing would match") if counted[payload["column"]][payload["value"]] == 0 else null


func told(action: StringName, payload: Dictionary) -> Phrase:
	match action:
		PICKS: _picked.read()[payload["column"]] = [] if payload["value"] == "" else [payload["value"]]
		TOGGLES: _toggle(payload["column"], payload["value"])
		SETS_RANGE: _range.set_value((payload["value"] as Vector2).clamp(Vector2.ONE * get_bounds().x, Vector2.ONE * get_bounds().y))
		SEARCHES: _line.set_value(String(payload["line"]).strip_edges())
		TURNS:
			if not _off.read().erase(payload["id"]):
				_off.read()[payload["id"]] = true
		REMOVES: _remove(payload["id"])
		CLEARS:
			_picked.read().clear()
			_off.read().clear()
			_range.set_value(get_bounds())
			_line.set_value("")
		Stretch.PICKS, Stretch.SETS_FIRST_DAY, Stretch.SETS_LAST_DAY: stretch.told(action, payload)
		_: _toggle(_picks[action], payload["picked"])
	_moved()
	return null


## A value picked if it was not, let go if it was, its chip turned back on;
## in a column at most one is picked from, it takes the place of that one.
func _toggle(column: StringName, one: String) -> void:
	var picked: Array = _picked.read().get(column, [])
	_off.read().erase("%s:%s" % [column, one])
	if picked.has(one):
		picked.erase(one)
	elif _spec["one_of"].has(column):
		picked = [one]
	else:
		picked.append(one)
	_picked.read()[column] = picked


## A chip taken away: its value let go, its stretch widened, its line cleared.
func _remove(id: String) -> void:
	_off.read().erase(id)
	match id:
		FilterQuery.RANGE_CHIP: _range.set_value(get_bounds())
		FilterQuery.SEARCH_CHIP: _line.set_value("")
		_:
			var parts := id.split(":", true, 1)
			(_picked.read()[StringName(parts[0])] as Array).erase(parts[1])


## What the reader has set, as filter_query.gd reads it: every value of it
## read, so whoever asked follows every one.
func _set_by() -> Dictionary:
	var within: Dictionary = stretch.get_stretches()["now"] if stretch != null else {}
	return {"picked": _picked.read(), "off": _off.read(), "line": _line.read(), "range": _range.read(), "bounds": get_bounds(), "stretch": within}


## Moved - the picks and the chips off, changed in place, set again for whatever reads them - the clauses asked and the counts set out.
func _moved() -> void:
	_picked.set_value(_picked.read())
	_off.set_value(_off.read())
	var set_by := _set_by()
	if _asks.is_valid():
		_asks.call(FilterQuery.clauses(_spec, set_by))
	if facets != null:
		facets.count(FilterQuery.columns(_spec), FilterQuery.picks(_spec, set_by), FilterQuery.beneath(_spec, set_by))


## Every action this model is told: its own, the dates column's, and one for each column picked on a drawing.
func answers() -> Array[StringName]:
	var every: Array[StringName] = COMMANDS.duplicate()
	every.append_array(_picks.keys() + (Stretch.COMMANDS if stretch != null else []))
	return every
