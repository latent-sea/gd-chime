extends RefCounted

const PackedRows := preload("packed_rows.gd")

## A query over packed rows (packed_rows.gd): the rows every clause keeps,
## in the order asked, and where each group of them starts - an answer of
## row ids, never of rows.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## PURE, AND FOR ANOTHER THREAD. run() reads the arrays of the rows it is
## handed and nothing else - no tree, no bell, no model - so a caller hands
## it a snapshot and runs it off the frame (jobs.gd). A hundred thousand rows
## cost a pass per clause, a pass to key them and the engine's own sort.
##
## A CLAUSE is {column, test, value}, and a row is kept when every clause
## keeps it. IS and IS_NOT take the words a words column's value may be, or
## may not be; INCLUDES and EXCLUDES the letters its word holds, or does
## not, whatever their case; OVER, UNDER and EXACTLY a number that a number
## or date column's value is compared with. A words test is settled over
## the column's list of words once, then read per row as a yes by code.
##
## THE ORDER is by one column, up or down, else the order the rows were
## added. It is the engine's sort of one 64-bit key a row: the group's
## place, then the column's value - a word's place among its column's
## words, or a number set on a scale from the least kept to the most - then
## the row id, which keeps rows of one value in the order they were added
## and is read back out of the key. GROUPED by a words column, the rows run
## group by group, the groups in the order of their words, and the answer
## says for each its code, its word, the first place it takes in the order
## and how many it holds.
##
## Deliberately absent: an OR between clauses, a second sort column, and
## grouping by a number - each a pure addition to the key or the passes.

const IS := &"is"
const IS_NOT := &"is_not"
const INCLUDES := &"includes"
const EXCLUDES := &"excludes"
const OVER := &"over"
const UNDER := &"under"
const EXACTLY := &"exactly"
## The key's three parts, low to high: the row, the value on its scale, the group.
const ROW_BITS := 20
const VALUE_BITS := 27
const ROW_MASK := (1 << ROW_BITS) - 1
const VALUE_TOP := (1 << VALUE_BITS) - 1


## The rows kept, in order, the groups, where each row stands in the order
## - -1 for one not kept - and the query answered: {order, groups, index_of,
## clauses, sort, group}. sort is {} or {column, ascending}; group is a
## words column, or none.
static func run(rows: PackedRows, clauses: Array, sort: Dictionary, group: StringName) -> Dictionary:
	var kept := PackedInt32Array(range(rows.count()))
	# every clause in turn, each narrowing what the one before kept
	for clause: Dictionary in clauses:
		kept = _kept_by(rows, clause, kept)
	if not sort.is_empty() or group != &"":
		kept = _ordered(rows, kept, sort, group)
	var index_of := PackedInt32Array()
	index_of.resize(rows.count())
	index_of.fill(-1)
	# every row kept, where it stands in the order
	for at: int in kept.size():
		index_of[kept[at]] = at
	return {"order": kept, "groups": _groups(rows, kept, group) if group != &"" else [], "index_of": index_of, "clauses": clauses, "sort": sort, "group": group}


## Of these rows an answer shows, those it would no longer give their place
## as the rows stand now: a clause no longer keeps them, their word is not
## the group's they are shown in, or they sit out of order beside the
## nearest rows before and after them that are not among them - by the
## group's word, then the sort's value - so one moved row never makes its
## neighbour look moved. Each clause and each words column
## is settled once for all of them: three hundred rows cost little more than one.
static func misplaced(rows: PackedRows, shown: Dictionary, among: PackedInt32Array) -> PackedInt32Array:
	var order: PackedInt32Array = shown["order"]
	var index_of: PackedInt32Array = shown["index_of"]
	var judged := {}
	# every row given, as a set
	for row: int in among:
		judged[row] = true
	var still := among
	# every clause, what of these rows it still keeps
	for clause: Dictionary in shown["clauses"]:
		still = _kept_by(rows, clause, still)
	var kept := {}
	# every row still kept, as a set
	for row: int in still:
		kept[row] = true
	var group: StringName = shown["group"]
	var sort: Dictionary = shown["sort"]
	var sorted_by: StringName = sort.get("column", &"")
	# each words column the order reads, its words' places worked out once: the group's, and the sort's
	var ranked := {group: rows.ranks(group) if group != &"" else PackedInt32Array(), sorted_by: rows.ranks(sorted_by) if sorted_by != &"" and rows.kind_of(sorted_by) == PackedRows.WORDS else PackedInt32Array()}
	var firsts := PackedInt32Array(shown["groups"].map(func(one: Dictionary) -> int: return one["first"]))
	var out := PackedInt32Array()
	# every row given: out when a clause lets it go, its word is not the group's it is shown in, or it belongs before the row ahead of it or after the row behind it
	for row: int in among:
		if group != &"" and rows.codes(group)[row] != shown["groups"][firsts.bsearch(index_of[row], false) - 1]["code"]:
			out.append(row)
			continue
		var ahead := index_of[row] - 1
		var behind := index_of[row] + 1
		# the nearest place ahead whose row is not among those judged, and the nearest behind
		while ahead >= 0 and judged.has(order[ahead]):
			ahead -= 1
		while behind < order.size() and judged.has(order[behind]):
			behind += 1
		if not kept.has(row) or (ahead >= 0 and _after(rows, ranked, order[ahead], row, sort, group)) or (behind < order.size() and _after(rows, ranked, row, order[behind], sort, group)):
			out.append(row)
	return out


