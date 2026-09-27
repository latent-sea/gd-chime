extends "../../presentation.gd"

const Commands := preload("../../commands.gd")
const Phrase := preload("../../phrase.gd")
const Bound := preload("bound.gd")
const Local := preload("local.gd")

## A line a person types: Enter dispatches the action with the line, and
## the line is cleared once the action is done.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The engine's own LineEdit does the typing - the letters, the caret,
## selection, copy and paste, undo, other alphabets. Enter is a command
## through the door: dispatch(region, action, {"line": the line}), refused
## like any other; done, the line is cleared so the next can be typed
## straight away (measured on 4.6.2, left as the engine sets it, Enter ends
## editing). Focus sits on the LineEdit: a click, Tab or start_typing()
## starts editing. Its look is its style's, a variation of LineEdit.
##
## A REFUSAL IS SHOWN, as a pressable shows its own: every dispatch it makes
## keeps the door's answer, and its REASON (reason()) - the last refusal,
## until a dispatch is not refused - stands under the line in the look's
## Reason, wrapping, taking no room while there is none. A field standing
## where nothing may stand under it - a table's cell, in a row as tall as
## every other - is handed a local (REFUSED) to keep the refusal in
## instead, and whoever holds the local shows it where there is room.
##
## By option: CHANGES, a second action dispatched with the line on every
## change - what a type-ahead narrows on - and SHOWS, a bound value the
## line is set to whenever it moves - a named field showing the name it
## holds - in which case Enter leaves the line as it is, since the model's
## answer is what it shows; and a value that is already the line as it
## stands is not written back, so the caret and the engine's undo survive a
## model that holds every keystroke. CARRIES, a function from the line to
## what Enter and every change dispatch in place of {"line"} - a number
## field's {"value"}, the payload every other control setting that value
## carries, one payload however the value was put in. And LEAVES,
## an action dispatched with {"line"} as the focus leaves the line - an
## answer checked once the reader has moved on from it.
##
## Deliberately absent: history, more than one line, an on-screen
## keyboard.

var _commands: Commands
var _action: StringName
var _line := LineEdit.new()
var _takes_focus: bool
var _changes: StringName  # the action dispatched on every change, or none
var _shows: Variant  # a Bound the line is set to, or null
var _shown: Variant = null  # the value last put in the line
var _carries: Callable  # the line to the payload Enter dispatches, or none for {"line"}
var _leaves: StringName  # the action dispatched as the focus leaves the line, or none
var _refused: Local  # the local the refusal is kept in in place of the reason under the line, or null
var _refusal: Phrase = null  # the door's answer to the last dispatch
var _dependents: Array = []  # the controls reading its reason, drawn as this is


## Its action, look and focus, and its options as the description says them (describe_inputs.gd).
func _init(chimes: Chimes, commands: Commands, action: StringName, style: StringName, in_region: StringName, takes_focus: bool, options: Dictionary) -> void:
	super(chimes, [], in_region)
	_commands = commands
	_action = action
	_takes_focus = takes_focus
	_changes = options["changes"]
	_shows = options["shows"]
	_carries = options["carries"]
	_leaves = options["leaves"]
	_refused = options["refused"]
	if style != &"":
		_line.theme_type_variation = style
	_line.keep_editing_on_text_submit = true
	add_child(_line)
	_line.text_submitted.connect(_submitted)
	_line.text_changed.connect(_changed)
	_line.focus_exited.connect(_left)


## Built to take the focus, it does once the frame it entered on has
## shown it: a hidden control cannot take the focus, and the place it is
## built into is shown at the end of the same move.
func _ready() -> void:
	super()
	if _takes_focus:
		_line.grab_focus.call_deferred()


## Put the caret in it, so typing goes here.
func start_typing() -> void:
	_line.grab_focus()


## The line as it stands.
func get_line() -> String:
	return _line.text


## Why the last dispatch was refused, or null: an answer of this, for its reason to show.
func reason() -> Bound:
	return Bound.new(func() -> Variant: return _refusal, self)


## A reader of its reason, drawn again as this is.
func depends(reader: Node) -> void:
	_dependents.append(reader)


## The line over its reason: as wide as the wider, as tall as both with the column's gap between.
func _get_minimum_size() -> Vector2:
	var least := _line.get_combined_minimum_size()
	# every part under the line that shows, each adding its height and the gap
	for part: Control in _under():
		least = Vector2(maxf(least.x, part.get_combined_minimum_size().x), least.y + _gap() + part.get_combined_minimum_size().y)
	return least


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		var below := size.y
		# every part under the line that shows, from the foot up, each on its own least height
		for part: Control in _under():
			below -= part.get_combined_minimum_size().y
			fit_child_in_rect(part, Rect2(0.0, below, size.x, part.get_combined_minimum_size().y))
			below -= _gap()
		fit_child_in_rect(_line, Rect2(Vector2.ZERO, Vector2(size.x, below)))
	# gone with the cell it was typed in, a refusal kept in a local goes with it
	if what == NOTIFICATION_EXIT_TREE and _refused != null and _refusal != null:
		_refused.set_value(null)


## The parts under the line that show: its reason, when it holds one.
func _under() -> Array:
	return get_children().filter(func(part: Node) -> bool: return part != _line and (part as Control).visible)


func _gap() -> float:
	return float(get_theme_constant(&"gap", Themes.COLUMN))


## Enter: the line through the door, and cleared once done - or left, for
## a field showing the model's own value.
func _submitted(line: String) -> void:
	if _answered(_commands.dispatch(region, _action, _carries.call(line) if _carries.is_valid() else {"line": line})) and _shows == null:
		_line.clear()


## Every change, through the door under the second action, when one is
## given, carrying what Enter would.
func _changed(line: String) -> void:
	if _changes != &"":
		_answered(_commands.dispatch(region, _changes, _carries.call(line) if _carries.is_valid() else {"line": line}))


## The focus leaving the line, through the door under the action for it, when one is given.
func _left() -> void:
	if _leaves != &"" and is_inside_tree():
		_answered(_commands.dispatch(region, _leaves, {"line": _line.text}))


## The door's answer kept for the reason to show - none for a dispatch the
## door held while paused - and whether it was done.
func _answered(answer: Phrase) -> bool:
	var refusal: Phrase = null if _commands.get_last()["paused"] else answer
	if refusal != _refusal:
		_refusal = refusal
		if _refused != null:
			_refused.set_value(refusal)
		needs_refresh()
	return answer == null


func heard(_what: StringName) -> void:
	needs_refresh()


## The line set to the value it shows when that value moves - never
## otherwise, so typing is not written over by a draw - and never to the
## line it already is; and every reader of its reason drawn again.
func refresh() -> void:
	# every reader of its reason, drawn with it
	for reader: Node in _dependents:
		reader.needs_refresh()
	if _shows == null:
		return
	var value: Variant = _shows.read()
	if value != _shown:
		_shown = value
		var written := "" if value == null else str(value)
		if written != _line.text:
			_line.text = written


## The builder's door: the field, and its reason under the line unless a local keeps the refusal.
static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"field").new(ui.chimes, ui.commands, desc.props["action"], desc.props["style"], ui.region(), desc.props["takes_focus"], desc.props)
	ui.attach(made, parent, desc.facts)
	if desc.props["refused"] == null:
		ui.build(ui.text(made.reason(), Themes.REASON).hides_empty().wraps(), made)
	return made
