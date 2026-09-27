extends SceneTree

## What must be true of named areas: a layout's words give each part the
## rectangle of cells its name takes; the widest layout the width meets is
## worn; each part is laid into its cells - columns by their shares, a row as
## tall as its parts or its share of what is left; a narrower width re-flows
## the same parts, the focus kept and a part named nowhere hidden, never
## freed; and it needs the height of every row's least.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_areas.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Areas := preload("res://addons/gd_chime/components/primitives/areas.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Verdict := preload("res://tests/verdict.gd")

const PRESSES := &"presses"
## Figures along the top and a tall chart at the right when wide; one over another, and the note let go, when narrow.
const LAYOUTS := {
	&"wide": {"least": &"compact_below", "columns": [0.25, 0.25, 0.5], "rows": [0.0, 0.2], "areas": ["a b c", "d d c"]},
	&"narrow": {"least": 0.0, "columns": [1.0], "rows": [0.0, 0.0, 0.0], "areas": ["a", "b", "c"]},
}

var _verdict := Verdict.new()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(1600, 900)
	await _verdict.states(_the_words_give_each_part_the_rectangle_its_name_takes)
	await _verdict.states(_the_widest_layout_the_width_meets_is_worn_and_each_part_laid_into_its_cells)
	await _verdict.states(_a_narrower_width_reflows_the_same_parts_the_focus_kept_and_one_named_nowhere_hidden)
	await _verdict.states(_a_layout_whose_part_is_wider_than_its_columns_is_passed_over_for_a_narrower)
	quit(_verdict.deliver(get_script()))


func _frames(count: int) -> void:
	# as many frames as asked, for the window's size to reach the layouts
	for waited: int in count:
		await process_frame


## The four parts in their areas, built and started, a's words those given: [the fixture, the areas].
func _built(a_says: String = "a") -> Array:
	var made := Fixture.new(root, {PRESSES: "press"})
	var ui := made.ui
	var part := func(named: String, words: String) -> Desc: return ui.pressable(PRESSES, {}, [ui.text(words, Themes.FACE)]).named(StringName(named))
	var laid := ui.areas({&"a": part.call("a", a_says), &"b": part.call("b", "b"), &"c": part.call("c", "c"), &"d": part.call("d", "d")}, LAYOUTS).named(&"areas")
	ui.start(ui.app(&"app", [ui.column([laid.grow()])]))
	await _frames(3)
	return [made, ui.node_named(&"areas")]


func _the_words_give_each_part_the_rectangle_its_name_takes() -> void:
	var cells := Areas.cells_of(LAYOUTS[&"wide"]["areas"])
	_verdict.check(cells == {&"a": Rect2i(0, 0, 1, 1), &"b": Rect2i(1, 0, 1, 1), &"c": Rect2i(2, 0, 1, 2), &"d": Rect2i(0, 1, 2, 1)}, "each name fills the cells it takes: c two rows down, d two columns across: %s" % [cells])
	_verdict.check(Areas.cells_of(["a . b"]) == {&"a": Rect2i(0, 0, 1, 1), &"b": Rect2i(2, 0, 1, 1)}, "a dot is a cell nobody fills")


func _the_widest_layout_the_width_meets_is_worn_and_each_part_laid_into_its_cells() -> void:
	var both: Array = await _built()
	var ui: RefCounted = (both[0] as Fixture).ui
	var areas: Control = both[1]
	var gap := float(areas.get_theme_constant(&"gap", &"Grid"))
	var row_gap := float(areas.get_theme_constant(&"row_gap", &"Grid"))
	var across := areas.size.x - gap * 2.0
	var a: Rect2 = ui.node_named(&"a").get_rect()
	var c: Rect2 = ui.node_named(&"c").get_rect()
	var d: Rect2 = ui.node_named(&"d").get_rect()
	_verdict.check(areas.get_worn() == &"wide", "a wide window wears the wide layout: %s at %s" % [areas.get_worn(), areas.size])
	_verdict.check(is_equal_approx(a.size.x, across * 0.25) and is_equal_approx(c.position.x, across * 0.5 + gap * 2.0) and is_equal_approx(c.size.x, across * 0.5), "columns take their shares of the width left after the gaps: a %s, c %s" % [a, c])
	_verdict.check(is_equal_approx(a.size.y, ui.node_named(&"a").get_combined_minimum_size().y) and is_equal_approx(d.position.y, a.size.y + row_gap) and is_equal_approx(d.end.y, areas.size.y), "the first row is as tall as its parts need, and the row with a share takes the rest: a %s, d %s" % [a, d])
	_verdict.check(is_equal_approx(d.size.x, across * 0.5 + gap) and is_equal_approx(c.size.y, areas.size.y), "a part across two columns spans them and the gap between, and one down two rows spans the whole height: d %s, c %s" % [d, c])
	var widest: float = [&"a", &"b", &"c"].map(func(named: StringName) -> float: return ui.node_named(named).get_combined_minimum_size().x).max()
	_verdict.check(is_equal_approx(areas.get_combined_minimum_size().x, widest), "wearing the wide layout, it needs across only what its narrowest layout does - the widest part it stacks - so a holder may narrow it: %s against %s" % [areas.get_combined_minimum_size().x, widest])
	(both[0] as Fixture).done()


