extends SceneTree

## What must be true of the safe room: how far in from each edge of an app's
## rect only the ground is drawn, the scale that keeps the room at least the
## floor, and the canvas laying the app and its pop-ups in what is left.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_safe_area.gd
##
## The sums are safe_area.gd's, asserted with numbers worked out by hand: the
## A55 held both ways, a notch with a home bar, a desk, an app in a side
## panel, the keyboard at the foot, and the floor's cap on the scale. Then an
## easel over the window, every read it makes of its screen handed in, as a
## phone would answer them: the app laid in the safe rect while the ground
## covers the whole canvas, the cutout followed round as the phone turns, the
## keyboard read only while a field holds the focus and laid under the foot,
## a piece that needs more than the room said out loud, once, a desk's
## window standing away from the screen's corner inset by the gutter alone,
## and a panel sliding in laid again on its way without being snapped to rest.
##
## THE A55: 2340 by 1080 pixels at 450 dots to the inch, an 89 pixel cutout
## on one short edge's side, corners of 128 pixels' radius; at a least base
## pixel of 120 thousandths of a millimetre a base pixel is 2.126 pixels.

const Fixture := preload("res://tests/fixture.gd")
const Verdict := preload("res://tests/verdict.gd")
const SafeArea := preload("res://addons/gd_chime/safe_area.gd")
const Easel := preload("res://addons/gd_chime/easel.gd")
const Shape := preload("res://addons/gd_chime/shape.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")

## The A55's numbers: its screen, its cutout, its dots to the inch, its corners' radius in thousandths of a millimetre, and its base pixel.
const A55 := Vector2(2340, 1080)
const CUTOUT := 89.0
const DPI := 450.0
const CORNER_UM := 128.0 * 25400.0 / 450.0
const LEAST := 120.0 / 25400.0 * 450.0
## The gutter the cabinet's look names, in base pixels.
const GUTTER := 12.0

var _verdict := Verdict.new()
var _hearing := Hearing.new()
var _easel: Easel
var _made: Fixture
var _keyboard_asked: int = 0  # how many times the easel asked for the keyboard's height
var _keyboard_px: int = 0  # the keyboard's height the easel is answered


