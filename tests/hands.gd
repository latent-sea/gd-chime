extends RefCounted

const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Applier := preload("res://addons/gd_chime/applier.gd")
const Clipped := preload("res://addons/gd_chime/clipped_text.gd")
const DrawnOver := preload("res://addons/gd_chime/drawn_over.gd")
const Faint := preload("res://addons/gd_chime/faint_words.gd")
const ActionControl := preload("res://addons/gd_chime/action_control.gd")
const Options := preload("res://addons/gd_chime/components/primitives/options.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")

## A pair of hands on a running application: what a reader does, done the
## way a reader does it, and what a reader sees, read the way a reader sees
## it. The one set for every test and every probe.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## IT IS MADE WITH THE TREE THE APPLICATION STANDS IN - a SceneTree holding
## root, ui, driver and commands, which is what every demo's main script is
## and what tests/fixture.gd composes - and it reaches nothing else.
##
## EVERY PRESS GOES IN AT THE WINDOW, never called on a control: a click at
## the middle of what it presses, a key or a pad button down and then up to
## whatever holds the focus - so the engine decides what is pressed and
## walked to, as it does for a person, and a claim that a thing works by a
## hand is a claim the hand reaches it. A POINT IS THE CANVAS'S, turned to
## the window's own pixels as it goes in, since the canvas is stretched to
## the window and a point of one is not a point of the other; so a press
## lands where the control is drawn at every window shape. press(action) is the one
## exception and lands the press on the control itself: a probe walking to
## a button it has already shown is reachable says nothing new by walking
## there again, and the walk is what the keys' claims are for.
##
## WHAT IS SHOWN IS NOT WHAT IS VISIBLE. A place being seen out is still
## drawn while its motion runs, and nothing in it can be pressed; a place
## under a pop-up is drawn and dead. shown() is the only honest answer -
## the node is visible in the tree AND every place it stands inside is one
## the driver's state names - and it is here so that no probe reaches for
## the applier or the driver's index to ask.
##
## IT ASSERTS NOTHING. A claim is the caller's: this presses, types, walks,
## reads and says what stands where, and a probe or a test decides what
## that has to be.
##
## Deliberately absent: a wait on a condition. A hand waits frames or
## seconds, as a person does; a loop until something is true belongs to the
## probe that knows what it is waiting for.

## What a press may be asked for (press_of, presses_of, press): carrying, a
## payload every key of which the press's own payload must match; at, which
## of several, in the order they stand across and down; under, the node to
## look inside, the whole window by default.
const FINDING: Array[String] = ["carrying", "at", "under"]

var _app: SceneTree
var _pointer := Vector2.ZERO  # where the pointer was last put, so a move says how far it went
var _faint: Array[String] = []  # every set of words found too faint against its ground, with where it was first seen
var _faint_seen: Dictionary = {}  # those same sentences as a set: one screen is judged again and again, and the same faint words are one finding


func _init(app: SceneTree) -> void:
	_app = app


## --- time ---

## Frames enough for a press to land, a move to be laid out and drawn, and
## the one clock to run on past whatever it set moving - a piece growing in,
## a list re-ordering - so the next press finds everything where it came to rest.
func frames(count: int = 3) -> void:
	# each frame in turn, the clock run on after the first
	for waited: int in count:
		await _app.process_frame
		if waited == 0:
			_app.ui.motion.step(2.0)


## Frames without the clock touched: for a probe timing something that runs on its own.
func plain_frames(count: int = 3) -> void:
	# the frames asked for, each passing
	for waited: int in count:
		await _app.process_frame


## Real seconds passing, and then the frames for what they brought to land.
func seconds(waiting: float) -> void:
	await _app.create_timer(waiting).timeout
	await plain_frames(2)


## --- the door ---

## An action told through the door, as a press of it would.
func does(region: StringName, action: StringName, payload: Dictionary = {}) -> Phrase:
	return _app.commands.dispatch(region, action, payload)


## The reader taken to a place, entered as this.
func goes(named: StringName, parameter: Variant = null) -> void:
	does(Chimes.GLOBAL, Driver.GO, {"place": named, "parameter": parameter})
	await frames()


