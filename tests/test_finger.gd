extends SceneTree

## What must be true of a finger on the floor's controls: a press is a tap,
## a list scrolls under it and glides on, and on a phone's window anything
## pressed is big enough to hit - while the mouse, the keys and the pad press
## as they always did.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_finger.gd
##
## The touches go in as a device's do, through Input.parse_input_event, so
## the engine makes its mouse from them first (touch.gd); the mouse, the keys
## and the pad go in at the window. The app is a list of forty rows, each a
## pressable of one action, over a slider, in a scroll.

const Fixture := preload("res://tests/fixture.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Shape := preload("res://addons/gd_chime/shape.gd")
const Touch := preload("res://addons/gd_chime/touch.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Verdict := preload("res://tests/verdict.gd")

const PICKS := &"picks"
const SETS := &"sets"

var _verdict := Verdict.new()
var _made: Fixture
var _model: Fixture.Model
var _scroll: ScrollContainer


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	# a look that sets a least touch size, as the floor's does not
	root.theme.set_constant(&"least", &"Touch", 88)
	await process_frame
	await _verdict.states(_a_finger_that_scrolls_the_list_presses_no_row)
	await _verdict.states(_a_tap_presses_once_as_the_finger_lifts)
	await _verdict.states(_the_mouse_the_keys_and_the_pad_press_as_before)
	await _verdict.states(_let_go_moving_the_list_glides_on_the_clock_and_reduced_it_stops_dead)
	await _verdict.states(_a_list_at_its_top_lets_a_finger_drawn_down_go_by)
	await _verdict.states(_a_finger_on_a_slider_moves_no_list)
	await _verdict.states(_on_a_phone_s_window_a_pressable_is_at_least_the_look_s_least)
	quit(_verdict.deliver(get_script()))


## The list of rows over a slider, in a scroll, in a window this size.
func _standing(window: Vector2i = Vector2i(1920, 1080)) -> void:
	_made = Fixture.new(root, {PICKS: "pick", SETS: "set"})
	_model = Fixture.Model.new(_made.chimes)
	_model.set_value(&"flag", 3.0)
	root.add_child(_model)
	_made.commands.register(Chimes.GLOBAL, PICKS, _model)
	_made.commands.register(Chimes.GLOBAL, SETS, _model)
	var ui := _made.ui
	var rows: Array = range(40).map(func(at: int) -> RefCounted: return ui.pressable(PICKS, {"row": at}, [ui.text("row %d" % at)]).named(StringName("row %d" % at)))
	var slider := ui.slider(SETS, _model.of(&"flag"), {minimum = 0.0, maximum = 10.0, step = 1.0}).named(&"slider")
	ui.start(ui.app(&"app", [ui.scroll(ui.column([slider] + rows)).named(&"list")]))
	root.size = window
	# the frames the start, the first move and the window's shape take
	for frame: int in 6:
		await process_frame
	_scroll = ui.node_named(&"list")


## Everything under the root freed, the model with it.
func _done() -> void:
	_made.done()


## A point of the canvas, in the window's own pixels.
func _on_window(canvas: Vector2) -> Vector2:
	return root.get_final_transform() * canvas


## A control's middle, on the canvas.
func _middle(named: StringName) -> Vector2:
	return (_made.ui.node_named(named) as Control).get_global_rect().get_center()


func _touch(at: Vector2, down: bool) -> void:
	var touched := InputEventScreenTouch.new()
	touched.position = _on_window(at)
	touched.pressed = down
	Input.parse_input_event(touched)
	await process_frame


## A finger drawn from a point of the canvas by these steps, a frame each; lifted if asked.
func _drawn(at: Vector2, steps: Array, lifts: bool = true) -> void:
	await _touch(at, true)
	var now := at
	# every step, one drag a frame, in the window's pixels
	for step: Vector2 in steps:
		now += step
		var drag := InputEventScreenDrag.new()
		drag.position = _on_window(now)
		drag.relative = root.get_final_transform().basis_xform(step)
		Input.parse_input_event(drag)
		await process_frame
	if lifts:
		await _touch(now, false)


func _a_finger_that_scrolls_the_list_presses_no_row() -> void:
	await _standing()
	await _drawn(_middle(&"row 10"), [Vector2(0, -40), Vector2(0, -40), Vector2(0, -40)])
	_verdict.check(_model.told_actions.is_empty(), "a finger landing on a row and drawn up the list presses nothing: %s" % [_model.told_actions])
	_verdict.check(_scroll.scroll_vertical >= 80, "and the list followed it: %d" % _scroll.scroll_vertical)
	_done()


func _a_tap_presses_once_as_the_finger_lifts() -> void:
	await _standing()
	await _touch(_middle(&"row 3"), true)
	var landed := _model.told_actions.duplicate()
	await _touch(_middle(&"row 3") + Vector2(4, 2), false)
	_verdict.check(landed.is_empty() and _model.told_actions == [PICKS], "a finger landing presses nothing, and lifted within the slop it presses once: %s then %s" % [landed, _model.told_actions])
	# drawn past the slop across the row and back, lifted where it landed: a gesture nobody took, and no tap
	await _drawn(_middle(&"row 3"), [Vector2(40, 0), Vector2(-40, 0)])
	_verdict.check(_model.told_actions == [PICKS], "a finger drawn past the slop and back to where it landed presses nothing: %s" % [_model.told_actions])
	_done()


func _the_mouse_the_keys_and_the_pad_press_as_before() -> void:
	await _standing()
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = _on_window(_middle(&"row 3"))
	root.push_input(click)
	await process_frame
	_verdict.check(_model.told_actions == [PICKS], "the mouse's button presses a row as it goes down, as ever: %s" % [_model.told_actions])
	(_made.ui.node_named(&"row 4") as Control).grab_focus()
	var key := InputEventKey.new()
	key.keycode = KEY_ENTER
	key.pressed = true
	root.push_input(key)
	await process_frame
	_verdict.check(_model.told_actions == [PICKS, PICKS], "Enter presses the row with the focus: %s" % [_model.told_actions])
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_A
	pad.pressed = true
	root.push_input(pad)
	await process_frame
	_verdict.check(_model.told_actions == [PICKS, PICKS, PICKS], "and the pad's A presses it too: %s" % [_model.told_actions])
	_done()


func _let_go_moving_the_list_glides_on_the_clock_and_reduced_it_stops_dead() -> void:
	await _standing()
	var motion := _made.ui.motion
	motion.still = false
	motion.by_hand = true
	await _drawn(_middle(&"row 12"), [Vector2(0, -40), Vector2(0, -60), Vector2(0, -60)], false)
	var let_go := _scroll.get_v_scroll_bar().value
	await _touch(_middle(&"row 12") + Vector2(0, -160), false)
	var lifted := _scroll.get_v_scroll_bar().value
	motion.step(1.0)
	var glided := _scroll.get_v_scroll_bar().value
	_verdict.check(lifted == let_go and glided > let_go, "let go moving up the list, it glides on further up, on the clock and not before: %s, %s, then %s" % [let_go, lifted, glided])
	motion.told(motion.REDUCES, {"on": true})
	# drawn back down the list, from wherever the glide left it, so there is room to glide either way
	var at := _scroll.get_global_rect().get_center()
	await _drawn(at, [Vector2(0, 40), Vector2(0, 60), Vector2(0, 60)], false)
	let_go = _scroll.get_v_scroll_bar().value
	await _touch(at + Vector2(0, 160), false)
	motion.step(1.0)
	_verdict.check(let_go > 0.0 and _scroll.get_v_scroll_bar().value == let_go, "with motion reduced, it stops dead where the finger left it: %s then %s" % [let_go, _scroll.get_v_scroll_bar().value])
	_done()


func _a_list_at_its_top_lets_a_finger_drawn_down_go_by() -> void:
	await _standing()
	await _drawn(_middle(&"row 2"), [Vector2(0, 40), Vector2(0, 40)], false)
	_verdict.check(_made.ui.touch.get_taken() == null and _scroll.scroll_vertical == 0, "a list at its top takes no finger drawn down, and stays at its top")
	await _touch(_middle(&"row 2") + Vector2(0, 80), false)
	_done()


func _a_finger_on_a_slider_moves_no_list() -> void:
	await _standing()
	await _drawn(_middle(&"slider"), [Vector2(0, -40), Vector2(0, -40)], false)
	_verdict.check(_made.ui.touch.get_taken() == null and _scroll.scroll_vertical == 0, "a finger drawn on a slider is the slider's: the list under it does not move: %d" % _scroll.scroll_vertical)
	await _touch(_middle(&"slider") + Vector2(0, -80), false)
	_done()


func _on_a_phone_s_window_a_pressable_is_at_least_the_look_s_least() -> void:
	await _standing(Vector2i(1920, 1080))
	var row: Pressable = _made.ui.node_named(&"row 5")
	var least := float(row.get_theme_constant(&"least", Touch.TYPE))
	var wide := row.get_combined_minimum_size()
	root.size = Vector2i(720, 1280)
	# the frames the window's turn and its measuring again take
	for frame: int in 4:
		await process_frame
	var phone := row.get_combined_minimum_size()
	_verdict.check(wide.y < least and phone.y >= least and phone.x >= least, "on a wide window a row of one line is shorter than the least touch size, %s; on a phone's it is at least it each way, %s" % [wide, phone])
	root.size = Vector2i(1920, 1080)
	# the frames the window's turn back takes
	for frame: int in 4:
		await process_frame
	_verdict.check(row.get_combined_minimum_size() == wide, "and turned back to a wide window, live, it needs what it did: %s" % [row.get_combined_minimum_size()])
	# narrowed to a compact window still on its side: a desktop's window narrowed, not a phone's
	root.size = Vector2i(800, 700)
	# the frames the class moving takes
	for frame: int in 4:
		await process_frame
	_verdict.check(row.get_combined_minimum_size() == wide, "a narrow window on its side is no phone's: it needs what it did: %s" % [row.get_combined_minimum_size()])
	# a window on its end, wide enough to be regular, narrowed to a phone's: the class moves and the window does not turn
	root.size = Vector2i(1000, 1400)
	# the frames the turn takes
	for frame: int in 4:
		await process_frame
	var tall := row.get_combined_minimum_size()
	root.size = Vector2i(720, 1400)
	# the frames the class moving takes
	for frame: int in 4:
		await process_frame
	_verdict.check(tall.y < least and row.get_combined_minimum_size().y >= least, "narrowed on its end to a phone's without turning, it is at least the least at once: %s then %s" % [tall, row.get_combined_minimum_size()])
	_done()
