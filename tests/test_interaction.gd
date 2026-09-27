extends SceneTree

## What must be true of what a person does to a control.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_interaction.gd
##
## Every event is pushed through the engine, which decides which control it
## was for. Proved here: letting go of the button presses nothing; only the
## left button presses; the pointer arriving and leaving is told, in that
## order; a screen built on this still hears its own notifications - one
## object arranges on a resize and hears the pointer, because the engine
## calls both levels; the accept action presses the control with focus as it
## goes down, neither its repeats nor letting go press it again, and none of it
## goes past the control; a control that asks to repeat, held, is pressed as
## the press lands, again after the wait and then at each interval, by the left
## button and by the accept action alike; a control that does not ask is
## pressed once, however long it is held; the repeat stops at the release, even
## one off the control, when focus walks away while a key is held, and when the
## control leaves the tree; a control is told when its focus starts and stops
## showing - shown when given or walked to, hidden when a click lands on it
## even though it already had focus, and told nothing when nothing changed; and
## the input map this folder runs with gives the pad what it needs - its A for
## accept, its d-pad for the four directions, every action keeping its keys -
## so the A presses and the d-pad walks.
##
## Proved elsewhere and not repeated, each through a screen built on this: a
## press reaching the control it landed on, and focus arriving and leaving,
## in test_controller.gd; the wheel, in test_long_list_presentation.gd.
##
## A repeat is counted halfway into the wait and halfway between repeats, so a
## slow frame can move a repeat without moving a count.

const Belfry := preload("res://addons/gd_chime/belfry.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Interaction := preload("res://addons/gd_chime/interaction.gd")
const Presentation := preload("res://addons/gd_chime/presentation.gd")
const Verdict := preload("res://tests/verdict.gd")

const INSIDE := Vector2(50, 20)
const OUTSIDE := Vector2(300, 300)
## The repeat's two numbers in these properties, in seconds.
const WAIT := 0.4
const INTERVAL := 0.2
## Each action a pad needs, and the pad button it must hold.
const PAD := {
	&"ui_accept": JOY_BUTTON_A,
	&"ui_up": JOY_BUTTON_DPAD_UP,
	&"ui_down": JOY_BUTTON_DPAD_DOWN,
	&"ui_left": JOY_BUTTON_DPAD_LEFT,
	&"ui_right": JOY_BUTTON_DPAD_RIGHT,
}

var _verdict := Verdict.new()


## A control that records every hook that reached it, in order.
class Recorder extends Interaction:
	var rang: Array[StringName] = []  # the moments rung, apart from what it was told
	var told: Array[String] = []

	func pressed() -> void:
		told.append("pressed")

	func _ring(moment: StringName) -> void:
		rang.append(moment)

	func hovered(inside: bool) -> void:
		told.append("hovered %s" % inside)

	func focused(shown: bool) -> void:
		told.append("focused %s" % shown)


## A screen that counts its arrangements and records the pointer.
class Arranged extends Presentation:
	var arranged := 0
	var hovers: Array[bool] = []

	func arrange() -> void:
		arranged += 1

	func hovered(inside: bool) -> void:
		hovers.append(inside)


## Something below every control, counting each accept that reaches it
## unhandled.
class Listener extends Node:
	var heard := 0

	func _unhandled_input(event: InputEvent) -> void:
		if event.is_action("ui_accept"):
			heard += 1


func _init() -> void:
	# the first frame's signal comes before any node has been processed; after it, one await is one processed frame
	await process_frame
	# the headless window is 64 by 64 and puts back a size set before the first frame, so it is sized now
	root.size = Vector2i(400, 400)
	# the pointer tests measure in the window's own pixels: the base-size stretch the project sets is off here
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_letting_go_of_the_button_presses_nothing)
	await _verdict.states(_only_the_left_button_presses)
	await _verdict.states(_the_pointer_arriving_and_leaving_is_told_in_that_order)
	await _verdict.states(_a_screen_built_on_it_still_hears_its_own_notifications)
	await _verdict.states(_the_accept_action_presses_the_control_with_focus_once_as_it_goes_down)
	await _verdict.states(_a_control_that_asks_to_repeat_is_pressed_again_while_held)
	await _verdict.states(_a_control_that_does_not_ask_is_pressed_once_however_long_it_is_held)
	await _verdict.states(_the_repeat_stops_at_the_release_when_focus_leaves_and_when_the_control_leaves_the_tree)
	await _verdict.states(_a_control_is_told_when_its_focus_starts_and_stops_showing)
	await _verdict.states(_the_input_map_gives_the_pad_what_it_needs)
	quit(_verdict.deliver(get_script()))


