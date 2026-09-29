extends "../../presentation.gd"

const Commands := preload("../../commands.gd")
const Motion := preload("../../motion.gd")
const ScrollIndicator := preload("scroll_indicator.gd")

## An area a person types in: words over as many lines as they take,
## broken at the width it is given, growing as they grow to the most lines
## its look allows and scrolling past that.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The engine's own TextEdit does the typing - the letters, the caret,
## selection, copy and paste, undo, other alphabets. ENTER BREAKS THE WORDS,
## so nothing here submits: the words go on by a press of their own beside
## the area (text_area.gd). Every change goes through the door as the
## action it was built with, {"text": the words}, so the MODEL holds the
## words; and the area shows the bound value it is given whenever that
## value moves away from what is typed - a model clearing its words once
## they are sent clears the area - and never otherwise, since setting the
## engine's words sets its caret and its undo back.
##
## ITS HEIGHT IS ITS LINES: as many as the words take at its width, but
## never fewer than the look's least_lines nor more than its most_lines,
## each the engine's own line height, inside its box. Past the most it
## scrolls inside itself, the caret kept in sight by the engine.
##
## WHERE THE READER IS SHOWS OVER IT (scroll_indicator.gd), in the right of
## its box's padding, as over a scroll: the engine's own bar is kept, for
## where the words stand, but draws nothing and takes no room.
##
## Reached like any control: a click, or the focus walked to it. Tab and
## Shift+Tab walk the focus on out of it, never typed into it; the pad's
## directions walk out of it too - measured on 4.6.2, they move no caret -
## while the keyboard's arrows move the caret, as in any typed line. Its
## look is its style's, a variation of TextEdit.
##
## Deliberately absent: an on-screen keyboard, a count of what is left, and
## the words' own history.

var _commands: Commands
var _changes: StringName  # the action every change is dispatched as
var _shows: RefCounted  # the Bound the area is set to whenever it moves
var _area := TextEdit.new()
var _indicator: ScrollIndicator  # where the reader is in the words, over the engine's own
var _takes_focus: bool
var _shown: Variant = null  # the value it showed when it last looked


func _init(chimes: Chimes, commands: Commands, motion: Motion, changes: StringName, shows: RefCounted, style: StringName, in_region: StringName, takes_focus: bool) -> void:
	super(chimes, [], in_region)
	_commands = commands
	_changes = changes
	_shows = shows
	_takes_focus = takes_focus
	_area.theme_type_variation = style
	_area.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	# Tab walks the focus on, as it does from every other control, rather than typing a tab
	_area.tab_input_mode = false
	_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_area)
	_area.text_changed.connect(_changed)
	# the engine's bar, whose look is every list's, drawn as nothing and nothing wide
	var bar := _area.get_v_scroll_bar()
	for box: StringName in [&"scroll", &"scroll_focus", &"grabber", &"grabber_highlight", &"grabber_pressed"]:
		bar.add_theme_stylebox_override(box, StyleBoxEmpty.new())
	_indicator = ScrollIndicator.new(motion, bar, _area, &"normal")
	_area.add_child(_indicator, false, Node.INTERNAL_MODE_BACK)
	_area.gui_input.connect(_touched)


## Built to take the focus, it does once the frame it entered on has shown it.
func _ready() -> void:
	super()
	if _takes_focus:
		_area.grab_focus.call_deferred()


## Put the caret in it, so typing goes here.
func start_typing() -> void:
	_area.grab_focus()


## The words as they stand.
func get_text() -> String:
	return _area.text


## How many lines it shows before it scrolls: the lines the words take at
## this width, held between the look's least and most.
func get_lines_shown() -> int:
	return clampi(_area.get_total_visible_line_count(), _area.get_theme_constant(&"least_lines"), _area.get_theme_constant(&"most_lines"))


func _get_minimum_size() -> Vector2:
	var box := _area.get_theme_stylebox(&"normal").get_minimum_size()
	return Vector2(box.x, box.y + get_lines_shown() * _area.get_line_height())


## A new width breaks the words onto a different number of lines, and
## where the reader is may have moved with them.
func arrange() -> void:
	update_minimum_size()
	_indicator.moved()


## Every change through the door, and the height asked again.
func _changed() -> void:
	_commands.dispatch(region, _changes, {"text": _area.text})
	update_minimum_size()
	_indicator.moved()


## Anything the reader does in it - a wheel, a finger, a key - may move the
## words: where they are is looked at.
func _touched(_event: InputEvent) -> void:
	_indicator.moved()


func heard(_what: StringName) -> void:
	needs_refresh()


## The area set to the value it shows when that value has moved and is not
## what is typed - never otherwise, so a draw never writes over typing the
## engine has yet to report.
func refresh() -> void:
	var value: Variant = _shows.read()
	var words := "" if value == null else str(value)
	if words == _shown:
		return
	_shown = words
	if words != _area.text:
		_area.text = words
		update_minimum_size()
		_indicator.moved()


static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"area").new(ui.chimes, ui.commands, ui.motion, desc.props["action"], desc.props["shows"], desc.props["style"], ui.region(), desc.props["takes_focus"])
	ui.attach(made, parent, desc.facts)
	return made
