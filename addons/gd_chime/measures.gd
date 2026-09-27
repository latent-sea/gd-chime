extends "controller.gd"

const Jobs := preload("jobs.gd")
const PackedRows := preload("packed_rows.gd")
const Rollup := preload("rollup.gd")
const RowQuery := preload("row_query.gd")
const Reads := preload("reads.gd")

## What a dashboard shows of a collection: every figure and every split of
## one (rollup.gd), worked out off the frame each time what it is taken over
## moves, and read by every card and chart.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## WHAT IT IS TAKEN OVER is a bound value, never a filter of its own:
## {clauses, stretches} - the clauses keeping the rows, and the stretch
## shown with the one before it - which is what a filters' date column
## answers (filters.gd, get_rollup), and what a test hands in by hand.
##
## ONE ROLLUP FOR THE WHOLE DASHBOARD. That value moves - this follows
## whatever it read (reads.gd) - and this asks the job pool (jobs.gd) for
## every figure and split at once, over a copy of the rows, so the frame
## never pays for a pass; one is out at a time, and a move while one is out
## is asked once it lands, as it then stands - the answer to filters since
## moved is never shown. What landed, and whether one is out, are values
## (value.gd), set as a rollup goes out and as one lands, so a region
## pressed re-reads every card and chart in the one frame the answer lands
## in, and each reads only its own figure.
##
## Until the first lands, nothing has: get_landed() is false and every
## figure reads null, and a chart shows loading (loaded_or_empty.gd). A
## later rollup out leaves the last one shown - get_busy() says one is out -
## so the dashboard never blanks while the reader filters it.
##
## A figure is {now, before, days, days_before}; a split [{key, now,
## before}] (rollup.gd). clauses_of() are the rows a figure stands for now,
## the scope of a drill-down's grid (queried_rows.gd, scope_to).
##
## Deliberately absent: rows written while shown, and working out one
## figure alone - every rollup is the whole dashboard's.


var _rows: PackedRows
var _over: Bound  # the clauses and the stretches the figures are taken over
var _taken: Dictionary  # what it last read of them
var _jobs: Jobs
var _spec: Dictionary
var _times: Dictionary
var _answer := value({})  # the rollup last landed, or nothing yet
var _stretches := value({})  # the stretches it was worked out over
var _out := value(false)  # a rollup is on the pool
var _again: bool = false  # what it is taken over moved while one was out
var _asked_at: int = 0  # when the rollup out was asked, in microseconds
var _took_ms := value(0.0)


## Over these rows, narrowed to what this bound value reads, on this pool:
## the figures and splits the spec names (rollup.gd), the columns an open
## row opens and closes by.
func _init(chimes: Chimes, rows: PackedRows, over: Bound, jobs: Jobs, spec: Dictionary, times: Dictionary) -> void:
	super(chimes)
	_rows = rows
	_over = over
	_jobs = jobs
	_spec = spec
	_times = times
	follow(&"over", _taken_over_moved)


## Whether any rollup has landed yet.
func get_landed() -> bool:
	return not _answer.read().is_empty()


## Whether a rollup is out now.
func get_busy() -> bool:
	return _out.read()


func get_took_ms() -> float:
	return _took_ms.read()


## Every figure, by name, as last landed; nothing until one has.
func get_figures() -> Variant:
	return _answer.read().get("figures")


## Every split, by name, as last landed; nothing until one has.
func get_splits() -> Variant:
	return _answer.read().get("splits")


## The stretches the figures shown were worked out over.
func get_stretches() -> Dictionary:
	return _stretches.read()


## What the figures are taken over, read so that whatever it read is
## followed; moved, every figure asked again - apart from what is followed,
## so the rollup's own values are never among it (reads.gd).
func _taken_over_moved() -> void:
	_taken = _over.read()
	Reads.apart(_ask)


## The clauses keeping the rows a figure stands for now: the ones it is
## taken over, its own, and the stretch shown - or open at its end. Given a
## split's name and one of its words, the rows of that word: the split's
## column holding it, whatever narrows that column let go.
func clauses_of(name: StringName, picked: Variant = null) -> Array:
	if picked == null:
		return Rollup.clauses_for(_spec["figures"][name], _taken["clauses"], _taken["stretches"]["now"], _times)
	var split: Dictionary = _spec["splits"][name]
	var base: Array = _taken["clauses"].filter(func(clause: Dictionary) -> bool: return clause["column"] != split["by"])
	return Rollup.clauses_for(split, base + [{"column": split["by"], "test": RowQuery.IS, "value": [picked]}], _taken["stretches"]["now"], _times)


## The whole dashboard's rollup sent off over what it last read - or, with
## one out, asked once it lands.
func _ask() -> void:
	if _out.read():
		_again = true
		return
	_out.set_value(true)
	_asked_at = Time.get_ticks_usec()
	var stretches: Dictionary = _taken["stretches"]
	_jobs.submit(Rollup.run.bind(_rows.snapshot(), _spec, _taken["clauses"], stretches, _times), _landed.bind(stretches))


## An answer: shown, unless what it is taken over has moved since, when it is asked again instead.
func _landed(answer: Dictionary, stretches: Dictionary) -> void:
	_out.set_value(false)
	if _again:
		_again = false
		_ask()
		return
	_took_ms.set_value((Time.get_ticks_usec() - _asked_at) / 1000.0)
	_answer.set_value(answer)
	_stretches.set_value(stretches)
