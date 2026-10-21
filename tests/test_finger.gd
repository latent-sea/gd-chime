extends SceneTree

## What must be true of a finger on the floor's controls: a press is a tap,
## a list scrolls under it and glides on, and on a touched window, in any
## shape, anything pressed is big enough to hit - its reach, though it is
## drawn no larger - while the mouse, the keys and the pad press as they
## always did.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_finger.gd
##
## The touches go in as a device's do, through Input.parse_input_event, so
## the engine makes its mouse from them first (touch.gd); the mouse, the keys
## and the pad go in at the window. The app is a list of forty rows, each a
## pressable of one action, over a slider, in a scroll. The look's least
## touch size is 8800 thousandths of a millimetre, and a base pixel is said
## to measure 100 of them on the glass (touch.gd: PIXEL_UM), as an easel
## says it: so a touched press reaches at least 88 base pixels each way.

const Fixture := preload("res://tests/fixture.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
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
	# a look's least touch size, and a base pixel's measure on the glass: 88 base pixels each way
	root.theme.set_constant(&"least_um", Touch.TYPE, 8800)
	root.set_meta(Touch.PIXEL_UM, 100.0)
	await process_frame
	await _verdict.states(_a_finger_that_scrolls_the_list_presses_no_row)
	await _verdict.states(_a_tap_presses_once_as_the_finger_lifts)
	await _verdict.states(_the_mouse_the_keys_and_the_pad_press_as_before)
	await _verdict.states(_let_go_moving_the_list_glides_on_the_clock_and_reduced_it_stops_dead)
	await _verdict.states(_a_list_at_its_top_lets_a_finger_drawn_down_go_by)
	await _verdict.states(_a_finger_on_a_slider_moves_no_list)
	await _verdict.states(_on_a_touched_window_a_pressable_reaches_the_look_s_least_in_any_shape)
	await _verdict.states(_a_press_taller_than_its_words_stands_them_in_its_middle)
	await _verdict.states(_a_press_gives_under_a_hand_held_on_it_and_springs_back)
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


## The window said touched, or not, through the shape's own read, as a screen that takes touch says it.
func _touched(touched: bool) -> void:
	_made.ui.shape.reads_touchscreen = func() -> bool: return touched
	_made.ui.shape.arrange()
	# the frames the window's word that it is touched takes to be said
	for frame: int in 2:
		await process_frame


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


## On a touched window, in any shape, a row of one line is drawn its face's
## own height; under the last row, where nothing else stands, a finger within
## the least round its middle presses it; and a finger on the row above
## another is that row's own, though the other's reach would carry there.
## No longer touched, a row takes the pointer only on itself.
func _on_a_touched_window_a_pressable_reaches_the_look_s_least_in_any_shape() -> void:
	await _standing(Vector2i(1920, 1080))
	var row: Pressable = _made.ui.node_named(&"row 5")
	var last: Pressable = _made.ui.node_named(&"row 39")
	var above: Pressable = _made.ui.node_named(&"row 4")
	# a point inside the row above, a pixel over its foot, in this row's own space
	var on_above := func() -> Vector2: return row.get_global_transform().affine_inverse() * Vector2(above.get_global_rect().get_center().x, above.get_global_rect().end.y - 1.0)
	var least := Pressable.least_each_way(row)
	var own := row.get_combined_minimum_size()
	# a point this far under the last row's middle, as a share of the least
	var under := func(share: float) -> Vector2: return Vector2(last.size.x / 2.0, last.size.y / 2.0 + least * share)
	_verdict.check(least == 88.0 and own.y < least and not last.reaches(under.call(0.49)), "not touched, a row of one line on a wide window is its face's own height, under the least touch size of %s, and takes the pointer only on itself: %s" % [least, own])
	await _touched(true)
	_verdict.check(row.get_combined_minimum_size() == own and row.size.y == own.y, "touched, on the same wide window on its side, it is drawn at its face's own height still: %s" % [row.get_combined_minimum_size()])
	_verdict.check(last.reaches(under.call(0.49)) and not last.reaches(under.call(0.51)), "and under the last row, where nothing else stands, a finger within the least round its middle presses it, and one beyond does not")
	_verdict.check(on_above.call().y > -(least - own.y) / 2.0 and not row.reaches(on_above.call()), "a finger on the row above is that row's own, though this one's reach would carry there: %s" % [on_above.call()])
	# every shape a touched window may have: a phone's on its end, a narrow window on its side, a tall regular one
	for window: Vector2i in [Vector2i(720, 1280), Vector2i(800, 700), Vector2i(1000, 1400)]:
		root.size = window
		# the frames the window's turn and its measuring again take
		for frame: int in 4:
			await process_frame
		_verdict.check(row.get_combined_minimum_size() == own and last.reaches(under.call(0.49)) and not row.reaches(on_above.call()), "touched, a window of %s draws it at its own height too, and it reaches as far: %s" % [window, row.get_combined_minimum_size()])
	await _touched(false)
	_verdict.check(row.get_combined_minimum_size() == own and not last.reaches(under.call(0.49)), "no longer touched, live, a row takes the pointer only on itself again")
	root.size = Vector2i(1920, 1080)
	# the frames the window's turn back takes
	for frame: int in 4:
		await process_frame
	_verdict.check(row.get_combined_minimum_size() == own, "and back on the wide window it needs what it did: %s" % [row.get_combined_minimum_size()])
	_done()


## A row of one line made three lines tall by what it is asked to be: its
## words stand in the middle of the room its box leaves, not at the top of it.
func _a_press_taller_than_its_words_stands_them_in_its_middle() -> void:
	await _standing(Vector2i(720, 1280))
	var row: Pressable = _made.ui.node_named(&"row 5")
	row.custom_minimum_size.y = row.get_combined_minimum_size().y * 3.0
	await process_frame
	await process_frame
	var label: Label = row.find_children("*", "Label", true, false)[0]
	var box := row.get_drawn_box()
	var room := Rect2(row.global_position + Vector2(box.get_margin(SIDE_LEFT), box.get_margin(SIDE_TOP)), row.size - box.get_minimum_size())
	_verdict.check(room.size.y >= 2.0 * label.get_combined_minimum_size().y, "the room inside the row is at least twice its line: %s against %s" % [room.size.y, label.get_combined_minimum_size().y])
	# words are drawn from the top of their label, a line tall, wherever its box stretches to
	var off := label.global_position.y + label.get_combined_minimum_size().y / 2.0 - room.get_center().y
	_verdict.check(absf(off) <= 1.0, "and its words stand in the middle of it, within a pixel: %s off" % off)
	_done()


## Under a look whose press scale is 940: a row pressed with the mouse is
## drawn at that scale once the restyle has run, and whole again once the
## emphasis has; a finger landing does the same, and drawn on into a scroll
## the row is whole again; with reduced motion a press gives nothing; and
## the floor's own thousand gives nothing at all.
func _a_press_gives_under_a_hand_held_on_it_and_springs_back() -> void:
	await _standing()
	var motion := _made.ui.motion
	motion.by_hand = true
	motion.still = false
	var row: Pressable = _made.ui.node_named(&"row 3")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = _on_window(_middle(&"row 3"))
	click.pressed = true
	root.push_input(click)
	await process_frame
	motion.step(1.0)
	_verdict.check(row.scale == Vector2.ONE, "under the floor's press scale of a thousand, a press gives nothing: %s" % [row.scale])
	click.pressed = false
	root.push_input(click)
	await process_frame
	root.theme.set_constant(&"press_scale", &"Motion", 940)
	# the frame the look's change reaches the rows in
	await process_frame
	click.pressed = true
	root.push_input(click)
	await process_frame
	motion.step(motion.lasts(&"restyle", row) / 2.0)
	var landing := row.scale
	motion.step(motion.lasts(&"restyle", row) / 2.0)
	_verdict.check(landing.x < 1.0 and landing.x > 0.94 and is_equal_approx(row.scale.x, 0.94) and is_equal_approx(row.scale.y, 0.94), "held down with the mouse, it gives on the clock and reaches the look's press scale: %s then %s" % [landing, row.scale])
	_verdict.check(row.pivot_offset_ratio == Vector2(0.5, 0.5) and row.get_combined_minimum_size() == _made.ui.node_named(&"row 4").get_combined_minimum_size(), "about its middle, and never laid out smaller than a row not held")
	click.pressed = false
	root.push_input(click)
	await process_frame
	motion.step(motion.lasts(&"emphasis", row))
	_verdict.check(row.scale == Vector2.ONE, "let go, it springs back whole once the emphasis has run: %s" % [row.scale])
	await _touch(_middle(&"row 5"), true)
	var five: Pressable = _made.ui.node_named(&"row 5")
	motion.step(motion.lasts(&"restyle", five))
	var touched := five.scale
	await _drawn(_middle(&"row 5"), [Vector2(0, -40), Vector2(0, -40)], false)
	motion.step(motion.lasts(&"emphasis", five))
	_verdict.check(is_equal_approx(touched.x, 0.94) and five.scale == Vector2.ONE and _scroll.scroll_vertical > 0, "a finger landing gives it too, and drawn on into a scroll, it is whole again: %s then %s" % [touched, five.scale])
	await _touch(_middle(&"row 5"), false)
	motion.told(&"reduces_motion", {"on": true})
	click.position = _on_window(_middle(&"row 3"))
	click.pressed = true
	root.push_input(click)
	await process_frame
	var reduced := row.scale
	motion.step(1.0)
	_verdict.check(reduced == Vector2.ONE and row.scale == Vector2.ONE, "with reduced motion, a press gives nothing: %s then %s" % [reduced, row.scale])
	click.pressed = false
	root.push_input(click)
	await process_frame
	root.theme.set_constant(&"press_scale", &"Motion", 1000)
	_done()
