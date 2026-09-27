extends "res://addons/gd_chime/application.gd"

const Console := preload("res://addons/gd_chime/console.gd")
const DebugLog := preload("res://addons/gd_chime/debug_log.gd")
const DevCommands := preload("res://addons/gd_chime/dev_commands.gd")
const Dial := preload("res://demo/clock/dial.gd")
const DemoTheme := preload("res://demo/demo_theme.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")

## The console, over something running.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --path <this folder> --script res://demo/console/console.gd -- --console
##
## The clock from the other demo runs underneath, because a console is only
## worth looking at over something alive: the app is one place, THE CLOCK,
## holding two places that take each other's place, THE DIALS and THE DARK,
## an empty one. Press F10: the console is raised beside the app as the
## panel, built on that press, and comes up over the clock, which goes on
## ticking behind it, live - the panel blocks nothing. Type a command, press
## Enter, and the line and its answer arrive in the stream with everything
## else the application has said. F10 again lowers it, with a half-typed
## line kept for when it comes back.
##
## Ctrl+Tab, or a press on the other tab, turns to the NAVIGATION page: the
## path walked so far, each path whole. go, back and forget walk it - go
## dark arrives at the dark, go dials at the dials, back returns, and forget
## keeps where you are and forgets the way back - each through the driver's
## door from inside the typed line's own command, which the door keeps
## straight. Try back at the start of the path, or go somewhere that is no
## place: each is refused, and the refusal lands in the stream.
##
## Run it WITHOUT the switch and F10 does nothing, because no console was built.
## That is the whole of the rule: the console ships in every build, and whether
## it can be reached is decided when the application is launched.
##
## The other commands are this demo's own. say, warn and fail hand the engine
## the three kinds the log shows, frames answers with a number rather than
## "done", and quit ends it. The standard wiring is application.gd's; this
## file answers its questions and never listens.

const REGION := &"console_demo"
const SWITCH := "--console"
const CLOCK := &"clock"
const DIALS := &"dials"
const DARK := &"dark"
const UNITS := [Dial.Unit.HOUR, Dial.Unit.MINUTE, Dial.Unit.SECOND, Dial.Unit.MILLISECOND]

func look() -> Theme:
	return DemoTheme.new()


## The log and the dev commands made, the console where the
## switch asks for it, and the clock described: the dials in one place, the
## dark another.
func describe() -> Desc:
	var debug_log := DebugLog.new(chimes, "user://console_demo", 100000, 3, 200)
	ui.also(debug_log)
	var dev := DevCommands.new()
	dev.register(&"go", "arrives at a view of that name", _go)
	dev.register(&"back", "returns to the view before", _back)
	dev.register(&"forget", "forgets the way back", _forget)
	dev.register(&"say", "prints a line into the stream", _say)
	dev.register(&"warn", "raises a warning", _warn)
	dev.register(&"fail", "raises an error", _fail)
	dev.register(&"frames", "how many frames have been drawn", _frames)
	dev.register(&"quit", "closes the demo", _close)
	# a typed line reaches the dev commands from anywhere
	commands.register(Chimes.GLOBAL, DevCommands.RUN_LINE, dev)
	if OS.get_cmdline_user_args().has(SWITCH):
		ui.also(Console.new(ui, debug_log))
		print("the console is available: press F10, and Ctrl+Tab to turn the page")
	else:
		print("no console was built: run with -- %s for one" % SWITCH)
	print("the commands are %s" % ", ".join(PackedStringArray(dev.get_names())))
	var time := ui.every_frame(Dial.now)
	var dials: Array = []
	# the same face four times, handed the same time and a different unit each
	for unit: Dial.Unit in UNITS:
		dials.append(Dial.make(ui, time, unit).grow())
	return ui.app(CLOCK, [ui.stack([ui.screen(DIALS, [ui.row(dials)]), ui.screen(DARK, [])])])


## Arrive at a place in the clock through the door.
func _go(screen: String) -> Phrase:
	return _through(Driver.GO, {"place": StringName(screen)})


func _back() -> Phrase:
	return _through(Driver.GOES_BACK, {})


func _forget() -> Phrase:
	return _through(Driver.FORGETS, {})


## A navigation command through the door, from inside the typed line's own
## command; its refusal is the answer, and lands in the stream.
func _through(action: StringName, payload: Dictionary) -> Phrase:
	return ui.commands.dispatch(Chimes.GLOBAL, action, payload)


func _say(words: String) -> void:
	print(words)


func _warn(words: String) -> void:
	push_warning(words)


func _fail(words: String) -> void:
	push_error(words)


func _frames() -> int:
	return Engine.get_frames_drawn()


func _close() -> void:
	quit()
