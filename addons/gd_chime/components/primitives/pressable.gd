extends "../../action_control.gd"

## Something pressed: a control performing one of its place's actions, drawn
## in the state it is in, holding whatever content it was described with.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## What it does is action_control.gd's and how it is drawn is face.gd's.
## This adds: the payload a press carries - a dictionary, or a bound value
## read as the press lands; the states the door, the prompts and the driver
## put it in, over the face's hover and normal - inert, glowing, and CURRENT, for one whose destination is on the
## screen the reader is on: a tab of the place you are at is selected, not
## unavailable, so it draws current, gives no reason, and takes normal's
## box and ink where a look defines none - or, described current_while a
## bound value, CURRENT while that holds, wherever it goes: the flap of the
## file in front, a fact of a model and never of navigation;
## and its REASON, a bound value the content may read (ui.reason()), why it
## cannot be used or why the last press was refused, re-read as this draws.
##
## A FINGER'S TARGET: on a touched window (shape.gd's meta TOUCH), in any
## shape and either way round, it is at least the look's least touch size
## each way, Touch/least_um, in thousandths of a millimetre on the glass,
## made base pixels by how big a base pixel is drawn there
## (least_each_way): what the easel fitting the canvas says on its viewport
## (touch.gd's meta PIXEL_UM), or, on a window with no easel, the window's
## own pixel at the screen's dots to the inch. Every target is measured
## again as either moves. One holding nothing - a drawer's shade - is
## ground, not a target.

const Shape := preload("../../shape.gd")

var _payload: Variant
var _dependents: Array = []  # the controls reading an answer of this, drawn as this is
var absent_when_refused: bool = false  # gone from the screen, not inert, while the door would refuse it
var current_while: Bound = null  # current while this holds, in place of where it goes, when described so


func _init(chimes: Chimes, commands: Commands, place: Node, does: StringName, payload: Variant, style: Variant) -> void:
	super(chimes, commands, place, does, style)
	_payload = payload
	add_to_group(Touch.TARGETS)


## What the face needs, and on a touched window at least the look's least touch size each way.
func _get_minimum_size() -> Vector2:
	var needs := super._get_minimum_size()
	# a press holding nothing - a shade - is a stretch of ground whatever holds it sizes, not a target
	if get_child_count() == 0 or not is_inside_tree() or not get_viewport().get_meta(Shape.TOUCH, false):
		return needs
	return needs.max(Vector2.ONE * least_each_way(self))


## The look's least touch size in the base pixels this control is drawn in:
## Touch/least_um over how many thousandths of a millimetre one of them
## measures on the glass - said by the easel on its viewport, or else the
## window's own pixel, stretched as it is drawn, at the screen's dots to the
## inch (25,400 thousandths of a millimetre to the inch).
static func least_each_way(on: Control) -> float:
	var viewport := on.get_viewport()
	# the easel's word where it fits the canvas; else the window's pixel as drawn, at the screen's dots to the inch
	var pixel_um: float = viewport.get_meta(Touch.PIXEL_UM) if viewport.has_meta(Touch.PIXEL_UM) else viewport.get_final_transform().get_scale().x * 25400.0 / DisplayServer.screen_get_dpi()
	return on.get_theme_constant(&"least_um", Touch.TYPE) / pixel_um


## Why it cannot be used, or why the last press was refused: an answer of
## this, for its content to show.
func reason() -> Bound:
	return Bound.new(func() -> Variant: return null if is_current() else get_reason() if not is_usable() else get_refusal(), self)


## A reader of one of this control's answers, drawn again as this is.
func depends(reader: Node) -> void:
	_dependents.append(reader)


func payload() -> Dictionary:
	return _payload.read() if _payload is Bound else _payload


## Whether a press would land where the reader already is: the place it
## goes to is on the screen, entered as the very one this press carries -
## a link with no parameter against a place entered with none. Selected,
## not unavailable: a link to another of the same kind is not current. One
## described current_while is current while that value holds, and only then.
func is_current() -> bool:
	if current_while != null:
		return current_while.read() == true
	var goes_to := get_goes_to()
	if goes_to == &"" or not _place.driver.get_top().has(goes_to):
		return false
	return _place.driver.get_parameter(goes_to) == payload().get("parameter")


## The one state the look draws it in.
func get_state() -> StringName:
	if is_glowing():
		return &"glowing"
	if is_current():
		return &"current"
	if not is_usable():
		return &"inert"
	return super.get_state()


## Absent while refused, its own draw is what shows it again (presentation.gd).
func shows_itself() -> bool:
	return absent_when_refused


func refresh() -> void:
	# absent rather than inert while refused, when described so: the transport owed a decision
	if absent_when_refused:
		visible = is_usable()
	# every reader of an answer of this, drawn with it
	for reader: Node in _dependents:
		reader.needs_refresh()
	super.refresh()


## The builder's door: a pressable of the place being built into, glowing
## for the one set of prompts, repeating while held or taking no focus as
## described.
static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"pressable").new(ui.chimes, ui.commands, ui.current_place(), desc.props["action"], desc.props["payload"], desc.props["style"])
	made.prompts = ui.prompts
	if desc.props.has("repeat"):
		made.repeat_while_held(desc.props["repeat"][0], desc.props["repeat"][1])
	if desc.props.has("no_focus"):
		made.focus_mode = Control.FOCUS_NONE
	if desc.props.has("absent"):
		made.absent_when_refused = true
	if desc.props.has("current_while"):
		made.current_while = desc.props["current_while"]
	ui.attach(made, parent, desc.facts)
	return made