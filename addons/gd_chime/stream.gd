extends "controller.gd"

const Throttle := preload("throttle.gd")
const Token := preload("token.gd")

## A stream: the events a source pushes, handed to the models that take them
## once a frame, for as long as a place's stay lasts - held while the reader
## has it paused, and caught up on as it resumes.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE SOURCE PUSHES; THIS HANDS ON. A source is anything with open(stream)
## and close() - a socket's reader, a simulation - that calls this stream's
## push(event) as each event comes, on the main thread, at any rate, and
## its set_connection() as the connection moves. Events pushed in a
## frame are handed on once, at its end (throttle.gd), as one batch oldest
## first, to every sink - a function taking an array of events, a model's
## own. A model taking a batch changes as it likes and rings its own bells,
## gathered as a keyed item's are, so hundreds of events a second are one
## round of bells a frame.
##
## A SUBSCRIPTION IS A STAY. open(token) is what a place's on_fill calls,
## with the token of the reader's stay (place.gd): the source is opened
## then, and close(), its on_empty, closes it. A push arriving under a
## token no longer live - the place left without close() being called -
## closes the source there and then, and lands nowhere. Nothing arrives
## while nobody is there to read it.
##
## PAUSED, NOTHING IS HANDED ON, AND NOTHING IS LOST UP TO A LIMIT: events
## are held, oldest first, and resumed, what was held is handed on before
## anything newer. Past the capacity given, the oldest held is let go and
## counted as MISSED, so the newest - what a status now is - always
## survives. The pause is the reader's, a value set at once (value.gd);
## how many are held and how many a second arrive are read live, and move
## for their reader at the look's cadence - a value, PACED, set as often as
## the look says - so a status line is not drawn again for every event.
##
## A FRAME HANDS ON SO MANY AT MOST, the rest the next frame and the next,
## oldest first: catching up on twenty seconds held never stops the
## screen for the length of one frame of four thousand events - measured,
## four hundred milliseconds - but spreads them, the console live while it
## catches up. RUNNING, THE SAME CAPACITY HOLDS: a source outrunning a
## frame's share never leaves the stream behind forever - past it the oldest
## waiting are let go and counted as missed. How far BEHIND it is (events
## waiting) and how many were MISSED this stay are reads, for a status line.
##
## THE CONNECTION IS THE SOURCE'S TO SAY: set_connection(state) with one of
## CONNECTION's words, a value, for a status line.
##
## Deliberately absent: a second source, and a filter on what is handed on.

## The command that pauses or resumes it, {"on": whether paused}.
const HOLDS := &"holds_the_stream"
## The one action this is told.
const COMMANDS: Array[StringName] = [HOLDS]
## The states of the connection a source may say.
const CONNECTING := &"connecting"
const CONNECTED := &"connected"
const RECONNECTING := &"reconnecting"
const LOST := &"lost"

## Events handed on so far, for a reader measuring.
var handed_count: int = 0

var _source: Object
var _sinks: Array[Callable]
var _capacity: int
var _most: int  # events handed on in one frame at most
var _token: Token = null  # the stay it is open for, or none while closed
var _arrived: Array = []  # events waiting to be handed on, oldest first: this frame's, and any the frames before could not take
var _held: Array = []  # events pushed while paused, oldest first
var _missed: int = 0  # events let go past the capacity, held or waiting, since the stay began
var _paused := value(false)
var _connection := value(LOST)
var _opened := value(false)  # whether a stay has it open
var _paced := value(0)  # moved on at the look's cadence while events come, so what counts them is read again at that pace
var _second: Array[int] = [0, 0, 0]  # [the second counted, events pushed in it, events pushed in the one before]
var _hand_on: Throttle
var _pacing: Throttle


## Over this source, handing on to these sinks, holding this many while
## paused, and handing on this many in a frame at most.
func _init(chimes: Chimes, source: Object, sinks: Array[Callable], capacity: int, most: int) -> void:
	super(chimes)
	_source = source
	_sinks = sinks
	_capacity = capacity
	_most = most
	_hand_on = Throttle.new(_handed)
	_pacing = Throttle.new(func() -> void: _paced.set_value(_paced.read() + 1), {paced_by = Throttle.CADENCE})
	add_child(_hand_on)
	add_child(_pacing)


