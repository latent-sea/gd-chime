extends "res://addons/gd_chime/controller.gd"

const GdChime := preload("res://addons/gd_chime/gd_chime.gd")
const MobileData := preload("res://demo/apps/mobile/mobile_data.gd")

## The carrier's depot, standing in, and the phone's signal to it: every
## change the driver makes is sent here and answered later - kept, or
## refused with a reason - and a refresh asks it for the route again.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## What the floor is handed as the far side: send(request, answer) for the
## provisional changes (through the outbox, outbox.gd), fetch(answer) for a
## asking again (fetched.gd). A request is answered DELAY_MS after it is sent, a
## fetch FETCH_MS after, from _process - on the main thread, never within the
## call that asked. It refuses a delivery of the stop the sender cancelled,
## always; a fetch with no signal fails, "No connection", and so does the
## next one after fails_next is set, as a depot that did not answer. The
## first fetch brings the morning's route, every later one the route as it
## stands later in the day.
##
## THE SIGNAL IS SIMULATED. No phone is here to lose it, so the reader turns
## it with SETS_SIGNAL {"on"} - a switch the app shows and says is a
## simulation - and this tells the connection (connection.gd), the phone's
## own say of whether the depot can be reached.

const SETS_SIGNAL := &"sets_the_signal"
## The one action this is told.
const COMMANDS: Array[StringName] = [SETS_SIGNAL]
const DELAY_MS := 600
const FETCH_MS := 900
## The stop whose sender cancelled it, and why a delivery of it is refused.
const CANCELLED := 9

## The phone's connection to here, told as the signal moves.
var connection: GdChime.Connection
## Whether the next fetch fails as if the depot did not answer.
var fails_next: bool = false
## Whether answers wait until answer_all() is called: a probe holds them, so what it reads between is certain.
var held: bool = false
var _queue: Array[Dictionary] = []  # every request and fetch not yet answered, oldest first
var _fetched_once: bool = false  # whether the route has been fetched once: later, it is the depot's later route


func _init(chimes: Chimes) -> void:
	super(chimes, [], Chimes.GLOBAL)
	connection = GdChime.Connection.new(chimes)
	add_child(connection)
	connection.set_state(GdChime.Connection.CONNECTED)
	set_process(false)


## A change sent: answered a moment from now.
func send(request: Dictionary, answer: Callable) -> void:
	_queue.append({"due": Time.get_ticks_msec() + DELAY_MS, "request": request, "answer": answer})
	set_process(true)


## The route asked for again: answered a moment from now.
func fetch(answer: Callable) -> void:
	_queue.append({"due": Time.get_ticks_msec() + FETCH_MS, "fetch": true, "answer": answer})
	set_process(true)


## Every request queued answered now, whatever the time: for a probe and a measure.
func answer_all() -> void:
	# every one queued, answered as if its moment had come
	for waiting: Dictionary in _queue:
		waiting["due"] = 0
	_answer()


func _process(_delta: float) -> void:
	if not held:
		_answer()


## Every one whose moment has passed answered, oldest first.
func _answer() -> void:
	var now := Time.get_ticks_msec()
	# every one whose moment has passed, oldest first
	while not _queue.is_empty() and _queue[0]["due"] <= now:
		var asked: Dictionary = _queue.pop_front()
		if asked.has("fetch"):
			_fetched(asked["answer"])
		else:
			asked["answer"].call(_refusal(asked["request"]))
	if _queue.is_empty():
		set_process(false)


## A fetch answered: the route, or why not.
func _fetched(answer: Callable) -> void:
	if not connection.get_online():
		answer.call(null, Phrase.of("No connection"))
		return
	if fails_next:
		fails_next = false
		answer.call(null, Phrase.of("The depot did not answer"))
		return
	answer.call(MobileData.made() if not _fetched_once else MobileData.again(), null)
	_fetched_once = true


## Why the depot will not keep a change, or nothing.
func _refusal(request: Dictionary) -> Variant:
	if request["id"] == CANCELLED and request["status"] == "delivered":
		return Phrase.with("The sender cancelled stop %d", [CANCELLED])
	return null


## Whether the phone has a signal.
func get_signal() -> bool:
	return connection.get_online()


## The signal turned on or off: the connection told.
func told(_action: StringName, payload: Dictionary) -> Phrase:
	connection.set_state(GdChime.Connection.CONNECTED if payload["on"] else GdChime.Connection.LOST)
	return null


## Every action this model is told.
func answers() -> Array[StringName]:
	return COMMANDS
