extends "res://addons/gd_chime/controller.gd"

const GdChime := preload("res://addons/gd_chime/gd_chime.gd")

## The driver's route today: every stop, in the order it is driven, and what
## has happened at each - still to deliver, delivered, or a problem and
## which - every change made at once and sent to the depot provisionally.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE ROUTE LOADS AS ITS SCREEN IS FIRST SHOWN (fills): what the screen
## fills with asks the depot, the one model of that screen, told only to ask
## again (fetched.gd); until it lands no stop stands to press. Asking again
## after that - pulled, pressed - is the same asking under a token of its
## own, and brings the depot's route: new stops join, and every stop's
## address, name and note are the depot's, while what the driver has done at
## each stays the driver's. A failed asking loses nothing.
##
## A CHANGE IS ONE COMMAND ABOUT ONE STOP, {id}: DELIVERS, REPORTS {why} -
## one of PROBLEMS, nobody home when a swipe gives none - and UNDOES, back to
## still to deliver. Each stands at once and is sent (provisional.gd) through
## whatever far side the application hands the provisional changes - an
## outbox, which holds it while there is no signal; a refusal puts the stop
## back as it was and says why. A change the stop already has is refused, in
## words, so a swipe springs back saying so.

const DELIVERS := &"delivers_a_stop"
const REPORTS := &"reports_a_problem"
const UNDOES := &"undoes_a_stop"
## Every action this is told.
const COMMANDS: Array[StringName] = [DELIVERS, REPORTS, UNDOES]
## What has happened at a stop, and each said in words: shown on its own,
## and within a change's words - "Stop 9, delivered".
const TO_DELIVER := &"to_deliver"
const DELIVERED := &"delivered"
const PROBLEM := &"problem"
const STATUS_WORDS := {TO_DELIVER: "To deliver", DELIVERED: "Delivered", PROBLEM: "A problem"}
## Why a stop could not be delivered, by name, in the driver's words.
const PROBLEM_WORDS := {&"nobody_home": "Nobody home", &"no_access": "No way in", &"damaged": "Parcel damaged"}

## What the route's screen fills with, asked of the depot as it is entered
## and again whenever the driver asks (fetched.gd): its .data is the depot's
## route, nothing until it lands.
var stops: GdChime.Fetched
var _provisional: GdChime.Provisional
var _stops := value({})  # id -> the stop, with its status and why
var _order := value([])  # the ids, in the order driven


func _init(chimes: Chimes, provisional: GdChime.Provisional, fetches: Callable, notices: GdChime.Notifications) -> void:
	super(chimes)
	_provisional = provisional
	stops = GdChime.Fetched.new(chimes, fetches, notices, Phrase.of("Today's stops"))
	add_child(stops)
	# the depot's route taken as it lands
	follow(&"stops", _landed)


## Every stop in the order driven, with its status.
func get_stops() -> Array:
	return _order.read().map(func(id: int) -> Dictionary: return _stops.read()[id])


## One stop, bound: whichever id the bound value reads, or none.
func stop(id: RefCounted) -> RefCounted:
	return Bound.new(func() -> Variant: return _stops.read().get(id.read()))


func get_delivered() -> int:
	return _order.read().filter(func(id: int) -> bool: return _stops.read()[id]["status"] == DELIVERED).size()


func get_whole() -> int:
	return _order.read().size()


## What the screen filled with, read as it lands: the depot's route. Taking
## it is done APART from the reading (reads.gd), since taking it sets this
## model's own values, which this would otherwise follow into a circle.
func _landed() -> void:
	var route: Variant = stops.data.read()
	if route != null:
		GdChime.Reads.apart(func() -> void: lands(route))


## The depot's route: its stops' facts taken, what the driver did at each kept.
func lands(route: Array) -> void:
	# every stop the depot has, joined or brought up to date
	for fresh: Dictionary in route:
		if not _stops.read().has(fresh["id"]):
			_order.read().append(fresh["id"])
			_stops.read()[fresh["id"]] = fresh.merged({"status": TO_DELIVER, "why": &""})
		_stops.read()[fresh["id"]].merge(fresh, true)
	_moved()


func would(action: StringName, payload: Dictionary) -> Phrase:
	var loading := stops.would(action, payload)
	if loading != null:
		return loading
	# a press about no stop: the sheet of actions while it is raised for none
	if not payload.has("id"):
		return Phrase.of("No stop is chosen")
	var now: StringName = _stops.read()[payload["id"]]["status"]
	match action:
		DELIVERS when now == DELIVERED: return Phrase.with("Stop %d is delivered already", [payload["id"]])
		REPORTS when now == PROBLEM: return Phrase.with("Stop %d is reported already", [payload["id"]])
		UNDOES when now == TO_DELIVER: return Phrase.with("Stop %d is still to deliver", [payload["id"]])
	return null


func told(action: StringName, payload: Dictionary) -> Phrase:
	match action:
		DELIVERS: _change(payload["id"], DELIVERED, &"")
		REPORTS: _change(payload["id"], PROBLEM, StringName(payload.get("why", &"nobody_home")))
		UNDOES: _change(payload["id"], TO_DELIVER, &"")
	return null


## A stop's status changed at once and sent, undone back to what it was if the depot refuses.
func _change(id: int, status: StringName, why: StringName) -> void:
	var was: Array = [_stops.read()[id]["status"], _stops.read()[id]["why"]]
	_write(id, status, why)
	_provisional.begin(id, Phrase.with("Stop %d, %s", [id, Phrase.within(STATUS_WORDS[status])]), {"id": id, "status": status, "why": why}, _write.bind(id, was[0], was[1]))


func _write(id: int, status: StringName, why: StringName) -> void:
	_stops.read()[id]["status"] = status
	_stops.read()[id]["why"] = why
	_moved()


## The stops and their order, changed in place, set again for whatever reads them.
func _moved() -> void:
	_stops.set_value(_stops.read())
	_order.set_value(_order.read())


## Every action this model is told.
func answers() -> Array[StringName]:
	return COMMANDS
