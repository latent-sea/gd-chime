extends SceneTree

## What must be true of pieces laid where a plan puts them: each piece
## stands at the plan's rect, its words at the plan's type size, and back
## at its kind's where the plan leaves it; asked again when the room moves;
## where all of it is taller than the room, the bar's room is set aside and
## the plan asked in what is left, the bar shown, and the pieces moved up
## as it scrolls by an arrow's step or a wheel's; where it then fits, no bar
## shows and no room is lost to one.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_planned.gd
##
## The floor's look: a bar 24 thick, a step of 40. The plan stacks its two
## pieces down the room's width, each `tall` high, so how high all of it is
## is a sum worked out by hand.

const Fixture := preload("res://tests/fixture.gd")
const Verdict := preload("res://tests/verdict.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Planned := preload("res://addons/gd_chime/planned.gd")

## The look's bar and step (theme_placeholders.gd).
const BAR := 24.0
const STEP := 40.0

var _verdict := Verdict.new()
var _asked: Array[Vector2] = []  # every room the plan was asked in, in turn


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(1600, 800)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_each_piece_stands_at_the_plan_s_rect_at_its_type_size)
	await _verdict.states(_taller_than_the_room_it_scrolls_with_the_bar_s_room_set_aside)
	await _verdict.states(_fitting_it_shows_no_bar_and_loses_no_room_to_one)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## A plain control of this size under the root, for a piece to be built into.
func _host(of: Vector2) -> Control:
	var host := Control.new()
	host.size = of
	root.add_child(host)
	return host


## Two pieces of words stacked down the room's width, each `tall` high, the first at type size `type`.
func _stacked(ui: RefCounted, tall: float, type: int) -> Desc:
	var plan := func(room: Vector2, _on: Control) -> Dictionary:
		_asked.append(room)
		return {"rects": [Rect2(0, 0, room.x, tall), Rect2(0, tall, room.x, tall)], "types": [type, 0], "size": Vector2(room.x, 2.0 * tall)}
	return ui.planned([ui.text("the first", Themes.WORDS).named(&"one"), ui.text("the second", Themes.WORDS).named(&"two")], plan, &"Planned").grow().named(&"planned")


## The label a text piece draws its words in.
func _words(piece: Control) -> Label:
	return Planned.labels_in(piece)[0]


func _each_piece_stands_at_the_plan_s_rect_at_its_type_size() -> void:
	var made := Fixture.new(root)
	var host := _host(Vector2(600, 400))
	_asked.clear()
	made.ui.build(_stacked(made.ui, 100.0, 37), host)
	await _a_frame_passes()
	var one: Control = made.ui.node_named(&"one")
	var two: Control = made.ui.node_named(&"two")
	_verdict.check(one.get_rect() == Rect2(0, 0, 600, 100) and two.get_rect() == Rect2(0, 100, 600, 100), "each piece at the plan's rect: %s and %s" % [one.get_rect(), two.get_rect()])
	_verdict.check(_words(one).get_theme_font_size(&"font_size") == 37, "the first's words at the plan's size, 37: %s" % _words(one).get_theme_font_size(&"font_size"))
	_verdict.check(not _words(two).has_theme_font_size_override(&"font_size"), "the second's left at its kind's size, the plan giving it none")
	host.size = Vector2(500, 400)
	await _a_frame_passes()
	_verdict.check(_asked.back() == Vector2(500, 400) and one.size.x == 500.0, "asked again in the room as it moves, and laid there: %s, %s" % [_asked.back(), one.size])
	host.free()
	made.done()


func _taller_than_the_room_it_scrolls_with_the_bar_s_room_set_aside() -> void:
	var made := Fixture.new(root)
	var host := _host(Vector2(600, 300))
	_asked.clear()
	made.ui.build(_stacked(made.ui, 200.0, 0), host)
	await _a_frame_passes()
	var planned: Control = made.ui.node_named(&"planned")
	var two: Control = made.ui.node_named(&"two")
	var down: ScrollBar = planned.bars()[0]
	_verdict.check(_asked.has(Vector2(600 - BAR, 300)) and two.size.x == 600 - BAR, "400 high in 300, the plan asked again 24 narrower, for the bar's room: %s; laid %s" % [_asked, two.size])
	_verdict.check(down.visible and down.get_rect() == Rect2(600 - BAR, 0, BAR, 300), "the bar shows down the right, 24 thick, the room's height: %s" % down.get_rect())
	down.value += down.custom_step
	await _a_frame_passes()
	_verdict.check(is_equal_approx(two.position.y, 200.0 - STEP), "an arrow's step moves the pieces up by 40: %s" % two.position)
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	planned._gui_input(wheel)
	planned._gui_input(wheel)
	planned._gui_input(wheel)
	await _a_frame_passes()
	_verdict.check(is_equal_approx(two.position.y, 200.0 - 100.0), "a wheel steps it on, and never past the end, 100 down: %s" % two.position)
	host.free()
	made.done()


func _fitting_it_shows_no_bar_and_loses_no_room_to_one() -> void:
	var made := Fixture.new(root)
	var host := _host(Vector2(600, 300))
	_asked.clear()
	made.ui.build(_stacked(made.ui, 150.0, 0), host)
	await _a_frame_passes()
	var planned: Control = made.ui.node_named(&"planned")
	var bars: Array = planned.bars().filter(func(bar: ScrollBar) -> bool: return bar.visible)
	_verdict.check(bars.is_empty() and _asked.all(func(room: Vector2) -> bool: return room == Vector2(600, 300)), "300 high in 300: no bar, and the plan only ever asked in the whole room: %s" % [_asked])
	host.free()
	made.done()