## A recorder in the top left of the window, a hundred by forty, with the
## pointer moved off it and whatever that told it forgotten.
func _recorder() -> Recorder:
	var control := Recorder.new()
	control.size = Vector2(100, 40)
	root.add_child(control)
	_point_at(OUTSIDE)
	await _a_frame_passes()
	control.told.clear()
	return control


## Two recorders that take focus, under one screen, the second below the first,
## with whatever arriving told them forgotten. They share a parent because the
## arrows walk only among controls that do - measured.
func _screen_of_two() -> Array[Recorder]:
	var screen := Control.new()
	screen.size = Vector2(400, 400)
	root.add_child(screen)
	var pair: Array[Recorder] = [Recorder.new(), Recorder.new()]
	# each recorder, focusable, a hundred below the one before
	for index: int in range(pair.size()):
		pair[index].focus_mode = Control.FOCUS_ALL
		pair[index].size = Vector2(100, 40)
		pair[index].position = Vector2(0, index * 100)
		screen.add_child(pair[index])
	_point_at(OUTSIDE)
	await _a_frame_passes()
	# each recorder, told nothing yet
	for recorder: Recorder in pair:
		recorder.told.clear()
	return pair


## process_frame is emitted BEFORE nodes are processed, so the effect of a
## frame is only visible once the next one has come round.
func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## Frames until this many seconds have passed since started, then one more,
## because process_frame comes before the frame's timers are processed.
func _frames_until(started: int, seconds: float) -> void:
	# every frame until the time has come
	while Time.get_ticks_msec() - started < seconds * 1000.0:
		await process_frame
	await process_frame


func _click(button: MouseButton, down: bool, at: Vector2 = INSIDE) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = button
	click.pressed = down
	click.position = at
	root.push_input(click)


func _point_at(at: Vector2) -> void:
	var move := InputEventMouseMotion.new()
	move.position = at
	root.push_input(move)


func _key(code: Key, down: bool, echo: bool = false) -> void:
	var key := InputEventKey.new()
	key.keycode = code
	key.physical_keycode = code
	key.pressed = down
	key.echo = echo
	root.push_input(key)


## A pad button pressed and let go.
func _pad(button: JoyButton) -> void:
	# the button going down, then up
	for down: bool in [true, false]:
		var press := InputEventJoypadButton.new()
		press.button_index = button
		press.pressed = down
		root.push_input(press)


## What a recorder was told about its focus, in order.
func _focus_of(recorder: Recorder) -> Array:
	return recorder.told.filter(func(entry: String) -> bool: return entry.begins_with("focused"))


func _letting_go_of_the_button_presses_nothing() -> void:
	var control: Recorder = await _recorder()

	_click(MOUSE_BUTTON_LEFT, true)
	_click(MOUSE_BUTTON_LEFT, false)
	await _a_frame_passes()

	_verdict.check(control.told.count("pressed") == 1, "a press and a release are one press")
	control.queue_free()
	await _a_frame_passes()


func _only_the_left_button_presses() -> void:
	var control: Recorder = await _recorder()

	_click(MOUSE_BUTTON_RIGHT, true)
	_click(MOUSE_BUTTON_MIDDLE, true)
	await _a_frame_passes()
	_verdict.check(control.told.count("pressed") == 0, "a right click and a middle click press nothing")

	_click(MOUSE_BUTTON_LEFT, true)
	await _a_frame_passes()
	_verdict.check(control.told.count("pressed") == 1, "and the left button, on the same control, does")
	control.queue_free()
	await _a_frame_passes()


func _the_pointer_arriving_and_leaving_is_told_in_that_order() -> void:
	var control: Recorder = await _recorder()

	_point_at(INSIDE)
	await _a_frame_passes()
	_verdict.check(control.told == ["hovered true"], "the pointer arriving is told")

	_point_at(OUTSIDE)
	await _a_frame_passes()
	_verdict.check(control.told == ["hovered true", "hovered false"], "and its leaving, after it")
	control.queue_free()
	await _a_frame_passes()


## The split's own claim: the level below answering the pointer takes nothing
## from the level above, which answers the resize.
func _a_screen_built_on_it_still_hears_its_own_notifications() -> void:
	var screen := Arranged.new(Chimes.new(Belfry.new()))
	screen.size = Vector2(100, 40)
	root.add_child(screen)
	_point_at(OUTSIDE)
	await _a_frame_passes()
	var before := screen.arranged
	screen.hovers.clear()

	screen.size = Vector2(120, 40)
	_point_at(INSIDE)
	await _a_frame_passes()

	_verdict.check(screen.arranged == before + 1, "a resize reaches the screen's own arrange")
	_verdict.check(screen.hovers == [true], "and the pointer reaches the same screen, through the level below")
	screen.queue_free()
	await _a_frame_passes()


