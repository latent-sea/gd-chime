extends Control

## A planned's two scroll bars (planned.gd): each one shown where all of it
## is longer than the room on its axis, along its edge, its range what
## overflows; and the square where both meet, which this is, covered while
## both show, so nothing scrolled under it shows there - drawn in the down
## bar's track, after the bars, taking any press there from the pieces. A
## wheel turned over the planned steps whichever bar shows that way (wheeled).
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.

var _down: ScrollBar  # the bar whose track it is drawn in


func _init(down: ScrollBar) -> void:
	_down = down
	mouse_filter = Control.MOUSE_FILTER_STOP


## The bars [down, across] shown for `all` in `room`, each stepping by `step`, and the corner shown while both are.
func ranged(bars: Array[ScrollBar], room: Vector2, all: Vector2, step: float, thickness: float) -> void:
	# each bar: shown where all of it is longer than the room that way, its range what overflows
	for axis: int in 2:
		var bar: ScrollBar = bars[1 - axis]
		bar.visible = all[axis] > room[axis] + 0.5
		bar.max_value = all[axis]
		bar.page = room[axis]
		bar.step = 0.0
		bar.custom_step = step
		bar.value = clampf(bar.value, 0.0, maxf(0.0, all[axis] - room[axis])) if bar.visible else 0.0
	visible = bars.all(func(bar: ScrollBar) -> bool: return bar.visible)
	position = room
	size = Vector2(thickness, thickness)


## A wheel's step on `down` or `across`: down or up, or across with shift or a sideways wheel, on whichever bar shows
## that way; whether it was taken.
static func wheeled(event: InputEvent, down: ScrollBar, across: ScrollBar) -> bool:
	var wheel := event as InputEventMouseButton
	if wheel == null or not wheel.pressed:
		return false
	var steps := {MOUSE_BUTTON_WHEEL_DOWN: 1.0, MOUSE_BUTTON_WHEEL_UP: -1.0, MOUSE_BUTTON_WHEEL_RIGHT: 1.0, MOUSE_BUTTON_WHEEL_LEFT: -1.0}
	if not steps.has(wheel.button_index):
		return false
	var sideways: bool = wheel.button_index in [MOUSE_BUTTON_WHEEL_RIGHT, MOUSE_BUTTON_WHEEL_LEFT] or wheel.shift_pressed or not down.visible
	var bar: ScrollBar = across if sideways else down
	if bar.visible:
		bar.value += steps[wheel.button_index] * bar.custom_step
	return bar.visible


func _draw() -> void:
	draw_style_box(_down.get_theme_stylebox(&"scroll"), Rect2(Vector2.ZERO, size))
