extends Container

const Bound := preload("bound.gd")
const Inputs := preload("../../input_map.gd")
const Inset := preload("inset.gd")

## A menu's target: whatever it holds, given a context menu of declared
## actions - opened by a right press on it, a finger held on it, or the
## keyboard's menu key or a pad button while the focus is inside it
## (open_menu.gd).
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## IT HOLDS WHAT IT WAS DESCRIBED WITH, across the whole of itself, and takes
## no press of its own: what it holds is pressed as ever, and a press on its
## bare ground goes on to what holds it. It hears every
## event as it arrives, and acts on two alone. A right press opens its menu
## where the pointer is, when the control under the pointer is inside it
## and inside no nearer target - so a row's menu opens over the row and the
## list's over the rest of the list. The input the map puts on the opening
## action - the menu key, a pad button, rebound as the player likes - opens
## it over the control with the focus, when that control is inside it and
## inside no nearer target. Either way the event is spent here, so nothing
## else takes it too. A FINGER HELD STILL on it for the look's long press
## opens it where the finger is: touch.gd times the hold, finds the nearest
## target under the finger as a right press does, and tells it
## (finger_held).
##
## OPENING IS A PRESS THROUGH THE DOOR: the opening action, which its place
## declares as going to the menu's pop-up, carrying {actions, payload,
## region, at} as the pop-up's parameter - the actions offered, what a press
## of them is about (read now, from a bound value if it was given one), the
## region they are pressed in, and where to open. The pop-up reads it.
##
## Deliberately absent: a menu that differs by where in the target it opened.

## The mark on every target, the engine's own group: nothing to hold, gone with the node.
const TARGET := &"menu target"

var _no_box := StyleBoxEmpty.new()  # no padding: what it holds takes the whole of it
var _ui: RefCounted
var _actions: Array  # the declared actions its menu offers, in order
var _payload: Variant  # what a press of them is about: a dictionary, or a bound value read as the menu opens
var _opens: StringName  # the press going to the menu's pop-up
var _region: StringName  # the place it stands in, where the actions are pressed


func _init(ui: RefCounted, actions: Array, payload: Variant, opens: StringName) -> void:
	_ui = ui
	_actions = actions
	_payload = payload
	_opens = opens
	_region = ui.region()
	# the pointer over its bare ground is over it, so a right press there opens its menu; a press goes on to what holds it
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_to_group(TARGET)


## Every event as it arrives: a right press, or the opening input, meant for
## this target - the nearest one holding the control it lands on.
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not event.is_pressed() or event.is_echo():
		return
	var click := event as InputEventMouseButton
	if click != null and click.button_index == MOUSE_BUTTON_RIGHT:
		if nearest(get_viewport().gui_get_hovered_control()) == self:
			get_viewport().set_input_as_handled()
			# where the press landed, on the canvas the window draws
			_open(Rect2(get_global_transform() * (make_input_local(click) as InputEventMouseButton).position, Vector2.ZERO))
		return
	if not _ui.inputs.get_actions(Inputs.of_event(event)).has(_opens):
		return
	var focus := get_viewport().gui_get_focus_owner()
	if nearest(focus) == self:
		get_viewport().set_input_as_handled()
		_open(focus.get_global_rect())


## A finger held still on it past the look's long press (touch.gd): its
## menu opened where the finger is, a point of the canvas.
func finger_held(at: Vector2) -> void:
	_open(Rect2(at, Vector2.ZERO))


## The nearest target holding this control, itself or above it; none for
## nothing. PUBLIC because a held finger finds its target as a right press does.
static func nearest(control: Control) -> Node:
	var at: Node = control
	# up from the control, for the first node marked a target
	while at != null and not at.is_in_group(TARGET):
		at = at.get_parent()
	return at


## What a press of its menu's actions is about, as it stands now: the row
## it is over, where a row of a table holds one. PUBLIC because it is what
## the target IS about, and a pressable answers the same question.
func payload() -> Dictionary:
	return _payload.read() if _payload is Bound else _payload


## The menu opened over this rect, through the door.
func _open(at: Rect2) -> void:
	_ui.commands.dispatch(_region, _opens, {"parameter": {"actions": _actions, "payload": payload(), "region": _region, "at": at}})


## What it holds, across the whole of it.
func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		Inset.fit(self, _no_box)


func _get_minimum_size() -> Vector2:
	return Inset.least(self, _no_box)


## The builder's door: a target of the place being built into, its content built into it.
static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"menu_target").new(ui, desc.props["actions"], desc.props["payload"], desc.props["opens"])
	ui.attach(made, parent, desc.facts)
	return made
