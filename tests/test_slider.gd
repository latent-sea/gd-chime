extends SceneTree

## What must be true of a slider: a drag shows the value under the pointer
## and sends one command, on the release; left and right step it, from the
## keys and the pad, where nothing taking the focus stands beside it in its
## row, and where something does they walk past it and accept grabs it; it
## is held between its ends; a value the door refuses leaves it and says why;
## and it wears its style's track, fill and handle.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_slider.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const ValueSlider := preload("res://addons/gd_chime/components/primitives/slider.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Verdict := preload("res://tests/verdict.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const SoundBus := preload("res://addons/gd_chime/sound_bus.gd")
const Setting := preload("res://addons/gd_chime/components/recipes/setting.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Fields := preload("res://addons/gd_chime/theme_fields.gd")

const OUTSIDE := Vector2(390, 390)

var _verdict := Verdict.new()


## A level from 0 to 1: set to whatever it is told, refusing anything past its loudest.
class Level extends Fixture.Model:
	var said: Array = []  # every value it was told, in order
	var loudest := value(1.0)

	func would(_action: StringName, payload: Dictionary) -> Phrase:
		return Phrase.of("too loud") if payload["value"] > loudest.read() + 0.001 else null

	func told(action: StringName, payload: Dictionary) -> Phrase:
		told_actions.append(action)
		said.append(payload["value"])
		set_value(&"level", payload["value"])
		return null


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(400, 400)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_a_drag_across_the_whole_track_shows_the_pointer_s_value_and_sends_one_command_on_the_release)
	await _verdict.states(_alone_in_its_row_left_and_right_step_it_from_the_keys_and_the_pad_and_up_and_down_leave_it)
	await _verdict.states(_beside_others_in_its_row_the_pad_walks_past_it_and_accept_grabs_it_to_step_it)
	await _verdict.states(_it_is_held_between_its_ends)
	await _verdict.states(_a_value_the_door_refuses_leaves_it_where_it_was_and_the_reason_says_why)
	await _verdict.states(_a_refused_release_settles_back_on_the_model_s_value_with_the_reason)
	await _verdict.states(_it_wears_its_style_s_track_fill_and_handle_and_is_inert_while_its_value_is_refused)
	await _verdict.states(_its_first_use_the_settings_volume_sets_the_sounds_volume_through_the_door)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## An app holding one slider over the level, from 0 to 1 by tenths, in a
## row: between two local presses, BEFORE and BESIDE, or alone with its
## words as a settings row has it. A press FAR above it at the left edge, in
## a row of its own, and one UNDER it.
func _app(made: Fixture, level: Level, among_others: bool = false) -> ValueSlider:
	var ui := made.ui
	made.commands.register(&"app", &"sets_level", level)
	var slider: Desc = ui.slider(&"sets_level", level.of(&"level"), {minimum = 0.0, maximum = 1.0, step = 0.1}).named(&"slider").grow()
	var before := ui.press_local(ui.local(false), true, [ui.text("before")]).named(&"before")
	var beside := ui.press_local(ui.local(false), true, [ui.text("beside")]).named(&"beside")
	var far := ui.press_local(ui.local(false), true, [ui.text("far")]).named(&"far")
	var under := ui.press_local(ui.local(false), true, [ui.text("under")]).named(&"under")
	var line := ui.row([before, slider, beside]) if among_others else ui.row([ui.text("the level"), slider])
	ui.start(ui.app(&"app", [ui.column([ui.row([far]), line, under])]))
	return ui.node_named(&"slider")


## Where the handle stands for this value, in the window.
func _at(slider: ValueSlider, value: float) -> Vector2:
	return slider.global_position + Vector2(slider._x_of(value), slider._band().get_center().y)


func _button(at: Vector2, down: bool) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = down
	click.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	click.position = at
	root.push_input(click)


func _pointer(at: Vector2, held: bool) -> void:
	var move := InputEventMouseMotion.new()
	move.position = at
	move.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	root.push_input(move)


func _key(keycode: Key) -> void:
	var key := InputEventKey.new()
	key.keycode = keycode
	key.pressed = true
	root.push_input(key)


func _pad(button: JoyButton) -> void:
	var pressed := InputEventJoypadButton.new()
	pressed.button_index = button
	pressed.pressed = true
	root.push_input(pressed)


