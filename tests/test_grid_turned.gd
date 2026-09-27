extends SceneTree

## What must be true of a grid given columns for a shape of window, and of a
## grid laid over something that can be pressed.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_grid_turned.gd
##
## Turned, the same cells fall into the columns given for that shape, in the
## order they were given, a cell wider than those columns covering the row;
## nothing is rebuilt, so a typed line and the focus are where they were; the
## room it asks of whatever holds it is what its columns need now; and turned
## back it is the grid it was, to the pixel. A grid given no columns for a
## shape keeps its own whatever the window does, a grid gone is heard no
## more, and a grid takes no press itself, so what lies under it can still be
## pressed. A headless window is a real window for all of this (test_shape.gd
## says what that covers): root.size is the window's pixels and the shape
## model hears it.

const Fixture := preload("res://tests/fixture.gd")
const Verdict := preload("res://tests/verdict.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Shape := preload("res://addons/gd_chime/shape.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const GridLayout := preload("res://addons/gd_chime/components/primitives/grid_layout.gd")

## Four even columns on a wide window.
const FOUR: Array[float] = [0.25, 0.25, 0.25, 0.25]
## Two even columns on a window on its end.
const ON_ITS_END := {Shape.PORTRAIT: [0.5, 0.5]}

var _verdict := Verdict.new()
var _made: Fixture


func _init() -> void:
	await process_frame
	await _verdict.states(_turned_the_same_cells_fall_into_the_columns_for_that_shape_in_order)
	await _verdict.states(_a_cell_wider_than_the_columns_there_are_covers_the_row)
	await _verdict.states(_turned_nothing_is_rebuilt_so_a_typed_line_and_the_focus_are_kept)
	await _verdict.states(_turned_back_it_is_the_grid_it_was)
	await _verdict.states(_turned_it_asks_whatever_holds_it_for_the_room_its_columns_need_now)
	await _verdict.states(_a_grid_given_no_columns_for_a_shape_keeps_its_own_whatever_the_window_does)
	await _verdict.states(_a_grid_gone_is_heard_no_more)
	await _verdict.states(_a_press_on_what_lies_under_a_grid_reaches_it)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## The window at this size, and everything told about it.
func _window(wide: int, tall: int) -> void:
	root.size = Vector2i(wide, tall)
	await _a_frame_passes()


## A fixture on the floor's look, the base back at the project's, the window this size.
func _standing(wide: int, tall: int, declared: Dictionary = {}) -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	root.content_scale_size = Vector2i(1920, 1080)
	root.size = Vector2i(wide, tall)
	await _a_frame_passes()
	_made = Fixture.new(root, declared)


## Six cells of words named cell0 to cell5 covering the columns given, in a
## grid of four even columns - and of the columns given for a shape - as the
## whole of the app.
func _six(spans: Array, turned: Dictionary) -> GridLayout:
	var ui := _made.ui
	var cells: Array = []
	# every cell, named for where it was given, covering the columns asked
	for at: int in 6:
		cells.append(ui.surface(Themes.SURFACE, [ui.text("cell %d" % at)]).named(StringName("cell%d" % at)).span(spans[at]))
	ui.start(ui.app(&"app", [ui.grid(cells, FOUR, Themes.GRID, turned).named(&"grid")]))
	await _a_frame_passes()
	return ui.node_named(&"grid")


## Where each of the six cells is and how big, in the order they were given.
func _rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	# every cell, by its name
	for at: int in 6:
		var cell: Control = _made.ui.node_named(StringName("cell%d" % at))
		rects.append(Rect2(cell.position, cell.size))
	return rects


func _turned_the_same_cells_fall_into_the_columns_for_that_shape_in_order() -> void:
	await _standing(1920, 1080)
	var grid := await _six([1, 1, 1, 1, 1, 1], ON_ITS_END)
	var first: Control = _made.ui.node_named(&"cell0")
	var wide := _rects()
	_verdict.check(wide[0].position.y == wide[3].position.y and wide[3].position.x > wide[2].position.x and wide[4].position.y > wide[0].position.y and wide[4].position.x == wide[0].position.x, "on a wide window four cells run across a row and the fifth starts the next: %s %s" % [wide[3].position, wide[4].position])
	await _window(720, 1280)
	var tall := _rects()
	var half: float = (grid.size.x - float(grid.get_theme_constant(&"gap"))) / 2.0
	_verdict.check(tall[0].position.y == tall[1].position.y and tall[1].position.y < tall[2].position.y and tall[2].position.y == tall[3].position.y and tall[3].position.y < tall[4].position.y and tall[4].position.y == tall[5].position.y, "turned on its end, they fall two to a row, in the order given: %s" % [tall.map(func(rect: Rect2) -> Vector2: return rect.position)])
	_verdict.check(tall[0].position.x == tall[2].position.x and tall[2].position.x == tall[4].position.x and tall[1].position.x == tall[3].position.x and tall[1].position.x > tall[0].position.x, "down two columns that line up: %s %s" % [tall[0].position, tall[1].position])
	_verdict.check(is_equal_approx(tall[0].size.x, half) and is_equal_approx(tall[1].size.x, half), "each half the grid, less the gap: %s of %s" % [tall[0].size.x, half])
	_verdict.check(_made.ui.node_named(&"cell0") == first, "and they are the very cells there were")
	_made.done()


func _a_cell_wider_than_the_columns_there_are_covers_the_row() -> void:
	await _standing(1920, 1080)
	var grid := await _six([3, 1, 1, 1, 1, 1], ON_ITS_END)
	var wide := _rects()
	_verdict.check(wide[1].position.y == wide[0].position.y and wide[2].position.y > wide[0].position.y, "on a wide window the cell covering three leaves the fourth column to the next cell: %s %s" % [wide[1].position, wide[2].position])
	await _window(720, 1280)
	var tall := _rects()
	_verdict.check(tall[0].position.x == 0.0 and is_equal_approx(tall[0].size.x, grid.size.x), "turned, a cell covering three of the two there are covers the row: %s of %s" % [tall[0].size.x, grid.size.x])
	_verdict.check(tall[1].position.y > tall[0].position.y and tall[1].position.x == 0.0 and tall[2].position.y == tall[1].position.y, "and the next two share the row below: %s %s" % [tall[1].position, tall[2].position])
	_made.done()


func _turned_nothing_is_rebuilt_so_a_typed_line_and_the_focus_are_kept() -> void:
	await _standing(1920, 1080, {&"types": "type", &"presses": "press"})
	var ui := _made.ui
	var model := Fixture.Model.new(_made.chimes, &"app")
	_made.commands.register(&"app", &"types", model)
	_made.commands.register(&"app", &"presses", model)
	var cells: Array = [ui.field(&"types").named(&"line"), ui.pressable(&"presses", {}, [ui.text("press")]).named(&"button"), ui.text("a").named(&"a"), ui.text("b").named(&"b")]
	ui.start(ui.app(&"app", [ui.grid(cells, FOUR, Themes.GRID, ON_ITS_END).named(&"grid")]))
	await _a_frame_passes()
	var field: Control = ui.node_named(&"line")
	var button: Control = ui.node_named(&"button")
	field.find_children("*", "LineEdit", true, false)[0].text = "half a li"
	button.grab_focus()
	await _a_frame_passes()
	var along: float = button.position.y
	await _window(720, 1280)
	_verdict.check(button.position.y == along and ui.node_named(&"a").position.y > along, "turned, the cells re-flowed two to a row: %s %s" % [button.position, ui.node_named(&"a").position])
	_verdict.check(ui.node_named(&"line") == field and ui.node_named(&"button") == button, "and they are the very same nodes")
	_verdict.check(field.get_line() == "half a li" and root.gui_get_focus_owner() == button, "the half-typed line is still half typed and the focus is still on the button: %s %s" % [field.get_line(), root.gui_get_focus_owner()])
	model.free()
	_made.done()


func _turned_back_it_is_the_grid_it_was() -> void:
	await _standing(1920, 1080)
	await _six([2, 1, 1, 1, 2, 1], ON_ITS_END)
	var before := _rects()
	await _window(720, 1280)
	var turned := _rects()
	await _window(1920, 1080)
	var after := _rects()
	_verdict.check(turned != before, "on its end the cells stood elsewhere: %s" % [turned.slice(0, 2)])
	_verdict.check(after == before, "turned back, every cell is where it was and as big, to the pixel: %s then %s" % [before.slice(0, 2), after.slice(0, 2)])
	_made.done()


## What it needs is what its columns need NOW: the room it asked for as four
## across is not the room two across need, and whatever holds it - a screen,
## the frame around the screens - is sized by what it says. The cells are
## bare grounds, whose own needs never move, so nothing but the turn itself
## can tell the grid's holder anything.
func _turned_it_asks_whatever_holds_it_for_the_room_its_columns_need_now() -> void:
	await _standing(1920, 1080)
	var ui := _made.ui
	var cells: Array = []
	# six bare grounds of one size, needing nothing from the window
	for at: int in 6:
		cells.append(ui.surface(Themes.SURFACE))
	ui.start(ui.app(&"app", [ui.grid(cells, FOUR, Themes.GRID, ON_ITS_END).named(&"grid")]))
	await _a_frame_passes()
	var grid: GridLayout = ui.node_named(&"grid")
	var four := grid.get_combined_minimum_size()
	await _window(720, 1280)
	var two := grid.get_combined_minimum_size()
	_verdict.check(two.x < four.x and two.y > four.y, "turned, it asks for two columns across and three rows down, not four across and two down: %s then %s" % [four, two])
	await _window(1920, 1080)
	_verdict.check(grid.get_combined_minimum_size() == four, "and turned back, for four across again: %s" % grid.get_combined_minimum_size())
	_made.done()


func _a_grid_given_no_columns_for_a_shape_keeps_its_own_whatever_the_window_does() -> void:
	await _standing(1920, 1080)
	var ui := _made.ui
	var cells: Array = []
	# every cell, named for where it was given
	for at: int in 6:
		cells.append(ui.surface(Themes.SURFACE, [ui.text("cell %d" % at)]).named(StringName("cell%d" % at)))
	ui.start(ui.app(&"app", [ui.grid(cells, FOUR)]))
	await _a_frame_passes()
	await _window(720, 1280)
	var tall := _rects()
	_verdict.check(tall[0].position.y == tall[3].position.y and tall[4].position.y > tall[3].position.y, "described as it always was, on its end it is still four to a row: %s %s" % [tall[3].position, tall[4].position])
	_made.done()


func _a_grid_gone_is_heard_no_more() -> void:
	await _standing(1920, 1080)
	var grid := await _six([1, 1, 1, 1, 1, 1], ON_ITS_END)
	var shape: Array = [_made.ui.shape._own.get_address(), _made.ui.shape._own.get_address()]
	var hearing: Array = _made.chimes.listeners_of(shape[0], shape[1])
	_verdict.check(hearing.has(grid), "a grid given columns for a shape follows the window's shape: %s" % [hearing])
	grid.free()
	_verdict.check(_made.chimes.listeners_of(shape[0], shape[1]).size() == hearing.size() - 1, "gone, nothing of it is left in the chimes: %s" % [_made.chimes.listeners_of(shape[0], shape[1]).size()])
	await _window(720, 1280)
	_made.done()


## A grid laid over something to press takes no press itself: the press
## lands on what is under it, wherever the grid has no cell of its own.
func _a_press_on_what_lies_under_a_grid_reaches_it() -> void:
	await _standing(1920, 1080, {&"presses": "press"})
	var ui := _made.ui
	var model := Fixture.Model.new(_made.chimes, &"app")
	_made.commands.register(&"app", &"presses", model)
	var over := ui.grid([ui.text("a corner")], FOUR)
	ui.start(ui.app(&"app", [ui.stack([ui.pressable(&"presses", {}, [ui.text("under")]).named(&"under"), over])]))
	await _a_frame_passes()
	var middle: Vector2 = (ui.node_named(&"under") as Control).get_global_rect().get_center()
	# the press down and up, where the window's pixels put that point
	for down: bool in [true, false]:
		var press := InputEventMouseButton.new()
		press.button_index = MOUSE_BUTTON_LEFT
		press.pressed = down
		press.position = root.get_final_transform() * middle
		press.global_position = press.position
		Input.parse_input_event(press)
		await _a_frame_passes()
	_verdict.check(model.told_actions == [&"presses"], "pressed in the middle of the window, under the grid, it was pressed: %s" % [model.told_actions])
	model.free()
	_made.done()