## The reader taken back where they came from.
func goes_back() -> void:
	does(Chimes.GLOBAL, Driver.GOES_BACK, {})
	await frames()


## --- pressing ---

## Every press of this action the reader can see now, in the order they
## stand across and down (FINDING).
func presses_of(action: StringName, finding: Dictionary = {}) -> Array:
	Options.checked("finding a press", finding, FINDING)
	var under: Node = finding.get("under", _app.ui.root)
	var carrying: Dictionary = finding.get("carrying", {})
	var found: Array = under.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is ActionControl and (part as ActionControl).action == action and shown(part) and _carrying(part, carrying))
	found.sort_custom(func(a: Control, b: Control) -> bool: return a.global_position.x < b.global_position.x if a.global_position.y == b.global_position.y else a.global_position.y < b.global_position.y)
	return found


## Whether a press carries every key of this, as it carries them.
func _carrying(press: Node, carrying: Dictionary) -> bool:
	var payload: Dictionary = press.payload()
	# every key asked for, for one the press does not carry so
	for key: Variant in carrying:
		if not payload.has(key) or payload[key] != carrying[key]:
			return false
	return true


## The one press of this action the reader can see, or the one at this
## place among several; nothing where there is none (FINDING).
func press_of(action: StringName, finding: Dictionary = {}) -> Control:
	var found := presses_of(action, finding)
	var at: int = finding.get("at", 0)
	return found[at] if at < found.size() else null


## That press pressed, and the frames after it.
func press(action: StringName, finding: Dictionary = {}) -> void:
	press_of(action, finding).pressed()
	await frames()


