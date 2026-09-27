extends RefCounted

const GdChime := preload("res://addons/gd_chime/gd_chime.gd")
const Network := preload("res://demo/apps/console/network.gd")
const Operations := preload("res://demo/apps/console/operations.gd")

## The operations console's panes and pop-ups, described: the wall of five
## hundred devices under its legend, the two live charts, the incidents and
## the log, the status line, and the two inspections.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Every piece is the floor's - a wall (wall.gd), a live feed (live_feed.gd),
## the line chart fed by rolling series, a status (status.gd), a sheet - and
## this names what each shows. An incident row and a log row are lines of
## cells at their columns' widths, so nothing an entry says moves a column.

## A mark stands in a column as wide as two letters of the cells' words, which it never passes.
const MARK_ROOM := "MM"

## The two inspections: an incident, and a device - each a pop-up opened where it is pressed for.
var incident: GdChime.Desc
var device: GdChime.Desc
var _ui: GdChime.Ui
var _operations: Operations
var _stream: GdChime.Stream


func _init(ui: GdChime.Ui, operations: Operations, stream: GdChime.Stream) -> void:
	_ui = ui
	_operations = operations
	_stream = stream
	incident = _incident()
	device = _device()


## The devices: how many stand in each state, over the wall of them all.
func devices() -> GdChime.Desc:
	var counted := func(one: String, many: String) -> Callable: return func(count: int) -> GdChime.Phrase: return GdChime.Phrase.counted(one, many, count)
	var shown := [
		{"value": Network.HEALTHY, "state": GdChime.Status.WELL, "counted": counted.call("%d healthy", "%d healthy")},
		{"value": Network.WARNING, "state": GdChime.Status.NOTICE, "counted": counted.call("%d warning", "%d warning")},
		{"value": Network.OFFLINE, "state": GdChime.Status.FAULT, "counted": counted.call("%d offline", "%d offline")},
		{"value": Network.RECOVERING, "state": GdChime.Status.MENDING, "counted": counted.call("%d recovering", "%d recovering")},
	]
	var devices := _operations.devices
	var tile := func(key: int) -> GdChime.Desc: return GdChime.Wall.tile(_ui, Operations.INSPECTS_DEVICE, {"device": key}, devices.item(key).field("status").map(Operations.state_of), {name = devices.get_item(key)["name"]}).opens(device)
	var wall := _ui.column([GdChime.Wall.legend(_ui, devices, &"status", shown), GdChime.Wall.make(_ui, devices, tile).grow()])
	return GdChime.Panes.titled(_ui, GdChime.Phrase.of("Devices"), wall)


## The two live charts, side by side.
func charts() -> GdChime.Desc:
	var both := _ui.row([GdChime.LineChart.make(_ui, GdChime.Bound.new(_operations.latency.get_chart)).grow(), GdChime.LineChart.make(_ui, GdChime.Bound.new(_operations.rate.get_chart)).grow()])
	return GdChime.Panes.titled(_ui, GdChime.Phrase.of("Round trips, and incidents a minute"), both)


## The incidents, newest at the foot: a row each, Enter or a second press inspecting one.
func incidents() -> GdChime.Desc:
	var feed := _operations.incidents
	var names: Array = [&"time", &"name", &"mark", &"status", &"words"]
	var columns := _columns({&"time": 0.14, &"name": 0.1, &"mark": 0.04, &"status": 0.16, &"words": 0.56})
	var samples := {&"time": {"words": ["0:00:00.0"]}, &"name": {"words": ["D-000"]}, &"mark": {"words": [MARK_ROOM]}, &"status": {"words": [GdChime.Phrase.of("Warning"), GdChime.Phrase.of("Offline")]}, &"words": {"words": [GdChime.Phrase.of("Round trips far slower than usual"), GdChime.Phrase.of("Stopped answering")]}}
	var line := func(entry: GdChime.Bound) -> GdChime.Desc:
		var parts := [_said(entry, "time"), _said(entry, "name"), GdChime.Status.mark(_ui, entry.map(func(one: Variant) -> Variant: return null if one == null else Operations.state_of(one["status"]))), _ui.text(entry.map(func(one: Variant) -> Variant: return null if one == null else Operations.words_of(one["status"])), GdChime.Tables.WORDS), _said(entry, "words")]
		return GdChime.LiveFeed.row(_ui, feed, entry, parts, {names = names, columns = columns, samples = samples})
	# the press saying what it would inspect, or how to choose one: words that break rather than widen, so it never moves
	var said: GdChime.Bound = GdChime.Bound.new(feed.get_at).map(func(_at: int) -> GdChime.Phrase: return GdChime.Phrase.of("Move onto an incident to inspect it") if feed.get_entry() == null else GdChime.Phrase.with("Inspect the incident on %s", [feed.get_entry()["name"]]))
	var inspect := _ui.pressable(Operations.INSPECTS_INCIDENT, {}, [_ui.text(said, GdChime.Themes.FACE).wraps()], GdChime.Pressables.BUTTON).opens(incident)
	return GdChime.Panes.titled(_ui, GdChime.Phrase.of("Incidents"), _ui.column([GdChime.LiveFeed.make(_ui, feed, line, Operations.INSPECTS_INCIDENT).grow(), inspect]))


