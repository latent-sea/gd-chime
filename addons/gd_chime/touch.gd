extends Node

const Look := preload("look.gd")
const Chimes := preload("chimes.gd")
const Motion := preload("motion.gd")
const MenuTarget := preload("components/primitives/menu_target.gd")

## A finger on the glass: the one reader of every touch, handing each
## gesture whole to the one thing that takes it - a scroll it pans, a row it
## swipes, a list it pulls - and nothing else.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE ENGINE ALREADY TURNS A FINGER INTO A MOUSE. Measured on 4.6.2 with the
## project's emulate_mouse_from_touch on, as it is by default: a touch
## reaches the control under it first as a left button from the device
## InputEvent.DEVICE_ID_EMULATION, then as itself; a drag first as that
## mouse's motion, then as itself. So everything that reads the mouse - a
## typed line, the engine's drag and drop, a slider, a grip - is used by a
## finger unchanged, and a press is a TAP (interaction.gd: from_finger()
## tells the two apart). What no mouse does is a GESTURE: a finger drawn
## across a thing to move it. That is this.
##
## A GESTURE BELONGS TO ONE THING. As a finger comes down, this notes the
## control it came down on - the engine's hovered control, which the
## emulated press has just moved there - and every thing holding it, nearest
## first, that TAKES A FINGER (the group TAKES, answering takes_finger(axis,
## travel), finger_moved(travel, relative) and finger_ended(velocity)). Once
## it has moved past the look's SLOP, the way it went first - ACROSS or DOWN,
## whichever it went further - is its axis for good, and the nearest of them
## that takes it on that axis has the whole gesture: every move and the
## lifting of the finger, in the canvas's own pixels, the velocity at the
## lift in pixels a second. A row takes across and lets down go past it to
## the scroll holding it; a scroll takes down only while it can move that
## way, so a list at its top lets a pull go past it to what pulls it. A
## gesture begun on a thing that HOLDS THE FINGER itself - a slider, a grip, a
## draggable: the group HOLDS - is left to it, and nothing else moves under it.
##
## A FINGER HELD STILL IS A LONG PRESS: on the phone there is no right
## button, so a finger that comes down inside a menu's target and stays
## within the slop for the look's long press, in milliseconds on the one
## clock, opens that target's menu where it is - the nearest target, as a
## right press finds it (menu_target.gd) - and rings HELD in the global
## region, for a sound or a buzz to answer; nothing here hangs it. The lift
## that follows taps nothing: measured on 4.6.2, the menu raised over the
## control takes it, and the control under the finger never hears it. Moved
## past the slop first, it is a gesture as ever; a long press of none turns
## it off.
##
## The first finger alone: a second is a pinch, which nothing here reads.
##
## Deliberately absent: a pinch, and a fling of its own - a thing that
## glides on is the thing's to move.

## The look's type holding how far a finger moves before it is a gesture, in base pixels.
const TYPE := &"Touch"
## The groups: what takes a gesture handed to it, and what reads the finger itself.
const TAKES := &"takes a finger"
const HOLDS := &"holds the finger"
## Everything pressed, which a compact window makes at least the look's least each way (pressable.gd).
const TARGETS := &"touch targets"
## The two ways a gesture goes.
const ACROSS := &"across"
const DOWN := &"down"
## How far back the velocity at the lift is read, in seconds.
const RECENT := 0.1
## The moment a finger held still opened a menu, rung in the global region.
const HELD := &"held"

## A finger on one control, read as a TAP or not (interaction.gd): landing
## is nothing yet, since it may be about to scroll or swipe; lifted over the
## control without ever having moved past the look's slop, it is a tap.
class Tap extends RefCounted:
	var _down: bool = false  # whether a finger is down on the control and has not moved past the slop
	var _from := Vector2.ZERO  # where it came down, in the control's own pixels

	## Whether a finger is down on the control and still within the slop.
	func is_down() -> bool:
		return _down

	## The finger's mouse on this control: whether it made a tap just now.
	func read(event: InputEvent, on: Control) -> bool:
		var click := event as InputEventMouseButton
		if click == null:
			# moving past the slop, it is a gesture, and no tap however it ends
			_down = _down and (event as InputEventMouse).position.distance_to(_from) <= on.get_theme_constant(&"slop", TYPE)
			return false
		if click.button_index != MOUSE_BUTTON_LEFT:
			return false
		var tapped := _down and not click.pressed and Rect2(Vector2.ZERO, on.size).has_point(click.position)
		_down = click.pressed
		_from = click.position
		return tapped


