extends "pressable.gd"

const Shift := preload("shift.gd")

## A slider's track: the band a value is drawn along, laid out beside the
## words of the value and over its reason, and the value at any point of it.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## It knows no hand: what moves the value, and when a command is sent, is the
## slider's (slider.gd), which extends this. Here is only where things stand
## and what is drawn. It draws the value it is handed to SHOW - a bound value,
## the model's, or the one a drag holds under the pointer - never a value of
## its own.
##
## WHAT IT HOLDS IS LAID OUT HERE, not across it as a face lays its content:
## the first part - the words of its value (formats.gd) - beside the track on
## its line, and the rest - the reason - under it, across the whole width.
## The track takes what the line leaves. It draws, over its state's ground,
## the look's track, the part of it filled up to the value and the handle,
## and the focus over them all. Every number - the handle's width, the
## track's thickness, the least its track is long, the gap before the words -
## is its style's, in the look.

var _shown: Bound  # the value it shows, read as it draws
var _at: Variant  # the value shown as last read, which the track is drawn at
var _minimum: float
var _maximum: float
var _step: float


func _init(chimes: Chimes, commands: Commands, place: Node, does: StringName, payload: Variant, shown: Bound, minimum: float, maximum: float, step: float, style: Variant) -> void:
	super(chimes, commands, place, does, payload, style)
	_shown = shown
	_minimum = minimum
	_maximum = maximum
	_step = step


## The value shown read as it draws, so what it read is followed; the track is drawn at it.
func refresh() -> void:
	_at = _shown.read()
	super()


func _notification(what: int) -> void:
	# attached before what it holds is built into it, it has nothing to arrange until then
	if what == NOTIFICATION_SORT_CHILDREN and get_child_count() > 0:
		_arrange()


## The value at this distance across: snapped to the step from the minimum, and held between the ends.
func _value_at(x: float) -> float:
	var band := _band()
	var handle := float(get_theme_constant(&"handle_width"))
	var along := (x - band.position.x - handle / 2.0) / (band.size.x - handle)
	return clampf(_minimum + snappedf(along * (_maximum - _minimum), _step), _minimum, _maximum)


## Where a value stands in the canvas: the point a press would hold that
## value at. PUBLIC because a hand aiming at a value has to aim somewhere,
## and where the handle rests is the track's own arithmetic.
func point_at(value: float) -> Vector2:
	return global_position + Vector2(_x_of(value), _band().get_center().y)


## Where the handle's middle stands for this value, across the band.
func _x_of(value: float) -> float:
	var band := _band()
	var handle := float(get_theme_constant(&"handle_width"))
	return band.position.x + handle / 2.0 + (value - _minimum) / (_maximum - _minimum) * (band.size.x - handle)


## The rect inside its box's padding.
func _inside() -> Rect2:
	var box := _box()
	return Rect2(Vector2(box.get_margin(SIDE_LEFT), box.get_margin(SIDE_TOP)), size - box.get_minimum_size())


## How tall the first line is: its words, or the track where that is thicker.
func _line() -> float:
	return maxf(get_child(0).get_combined_minimum_size().y, float(get_theme_constant(&"track_thickness")))


## The band the track is drawn in: the first line, but the words and the gap before them.
func _band() -> Rect2:
	var inside := _inside()
	var words: float = get_child(0).get_combined_minimum_size().x
	return Rect2(inside.position, Vector2(inside.size.x - words - get_theme_constant(&"gap"), _line()))


## The words beside the track, at the end of its line, and every other part under it, one below another.
func _arrange() -> void:
	var inside := _inside()
	var words: float = get_child(0).get_combined_minimum_size().x
	Shift.fit(self, get_child(0), Rect2(inside.end.x - words, inside.position.y, words, _line()))
	var below := inside.position.y + _line()
	# every part after the words that shows, under the line
	for part: Control in get_children().slice(1):
		if part.visible:
			below += get_theme_constant(&"gap")
			Shift.fit(self, part, Rect2(inside.position.x, below, inside.size.x, part.get_combined_minimum_size().y))
			below += part.get_combined_minimum_size().y


## The least track, the gap and the words across; the line and every part that shows under it down.
func _get_minimum_size() -> Vector2:
	# measured as it is attached, before what it holds is built into it
	if get_child_count() == 0:
		return super._get_minimum_size()
	var gap := float(get_theme_constant(&"gap"))
	var least := Vector2(get_theme_constant(&"least_track") + gap + get_child(0).get_combined_minimum_size().x, _line())
	# every part after the words that shows, each adding its height and a gap
	for part: Control in get_children().slice(1):
		if part.visible:
			least = Vector2(maxf(least.x, part.get_combined_minimum_size().x), least.y + gap + part.get_combined_minimum_size().y)
	return least + _box().get_minimum_size()


## Its state's ground, the track, the fill up to the value shown and the handle at it, then the focus over them.
func _draw() -> void:
	var whole := Rect2(Vector2.ZERO, size)
	var boxes := get_drawn()
	draw_style_box(boxes[0], whole)
	var band := _band()
	var thickness := float(get_theme_constant(&"track_thickness"))
	var handle := float(get_theme_constant(&"handle_width"))
	var track := Rect2(band.position.x, band.get_center().y - thickness / 2.0, band.size.x, thickness)
	var at := _x_of(float(_at))
	draw_style_box(get_theme_stylebox(&"track"), track)
	draw_style_box(get_theme_stylebox(&"fill"), Rect2(track.position, Vector2(at - track.position.x, thickness)))
	draw_style_box(get_theme_stylebox(&"handle"), Rect2(at - handle / 2.0, band.position.y, handle, band.size.y))
	# the focus ring, drawn last so nothing covers it
	for ring: StyleBox in boxes.slice(1):
		draw_style_box(ring, whole)
