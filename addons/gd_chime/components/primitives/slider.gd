extends "slider_track.gd"

const Local := preload("local.gd")
const Layout := preload("layout.gd")

## A slider: a value along a track, between a minimum and a maximum, moved
## by the step it is given, every change a command through the door.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## IT HOLDS NO VALUE. The value is the model's, a bound value read as a
## change is worked out; a change is dispatch(region, action, {"value": v}) -
## the payload a choice carries - and the handle rests only where the model's
## value is. So a value the door's would() refuses leaves the handle where it
## was and the refusal kept, shown by the reason under the track, as a
## pressable shows its own; a ring of the model's bells clears it. It is a
## pressable in all else: its place declares its action, its states and its
## look are a pressable's, and a refusal of the value it has now makes it
## inert. Where things stand and what is drawn is its track's
## (slider_track.gd), which this extends.
##
## A DRAG IS ONE COMMAND. A press of the pointer in the track holds the value
## under it, and dragging from there follows the pointer, wherever it goes -
## held in a local the slider was described with (describe_inputs.gd), which
## the handle and the words show and which goes through no door. The release
## sends what is held, once, and lets it go, so the handle settles on the
## model's value: the one sent, or, refused, the one it had, with the reason.
## A press with no drag is one command as well, sent as it is released.
##
## THE PAD AND THE KEYS NEVER TRAP. Left and right - the arrow keys, the
## d-pad, the stick - step it, one command a step, where nothing taking the
## focus stands beside it in the nearest row holding it: a settings row, its
## words and it. Where something does, they walk past it like any control,
## and accept GRABS it, as a carried thing is lifted (draggable.gd), drawn
## LIFTED: left and right step it, up and down go nowhere, accept lets it go
## and cancel lets it go back to the value it had as it was grabbed; the
## focus leaving by another hand lets it go too. Beside is along that row
## alone, never the engine's neighbour, which a tab far above can be. Every
## value is snapped to the step and held between the two ends, and a value
## the model already has is not asked again.
##
## Deliberately absent: a second handle for a range, which nothing asks for.

var _value: Bound  # the model's value, read as a change is worked out
var _held: Local  # the value under the pointer while a drag is held, null while none is
var _grabbed: bool = false  # whether accept grabbed it, so left and right step it though they would walk past it
var _grabbed_from: float  # the model's value as it was grabbed, which cancel goes back to


func _init(chimes: Chimes, commands: Commands, place: Node, does: StringName, value: Bound, held: Local, shown: Bound, minimum: float, maximum: float, step: float, style: Variant) -> void:
	super(chimes, commands, place, does, value.map(func(now: Variant) -> Dictionary: return {"value": now}), shown, minimum, maximum, step, style)
	_value = value
	_held = held
	# a finger drawn on it drags its value, and nothing holding it moves under that
	add_to_group(Touch.HOLDS)


## The value as the model has it now.
func get_value() -> float:
	return float(_value.read())


## A press of accept changes nothing: a press lands where the pointer is, in the input.
func pressed() -> void:
	pass


## Grabbed, it is drawn lifted, as a carried thing is.
func get_state() -> StringName:
	return &"lifted" if _grabbed else super.get_state()


## The focus leaving lets a grab go, where it is.
func focused(shown: bool) -> void:
	if not shown:
		_grabbed = false
	super.focused(shown)


## The pointer in the track holds and drags, and the release sends; left
## and right step it where they are its own; accept grabs it where they are
## not. Anything else, and the press itself, is a face's.
func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	var moved := event as InputEventMouseMotion
	var sideways := event.is_action_pressed(&"ui_left", true) or event.is_action_pressed(&"ui_right", true)
	if click != null and click.button_index == MOUSE_BUTTON_LEFT:
		if click.pressed and _band().has_point(click.position) and is_usable():
			_hold(_value_at(click.position.x))
		elif not click.pressed and _held.read() != null:
			var released: float = _held.read()
			_hold(null)
			_change_to(released)
	elif moved != null and _held.read() != null and moved.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_hold(_value_at(moved.position.x))
		accept_event()
		return
	elif sideways and (_grabbed or not _walked_past()):
		var towards := 1.0 if event.is_action(&"ui_right") else -1.0
		_change_to(clampf(_minimum + snappedf(get_value() - _minimum + towards * _step, _step), _minimum, _maximum))
		accept_event()
		return
	elif _grabbed and (event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"ui_cancel")):
		_grabbed = false
		if event.is_action(&"ui_cancel"):
			_change_to(_grabbed_from)
		needs_refresh()
		accept_event()
		return
	elif _grabbed and (event.is_action_pressed(&"ui_up", true) or event.is_action_pressed(&"ui_down", true)):
		accept_event()
		return
	elif event.is_action_pressed(&"ui_accept") and is_usable() and _walked_past():
		_grabbed = true
		_grabbed_from = get_value()
		needs_refresh()
		accept_event()
		return
	super._gui_input(event)


## Whether the pad and the keys walk past it: something taking the focus
## stands before or after it along the nearest row holding it.
func _walked_past() -> bool:
	var branch: Node = self
	# up through whatever holds it to the nearest row, or out of the tree with none
	while branch.get_parent() != null and not (branch.get_parent() is Layout and branch.get_parent().is_row()):
		branch = branch.get_parent()
	var row := branch.get_parent()
	return row != null and row.get_children().any(func(part: Node) -> bool: return part != branch and part is Control and part.visible and part.focus_mode == FOCUS_ALL)


## The value a drag holds under the pointer, shown and sent nowhere; null lets it go.
func _hold(value: Variant) -> void:
	_held.set_value(value)
	needs_refresh()


## A new value through the door, unless it is the one the model has or the
## slider cannot be used; the answer kept for the reason to show.
func _change_to(value: float) -> void:
	if is_equal_approx(value, get_value()) or not is_usable():
		return
	var answer := _commands.dispatch(region, action, {"value": value})
	_keep_refusal(null if _commands.get_last()["paused"] else answer)
	needs_refresh()


## The builder's door: a slider of the place being built into, glowing for the one set of prompts.
static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"slider").new(ui.chimes, ui.commands, ui.current_place(), desc.props["action"], desc.props["value"], desc.props["held"], desc.props["shown"], desc.props["minimum"], desc.props["maximum"], desc.props["step"], desc.props["style"])
	made.prompts = ui.prompts
	ui.attach(made, parent, desc.facts)
	return made
