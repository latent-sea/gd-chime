extends "pressable.gd"

## A grip: a thin edge the reader takes hold of to resize something - the
## sash between a split's two panes (split.gd), a column's edge in a
## table's heading - every move a command through the door.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## IT HOLDS NO SIZE. A move is dispatch(region, action, carries + {"by":
## how far it moved}) - carries naming what it resizes, as the model wants
## it - and whatever it resizes moves only when the model does. BY IS A
## SHARE OF THE LENGTH OF WHAT HOLDS THE GRIP, measured along the way it
## moves in that holder's own size, so a heading wider than the window
## scrolling across gets the share of its own width. A holder that answers
## get_placed_share() - a split - is asked it as a drag or a step begins,
## and the payload carries {"to": that share and every move since, held
## between nothing and all}: where the edge is being taken, so a model
## setting its share to it follows the pointer exactly, however often the
## holder places its parts, and never sticks past a pane's least size.
##
## EVERY HAND MOVES IT, AND NONE BY HOVERING. The pointer pressed on it and
## dragged carries it, wherever the pointer goes, until the release; with
## the focus on it, the arrows, the d-pad and the stick along the way it
## moves step it by the look's STEP, a share in thousandths, and are its
## own - the focus leaves it only across. Given a FOLDS action, accept and a
## double press dispatch that with carries - the pane beside it folded away
## or brought back; given none, they do nothing. It is a pressable in all
## else: its place declares its actions, and its states, focus and look are
## a pressable's under its style.
##
## How thick it is along the way it moves is the look's THICKNESS, in base
## pixels; across, it is as long as its holder makes it. DOWN, it moves up
## and down - the edge of a panel below; the pointer over it shows the
## engine's own resize shape for its way.

## Whether it moves up and down rather than across; a split sets it as it
## turns, and the pointer's shape over it follows.
var down: bool = false:
	set(turned):
		down = turned
		mouse_default_cursor_shape = Control.CURSOR_VSPLIT if turned else Control.CURSOR_HSPLIT
		update_minimum_size()

var _folds: StringName  # dispatched with carries by accept and a double press, or none
var _dragging: bool = false  # whether a press that began on it is held, so the pointer moving is a drag
var _to: float = 0.0  # where a holder that says its share is being taken, since the drag began


func _init(chimes: Chimes, commands: Commands, place: Node, does: StringName, carries: Dictionary, moves_down: bool, folds: StringName, style: Variant) -> void:
	super(chimes, commands, place, does, carries, style)
	_folds = folds
	down = moves_down
	# a finger drawn on it drags it, and nothing holding it moves under that
	add_to_group(Touch.HOLDS)


## Accept folds the pane beside it, when it was given the action to.
func pressed() -> void:
	if _folds != &"" and _commands.refusal(region, _folds, payload()) == null:
		_commands.dispatch(region, _folds, payload())


## A press on it and a drag carry it; along its way the keys and the pad
## step it; a double press folds. Anything else is a face's.
func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	var moved := event as InputEventMouseMotion
	if click != null and click.button_index == MOUSE_BUTTON_LEFT:
		_dragging = click.pressed and not click.double_click
		_to = _placed()
		if click.pressed and click.double_click:
			pressed()
		accept_event()
		return
	if moved != null and _dragging and moved.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_moved((moved.relative.y if down else moved.relative.x) / _length())
		accept_event()
		return
	var back := &"ui_up" if down else &"ui_left"
	var on := &"ui_down" if down else &"ui_right"
	if event.is_action_pressed(back, true) or event.is_action_pressed(on, true):
		_to = _placed()
		_moved((1.0 if event.is_action(on) else -1.0) * get_theme_constant(&"step") / 1000.0)
		accept_event()
		return
	super._gui_input(event)


## A move of this share of the holder's length through the door, unless it
## is none or the grip cannot be used; the answer kept for the reason to show.
func _moved(by: float) -> void:
	if is_zero_approx(by) or not is_usable():
		return
	var carried := payload().duplicate()
	carried["by"] = by
	if get_parent().has_method(&"get_placed_share"):
		_to = clampf(_to + by, 0.0, 1.0)
		carried["to"] = _to
	var answer := _commands.dispatch(region, action, carried)
	_keep_refusal(null if _commands.get_last()["paused"] else answer)
	needs_refresh()


## The share the holder has placed its edge at now, if it says one.
func _placed() -> float:
	return get_parent().get_placed_share() if get_parent().has_method(&"get_placed_share") else 0.0


## The holder's length along the way the grip moves, in its own size.
func _length() -> float:
	var holder: Control = get_parent()
	return maxf(1.0, holder.size.y if down else holder.size.x)


## As thick as the look says along its way, and nothing across it.
func _get_minimum_size() -> Vector2:
	var thick := float(get_theme_constant(&"thickness"))
	return Vector2(0.0, thick) if down else Vector2(thick, 0.0)


## The builder's door: a grip of the place being built into, carrying what its model wants named.
static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"grip").new(ui.chimes, ui.commands, ui.current_place(), desc.props["action"], desc.props["carries"], desc.props["down"], desc.props["folds"], desc.props["style"])
	made.prompts = ui.prompts
	ui.attach(made, parent, desc.facts)
	return made
