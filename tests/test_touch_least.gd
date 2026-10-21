extends SceneTree

## What must be true of a finger's target (pressable.gd): on a touched
## window, in any shape and either way round, a press is drawn at its face's
## own size and a finger anywhere within the look's Touch/least_um each way
## round its middle presses it - made base pixels by how big a base pixel is
## on the glass, the easel's word on its viewport, or, with none, the
## window's own pixel at the screen's dots to the inch - but never where
## another press stands; on a window not touched it takes the pointer only
## on itself; a press holding nothing reaches no further than it is drawn;
## the reach follows the window coming to be touched, or not, and how big a
## base pixel is, as each changes; and the engine, asked where a finger
## lands, finds the press wherever it reaches.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_touch_least.gd
##
## Each statement is in the floor's look with a least touch size of 7600
## thousandths of a millimetre - 48 dp - on the window itself, which is
## told it is touched through the shape's own read (shape.gd); a model
## answers the presses. A base pixel of 120 thousandths of a millimetre is
## the A55's, 2.126 of its pixels at 450 to the inch: 7600 of them is 63.3.
## The presses stand down a column, each at its own height: one holding a
## short word, one holding nothing, and a line of two holding a letter each,
## side by side.

const Fixture := preload("res://tests/fixture.gd")
const Verdict := preload("res://tests/verdict.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Touch := preload("res://addons/gd_chime/touch.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")

## The look's least touch size, in thousandths of a millimetre on the glass.
const LEAST_UM := 7600
## A base pixel on the A55, in thousandths of a millimetre: 25,400 to the inch over 450 to the inch, times 2.126 pixels to a base pixel.
const A55_PIXEL_UM := 120.0

var _verdict := Verdict.new()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	root.theme.set_constant(&"least_um", Touch.TYPE, LEAST_UM)
	await process_frame
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_on_a_touched_window_a_press_is_drawn_its_own_size_and_reaches_the_touch_least)
	await _verdict.states(_a_press_never_reaches_over_another)
	await _verdict.states(_with_no_easel_s_word_the_window_s_own_pixel_at_the_screen_s_dpi_is_measured)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## The presses down a column, each at its own height, answered by a model.
func _presses() -> Array:
	var made := Fixture.new(root, {&"presses": "press", &"shades": "shade"})
	var model := Fixture.Model.new(made.chimes)
	model.answering.append_array([&"presses", &"shades"])
	made.commands.register(Chimes.GLOBAL, &"presses", model)
	made.commands.register(Chimes.GLOBAL, &"shades", model)
	var word := func(named: StringName, said: String) -> RefCounted: return made.ui.pressable(&"presses", {}, [made.ui.text(said, Themes.FACE)]).named(named)
	var ui: RefCounted = made.ui
	ui.start(ui.app(&"app", [ui.column([ui.row([word.call(&"press", "go")]), ui.row([ui.pressable(&"shades").named(&"shade")]), ui.row([word.call(&"left", "a"), word.call(&"right", "b")]), ui.row([]).grow()])]))
	return [made, model]


## The window said touched, or not, through the shape's own read, as a screen that takes touch says it.
func _touched(made: Fixture, touched: bool) -> void:
	made.ui.shape.reads_touchscreen = func() -> bool: return touched
	made.ui.shape.arrange()
	await _a_frame_passes()


## Whether a finger these many base pixels above and below the press's middle presses it.
func _reaches(press: Pressable, from_middle: float) -> bool:
	return press.reaches(press.size / 2.0 + Vector2(0.0, from_middle)) and press.reaches(press.size / 2.0 - Vector2(0.0, from_middle))


