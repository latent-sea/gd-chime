extends SceneTree

## What must be true of a hand's press that takes a while (slow_presses.gd):
## turned on, every press shows its face down first and its work follows a
## frame later, timed; once it has taken longer than SLOW, the next press of it
## dims the screen at once,
## its work follows only after the dim is drawn, and the dim lifts once the
## work is done and SHOWN has passed; an action that is quick never dims; and
## turned off, as it is until an application turns it on, no press dims.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_slow_presses.gd

const Fixture := preload("res://tests/fixture.gd")
const Verdict := preload("res://tests/verdict.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const SlowPresses := preload("res://addons/gd_chime/slow_presses.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")

const SLOWLY := &"takes_a_while"
const QUICKLY := &"is_quick"

var _verdict := Verdict.new()


## A model whose one action holds the frame up for longer than SLOW.
class Waits extends Fixture.Model:
	## The press watched, and how far down its face stood each time its work was done.
	var watched: Control = null
	var faces: Array = []

	func told(action: StringName, payload: Dictionary) -> Phrase:
		if watched != null:
			faces.append(watched.scale.x)
		if action == SLOWLY:
			OS.delay_msec(int(SlowPresses.SLOW * 1000.0) + 100)
		return super(action, payload)


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(800, 600)
	await _verdict.states(_a_slow_press_dims_first_its_work_follows_and_the_dim_lifts)
	quit(_verdict.deliver(get_script()))


func _frames(count: int) -> void:
	# as many frames as asked
	for waited: int in count:
		await process_frame


## Frames pass until `seconds` have on the clock: a face stays down for a time, not for a count of frames.
func _seconds(seconds: float) -> void:
	var from := Time.get_ticks_usec()
	# each frame until the time has passed
	while (Time.get_ticks_usec() - from) / 1e6 < seconds:
		await process_frame


## A hand's press of this control, landing and lifting, as interaction.gd hears it.
func _hand(on: Control) -> void:
	on._press(true)
	on._press(false)


func _a_slow_press_dims_first_its_work_follows_and_the_dim_lifts() -> void:
	var made := Fixture.new(root, {SLOWLY: "slow", QUICKLY: "quick"})
	var ui := made.ui
	var model := Waits.new(made.chimes)
	model.answering = [SLOWLY, QUICKLY]
	ui.start(ui.app(&"app", [ui.column([ui.pressable(SLOWLY, {}, [ui.text("slow", Themes.FACE)]).named(&"slow"), ui.pressable(QUICKLY, {}, [ui.text("quick", Themes.FACE)]).named(&"quick")])], model))
	await _frames(3)
	var slow: Control = ui.node_named(&"slow")
	var quick: Control = ui.node_named(&"quick")
	_hand(slow)
	await _frames(2)
	_verdict.check(model.told_actions.size() == 1 and SlowPresses._dim == null, "turned off, a slow press is done at once and dims nothing")
	# the look's press scale on the slow press: 90%, so its face going down can be seen
	var pressed_look := Theme.new()
	pressed_look.set_constant(&"press_scale", &"Motion", 900)
	slow.theme = pressed_look
	model.watched = slow
	SlowPresses.enabled = true
	_hand(slow)
	_verdict.check(model.told_actions.size() == 1, "turned on, a press's work waits for its face to be drawn down")
	await _frames(1)
	_verdict.check(model.told_actions.size() == 2 and not model.faces.is_empty() and is_equal_approx(model.faces.back(), 0.9), "the work follows a frame later, the face drawn down while it runs")
	await _seconds(SlowPresses.HELD + 0.1)
	_verdict.check(is_equal_approx(slow.scale.x, 1.0), "the face comes up again once the press has been seen")
	var pressed_at := Time.get_ticks_usec()
	_hand(slow)
	var dimmed_at_once := SlowPresses._dim != null and SlowPresses._dim.visible
	_verdict.check(dimmed_at_once and model.told_actions.size() == 2, "found slow, its next press dims the screen at once and its work waits for the dim to be drawn")
	var told_while_dimmed := false
	# each frame until the dim lifts, or two seconds: whether the work was done while it still showed
	while SlowPresses._dim.visible and Time.get_ticks_usec() - pressed_at < 2000000:
		told_while_dimmed = told_while_dimmed or model.told_actions.size() == 3
		await process_frame
	var dimmed_for := (Time.get_ticks_usec() - pressed_at) / 1e6
	_verdict.check(told_while_dimmed and model.told_actions.size() == 3, "the work follows once the dim is drawn, while it still shows")
	_verdict.check(not SlowPresses._dim.visible and dimmed_for >= SlowPresses.SHOWN and dimmed_for < SlowPresses.SHOWN + 0.5,
		"the dim lifts once the work is done and its least time has passed: %.2f s" % dimmed_for)
	# a quick action pressed twice: its face down first each time, its work a frame later, never found slow
	_hand(quick)
	await _seconds(SlowPresses.HELD + 0.1)
	_hand(quick)
	await _frames(2)
	_verdict.check(not SlowPresses._dim.visible and model.told_actions.slice(-2) == [QUICKLY, QUICKLY], "a quick action's work follows its face each time and never dims")
	SlowPresses.enabled = false
	made.done()
