extends SceneTree

## What must be true of the window's shape, and of laying out by it.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_shape.gd
##
## A HEADLESS WINDOW IS A REAL WINDOW for everything asserted here and for
## nothing else. root.size is the window's pixels, an easel spread over the
## root is resized by it, its viewport's size_2d_override is the base the
## canvas is drawn at, and the viewport's get_final_transform() is what the
## stretch works out to - all measured, all the same numbers a window on a
## screen gets. What it
## cannot do is show any of it: nothing is drawn, no window manager sends
## NOTIFICATION_WM_SIZE_CHANGED, and no pointer is routed by position. So
## whether the words are LEGIBLE at a size is not asserted here; that they
## keep the same share of the window's short side either way round is.

const Fixture := preload("res://tests/fixture.gd")
const Verdict := preload("res://tests/verdict.gd")
const Shape := preload("res://addons/gd_chime/shape.gd")
const ByShape := preload("res://addons/gd_chime/components/primitives/by_shape.gd")
const ByWidth := preload("res://addons/gd_chime/components/primitives/by_width.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Motion := preload("res://addons/gd_chime/motion.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Transition := preload("res://addons/gd_chime/components/primitives/transition.gd")
const Easel := preload("res://addons/gd_chime/easel.gd")

var _verdict := Verdict.new()
var _made: Fixture
var _easel: Easel  # the app's own viewport, across the whole window, which the shape reads
var _shape: Shape
var _heard: Fixture.Heard  # counts the shape's values moving, so ringing once per change is read rather than argued


func _init() -> void:
	await process_frame
	await _verdict.states(_the_shape_follows_the_window_and_rings_once_per_change_not_per_pixel)
	await _verdict.states(_a_class_holds_its_ground_until_the_width_is_well_past_the_edge)
	await _verdict.states(_the_real_size_is_read_in_millimetres_on_the_screen_not_in_pixels)
	await _verdict.states(_by_shape_arranges_by_orientation_and_by_size_class)
	await _verdict.states(_by_shape_arranges_by_the_real_size)
	await _verdict.states(_an_arrangement_gives_each_part_the_facts_named_for_it_and_none_to_the_rest)
	await _verdict.states(_turned_the_parts_are_the_same_parts_with_their_words_and_the_focus)
	await _verdict.states(_a_place_under_it_is_one_place_that_keeps_its_name_and_its_stay)
	await _verdict.states(_by_width_answers_its_own_width_while_the_window_says_one_thing)
	await _verdict.states(_the_base_turns_with_the_window_and_words_keep_their_size)
	await _verdict.states(_the_turn_ends_arranged_with_nothing_drawn_over_anything_else)
	await _verdict.states(_reduced_it_is_arranged_at_once)
	quit(_verdict.deliver(get_script()))


## The look, with the constants theme.gd is to hold for the type Shape.
func _look() -> Theme:
	var made := Themes.new(Themes.NEUTRAL)
	made.set_type_variation(Shape.TYPE, &"Control")
	made.set_constant(&"compact_below", Shape.TYPE, 900)
	made.set_constant(&"wide_from", Shape.TYPE, 1600)
	made.set_constant(&"dead_band", Shape.TYPE, 80)
	made.set_constant(&"phone_under_mm", Shape.TYPE, 110)
	made.set_constant(&"desk_from_mm", Shape.TYPE, 340)
	made.set_constant(&"sideways_from", Shape.TYPE, 150)
	Transition.defaults(made, {&"by_shape": Transition.FADE})
	return made


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


func _step(seconds: float) -> void:
	_made.ui.motion.step(seconds)
	await _a_frame_passes()


## The window at this size, and everything told about it.
func _window(wide: int, tall: int) -> void:
	root.size = Vector2i(wide, tall)
	await _a_frame_passes()


## A fixture on an easel across the window, the look on its canvas, and the
## shape model beside the app with a count of both its values moving.
func _standing(wide: int, tall: int, declared: Dictionary = {}) -> void:
	_easel = Easel.new()
	_easel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_easel.canvas.theme = _look()
	root.add_child(_easel)
	root.size = Vector2i(wide, tall)
	await _a_frame_passes()
	_made = Fixture.new(_easel.canvas, declared)
	_shape = _made.ui.shape
	# a screen of 72 dots to the inch whatever this machine's is, so no statement's sizes straddle an edge of real size by chance
	_shape.reads_dpi = func() -> int: return 72
	_heard = Fixture.Heard.new(_made.chimes, func() -> void:
		_shape.orientation.read()
		_shape.size_class.read())


func _moving() -> void:
	_made.ui.motion.by_hand = true
	_made.ui.motion.still = false


func _done() -> void:
	_heard.free()
	_made.done()
	_easel.free()


## Two surfaces of words, named, arranged one way by orientation and the
## other by size class, under the app.
func _two_parts(reads: Bound, arrangements: Dictionary) -> ByShape:
	var ui := _made.ui
	var parts: Array = [ui.surface(Themes.SURFACE, [ui.text("left")]).named(&"one"), ui.surface(Themes.SURFACE, [ui.text("right")]).named(&"two")]
	var shaped := Desc.new(&"by_shape", {"names": [&"one", &"two"], "arrangements": arrangements, "reads": reads}, parts)
	ui.start(ui.app(&"app", [shaped.named(&"shaped")]))
	await _a_frame_passes()
	return ui.node_named(&"shaped")


## An arrangement of these parts, along or down, each taking an equal share.
func _halves(down: bool, order: Array) -> Dictionary:
	var facts: Dictionary = {}
	for named: StringName in order:
		facts[named] = {"grow": 1.0}
	return _made.ui.column_of(order, facts) if down else _made.ui.row_of(order, facts)


func _the_shape_follows_the_window_and_rings_once_per_change_not_per_pixel() -> void:
	await _standing(1920, 1080)
	_verdict.check(_shape.orientation.read() == Shape.LANDSCAPE and _shape.size_class.read() == Shape.WIDE, "a 1920 by 1080 window is landscape and wide: %s %s" % [_shape.orientation.read(), _shape.size_class.read()])
	var before := _heard.rung
	await _window(1280, 800)
	_verdict.check(_shape.orientation.read() == Shape.LANDSCAPE and _shape.size_class.read() == Shape.REGULAR and _heard.rung == before + 1, "the deck's 1280 by 800 is landscape and regular, and the shape rang once: %s %d" % [_shape.size_class.read(), _heard.rung - before])
	before = _heard.rung
	await _window(1290, 800)
	await _window(1300, 810)
	_verdict.check(_heard.rung == before and _shape.size_class.read() == Shape.REGULAR, "dragged wider within its class, twice, it says nothing: %d" % (_heard.rung - before))
	var upright: bool = _shape.portrait.read()
	await _window(800, 1280)
	_verdict.check(_shape.orientation.read() == Shape.PORTRAIT and _shape.size_class.read() == Shape.COMPACT and _heard.rung == before + 1, "turned on its side it is portrait and compact, both set in the one change and rung once: %d" % (_heard.rung - before))
	_verdict.check(not upright and _shape.portrait.read(), "portrait is the window on its end, ready to bind to: %s then %s" % [upright, _shape.portrait.read()])
	_done()


func _a_class_holds_its_ground_until_the_width_is_well_past_the_edge() -> void:
	await _standing(1700, 700)
	_verdict.check(_shape.size_class.read() == Shape.WIDE, "1700 across is wide")
	await _window(1560, 700)
	_verdict.check(_shape.size_class.read() == Shape.WIDE, "dragged 40 inside the edge it is wide still, not flickering: %s" % _shape.size_class.read())
	await _window(1500, 700)
	_verdict.check(_shape.size_class.read() == Shape.REGULAR, "dragged well past it, it gives way: %s" % _shape.size_class.read())
	await _window(1560, 700)
	_verdict.check(_shape.size_class.read() == Shape.REGULAR, "and back inside the edge the other way it stays regular: %s" % _shape.size_class.read())
	await _window(1620, 700)
	_verdict.check(_shape.size_class.read() == Shape.WIDE, "past the edge it is wide again: %s" % _shape.size_class.read())
	await _window(880, 700)
	_verdict.check(_shape.size_class.read() == Shape.COMPACT, "under 900 it is compact")
	await _window(940, 700)
	_verdict.check(_shape.size_class.read() == Shape.COMPACT, "40 back over the edge it is compact still: %s" % _shape.size_class.read())
	await _window(1000, 700)
	_verdict.check(_shape.size_class.read() == Shape.REGULAR, "100 over it, it gives way: %s" % _shape.size_class.read())
	_done()


## On a screen of 96 dots to the inch a millimetre is 3.78 pixels: 340 mm is
## 1285 across and 110 mm is 416. On a phone's of 460 it is 18.1.
func _the_real_size_is_read_in_millimetres_on_the_screen_not_in_pixels() -> void:
	await _standing(1920, 1080)
	_shape.reads_dpi = func() -> int: return 96
	await _window(1300, 800)
	_verdict.check(_shape.real_size.read() == Shape.DESK, "344 mm across and 212 on its shorter side is a desk's window: %s" % _shape.real_size.read())
	await _window(1270, 800)
	_verdict.check(_shape.real_size.read() == Shape.SIDEWAYS, "336 mm across is too narrow for a desk's, and over half again as wide as tall is a phone's held sideways: %s" % _shape.real_size.read())
	await _window(1100, 800)
	_verdict.check(_shape.real_size.read() == Shape.UPRIGHT, "narrowed under half again as wide as tall it is a phone's upright: %s" % _shape.real_size.read())
	await _window(1900, 400)
	_verdict.check(_shape.real_size.read() == Shape.SIDEWAYS, "wide enough for a desk's but 106 mm on its shorter side, it is a phone's held sideways: %s" % _shape.real_size.read())
	await _window(1900, 1000)
	var on_a_desk: StringName = _shape.real_size.read()
	_shape.reads_dpi = func() -> int: return 460
	await _window(1900, 1001)
	_verdict.check(on_a_desk == Shape.DESK and _shape.real_size.read() == Shape.SIDEWAYS, "the same pixels are a desk's window on a desk's screen and a phone's on a phone's, 105 mm across: %s then %s" % [on_a_desk, _shape.real_size.read()])
	await _window(1001, 1900)
	_verdict.check(_shape.real_size.read() == Shape.UPRIGHT, "and that phone turned on its end is upright: %s" % _shape.real_size.read())
	_done()


func _by_shape_arranges_by_the_real_size() -> void:
	await _standing(1920, 1080)
	_shape.reads_dpi = func() -> int: return 96
	var shaped := await _two_parts(_shape.real_size, {Shape.DESK: _halves(false, [&"one", &"two"]), Shape.SIDEWAYS: _halves(false, [&"two", &"one"]), Shape.UPRIGHT: _halves(true, [&"one", &"two"])})
	var one: Control = shaped.part_for(&"one")
	var two: Control = shaped.part_for(&"two")
	_verdict.check(shaped.get_worn() == Shape.DESK and one.position.x < two.position.x, "a desk's window wears the desk's arrangement: %s" % shaped.get_worn())
	await _window(844, 390)
	await _a_frame_passes()
	_verdict.check(shaped.get_worn() == Shape.SIDEWAYS and two.position.x < one.position.x, "a phone's held sideways wears its own, the parts swapped along the row: %s" % shaped.get_worn())
	await _window(390, 844)
	await _a_frame_passes()
	_verdict.check(shaped.get_worn() == Shape.UPRIGHT and one.position.y < two.position.y, "and upright they are down a column: %s" % shaped.get_worn())
	_done()


## An arrangement names the facts of the parts that have any, and a part
## left out of them takes its own length: the first part is told to take
## the room left, the second is named nowhere, so the first is far the
## wider of the two and the second is only as wide as its words.
func _an_arrangement_gives_each_part_the_facts_named_for_it_and_none_to_the_rest() -> void:
	await _standing(1920, 1080)
	var ui := _made.ui
	var across := ui.row_of([&"one", &"two"], {&"one": {"grow": 1.0}})
	var shaped := await _two_parts(_shape.orientation, {Shape.LANDSCAPE: across, Shape.PORTRAIT: across})
	var one: Control = shaped.part_for(&"one")
	var two: Control = shaped.part_for(&"two")
	_verdict.check(one.size.x > two.size.x * 4.0, "the part told to take the room left has far the most of it: %s against %s" % [one.size.x, two.size.x])
	_verdict.check(two.size.x > 0.0 and two.size.x < 400.0, "and the part named in no facts is only as wide as what it holds: %s" % two.size.x)
	_done()


func _by_shape_arranges_by_orientation_and_by_size_class() -> void:
	await _standing(1920, 1080)
	var shaped := await _two_parts(_shape.orientation, {Shape.LANDSCAPE: _halves(false, [&"one", &"two"]), Shape.PORTRAIT: _halves(true, [&"two", &"one"])})
	var one: Control = shaped.part_for(&"one")
	var two: Control = shaped.part_for(&"two")
	_verdict.check(shaped.get_worn() == Shape.LANDSCAPE and one.position.x < two.position.x and one.position.y == two.position.y, "landscape, the two parts are along a row: %s %s" % [one.position, two.position])
	await _window(800, 1280)
	await _a_frame_passes()
	_verdict.check(shaped.get_worn() == Shape.PORTRAIT and two.position.y < one.position.y and one.position.x == two.position.x, "turned, the same two parts are down a column in the other order: %s %s" % [one.position, two.position])
	_done()
	await _standing(1920, 1080)
	var classed := await _two_parts(_shape.size_class, {Shape.WIDE: _halves(false, [&"one", &"two"]), Shape.REGULAR: _halves(false, [&"two", &"one"]), Shape.COMPACT: _halves(true, [&"one", &"two"])})
	_verdict.check(classed.get_worn() == Shape.WIDE, "wide, it wears the wide arrangement")
	await _window(1280, 800)
	_verdict.check(classed.get_worn() == Shape.REGULAR and classed.part_for(&"two").position.x < classed.part_for(&"one").position.x, "narrowed to regular, the same parts swap ends without the window turning: %s" % classed.part_for(&"two").position)
	await _window(700, 600)
	_verdict.check(classed.get_worn() == Shape.COMPACT and classed.part_for(&"one").position.y < classed.part_for(&"two").position.y, "narrowed again it stacks: %s %s" % [classed.part_for(&"one").position, classed.part_for(&"two").position])
	_done()


func _turned_the_parts_are_the_same_parts_with_their_words_and_the_focus() -> void:
	await _standing(1920, 1080, {&"types": "type", &"presses": "press"})
	var ui := _made.ui
	var model := Fixture.Model.new(_made.chimes, &"app")
	_made.commands.register(&"app", &"types", model)
	_made.commands.register(&"app", &"presses", model)
	var parts: Array = [ui.field(&"types").named(&"line"), ui.pressable(&"presses", {}, [ui.text("press")]).named(&"button")]
	var shaped := Desc.new(&"by_shape", {"names": [&"line", &"button"], "arrangements": {Shape.LANDSCAPE: _halves(false, [&"line", &"button"]), Shape.PORTRAIT: _halves(true, [&"button", &"line"])}, "reads": _shape.orientation}, parts)
	ui.start(ui.app(&"app", [shaped.named(&"shaped")]))
	await _a_frame_passes()
	var field: Control = ui.node_named(&"line")
	var button: Control = ui.node_named(&"button")
	field.find_children("*", "LineEdit", true, false)[0].text = "half a li"
	button.grab_focus()
	await _a_frame_passes()
	_verdict.check(field.get_line() == "half a li" and _easel.viewport.gui_get_focus_owner() == button, "a line half typed and the focus on the button: %s" % field.get_line())
	await _window(800, 1280)
	await _a_frame_passes()
	_verdict.check(ui.node_named(&"shaped").get_worn() == Shape.PORTRAIT and ui.node_named(&"line") == field and ui.node_named(&"button") == button, "turned, they are the very same nodes, arranged the other way")
	_verdict.check(field.get_line() == "half a li" and _easel.viewport.gui_get_focus_owner() == button, "the half-typed line is still half typed and the focus is still on the button: %s %s" % [field.get_line(), _easel.viewport.gui_get_focus_owner()])
	model.free()
	_done()


func _a_place_under_it_is_one_place_that_keeps_its_name_and_its_stay() -> void:
	await _standing(1920, 1080)
	var ui := _made.ui
	var counts := [0, 0]
	var page := ui.screen(&"page", [ui.text("a page")], null, {on_fill = func(_token: Variant) -> void: counts[0] += 1, on_empty = func() -> void: counts[1] += 1})
	var parts: Array = [page.named(&"page"), ui.surface(Themes.SURFACE, [ui.text("beside")]).named(&"side")]
	var shaped := Desc.new(&"by_shape", {"names": [&"page", &"side"], "arrangements": {Shape.LANDSCAPE: ui.row_of([&"page", &"side"], {&"page": {"grow": 1.0}, &"side": {"basis": 0.25}}), Shape.PORTRAIT: ui.column_of([&"side", &"page"], {&"page": {"grow": 1.0}, &"side": {"basis": 0.2}})}, "reads": _shape.orientation}, parts)
	ui.start(ui.app(&"app", [shaped.named(&"shaped")]))
	await _a_frame_passes()
	_made.commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": &"page"})
	await _a_frame_passes()
	var place: Node = ui.node_named(&"page")
	_verdict.check(_made.driver.index.place_named(&"page") == place and counts == [1, 0], "the place is the place of its name and the reader is in it: %s" % [counts])
	await _window(800, 1280)
	await _a_frame_passes()
	_verdict.check(ui.node_named(&"shaped").get_worn() == Shape.PORTRAIT and _made.driver.index.place_named(&"page") == place and place.is_inside_tree(), "turned, it is the same place, never out of the tree, still of its name")
	_verdict.check(counts == [1, 0] and _made.driver.index.refused_names().is_empty(), "it was never emptied, never filled again, and no second of its name was refused: %s %s" % [counts, _made.driver.index.refused_names()])
	_done()


func _by_width_answers_its_own_width_while_the_window_says_one_thing() -> void:
	await _standing(1920, 1080)
	var ui := _made.ui
	var card := func(under: StringName) -> Desc:
		var parts: Array = [ui.surface(Themes.SURFACE, [ui.text("top")]), ui.surface(Themes.SURFACE, [ui.text("foot")])]
		return Desc.new(&"by_width", {"names": [&"one", &"two"], "arrangements": {&"stacked": _halves(true, [&"one", &"two"]), &"across": _halves(false, [&"one", &"two"])}, "breakpoints": {&"stacked": 0.0, &"across": 0.3}}, parts).named(under)
	ui.start(ui.app(&"app", [ui.row([card.call(&"narrow").basis(0.2), card.call(&"broad").basis(0.75)])]))
	await _a_frame_passes()
	var narrow: ByWidth = ui.node_named(&"narrow")
	var broad: ByWidth = ui.node_named(&"broad")
	_verdict.check(narrow.size.x < broad.size.x and _shape.size_class.read() == Shape.WIDE, "one card is in a narrow column and one in a wide, on one wide window: %s %s" % [narrow.size.x, broad.size.x])
	_verdict.check(narrow.get_worn() == &"stacked" and broad.get_worn() == &"across", "the same card stacks in the narrow column and stays a row in the wide one: %s %s" % [narrow.get_worn(), broad.get_worn()])
	_verdict.check(narrow.part_for(&"one").position.y < narrow.part_for(&"two").position.y and broad.part_for(&"one").position.x < broad.part_for(&"two").position.x, "and their parts are where that says: %s %s" % [narrow.part_for(&"two").position, broad.part_for(&"two").position])
	_done()


func _the_base_turns_with_the_window_and_words_keep_their_size() -> void:
	await _standing(1920, 1080)
	var ui := _made.ui
	ui.start(ui.app(&"app", [ui.column([ui.text("a line of words").named(&"words")])]))
	await _a_frame_passes()
	var words: Control = ui.node_named(&"words")
	var across := _share_of_the_short_side(words)
	_verdict.check(_easel.viewport.size_2d_override == Vector2i(1920, 1080), "landscape, the canvas is drawn at the project's base: %s" % _easel.viewport.size_2d_override)
	await _window(1080, 1920)
	await _a_frame_passes()
	var down := _share_of_the_short_side(words)
	_verdict.check(_easel.viewport.size_2d_override == Vector2i(1080, 1920), "turned, the base is turned with it: %s" % _easel.viewport.size_2d_override)
	_verdict.check(absf(down - across) < across * 0.02, "and the same line of words takes the same share of the window's short side either way round, rather than shrinking to a stamp: %s then %s" % [across, down])
	await _window(1920, 1080)
	_verdict.check(_easel.viewport.size_2d_override == Vector2i(1920, 1080), "turned back, the base comes back: %s" % _easel.viewport.size_2d_override)
	_done()


## How tall this is drawn on the window, as a share of the window's shorter side.
func _share_of_the_short_side(control: Control) -> float:
	var scale: float = _easel.viewport.get_final_transform().get_scale().y
	return control.get_combined_minimum_size().y * scale / mini(root.size.x, root.size.y)


## Every pair of parts drawn over each other now.
func _overlapping(shaped: ByShape) -> Array:
	var seen: Array = shaped.get_children(true).filter(func(child: Node) -> bool: return child is Control and (child as Control).modulate.a > 0.01)
	var pairs: Array = []
	for a: int in seen.size():
		for b: int in range(a + 1, seen.size()):
			if Rect2(seen[a].position, seen[a].size).intersects(Rect2(seen[b].position, seen[b].size)):
				pairs.append([seen[a].position, seen[b].position])
	return pairs


func _the_turn_ends_arranged_with_nothing_drawn_over_anything_else() -> void:
	await _standing(1920, 1080)
	_moving()
	var shaped := await _two_parts(_shape.orientation, {Shape.LANDSCAPE: _halves(false, [&"one", &"two"]), Shape.PORTRAIT: _halves(true, [&"two", &"one"])})
	await _window(800, 1280)
	_verdict.check(shaped.get_worn() == Shape.PORTRAIT and shaped.modulate.a == 0.0 and _made.ui.motion.get_running() == 1, "the turn is arranged at once and the whole of it is on its way in, unseen: %s %s" % [shaped.get_worn(), shaped.modulate.a])
	var crossed: Array = []
	# the clock stepped a hundredth at a time through the whole turn, looked at after every step
	for tick: int in 80:
		await _step(0.01)
		crossed.append_array(_overlapping(shaped))
	var one: Control = shaped.part_for(&"one")
	var two: Control = shaped.part_for(&"two")
	_verdict.check(crossed.is_empty(), "at no step of the turn was a part drawn over another: %s" % [crossed.slice(0, 3)])
	_verdict.check(two.position.y < one.position.y and shaped.modulate == Color.WHITE and one.modulate == Color.WHITE and two.modulate == Color.WHITE and _made.ui.motion.get_running() == 0, "and it ends exactly arranged, both parts whole, nothing left running: %s %s" % [one.position, two.position])
	_done()


func _reduced_it_is_arranged_at_once() -> void:
	await _standing(1920, 1080)
	_moving()
	var shaped := await _two_parts(_shape.orientation, {Shape.LANDSCAPE: _halves(false, [&"one", &"two"]), Shape.PORTRAIT: _halves(true, [&"two", &"one"])})
	_made.ui.motion.told(Motion.REDUCES, {"on": true})
	await _window(800, 1280)
	var one: Control = shaped.part_for(&"one")
	var two: Control = shaped.part_for(&"two")
	_verdict.check(shaped.get_worn() == Shape.PORTRAIT and two.position.y < one.position.y and one.modulate == Color.WHITE, "reduced, the turn is arranged there and then: %s %s" % [one.position, two.position])
	_verdict.check(_made.ui.motion.get_running() == 1, "what is left of it arriving is a fade")
	await _step(0.09)
	_verdict.check(shaped.modulate == Color.WHITE and _made.ui.motion.get_running() == 0, "a short one: %s" % shaped.modulate.a)
	_done()
