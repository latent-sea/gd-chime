extends Node

const GdChime := preload("res://addons/gd_chime/gd_chime.gd")

## The network the operations console watches, made up: five hundred
## devices, each Healthy, Warning, Offline or Recovering, reporting how long
## a round trip took and when their status moves - about two hundred events
## a second - and the link to them dropping now and then for a few seconds.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## IT IS A SOURCE (stream.gd): open(stream) starts it pushing into that
## stream and saying its connection there; close() stops it. It knows
## nothing of screens. Time is its own, seconds since it first opened,
## carried on every event as "at". The random numbers are seeded, so every
## run is the same network.
##
## An event is {at, device, latency} - a reading in milliseconds - or
## {at, device, status}, the device's status moving on round its cycle:
## Healthy, then Warning, then either Healthy again or Offline, then
## Recovering, then Healthy. A device's readings run high while it is
## Warning and stop while it is Offline.

const HEALTHY := "healthy"
const WARNING := "warning"
const OFFLINE := "offline"
const RECOVERING := "recovering"
const COUNT := 500
## Events a second, and of them how many move a status.
const RATE := 200.0
const MOVES := 0.04
## How long the link stays up between drops, and how long a drop lasts, in seconds.
const LINKED_FOR := 40.0
const DROPPED_FOR := 3.0

## Events pushed so far, for a reader measuring.
var pushed_count: int = 0

var _stream: GdChime.Stream = null  # where events go while open, or none
var _random := RandomNumberGenerator.new()
var _statuses: PackedStringArray = []
var _usual: PackedFloat32Array = []  # each device's usual round trip, in milliseconds
var _clock: float = 0.0  # seconds since it first opened
var _owed: float = 0.0  # events due but not yet pushed, a fraction carried
var _link_moves_at: float = 1.0  # when the link next drops or comes back
var _linked: bool = false


func _init() -> void:
	_random.seed = 5
	# every device, most healthy, some already in trouble, each with a usual round trip
	for device: int in COUNT:
		var roll := _random.randf()
		_statuses.append(OFFLINE if roll < 0.03 else WARNING if roll < 0.09 else RECOVERING if roll < 0.11 else HEALTHY)
		_usual.append(_random.randf_range(4.0, 60.0))


func _ready() -> void:
	set_process(false)


## The devices' names, their statuses as they stand, in order: each {id, name, status}.
func get_devices() -> Array:
	return range(COUNT).map(func(device: int) -> Dictionary: return {"id": device, "name": "D-%03d" % device, "status": _statuses[device]})


func open(stream: GdChime.Stream) -> void:
	_stream = stream
	_stream.set_connection(GdChime.Stream.CONNECTING)
	set_process(true)


func close() -> void:
	_stream = null
	set_process(false)


func _process(delta: float) -> void:
	_clock += delta
	if _clock >= _link_moves_at:
		_linked = not _linked
		_link_moves_at = _clock + (LINKED_FOR if _linked else DROPPED_FOR)
		_stream.set_connection(GdChime.Stream.CONNECTED if _linked else GdChime.Stream.RECONNECTING)
	if not _linked:
		return
	_owed += RATE * delta
	# every event due by now, each a reading or a status moving on
	while _owed >= 1.0:
		_owed -= 1.0
		_stream.push(_event())
		pushed_count += 1


## One event: a device's status moving on round its cycle, or a reading.
func _event() -> Dictionary:
	var device := _random.randi_range(0, COUNT - 1)
	if _random.randf() < MOVES:
		_statuses[device] = _next_status(_statuses[device])
		return {"at": _clock, "device": device, "status": _statuses[device]}
	if _statuses[device] == OFFLINE:
		return {"at": _clock, "device": device, "status": OFFLINE}
	var high := 4.0 if _statuses[device] == WARNING else 1.0
	return {"at": _clock, "device": device, "latency": _usual[device] * high * _random.randf_range(0.7, 1.4)}


## The status after this one: a warning clears as often as it worsens, and
## a healthy device warns seldom enough that most stay healthy.
func _next_status(status: String) -> String:
	match status:
		HEALTHY: return WARNING if _random.randf() < 0.35 else HEALTHY
		WARNING: return OFFLINE if _random.randf() < 0.5 else HEALTHY
		OFFLINE: return RECOVERING
	return HEALTHY
