extends RefCounted

const Motion := preload("../../motion.gd")
const Touch := preload("../../touch.gd")

## A finger on what scrolls - a scroll (scroll.gd), a text area's words
## (area.gd): drawn along the way it runs, it pans what is shown under it,
## and let go moving, it glides on.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A GESTURE IS TAKEN ONLY WHERE IT CAN MOVE SOMETHING (touch.gd): along a
## way it runs, and only while it can go the way the finger pushes it - a
## list at its top lets a finger drawn down go past it to whatever holds
## it, a pull that refreshes it (pull.gd). Taken, what is shown follows the
## finger, its bar's value moved by each move.
##
## IT MOVES IN ITS BARS' OWN STEPS: a pixel for a scroll, a line for a text
## area, which hands the finger over in lines, so either follows it to the
## pixel.
##
## LET GO MOVING, IT GLIDES ON on the one clock (motion.gd), easing out over
## as far as the finger's speed carries it for the look's GLIDE, a motion
## token in milliseconds, and no further than its ends; the finger taking
## it again stops it where it is. With motion reduced it never glides: it
## stops dead where the finger left it.
##
## Deliberately absent: a scroll pulled past its end that springs back.

var _on: Control  # what it scrolls, whose look says how far a glide goes
var _motion: Motion
var _down: Range  # the bar a gesture down moves, or none where it does not run down
var _across: Range  # the bar a gesture across moves, or none where it does not run across
var _axis: StringName = &""  # the way the gesture it took goes
var _gliding: Motion.Run = null  # the glide on its way, or none


func _init(on: Control, motion: Motion, down: Range, across: Range) -> void:
	_on = on
	_motion = motion
	_down = down
	_across = across


## Whether it takes a gesture on this axis, gone this far: along a
## way it runs, and only where it can go the way the finger pushes it.
func takes(axis: StringName, travel: Vector2) -> bool:
	var bar: Range = _bar_for(axis)
	if bar == null:
		return false
	var pushed: float = -(travel.y if axis == Touch.DOWN else travel.x)
	var taken := (pushed < 0.0 and bar.value > bar.min_value) or (pushed > 0.0 and bar.value < bar.max_value - bar.page)
	if taken:
		_axis = axis
	return taken


## The finger moved: what is shown follows it, and a glide on its way stops.
func moved(relative: Vector2) -> void:
	stop()
	var bar: Range = _bar_for(_axis)
	bar.value -= relative.y if _axis == Touch.DOWN else relative.x


## The finger let go at this velocity: it glides on as far as the look's
## glide carries it, eased out - or, with motion reduced, stops dead.
func ended(velocity: Vector2) -> void:
	if _motion.get_reduced():
		return
	var bar: Range = _bar_for(_axis)
	var speed: float = velocity.y if _axis == Touch.DOWN else velocity.x
	var to := clampf(bar.value - speed * _motion.get_token(&"glide", _on) / 1000.0, bar.min_value, bar.max_value - bar.page)
	if is_equal_approx(to, bar.value):
		return
	_gliding = _motion.drive(bar, &"glide", bar.value, to, Motion.ENTER, bar.set_value)


## Whether a glide is on its way.
func is_gliding() -> bool:
	return _gliding != null and not _gliding.is_over() and not _gliding.stopped


## A glide on its way stopped where it is: a finger taking it again, or its
## mark taken hold of (scroll_indicator.gd).
func stop() -> void:
	if _gliding != null:
		_gliding.stopped = true
		_gliding = null


## The bar a gesture on this axis moves, or none where it does not run that way.
func _bar_for(axis: StringName) -> Range:
	return _down if axis == Touch.DOWN else _across
