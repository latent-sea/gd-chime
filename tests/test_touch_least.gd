extends SceneTree

## What must be true of a finger's target (pressable.gd): on a touched
## window, in any shape and either way round, a press is at least the look's
## Touch/least_um each way, made base pixels by how big a base pixel is on
## the glass - the easel's word on its viewport, or, with none, the window's
## own pixel at the screen's dots to the inch; on a window not touched it is
## its face's own size; a press holding nothing is never a target; and a
## window coming to be touched, or not, measures every target again.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_touch_least.gd
##
## Each statement is in the floor's look with a least touch size of 7600
## thousandths of a millimetre - 48 dp - on the window itself, which is
## told it is touched through the shape's own read (shape.gd); a model
## answers both presses. A base pixel of 120 thousandths of a millimetre is
## the A55's, 2.126 of its pixels at 450 to the inch: 7600 of them is 63.3.

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
	await _verdict.states(_on_a_touched_window_a_press_is_at_least_the_touch_least_in_any_shape)
	await _verdict.states(_with_no_easel_s_word_the_window_s_own_pixel_at_the_screen_s_dpi_is_measured)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## Two presses side by side, one holding a short word and one holding nothing, answered by a model.
func _presses() -> Array:
	var made := Fixture.new(root, {&"presses": "press", &"shades": "shade"})
	var model := Fixture.Model.new(made.chimes)
	model.answering.append_array([&"presses", &"shades"])
	made.commands.register(Chimes.GLOBAL, &"presses", model)
	made.commands.register(Chimes.GLOBAL, &"shades", model)
	made.ui.start(made.ui.app(&"app", [made.ui.row([made.ui.pressable(&"presses", {}, [made.ui.text("go", Themes.FACE)]).named(&"press"), made.ui.pressable(&"shades").named(&"shade"), made.ui.text("").grow()])]))
	return [made, model]


## The window said touched, or not, through the shape's own read, as a screen that takes touch says it.
func _touched(made: Fixture, touched: bool) -> void:
	made.ui.shape.reads_touchscreen = func() -> bool: return touched
	made.ui.shape.arrange()
	await _a_frame_passes()


func _on_a_touched_window_a_press_is_at_least_the_touch_least_in_any_shape() -> void:
	root.set_meta(Touch.PIXEL_UM, A55_PIXEL_UM)
	var pair := _presses()
	var made: Fixture = pair[0]
	root.size = Vector2i(1600, 900)
	await _a_frame_passes()
	var press: Pressable = made.ui.node_named(&"press")
	var shade: Pressable = made.ui.node_named(&"shade")
	var own := press.get_combined_minimum_size()
	var least := LEAST_UM / A55_PIXEL_UM
	_verdict.check(own.x < least and own.y < least, "not touched, a press holding a short word is its face's own size, under the touch least each way: %s against %s" % [own, least])
	await _touched(made, true)
	var sideways := press.get_combined_minimum_size()
	_verdict.check(is_equal_approx(sideways.x, least) and is_equal_approx(sideways.y, least) and press.size.x >= least - 0.01 and press.size.y >= least - 0.01, "touched, on a wide window on its side, it is the touch least each way, 7600 thousandths of a millimetre on the glass: %s, laid at %s" % [sideways, press.size])
	_verdict.check(shade.get_combined_minimum_size().x < least, "a press holding nothing is ground, never a target: %s" % shade.get_combined_minimum_size())
	root.size = Vector2i(720, 1280)
	await _a_frame_passes()
	await _touched(made, true)
	_verdict.check(is_equal_approx(press.get_combined_minimum_size().x, least) and is_equal_approx(press.get_combined_minimum_size().y, least), "and on a window on its end, the same: %s" % press.get_combined_minimum_size())
	root.set_meta(Touch.PIXEL_UM, 2.0 * A55_PIXEL_UM)
	root.get_tree().call_group(Touch.TARGETS, &"update_minimum_size")
	await _a_frame_passes()
	_verdict.check(is_equal_approx(press.get_combined_minimum_size().x, maxf(own.x, least / 2.0)), "a base pixel drawn twice as big on the glass, measured again, needs half as many of them: %s" % press.get_combined_minimum_size())
	await _touched(made, false)
	_verdict.check(press.get_combined_minimum_size() == own, "and the window no longer touched, every target is measured again at its face's own size: %s" % press.get_combined_minimum_size())
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
	_verdict.check(not root.has_meta(Touch.PIXEL_UM) and is_equal_approx(Pressable.least_each_way(press), LEAST_UM / pixel_um), "on a window with no easel's word, a base pixel is the window's own, at the screen's %d dots to the inch: the least is %s" % [DisplayServer.screen_get_dpi(), Pressable.least_each_way(press)])
	_verdict.check(press.get_combined_minimum_size().y >= LEAST_UM / pixel_um - 0.01, "and the press is at least that each way: %s" % press.get_combined_minimum_size())
	await _touched(made, false)
	(pair[1] as Node).free()
	made.done()