## Whether two lists of numbers agree, each to within a hair.
func _near(a: Array, b: Array) -> bool:
	return a.size() == b.size() and range(a.size()).all(func(index: int) -> bool: return is_equal_approx(a[index], b[index]))


func _words(slider: ValueSlider) -> Text:
	return slider.get_child(0)


func _reason(slider: ValueSlider) -> Text:
	return slider.get_child(1)


func _a_drag_across_the_whole_track_shows_the_pointer_s_value_and_sends_one_command_on_the_release() -> void:
	var made := Fixture.new(root, {&"sets_level": "set the level"})
	var level := Level.new(made.chimes, &"app")
	level.set_value(&"level", 0.5)
	var slider := _app(made, level)
	await _a_frame_passes()
	_verdict.check(_words(slider).get_text() == "0.5", "the value's words stand beside it, written to the step's places: %s" % _words(slider).get_text())
	var words := Rect2(_words(slider).position, _words(slider).size)
	_verdict.check(words.position.x >= slider._band().end.x and slider._band().size.x >= root.theme.get_constant(&"least_track", Fields.SLIDER), "the words are beside the track, never over it, and the track has at least its least length: %s %s" % [words, slider._band()])
	_button(_at(slider, 0.0), true)
	await _a_frame_passes()
	_verdict.check(level.said.is_empty() and _words(slider).get_text() == "0.0" and is_equal_approx(slider._shown.read(), 0.0), "pressed at the start of the track, it shows the value there and sends nothing yet: %s %s" % [level.said, _words(slider).get_text()])
	var shown_on_the_way: Array = []
	# the pointer held across every step of the track, the last one off it below, noting what it shows at each
	for step: int in range(1, 11):
		_pointer(_at(slider, step / 10.0) + (Vector2(0, 60) if step == 6 else Vector2.ZERO), true)
		await _a_frame_passes()
		shown_on_the_way.append(_words(slider).get_text())
	_verdict.check(shown_on_the_way == ["0.1", "0.2", "0.3", "0.4", "0.5", "0.6", "0.7", "0.8", "0.9", "1.0"] and is_equal_approx(slider._shown.read(), 1.0), "dragging, the words and the handle follow the pointer, even off the track: %s" % [shown_on_the_way])
	_verdict.check(level.said.is_empty() and is_equal_approx(slider.get_value(), 0.5), "and nothing goes through the door while it is held: the model still has its value: %s" % [level.said])
	_button(_at(slider, 1.0), false)
	await _a_frame_passes()
	_verdict.check(_near(level.said, [1.0]) and made.commands.get_last()["payload"].keys() == ["value"], "the release sends one command, the value let go at, as {value}: %s %s" % [level.said, made.commands.get_last()["payload"]])
	_verdict.check(is_equal_approx(slider.get_value(), 1.0) and _words(slider).get_text() == "1.0" and slider._held.read() == null, "and the model's value is what it shows, nothing held: %s" % _words(slider).get_text())
	_pointer(_at(slider, 0.4), false)
	await _a_frame_passes()
	_verdict.check(_near(level.said, [1.0]) and _words(slider).get_text() == "1.0", "released, the pointer moving moves nothing: %s" % [level.said])
	_button(_at(slider, 0.2), true)
	_button(_at(slider, 0.2), false)
	await _a_frame_passes()
	_verdict.check(_near(level.said, [1.0, 0.2]), "a press in the track with no drag is one command, sent as it is released: %s" % [level.said])
	_button(slider.global_position + words.get_center(), true)
	_pointer(slider.global_position + words.get_center() + Vector2(-40, 0), true)
	_button(slider.global_position + words.get_center(), false)
	await _a_frame_passes()
	_verdict.check(_near(level.said, [1.0, 0.2]), "a press on its words, and a drag from there, is not a press in the track: %s" % [level.said])
	_pointer(OUTSIDE, false)
	level.free()
	made.done()


