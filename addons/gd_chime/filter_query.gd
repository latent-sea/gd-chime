extends RefCounted

const RowQuery := preload("row_query.gd")
const Rollup := preload("rollup.gd")
const Phrase := preload("phrase.gd")

## What a filter spec MEANS over a thing (filters.gd): the query it is over
## packed rows, and the test it is over an ordinary item - the same answer,
## read two ways.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## PURE AND STATIC, as row_query.gd and facet_counts.gd are: every function
## here reads the two dictionaries it is handed and nothing else - no tree,
## no bell, no model - so the same rule serves a query sent off the frame
## and a test run over a card as a lane draws it, and neither can drift
## from the other.
##
## SPEC is the filters' spec already sorted out: searched, the columns a
## line of letters is looked for in; one_of and any_of, the columns values
## are picked in; between, {column, bounds, words} or nothing; dates,
## {column, ...} or nothing. SET is what the reader has set: picked, column
## -> the values picked; off, the ids of the chips turned off; line; range;
## bounds; stretch, the days the dates stand in, as stretch.gd states one;
## and the ids the stretch's chip and the line's go by.
##
## THE DATES ARE ASKED BOTH WAYS: with them, for the whole query and the
## test over an item; and APART from them, which is what a rollup is taken
## over, since each of its measures takes its own stretch of its own column
## of time (rollup.gd, within - the one statement of a stretch as clauses,
## read here so the two cannot part).
##
## A CLAUSE PER COLUMN, ANDed, as row_query.gd reads them: a column's clause
## keeps a row whose word is any of the values picked in it, so values
## within one column widen it - oak or walnut - and columns narrow each
## other. The stretch is two clauses, reaching EDGE past its ends so a value
## on an end is kept, and the search one. An item is kept by the same rule,
## its own value read straight off it; a value that is a LIST - a card's
## labels - is kept where it shares one with those picked.
##
## Deliberately absent: an OR between columns, and any state at all - what
## is picked belongs to the model, never here.

## How far past a stretch's ends its clauses reach, so a value on an end is kept.
const EDGE := 0.001
## The chips the stretch and the line go by, by id; a value's chip is its column and its value.
const RANGE_CHIP := "range"
const SEARCH_CHIP := "search"


## Every column a value may be picked in, in the order declared.
static func columns(spec: Dictionary) -> Array:
	return spec["one_of"] + spec["any_of"]


## Every column a value may be picked in, and its clause or none for a
## column with nothing picked in it - what the counts are worked out by.
static func picks(spec: Dictionary, set_by: Dictionary) -> Dictionary:
	var by_column: Dictionary = {}
	# every column a value may be picked in: the values picked whose chips are on, as one clause
	for column: StringName in columns(spec):
		var on: Array = on_in(set_by, column)
		by_column[column] = {"column": column, "test": RowQuery.IS, "value": on} if not on.is_empty() else null
	return by_column


## The clauses beneath every column's: the stretch, the line searched for, and the days the dates stand in.
static func beneath(spec: Dictionary, set_by: Dictionary) -> Array:
	return _under(spec, set_by) + within_dates(spec, set_by)


## The days a date column stands in, as clauses over its hours; none where no dates were declared.
static func within_dates(spec: Dictionary, set_by: Dictionary) -> Array:
	return [] if spec["dates"].is_empty() else Rollup.within(spec["dates"]["column"], set_by["stretch"])


## The whole query the filters are, as row_query.gd reads it.
static func clauses(spec: Dictionary, set_by: Dictionary) -> Array:
	return within_dates(spec, set_by) + apart_from_dates(spec, set_by)


## The same query with the dates left out: what a rollup is taken over.
static func apart_from_dates(spec: Dictionary, set_by: Dictionary) -> Array:
	return _under(spec, set_by) + picks(spec, set_by).values().filter(func(clause: Variant) -> bool: return clause != null)


