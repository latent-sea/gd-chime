extends "../../presentation.gd"

const Commands := preload("../../commands.gd")
const Motion := preload("../../motion.gd")
const ScrollIndicator := preload("scroll_indicator.gd")
const ScrollFinger := preload("scroll_finger.gd")

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
## where the words stand, but draws nothing and takes no room. Taken hold
## of and drawn, the mark scrolls the words.
##
## A FINGER DRAWN ALONG IT SCROLLS THE WORDS, as a finger pans a list
## (scroll_finger.gd), and glides on let go - the finger's pixels handed on
## as the engine's lines. The engine never hears a finger's mouse, which
## would select as it is drawn: lifted where it landed it puts the caret
## there, and held there for the look's long press (Touch/long_press, in
## milliseconds on the one clock) it selects the word under it. A finger
## landing on the words while they are not being typed in gives them no
## focus until it lifts - the engine hands the focus to what a press lands
## on before that hears it - so a finger drawn along them brings up no
## keyboard. The mouse is the engine's as ever: drawn, it selects.
##
## Reached like any control: a click, or the focus walked to it. Tab and
## Shift+Tab walk the focus on out of it, never typed into it; the pad's
## directions walk out of it too - measured on 4.6.2, they move no caret -
## while the keyboard's arrows move the caret, as in any typed line. Its
## look is its style's, a variation of TextEdit.
##
## Deliberately absent: an on-screen keyboard, a count of what is left, the
## words' own history, and handles a finger draws to widen a selection.

var _commands: Commands
var _motion: Motion
var _changes: StringName  # the action every change is dispatched as
var _shows: RefCounted  # the Bound the area is set to whenever it moves
var _area := TextEdit.new()
var _indicator: ScrollIndicator  # where the reader is in the words, over the engine's own
var _finger: ScrollFinger  # a finger scrolling the words, in lines
var _on_words := Touch.Tap.new()  # a finger on the words, read as a tap or a gesture
var _holding: Motion.Run = null  # the wait for a long press while the finger stays still, or none
var _at := Vector2.ZERO  # where the finger came down, in the words' own pixels
var _worded: bool = false  # whether the finger down now has selected a word by holding still
var _takes_focus: bool
var _shown: Variant = null  # the value it showed when it last looked


func _init(chimes: Chimes, commands: Commands, motion: Motion, changes: StringName, shows: RefCounted, style: StringName, in_region: StringName, takes_focus: bool) -> void:
	super(chimes, [], in_region)
	_commands = commands
	_motion = motion
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
	_finger = ScrollFinger.new(_area, motion, bar, null)
	_indicator = ScrollIndicator.new(motion, bar, _area, &"normal", _finger.stop)
	_area.add_child(_indicator, false, Node.INTERNAL_MODE_BACK)
	add_to_group(Touch.TAKES)
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


## A finger landing on the words while they are not being typed in: they
## take no focus until it lifts.
func _input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click == null or not Touch.from_finger(click):
		return
	if not click.pressed:
		_area.focus_mode = Control.FOCUS_ALL
	elif not _area.has_focus() and Rect2(Vector2.ZERO, _area.size).has_point(_area.make_input_local(click).position):
		_area.focus_mode = Control.FOCUS_NONE


## Anything the reader does in it - a wheel, a finger, a key - may move the
## words: where they are is looked at. A finger's mouse goes no further:
## lifted where it landed it puts the caret there, and held there it
## selects the word.
func _touched(event: InputEvent) -> void:
	_indicator.moved()
	if not Touch.from_finger(event):
		return
	_area.accept_event()
	var click := event as InputEventMouseButton
	var tapped := _on_words.read(event, _area)
	var lasts := _area.get_theme_constant(&"long_press", Touch.TYPE)
	if click != null and click.pressed:
		_worded = false
		_at = click.position
		if lasts > 0:
			_holding = _motion.wait(lasts / 1000.0, _held)
	# moved past the slop or lifted, it is no long press
	if not _on_words.is_down() and _holding != null:
		_holding.stopped = true
		_holding = null
	if tapped and not _worded:
		_caret_to(click.position)


## The finger held still as long as a long press lasts: the word under it selected.
func _held() -> void:
	_holding = null
	_worded = true
	_caret_to(_at)
	_area.select_word_under_caret()


## The caret put at this point of the words, nothing selected, and typing sent here.
func _caret_to(at: Vector2) -> void:
	var place := _area.get_line_column_at_pos(Vector2i(at))
	_area.focus_mode = Control.FOCUS_ALL
	_area.grab_focus()
	_area.deselect()
	_area.set_caret_line(place.y, false)
	_area.set_caret_column(place.x, false)


## A finger along the words, where they can move for it: its own (touch.gd).
func takes_finger(axis: StringName, travel: Vector2) -> bool:
	return _finger.takes(axis, travel)


## The finger moving the words: its pixels are handed on as the engine's lines.
func finger_moved(_travel: Vector2, relative: Vector2) -> void:
	_finger.moved(relative / _area.get_line_height())


func finger_ended(velocity: Vector2) -> void:
	_finger.ended(velocity / _area.get_line_height())


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
