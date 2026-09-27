extends "controller.gd"

const Jobs := preload("jobs.gd")
const PackedRows := preload("packed_rows.gd")
const FacetCounts := preload("facet_counts.gd")

## The facets: a view over the filters (filters.gd) - every value of every
## column with how many things it would keep, and how many every filter
## keeps together - worked out off the frame.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## IT IS THE FILTERS' OWN, made by them from the rows and the job pool they
## were given; nothing else builds one, and it answers no action. The
## filters hand it what they now are - the columns, each column's clause or
## none, and the clauses beneath them all - every time a reader moves them,
## and it sets out a count (facet_counts.gd) over a snapshot of the rows.
##
## ONE SET OUT AT A TIME. A move while one is out is counted once that one
## lands, with the filters as they then stand, so a reader dragging a price
## slider sets out one count a landing and never a queue of them. The
## counts, and whether one is out, are values (value.gd): whatever draws a
## number beside a value follows them, and before the first lands the counts
## are empty, which whoever draws them says nothing of.
##
## A FACET'S COUNTS IGNORE ITS OWN PICKS, which is facet_counts.gd's rule,
## not this file's: beside every value stands what it would keep given the
## OTHER columns' picks, so picking a second material shows what it adds.
##
## Deliberately absent: a count of a stretch, an action of its own, and any
## hold on what is picked - it is handed what the filters are, each time.

var _rows: PackedRows
var _jobs: Jobs
var _counts := value({})  # facet_counts.gd's answer, or empty before the first
var _out := value(false)  # a count is on the pool
var _asked: Array = []  # the columns, the picks and the clauses beneath, as last handed


func _init(chimes: Chimes, rows: PackedRows, jobs: Jobs) -> void:
	super(chimes)
	_rows = rows
	_jobs = jobs


## {column: {value: how many it would keep}} and "kept", or empty before the first lands.
func get_counts() -> Dictionary:
	return _counts.read()


## Every value a column holds, in a reader's order, with how many it would
## keep and whether it is among those picked: {value, count, picked}; a
## count is nothing until the first lands.
func get_values(column: StringName, picked: Array) -> Array:
	var counted: Dictionary = _counts.read()
	var sorted := Array(_rows.words(column))
	sorted.sort_custom(func(a: String, b: String) -> bool: return a.naturalnocasecmp_to(b) < 0)
	return sorted.map(func(one: String) -> Dictionary: return {"value": one, "count": counted[column][one] if not counted.is_empty() else null, "picked": picked.has(one)})


## How many things every filter keeps, or nothing before the first lands.
func get_kept() -> Variant:
	return _counts.read().get("kept")


## Whether a count is being worked out.
func get_busy() -> bool:
	return _out.read()


## The filters as they now stand: counted at once, or once the count out lands.
func count(columns: Array, picks: Dictionary, beneath: Array) -> void:
	_asked = [columns, picks, beneath]
	if _out.read():
		return
	_send()


## What was last handed in, set out over a snapshot of the rows.
func _send() -> void:
	_out.set_value(true)
	var asked: Array = _asked
	_asked = []
	_jobs.submit(FacetCounts.counted.bind(_rows.snapshot(), asked[0], asked[1], asked[2]), _counted)


## A count landed: kept, unless the filters moved while it was out - then
## the answer is let go and what they now are is set out instead.
func _counted(counts: Dictionary) -> void:
	_out.set_value(false)
	if not _asked.is_empty():
		_send()
		return
	_counts.set_value(counts)