## Whether this row belongs after that one: a later group, or in one group a
## later value the way the sort runs; a words column read by its words' places.
static func _after(rows: PackedRows, ranked: Dictionary, row: int, then: int, sort: Dictionary, group: StringName) -> bool:
	if group != &"":
		var mine: int = ranked[group][rows.codes(group)[row]]
		var theirs: int = ranked[group][rows.codes(group)[then]]
		if mine != theirs:
			return mine > theirs
	if sort.is_empty():
		return false
	var column: StringName = sort["column"]
	var a: Variant = rows.value_at(row, column)
	var b: Variant = rows.value_at(then, column)
	if rows.kind_of(column) == PackedRows.WORDS:
		a = ranked[column][rows.codes(column)[row]]
		b = ranked[column][rows.codes(column)[then]]
	return a > b if sort["ascending"] else a < b


## What of these rows one clause keeps, in the order they came.
static func _kept_by(rows: PackedRows, clause: Dictionary, among: PackedInt32Array) -> PackedInt32Array:
	var column: StringName = clause["column"]
	var test: StringName = clause["test"]
	var kept := PackedInt32Array()
	kept.resize(among.size())
	var found := 0
	if rows.kind_of(column) == PackedRows.WORDS:
		var yes := _codes_kept(rows.words(column), test, clause["value"])
		var codes := rows.codes(column)
		# every row, kept when its word's code is one the test says yes to
		for row: int in among:
			if yes[codes[row]] == 1:
				kept[found] = row
				found += 1
	else:
		var numbers := rows.numbers(column)
		var than: float = clause["value"]
		# every row, kept when its number stands to the clause's as the test asks
		for row: int in among:
			var value := numbers[row]
			if (test == OVER and value > than) or (test == UNDER and value < than) or (test == EXACTLY and value == than):
				kept[found] = row
				found += 1
	kept.resize(found)
	return kept


## A yes (1) or no (0) for every word of a column, by its code: whether a
## row holding it passes the test.
static func _codes_kept(words: PackedStringArray, test: StringName, value: Variant) -> PackedByteArray:
	var yes := PackedByteArray()
	yes.resize(words.size())
	var letters := String(value).to_lower() if test in [INCLUDES, EXCLUDES] else ""
	# every word the column holds, settled once for every row that holds it
	for code: int in words.size():
		var passes := false
		match test:
			IS: passes = (value as Array).has(words[code])
			IS_NOT: passes = not (value as Array).has(words[code])
			INCLUDES: passes = words[code].to_lower().contains(letters)
			EXCLUDES: passes = not words[code].to_lower().contains(letters)
		yes[code] = 1 if passes else 0
	return yes


## These rows in order: by the group's place, then the sort column's value,
## then the row - one key each, sorted by the engine and read back.
static func _ordered(rows: PackedRows, kept: PackedInt32Array, sort: Dictionary, group: StringName) -> PackedInt32Array:
	var keys := PackedInt64Array()
	keys.resize(kept.size())
	var valued := _values_on_scale(rows, kept, sort)
	var group_codes := rows.codes(group) if group != &"" else PackedInt32Array()
	var group_ranks := rows.ranks(group) if group != &"" else PackedInt32Array()
	# every row, its key: the group's place over the value's over the row
	for at: int in kept.size():
		var row := kept[at]
		var placed := group_ranks[group_codes[row]] if group != &"" else 0
		keys[at] = (placed << (VALUE_BITS + ROW_BITS)) | (valued[at] << ROW_BITS) | row
	keys.sort()
	var ordered := PackedInt32Array()
	ordered.resize(keys.size())
	# every key, the row read back out of its lowest bits
	for at: int in keys.size():
		ordered[at] = keys[at] & ROW_MASK
	return ordered


## Each kept row's value for the sort, as a whole number whose order is the
## order asked: a word's place, or a number on a scale from the least kept
## to the most; turned over for downward; nothing at all with no sort.
static func _values_on_scale(rows: PackedRows, kept: PackedInt32Array, sort: Dictionary) -> PackedInt64Array:
	var valued := PackedInt64Array()
	valued.resize(kept.size())
	if sort.is_empty():
		return valued
	var column: StringName = sort["column"]
	var up: bool = sort["ascending"]
	if rows.kind_of(column) == PackedRows.WORDS:
		var codes := rows.codes(column)
		var ranks := rows.ranks(column)
		# every kept row, the place its word stands in, turned over for downward
		for at: int in kept.size():
			var placed := ranks[codes[kept[at]]]
			valued[at] = placed if up else VALUE_TOP - placed
		return valued
	var numbers := rows.numbers(column)
	var least := INF
	var most := -INF
	# every kept row, for the least and the most value the scale runs between
	for row: int in kept:
		least = minf(least, numbers[row])
		most = maxf(most, numbers[row])
	var scale := VALUE_TOP / (most - least) if most > least else 0.0
	# every kept row, its value set on the scale, turned over for downward
	for at: int in kept.size():
		var placed := int((numbers[kept[at]] - least) * scale)
		valued[at] = placed if up else VALUE_TOP - placed
	return valued


## Where each group starts in the order and how many it holds, one after
## another as they run: {code, words, first, count}.
static func _groups(rows: PackedRows, order: PackedInt32Array, group: StringName) -> Array:
	var codes := rows.codes(group)
	var words := rows.words(group)
	var groups: Array = []
	# every row in order, a new group begun wherever its word differs from the row before
	for at: int in order.size():
		var code := codes[order[at]]
		if groups.is_empty() or groups[-1]["code"] != code:
			groups.append({"code": code, "words": words[code], "first": at, "count": 0})
		groups[-1]["count"] += 1
	return groups
