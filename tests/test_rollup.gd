extends SceneTree

## What must be true of a rollup: every figure, whole and day by day, in
## the stretch and the one before, is what a pass over every row finds; a
## figure of rows open at a stretch's end counts those open then, each day
## those open at its end; a spread's day is a band around its middle; a
## split holds every word, never narrowed by its own column; and the clauses
## a figure is taken over keep exactly the rows it counted.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_rollup.gd

const PackedRows := preload("res://addons/gd_chime/packed_rows.gd")
const RowQuery := preload("res://addons/gd_chime/row_query.gd")
const Rollup := preload("res://addons/gd_chime/rollup.gd")
const Verdict := preload("res://tests/verdict.gd")

const TIMES := {"opens": &"reported", "closes": &"restored"}
const REGIONS := ["Wales", "London", "East"]
const TEAMS := ["T1", "T2", "T3", "T4", "T5"]
## Days 10 to 12 and, before them, 7 to 9; the stretch shown ending at noon on day 12.
const NOW := {"from": 240.0, "to": 300.0, "first_day": 10, "days": 3}
const BEFORE := {"from": 168.0, "to": 240.0, "first_day": 7, "days": 3}

var _verdict := Verdict.new()
var _rows: PackedRows


func _init() -> void:
	_rows = _incidents()
	await _verdict.states(_every_figure_whole_and_by_day_is_what_a_pass_over_every_row_finds)
	await _verdict.states(_a_figure_of_rows_open_counts_those_open_at_the_end_and_each_day_at_its_end)
	await _verdict.states(_a_spread_is_the_middle_and_each_day_a_band_around_it)
	await _verdict.states(_a_split_holds_every_word_and_is_never_narrowed_by_its_own_column)
	await _verdict.states(_the_clauses_a_figure_is_taken_over_keep_exactly_the_rows_it_counted)
	quit(_verdict.deliver(get_script()))


## Three hundred incidents over days 5 to 13, the same every run.
func _incidents() -> PackedRows:
	var rows := PackedRows.new({&"region": PackedRows.WORDS, &"team": PackedRows.WORDS, &"reported": PackedRows.NUMBER, &"restored": PackedRows.NUMBER, &"customers": PackedRows.NUMBER, &"repair": PackedRows.NUMBER})
	var draws := RandomNumberGenerator.new()
	draws.seed = 7
	# every incident, drawn in turn
	for at: int in 300:
		var reported := draws.randf_range(5.0 * 24.0, 13.0 * 24.0)
		var repair := draws.randf_range(1.0, 30.0)
		rows.add([REGIONS[draws.randi() % 3], TEAMS[draws.randi() % 5], reported, reported + repair, float(draws.randi_range(10, 500)), repair])
	return rows


## The rows a pass over every one keeps: in Wales, and true of the test given.
func _by_hand(keeps: Callable) -> Array:
	return range(_rows.count()).filter(func(row: int) -> bool: return _rows.value_at(row, &"region") == "Wales" and keeps.call(row))


func _in(row: int, column: StringName, stretch: Dictionary) -> bool:
	return _rows.value_at(row, column) >= stretch["from"] and _rows.value_at(row, column) < stretch["to"]


func _on_day(row: int, day: int) -> bool:
	return floori(_rows.value_at(row, &"reported") / 24.0) == day


func _wales() -> Array:
	return [{"column": &"region", "test": RowQuery.IS, "value": ["Wales"]}]


func _run(spec: Dictionary) -> Dictionary:
	return Rollup.run(_rows, spec, _wales(), {"now": NOW, "before": BEFORE}, TIMES)


func _every_figure_whole_and_by_day_is_what_a_pass_over_every_row_finds() -> void:
	var spec := {"figures": {&"reported": {"how": Rollup.COUNT, "when": &"reported"}, &"customers": {"how": Rollup.SUM, "of": &"customers", "when": &"reported"}, &"repair": {"how": Rollup.MEAN, "of": &"repair", "when": &"restored"}, &"teams": {"how": Rollup.DISTINCT, "of": &"team", "when": &"reported"}}}
	var got: Dictionary = _run(spec)["figures"]
	var now := _by_hand(func(row: int) -> bool: return _in(row, &"reported", NOW))
	var before := _by_hand(func(row: int) -> bool: return _in(row, &"reported", BEFORE))
	_verdict.check(got[&"reported"]["now"] == float(now.size()) and got[&"reported"]["before"] == float(before.size()) and now.size() > 5, "the count is the Welsh incidents reported in each stretch: %s and %s against %d and %d" % [got[&"reported"]["now"], got[&"reported"]["before"], now.size(), before.size()])
	var days: Array = range(10, 13).map(func(day: int) -> float: return float(now.filter(func(row: int) -> bool: return _on_day(row, day)).size()))
	_verdict.check(got[&"reported"]["days"] == days and got[&"reported"]["days_before"].size() == 3, "day by day, each day's count is the incidents reported on it: %s against %s" % [got[&"reported"]["days"], days])
	var customers: float = now.reduce(func(sum: float, row: int) -> float: return sum + _rows.value_at(row, &"customers"), 0.0)
	_verdict.check(is_equal_approx(got[&"customers"]["now"], customers), "the sum is theirs added: %s against %s" % [got[&"customers"]["now"], customers])
	var restored := _by_hand(func(row: int) -> bool: return _in(row, &"restored", NOW))
	var mean: float = restored.reduce(func(sum: float, row: int) -> float: return sum + _rows.value_at(row, &"repair"), 0.0) / restored.size()
	_verdict.check(is_equal_approx(got[&"repair"]["now"], mean), "the mean is over the incidents restored in the stretch, by their own time: %s against %s" % [got[&"repair"]["now"], mean])
	var teams := {}
	# every incident reported in the stretch, its team noted once
	for row: int in now:
		teams[_rows.value_at(row, &"team")] = true
	_verdict.check(got[&"teams"]["now"] == float(teams.size()), "the distinct count is how many teams, not incidents: %s against %d" % [got[&"teams"]["now"], teams.size()])
	var empty: Dictionary = Rollup.run(_rows, spec, [{"column": &"region", "test": RowQuery.IS, "value": ["nowhere"]}], {"now": NOW, "before": BEFORE}, TIMES)["figures"]
	_verdict.check(empty[&"reported"]["now"] == 0.0 and empty[&"repair"]["now"] == null, "nothing kept is a count of none, and no mean at all: %s, %s" % [empty[&"reported"]["now"], empty[&"repair"]["now"]])


