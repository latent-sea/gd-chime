extends SceneTree

## What must be true of a range slider: a press takes the nearer end and a
## drag holds the stretch under the pointer, sending one command on the
## release, {value: Vector2}; an end dragged past the other stops there;
## left and right step the end being moved, accept turns to the other - said
## in words under it - and each step is one command; the stretch is held
## between the ends of the track; and a stretch the door refuses leaves the
## handles where they were, the reason saying why.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_range_slider.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const RangeSlider := preload("res://addons/gd_chime/components/primitives/range_slider.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Verdict := preload("res://tests/verdict.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")

const SETS := &"sets_the_price"

var _verdict := Verdict.new()


## A price from 0 to 100: set to whatever it is told, refusing a stretch under 10 wide.
class Price extends Fixture.Model:
	var said: Array = []

	func get_price() -> Variant:
		return of(&"price").read()

	func would(_action: StringName, payload: Dictionary) -> Phrase:
		return Phrase.of("too narrow") if payload["value"].y - payload["value"].x < 10.0 else null

	func told(_action: StringName, payload: Dictionary) -> Phrase:
		said.append(payload["value"])
		set_value(&"price", payload["value"])
		return null


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(600, 300)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_a_press_takes_the_nearer_end_and_a_drag_is_one_command_on_the_release)
	await _verdict.states(_an_end_dragged_past_the_other_stops_there)
	await _verdict.states(_the_keys_step_the_end_being_moved_and_accept_turns_to_the_other)
	await _verdict.states(_a_stretch_the_door_refuses_leaves_the_handles_and_the_reason_says_why)
	quit(_verdict.deliver(get_script()))


## An app holding one range slider over the price, from 0 to 100 by fives, starting at 20 to 80.
func _app() -> Array:
	var made := Fixture.new(root, {SETS: "set the price"})
	var price := Price.new(made.chimes, &"app")
	price.set_value(&"price", Vector2(20, 80))
	root.add_child(price)
	made.commands.register(&"app", SETS, price)
	var ui := made.ui
	var worded := func(stretch: Vector2) -> Phrase: return Phrase.with("%d to %d", [stretch.x, stretch.y])
	ui.start(ui.app(&"app", [ui.column([ui.range_slider(SETS, Bound.new(price.get_price), {minimum = 0.0, maximum = 100.0, step = 5.0, words = worded}).named(&"range")])]))
	await _frames()
	return [made, price, ui.node_named(&"range")]


func _frames() -> void:
	await process_frame
	await process_frame


func _at(slider: RangeSlider, value: float) -> Vector2:
	return slider.global_position + Vector2(slider._x_of(value), slider._band().get_center().y)


func _button(at: Vector2, down: bool) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = down
	click.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	click.position = at
	root.push_input(click)


func _pointer(at: Vector2) -> void:
	var move := InputEventMouseMotion.new()
	move.position = at
	move.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(move)


func _key(keycode: Key) -> void:
	var key := InputEventKey.new()
	key.keycode = keycode
	key.physical_keycode = keycode
	key.pressed = true
	root.push_input(key)


func _said(slider: RangeSlider) -> Array:
	return slider.get_children().filter(func(part: Node) -> bool: return part is Text and part.visible).map(func(part: Text) -> String: return part.get_text())


func _a_press_takes_the_nearer_end_and_a_drag_is_one_command_on_the_release() -> void:
	var built: Array = await _app()
	var price: Price = built[1]
	var slider: RangeSlider = built[2]
	_verdict.check(_said(slider)[0] == "20 to 80", "the stretch's words stand beside it, in the caller's words: %s" % [_said(slider)])
	_button(_at(slider, 70), true)
	_pointer(_at(slider, 60))
	await _frames()
	_verdict.check(price.said.is_empty() and slider._shown.read() == Vector2(20, 60) and _said(slider)[0] == "20 to 60", "pressed near the most, the most follows the pointer and nothing is sent yet: %s" % [slider._shown.read()])
	_button(_at(slider, 60), false)
	await _frames()
	_verdict.check(price.said == [Vector2(20, 60)], "the release sends one command, {value: the stretch}: %s" % [price.said])
	_button(_at(slider, 30), true)
	_button(_at(slider, 30), false)
	await _frames()
	_verdict.check(price.said == [Vector2(20, 60), Vector2(30, 60)] and slider.get_moving() == RangeSlider.LEAST, "a press nearer the least moves the least: %s" % [price.said])
	(built[0] as Fixture).done()


func _an_end_dragged_past_the_other_stops_there() -> void:
	var built: Array = await _app()
	var slider: RangeSlider = built[2]
	_button(_at(slider, 20), true)
	_pointer(_at(slider, 95))
	await _frames()
	_verdict.check(slider._shown.read() == Vector2(80, 80), "the least dragged past the most stops at it: %s" % [slider._shown.read()])
	_button(_at(slider, 95), false)
	(built[0] as Fixture).done()


func _the_keys_step_the_end_being_moved_and_accept_turns_to_the_other() -> void:
	var built: Array = await _app()
	var price: Price = built[1]
	var slider: RangeSlider = built[2]
	slider.grab_focus()
	_key(KEY_RIGHT)
	await _frames()
	_verdict.check(price.said == [Vector2(25, 80)] and _said(slider).has("The keys move the least"), "right steps the least by the step, one command, and which end moves is said: %s %s" % [price.said, _said(slider)])
	_key(KEY_ENTER)
	_key(KEY_LEFT)
	await _frames()
	_verdict.check(price.said.back() == Vector2(25, 75) and _said(slider).has("The keys move the most"), "accept turns to the most, and left steps it down: %s %s" % [price.said, _said(slider)])
	# the most stepped past the top: held at the track's end
	for step: int in 8:
		_key(KEY_RIGHT)
	await _frames()
	_verdict.check(price.said.back() == Vector2(25, 100), "held at the track's end: %s" % [price.said.back()])
	(built[0] as Fixture).done()


func _a_stretch_the_door_refuses_leaves_the_handles_and_the_reason_says_why() -> void:
	var built: Array = await _app()
	var price: Price = built[1]
	var slider: RangeSlider = built[2]
	_button(_at(slider, 80), true)
	_pointer(_at(slider, 25))
	_button(_at(slider, 25), false)
	await _frames()
	_verdict.check(price.said.is_empty() and slider._shown.read() == Vector2(20, 80) and _said(slider).has("too narrow"), "a stretch too narrow is refused: the handles stay and the reason says why: %s %s" % [slider._shown.read(), _said(slider)])
	(built[0] as Fixture).done()