## The left button down and up at the middle of this control, the pointer
## brought over it first - a menu's target opens over whatever the pointer
## is over, and a hover state is a pointer that arrived.
func click(on: Control, which: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	await move_to(on)
	var at := middle_of(on)
	# the button going down, then up, where it stands
	for down: bool in [true, false]:
		await button(at, down, which)
	await frames()


## A right press on a control.
func right_click(on: Control) -> void:
	await click(on, MOUSE_BUTTON_RIGHT)


## The pointer moved over this control, with nothing held.
func move_to(on: Control) -> void:
	move(middle_of(on), false)
	await plain_frames(1)


## The pointer moved to a point of the canvas, the button held or not: a
## move says how far it went, which is what the engine's drag counts before
## it begins.
func move(at: Vector2, held: bool) -> void:
	var moved := InputEventMouseMotion.new()
	moved.position = _on_window(at)
	moved.relative = _on_window(at) - _on_window(_pointer)
	moved.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	_pointer = at
	_app.ui.root.get_window().push_input(moved)


## A button down or up at a point of the canvas.
func button(at: Vector2, down: bool, which: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = which
	press.pressed = down
	press.button_mask = MOUSE_BUTTON_MASK_LEFT if down and which == MOUSE_BUTTON_LEFT else 0
	press.position = _on_window(at)
	_app.ui.root.get_window().push_input(press)
	await plain_frames(1)


## The pointer brought here, the left button pressed, held while it moves
## there, and let go there - points of the canvas. It is brought here first
## so that the move says how far it went from the press, which is what a
## drag reads.
func drag(from: Vector2, to: Vector2) -> void:
	move(from, false)
	await plain_frames(1)
	await button(from, true)
	await plain_frames(1)
	move(to, true)
	await plain_frames(1)
	await button(to, false)
	await frames()


## The middle of a control, in the canvas.
func middle_of(control: Control) -> Vector2:
	return control.get_global_rect().get_center()


## A point of the canvas where the window's pointer is over it: the canvas
## is stretched to the app's viewport, so a point of one is not a point of
## the other; and an app on an easel stands somewhere in the window, so the
## easel's place is added. Input goes in through the WINDOW, never the
## app's viewport: the engine walks a pointer down into a viewport from the
## window it is in, and what is hovered is only ever known that way.
func _on_window(at: Vector2) -> Vector2:
	var viewport: Viewport = _app.ui.root.get_viewport()
	var placed: Vector2 = viewport.get_final_transform() * at
	return placed if viewport is Window else (viewport.get_parent() as Control).global_position + placed


## --- a finger ---

## A finger down or lifted at a point of the canvas. IT GOES IN THROUGH
## Input.parse_input_event, as a touchscreen's does, so the engine makes its
## mouse from it first (touch.gd) - never through the window's push_input,
## which makes no mouse and would test a hand no device has.
func touch(at: Vector2, down: bool) -> void:
	var touched := InputEventScreenTouch.new()
	touched.position = _on_window(at)
	touched.pressed = down
	Input.parse_input_event(touched)
	await _app.process_frame


## A tap: a finger down and lifted at the middle of this control.
func tap(on: Control) -> void:
	await touch(middle_of(on), true)
	await touch(middle_of(on), false)


## A finger down on a control's middle, drawn this far in so many steps -
## one drag a frame - and lifted where it ended, unless it is held there;
## where it ended, in the canvas.
func drawn(on: Control, by: Vector2, steps: int, lifts: bool = true) -> Vector2:
	var at := await draws_on(middle_of(on), by, steps, true)
	await touch(at, false)
	return at


## A finger drawn from a point of the canvas this far in so many steps -
## one drag a frame - put down there first where it is not already down;
## where it ended. It is left held, for a pull that goes on.
func draws_on(from: Vector2, by: Vector2, steps: int, lands: bool = false) -> Vector2:
	if lands:
		await touch(from, true)
	var at := from
	# every step, one drag a frame
	for step: int in steps:
		at += by / steps
		var drag := InputEventScreenDrag.new()
		drag.position = _on_window(at)
		drag.relative = _app.ui.root.get_viewport().get_final_transform().basis_xform(by / steps)
		Input.parse_input_event(drag)
		await _app.process_frame
	return at


## --- keys, the pad, and typing ---

## A key down and up, typing this letter if it types one, with these
## modifiers held: ctrl, shift, alt.
func key(code: Key, letter: String = "", modifiers: Array = []) -> void:
	# the key going down, which types, then up
	for down: bool in [true, false]:
		var press := InputEventKey.new()
		press.keycode = code
		press.physical_keycode = code
		press.unicode = letter.unicode_at(0) if letter != "" else 0
		press.ctrl_pressed = modifiers.has(&"ctrl")
		press.shift_pressed = modifiers.has(&"shift")
		press.alt_pressed = modifiers.has(&"alt")
		press.pressed = down
		_app.ui.root.get_window().push_input(press)
	await frames()


## A pad button down and up.
func pad(button: JoyButton) -> void:
	# the button going down, then up
	for down: bool in [true, false]:
		var press := InputEventJoypadButton.new()
		press.button_index = button
		press.pressed = down
		_app.ui.root.get_window().push_input(press)
	await frames()


## Every letter of these words typed into whatever holds the focus, a space
## as a space: a key at a time, as a person types them.
func types(words: String) -> void:
	# each letter, as the key that makes it
	for letter: String in words:
		await key(KEY_SPACE if letter == " " else OS.find_keycode_from_string(letter.to_upper()), letter)


## The first line under this node given the focus, emptied, and these words
## typed into it.
func types_into(under: Node, words: String) -> void:
	var line: LineEdit = under.find_children("*", "LineEdit", true, false)[0]
	line.grab_focus()
	line.select_all()
	await key(KEY_BACKSPACE)
	await types(words)


## --- what the reader sees ---

## Whether the reader can see this node: it is visible in the tree, and
## every place it stands inside is one the driver's state names - a place
## being seen out is drawn for its motion, and nothing in it can be pressed.
func shown(node: Node) -> bool:
	return (node as Control).is_visible_in_tree() and Applier.shows(_app.driver.get_state(), node, _app.driver.index)


## The node of the place of this name, whether or not it is on the screen.
func place(named: StringName) -> Node:
	return _app.driver.index.place_named(named)


## Whether a place of this name stands in the tree at all.
func has_place(named: StringName) -> bool:
	return _app.driver.index.has_place(named)


## Every set of words the reader can see under this node - the whole window
## by default - in tree order, as they are drawn in the language on.
func words(under: Node = null) -> Array:
	var node: Node = _app.ui.root if under == null else under
	return node.find_children("*", "Label", true, false).filter(func(label: Node) -> bool: return shown(label)).map(func(label: Node) -> String: return (label as Label).text)


## Every set of words drawn within this node, whether or not the place it
## stands in is still one the reader is on: a place being seen out is drawn
## for its motion, and what it says is worth reading while it is.
func words_within(under: Node) -> Array:
	return under.find_children("*", "Label", true, false).filter(func(label: Node) -> bool: return (label as Label).visible).map(func(label: Node) -> String: return (label as Label).text)


## Every set of words a text primitive draws under this node, in tree order:
## what a description put there, where words() takes every label the engine holds.
func texts(under: Node = null) -> Array:
	var node: Node = _app.ui.root if under == null else under
	return node.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Text and shown(part)).map(func(part: Node) -> String: return (part as Text).get_text())


## The first set of words saying exactly this that the reader can see, in
## tree order, or nothing: the label itself, to point at or to walk up from.
func saying(said: String, under: Node = null) -> Control:
	var node: Node = _app.ui.root if under == null else under
	var found: Array = node.find_children("*", "Label", true, false).filter(func(label: Node) -> bool: return (label as Label).text == said and shown(label))
	return found[0] if not found.is_empty() else null


## Whether words saying exactly this stand where the reader can see them.
func shows_words(said: String, under: Node = null) -> bool:
	return saying(said, under) != null


## Whether words beginning this way stand where the reader can see them.
func shows_words_beginning(said: String, under: Node = null) -> bool:
	return words(under).any(func(one: String) -> bool: return one.begins_with(said))


## What holds the focus now.
func focused() -> Control:
	return _app.ui.root.get_viewport().gui_get_focus_owner()


## Whether what holds the focus stands under this node.
func focus_under(node: Node) -> bool:
	var holder := focused()
	return holder != null and node.is_ancestor_of(holder)


## --- the window judged ---

## The window judged as it stands, every move's motion run to its end first:
## every set of words cut off and every thing drawn over another, each said
## with what is showing and the shape, added to these - and every set of
## words too faint against its ground, which these hands keep themselves,
## since a probe asks for them by get_faint() rather than carrying a third
## array through every call it makes.
func judged(showing: Variant, shape: Vector2i, cut: Array, over: Array) -> void:
	await frames(4)
	_app.ui.motion.step(10.0)
	await plain_frames(2)
	# every set of words cut here
	for sentence: String in Clipped.clipped(_app.ui.root, _app.ui.root.get_viewport().get_visible_rect()):
		cut.append("%s at %s: %s" % [showing, shape, sentence])
	# and every thing drawn over another
	for sentence: String in DrawnOver.covered(_app.ui.root, _app.ui.root.get_viewport().get_visible_rect()):
		over.append("%s at %s: %s" % [showing, shape, sentence])
	# and every set of words too faint to read against what it stands on, in the look worn
	for sentence: String in Faint.faint(_app.ui.root):
		if not _faint_seen.has(sentence):
			_faint_seen[sentence] = true
			_faint.append("%s at %s: %s" % [showing, shape, sentence])


## Every set of words too faint against its ground, found by every judging
## these hands have done: a claim of the probe's, as cut and covered are.
func get_faint() -> Array[String]:
	return _faint


## Every set of words cut, every thing drawn over and every set too faint,
## said one by one, so a failure names them rather than counting them.
func say_every(cut: Array, over: Array) -> void:
	# every set of words cut
	for sentence: String in cut:
		print("PROBE CLIPPED " + sentence)
	# and every thing drawn over
	for sentence: String in over:
		print("PROBE DRAWN OVER " + sentence)
	# and every set of words too faint against its ground
	for sentence: String in _faint:
		print("PROBE FAINT " + sentence)
