extends "stack.gd"

const Chimes := preload("../../chimes.gd")
const Commands := preload("../../commands.gd")
const Bound := preload("bound.gd")
const Nearness := preload("nearness.gd")

## What it holds, pressing an action through the door as the reader nears
## it: the foot of an infinite collection asking for the next page before
## the reader reaches the end.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## It presses once each time it is found near (nearness.gd) where it was
## not pressed before: coming near, and - still near - moved on through
## what its scroll holds, as a page landing above it pushes it down. So the
## reader scrolling to and fro over it asks nothing more. A press REFUSED -
## still loading - is pressed again, while it is near, as the refusal may
## have moved: on whatever the action's refusal read, followed as a button
## follows what its refusal read. So a window tall enough to show a page's
## end asks page after page until it no longer can.
## What it holds is the caller's: a press of the same action, so the keys,
## the pad and a reader who wants to can ask for it too - nothing is
## reached by scrolling alone.
##
## Deliberately absent: pressing as it goes away.

var _chimes: Chimes
var _commands: Commands
var _region: StringName
var _action: StringName
var _payload: Variant  # a dictionary, or a bound value read as it presses
var _near: Nearness
var _pressed_at: Variant = null  # where in its scroll's content it last pressed, or null
var _refused: bool = false  # whether that press was refused


func _init(chimes: Chimes, commands: Commands, action: StringName, payload: Variant, in_region: StringName) -> void:
	super()
	_chimes = chimes
	_commands = commands
	_action = action
	_payload = payload
	_region = in_region
	_near = Nearness.new(self, func(_near_now: bool) -> void: _press_if_new())


## Its scroll moved or placed what it holds: near again or not, and pressed if it is somewhere new.
func near_moved() -> void:
	_near.check()
	_press_if_new()


## The refusal asked, so what it read is followed; moved once this is ready,
## a refused press, still near, pressed again - once the bell's own command
## is over, since nothing dispatches from inside one.
func _refusal_moved() -> void:
	_commands.refusal(_region, _action, _payload.read() if _payload is Bound else _payload)
	if is_node_ready():
		_retry.call_deferred()


func _retry() -> void:
	if not _refused or not is_inside_tree():
		return
	_near.check()
	if _near.is_near():
		_press()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE:
			# what the action's refusal reads, followed while this stands
			_chimes.follow(self, &"refusal", _refusal_moved)
			_near.entered.call_deferred()
		NOTIFICATION_EXIT_TREE:
			_chimes.stop_all(self)
			_near.left()
		NOTIFICATION_VISIBILITY_CHANGED: _near.check()


## Near, and somewhere in its scroll it has not pressed from: pressed.
func _press_if_new() -> void:
	if not _near.is_near():
		_pressed_at = null
		return
	if _near.get_place() != _pressed_at:
		_press()


func _press() -> void:
	_pressed_at = _near.get_place()
	_refused = _commands.dispatch(_region, _action, _payload.read() if _payload is Bound else _payload) != null


static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"nearing").new(ui.chimes, ui.commands, desc.props["action"], desc.props["payload"], ui.region())
	ui.attach(made, parent, desc.facts)
	return made