func _on_a_touched_window_a_press_is_drawn_its_own_size_and_reaches_the_touch_least() -> void:
	root.set_meta(Touch.PIXEL_UM, A55_PIXEL_UM)
	var pair := _presses()
	var made: Fixture = pair[0]
	root.size = Vector2i(1600, 900)
	await _a_frame_passes()
	var press: Pressable = made.ui.node_named(&"press")
	var shade: Pressable = made.ui.node_named(&"shade")
	var own := press.get_combined_minimum_size()
	var least := LEAST_UM / A55_PIXEL_UM
	_verdict.check(own.y < least and press.size.y == own.y and not _reaches(press, least * 0.49), "not touched, a press holding a short word is its face's own height, under the touch least, and takes the pointer only on itself: %s against %s" % [own, least])
	await _touched(made, true)
	_verdict.check(press.get_combined_minimum_size() == own and press.size.y == own.y, "touched, on a wide window on its side, it is drawn at its face's own size still: %s, laid at %s" % [press.get_combined_minimum_size(), press.size])
	_verdict.check(_reaches(press, least * 0.49) and not _reaches(press, least * 0.51), "and a finger within the touch least round its middle, 7600 thousandths of a millimetre on the glass, presses it, and one beyond it does not")
	_verdict.check(not _reaches(shade, 1.0 + shade.size.y), "a press holding nothing is ground, never a target, and reaches no further than it is drawn")
	# the pointer pressed and let go under the press, outside it, half the least under its middle less a hair, as the engine takes it
	var under := press.get_global_rect().get_center() + Vector2(0.0, least * 0.49)
	var told_before: int = (pair[1] as Fixture.Model).told_actions.size()
	for down: bool in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = down
		click.position = under
		click.global_position = under
		root.push_input(click)
		await _a_frame_passes()
	_verdict.check(not press.get_global_rect().has_point(under) and (pair[1] as Fixture.Model).told_actions.slice(told_before) == [&"presses"], "and the pointer pressed and let go under it, outside what it draws, presses it, as the engine finds where it lands")
	root.size = Vector2i(720, 1280)
	await _a_frame_passes()
	await _touched(made, true)
	_verdict.check(press.get_combined_minimum_size() == own and _reaches(press, least * 0.49) and not _reaches(press, least * 0.51), "and on a window on its end, the same: drawn at %s, reaching the least" % press.get_combined_minimum_size())
	root.set_meta(Touch.PIXEL_UM, 2.0 * A55_PIXEL_UM)
	_verdict.check(_reaches(press, maxf(least / 2.0, own.y) * 0.49) and not _reaches(press, maxf(least / 2.0, own.y) * 0.51), "a base pixel drawn twice as big on the glass, its reach is half as many of them, read as the finger lands")
	await _touched(made, false)
	_verdict.check(press.get_combined_minimum_size() == own and not _reaches(press, own.y * 0.6), "and the window no longer touched, it takes the pointer only on itself again")
	root.remove_meta(Touch.PIXEL_UM)
	(pair[1] as Node).free()
	made.done()


## Two presses side by side, so near that each one's reach would carry onto the other: a finger on either is that
## one's alone, and beside the left one, where nothing else stands, the left one's reach takes it.
func _a_press_never_reaches_over_another() -> void:
	root.set_meta(Touch.PIXEL_UM, A55_PIXEL_UM)
	var pair := _presses()
	var made: Fixture = pair[0]
	root.size = Vector2i(1600, 900)
	await _touched(made, true)
	var left: Pressable = made.ui.node_named(&"left")
	var right: Pressable = made.ui.node_named(&"right")
	var least := LEAST_UM / A55_PIXEL_UM
	# a point inside the left press, two base pixels in from its right edge, in the right one's own space
	var on_left := right.get_global_transform().affine_inverse() * Vector2(left.get_global_rect().end.x - 2.0, left.get_global_rect().get_center().y)
	# how far past its left edge the right press would reach, were nothing there
	var right_reach := (least - right.size.x) / 2.0
	_verdict.check(on_left.x < 0.0 and on_left.x > -right_reach, "the two stand so near that the right one's reach would carry onto the left one: %s and %s, reaching %s" % [left.get_global_rect(), right.get_global_rect(), right_reach])
	_verdict.check(not right.reaches(on_left) and left.reaches(left.get_global_transform().affine_inverse() * (right.get_global_transform() * on_left)), "a finger on the left press is the left one's, and never the right one's")
	_verdict.check(left.reaches(left.size / 2.0 - Vector2(least * 0.45, 0.0)) and not left.reaches(left.size / 2.0 - Vector2(least * 0.55, 0.0)), "beside the left press, where nothing else stands, its reach takes the finger, as far as the touch least round its middle")
	root.remove_meta(Touch.PIXEL_UM)
	(pair[1] as Node).free()
	made.done()


func _with_no_easel_s_word_the_window_s_own_pixel_at_the_screen_s_dpi_is_measured() -> void:
	var pair := _presses()
	var made: Fixture = pair[0]
	root.size = Vector2i(1600, 900)
	await _touched(made, true)
	var press: Pressable = made.ui.node_named(&"press")
	var pixel_um := root.get_final_transform().get_scale().x * 25400.0 / DisplayServer.screen_get_dpi()
	var least := LEAST_UM / pixel_um
	_verdict.check(not root.has_meta(Touch.PIXEL_UM) and is_equal_approx(Pressable.least_each_way(press), least), "on a window with no easel's word, a base pixel is the window's own, at the screen's %d dots to the inch: the least is %s" % [DisplayServer.screen_get_dpi(), Pressable.least_each_way(press)])
	_verdict.check(_reaches(press, maxf(least, press.size.y) * 0.49), "and a finger within that round the press's middle presses it")
	await _touched(made, false)
	(pair[1] as Node).free()
	made.done()
