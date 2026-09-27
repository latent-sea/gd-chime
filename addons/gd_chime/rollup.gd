extends RefCounted

const PackedRows := preload("packed_rows.gd")
const RowQuery := preload("row_query.gd")

## A rollup of rows over a stretch of time and the stretch before it: each
## figure a dashboard shows, day by day as well as whole, and each figure
## split by the words of a column - an answer of numbers, never of rows.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## PURE, AND FOR ANOTHER THREAD, as row_query.gd is: run() reads the arrays
## of the rows it is handed and nothing else, so a caller hands it a copy and
## runs it off the frame (measures.gd).
##
## A MEASURE is {how, of, when, where}. HOW: COUNT the rows, SUM or take the
## MEAN of a number column, count the DISTINCT words of a words column, or
## the SPREAD of a number column - its median, and each day the quarter
## below and above it, a band. OF: the column. WHERE: clauses of its own
## (row_query.gd), under the filter's. WHEN: a column of hours - the rows
## whose time there falls in the stretch, bucketed by its day - or OPEN, the
## rows standing open at the stretch's end: opened before it and closed
## after, the times of both the caller's ("opens", "closes"). Open, each
## day is the rows open at that day's end, or at the stretch's for its last.
##
## clauses_for() is the ONE statement of which rows a measure is taken
## over, so a drill-down's grid (queried_rows.gd, scope_to) shows exactly the
## rows a figure counted. A SPLIT never narrows its own column: split by
## region, the filter's region is let go, so every region stays to be
## pressed however one is filtered.
##
## A stretch is {from, to, first_day, days}, in hours and days since 1970
## (stretch.gd). Nothing kept is a count of none, and no mean, no
## spread: null.
##
## Deliberately absent: splitting by two columns at once, and a measure
## over time finer than a day.

const COUNT := &"count"
const SUM := &"sum"
const MEAN := &"mean"
const DISTINCT := &"distinct"
const SPREAD := &"spread"
const OPEN := &"open"
const HOURS := 24.0
const STRETCHES := ["now", "before"]


## Every figure and every split of the spec, {figures: {name: measure},
## splits: {name: measure with "by"}}, over the base clauses in both
## stretches: {figures: {name: {now, before, days, days_before}}, splits:
## {name: [{key, now, before, rank}]}}, a day's value [low, middle, high]
## for a spread.
static func run(rows: PackedRows, spec: Dictionary, base: Array, stretches: Dictionary, times: Dictionary) -> Dictionary:
	var figures: Dictionary = {}
	var splits: Dictionary = {}
	# every figure, whole and day by day, in each stretch
	for name: StringName in spec.get("figures", {}):
		var measure: Dictionary = spec["figures"][name]
		var taken: Dictionary = {}
		# each stretch in turn, the one shown and the one before
		for which: String in STRETCHES:
			var days := _days(rows, measure, base, stretches[which], times)
			taken[which] = _value(measure["how"], days[-1]) if measure["when"] == OPEN else _value(measure["how"], _joined(days))
			taken["days" if which == "now" else "days_before"] = days.map(func(day: Dictionary) -> Variant: return _day_value(measure["how"], day))
		figures[name] = taken
	# every split, by the words of its column
	for name: StringName in spec.get("splits", {}):
		splits[name] = _split(rows, spec["splits"][name], base, stretches, times)
	return {"figures": figures, "splits": splits}


## The clauses that keep the rows a measure is taken over in a stretch:
## the base's and its own, then those in the stretch - or open at its end.
static func clauses_for(measure: Dictionary, base: Array, stretch: Dictionary, times: Dictionary) -> Array:
	var clauses: Array = base + measure.get("where", [])
	if measure["when"] == OPEN:
		return clauses + [{"column": times["opens"], "test": RowQuery.UNDER, "value": stretch["to"]}, {"column": times["closes"], "test": RowQuery.OVER, "value": stretch["to"]}]
	return clauses + within(measure["when"], stretch)


## A stretch over a column of hours: from its first hour - over a hair
## before it, since over is strict - and before its last.
static func within(column: StringName, stretch: Dictionary) -> Array:
	return [{"column": column, "test": RowQuery.OVER, "value": stretch["from"] - 0.001}, {"column": column, "test": RowQuery.UNDER, "value": stretch["to"]}]


