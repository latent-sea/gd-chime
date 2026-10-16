extends SceneTree

## What must be true of a drawer: raised, its sheet stands against its edge,
## the look's share of the window across - most of it on a window on its end
## - the shade taking the rest; the sheet slides in from its edge while the
## pop-up fades, and from the left edge for a drawer from the left; the
## focus goes into it; its close press, a press on the shade and Back each
## lower it, the focus back on its opener; and the shade never takes the
## focus. Its head says its title over what it holds, the foot below. A
## bottom sheet is capped across as a fitted sheet is - the room less the
## look's sheet margin either side, at most its sheet most - in the middle,
## and meets the window's edges only where that leaves less than its least.
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
const Sheet := preload("res://addons/gd_chime/components/recipes/sheet.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Verdict := preload("res://tests/verdict.gd")

const WIDE := Vector2i(1000, 500)
## The look's sheet margin and most across, in base pixels.
const MARGIN := 24
const MOST := 600
const OPENS := &"opens_the_basket"

var _verdict := Verdict.new()
var _basket: StringName  # the drawer's pop-up, named by the builder


func _init() -> void:
	var theme := Themes.new(Themes.NEUTRAL)
	theme.set_constant(&"wide", Drawer.SHEET, 300)
	theme.set_constant(&"narrow", Drawer.SHEET, 900)
	theme.set_constant(&"tall", Drawer.SHEET, 600)
	theme.set_constant(&"margin", Sheet.LOOK, MARGIN)
	theme.set_constant(&"most_wide", Sheet.LOOK, MOST)
	root.theme = theme
	await process_frame
	root.size = WIDE
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_raised_its_sheet_stands_against_its_edge_the_looks_share_across)
	await _verdict.states(_what_it_holds_scrolls_between_its_head_and_its_foot)
	await _verdict.states(_its_sheet_slides_in_from_its_edge_while_the_pop_up_fades)
	await _verdict.states(_its_close_press_the_shade_and_back_each_lower_it_the_focus_back_on_its_opener)
	await _verdict.states(_a_bottom_sheet_meets_the_window_s_edges_only_where_the_cap_leaves_less_than_its_least)
	quit(_verdict.deliver(get_script()))


## An app whose opener opens a drawer from this edge, holding so many lines, described on it: the fixture, started, on the window or on an easel.
func _drawn(from: StringName, under: Node = root, lines: int = 1) -> Fixture:
	var made := Fixture.new(under, {OPENS: "open the basket"})
	var ui := made.ui
	var foot := ui.text("the total").named(&"foot")
	var drawer := Drawer.over(ui, "basket", func(_which: Bound) -> Desc: return ui.column(range(lines).map(func(line: int) -> Desc: return ui.text("a sofa %d" % line))).named(&"body"), {foot = foot, from = from})
	_basket = drawer.get_place()
	ui.start(ui.app(&"app", [ui.screen(&"shelf", [ui.pressable(OPENS, {}, [ui.text("basket")], Themes.PRESSABLE).opens(drawer).named(&"opener")])]))
	return made


func _frames(count: int) -> void:
	# so many frames, for a move to be carried out and laid out
	for frame: int in count:
		await process_frame


## The sheet: what it holds stands in its page, in its column, on it.
func _sheet(made: Fixture) -> Control:
	return (made.ui.node_named(&"body") as Control).get_parent().get_parent().get_parent()


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
	_verdict.check(is_equal_approx(bottom.size.x, MOST) and is_equal_approx(bottom.position.x, (WIDE.x - MOST) / 2.0) and is_equal_approx(bottom.end.y, WIDE.y) and is_equal_approx(bottom.size.y, WIDE.y * 0.6), "a drawer from the foot is a bottom sheet against its foot, the look's share of its height, and across the look's most, in the middle: %s" % [bottom])
	root.size = Vector2i(500, 1000)
	await _frames(4)
	bottom = _sheet(made).get_global_rect()
	_verdict.check(is_equal_approx(bottom.size.x, 500 - 2 * MARGIN) and is_equal_approx(bottom.position.x, MARGIN) and is_equal_approx(bottom.end.y, 1000), "and on a window narrower than the most, the room less the margin either side: %s" % [bottom])
	root.size = WIDE
	made.done()


## A margin of 240 either side of a window 500 across leaves 20, less than
## the sheet's least: the margin goes, and the sheet spans the window.
func _a_bottom_sheet_meets_the_window_s_edges_only_where_the_cap_leaves_less_than_its_least() -> void:
	var look: Theme = root.theme
	look.set_constant(&"margin", Sheet.LOOK, 240)
	root.size = Vector2i(500, 1000)
	var made := _drawn(Drawer.FROM_BOTTOM)
	await _frames(3)
	(made.ui.node_named(&"opener") as Pressable).pressed()
	await _frames(4)
	var bottom := _sheet(made).get_global_rect()
	_verdict.check(_sheet(made).get_combined_minimum_size().x > 20.0 and bottom.position.x == 0.0 and bottom.size.x == 500.0 and bottom.end.y == 1000.0, "the cap leaving less than its least of %s, the bottom sheet meets the window's edges against its foot: %s" % [_sheet(made).get_combined_minimum_size(), bottom])
	look.set_constant(&"margin", Sheet.LOOK, MARGIN)
	root.size = Vector2i(1200, 1000)
	await _frames(4)
	bottom = _sheet(made).get_global_rect()
	_verdict.check(is_equal_approx(bottom.size.x, MOST) and is_equal_approx(bottom.position.x, 300.0), "and the same sheet, given room for its margins and its most, keeps them - the room decides, never the window's kind: %s" % [bottom])
	made.done()
	root.size = WIDE


## Sixty lines, far more than a window 500 tall shows.
func _what_it_holds_scrolls_between_its_head_and_its_foot() -> void:
	# from a side and from the foot
	for from: StringName in [Drawer.FROM_RIGHT, Drawer.FROM_BOTTOM]:
		var made := _drawn(from, root, 60)
		await _frames(3)
		(made.ui.node_named(&"opener") as Pressable).pressed()
		await _frames(4)
		var page: ScrollContainer = (made.ui.node_named(&"body") as Control).get_parent()
		var foot: Control = made.ui.node_named(&"foot")
		var window := Rect2(Vector2.ZERO, Vector2(WIDE)).grow(0.5)
		_verdict.check(page.get_v_scroll_bar().max_value > page.size.y and window.encloses(foot.get_global_rect()) and window.encloses(_sheet(made).get_global_rect()), "from %s, sixty lines scroll in the sheet, which stays in the window with its foot in view: %s, %s" % [from, _sheet(made).get_global_rect(), foot.get_global_rect()])
		made.done()


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
