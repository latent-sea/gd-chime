extends "controller.gd"

const Actions := preload("actions.gd")
const Inputs := preload("input_map.gd")
const Relay := preload("relay.gd")
const Dates := preload("dates.gd")
const Language := preload("language.gd")
const Formats := preload("formats.gd")

## The calendar: which date field opened it last, the month it shows, and a
## day picked from it sent on through the door as that field's own press.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## ONE CALENDAR SERVES EVERY DATE FIELD, as one context menu serves every
## row (open_menu.gd): a field's opener, OPENS, is a press opening the
## calendar's pop-up carrying {action, day} as the pop-up's PARAMETER - the
## field's action, and the day it holds or none. This is told the press
## before the pop-up rises, and notes it: the field it is for, the region
## the opener was pressed in, where a pick is pressed, and the month to
## show. A pick carries the parameter it was picked under, handed to the
## pop-up's days as a bound value, so this reads nothing of the driver.
##
## THE MONTH SHOWN IS THIS MODEL'S: set, as the calendar opens, to the month
## of the day the field holds, else of today; turned a month at a time by
## SHOWS_MONTH_BEFORE and SHOWS_MONTH_AFTER - keys and pad buttons of their own, since a press
## carrying a payload is never a shortcut's. The days shown are always six
## weeks from the Monday on or before the first, so the grid never changes
## shape as months turn and the reader's place in it does not jump.
##
## A PICK IS THE FIELD'S OWN PRESS (relay.gd): PICKS {value: the day, for:
## the parameter the calendar is up as - none while it is down} lowers
## the calendar and dispatches the field's action carrying {"value": the
## day, "line": the day typed} - what the field carries for a typed day - so
## a day the field's model refuses is refused on the calendar before it is
## picked, drawn inert with the reason, exactly as that model refuses a line.
##
## Deliberately absent: a range picked in one calendar, weeks starting on
## any day but Monday, and years turned but a month at a time.

## The press opening the calendar, {"parameter": {action, day}}; a day picked, {"value", "for"}; the months either side.
const OPENS := &"opens_the_calendar"
const PICKS := &"picks_a_day"
const SHOWS_MONTH_BEFORE := &"shows_the_month_before"
const SHOWS_MONTH_AFTER := &"shows_the_month_after"
## The days of the week as the grid heads them, Monday first.
const WEEKDAY_WORDS: Array[String] = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
## How many days the grid shows: six weeks.
const SHOWN := 42

var _door: Object
var _year := value(1970)
var _month := value(1)
var _opened := value(null)  # the parameter the calendar was last opened with: {action, day}
var _opened_in: StringName = Chimes.GLOBAL  # the region the opener was pressed in, where a pick is pressed


func _init(chimes: Chimes, door: Object) -> void:
	super(chimes, [], Chimes.GLOBAL)
	_door = door


## Every action declared with its words and inputs, and this answering its own from anywhere.
func declare(register: Actions) -> void:
	register.declare_all({OPENS: ["Calendar"]})
	register.declare_all({PICKS: ["Pick the day"]})
	register.declare_all({SHOWS_MONTH_BEFORE: ["The month before", Actions.keys(KEY_PAGEUP), Actions.pad(JOY_BUTTON_LEFT_SHOULDER)]})
	register.declare_all({SHOWS_MONTH_AFTER: ["The month after", Actions.keys(KEY_PAGEDOWN), Actions.pad(JOY_BUTTON_RIGHT_SHOULDER)]})
	# every action a press of which this answers
	for action: StringName in [OPENS, PICKS, SHOWS_MONTH_BEFORE, SHOWS_MONTH_AFTER]:
		_door.register(Chimes.GLOBAL, action, self)


## The month shown, in words: September 2026.
func get_title() -> Phrase:
	var year: int = _year.read()
	var month: int = _month.read()
	return Phrase.written(func() -> String: return "%s %d" % [Language.word(Formats.MONTHS[month - 1], Formats.MONTH), year])


## The six weeks shown, day by day from the Monday on or before the month's
## first: {value - the day, at - its place in the grid, words - its number,
## state - chosen, today, outside the month, or in it}.
func get_days() -> Array:
	var month: int = _month.read()
	var first := Dates.day_of(_year.read(), month, 1)
	var start: int = first - Dates.parts_of(first)["weekday"]
	var chosen: Variant = _chosen()
	var today := Dates.today()
	var days: Array = []
	# every day of the six weeks, its state read against the month, the field's day and today
	for at: int in SHOWN:
		var day: int = start + at
		var parts := Dates.parts_of(day)
		# the field's day marked wherever it falls, then a day of another month, then today
		var state := &"chosen" if day == chosen else &"outside" if parts["month"] != month else &"today" if day == today else &"in"
		days.append({"value": day, "at": at, "words": str(parts["day"]), "state": state})
	return days


## The day the focus lands on as the calendar opens: the field's day where
## this month holds it, else the first of the month shown.
func get_focused() -> int:
	var chosen: Variant = _chosen()
	if chosen != null and Dates.parts_of(chosen)["month"] == _month.read() and Dates.parts_of(chosen)["year"] == _year.read():
		return chosen
	return Dates.day_of(_year.read(), _month.read(), 1)


## A pick is refused as the field's own press would be, and while the
## calendar is not up: while it is up it stands over everything, so nothing
## else the reader does moves the field's model, and a pick asks again as it
## lands. It reads the parameter it carries and the field's model's refusal,
## and nothing of the month - forty-two days are not drawn again as it turns.
func would(action: StringName, payload: Dictionary) -> Phrase:
	if action == PICKS:
		return Phrase.of("The calendar is not open") if payload["for"] == null else Relay.refusal(_door, _entry(payload))
	return null


func told(action: StringName, payload: Dictionary) -> Phrase:
	match action:
		OPENS:
			_opened_in = _door.get_last()["region"]
			_opened.set_value(payload["parameter"])
			# opened afresh, the calendar shows the month of the field's day, else of today
			var parts := Dates.parts_of(_chosen() if _chosen() != null else Dates.today())
			_year.set_value(parts["year"])
			_month.set_value(parts["month"])
		PICKS:
			return Relay.send(_door, _entry(payload))
		SHOWS_MONTH_BEFORE, SHOWS_MONTH_AFTER:
			# months counted from year nought, one on or one back, and split again into the year and its month
			var months: int = _year.read() * 12 + _month.read() - 1 + (1 if action == SHOWS_MONTH_AFTER else -1)
			_year.set_value(floori(months / 12.0))
			_month.set_value(posmod(months, 12) + 1)
	return null


## The day the field held as the calendar was last opened, or none.
func _chosen() -> Variant:
	var opened: Variant = _opened.read()
	return null if opened == null else opened["day"]


## The field's own press a pick stands for: the day, pressed as the field it was opened for.
func _entry(picked: Dictionary) -> Dictionary:
	return {"action": picked["for"]["action"], "region": _opened_in, "payload": {"value": picked["value"], "line": Dates.typed(picked["value"])}}