## The stretch of a number column, and the line searched for.
static func _under(spec: Dictionary, set_by: Dictionary) -> Array:
	var under: Array = []
	if stretched(spec, set_by):
		under.append({"column": spec["between"]["column"], "test": RowQuery.OVER, "value": set_by["range"].x - EDGE})
		under.append({"column": spec["between"]["column"], "test": RowQuery.UNDER, "value": set_by["range"].y + EDGE})
	if searching(set_by):
		under.append({"column": spec["searched"][0], "test": RowQuery.INCLUDES, "value": set_by["line"]})
	return under


## Whether an ordinary item is kept: every column picked in shares a value
## with it, the stretch holds its number, and one of the searched columns
## holds the letters typed.
static func keeps(spec: Dictionary, set_by: Dictionary, item: Dictionary) -> bool:
	# every column a value may be picked in: the thing's own value, or one it holds, must be among those picked and on
	for column: StringName in columns(spec):
		var on: Array = on_in(set_by, column)
		if not on.is_empty() and not _shares(item[column], on):
			return false
	if stretched(spec, set_by) and (item[spec["between"]["column"]] < set_by["range"].x or item[spec["between"]["column"]] > set_by["range"].y):
		return false
	# the dates: the hours a thing falls on, from the stretch's first hour up to but not on its last
	if not spec["dates"].is_empty() and (item[spec["dates"]["column"]] < set_by["stretch"]["from"] or item[spec["dates"]["column"]] >= set_by["stretch"]["to"]):
		return false
	if not searching(set_by):
		return true
	var wanted: String = (set_by["line"] as String).to_lower()
	# every column searched: kept where any of them holds the letters typed
	return (spec["searched"] as Array).any(func(column: StringName) -> bool: return _written(item[column]).to_lower().contains(wanted))


## What narrows the filters, said as chips - {id, words, on}: every value
## picked, in the order picked, then the stretch once its ends are moved in,
## then the line typed.
static func chips(spec: Dictionary, set_by: Dictionary) -> Array:
	var said: Array = []
	# every value picked in every column a value may be picked in, its chip
	for column: StringName in columns(spec):
		for one: String in set_by["picked"].get(column, []):
			said.append(_chip(set_by, "%s:%s" % [column, one], one))
	if not spec["between"].is_empty() and set_by["range"] != set_by["bounds"]:
		said.append(_chip(set_by, RANGE_CHIP, spec["between"]["words"].call(set_by["range"])))
	if set_by["line"] != "":
		said.append(_chip(set_by, SEARCH_CHIP, Phrase.with("\"%s\"", [set_by["line"]])))
	return said


## The values picked in a column whose chips are on.
static func on_in(set_by: Dictionary, column: StringName) -> Array:
	return set_by["picked"].get(column, []).filter(func(one: String) -> bool: return not set_by["off"].has("%s:%s" % [column, one]))


## Whether the stretch narrows anything as it stands: a column declared, its
## ends moved in from the whole of it, and its chip on.
static func stretched(spec: Dictionary, set_by: Dictionary) -> bool:
	return not spec["between"].is_empty() and set_by["range"] != set_by["bounds"] and not set_by["off"].has(RANGE_CHIP)


## Whether a line has been typed and its chip is on.
static func searching(set_by: Dictionary) -> bool:
	return set_by["line"] != "" and not set_by["off"].has(SEARCH_CHIP)


## One chip: what it says, and whether it is on - a chip turned off is kept and applies nothing.
static func _chip(set_by: Dictionary, id: String, words: Variant) -> Dictionary:
	return {"id": id, "words": words, "on": not set_by["off"].has(id)}


## Whether a thing's own value, or one of those it holds, is among these.
static func _shares(held: Variant, on: Array) -> bool:
	return (held as Array).any(func(one: Variant) -> bool: return on.has(one)) if held is Array else on.has(held)


## A thing's value written out, a list of them as one line, to search within.
static func _written(held: Variant) -> String:
	return " ".join(held) if held is Array else str(held)