## The log of every event, newest at the foot, in a place of its own, whose region its feed answers in.
func log(named: StringName) -> GdChime.Desc:
	var feed := _operations.log
	var names: Array = [&"time", &"name", &"words"]
	var columns := _columns({&"time": 0.16, &"name": 0.12, &"words": 0.72})
	var samples := {&"time": {"words": ["0:00:00.0"]}, &"name": {"words": ["D-000"]}, &"words": {"words": [GdChime.Phrase.with("Round trip %d ms", [888]), Operations.now_of(Network.RECOVERING), GdChime.Phrase.of("No reply")]}}
	var line := func(entry: GdChime.Bound) -> GdChime.Desc: return GdChime.LiveFeed.row(_ui, feed, entry, [_said(entry, "time"), _said(entry, "name"), _said(entry, "words")], {names = names, columns = columns, samples = samples})
	return _ui.screen(named, [GdChime.Panes.titled(_ui, GdChime.Phrase.of("Log"), GdChime.LiveFeed.make(_ui, feed, line, GdChime.Feed.FOLLOWS))], feed)


## The status line: how the connection stands, or that the stream is paused,
## how busy it is, how far behind it has fallen and how many it let go.
func status() -> GdChime.Desc:
	var read := [GdChime.Bound.new(_stream.get_connection), GdChime.Bound.new(_stream.get_paused), GdChime.Bound.new(_stream.get_rate), GdChime.Bound.new(_stream.get_held), GdChime.Bound.new(_stream.get_behind), GdChime.Bound.new(_stream.get_missed), GdChime.Bound.new(_operations.get_open_count)]
	var state: GdChime.Bound = GdChime.Bound.all(read, _status_state)
	var words: GdChime.Bound = GdChime.Bound.all(read, _status_words)
	return GdChime.Status.make(_ui, state, words, {wraps = true})


## Paused is still; connected but outrun, a notice - its own mark, beside the words saying how far behind.
static func _status_state(connection: StringName, paused: bool, _rate: int, _held: int, behind: int, _missed: int, _open: int) -> StringName:
	if paused:
		return GdChime.Status.STILL
	if connection == GdChime.Stream.CONNECTED and behind > 0:
		return GdChime.Status.NOTICE
	return {GdChime.Stream.CONNECTED: GdChime.Status.WELL, GdChime.Stream.CONNECTING: GdChime.Status.MENDING, GdChime.Stream.RECONNECTING: GdChime.Status.MENDING}.get(connection, GdChime.Status.FAULT)


static func _status_words(connection: StringName, paused: bool, rate: int, held: int, behind: int, missed: int, open: int) -> GdChime.Phrase:
	if paused:
		return GdChime.Phrase.with("Paused: %d events held until you resume, %d missed. %d incidents open", [held, missed, open])
	match connection:
		GdChime.Stream.CONNECTED when behind > 0: return GdChime.Phrase.with("Connected, falling behind: %d events waiting, %d missed, %d a second. %d incidents open", [behind, missed, rate, open])
		GdChime.Stream.CONNECTED: return GdChime.Phrase.with("Connected: %d events a second, %d missed. %d incidents open", [rate, missed, open])
		GdChime.Stream.RECONNECTING: return GdChime.Phrase.with("The link dropped; reconnecting. %d incidents open", [open])
		GdChime.Stream.CONNECTING: return GdChime.Phrase.of("Connecting")
	return GdChime.Phrase.of("Not connected")


## An incident inspected, the stream running on behind: what it was, and its device as it stands now.
func _incident() -> GdChime.Desc:
	var entry: GdChime.Bound = GdChime.Bound.new(_operations.incidents.get_at).map(func(_at: int) -> Variant: return _operations.incidents.get_entry())
	var what := _ui.text(entry.map(func(one: Variant) -> Variant: return null if one == null else GdChime.Phrase.with("%s at %s: %s", [one["name"], one["time"], one["words"]])), GdChime.Themes.FACE).wraps()
	return _ui.pop_up(&"incident", func(_which: GdChime.Bound) -> GdChime.Desc: return GdChime.Sheet.over(_ui, [_ui.text(GdChime.Phrase.of("Incident"), GdChime.Themes.WORDS), what] + _now() + [GdChime.Sheet.close(_ui)], GdChime.Setting.SHEET))


## A device inspected, the stream running on behind: it as it stands now.
func _device() -> GdChime.Desc:
	var named := _ui.text(GdChime.Bound.new(_operations.get_inspected).map(func(one: Variant) -> Variant: return null if one == null else one["name"]), GdChime.Themes.WORDS)
	return _ui.pop_up(&"device", func(_which: GdChime.Bound) -> GdChime.Desc: return GdChime.Sheet.over(_ui, [named] + _now() + [GdChime.Sheet.close(_ui)], GdChime.Setting.SHEET))


## The device inspected as it stands now, live: its status and its last round trip.
func _now() -> Array:
	var inspected := GdChime.Bound.new(_operations.get_inspected)
	var state: GdChime.Desc = GdChime.Status.make(_ui, inspected.map(func(one: Variant) -> Variant: return null if one == null else Operations.state_of(one["status"])), inspected.map(func(one: Variant) -> Variant: return null if one == null else Operations.now_of(one["status"])), {kind = GdChime.Themes.FACE})
	var reading := _ui.text(inspected.map(func(one: Variant) -> Variant: return null if one == null else GdChime.Phrase.with("Last round trip %d ms", [one["reading"]])), GdChime.Themes.FACE)
	return [state, reading]


## One field of an entry, as words in a cell.
func _said(entry: GdChime.Bound, field: String) -> GdChime.Desc:
	return _ui.text(entry.map(func(one: Variant) -> Variant: return null if one == null else one[field]), GdChime.Tables.WORDS)


## Columns at these shares, fixed.
static func _columns(shares: Dictionary) -> GdChime.Bound:
	return GdChime.Bound.new(func() -> Array: return shares.keys().map(func(name: StringName) -> Dictionary: return {"name": name, "share": shares[name]}))
