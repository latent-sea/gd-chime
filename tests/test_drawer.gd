extends SceneTree

## What must be true of a drawer: raised, its sheet stands against its edge,
## the look's share of the window across - most of it on a window on its end
## - the shade taking the rest; the sheet slides in from its edge while the
## pop-up fades, and from the left edge for a drawer from the left; the
## focus goes into it; its close press, a press on the shade and Back each
## lower it, the focus back on its opener; and the shade never takes the
## focus. Its head says its title over what it holds, the foot below. A
## bottom sheet is centred at the look's most share of a desk's window and
## spans a phone's, whose canvas is wider than any look's compact width.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_drawer.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Drawer := preload("res://addons/gd_chime/components/recipes/drawer.gd")
const Shape := preload("res://addons/gd_chime/shape.gd")
const Easel := preload("res://addons/gd_chime/easel.gd")
const Touch := preload("res://addons/gd_chime/touch.gd")
const Sheet := preload("res://addons/gd_chime/components/recipes/sheet.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Verdict := preload("res://tests/verdict.gd")

const WIDE := Vector2i(1000, 500)
const OPENS := &"opens_the_basket"

var _verdict := Verdict.new()
var _basket: StringName  # the drawer's pop-up, named by the builder


func _init() -> void:
	var theme := Themes.new(Themes.NEUTRAL)
	theme.set_constant(&"wide", Drawer.SHEET, 300)
	theme.set_constant(&"narrow", Drawer.SHEET, 900)
	theme.set_constant(&"tall", Drawer.SHEET, 600)
	theme.set_constant(&"most_wide", Drawer.SHEET, 600)
	root.theme = theme
	await process_frame
	root.size = WIDE
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_raised_its_sheet_stands_against_its_edge_the_looks_share_across)
	await _verdict.states(_its_sheet_slides_in_from_its_edge_while_the_pop_up_fades)
	await _verdict.states(_its_close_press_the_shade_and_back_each_lower_it_the_focus_back_on_its_opener)
	await _verdict.states(_a_bottom_sheet_spans_a_phones_window_whose_canvas_is_wider_than_compact)
	quit(_verdict.deliver(get_script()))


## An app whose opener opens a drawer from this edge, described on it: the fixture, started, on the window or on an easel.
func _drawn(from: StringName, under: Node = root) -> Fixture:
	var made := Fixture.new(under, {OPENS: "open the basket"})
	var ui := made.ui
	var foot := ui.text("the total").named(&"foot")
	var drawer := Drawer.over(ui, "basket", func(_which: Bound) -> Desc: return ui.column([ui.text("a sofa")]).named(&"body"), {foot = foot, from = from})
	_basket = drawer.get_place()
	ui.start(ui.app(&"app", [ui.screen(&"shelf", [ui.pressable(OPENS, {}, [ui.text("basket")], Themes.PRESSABLE).opens(drawer).named(&"opener")])]))
	return made


func _frames(count: int) -> void:
	# so many frames, for a move to be carried out and laid out
	for frame: int in count:
		await process_frame


func _sheet(made: Fixture) -> Control:
	return (made.ui.node_named(&"body") as Control).get_parent().get_parent()


func _raised_its_sheet_stands_against_its_edge_the_looks_share_across() -> void:
	var made := _drawn(Drawer.FROM_RIGHT)
	await _frames(3)
	(made.ui.node_named(&"opener") as Pressable).pressed()
	await _frames(3)
	var sheet := _sheet(made)
	_verdict.check(made.driver.get_top().has(_basket) and is_equal_approx(sheet.get_global_rect().end.x, WIDE.x) and is_equal_approx(sheet.size.x, WIDE.x * 0.3) and sheet.size.y == WIDE.y, "raised, the sheet stands against the right edge, the look's share across and the whole height: %s" % [sheet.get_global_rect()])
	var shade: Control = root.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable and part.theme_type_variation == Sheet.SHADE and part.is_visible_in_tree())[0]
	_verdict.check(is_equal_approx(shade.get_global_rect().end.x, sheet.get_global_rect().position.x) and shade.get_global_rect().position.x == 0.0, "the shade runs from the window's edge right up to the sheet, no gap between them where the screen beneath would show unshaded: %s %s" % [shade.get_global_rect(), sheet.get_global_rect()])
	var foot: Control = made.ui.node_named(&"foot")
	_verdict.check(foot.get_global_rect().end.y > (made.ui.node_named(&"body") as Control).get_global_rect().end.y, "its foot is below what it holds")
	root.size = Vector2i(500, 1000)
	await _frames(4)
	_verdict.check(is_equal_approx(sheet.size.x, 500 * 0.9) and is_equal_approx(sheet.get_global_rect().end.x, 500), "on a window on its end it takes the look's larger share: %s" % [sheet.get_global_rect()])
	root.size = WIDE
	made.done()
	made = _drawn(Drawer.FROM_LEFT)
	await _frames(3)
	(made.ui.node_named(&"opener") as Pressable).pressed()
	await _frames(3)
	_verdict.check(_sheet(made).get_global_rect().position.x == 0.0, "a drawer from the left stands against the left edge: %s" % [_sheet(made).get_global_rect()])
	made.done()
	made = _drawn(Drawer.FROM_BOTTOM)
	await _frames(3)
	(made.ui.node_named(&"opener") as Pressable).pressed()
	await _frames(3)
	var bottom := _sheet(made).get_global_rect()
	_verdict.check(is_equal_approx(bottom.size.x, WIDE.x * 0.6) and is_equal_approx(bottom.position.x, WIDE.x * 0.2) and is_equal_approx(bottom.end.y, WIDE.y) and is_equal_approx(bottom.size.y, WIDE.y * 0.6), "a drawer from the foot is a bottom sheet against its foot, the look's share of its height - on a window on its side centred at the look's most share of its width: %s" % [bottom])
	root.size = Vector2i(500, 1000)
	await _frames(4)
	bottom = _sheet(made).get_global_rect()
	_verdict.check(is_equal_approx(bottom.size.x, 500) and is_equal_approx(bottom.end.y, 1000), "and on a window on its end, the whole width: %s" % [bottom])
	root.size = WIDE
	made.done()


