extends "slider_track.gd"

const Local := preload("local.gd")

## A range slider: a stretch between two handles along a track - a price
## from least to most - every change a command through the door carrying
## {"value": Vector2(least, most)}.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A SLIDER WITH TWO ENDS (slider.gd), and like it IT HOLDS NO VALUE: the
## stretch is the model's, a bound value, and the handles rest only where
## it is. Where things stand, the track and the band are its track's
## (slider_track.gd); here the two ends are drawn, the track filled between
## them, and the hands move them.
##
## A DRAG IS ONE COMMAND: a press in the track takes the NEARER END and
## holds the stretch with that end under the pointer, following it - in a
## local, through no door - and the release sends it once. An end never
## passes the other: dragged past it, it stops there.
##
## THE KEYS AND THE PAD MOVE ONE END AT A TIME: left and right step the end
## being moved - the least, as it is first reached - by the step, and
## accept turns to the other end; that end is drawn ringed while this has
## the focus, and said in words, "moving the least" - never by the ring
## alone. It is never a trap: up and down, Tab and the rest walk on.
##
## Deliberately absent: more than two ends, and a stretch dragged whole.

## Which end the keys move, by its place in the stretch.
const LEAST := 0
const MOST := 1

var _value: Bound  # the model's stretch, read as a change is worked out
var _held: Local  # the stretch a drag holds while the pointer is down, null while none is
var _moving: Local  # which end the keys move and a drag holds: LEAST or MOST


func _init(chimes: Chimes, commands: Commands, place: Node, does: StringName, value: Bound, held: Local, moving: Local, shown: Bound, minimum: float, maximum: float, step: float, style: Variant) -> void:
	super(chimes, commands, place, does, value.map(func(now: Variant) -> Dictionary: return {"value": now}), shown, minimum, maximum, step, style)
	_value = value
	_held = held
	_moving = moving


## Which end the keys move read as it draws too, so it is followed: the handle at it is drawn apart.
func refresh() -> void:
	_moving.read()
	super()


## The stretch as the model has it now.
func get_value() -> Vector2:
	return _value.read()


## Which end the keys move now: LEAST or MOST.
func get_moving() -> int:
	return _moving.read()


## A press of accept is the input's: it turns to the other end.
func pressed() -> void:
	pass


## The pointer takes the nearer end and drags it, the release sends; left
## and right step the end being moved, accept turns to the other.
func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	var moved := event as InputEventMouseMotion
	if click != null and click.button_index == MOUSE_BUTTON_LEFT:
		if click.pressed and _band().has_point(click.position) and is_usable():
			var at := _value_at(click.position.x)
			var now := get_value()
			_moving.set_value(MOST if absf(at - now.y) < absf(at - now.x) or (at > now.y) else LEAST)
			_hold(_with(now, at))
		elif not click.pressed and _held.read() != null:
			var released: Vector2 = _held.read()
			_hold(null)
			_change_to(released)
	elif moved != null and _held.read() != null and moved.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_hold(_with(_held.read(), _value_at(moved.position.x)))
		accept_event()
		return
	elif event.is_action_pressed(&"ui_left", true) or event.is_action_pressed(&"ui_right", true):
		var now := get_value()
		var towards := _step if event.is_action(&"ui_right") else -_step
		_change_to(_with(now, now[_moving.read()] + towards))
		accept_event()
		return
	elif event.is_action_pressed(&"ui_accept"):
		_moving.set_value(MOST - _moving.read())
		needs_refresh()
		accept_event()
		return
	super._gui_input(event)


## The stretch with the end being moved at this value, snapped, held within the track and never past the other end.
func _with(stretch: Vector2, at: float) -> Vector2:
	var snapped := clampf(_minimum + snappedf(at - _minimum, _step), _minimum, _maximum)
	return Vector2(minf(snapped, stretch.y), stretch.y) if _moving.read() == LEAST else Vector2(stretch.x, maxf(snapped, stretch.x))


func _hold(stretch: Variant) -> void:
	_held.set_value(stretch)
	needs_refresh()


## A new stretch through the door, unless it is the model's already or this cannot be used.
func _change_to(stretch: Vector2) -> void:
	if stretch == get_value() or not is_usable():
		return
	var answer := _commands.dispatch(region, action, {"value": stretch})
	_keep_refusal(null if _commands.get_last()["paused"] else answer)
	needs_refresh()


## Its state's ground, the track, the fill between the two ends and a handle at each - the one being moved ringed while the focus shows.
func _draw() -> void:
	var boxes := get_drawn()
	draw_style_box(boxes[0], Rect2(Vector2.ZERO, size))
	var band := _band()
	var thickness := float(get_theme_constant(&"track_thickness"))
	var handle := float(get_theme_constant(&"handle_width"))
	var track := Rect2(band.position.x, band.get_center().y - thickness / 2.0, band.size.x, thickness)
	var stretch: Vector2 = _at
	var ends := [_x_of(stretch.x), _x_of(stretch.y)]
	draw_style_box(get_theme_stylebox(&"track"), track)
	draw_style_box(get_theme_stylebox(&"fill"), Rect2(ends[0], track.position.y, ends[1] - ends[0], thickness))
	# each end's handle, the one the keys move ringed while the focus shows
	for end: int in 2:
		var at := Rect2(ends[end] - handle / 2.0, band.position.y, handle, band.size.y)
		draw_style_box(get_theme_stylebox(&"handle"), at)
		if boxes.size() > 1 and end == _moving.read():
			draw_style_box(boxes[1], at)


## The builder's door: a range slider of the place being built into.
static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"range_slider").new(ui.chimes, ui.commands, ui.current_place(), desc.props["action"], desc.props["value"], desc.props["held"], desc.props["moving"], desc.props["shown"], desc.props["minimum"], desc.props["maximum"], desc.props["step"], desc.props["style"])
	made.prompts = ui.prompts
	ui.attach(made, parent, desc.facts)
	return made
