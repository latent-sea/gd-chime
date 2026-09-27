extends "res://addons/gd_chime/controller.gd"

const GdChime := preload("res://addons/gd_chime/gd_chime.gd")
const Network := preload("res://demo/apps/console/network.gd")

## What the operations console shows, made from the network's events as the
## stream hands them on (stream.gd): the devices' statuses, the incidents
## opened and closed, the log of every event, the two charts' series, and
## the one device or incident being inspected.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Every model is the floor's: the devices are keyed items (a tile's bell
## each), the incidents and the log feeds, the charts rolling series, the
## alerts paced notices. This turns an event into their words: a device
## warning or going offline opens an incident, one coming back healthy
## closes it, and one going offline is an alert. Only the last reading of
## each device is its own, kept for the device inspected.
##
## INSPECTED is the device a pop-up is showing: an incident's, or a tile's,
## a value (value.gd). Reading it reads that device's status and, paced,
## its reading, so the pop-up goes on living while the stream runs behind it.

## The commands: inspect the incident the cursor is on; inspect a device, {"device"}.
const INSPECTS_INCIDENT := &"inspects_the_incident"
const INSPECTS_DEVICE := &"inspects_a_device"
## Every action this is told.
const COMMANDS: Array[StringName] = [INSPECTS_INCIDENT, INSPECTS_DEVICE]
## A status as the floor draws it, by the network's word for it.
const STATES := {Network.HEALTHY: GdChime.Status.WELL, Network.WARNING: GdChime.Status.NOTICE, Network.OFFLINE: GdChime.Status.FAULT, Network.RECOVERING: GdChime.Status.MENDING}
## A status in words, by the network's word: shown on its own, and said
## within a log's line - "Now recovering".
const STATUS_WORDS := {Network.HEALTHY: "Healthy", Network.WARNING: "Warning", Network.OFFLINE: "Offline", Network.RECOVERING: "Recovering"}

var devices: GdChime.KeyedItems
var incidents: GdChime.Feed
var log: GdChime.Feed
var latency: GdChime.RollingSeries
var rate: GdChime.RollingSeries
var notices: GdChime.PacedNotices

var _names: PackedStringArray = []  # each device's name
var _readings: PackedFloat32Array = []  # each device's last round trip, in milliseconds
var _open := value({})  # device -> the incident open for it
var _inspected := value(-1)  # the device inspected, or none
var _paced := value(0)  # moved on at the look's cadence while the inspected device's readings come
var _pacing: GdChime.Throttle


func _init(chimes: Chimes, network: Network, alerts: GdChime.PacedNotices) -> void:
	super(chimes)
	var listed := network.get_devices()
	devices = GdChime.KeyedItems.new(chimes, listed, &"id", [&"status"])
	_names = PackedStringArray(listed.map(func(one: Dictionary) -> String: return one["name"]))
	_readings.resize(listed.size())
	incidents = GdChime.Feed.new(chimes, 2000, 12)
	log = GdChime.Feed.new(chimes, 4000, 12)
	latency = GdChime.RollingSeries.new(chimes, [{"name": Phrase.of("Average round trip"), "kind": GdChime.RollingSeries.MEAN}], 1.0, 60, Phrase.of("Seconds"), Phrase.of("Round trip, ms"))
	rate = GdChime.RollingSeries.new(chimes, [{"name": Phrase.of("Opened"), "kind": GdChime.RollingSeries.PER_MINUTE}, {"name": Phrase.of("Closed"), "kind": GdChime.RollingSeries.PER_MINUTE}], 10.0, 30, Phrase.of("Seconds"), Phrase.of("A minute"))
	notices = alerts
	_pacing = GdChime.Throttle.new(func() -> void: _paced.set_value(_paced.read() + 1), {paced_by = GdChime.Throttle.CADENCE})
	for model: Node in [devices, incidents, log, latency, rate, _pacing]:
		add_child(model)


## A batch of the network's events, oldest first: every model moved by each.
func take(batch: Array) -> void:
	var lines: Array = []
	# every event, read as a reading or a status
	for event: Dictionary in batch:
		var device: int = event["device"]
		if event.has("latency"):
			_readings[device] = event["latency"]
			latency.take(0, event["at"], event["latency"])
			lines.append(_line(event, Phrase.with("Round trip %d ms", [roundi(event["latency"])])))
		else:
			_status(event, lines)
		if device == _inspected.read():
			_pacing.ask()
	log.append(lines)


## A status in an event: the device's set, an incident opened or closed, an alert, and its line in the log.
func _status(event: Dictionary, lines: Array) -> void:
	var device: int = event["device"]
	var status: String = event["status"]
	if devices.get_item(device)["status"] == status:
		lines.append(_line(event, Phrase.of("No reply")))
		return
	devices.set_field(device, &"status", status)
	lines.append(_line(event, now_of(status)))
	if (status == Network.WARNING or status == Network.OFFLINE) and not _open.read().has(device):
		_open.set_value(_open.read().merged({device: true}))
		rate.take(0, event["at"], 1.0)
		var words := Phrase.of("Round trips far slower than usual") if status == Network.WARNING else Phrase.of("Stopped answering")
		incidents.append([{"time": GdChime.Formats.written_elapsed(event["at"], GdChime.Formats.HOURS, 1), "device": device, "name": _names[device], "status": status, "words": words}])
	if status == Network.OFFLINE:
		notices.notify(Phrase.with("%s stopped answering", [_names[device]]), INSPECTS_DEVICE, {"device": device})
	if status == Network.HEALTHY and _open.read().has(device):
		var open: Dictionary = _open.read().duplicate()
		open.erase(device)
		_open.set_value(open)
		rate.take(1, event["at"], 1.0)


func _line(event: Dictionary, words: Phrase) -> Dictionary:
	return {"time": GdChime.Formats.written_elapsed(event["at"], GdChime.Formats.HOURS, 1), "device": event["device"], "name": _names[event["device"]], "words": words}


## The device inspected: {name, status, reading}, or null - its reading
## read again at the look's cadence as readings come.
func get_inspected() -> Variant:
	var inspected: int = _inspected.read()
	_paced.read()
	if inspected < 0:
		return null
	return {"name": _names[inspected], "status": devices.get_item(inspected)["status"], "reading": roundi(_readings[inspected])}


## How many incidents are open now.
func get_open_count() -> int:
	return _open.read().size()


## A status in the floor's states, by the network's word.
static func state_of(status: Variant) -> Variant:
	return null if status == null else STATES[status]


## A status in words, shown on its own, by the network's word.
static func words_of(status: Variant) -> Variant:
	return null if status == null else Phrase.of(STATUS_WORDS[status])


## A status become: "Now recovering", its words said within the sentence.
static func now_of(status: String) -> Phrase:
	return Phrase.with("Now %s", [Phrase.within(STATUS_WORDS[status])])


## Inspecting an incident with the cursor on none is refused.
func would(action: StringName, _payload: Dictionary) -> Phrase:
	if action == INSPECTS_INCIDENT and incidents.get_entry() == null:
		return Phrase.of("Move onto an incident first")
	return null


func told(action: StringName, payload: Dictionary) -> Phrase:
	_inspected.set_value(incidents.get_entry()["device"] if action == INSPECTS_INCIDENT else payload["device"])
	return null


## Every action this model is told.
func answers() -> Array[StringName]:
	return COMMANDS