## Enter held and let go, then Space, with something below listening for any
## of it that gets past the control.
func _the_accept_action_presses_the_control_with_focus_once_as_it_goes_down() -> void:
	var control: Recorder = await _recorder()
	control.focus_mode = Control.FOCUS_ALL
	control.grab_focus()
	var listener := Listener.new()
	root.add_child(listener)
	await _a_frame_passes()
	control.told.clear()

	_key(KEY_ENTER, true)
	await _a_frame_passes()
	var on_down := control.told.count("pressed")
	_key(KEY_ENTER, true, true)
	_key(KEY_ENTER, false)
	await _a_frame_passes()
	var let_go := control.told.count("pressed")
	_key(KEY_SPACE, true)
	_key(KEY_SPACE, false)
	await _a_frame_passes()

	_verdict.check(on_down == 1, "Enter going down pressed it")
	_verdict.check(let_go == 1, "and neither the key's own repeat nor letting go pressed it again: %d" % let_go)
	_verdict.check(control.told.count("pressed") == 2, "and Space, the other accept key, pressed it once more")
	_verdict.check(listener.heard == 0, "and none of it went past the control: %d heard below" % listener.heard)
	listener.queue_free()
	control.queue_free()
	await _a_frame_passes()


## Held with the left button, then with Enter, counting halfway into the wait,
## halfway to the second repeat, and halfway to the third.
func _a_control_that_asks_to_repeat_is_pressed_again_while_held() -> void:
	var control: Recorder = await _recorder()
	control.focus_mode = Control.FOCUS_ALL
	control.repeat_while_held(WAIT, INTERVAL)

	var started := Time.get_ticks_msec()
	_click(MOUSE_BUTTON_LEFT, true)
	var by_mouse: Array[int] = []
	# each point to count at, the press still held
	for seconds: float in [WAIT / 2, WAIT + INTERVAL / 2, WAIT + INTERVAL * 1.5]:
		await _frames_until(started, seconds)
		by_mouse.append(control.told.count("pressed"))
	_verdict.check(control.rang.count(Interaction.PRESSED) == 1, "pressed three times by one held hand, the press moment rang once, as it landed: a held button does not tick: %s" % [control.rang])
	_click(MOUSE_BUTTON_LEFT, false)
	control.grab_focus()
	await _a_frame_passes()
	control.told.clear()

	started = Time.get_ticks_msec()
	_key(KEY_ENTER, true)
	var by_key: Array[int] = []
	# each point to count at, the key still held and repeating by itself as a keyboard does
	for seconds: float in [WAIT / 2, WAIT + INTERVAL / 2, WAIT + INTERVAL * 1.5]:
		await _frames_until(started, seconds)
		_key(KEY_ENTER, true, true)
		by_key.append(control.told.count("pressed"))
	_key(KEY_ENTER, false)

	_verdict.check(by_mouse == [1, 2, 3], "held with the left button: pressed as it landed, again after the wait, then at the interval: %s" % [by_mouse])
	_verdict.check(by_key == [1, 2, 3], "and held with Enter, the same: %s" % [by_key])
	control.queue_free()
	await _a_frame_passes()


func _a_control_that_does_not_ask_is_pressed_once_however_long_it_is_held() -> void:
	var control: Recorder = await _recorder()

	var started := Time.get_ticks_msec()
	_click(MOUSE_BUTTON_LEFT, true)
	await _frames_until(started, WAIT + INTERVAL * 1.5)
	_click(MOUSE_BUTTON_LEFT, false)
	await _a_frame_passes()

	_verdict.check(control.told.count("pressed") == 1, "held past a wait and two intervals, it was pressed once: %d" % control.told.count("pressed"))
	control.queue_free()
	await _a_frame_passes()