## A bucket for each day of a stretch, the measure's rows added to it: by
## the day their time falls on, or, open, to every day whose end they stand open at.
static func _days(rows: PackedRows, measure: Dictionary, base: Array, stretch: Dictionary, times: Dictionary) -> Array[Dictionary]:
	var days: Array[Dictionary] = []
	# one empty bucket per day
	for day: int in stretch["days"]:
		days.append(_bucket())
	if measure["when"] != OPEN:
		var hours := rows.numbers(measure["when"])
		# every row the measure keeps, into the bucket of its day
		for row: int in _kept(rows, clauses_for(measure, base, stretch, times)):
			_add(days[int(hours[row] / HOURS) - stretch["first_day"]], rows, measure, row)
		return days
	var ends: Array[float] = []
	# every day's end, the last the stretch's own
	for day: int in stretch["days"]:
		ends.append(minf((stretch["first_day"] + day + 1) * HOURS, stretch["to"]))
	var opens := rows.numbers(times["opens"])
	var closes := rows.numbers(times["closes"])
	var standing: Array = base + measure.get("where", []) + [{"column": times["opens"], "test": RowQuery.UNDER, "value": stretch["to"]}, {"column": times["closes"], "test": RowQuery.OVER, "value": ends[0]}]
	# every row open at some day's end, into the bucket of every day it stands open at the end of
	for row: int in _kept(rows, standing):
		# every day's end, the row added where it is open then
		for day: int in ends.size():
			if opens[row] < ends[day] and closes[row] > ends[day]:
				_add(days[day], rows, measure, row)
	return days


## A measure split by the words of its column, the filter never narrowing
## that column: every word the column holds, in a reader's order, with its
## value in each stretch.
static func _split(rows: PackedRows, measure: Dictionary, base: Array, stretches: Dictionary, times: Dictionary) -> Array:
	var by: StringName = measure["by"]
	var codes := rows.codes(by)
	var open: Array = base.filter(func(clause: Dictionary) -> bool: return clause["column"] != by)
	var split: Dictionary = {}
	# each stretch, every kept row into its word's bucket
	for which: String in STRETCHES:
		var buckets: Array[Dictionary] = []
		# one bucket per word the column holds
		for code: int in rows.words(by).size():
			buckets.append(_bucket())
		# every row kept in this stretch, into the bucket of its word
		for row: int in _kept(rows, clauses_for(measure, open, stretches[which], times)):
			_add(buckets[codes[row]], rows, measure, row)
		split[which] = buckets
	var ranks := rows.ranks(by)
	var found: Array = []
	# every word, its values in both stretches
	for code: int in rows.words(by).size():
		found.append({"key": rows.words(by)[code], "now": _value(measure["how"], split["now"][code]), "before": _value(measure["how"], split["before"][code]), "rank": ranks[code]})
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["rank"] < b["rank"])
	return found


static func _kept(rows: PackedRows, clauses: Array) -> PackedInt32Array:
	return RowQuery.run(rows, clauses, {}, &"")["order"]


## What a bucket gathers: how many, their sum, their values for a spread, and their words' codes for a distinct count.
static func _bucket() -> Dictionary:
	return {"count": 0, "sum": 0.0, "values": [], "codes": {}}


## One row into a bucket, gathering only what the measure asks for.
static func _add(bucket: Dictionary, rows: PackedRows, measure: Dictionary, row: int) -> void:
	bucket["count"] += 1
	match measure["how"]:
		SUM, MEAN: bucket["sum"] += rows.numbers(measure["of"])[row]
		SPREAD: bucket["values"].append(rows.numbers(measure["of"])[row])
		DISTINCT: bucket["codes"][rows.codes(measure["of"])[row]] = true


## Every day's bucket as one, for the whole of a stretch.
static func _joined(days: Array[Dictionary]) -> Dictionary:
	var whole := _bucket()
	# every day, its gathering added to the whole
	for day: Dictionary in days:
		whole["count"] += day["count"]
		whole["sum"] += day["sum"]
		whole["values"].append_array(day["values"])
		whole["codes"].merge(day["codes"])
	return whole


## A bucket's value as the measure takes it; nothing gathered is no mean and no spread.
static func _value(how: StringName, bucket: Dictionary) -> Variant:
	match how:
		COUNT: return float(bucket["count"])
		SUM: return bucket["sum"]
		DISTINCT: return float(bucket["codes"].size())
		MEAN: return null if bucket["count"] == 0 else bucket["sum"] / bucket["count"]
	return _quarter(bucket["values"], 0.5)


## A day's value: a spread's is its band, [low, middle, high].
static func _day_value(how: StringName, bucket: Dictionary) -> Variant:
	if how != SPREAD or bucket["values"].is_empty():
		return _value(how, bucket)
	return [_quarter(bucket["values"], 0.25), _quarter(bucket["values"], 0.5), _quarter(bucket["values"], 0.75)]


## The value this share of the way up these values, read off them sorted; none of none.
static func _quarter(values: Array, share: float) -> Variant:
	if values.is_empty():
		return null
	var sorted := values.duplicate()
	sorted.sort()
	return sorted[int(share * (sorted.size() - 1))]