## The reader's stay has begun: the source opened, pushing here and saying
## its connection here.
func open(token: Token) -> void:
	_token = token
	_opened.set_value(true)
	_missed = 0
	_source.open(self)


## The reader's stay is over: the source closed, and what was waiting let go.
func close() -> void:
	if _token == null:
		return
	_token = null
	_opened.set_value(false)
	_source.close()
	_arrived.clear()
	_held.clear()
	_pacing.ask()


## One event from the source: handed on at the frame's end, or held while paused.
func push(event: Variant) -> void:
	if _token == null:
		return
	if not _token.is_live():
		close()
		return
	_count_one()
	if not _paused.read():
		_arrived.append(event)
		_hand_on.ask()
		return
	_held.append(event)
	if _held.size() > _capacity:
		_held.pop_front()
		_missed += 1
	_pacing.ask()


## The source says how its connection stands: one of the CONNECTION words.
func set_connection(state: StringName) -> void:
	if state != _connection.read():
		_connection.set_value(state)


func get_paused() -> bool:
	return _paused.read()


func get_connection() -> StringName:
	return _connection.read()


## How many events are held while paused.
func get_held() -> int:
	_paced.read()
	return _held.size()


## How many events were let go past the capacity, held or waiting, since the stay began.
func get_missed() -> int:
	_paced.read()
	return _missed


## How far behind it is: the events waiting past what this frame hands on, none unless outrun.
func get_behind() -> int:
	_paced.read()
	return maxi(_arrived.size() - _most, 0)


## How many events arrived in the last whole second.
func get_rate() -> int:
	_paced.read()
	return _second[2] if _this_second() == _second[0] else (_second[1] if _this_second() == _second[0] + 1 else 0)


## Whether a stay has it open.
func get_open() -> bool:
	return _opened.read()


## Paused already, or running already, is refused.
func would(_action: StringName, payload: Dictionary) -> Phrase:
	if payload["on"] == _paused.read():
		return Phrase.of("Already paused") if _paused.read() else Phrase.of("Already running")
	return null


## Paused: what was waiting is held with the rest, nothing handed on.
## Resumed: what was held handed on from the end of this frame, before anything newer.
func told(_action: StringName, payload: Dictionary) -> Phrase:
	_paused.set_value(payload["on"])
	if _paused.read():
		_held = _arrived
		_arrived = []
	else:
		_arrived = _held
		_held = []
		_hand_on.ask()
	return null


## The frame's end: the oldest waiting, as many as a frame takes, one batch
## to every sink; any left, asked for again as the next frame is processed,
## so it is handed on at that frame's end - one batch a frame, whatever waits.
func _handed() -> void:
	if _arrived.is_empty():
		return
	var batch := _arrived.slice(0, _most)
	_arrived = _arrived.slice(_most)
	# left waiting past the capacity, the oldest let go and counted, as the held are while paused
	var over := _arrived.size() - _capacity
	if over > 0:
		_arrived = _arrived.slice(over)
		_missed += over
	_pacing.ask()
	handed_count += batch.size()
	# every model taking events, handed the same batch
	for sink: Callable in _sinks:
		sink.call(batch)
	set_process(not _arrived.is_empty())


## Entering the tree switches processing on by itself for a script with
## _process: off, until events wait past a frame's share.
func _ready() -> void:
	set_process(false)


func _process(_delta: float) -> void:
	set_process(false)
	_hand_on.ask()


## One more event pushed in the second it came in.
func _count_one() -> void:
	var now := _this_second()
	if now != _second[0]:
		_second = [now, 0, _second[1] if now == _second[0] + 1 else 0]
	_second[1] += 1
	_pacing.ask()


func _this_second() -> int:
	return Time.get_ticks_msec() / 1000


## Every action this model is told.
func answers() -> Array[StringName]:
	return COMMANDS
