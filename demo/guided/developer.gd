extends RefCounted

const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const DebugLog := preload("res://addons/gd_chime/debug_log.gd")
const DevCommands := preload("res://addons/gd_chime/dev_commands.gd")
const Console := preload("res://addons/gd_chime/console.gd")
const Ui := preload("res://addons/gd_chime/components/primitives/ui.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")

## The guided demo's developer's console, built only where the launch
## switch asks for one: the log the console reads, the dev commands a typed
## line reaches, and the console itself, a place beside the app.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The commands typed - path, back, quit - are this demo's own, named
## functions of a small model over the builder; each runs inside the typed
## line's command, and one that moves the reader goes through the door from
## there, which the door keeps straight.

const SWITCH := "--console"


## The typed commands, over the builder's door and driver: a node, kept
## under the root, since a command holds only a name and not the thing.
class Typed extends Node:
	var _ui: Ui

	func _init(ui: Ui) -> void:
		_ui = ui

	func path() -> String:
		return " / ".join(PackedStringArray(_ui.driver.get_top()))

	func back() -> Phrase:
		return _ui.commands.dispatch(Chimes.GLOBAL, Driver.GOES_BACK, {})

	func quit() -> void:
		_ui.root.get_tree().quit()


static func asked_for() -> bool:
	return OS.get_cmdline_user_args().has(SWITCH)


## The console over this builder's application, its log put beside it.
static func console(ui: Ui) -> Node:
	var debug_log := DebugLog.new(ui.chimes, "user://guided", 100000, 3, 200)
	var typed := Typed.new(ui)
	ui.also(typed)
	var dev := DevCommands.new()
	dev.register(&"path", "where the reader is, root down", typed.path)
	dev.register(&"back", "back on the top layer", typed.back)
	dev.register(&"quit", "closes the demo", typed.quit)
	ui.commands.register(Chimes.GLOBAL, DevCommands.RUN_LINE, dev)
	ui.also(debug_log)
	return Console.new(ui, debug_log)
