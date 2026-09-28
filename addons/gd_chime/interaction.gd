extends Container

const Touch := preload("touch.gd")

## What a person does to a control - with a mouse, a key or a pad: each arrives
## at one method named for what happened.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## presentation.gd extends this, so every screen has these hooks, and a
## subclass overrides only the ones it cares about. Deciding which control an
## event was for is the engine's - hit-testing for the pointer, focus for keys
## and the pad - and this is the only place in the folder that reads an event.
##
## A press is the left button going DOWN, or the accept action going down on the
## control with focus: Enter and Space, and whatever else the project's input
## map adds. Measured on 4.6.2, the engine's own accept action holds no pad
## button, so a pad presses nothing until the map adds one, while its directions
## already hold the d-pad and the left stick. The keyboard's own repeats press
## nothing, and neither does any other mouse button. The wheel is
## scrolled(steps), downward when positive, one step an event. The pointer
## arriving and leaving is hovered(inside).
##
## A control whose builder calls repeat_while_held(wait, interval) is pressed
## again while a press is held: after wait seconds, then every interval seconds,
## until the press ends. The control counts the time down itself, so a mouse
## button, a key and a pad repeat alike; a pad button never repeats by itself,
## measured. A press ends at its release. The release of a mouse press comes
## back to the control that took it, wherever the pointer has gone, but a key's
## release goes to whichever control has focus by then - both measured - so the
## repeat also ends when focus leaves, and when the control leaves the tree,
## where no release can reach it. A control that never asks is pressed once,
## however long it is held.
##
## focused(shown) is focus starting or stopping showing on this control. Focus a
## key or the pad walked to shows. Focus a click gave is held but hidden, so the
## accept action still presses the control and nothing is drawn. A click on the
## control that already had focus hides it with no focus notification, only a
## redraw - measured - so whether focus shows is asked on every redraw as well,
## and told only when it changes. A control takes focus only if it sets its own
## focus_mode, and whoever builds a screen gives the first focus.
##
## WHERE an arrow or the pad takes focus is the engine's as well, and it answers
## by GEOMETRY: the nearest control in that direction from where things actually
## ended up. Measured on 4.6.2: in a row of two columns it crosses from one
## column into the other, however deeply either is nested; in a line of four
## that wraps when the window narrows, down reaches the part the wrap put
## underneath, where in a wide window it had reached nothing; and focus stays on
## the control it was on through a resize and travels with it. So a layout that
## moves its parts moves the walk with them, and no screen declares an order -
## which is why nothing in this folder computes one.
##
## Focus can walk to a part scrolled out of sight: whatever scrolls brings the
## focused part into view (scroll.gd).
##
## A FINGER'S PRESS IS A TAP. The engine hands a touch here as a mouse of its
## own (touch.gd): landing, it presses nothing, since the finger may be about to
## scroll or swipe; lifted over the control without having moved past the
## look's slop, it presses and lets go at once; moved further, it is a gesture
## and presses nothing. Lifted anywhere, it leaves no hover behind. The hand
## DOWN on it is held_down(down), a finger's from landing to its lift or gesture.
##
## Anything that renders takes mouse events by default, so a screen that must
## not intercept a click sets its own mouse_filter to ignore.
##
## This is the engine's Container, not a bare Control, for one reason: a
## Container is told when a part inside it needs more room - words arriving
## in a label after the build - and tells whatever holds it, up to the layout
## that places it. A bare Control is told nothing, and a button whose words
## arrive late keeps no width. Nothing here sorts children; a container's
## own default takes no press, so this sets the stop a control needs.
##
## The engine calls every level's _notification, parent first - measured on
## 4.6.2 - so this answers the pointer, focus, leaving the tree and its own
## count-down, the level above answers its own, and nothing is passed on. The
## count-down runs on the engine's internal process, and only while a press is
## held, because presentation.gd owns _process and only the chimes connect a
## signal.
##
## THREE OF THESE MOMENTS ARE ALSO BELLS, for whatever watches what a person
## does without being one of the controls it happens to: the pointer arriving,
## focus starting to show, and a press landing. They are named here, where the
## moments are, and rung by the level that holds the chimes, which this does
## not - face.gd. A press rings AFTER the control has done what a press does,
## so whatever a press dispatched has already run and been answered by the time
## the moment sounds, and the control's own answer can be read. A HELD PRESS
## THAT REPEATS RINGS ONCE, as it lands: the repeats are the same hand still
## down, and a moment per repeat would make a held button tick.
##
## WHICH CONTROL A PRESS LANDED ON is kept here, because a bell carries nothing
## and where the focus is is not the answer: a control built to take no focus is
## pressed without ever holding it, and a press with the pointer reaches one the
## focus never touches. It is one control at a time for the whole application -
## there is one hand - and it is held WEAKLY, so a screen freed since is not
## kept alive by having been pressed.
##
## Deliberately absent, each a pure addition: the right button, double clicks,
## a repeat that pauses while the pointer is off the control or speeds up the
## longer it is held, and a text field's focus, which must show even after a
## click.