func _a_narrower_width_reflows_the_same_parts_the_focus_kept_and_one_named_nowhere_hidden() -> void:
	var both: Array = await _built()
	var ui: RefCounted = (both[0] as Fixture).ui
	var areas: Control = both[1]
	var parts: Array = [&"a", &"b", &"c", &"d"].map(func(named: StringName) -> Node: return ui.node_named(named))
	(parts[2] as Control).grab_focus()
	root.size = Vector2i(700, 900)
	await _frames(3)
	var now: Array = [&"a", &"b", &"c", &"d"].map(func(named: StringName) -> Node: return ui.node_named(named))
	_verdict.check(areas.get_worn() == &"narrow" and now == parts and (parts[2] as Control).has_focus(), "narrow, the narrow layout is worn over the very same parts, and the focus is still on c")
	var a: Rect2 = (parts[0] as Control).get_rect()
	var b: Rect2 = (parts[1] as Control).get_rect()
	var c: Rect2 = (parts[2] as Control).get_rect()
	_verdict.check(is_equal_approx(a.size.x, areas.size.x) and b.position.y > a.end.y and c.position.y > b.end.y, "one column, each part under the one before: %s %s %s" % [a, b, c])
	_verdict.check(not (parts[3] as Control).visible and is_instance_valid(parts[3]), "d, named nowhere here, is hidden and never freed")
	var least := 0.0
	# every part shown, its least height added
	for shown: Control in parts.slice(0, 3):
		least += shown.get_combined_minimum_size().y
	_verdict.check(is_equal_approx(areas.get_combined_minimum_size().y, least + 2.0 * areas.get_theme_constant(&"row_gap", &"Grid")), "it needs every row's least and the gaps between them: %s" % areas.get_combined_minimum_size().y)
	root.size = Vector2i(1600, 900)
	await _frames(3)
	_verdict.check(areas.get_worn() == &"wide" and (parts[3] as Control).visible, "wide again, the wide layout is back and d is shown again")
	(both[0] as Fixture).done()


## A wide window, but a's words wider than a quarter of it: the wide layout
## would draw a over b, so the narrow one is worn; and what the areas need
## across is the narrow one's, never held wide by the layout it cannot wear.
func _a_layout_whose_part_is_wider_than_its_columns_is_passed_over_for_a_narrower() -> void:
	var both: Array = await _built("a figure a great deal wider than a quarter of the window")
	var areas: Control = both[1]
	var a: Control = (both[0] as Fixture).ui.node_named(&"a")
	_verdict.check(a.get_combined_minimum_size().x > areas.size.x * 0.25 and a.get_combined_minimum_size().x < areas.size.x, "a needs more than a quarter of the width and less than the whole: %s of %s" % [a.get_combined_minimum_size().x, areas.size.x])
	_verdict.check(areas.get_worn() == &"narrow", "so the wide layout, which would draw it over b, is passed over for the narrow: %s" % areas.get_worn())
	_verdict.check(is_equal_approx(areas.get_combined_minimum_size().x, a.get_combined_minimum_size().x), "and the areas need across only what the narrow layout needs, a's width: %s" % areas.get_combined_minimum_size().x)
	(both[0] as Fixture).done()
