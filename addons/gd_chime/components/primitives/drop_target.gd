extends "pressable.gd"

const Carried := preload("../../carried.gd")
const CarryWalk := preload("carry_walk.gd")
const Going := preload("going.gd")

## Somewhere a carried thing can be dropped: an action control whose action
## is dispatched with whatever was dropped on it - and, standing for a list,
## with where among the list it landed.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A DROP IS AN ORDINARY COMMAND. Its place declares the action like any
## other; the door is asked refusal(region, action, the CARRIED payload)
## while something is over it, and a drop dispatches that same address with
## that same payload. What a drop MEANS is the model's, and never reaches
## this.
##
## A LIST TARGET stands for a list - a column of a board - named by INTO,
## and holds the keyed each that shows it. Over it, what is carried would
## land at a place among the pieces it shows, the carried one and any going
## left out: before the first piece whose middle lies past the pointer. It
## moves the carry's over there (carried.gd), so the list shows the thing
## where it would land (lane.gd), and a drop carries {into, at} beside the
## payload - one command, whatever the list shows, the model reading the
## place against the same narrowing the reader sees. A piece of the list
## that is dropped on hands the drop to this (draggable.gd).
##
## Its states, over the face's: ACCEPTING while what is carried is over it
## and the door would take it, REFUSING while the door would not - and the
## refusal is a sentence its content can show (ui.reason()), never a colour
## alone - and otherwise normal. Over it means under the pointer or focused,
## or, for a list target, that the carry would land in its list. It is never
## inert and never current: a target with nothing being carried is not a
## control that cannot be used, it is a target with nothing to take.
##
## It extends a pressable so its look, its blending and the reason bound to
## it are the ones every other action control has. A press of it does
## nothing: a target is used by what is dropped on it, not by being clicked.
##
## THE MOUSE IS THE ENGINE'S OWN drag and drop: _can_drop_data answers the
## door and _drop_data does the drop. What arrives there came out of another
## control's drag and is the one thing in this folder that is genuinely
## unknown, so it is checked before it is read. THE DROP IS DISPATCHED
## BEFORE THE CARRY IS SET DOWN: the model moves the thing to where it is
## already shown, and setting the carry down after changes nothing drawn - a
## thing dropped is never seen to go back and come again. THE PAD AND THE
## KEYBOARD CARRY IT TOO (carry_walk.gd).

var _carried: Carried
var _into: Variant  # the list this stands for, or null for a target that is no list's
var _list: Control = null  # the keyed each showing the list, found once it is built


func _init(chimes: Chimes, commands: Commands, place: Node, does: StringName, carried: Carried, style: Variant, into: Variant = null) -> void:
	_carried = carried
	_into = into
	super(chimes, commands, place, does, {}, style)
	add_to_group(CarryWalk.TARGET)
	# a list's pieces take the focus, and a carry from it keeps the focus on the thing carried: the list itself is walked past
	if is_list():
		focus_mode = Control.FOCUS_NONE


## Whether this stands for a list.
func is_list() -> bool:
	return _into != null


## The list this stands for.
func get_into() -> Variant:
	return _into


## What a drop carries: whatever is being carried now - and, for a list,
## where among it it would land - so the door is asked about the thing over
## it and never about this control.
func payload() -> Dictionary:
	if not is_list():
		return _carried.get_payload()
	var over := _carried.get_over()
	var landing: Dictionary = _carried.get_payload().duplicate()
	landing["into"] = _into
	landing["at"] = over["at"] if over.get("into") == _into else count_shown()
	return landing


## Whether what is carried is over this one: under the pointer or focused
## - or, for a list, landing in it.
func is_taking_it() -> bool:
	if is_list():
		return _carried.is_carrying() and _carried.get_over().get("into") == _into
	return _carried.is_carrying() and (_lit or _focused)


func get_state() -> StringName:
	if not is_taking_it():
		return &"hover" if _lit else &"normal"
	return &"accepting" if is_usable() else &"refusing"


## Why it would refuse what is over it, for its content to show; nothing
## while it would take it, and nothing while nothing is over it.
func reason() -> Bound:
	return Bound.new(func() -> Variant: return get_reason() if is_taking_it() and not is_usable() else null, self)


