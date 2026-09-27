extends Node

const Inputs := preload("input_map.gd")
const Commands := preload("commands.gd")
const Driver := preload("driver.gd")

## The shortcuts: a key or a pad button pressed where nothing else took it,
## turned into a press of the action it is on.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A SHORTCUT IS A PRESS, NOT A SECOND WAY IN. What the input is on is the
## map's (input_map.gd); where the press lands is the same walk a reader makes
## with their eyes - THE NEAREST PLACE ON THE PATH THAT TAKES INPUT DECLARING
## THE ACTION, innermost first - so the tab's own is pressed and not the
## screen's behind it, and the region the command runs in is that place's
## name, exactly as a click in it would be. Of several actions on one input -
## every pop-up's way out and the app's own Back on Escape - the first one a
## place on that path declares is pressed. A place on no top path declares
## nothing that can be pressed this way, and a press of an action nothing on
## the screen declares does nothing at all.
##
## IT PRESSES THROUGH THE BUTTON. The control drawing the action under that
## place is found and its own pressed() is called, so everything a click gets
## it gets: the door asked again as the press lands, the refusal kept on that
## control and drawn on its face where its button is, and the look following.
## Nothing of the door's is written twice here. Where no control draws the
## action - a place that performs it with no button of its own - the door is
## dispatched at that place with an empty payload.
##
## A PAYLOAD IS WHAT A PRESS IS ABOUT, and an input has none: a row's button
## carries which row, and no key can say which. Such a control is said out
## loud and left alone, rather than pressed about the wrong row in silence.
##
## THE EVENT COMES TO THIS NODE BECAUSE IT IS ONE. Unhandled input is what the
## engine has offered to everything else first, so a line being typed into and
## a binding waiting for the next key have already taken it and no shortcut
## fires under them - which is the whole reason it is heard here and not
## wherever else an event could be seen. Every key and button is also seen as
## it arrives, handled or not, to say which device the player is on: what
## they are typing on is still what they are holding.
##
## THE CANCEL KEY IS NEVER TYPED. A line being typed into takes Escape for
## itself - it stops editing - so a pop-up whose line has the focus, the
## command palette's, could never be closed from the keyboard. So Escape,
## arriving while a line or an area has the focus, is pressed here before the
## line sees it, when the map puts an action on it that a place on the top
## path declares; with none, the line has it as before.
##
## Deliberately absent: a shortcut for a local press, which has no action and
## so has no input in the map; a chord; and any look of its own.

var _map: Inputs
var _driver: Driver
var _commands: Commands


func _init(map: Inputs, moves: Driver, door: Commands) -> void:
	_map = map
	_driver = moves
	_commands = door


## Every key and pad button as it arrives, whatever takes it: which device the
## player is on now.
func _input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	var input := Inputs.of_event(event)
	if not input.is_empty():
		_map.used(input)
	# the cancel key, while a line or an area is being typed into: pressed before the line takes it
	var typing := get_viewport().gui_get_focus_owner()
	if event.is_action(&"ui_cancel") and (typing is LineEdit or typing is TextEdit):
		_unhandled_input(event)


## A press nothing else took: the action its input is on, pressed in the
## nearest place on the top path that declares it.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	# every action the input is on, for the first a place on the top path declares
	for action: StringName in _map.get_actions(Inputs.of_event(event)):
		var place := _nearest(action)
		if place != null:
			get_viewport().set_input_as_handled()
			_press(place, action)
			return


## The place nearest the reader on the path that takes input which declares
## the action; nothing when none of them does.
func _nearest(action: StringName) -> Node:
	var top := _driver.get_top()
	# the top path innermost first, for the first place declaring the action
	for step: int in range(top.size() - 1, -1, -1):
		var place: Node = _driver.index.place_named(top[step])
		if place.performs.has(action):
			return place
	return null


## The action pressed as a click would press it: through the control drawing
## it, so a refusal lands on that control's face; through the door itself
## where nothing draws it; and not at all where the press would carry what no
## input can say.
func _press(place: Node, action: StringName) -> void:
	var control: Node = _driver.index.drawn_by(place, action)
	if control == null:
		_commands.dispatch(place.name, action, {})
		return
	if not control.payload().is_empty():
		push_error("%s carries what its press is about, so no input can press it" % action)
		return
	control.pressed()
