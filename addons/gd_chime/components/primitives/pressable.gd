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
## shape and either way round, a finger anywhere within the look's least
## touch size each way round its middle presses it, Touch/least_um, in
## thousandths of a millimetre on the glass, made base pixels by how big a
## base pixel is drawn there (least_each_way): what the easel fitting the
## canvas says on its viewport (touch.gd's meta PIXEL_UM), or, on a window
## with no easel, the window's own pixel at the screen's dots to the inch.
## IT IS DRAWN AT ITS FACE'S OWN SIZE ALL THE SAME, so a phone's screens
## are laid out as a desk's are and fit it (design/ui/responsive-screens.md,
## "Fit first, scroll last"): the target reaches past what is drawn, as a
## phone's own presses do, but never over anything else that takes the
## pointer - the row beside it in a list, a press beside it in a bar - save
## what it stands on, a picture pressed as a whole under its glass. Its
## reach is measured as the finger lands, so whatever moves either is
## followed. One holding nothing - a drawer's shade - is ground, not a
## target, and reaches no further than it is drawn.

const Shape := preload("../../shape.gd")

var _payload: Variant
var _dependents: Array = []  # the controls reading an answer of this, drawn as this is
var absent_when_refused: bool = false  # gone from the screen, not inert, while the door would refuse it
var current_while: Bound = null  # current while this holds, in place of where it goes, when described so


func _init(chimes: Chimes, commands: Commands, place: Node, does: StringName, payload: Variant, style: Variant) -> void:
	super(chimes, commands, place, does, style)
	_payload = payload


## Whether a finger or the pointer at this point of its own presses it:
## inside it, and on a touched window anywhere within the look's least touch
## size each way round its middle where nothing else that takes the pointer
## stands - never further for a press holding nothing, which is ground.
func reaches(point: Vector2) -> bool:
	var drawn := Rect2(Vector2.ZERO, size)
	if drawn.has_point(point):
		return true
	if get_child_count() == 0 or not is_inside_tree() or not get_viewport().get_meta(Shape.TOUCH, false):
		return false
	# how far short of the least it is drawn each way, half of it on each side
	var short := (Vector2.ONE * least_each_way(self) - size).max(Vector2.ZERO) / 2.0
	var reach := drawn.grow_individual(short.x, short.y, short.x, short.y)
	return reach.has_point(point) and not _another_takes(get_global_transform() * point, get_global_transform() * reach)


## The engine asking where the pointer lands: wherever it reaches.
func _has_point(point: Vector2) -> bool:
	return reaches(point)


## Whether anything else that takes the pointer stands at this point of the
## canvas, other than what this stands on: looked for beside this, then
## beside what holds it, outward until a holder holds the whole of `reach`.
func _another_takes(at: Vector2, reach: Rect2) -> bool:
	var mine := get_global_rect()
	var path: Node = self
	var holder := get_parent()
	# outward through what holds this, each holder's other parts looked into
	while holder is Control:
		for other: Node in holder.get_children():
			if other != path and other is Control and _takes(other, at, mine):
				return true
		if (holder as Control).get_global_rect().encloses(reach):
			return false
		path = holder
		holder = holder.get_parent()
	return false


## Whether this control, or anything shown in it at this point, takes the
## pointer there and is not what `mine` stands on - a control whose rect
## holds the whole of it.
static func _takes(control: Control, at: Vector2, mine: Rect2) -> bool:
	var rect := control.get_global_rect()
	if not control.is_visible_in_tree() or not rect.has_point(at):
		return false
	if control.mouse_filter != Control.MOUSE_FILTER_IGNORE and not rect.encloses(mine):
		return true
	return control.get_children().any(func(part: Node) -> bool: return part is Control and _takes(part, at, mine))


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