## A phone's window is compact and on its end, and its CANVAS is wider than
## any look's compact width: the base the app is drawn at, turned (easel.gd).
## So a bottom sheet that measured itself capped a phone's sheet in the
## middle, as it should a desk's. It is the shape that says whose window it is.
func _a_bottom_sheet_spans_a_phones_window_whose_canvas_is_wider_than_compact() -> void:
	var easel := Easel.new()
	easel.set_anchors_preset(Control.PRESET_FULL_RECT)
	easel.canvas.theme = root.theme
	root.add_child(easel)
	root.size = Vector2i(720, 1280)
	var made := _drawn(Drawer.FROM_BOTTOM, easel.canvas)
	await _frames(4)
	(made.ui.node_named(&"opener") as Pressable).pressed()
	await _frames(4)
	var canvas := easel.viewport.get_visible_rect().size
	_verdict.check(canvas.x > root.theme.get_constant(&"compact_below", &"Shape") and made.ui.shape.whose_window.read() == Shape.PHONE, "the phone's canvas is wider than the look's compact width, and the shape still calls the window a phone's: %s" % [canvas])
	var opener: Control = made.ui.node_named(&"opener")
	_verdict.check(easel.viewport.get_meta(Shape.PHONE, false) and opener.get_combined_minimum_size().y >= easel.canvas.get_theme_constant(&"least", Touch.TYPE), "and says so on the app's own viewport, so a press measures at least the look's touch size: %s" % [opener.get_combined_minimum_size()])
	var bottom := _sheet(made).get_global_rect()
	_verdict.check(bottom.position.x == 0.0 and is_equal_approx(bottom.size.x, canvas.x) and is_equal_approx(bottom.end.y, canvas.y), "so the bottom sheet spans the phone's window, edge to edge against its foot: %s of %s" % [bottom, canvas])
	made.done()
	easel.free()
	root.size = WIDE


func _its_sheet_slides_in_from_its_edge_while_the_pop_up_fades() -> void:
	var made := _drawn(Drawer.FROM_RIGHT)
	await _frames(3)
	made.ui.motion.by_hand = true
	made.ui.motion.still = false
	(made.ui.node_named(&"opener") as Pressable).pressed()
	await _frames(2)
	var sheet := _sheet(made)
	var rest := WIDE.x * 0.7
	made.ui.motion.step(0.06)
	await _frames(1)
	var basket: Control = root.find_children(String(_basket), "Control", true, false)[0]
	_verdict.check(sheet.position.x > rest + 1.0 and basket.position.x == 0.0 and basket.modulate.a < 1.0, "part way, the sheet is still coming in from the right while the pop-up only fades: %s %s" % [sheet.position.x, basket.modulate.a])
	made.ui.motion.step(1.0)
	await _frames(1)
	_verdict.check(is_equal_approx(sheet.position.x, rest) and basket.modulate == Color.WHITE, "and comes to rest against the edge: %s" % sheet.position.x)
	made.done()


func _its_close_press_the_shade_and_back_each_lower_it_the_focus_back_on_its_opener() -> void:
	var made := _drawn(Drawer.FROM_RIGHT)
	await _frames(3)
	var opener: Pressable = made.ui.node_named(&"opener")
	var closes: Array = []
	# each way out: the close press in the head, the shade beside the sheet, and Back
	for way: StringName in [&"close", &"shade", &"back"]:
		opener.grab_focus()
		opener.pressed()
		await _frames(3)
		var inside: Control = root.gui_get_focus_owner()
		var presses: Array = root.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable and part.is_visible_in_tree() and part.action == made.ui.CLOSES)
		var shade: Pressable = presses.filter(func(press: Pressable) -> bool: return press.theme_type_variation == Sheet.SHADE)[0]

		var close: Pressable = presses.filter(func(press: Pressable) -> bool: return press.theme_type_variation == Drawer.CLOSE)[0]
		_verdict.check(inside != null and _sheet(made).is_ancestor_of(inside) and shade.focus_mode == Control.FOCUS_NONE, "raised, the focus goes into the sheet, and the shade never takes it")
		match way:
			&"close": close.pressed()
			&"shade": shade.pressed()
			&"back": made.commands.dispatch(Chimes.GLOBAL, Driver.GOES_BACK, {})
		await _frames(3)
		closes.append(not made.driver.get_top().has(_basket) and root.gui_get_focus_owner() == opener)
	_verdict.check(closes == [true, true, true], "its close press, the shade and Back each lower it, the focus back on its opener: %s" % [closes])
	made.done()
