extends "../../face.gd"

const Carried := preload("../../carried.gd")
const Commands := preload("../../commands.gd")
const CarryWalk := preload("carry_walk.gd")

## Something a reader can pick up and drop somewhere else: a face, focused
## and drawn like any other, that hands what it carries to whatever takes it
## - and, described with an action, is pressed as well as carried.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE MOUSE IS THE ENGINE'S OWN drag and drop. The engine asks this for the
## data as a press is dragged (_get_drag_data), carries the preview under
## the pointer, asks each control beneath it whether it would take it, and
## ends the drag itself - on a drop, on a release over nothing, and on
## Escape. None of that is rebuilt here. A CLICK - the button let go on it
## with no drag begun - dispatches its action, if it was described with one,
## with its payload: a card opens where a drag would move it.
##
## A PIECE OF A LIST - standing inside a list target (drop_target.gd) - IS
## PART OF THAT TARGET for the engine: a drag over it is a drag over the list
## at that point, and a drop on it is the list's. Lifted, it would land where
## it stood to begin with, and the list shows it there, so nothing moves
## until the pointer or the keys do.
##
## LIFTED BY THE POINTER, IT IS A HOLE: the look's lifted box, and none of its
## content, since its likeness travels under the pointer and the room it
## keeps is where it would land. Lifted by the keys or the pad, it is the
## thing itself, drawn lifted where it would land, and keeps the focus
## wherever the list builds it - the reader moves it under their hand.
##
## THE PREVIEW IS A COPY OF THIS ONE'S LOOK, built here and nowhere else:
## the box the look draws it in at that moment, the words it holds, and its
## ink - so no recipe ever writes engine styling. The engine owns the
## preview once it is handed over and frees it as the drag ends.
##
## THE PAD AND THE KEYBOARD CARRY IT TOO (carry_walk.gd), which the Steam
## Deck needs: accept while it holds the focus lifts it, and then the
## directions, accept and cancel are the carry's. Accept is answered in the
## input here and NOT in pressed(), because a press arrives from a click as
## well, and a click is the beginning of a drag, not a lift.
##
## What is carried is the carried model's and is never held here: this asks
## it whether its payload is what is carried and draws LIFTED while it is,
## over the face's hover and normal; while it is, it wears the engine's own
## group LIFTED, which a list target reads to leave it out of the places.
##
## Deliberately absent: a handle to pick it up by, and a drag that begins
## only after the pointer has moved a distance - both the engine's, and both
## a pure addition to it.


## The copy carried under the pointer: the look's box, drawn, with the words
## across it. It is the engine's once it is handed over.
class Copy extends Control:
	var box: StyleBox

	func _draw() -> void:
		draw_style_box(box, Rect2(Vector2.ZERO, size))


var _carried: Carried
var _commands: Commands
var _payload: Variant  # a Dictionary, or a Bound read as the lift lands
var _presses: StringName  # dispatched by a click, or none
var _clicked: bool = false  # whether the button went down here and no drag has begun since


func _init(chimes: Chimes, commands: Commands, in_region: StringName, carried: Carried, payload: Variant, presses: StringName, style: Variant) -> void:
	_carried = carried
	_commands = commands
	_presses = presses
	super(chimes, in_region, style)
	# a finger drawn on it carries it, and nothing holding it moves under that
	add_to_group(Touch.HOLDS)
	_payload = payload
	_chimes.follow(self, &"carry", _carry_moved)


func _notification(what: int) -> void:
	if what == NOTIFICATION_ENTER_TREE:
		_mark()
		# built again where the carry would land, lifted by the keys - or back where it stood, put back - the focus is its still
		if (is_lifted() or _returned_here()) and _carried.is_by_keys():
			grab_focus.call_deferred()
	# the engine ended a drag with nothing dropped: a release over nothing, or Escape
	if what == NOTIFICATION_DRAG_END and is_lifted():
		_carried.put_back()


## The carry read, so it is followed apart from the draw; moved once this is
## ready, drawn again if whether this is the thing carried changed - every
## draggable follows every lift, and a board of three hundred drawn again
## for each would stall it, so a draw reads the mark, never the carry - and,
## given up after the pad or the keys lifted this, the focus comes home, so
## the reader is back where they started.
func _carry_moved() -> void:
	var lifted := is_lifted()
	var returned := _returned_here()
	if not is_node_ready():
		return
	if returned and _carried.is_by_keys():
		grab_focus()
	if lifted != is_in_group(CarryWalk.LIFTED):
		_mark()
		needs_refresh()


## Whether the carry was given up, and this is the thing given up.
func _returned_here() -> bool:
	return not _carried.is_carrying() and _carried.get_put_back() and _carried.get_returned() == _given()


