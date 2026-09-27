extends RefCounted

const PackedRows := preload("packed_rows.gd")
const RowQuery := preload("row_query.gd")

## How many rows each value of each facet would keep: the number a reader
## reads beside "oak" before pressing it.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A FACET'S COUNTS IGNORE ITS OWN PICKS: beside every value of a facet
## stands how many rows the OTHER facets' picks and the clauses beneath
## every facet - a range, a search - keep with that value, so picking a
## second material shows what it would add, and a value counted nothing
## would leave nothing. That is a query a facet, each a pass over the rows,
## and a tally by code.
##
## PURE, AND FOR ANOTHER THREAD, as row_query.gd is: counted() reads the
## arrays of the rows it is handed and nothing else, so a caller hands it a
## copy and runs it off the frame (jobs.gd).
##
## Deliberately absent: counts of a number column's stretches.


## {facet: {value: count}} for every words column named, and "kept": how
## many rows every clause together keeps. picks is {facet: its clause, or
## null for a facet with nothing picked}; beneath, the clauses under all.
static func counted(rows: PackedRows, facets: Array, picks: Dictionary, beneath: Array) -> Dictionary:
	var counts: Dictionary = {}
	# every facet: the rows every other facet and the clauses beneath keep, tallied by this facet's words
	for facet: StringName in facets:
		var others: Array = beneath + facets.filter(func(other: StringName) -> bool: return other != facet and picks[other] != null).map(func(other: StringName) -> Dictionary: return picks[other])
		var kept: PackedInt32Array = RowQuery.run(rows, others, {}, &"")["order"]
		var codes := rows.codes(facet)
		var words := rows.words(facet)
		var tally := PackedInt32Array()
		tally.resize(words.size())
		# every row kept, one more for its word
		for row: int in kept:
			tally[codes[row]] += 1
		counts[facet] = {}
		# every word the column holds, with its tally
		for code: int in words.size():
			counts[facet][words[code]] = tally[code]
	var every: Array = beneath + picks.values().filter(func(clause: Variant) -> bool: return clause != null)
	counts["kept"] = RowQuery.run(rows, every, {}, &"")["order"].size()
	return counts