## Three presses that end without a release reaching the control where it is:
## let go off it, a key held while focus walks away, and the control taken out
## of the tree and put back. Each is counted after a repeat would have come.
func _the_repeat_stops_at_the_release_when_focus_leaves_and_when_the_control_leaves_the_tree() -> void:
	var pair: Array[Recorder] = await _screen_of_two()
	var control := pair[0]
	control.repeat_while_held(WAIT, INTERVAL)

	var started := Time.get_ticks_msec()
	_click(MOUSE_BUTTON_LEFT, true)
	_point_at(OUTSIDE)
	_click(MOUSE_BUTTON_LEFT, false, OUTSIDE)
	await _frames_until(started, WAIT + INTERVAL * 1.5)
	var let_go_off := control.told.count("pressed")

	control.grab_focus()
	await _a_frame_passes()
	control.told.clear()
	started = Time.get_ticks_msec()
	_key(KEY_ENTER, true)
	_key(KEY_DOWN, true)
	_key(KEY_DOWN, false)
	await _frames_until(started, WAIT + INTERVAL * 1.5)
	var focus_walked := control.told.count("pressed")
	_key(KEY_ENTER, false)
	control.get_parent().queue_free()
	await _a_frame_passes()

	var lone: Recorder = await _recorder()
	lone.repeat_while_held(WAIT, INTERVAL)
	started = Time.get_ticks_msec()
	_click(MOUSE_BUTTON_LEFT, true)
	await _a_frame_passes()
	root.remove_child(lone)
	root.add_child(lone)
	await _frames_until(started, WAIT + INTERVAL * 1.5)
	var left_the_tree := lone.told.count("pressed")
	_click(MOUSE_BUTTON_LEFT, false)

	_verdict.check(let_go_off == 1, "let go off the control, it was pressed no more: %d" % let_go_off)
	_verdict.check(focus_walked == 1, "a key held while focus walked away pressed it no more: %d" % focus_walked)
	_verdict.check(left_the_tree == 1, "taken out of the tree while held and put back, it was pressed no more: %d" % left_the_tree)
	lone.queue_free()
	await _a_frame_passes()


## Focus given, hidden by a click, walked away from by an arrow, and walked
## back to by Tab, with what each recorder was told read after every step.
func _a_control_is_told_when_its_focus_starts_and_stops_showing() -> void:
	var pair: Array[Recorder] = await _screen_of_two()
	var first := pair[0]
	var second := pair[1]

	first.grab_focus()
	await _a_frame_passes()
	var given := _focus_of(first)
	_click(MOUSE_BUTTON_LEFT, true)
	_click(MOUSE_BUTTON_LEFT, false)
	await _a_frame_passes()
	var clicked := _focus_of(first)
	_key(KEY_DOWN, true)
	_key(KEY_DOWN, false)
	await _a_frame_passes()
	var walked_away := [_focus_of(first), _focus_of(second)]
	_key(KEY_TAB, true)
	_key(KEY_TAB, false)
	await _a_frame_passes()

	_verdict.check(given == ["focused true"], "given focus, its focus showed: %s" % [given])
	_verdict.check(clicked == ["focused true", "focused false"], "a click on it, though it had focus already, hid it: %s" % [clicked])
	_verdict.check(walked_away == [["focused true", "focused false"], ["focused true"]], "the arrow walked to the second, which showed it, and told the first nothing more: %s" % [walked_away])
	_verdict.check(_focus_of(first) == ["focused true", "focused false", "focused true"] and _focus_of(second) == ["focused true", "focused false"], "and Tab walked back, showing it on the first and taking it from the second: %s %s" % [_focus_of(first), _focus_of(second)])
	first.get_parent().queue_free()
	await _a_frame_passes()


## The input map read as the engine loaded it from this folder's project, then
## the pad's A and d-pad pushed at two recorders.
func _the_input_map_gives_the_pad_what_it_needs() -> void:
	var lacking: Array[StringName] = []
	# each action a pad needs, kept if it lacks its pad button or its keys
	for action: StringName in PAD:
		var events := InputMap.action_get_events(action)
		var holds_the_pad := events.any(func(event: InputEvent) -> bool: return event is InputEventJoypadButton and (event as InputEventJoypadButton).button_index == PAD[action])
		var keeps_its_keys := events.any(func(event: InputEvent) -> bool: return event is InputEventKey)
		if not holds_the_pad or not keeps_its_keys:
			lacking.append(action)
	var pair: Array[Recorder] = await _screen_of_two()
	pair[0].grab_focus()
	await _a_frame_passes()

	_pad(JOY_BUTTON_A)
	await _a_frame_passes()
	var pressed_by_a := pair[0].told.count("pressed")
	_pad(JOY_BUTTON_DPAD_DOWN)
	await _a_frame_passes()

	_verdict.check(lacking.is_empty(), "every action holds its pad button and keeps its keys; lacking: %s" % [lacking])
	_verdict.check(pressed_by_a == 1, "the pad's A pressed the control with focus")
	_verdict.check(pair[1].has_focus(), "and its d-pad walked focus to the one below")
	pair[0].get_parent().queue_free()
	await _a_frame_passes()