## Whether this is the thing being carried now: its payload is what is carried.
func is_lifted() -> bool:
	return _carried.is_lifted(_given())


## Lifted while it wears the mark, which the carry moving puts on and takes off.
func get_state() -> StringName:
	return &"lifted" if is_in_group(CarryWalk.LIFTED) else super.get_state()


## Drawn as its state says; its content hidden while it is a hole the pointer lifted.
func refresh() -> void:
	var hole := is_in_group(CarryWalk.LIFTED) and not _carried.is_by_keys()
	# every part of its content, shown or left out of the hole
	for part: Node in get_children():
		if part is Control:
			(part as Control).modulate.a = 0.0 if hole else 1.0
	super.refresh()


## Worn while carried, and only then: the mark a list target reads.
func _mark() -> void:
	if is_lifted():
		add_to_group(CarryWalk.LIFTED)
	elif is_in_group(CarryWalk.LIFTED):
		remove_from_group(CarryWalk.LIFTED)


## While it is carried, the carry's keys are the carry's; accept lifts it;
## a click lets go on it presses it. The rest is the face's, and a press
## held and moved becomes the engine's drag.
func _gui_input(event: InputEvent) -> void:
	if is_lifted() and (CarryWalk.stepped(self, event, _carried) if _list() != null else CarryWalk.walked(self, event, _carried)):
		accept_event()
		return
	if event.is_action_pressed(&"ui_accept") and not _carried.is_carrying():
		_carried.lift(_given(), _where(), true)
		# marked now, as a drag's lift is
		_carry_moved()
		accept_event()
		return
	var click := event as InputEventMouseButton
	if click != null and click.button_index == MOUSE_BUTTON_LEFT:
		if not click.pressed and _clicked and _presses != &"":
			_commands.dispatch(region, _presses, _given())
		_clicked = click.pressed
	super._gui_input(event)


## The list target this is a piece of, or none.
func _list() -> Control:
	var above: Node = get_parent()
	# up through whatever holds it, to the first target standing for a list
	while above != null:
		if above.is_in_group(CarryWalk.TARGET) and above.is_list():
			return above
		above = above.get_parent()
	return null


## Where it would land to begin with: where it stands in its list, or nowhere.
func _where() -> Dictionary:
	var list := _list()
	return {} if list == null else {"into": list.get_into(), "at": list.place_of(self)}


## The engine, asking for the data as a press is dragged: what this carries,
## put into the carry as well so every target reads one truth, and a copy of
## the look to carry under the pointer.
func _get_drag_data(_at: Vector2) -> Variant:
	_clicked = false
	var carrying := _given()
	_carried.lift(carrying, _where(), false)
	# marked now, not as the carry rings at the frame's end: a list target reads the mark on the very next move
	_carry_moved()
	# the preview is the engine's to carry, and there is one only while the engine is the one dragging: asked by hand, as a test asks, there is no drag to hang it on
	if get_viewport().gui_is_dragging():
		set_drag_preview(_copy())
	return {"payload": carrying}


## The engine's drag over this piece: its list's, at this point.
func _can_drop_data(at: Vector2, data: Variant) -> bool:
	var list := _list()
	return list != null and list.takes_at(get_global_transform() * at, data)


## Let go over this piece: its list's drop.
func _drop_data(_at: Vector2, _data: Variant) -> void:
	_list().drop()


## What it carries: a bound payload read as the lift lands - nothing, for a
## piece of a list whose item has gone and which is on its way out.
func _given() -> Dictionary:
	var given: Variant = _payload.read() if _payload is Bound else _payload
	return {} if given == null else given


## A copy of the look to carry: the box this is drawn in now, at the size it
## has, with the words it holds in the ink the look gives them.
func _copy() -> Control:
	var copy := Copy.new()
	copy.box = _box()
	copy.custom_minimum_size = size
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var said := Label.new()
	# the words copied are in the language on already, and never translated a second time
	said.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	said.text = _said_by(self)
	said.add_theme_color_override(&"font_color", _colour())
	said.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	said.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	said.set_anchors_preset(Control.PRESET_FULL_RECT)
	said.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(said)
	return copy


## Every word this face holds, in order, for the copy to show.
func _said_by(node: Node) -> String:
	var words := ""
	# every part of this face, down to the labels, whose words the copy carries
	for child: Node in node.get_children():
		if child is Label:
			words += (child as Label).text
		words += _said_by(child)
	return words


## The builder's door: a draggable in the region of the place being built
## into, handed the one carry, and pressed as its action if described with one.
static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"draggable").new(ui.chimes, ui.commands, ui.region(), desc.props["carried"], desc.props["payload"], desc.props.get("presses", &""), desc.props["style"])
	ui.attach(made, parent, desc.facts)
	return made
