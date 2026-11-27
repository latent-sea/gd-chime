extends SceneTree

## What must be true of a hand's press that takes a while (slow_presses.gd):
## turned on, every press shows its face down first and its work follows a
## frame later, and no press dims; with the player's dim turned on too, every
## press dims the screen at once, slow or quick, the first time as every time,
## its work follows under the dim, and the dim lifts on completion; and turned
## off, as it is until an application turns it on, a press is done at once.
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


## A model whose one action holds the frame up for a while.
class Waits extends Fixture.Model:
	## The press watched, and how far down its face stood each time its work was done.
	var watched: Control = null
	var faces: Array = []

	func told(action: StringName, payload: Dictionary) -> Phrase:
		if watched != null:
			faces.append(watched.scale.x)
		if action == SLOWLY:
			OS.delay_msec(300)
		return super(action, payload)


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(800, 600)
	await _verdict.states(_a_slow_press_dims_first_its_work_follows_and_the_dim_lifts)
	await _verdict.states(_a_press_freed_with_its_face_down_leaves_nothing_to_raise_it)
	# the dims' longest stands run out before the engine stops, so no lift is still waiting on a timer at exit
	await create_timer(SlowPresses.LONGEST + 0.1).timeout
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


## A model whose one action frees the press that asked for it, as a screen made again does (crash-hunt CH-15).
class Frees extends Fixture.Model:
	var press: Control = null

	func told(action: StringName, payload: Dictionary) -> Phrase:
		press.queue_free()
		return super(action, payload)


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
	# the dim off, as it is until the player turns it on: the face down at once, the work a frame later, no dim
	_hand(slow)
	_verdict.check(model.told_actions.size() == 1, "turned on, a press's work waits for its face to be drawn down")
	await _frames(1)
	_verdict.check(model.told_actions.size() == 2 and is_equal_approx(model.faces.back(), 0.9) and (SlowPresses._dim == null or not SlowPresses._dim.visible),
		"the work follows a frame later, the face drawn down while it runs, and nothing dims while the player's dim is off")
	await _seconds(SlowPresses.HELD + 0.1)
	SlowPresses.dims = true
	# a slow press: the dim and the face down at once, the work a frame later under both, the dim lifted on completion
	var pressed_at := Time.get_ticks_usec()
	_hand(slow)
	var dimmed_at_once := SlowPresses._dim != null and SlowPresses._dim.visible
	_verdict.check(dimmed_at_once and model.told_actions.size() == 2, "with the dim turned on, a press dims the screen at once, and its work waits for the dim to be drawn")
	var told_while_dimmed := false
	# each frame until the dim lifts, or two seconds: whether the work was done while it still showed
	while SlowPresses._dim.visible and Time.get_ticks_usec() - pressed_at < 2000000:
		told_while_dimmed = told_while_dimmed or model.told_actions.size() == 3
		await process_frame
	var dimmed_for := (Time.get_ticks_usec() - pressed_at) / 1e6
	_verdict.check(told_while_dimmed and model.told_actions.size() == 3 and not model.faces.is_empty() and is_equal_approx(model.faces.back(), 0.9),
		"the work follows under the dim, the face drawn down while it runs")
	_verdict.check(not SlowPresses._dim.visible and dimmed_for >= SlowPresses.SHOWN and dimmed_for < 1.0,
		"the dim lifts on completion, once what the work made is drawn: %.2f s" % dimmed_for)
	await _seconds(SlowPresses.HELD + 0.1)
	_verdict.check(is_equal_approx(slow.scale.x, 1.0), "the face comes up again once the press has been seen")
	# a quick press: dimmed too, every time, the first as the second (Ian, 2026-11-07: dim on press, off on completion)
	var quick_at := Time.get_ticks_usec()
	_hand(quick)
	var quick_dimmed := SlowPresses._dim.visible
	while SlowPresses._dim.visible and Time.get_ticks_usec() - quick_at < 2000000:
		await process_frame
	var quick_for := (Time.get_ticks_usec() - quick_at) / 1e6
	_verdict.check(quick_dimmed and model.told_actions.back() == QUICKLY and quick_for < 0.5,
		"a quick press dims too, the first time, and lifts as soon as it is done: %.2f s" % quick_for)
	SlowPresses.enabled = false
	SlowPresses.dims = false
	made.done()



## A press freed by its own work while its face is down: no tween is left to raise a face that is gone (crash-hunt
## CH-15: the delayed raise called on a freed press, "Lambda capture at index 0 was freed", on most moves).
func _a_press_freed_with_its_face_down_leaves_nothing_to_raise_it() -> void:
	var made := Fixture.new(root, {SLOWLY: "slow"})
	var ui := made.ui
	var model := Frees.new(made.chimes)
	model.answering = [SLOWLY]
	ui.start(ui.app(&"app", [ui.column([ui.pressable(SLOWLY, {}, [ui.text("slow", Themes.FACE)]).named(&"slow")])], model))
	await _frames(3)
	model.press = ui.node_named(&"slow")
	SlowPresses.enabled = true
	_hand(model.press)
	await _frames(3)
	var freed := not is_instance_valid(model.press)
	var waiting: int = get_processed_tweens().size()
	_verdict.check(freed and waiting == 0, "a press freed by its work leaves no tween waiting to raise its face: freed %s, %d waiting" % [freed, waiting])
	await _seconds(SlowPresses.HELD + 0.1)
	SlowPresses.enabled = false
	made.done()