func _alone_in_its_row_left_and_right_step_it_from_the_keys_and_the_pad_and_up_and_down_leave_it() -> void:
	var made := Fixture.new(root, {&"sets_level": "set the level"})
	var level := Level.new(made.chimes, &"app")
	level.set_value(&"level", 0.5)
	var slider := _app(made, level)
	await _a_frame_passes()
	var outside_its_row := [made.ui.node_named(&"far"), made.ui.node_named(&"under")]
	_verdict.check(outside_its_row.has(slider.find_valid_focus_neighbor(SIDE_LEFT)), "the engine's own walk finds a neighbour to its left outside its row - FAR above or UNDER below, each starting further left: %s" % [slider.find_valid_focus_neighbor(SIDE_LEFT)])
	slider.grab_focus()
	_key(KEY_RIGHT)
	await _a_frame_passes()
	_pad(JOY_BUTTON_DPAD_RIGHT)
	await _a_frame_passes()
	_pad(JOY_BUTTON_DPAD_LEFT)
	await _a_frame_passes()
	_key(KEY_LEFT)
	_key(KEY_LEFT)
	await _a_frame_passes()
	_verdict.check(_near(level.said, [0.6, 0.7, 0.6, 0.5, 0.4]), "nothing taking the focus beside it in its row - FAR above does not count - the arrow keys and the d-pad step it, one command a step: %s" % [level.said])
	_verdict.check(slider.has_focus(), "left and right are its own: the focus stays on it")
	_key(KEY_ENTER)
	await _a_frame_passes()
	_verdict.check(level.said.size() == 5 and slider.get_state() != &"lifted", "accept alone changes nothing and grabs nothing: %s %s" % [level.said, slider.get_state()])
	_key(KEY_DOWN)
	await _a_frame_passes()
	_verdict.check(root.gui_get_focus_owner() == made.ui.node_named(&"under"), "down leaves it, to what is under it: %s" % [root.gui_get_focus_owner()])
	level.free()
	made.done()


func _beside_others_in_its_row_the_pad_walks_past_it_and_accept_grabs_it_to_step_it() -> void:
	var made := Fixture.new(root, {&"sets_level": "set the level"})
	var level := Level.new(made.chimes, &"app")
	level.set_value(&"level", 0.5)
	var slider := _app(made, level, true)
	await _a_frame_passes()
	slider.grab_focus()
	_key(KEY_RIGHT)
	await _a_frame_passes()
	var right_to: Control = root.gui_get_focus_owner()
	slider.grab_focus()
	_pad(JOY_BUTTON_DPAD_LEFT)
	await _a_frame_passes()
	_verdict.check(right_to == made.ui.node_named(&"beside") and root.gui_get_focus_owner() == made.ui.node_named(&"before") and level.said.is_empty(), "between two presses in its row, right and left walk past it like any control, stepping nothing: %s %s %s" % [right_to, root.gui_get_focus_owner(), level.said])
	slider.grab_focus()
	_key(KEY_ENTER)
	await _a_frame_passes()
	_verdict.check(slider.get_state() == &"lifted" and level.said.is_empty(), "accept grabs it, drawn lifted as a carried thing is, and sends nothing: %s" % slider.get_state())
	_key(KEY_RIGHT)
	await _a_frame_passes()
	_pad(JOY_BUTTON_DPAD_RIGHT)
	await _a_frame_passes()
	_key(KEY_DOWN)
	await _a_frame_passes()
	_verdict.check(_near(level.said, [0.6, 0.7]) and slider.has_focus(), "grabbed, the key and the pad step it, one command a step, and down goes nowhere: %s %s" % [level.said, root.gui_get_focus_owner()])
	_key(KEY_ENTER)
	await _a_frame_passes()
	_key(KEY_RIGHT)
	await _a_frame_passes()
	_verdict.check(root.gui_get_focus_owner() == made.ui.node_named(&"beside") and _near(level.said, [0.6, 0.7]) and slider.get_state() != &"lifted", "accept lets it go where it is, and right walks past it again: %s %s" % [root.gui_get_focus_owner(), level.said])
	slider.grab_focus()
	_pad(JOY_BUTTON_A)
	await _a_frame_passes()
	_key(KEY_LEFT)
	_pad(JOY_BUTTON_DPAD_LEFT)
	await _a_frame_passes()
	_key(KEY_ESCAPE)
	await _a_frame_passes()
	_verdict.check(_near(level.said, [0.6, 0.7, 0.6, 0.5, 0.7]) and is_equal_approx(slider.get_value(), 0.7) and slider.get_state() != &"lifted" and slider.has_focus(), "grabbed by the pad and stepped down twice, cancel lets it go back at the value it had as it was grabbed: %s" % [level.said])
	_key(KEY_ENTER)
	await _a_frame_passes()
	(made.ui.node_named(&"under") as Control).grab_focus()
	await _a_frame_passes()
	_verdict.check(slider.get_state() != &"lifted" and is_equal_approx(slider.get_value(), 0.7), "grabbed, and the focus taken elsewhere by another hand, it is let go where it is: %s" % slider.get_state())
	level.free()
	made.done()