var _down: bool = false  # whether the first finger is on the glass
var _travel := Vector2.ZERO  # how far it has gone since it came down
var _axis: StringName = &""  # the way it went first, once past the slop
var _takers: Array = []  # what may take it, nearest first, as weak references
var _taken: WeakRef = null  # what has it, once one took it
var _recent: Array = []  # [time in seconds, the move] of its last moves, for the velocity
var _holding: Motion.Run = null  # the wait for a long press while the finger stays still, or none
var _held_on: WeakRef = null  # the target a long press would open, as the finger came down
var _at := Vector2.ZERO  # where the finger came down, on the canvas, while a long press waits
## The bells a long press rings on, and the one clock it is timed on: handed in by the builder.
var chimes: Chimes
var motion: Motion


## Whether an event came from a finger: the engine's mouse made from a touch.
static func from_finger(event: InputEvent) -> bool:
	return event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION


## How far a finger moves before it is a gesture, as the look on this
## control or window says.
static func slop(under: Object) -> float:
	return float(under.get_theme_constant(&"slop", TYPE))


## The axis of a gesture that has gone this far: none within the slop, else
## the way it went further, across on a tie.
static func axis_of(travel: Vector2, within: float) -> StringName:
	if travel.length() <= within:
		return &""
	return ACROSS if absf(travel.x) >= absf(travel.y) else DOWN


## What has the gesture now, or none.
func get_taken() -> Node:
	return null if _taken == null else _taken.get_ref()


func _input(event: InputEvent) -> void:
	var touched := event as InputEventScreenTouch
	if touched != null and touched.index == 0:
		if touched.pressed:
			_began()
			_hold(touched)
		else:
			_ended(touched.canceled)
		return
	var dragged := event as InputEventScreenDrag
	if dragged != null and dragged.index == 0 and _down:
		_moved(dragged.relative)


## The finger down: what it came down on, and every thing holding that which
## may take it, nearest first - none, if it came down on a thing holding the
## finger itself.
func _began() -> void:
	_down = true
	_travel = Vector2.ZERO
	_axis = &""
	_taken = null
	_recent.clear()
	_takers.clear()
	var at: Node = get_viewport().gui_get_hovered_control()
	_held_on = weakref(MenuTarget.nearest(at))
	# up from the control under the finger to the window, for what may take the gesture
	while at != null:
		if at.is_in_group(HOLDS):
			_takers.clear()
			_held_on = weakref(null)
			return
		if at.is_in_group(TAKES):
			_takers.append(weakref(at))
		at = at.get_parent()


## The finger moved: past the slop, its axis is set and the nearest that
## takes it on that axis has it; the one that has it is told every move.
func _moved(relative: Vector2) -> void:
	_travel += relative
	_recent.append([Time.get_ticks_usec() / 1000000.0, relative])
	if _axis == &"":
		_axis = axis_of(_travel, slop(Look.wearer(self)))
		if _axis == &"":
			return
		_let_hold_go()
		# nearest first, for the one that takes it on this axis
		for taker: WeakRef in _takers:
			var one: Node = taker.get_ref()
			if one != null and one.is_visible_in_tree() and one.takes_finger(_axis, _travel):
				_taken = taker
				break
	var holder := get_taken()
	if holder != null:
		holder.finger_moved(_travel, relative)


## The finger lifted, or the touch cancelled: the one that had it told, with
## the velocity of its last moves - none for a touch the system cancelled.
func _ended(canceled: bool) -> void:
	_down = false
	_let_hold_go()
	var holder := get_taken()
	_taken = null
	if holder == null:
		return
	var now := Time.get_ticks_usec() / 1000000.0
	var moved := Vector2.ZERO
	var since := now
	# the moves of the last moment, summed, and when the first of them came
	for one: Array in _recent:
		if now - one[0] <= RECENT:
			moved += one[1]
			since = minf(since, one[0])
	holder.finger_ended(Vector2.ZERO if canceled or now <= since else moved / maxf(now - since, 1.0 / 60.0))


## The finger down inside a menu's target, and the look holding a long
## press: where it is noted, and the wait for it begun.
func _hold(touched: InputEventScreenTouch) -> void:
	var target: Control = _held_on.get_ref()
	var lasts: int = Look.wearer(self).get_theme_constant(&"long_press", TYPE)
	if target == null or lasts <= 0:
		return
	# where it came down, on the canvas the window draws, as a right press on the target is placed
	_at = target.get_global_transform() * (target.make_input_local(touched) as InputEventScreenTouch).position
	_holding = motion.wait(lasts / 1000.0, _held)


## The finger stayed still as long as a long press lasts: the target's menu
## opened where it is, and the moment rung.
func _held() -> void:
	_holding = null
	var target: Node = _held_on.get_ref()
	if target == null or not target.is_visible_in_tree():
		return
	target.finger_held(_at)
	chimes.strike(Chimes.GLOBAL, HELD)


## No long press now: the finger moved past the slop, or lifted, first.
func _let_hold_go() -> void:
	if _holding != null:
		_holding.stopped = true
	_holding = null