## The moments a person's hand makes, each hung in the global region by
## whatever listens for them (sounds.gd). A bell carries nothing: whoever
## hears one reads the viewport for the control it was about.
const HOVERED := &"hovered"
const FOCUS_MOVED := &"focus_moved"
const PRESSED := &"pressed"

## The control the last press landed on, held weakly and shared by every one
## of these: there is one hand.
static var _pressed_on: WeakRef = weakref(null)

var _focus_shown := false  # whether focus showed here when this control was last told
var _repeat_wait := 0.0
var _repeat_interval := 0.0  # none until the control asks to repeat
var _repeat_left := 0.0  # seconds to the next repeat, while a press is held
var _tap := Touch.Tap.new()  # a finger on this, read as a tap or a gesture


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_MOUSE_ENTER:
			hovered(true)
			_ring(HOVERED)
		NOTIFICATION_MOUSE_EXIT: hovered(false)
		NOTIFICATION_FOCUS_ENTER, NOTIFICATION_DRAW: _follow_focus()
		NOTIFICATION_FOCUS_EXIT:
			_let_go()
			_follow_focus()
		NOTIFICATION_EXIT_TREE: _let_go()
		NOTIFICATION_INTERNAL_PROCESS: _count_down()


## The engine hands a control the input it decided was for it.
func _gui_input(event: InputEvent) -> void:
	# the accept action: Enter, Space, and whatever the project's input map adds
	if event.is_action("ui_accept"):
		if not event.is_echo():
			_press(event.is_pressed())
		accept_event()
		return
	if Touch.from_finger(event):
		var was_down := _tap.is_down()
		# a tap presses and lets go at once, and a finger lifted leaves no hover
		if _tap.read(event, self):
			_press(true)
			_press(false)
		# landing, the hand is down on it; lifted, or gone past the slop into a gesture, it is not
		if _tap.is_down() != was_down:
			held_down(_tap.is_down())
		if event is InputEventMouseButton and not event.is_pressed():
			hovered(false)
		return
	var click := event as InputEventMouseButton
	if click == null:
		return
	if click.button_index == MOUSE_BUTTON_LEFT:
		held_down(click.pressed)
		_press(click.pressed)
	elif click.pressed and click.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		scrolled(1)
	elif click.pressed and click.button_index == MOUSE_BUTTON_WHEEL_UP:
		scrolled(-1)


## A hand down on this control or lifted - a pointer's button, or a finger
## until it lifts or becomes a gesture - whatever a press then does. Overridden.
func held_down(_down: bool) -> void:
	pass


## Be pressed again while a press is held: after wait seconds, then every
## interval seconds, until the press ends. Called by whoever builds the control.
func repeat_while_held(wait: float, interval: float) -> void:
	_repeat_wait = wait
	_repeat_interval = interval


## A press starting or ending, from the left button or the accept action.
func _press(down: bool) -> void:
	if not down:
		_let_go()
		return
	# a control that asked to repeat starts counting down to its first repeat
	if _repeat_interval > 0.0:
		_repeat_left = _repeat_wait
		set_process_internal(true)
	# what the control does, and THEN the moment: a press that dispatched has been answered by the time anything hears it
	pressed()
	_pressed_on = weakref(self)
	_ring(PRESSED)


## A frame of a held press: pressed again each time the count runs out.
func _count_down() -> void:
	_repeat_left -= get_process_delta_time()
	if _repeat_left > 0.0:
		return
	_repeat_left = _repeat_interval
	# a repeat is the same hand still down: it presses again and rings nothing, so a held button does not tick
	pressed()


## The control the last press landed on, for whoever heard the moment.
static func get_pressed() -> Control:
	return _pressed_on.get_ref()


## The press ended, or no release can reach this any more: the count-down stops.
func _let_go() -> void:
	set_process_internal(false)


## Tell the control, when whether its focus shows has changed.
func _follow_focus() -> void:
	# true only while focus shows: focus a click gave is held but hidden
	var shown := has_focus(true)
	if shown == _focus_shown:
		return
	_focus_shown = shown
	focused(shown)
	# the moment is focus arriving somewhere, so focus leaving here rings nothing: it is about to show elsewhere
	if shown:
		_ring(FOCUS_MOVED)


## A moment rung, by the level that holds the chimes. Nothing here does, so a
## control built straight on this rings nothing at all.
func _ring(_moment: StringName) -> void:
	pass


## Overridden by a subclass that can be pressed.
func pressed() -> void:
	pass


## The wheel turned this many steps, downward when positive.
func scrolled(_steps: int) -> void:
	pass


## The pointer arriving at or leaving this control.
func hovered(_inside: bool) -> void:
	pass


## Focus starting to show on this control, or stopping.
func focused(_shown: bool) -> void:
	pass