func _it_is_held_between_its_ends() -> void:
	var made := Fixture.new(root, {&"sets_level": "set the level"})
	var level := Level.new(made.chimes, &"app")
	level.set_value(&"level", 0.5)
	var slider := _app(made, level)
	await _a_frame_passes()
	_button(_at(slider, 0.5), true)
	_pointer(_at(slider, 1.0) + Vector2(200, 0), true)
	_button(_at(slider, 1.0) + Vector2(200, 0), false)
	await _a_frame_passes()
	slider.grab_focus()
	_key(KEY_RIGHT)
	await _a_frame_passes()
	_verdict.check(_near(level.said, [1.0]), "dragged past the maximum it is the maximum, and a step on from there asks nothing: %s" % [level.said])
	_button(_at(slider, 1.0), true)
	_pointer(Vector2(-50, _at(slider, 0.0).y), true)
	_button(Vector2(-50, _at(slider, 0.0).y), false)
	await _a_frame_passes()
	_key(KEY_LEFT)
	await _a_frame_passes()
	_verdict.check(_near(level.said, [1.0, 0.0]), "and past the minimum it is the minimum, and a step below asks nothing: %s" % [level.said])
	_pointer(OUTSIDE, false)
	level.free()
	made.done()


func _a_value_the_door_refuses_leaves_it_where_it_was_and_the_reason_says_why() -> void:
	var made := Fixture.new(root, {&"sets_level": "set the level"})
	var level := Level.new(made.chimes, &"app")
	level.set_value(&"level", 0.5)
	level.loudest.set_value(0.8)
	var slider := _app(made, level)
	await _a_frame_passes()
	_verdict.check(not _reason(slider).visible, "nothing refused, no reason shows")
	var line_before := slider.size.y
	_button(_at(slider, 0.9), true)
	_button(_at(slider, 0.9), false)
	await _a_frame_passes()
	_verdict.check(level.said.is_empty() and str(made.commands.get_last()["answer"]) == "too loud" and is_equal_approx(slider.get_value(), 0.5) and _words(slider).get_text() == "0.5", "the door refused the value: the model was told nothing and the slider still shows what the model has: %s" % [level.said])
	_verdict.check(_reason(slider).visible and _reason(slider).get_text() == "too loud", "and the door's reason is shown: %s" % _reason(slider).get_text())
	var reason := Rect2(_reason(slider).position, _reason(slider).size)
	_verdict.check(reason.position.y >= slider._band().end.y and slider.size.y > line_before, "under the track, the slider growing to hold it: %s %s" % [reason, slider._band()])
	_button(_at(slider, 0.7), true)
	_button(_at(slider, 0.7), false)
	await _a_frame_passes()
	_verdict.check(_near(level.said, [0.7]) and not _reason(slider).visible, "a value the door takes clears it: %s" % [level.said])
	_pointer(OUTSIDE, false)
	level.free()
	made.done()