func _a_figure_of_rows_open_counts_those_open_at_the_end_and_each_day_at_its_end() -> void:
	var got: Dictionary = _run({"figures": {&"out": {"how": Rollup.SUM, "of": &"customers", "when": Rollup.OPEN}}})["figures"][&"out"]
	var open_at := func(hour: float) -> float: return _by_hand(func(row: int) -> bool: return _rows.value_at(row, &"reported") < hour and _rows.value_at(row, &"restored") > hour).reduce(func(sum: float, row: int) -> float: return sum + _rows.value_at(row, &"customers"), 0.0)
	_verdict.check(is_equal_approx(got["now"], open_at.call(300.0)) and is_equal_approx(got["before"], open_at.call(240.0)) and got["now"] > 0.0, "the customers of incidents standing open at each stretch's end: %s against %s" % [got["now"], open_at.call(300.0)])
	var days: Array = [264.0, 288.0, 300.0].map(func(hour: float) -> float: return open_at.call(hour))
	_verdict.check(got["days"] == days, "each day, those open at its end - the last day's end being now: %s against %s" % [got["days"], days])


func _a_spread_is_the_middle_and_each_day_a_band_around_it() -> void:
	var got: Dictionary = _run({"figures": {&"repair": {"how": Rollup.SPREAD, "of": &"repair", "when": &"restored"}}})["figures"][&"repair"]
	var repairs: Array = _by_hand(func(row: int) -> bool: return _in(row, &"restored", NOW)).map(func(row: int) -> float: return _rows.value_at(row, &"repair"))
	repairs.sort()
	_verdict.check(got["now"] == repairs[int(0.5 * (repairs.size() - 1))], "the whole stretch's is the middle repair: %s" % [got["now"]])
	var banded: bool = got["days"].all(func(day: Variant) -> bool: return day == null or (day[0] <= day[1] and day[1] <= day[2]))
	var wide: bool = got["days"].any(func(day: Variant) -> bool: return day != null and day[0] < day[2])
	_verdict.check(banded and wide, "each day is a band, the quarter below at or under the middle and the quarter above at or over it: %s" % [got["days"]])


func _a_split_holds_every_word_and_is_never_narrowed_by_its_own_column() -> void:
	var spec := {"splits": {&"regions": {"how": Rollup.COUNT, "when": &"reported", "by": &"region"}, &"teams": {"how": Rollup.COUNT, "when": &"reported", "by": &"team"}}}
	var got: Dictionary = _run(spec)["splits"]
	var regions: Array = got[&"regions"].map(func(one: Dictionary) -> String: return one["key"])
	var london: Dictionary = got[&"regions"].filter(func(one: Dictionary) -> bool: return one["key"] == "London")[0]
	var in_london := range(_rows.count()).filter(func(row: int) -> bool: return _rows.value_at(row, &"region") == "London" and _in(row, &"reported", NOW)).size()
	_verdict.check(regions == ["East", "London", "Wales"] and london["now"] == float(in_london) and in_london > 0, "split by region with Wales filtered, every region is there in a reader's order, London's own count kept: %s, %s" % [regions, london])
	var teams: float = got[&"teams"].reduce(func(sum: float, one: Dictionary) -> float: return sum + one["now"], 0.0)
	_verdict.check(teams == _run({"figures": {&"all": {"how": Rollup.COUNT, "when": &"reported"}}})["figures"][&"all"]["now"], "split by team, the filter's region still narrows it: the teams add up to Wales's count, %s" % teams)


func _the_clauses_a_figure_is_taken_over_keep_exactly_the_rows_it_counted() -> void:
	var measures := {&"reported": {"how": Rollup.COUNT, "when": &"reported", "where": [{"column": &"customers", "test": RowQuery.OVER, "value": 100.0}]}, &"open": {"how": Rollup.COUNT, "when": Rollup.OPEN}}
	var got: Dictionary = _run({"figures": measures})["figures"]
	# every figure, its rows kept by its clauses against its count
	for name: StringName in measures:
		var kept: PackedInt32Array = RowQuery.run(_rows, Rollup.clauses_for(measures[name], _wales(), NOW, TIMES), {}, &"")["order"]
		_verdict.check(float(kept.size()) == got[name]["now"] and kept.size() > 0, "the %s figure's clauses keep exactly the %s rows it counted: %d" % [name, got[name]["now"], kept.size()])
