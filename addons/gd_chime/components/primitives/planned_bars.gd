extends Control

## A planned's two scroll bars (planned.gd): each one shown where all of it
## is longer than the room on its axis, along its edge, its range what
## overflows; and the square where both meet, which this is, covered while
## both show, so nothing scrolled under it shows there - drawn in the down
## bar's track, after the bars, taking any press there from the pieces.
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


func _draw() -> void:
	draw_style_box(_down.get_theme_stylebox(&"scroll"), Rect2(Vector2.ZERO, size))