## A press does nothing: a target is used by what is dropped on it.
func pressed() -> void:
	pass


## The drop: the action dispatched with what was carried, in this control's
## own region, and then the carry set down. Refused, nothing runs and it is
## carried still.
func drop() -> void:
	if not is_usable():
		return
	_keep_refusal(_commands.dispatch(region, action, payload()))
	_carried.put_down()
	needs_refresh()


## --- a list's places ---

## Whether a direction runs along the list, as a step within it, rather than across it.
func runs_along(side: Side) -> bool:
	return (side == SIDE_LEFT or side == SIDE_RIGHT) == _each().is_row()


## How many pieces the list shows, the carried one and any going left out.
func count_shown() -> int:
	return _shown().size()


## The place among what the list shows that a thing let go at this point,
## on the canvas, would land at: before the first piece whose middle lies
## past it along the list.
func lands_at(point: Vector2) -> int:
	var along := 0 if _each().is_row() else 1
	var at := 0
	# every piece shown, in order, for the first whose middle lies past the point
	for piece: Control in _shown():
		if piece.get_global_rect().get_center()[along] > point[along]:
			return at
		at += 1
	return at


## The place among what the list shows of the piece holding this node.
func place_of(node: Node) -> int:
	var piece: Node = node
	# up from the node to the piece of the list that holds it
	while piece.get_parent() != _each():
		piece = piece.get_parent()
	return _shown().find(piece)


## The engine's drag at this point on the canvas, over this list or a piece
## of it: where it would land moved there, and whether the door would take it.
func takes_at(point: Vector2, data: Variant) -> bool:
	if not (data is Dictionary and (data as Dictionary).has("payload")) or not _carried.is_carrying():
		return false
	if is_list():
		_carried.move_over(_into, lands_at(point))
	needs_refresh()
	return _commands.refusal(region, action, payload()) == null


## The pieces the list shows: shown, not going, and not the one carried.
func _shown() -> Array:
	var lifted: Array = get_tree().get_nodes_in_group(CarryWalk.LIFTED)
	return _each().get_children().filter(func(piece: Node) -> bool: return piece is Control and (piece as Control).visible and not Going.is_going(piece) and not lifted.any(func(one: Node) -> bool: return piece == one or piece.is_ancestor_of(one)))


## The keyed each showing the list: the first inside this.
func _each() -> Control:
	if _list == null:
		_list = find_children("*", "Container", true, false).filter(func(inside: Node) -> bool: return inside.has_method(&"piece_for"))[0]
	return _list


## While something is carried with no list, accept drops it here and cancel
## and the directions walk the carry; everything else, and everything at
## rest, is the face's.
func _gui_input(event: InputEvent) -> void:
	if _carried.is_carrying() and not is_list():
		if event.is_action_pressed(&"ui_accept"):
			accept_event()
			drop()
			return
		if CarryWalk.walked(self, event, _carried):
			accept_event()
			return
	super._gui_input(event)


## Focused while something is carried, it brings itself into view: a scroll
## it sits in moves, so the reader sees what they are about to drop on.
func focused(shown: bool) -> void:
	super.focused(shown)
	if shown and _carried.is_carrying():
		_into_view()


func _into_view() -> void:
	var above: Node = get_parent()
	# up through whatever holds it, to the first scroll that could have it out of sight
	while above != null:
		if above is ScrollContainer:
			(above as ScrollContainer).ensure_control_visible(self)
			return
		above = above.get_parent()


## The engine, asking whether the drag under the pointer could be dropped
## here. Asked again on every move, so the look and the landing follow it.
func _can_drop_data(at: Vector2, data: Variant) -> bool:
	return takes_at(get_global_transform() * at, data)


## The engine, saying the drag was released here. What it hands over is what
## the carry holds - the draggable put it in both as it was lifted - so the
## drop reads the one truth.
func _drop_data(_at: Vector2, _data: Variant) -> void:
	drop()


## The builder's door: a drop target of the place being built into, for an
## action that place declares, handed the one carry, standing for a list if
## described so.
static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"drop_target").new(ui.chimes, ui.commands, ui.current_place(), desc.props["action"], desc.props["carried"], desc.props["style"], desc.props.get("into"))
	made.prompts = ui.prompts
	ui.attach(made, parent, desc.facts)
	return made