func _a_refused_release_settles_back_on_the_model_s_value_with_the_reason() -> void:
	var made := Fixture.new(root, {&"sets_level": "set the level"})
	var level := Level.new(made.chimes, &"app")
	level.set_value(&"level", 0.5)
	level.loudest.set_value(0.8)
	var slider := _app(made, level)
	await _a_frame_passes()
	_button(_at(slider, 0.5), true)
	_pointer(_at(slider, 0.9), true)
	await _a_frame_passes()
	_verdict.check(_words(slider).get_text() == "0.9" and is_equal_approx(slider._shown.read(), 0.9) and not _reason(slider).visible, "held past what the door takes, it shows the value under the pointer, and nothing is refused yet: %s" % _words(slider).get_text())
	_button(_at(slider, 0.9), false)
	await _a_frame_passes()
	_verdict.check(level.said.is_empty() and str(made.commands.get_last()["answer"]) == "too loud", "the release is sent and refused: %s" % [level.said])
	_verdict.check(_words(slider).get_text() == "0.5" and is_equal_approx(slider._shown.read(), 0.5), "the words and the handle settle back on the model's value: %s %s" % [_words(slider).get_text(), slider._shown.read()])
	_verdict.check(_reason(slider).visible and _reason(slider).get_text() == "too loud", "and the door's reason is shown, as any refusal's: %s" % _reason(slider).get_text())
	_pointer(OUTSIDE, false)
	level.free()
	made.done()


func _it_wears_its_style_s_track_fill_and_handle_and_is_inert_while_its_value_is_refused() -> void:
	var made := Fixture.new(root, {&"sets_level": "set the level"})
	var level := Level.new(made.chimes, &"app")
	level.set_value(&"level", 0.5)
	var slider := _app(made, level)
	await _a_frame_passes()
	var own := [&"track", &"fill", &"handle"].all(func(box: StringName) -> bool: return slider.get_theme_stylebox(box) == root.theme.get_stylebox(box, Fields.SLIDER) and root.theme.has_stylebox(box, Fields.SLIDER))
	var numbers := [&"handle_width", &"track_thickness", &"least_track", &"gap"].all(func(number: StringName) -> bool: return root.theme.has_constant(number, Fields.SLIDER) and slider.get_theme_constant(number) > 0)
	_verdict.check(slider.theme_type_variation == Fields.SLIDER and own and numbers, "it wears its style, which the floor's look gives a track, a fill, a handle and its numbers: %s" % slider.theme_type_variation)
	_verdict.check(slider.get_drawn()[0] == root.theme.get_stylebox(&"normal", Themes.PRESSABLE), "its ground is a pressable's for its state")
	level.loudest.set_value(0.3)
	await _a_frame_passes()
	_button(_at(slider, 0.2), true)
	_button(_at(slider, 0.2), false)
	slider.grab_focus()
	_key(KEY_LEFT)
	await _a_frame_passes()
	_verdict.check(slider.get_state() == &"inert" and level.said.is_empty() and _reason(slider).get_text() == "too loud", "the value it has refused, it is inert, says why, and nothing moves it: %s %s" % [slider.get_state(), level.said])
	_pointer(OUTSIDE, false)
	level.free()
	made.done()


## The settings row of the volume, a slider over the game's bus's volume, 0 to 1 by tenths, and the bus answering it from anywhere.
func _its_first_use_the_settings_volume_sets_the_sounds_volume_through_the_door() -> void:
	var made := Fixture.new(root, {SoundBus.SETS_VOLUME: "set the volume"})
	var ui := made.ui
	var sound_bus := SoundBus.new(made.chimes)
	made.commands.register(Chimes.GLOBAL, SoundBus.SETS_VOLUME, sound_bus)
	root.add_child(sound_bus)
	var volume := ui.slider(SoundBus.SETS_VOLUME, sound_bus.volume, {minimum = 0.0, maximum = 1.0, step = 0.1}).named(&"volume")
	ui.start(ui.app(&"app", [Setting.row(ui, Phrase.of("volume"), Phrase.of("how loud the sounds are"), volume.grow())]))
	await _a_frame_passes()
	var slider: ValueSlider = ui.node_named(&"volume")
	slider.grab_focus()
	_pad(JOY_BUTTON_DPAD_LEFT)
	_pad(JOY_BUTTON_DPAD_LEFT)
	await _a_frame_passes()
	var bus := AudioServer.get_bus_index(sound_bus.named)
	_verdict.check(is_equal_approx(sound_bus.volume.read(), 0.8) and is_equal_approx(AudioServer.get_bus_volume_db(bus), linear_to_db(0.8)) and _words(slider).get_text() == "0.8", "two steps down on the pad, the volume is 0.8, on the game's bus, and the slider says so: %s" % _words(slider).get_text())
	sound_bus.told(SoundBus.SETS_VOLUME, {"value": 1.0})
	made.done()
