extends RefCounted

const Motion := preload("../../motion.gd")
const Touch := preload("../../touch.gd")

## A finger on a scroll (scroll.gd): drawn along the way the scroll runs, it
## pans what the scroll holds under it, and let go moving, it glides on.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A GESTURE IS TAKEN ONLY WHERE IT CAN MOVE SOMETHING (touch.gd): along a
## way the scroll runs, and only while the scroll can go the way the finger
## pushes it - a list at its top lets a finger drawn down go past it to
## whatever holds it, a pull that refreshes it (pull.gd). Taken, the scroll
## follows the finger to the pixel, its bar's value moved by each move.
##
## LET GO MOVING, IT GLIDES ON on the one clock (motion.gd), easing out over
## as far as the finger's speed carries it for the look's GLIDE, a motion
## token in milliseconds, and no further than its ends; the finger taking
## it again stops it where it is. With motion reduced it never glides: it
## stops dead where the finger left it.
##
## Deliberately absent: a scroll pulled past its end that springs back.

var _scroll: ScrollContainer
var _motion: Motion
var _axis: StringName = &""  # the way the gesture it took goes
var _gliding: Motion.Run = null  # the glide on its way, or none


func _init(scroll: ScrollContainer, motion: Motion) -> void:
	_scroll = scroll
	_motion = motion


## Whether the scroll takes a gesture on this axis, gone this far: along a
## way it runs, and only where it can go the way the finger pushes it.
func takes(axis: StringName, travel: Vector2) -> bool:
	var bar: ScrollBar = _bar_for(axis)
	if bar == null:
		return false
	var pushed: float = -(travel.y if axis == Touch.DOWN else travel.x)
	var taken := (pushed < 0.0 and bar.value > bar.min_value) or (pushed > 0.0 and bar.value < bar.max_value - bar.page)
	if taken:
		_axis = axis
	return taken


## The finger moved: what the scroll holds follows it, and a glide on its way stops.
func moved(relative: Vector2) -> void:
	_stop()
	var bar: ScrollBar = _bar_for(_axis)
	bar.value -= relative.y if _axis == Touch.DOWN else relative.x


## The finger let go at this velocity: it glides on as far as the look's
## glide carries it, eased out - or, with motion reduced, stops dead.
func ended(velocity: Vector2) -> void:
	if _motion.get_reduced():
		return
	var bar: ScrollBar = _bar_for(_axis)
	var speed: float = velocity.y if _axis == Touch.DOWN else velocity.x
	var to := clampf(bar.value - speed * _motion.get_token(&"glide", _scroll) / 1000.0, bar.min_value, bar.max_value - bar.page)
	if is_equal_approx(to, bar.value):
		return
	_gliding = _motion.drive(bar, &"glide", bar.value, to, Motion.ENTER, bar.set_value)


## Whether a glide is on its way.
func is_gliding() -> bool:
	return _gliding != null and not _gliding.is_over() and not _gliding.stopped


## A glide on its way stopped where it is.
func _stop() -> void:
	if _gliding != null:
		_gliding.stopped = true
		_gliding = null


## The bar a gesture on this axis moves, or none where the scroll does not run that way.
func _bar_for(axis: StringName) -> ScrollBar:
	if axis == Touch.DOWN:
		return null if _scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED else _scroll.get_v_scroll_bar()
	return null if _scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED else _scroll.get_h_scroll_bar()