## Every error said while it listens, by its words.
class Hearing extends Logger:
	var said: Array[String] = []

	func _log_error(_function: String, _file: String, _line: int, code: String, _rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type != ERROR_TYPE_WARNING:
			said.append(code)


func _init() -> void:
	OS.add_logger(_hearing)
	await process_frame
	await _verdict.states(_the_a55_is_inset_54_on_the_cutout_edge_and_30_on_the_others_both_ways)
	await _verdict.states(_a_notch_and_a_home_bar_cover_their_own_edges)
	await _verdict.states(_a_desk_is_covered_by_nothing_and_inset_by_the_gutter_alone)
	await _verdict.states(_an_app_in_a_panel_away_from_the_cutout_loses_nothing_to_it)
	await _verdict.states(_the_keyboard_covers_the_foot_alone_and_the_largest_cover_wins)
	await _verdict.states(_the_scale_is_capped_so_the_safe_short_side_is_never_under_the_floor)
	await _verdict.states(_the_canvas_lays_the_app_in_the_safe_rect_and_paints_the_ground_across_all_of_it)
	await _verdict.states(_turned_the_cutout_goes_to_its_new_edge)
	await _verdict.states(_a_window_too_small_for_the_floor_gives_a_safe_short_side_of_exactly_the_floor)
	await _verdict.states(_the_keyboard_is_read_only_while_a_field_holds_the_focus_and_insets_the_foot)
	await _verdict.states(_a_piece_needing_more_than_the_safe_room_is_said_once_by_name)
	await _verdict.states(_a_desk_window_away_from_the_screen_s_corner_is_inset_by_the_gutter_alone)
	await _verdict.states(_a_panel_laid_again_on_its_way_in_keeps_the_way_it_has_come)
	OS.remove_logger(_hearing)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## The insets at the A55's base pixel and the cabinet's gutter, for a rect on this window with this unobscured area.
func _insets(window: Rect2, rect: Rect2, unobscured: Rect2, keyboard_px: float = 0.0) -> PackedFloat32Array:
	return SafeArea.insets(SafeArea.covered(window, rect, unobscured, keyboard_px, CORNER_UM, DPI), LEAST, GUTTER)


## 89 pixels are 41.9 base pixels, and 12 of gutter make 54; a corner of 128
## pixels is cleared at 37.5 pixels in, 17.6 base pixels, and 12 make 30.
func _the_a55_is_inset_54_on_the_cutout_edge_and_30_on_the_others_both_ways() -> void:
	var sideways := Rect2(Vector2.ZERO, A55)
	var across := _insets(sideways, sideways, Rect2(CUTOUT, 0, A55.x - CUTOUT, A55.y))
	_verdict.check(across == PackedFloat32Array([54, 30, 30, 30]), "held sideways, the cutout on the left: 54 on the left and 30 on the other three: %s" % [across])
	var upright := Rect2(0, 0, A55.y, A55.x)
	var down := _insets(upright, upright, Rect2(0, CUTOUT, A55.y, A55.x - CUTOUT))
	_verdict.check(down == PackedFloat32Array([30, 54, 30, 30]), "held upright, the cutout at the top: 54 at the top and 30 on the other three: %s" % [down])
	var token := SafeArea.insets(SafeArea.covered(sideways, sideways, Rect2(CUTOUT, 0, A55.x - CUTOUT, A55.y), 0.0, 7500.0, DPI), LEAST, GUTTER)
	_verdict.check(token == PackedFloat32Array([54, 30, 30, 30]), "and the cabinet's corner of 7500 thousandths of a millimetre, about 133 pixels, clears the same: %s" % [token])


## At two pixels to a base pixel and a gutter of 10: a notch of 100 pixels
## is 50 and a home bar of 60 is 30, each with the gutter on top.
func _a_notch_and_a_home_bar_cover_their_own_edges() -> void:
	var screen := Rect2(0, 0, 1000, 2000)
	var inset := SafeArea.insets(SafeArea.covered(screen, screen, Rect2(0, 100, 1000, 1840), 0.0, 0.0, 400.0), 2.0, 10.0)
	_verdict.check(inset == PackedFloat32Array([10, 60, 10, 40]), "the notch covers the top and the home bar the foot, and the sides only the gutter: %s" % [inset])


func _a_desk_is_covered_by_nothing_and_inset_by_the_gutter_alone() -> void:
	var window := Rect2(300, 200, 1600, 900)
	var covered := SafeArea.covered(window, window, Rect2(), 0.0, 0.0, 96.0)
	_verdict.check(covered == PackedFloat32Array([0, 0, 0, 0]), "where the platform names no unobscured area and there are no corners, nothing is covered: %s" % [covered])
	_verdict.check(SafeArea.insets(covered, 1.0, GUTTER) == PackedFloat32Array([12, 12, 12, 12]) and SafeArea.insets(covered, 1.0, 0.0) == PackedFloat32Array([0, 0, 0, 0]), "so the insets are the gutter, or nothing without one")


## The A55 sideways with no corners: an app across its right half, away
## from the cutout on the left, and one across its left half, against it.
func _an_app_in_a_panel_away_from_the_cutout_loses_nothing_to_it() -> void:
	var screen := Rect2(Vector2.ZERO, A55)
	var unobscured := Rect2(CUTOUT, 0, A55.x - CUTOUT, A55.y)
	var away := SafeArea.covered(screen, Rect2(A55.x / 2.0, 0, A55.x / 2.0, A55.y), unobscured, 0.0, 0.0, DPI)
	var against := SafeArea.covered(screen, Rect2(0, 0, A55.x / 2.0, A55.y), unobscured, 0.0, 0.0, DPI)
	_verdict.check(away == PackedFloat32Array([0, 0, 0, 0]), "the right half loses nothing to a cutout on the left: %s" % [away])
	_verdict.check(against == PackedFloat32Array([CUTOUT, 0, 0, 0]), "the left half loses the cutout's 89 pixels on its left, and nothing on its right, the middle of the screen: %s" % [against])


## Upright, a keyboard of 900 pixels is 423 base pixels, 435 with the
## gutter; one of 20 is less than the corner's 37.5 and so changes nothing.
func _the_keyboard_covers_the_foot_alone_and_the_largest_cover_wins() -> void:
	var upright := Rect2(0, 0, A55.y, A55.x)
	var typing := _insets(upright, upright, Rect2(), 900.0)
	_verdict.check(typing == PackedFloat32Array([30, 30, 30, 435]), "a keyboard up covers the foot, and only the foot: %s" % [typing])
	var low := _insets(upright, upright, Rect2(), 20.0)
	_verdict.check(low == PackedFloat32Array([30, 30, 30, 30]), "a keyboard lower than the corner's clearance adds nothing: the largest cover wins, never the sum: %s" % [low])
	var above := SafeArea.covered(upright, Rect2(0, 0, A55.y, A55.x / 2.0), Rect2(), 900.0, 0.0, DPI)
	_verdict.check(above[SIDE_BOTTOM] == 0.0, "and an app on the top half, above where the keyboard reaches, loses nothing to it: %s" % [above])


## A window of 800 by 600 at the A55's least pixel would be a canvas 282
## base pixels tall; capped, it is drawn at 600 / (360 + 2 x 12) = 1.5625.
func _the_scale_is_capped_so_the_safe_short_side_is_never_under_the_floor() -> void:
	var none := PackedFloat32Array([0, 0, 0, 0])
	var small := SafeArea.drawn_at(Vector2(800, 600), none, Vector2(1920, 1080), LEAST, 360.0, GUTTER)
	_verdict.check(is_equal_approx(small, 1.5625) and is_equal_approx(600.0 / small - 2.0 * GUTTER, 360.0), "a small window is drawn smaller than the least pixel, so its safe short side is exactly the floor: %s" % small)
	var sideways := SafeArea.covered(Rect2(Vector2.ZERO, A55), Rect2(Vector2.ZERO, A55), Rect2(CUTOUT, 0, A55.x - CUTOUT, A55.y), 0.0, CORNER_UM, DPI)
	var roomy := SafeArea.drawn_at(A55, sideways, Vector2(1920, 1080), LEAST, 360.0, GUTTER)
	_verdict.check(is_equal_approx(roomy, LEAST), "the A55, with room to spare over the floor, is drawn at the least pixel: %s" % roomy)
	var fitted := SafeArea.drawn_at(Vector2(1920, 1080), none, Vector2(1280, 720), 0.0, 360.0, GUTTER)
	_verdict.check(is_equal_approx(fitted, 1.5), "and a desk's screen with no least is only fitted: %s" % fitted)


## The look of the cabinet's numbers: the least pixel and the gutter.
func _look() -> Theme:
	var made := Themes.new(Themes.NEUTRAL)
	made.set_constant(&"least_pixel_um", Shape.TYPE, 120)
	made.set_constant(&"edge", Shape.TYPE, int(GUTTER))
	return made


## An easel across a window of this size, every read of its screen answered
## as the A55 would - the cutout down the left, or at the top on its end -
## and an app on it holding what this makes of the fixture.
func _standing(wide: int, tall: int, content: Callable = func(_made: Fixture) -> Array: return [], declared: Dictionary = {}) -> void:
	_easel = Easel.new()
	_easel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_easel.canvas.theme = _look()
	_easel.reads_dpi = func() -> int: return int(DPI)
	_easel.reads_corner_um = func() -> int: return int(CORNER_UM)
	_easel.reads_safe_area = _cutout
	_easel.reads_keyboard = func() -> int:
		_keyboard_asked += 1
		return _keyboard_px
	root.add_child(_easel)
	root.size = Vector2i(wide, tall)
	await _a_frame_passes()
	_made = Fixture.new(_easel.canvas, declared)
	_made.ui.start(_made.ui.app(&"app", content.call(_made)))
	await _a_frame_passes()


## The A55's unobscured area on the window as it stands: the cutout down its left held sideways, at its top upright.
func _cutout() -> Rect2i:
	var cut := Vector2i(0, int(CUTOUT)) if root.size.y > root.size.x else Vector2i(int(CUTOUT), 0)
	return Rect2i(root.position + cut, root.size - cut)


func _done() -> void:
	_made.done()
	_easel.free()


## The app as it stands on the canvas.
func _app() -> Control:
	return _made.driver.index.app


## Every visible control of the app reaching outside the safe rect, by its path.
func _outside_the_safe_rect() -> Array:
	var safe: Rect2 = _easel.canvas.get_safe().grow(0.5)
	var built: Array = [_app()] + _app().find_children("*", "Control", true, false)
	return built.filter(func(piece: Control) -> bool: return piece.is_visible_in_tree() and not safe.encloses(piece.get_global_rect())).map(func(piece: Control) -> NodePath: return piece.get_path())


func _the_canvas_lays_the_app_in_the_safe_rect_and_paints_the_ground_across_all_of_it() -> void:
	var asked: Array = []
	await _standing(int(A55.x), int(A55.y), func(made: Fixture) -> Array:
		asked.append(made.ui.pop_up(&"asked", func(_which: Bound) -> Desc: return made.ui.column([made.ui.text("a question asked over the app")])))
		return [made.ui.column([made.ui.text("words standing in the app").grow(), made.ui.pressable(&"asks", {}, [made.ui.text("ask")]).opens(asked[0]).named(&"asks")])], {&"asks": "ask"})
	var canvas := _easel.canvas
	var safe := canvas.get_safe()
	_verdict.check(safe.position == Vector2(54, 30) and safe.end == canvas.size - Vector2(30, 30), "the safe rect is 54 in from the cutout's edge and 30 from the others: %s of %s" % [safe, canvas.size])
	_verdict.check(_app().get_global_rect() == safe, "the app is laid exactly in it: %s" % [_app().get_global_rect()])
	_verdict.check(_outside_the_safe_rect().is_empty(), "and nothing it built is drawn in the band round it: %s" % [_outside_the_safe_rect()])
	_verdict.check(canvas.size == _easel.viewport.get_visible_rect().size and canvas.get_drawn().size() == 1, "while the ground is painted across the whole canvas, the band included: %s" % [canvas.size])
	_verdict.check(_made.ui.shape.safe_size.read() == safe.size and _made.ui.shape.insets.read() == PackedFloat32Array([54, 30, 30, 30]), "and the shape says the same room: %s %s" % [_made.ui.shape.safe_size.read(), _made.ui.shape.insets.read()])
	(_made.ui.node_named(&"asks") as Pressable).pressed()
	await _a_frame_passes()
	var lifted: Control = _made.driver.index.place_named((asked[0] as Desc).get_place())
	_verdict.check(_made.driver.is_raised() and lifted.get_parent() == canvas and lifted.is_visible_in_tree() and lifted.get_global_rect() == safe, "a pop-up lifted beside the app is laid in the same safe rect: %s" % [lifted.get_global_rect()])
	_done()


func _turned_the_cutout_goes_to_its_new_edge() -> void:
	await _standing(int(A55.x), int(A55.y))
	root.size = Vector2i(int(A55.y), int(A55.x))
	await _a_frame_passes()
	var safe := _easel.canvas.get_safe()
	_verdict.check(safe.position == Vector2(30, 54) and safe.end == _easel.canvas.size - Vector2(30, 30), "turned on its end, the cutout at the top: 54 in at the top and 30 from the others: %s of %s" % [safe, _easel.canvas.size])
	_verdict.check(_app().get_global_rect() == safe, "and the app is laid in the turned safe rect: %s" % [_app().get_global_rect()])
	_done()


## 800 by 600 at the A55's least pixel would leave 282 base pixels of height.
## A desk's window: nothing covers it, and the gutter alone insets it.
func _a_window_too_small_for_the_floor_gives_a_safe_short_side_of_exactly_the_floor() -> void:
	await _standing(800, 600)
	_easel.reads_safe_area = func() -> Rect2i: return Rect2i()
	_easel.reads_corner_um = func() -> int: return 0
	root.size = Vector2i(801, 600)
	await _a_frame_passes()
	var safe := _easel.canvas.get_safe()
	_verdict.check(safe.size.y == 360.0 and safe.size.x > 360.0, "the safe room's short side is exactly the floor of 360 base pixels: %s" % [safe.size])
	_done()


## Sideways, a keyboard of 600 pixels: 282 base pixels, 294 with the gutter.
## It leaves under the floor's height, and the app is drawn at the same size.
func _the_keyboard_is_read_only_while_a_field_holds_the_focus_and_insets_the_foot() -> void:
	_keyboard_px = 600
	var model: Array = []
	await _standing(int(A55.x), int(A55.y), func(made: Fixture) -> Array:
		model.append(Fixture.Model.new(made.chimes, &"app"))
		made.commands.register(&"app", &"types", model[0])
		made.commands.register(&"app", &"presses", model[0])
		return [made.ui.column([made.ui.field(&"types").named(&"line"), made.ui.pressable(&"presses", {}, [made.ui.text("press")]).named(&"button")])], {&"types": "type", &"presses": "press"})
	var button: Control = _made.ui.node_named(&"button")
	var line: LineEdit = _made.ui.node_named(&"line").find_children("*", "LineEdit", true, false)[0]
	button.grab_focus()
	await _a_frame_passes()
	var drawn := _easel.viewport.size_2d_override
	_keyboard_asked = 0
	await _a_frame_passes()
	_verdict.check(_keyboard_asked == 0 and _easel.canvas.get_safe().end.y == _easel.canvas.size.y - 30.0, "with a press holding the focus the keyboard is not asked for, and the foot is inset 30: %d %s" % [_keyboard_asked, _easel.canvas.get_safe()])
	line.grab_focus()
	await _a_frame_passes()
	_verdict.check(_keyboard_asked > 0 and _easel.canvas.get_safe().end.y == _easel.canvas.size.y - 294.0, "a field taking the focus has the keyboard read, and the foot inset 294, above it: %d %s" % [_keyboard_asked, _easel.canvas.get_safe()])
	_verdict.check(_app().get_global_rect() == _easel.canvas.get_safe() and _easel.viewport.size_2d_override == drawn, "the app is laid above it, drawn at the same size as before: %s %s %s" % [_app().get_global_rect(), _easel.viewport.size_2d_override, drawn])
	button.grab_focus()
	await _a_frame_passes()
	var asked := _keyboard_asked
	await _a_frame_passes()
	_verdict.check(_easel.canvas.get_safe().end.y == _easel.canvas.size.y - 30.0 and _keyboard_asked == asked, "the field let go, the foot is inset 30 again and the keyboard is asked for no more: %s %d then %d" % [_easel.canvas.get_safe(), asked, _keyboard_asked])
	_verdict.check(not _easel.is_physics_processing(), "and the easel runs nothing each frame any more")
	(model[0] as Node).free()
	_done()


## A piece 5000 base pixels wide, in an app on the A55's canvas of 1101.
func _a_piece_needing_more_than_the_safe_room_is_said_once_by_name() -> void:
	var said := _hearing.said.size()
	await _standing(int(A55.x), int(A55.y), func(made: Fixture) -> Array:
		var wide := Control.new()
		wide.custom_minimum_size = Vector2(5000, 10)
		return [made.ui.embed(wide)])
	var about_the_app := func(sentence: String) -> bool: return sentence.contains(str(_app().get_path())) and sentence.contains("more than the safe room")
	_verdict.check(_hearing.said.slice(said).filter(about_the_app).size() == 1, "the app, grown past the safe rect by what it holds, is said by name: %s" % [_hearing.said.slice(said)])
	root.size = Vector2i(int(A55.x), int(A55.y) + 1)
	await _a_frame_passes()
	_verdict.check(_hearing.said.slice(said).filter(about_the_app).size() == 1 and _hearing.said.size() == said + 1, "and laid again, it is not said again, nor is anything else: %s" % [_hearing.said.slice(said)])
	_done()


## A desk's window of 1600 by 900 at 96 dots to the inch, standing 300 across
## and 200 down the screen: nothing covers it, so its canvas, fitted at 0.83,
## is inset by the gutter of 12 alone - never by where the window stands.
func _a_desk_window_away_from_the_screen_s_corner_is_inset_by_the_gutter_alone() -> void:
	await _standing(1600, 900)
	_easel.reads_dpi = func() -> int: return 96
	_easel.reads_safe_area = func() -> Rect2i: return Rect2i()
	_easel.reads_corner_um = func() -> int: return 0
	root.position = Vector2i(300, 200)
	root.size = Vector2i(1601, 900)
	await _a_frame_passes()
	var safe := _easel.canvas.get_safe()
	var room := Rect2(Vector2(GUTTER, GUTTER), _easel.canvas.size - Vector2(2.0 * GUTTER, 2.0 * GUTTER))
	_verdict.check(root.position == Vector2i(300, 200) and safe == room, "the window away from the screen's corner, the safe rect is the canvas less the gutter on every side: %s of %s" % [safe, _easel.canvas.size])
	_verdict.check(_app().get_global_rect() == room, "and the app is laid across all of it: %s" % [_app().get_global_rect()])
	root.position = Vector2i.ZERO
	_done()


## The A55 sideways, the clock by hand: a panel beside the app slides in from
## its side, and a third of the way in the canvas lays everything again, as a
## resize or a piece's needs moving would.
func _a_panel_laid_again_on_its_way_in_keeps_the_way_it_has_come() -> void:
	var panel: Array = []
	await _standing(int(A55.x), int(A55.y), func(made: Fixture) -> Array:
		panel.append(made.ui.pop_up(&"panel", func(_which: Bound) -> Desc: return made.ui.text("a panel beside the app")).blocks_nothing())
		return [made.ui.column([made.ui.pressable(&"opens", {}, [made.ui.text("open")]).opens(panel[0]).named(&"opens")])], {&"opens": "open"})
	_made.ui.motion.by_hand = true
	_made.ui.motion.still = false
	(_made.ui.node_named(&"opens") as Pressable).pressed()
	await _a_frame_passes()
	_made.ui.motion.step(0.06)
	await _a_frame_passes()
	var lifted: Control = _made.driver.index.place_named((panel[0] as Desc).get_place())
	var safe := _easel.canvas.get_safe()
	var on_its_way := lifted.position
	_easel.canvas.queue_sort()
	await _a_frame_passes()
	_verdict.check(on_its_way.x > safe.position.x and lifted.position == on_its_way, "laid again on its way in, it stands where it had come to, never snapped to rest: %s then %s, at rest %s" % [on_its_way, lifted.position, safe.position])
	_made.ui.motion.step(0.5)
	await _a_frame_passes()
	_verdict.check(lifted.get_global_rect() == safe, "and it comes to rest in the safe rect: %s" % [lifted.get_global_rect()])
	_done()
