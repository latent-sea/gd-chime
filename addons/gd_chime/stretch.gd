extends RefCounted

const Value := preload("components/primitives/value.gd")
const Options := preload("components/primitives/options.gd")
const Phrase := preload("phrase.gd")

## The stretch of time a filters' date column stands in (filters.gd): the
## preset a reader picked out of the ones handed in as data, or the days
## they set by hand, and the stretch as long just before it.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE PRESETS ARE DATA, never a list written here: each is {value, words,
## days}, days being how many it runs back from today, and one with NO days
## is the stretch SET BY HAND - its first and last day the reader's,
## SETS_FIRST_DAY and SETS_LAST_DAY {value: a day, or null for a line that
## is no date}, the payload a date field's press carries. So today, the
## last 7 days and the last 30 are an application's words and numbers, and
## nothing here knows what any of them is called. A day that is no date,
## one that has not come yet and one that runs the stretch backwards are
## refused in words, on the control that asked.
##
## TIME IS THE DATA'S OWN, in HOURS since 1970, and a day is a whole number
## of days since then (packed_rows.gd): now is handed in, so a stretch ends
## where the data does and today is the day that holds now. THE STRETCH
## BEFORE is as long and ends where this one starts, so a figure can be set
## beside what it was then (rollup.gd).
##
## IT HANGS NO BELL: its three values are the filters' own (value.gd), made
## by the maker handed in, so an end moved rings the filters' one bell and
## whoever follows the filters follows this with them.
##
## Deliberately absent: a time of day, a stretch compared with any other
## than the one before it, and presets of months or years - the ends of a
## stretch are days.

const PICKS := &"picks_a_stretch"
const SETS_FIRST_DAY := &"sets_the_first_day"
const SETS_LAST_DAY := &"sets_the_last_day"
const COMMANDS: Array[StringName] = [PICKS, SETS_FIRST_DAY, SETS_LAST_DAY]
## What a date column is declared with: the column of hours, the data's now, the presets, and the one it starts on.
const SPEC: Array[String] = ["column", "now", "presets", "starts"]
const HOURS := 24.0

var _now: float  # the data's now, in hours
var _presets: Array  # each {value, words, days}, the days left out where the reader sets the ends
var _picked: Value
var _first: Value  # the first day of the stretch set by hand
var _last: Value  # and its last


## The dates a filters declared, and the maker of its values: the stretch
## starts on the preset named, its own ends on today until the reader moves one.
func _init(spec: Dictionary, value: Callable) -> void:
	Options.checked("a filters' dates", spec, SPEC)
	_now = spec["now"]
	_presets = spec["presets"]
	_picked = value.call(spec["starts"])
	_first = value.call(get_today())
	_last = value.call(get_today())


## The day that holds now, counted from 1970.
func get_today() -> int:
	return floori(_now / HOURS)


## The stretches to pick from, as a choice's options.
func get_presets() -> Array:
	return _presets


func get_picked() -> StringName:
	return _picked.read()


## Whether the stretch picked is the one set by hand: a preset of no days.
func get_by_hand() -> bool:
	return _days_of(_picked.read()) == 0


func get_first_day() -> int:
	return _first.read()


func get_last_day() -> int:
	return _last.read()


## The stretch shown, and the one before it as long: each {from, to} in
## hours - to never past now - and its first day and how many days it runs.
func get_stretches() -> Dictionary:
	var days := _days_of(_picked.read())
	var first: int = get_today() - days + 1 if days > 0 else _first.read()
	var last: int = get_today() if days > 0 else _last.read()
	var runs: int = last - first + 1
	var now := {"from": first * HOURS, "to": minf((last + 1) * HOURS, _now), "first_day": first, "days": runs}
	return {"now": now, "before": {"from": (first - runs) * HOURS, "to": first * HOURS, "first_day": first - runs, "days": runs}}


## A day that is no date, one to come, and one that puts the first after the last, each refused.
func would(action: StringName, payload: Dictionary) -> Phrase:
	if action == PICKS:
		return null
	if payload["value"] == null:
		return Phrase.of("That is not a date")
	var day: int = payload["value"]
	if day > get_today():
		return Phrase.of("That day has not come yet")
	if (action == SETS_FIRST_DAY and day > _last.read()) or (action == SETS_LAST_DAY and day < _first.read()):
		return Phrase.of("The first day is after the last")
	return null


## A stretch picked, or an end of the one set by hand moved.
func told(action: StringName, payload: Dictionary) -> void:
	match action:
		PICKS: _picked.set_value(payload["value"])
		SETS_FIRST_DAY: _first.set_value(payload["value"])
		SETS_LAST_DAY: _last.set_value(payload["value"])


## How many days a preset runs back from today; none at all where the reader sets its ends.
func _days_of(picked: StringName) -> int:
	# every preset, for the one picked
	for preset: Dictionary in _presets:
		if preset["value"] == picked:
			return preset.get("days", 0)
	return 0
