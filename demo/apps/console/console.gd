extends "res://addons/gd_chime/application.gd"

const GdChime := preload("res://addons/gd_chime/gd_chime.gd")
const Looks := preload("res://demo/gallery/looks/looks.gd")
const Network := preload("res://demo/apps/console/network.gd")
const Operations := preload("res://demo/apps/console/operations.gd")
const ConsoleView := preload("res://demo/apps/console/console_view.gd")
const ConsoleProbe := preload("res://demo/apps/console/console_probe.gd")

## Application 5, the real-time operations console: a network operations
## centre watching five hundred devices - their statuses on a wall, the
## incidents as they open, a live chart of round trips and one of incidents
## a minute, the log of every event, alerts, and how the link stands - two
## hundred events a second, with the reader able to pause the stream and
## inspect an incident or a device while it runs on behind.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --path <this folder> --script res://demo/apps/console/console.gd
##       [-- --look=<a gallery look>; glass, its own, unless asked] [-- --probe]
##
## EVERYTHING LIVE IS THE FLOOR'S: the network is a source a stream opens
## for the console's stay and closes as it is left (stream.gd); P, or the
## pad's Y, pauses it - held, and caught up on as it resumes. What the
## events move are the floor's models (operations.gd), each ringing at most
## once a frame; the panes are the shell's (shell.gd, panes.gd), splits a
## reader resizes; the status line says how the link stands, a mark beside
## its words. This file declares the actions and their keys, makes the
## models and arranges the panes.

const APP := &"app"
const CONSOLE := &"console"
const LOG := &"log"
## The console's own look, worn unless another is asked for: every application its own.
const OWN_LOOK := &"glass"
## How many events are held while paused before the oldest are let go, and
## how many a frame hands on at most: half a second's worth a frame, so
## twenty seconds held are caught up on in about forty frames, the screen live.
const HELD := 60000
const A_FRAME := 100

var network: Network
var stream: GdChime.Stream
var operations: Operations
var panels: GdChime.Panels
## The console's pieces, a probe finding the inspections on it.
var view: ConsoleView


## The look asked for at launch, or the console's own, glass.
func look() -> Theme:
	return Looks.make(Looks.asked(OWN_LOOK))


func probe() -> RefCounted:
	return ConsoleProbe.new(self)


## Every action with its words, and the key and pad button it is on to begin with.
func declare(register: Actions) -> void:
	register.declare_all({
		GdChime.Stream.HOLDS: ["Pause the stream", Actions.keys(KEY_P), Actions.pad(JOY_BUTTON_Y)],
		Operations.INSPECTS_INCIDENT: ["Inspect the incident", Actions.keys(KEY_I)],
		Operations.INSPECTS_DEVICE: ["Inspect the device"],
		GdChime.Feed.FOLLOWS: ["Show the newest"],
		GdChime.Feed.MOVES: ["Move along"],
		GdChime.Feed.PRESSES: ["Pick"],
		GdChime.Feed.LETS_GO: ["Let go"],
		Notifications.DISMISSES: ["Dismiss"],
		GdChime.Panels.RESIZES: ["Resize"],
	})


## The models made - the pause and the panes answered from anywhere, so a
## key presses them wherever the focus is - then the shell described.
func describe() -> Desc:
	network = Network.new()
	ui.also(network)
	var alerts := GdChime.PacedNotices.new(notifications, func(many: int) -> GdChime.Phrase: return GdChime.Phrase.counted("%d device stopped answering", "%d devices stopped answering", many), GdChime.Feed.FOLLOWS)
	ui.also(alerts)
	operations = Operations.new(chimes, network, alerts)
	var sinks: Array[Callable] = [operations.take]
	stream = model(GdChime.Stream.new(chimes, network, sinks, HELD, A_FRAME))
	panels = model(GdChime.Panels.new(chimes, {&"main": 0.52, &"watched": 0.5, &"told": 0.55}, {&"watched": [&"main", GdChime.Panels.FIRST], &"told": [&"main", GdChime.Panels.SECOND], &"devices": [&"watched", GdChime.Panels.FIRST], &"charts": [&"watched", GdChime.Panels.SECOND], &"incidents": [&"told", GdChime.Panels.FIRST], &"log": [&"told", GdChime.Panels.SECOND]}))
	view = ConsoleView.new(ui, operations, stream)
	var shell: GdChime.Desc = GdChime.Shell.make(ui, _bar(), _panes(), {status = view.status(), notifications = notifications, offers = {Operations.INSPECTS_DEVICE: view.device.get_place(), GdChime.Feed.FOLLOWS: &""}})
	# the inspections and the incidents' feed answer on the console screen; the log's feed answers on the log (console_view.gd)
	return ui.app(APP, [ui.screen(CONSOLE, [shell], [operations, operations.incidents], {on_fill = stream.open, on_empty = stream.close})])


## The bar: the pause, a toggle on while the stream is held, and its key.
func _bar() -> Array:
	var paused := ui.bound(stream.get_paused)
	var holds := ui.pressable(GdChime.Stream.HOLDS, paused.map(func(on: bool) -> Dictionary: return {"on": not on}), [ui.row([ui.text(ui.words(GdChime.Stream.HOLDS), Themes.FACE).grow(), GdChime.Hint.make(ui, GdChime.Stream.HOLDS)])], paused.map(func(on: bool) -> StringName: return GdChime.Panes.SHOWN if on else GdChime.Panes.FOLDED))
	return [holds]


## The panes: the wall over the charts, beside the incidents over the log;
## on a window on its end, the two columns one over the other.
func _panes() -> Desc:
	var standing: GdChime.Bound = ui.shape.portrait.map(func(down: Variant) -> int: return GdChime.Layout.COLUMN if down else GdChime.Layout.ROW)
	var watched: GdChime.Desc = GdChime.Panes.split(ui, view.devices(), view.charts(), {panels = panels, named = &"watched", runs = GdChime.Layout.COLUMN})
	var told: GdChime.Desc = GdChime.Panes.split(ui, view.incidents(), view.log(LOG), {panels = panels, named = &"told", runs = GdChime.Layout.COLUMN})
	return GdChime.Panes.split(ui, watched, told, {panels = panels, named = &"main", runs = standing})
