extends SceneTree

## What must be true of a finger on a text area: drawn along it, it scrolls
## the words and glides on, selecting nothing and bringing up no keyboard; a
## tap puts the caret where it landed and a long press selects the word
## there - while a mouse drawn across it still selects, as on a desktop.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_text_area_finger.gd
##
## At a phone's shape, a text area of forty lines, more than it shows. The
## touches go in as a device's do, through Input.parse_input_event, so the
## engine makes its mouse from them first (touch.gd); the mouse goes in at
## the window. The clock is stepped by hand.

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Touch := preload("res://addons/gd_chime/touch.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Verdict := preload("res://tests/verdict.gd")

## A phone held upright, in pixels.
const PHONE := Vector2i(540, 1200)
const WRITES := &"writes_words"

var _verdict := Verdict.new()
var _made: Fixture
var _words: Words
var _edit: TextEdit


## Words to write in: whatever it is told, held.
class Words extends Fixture.Model:
	func get_words() -> Variant:
		return of(&"words").read()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = PHONE
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_a_finger_drawn_up_it_scrolls_the_words_with_it_selecting_nothing_and_giving_it_no_focus)
	await _verdict.states(_let_go_moving_the_words_glide_on_the_clock_and_reduced_they_stop_dead)
	await _verdict.states(_a_tap_puts_the_caret_where_the_finger_landed)
	await _verdict.states(_a_finger_held_still_selects_the_word_under_it)
	await _verdict.states(_a_mouse_drawn_across_it_still_selects)
	quit(_verdict.deliver(get_script()))


## A text area of forty lines, the whole of the window across, the clock stepped by hand.
func _written() -> void:
	_made = Fixture.new(root, {WRITES: "write"})
	var ui := _made.ui
	_words = Words.new(_made.chimes, &"app")
	_words.set_value(&"words", "\n".join(range(40).map(func(at: int) -> String: return "line %d word" % at)))
	_made.commands.register(&"app", WRITES, _words)
	ui.start(ui.app(&"app", [ui.column([ui.area(WRITES, Bound.new(_words.get_words)).named(&"it")])]))
	ui.motion.by_hand = true
	# the frames the start and its first layout take
	for frame: int in 3:
		await process_frame
	_edit = ui.node_named(&"it").find_children("*", "TextEdit", true, false)[0]


func _done() -> void:
	_words.free()
	_made.done()


## Where a line and column of the words is drawn, on the canvas: the middle of its letter.
func _at_letter(line: int, column: int) -> Vector2:
	return _edit.get_global_transform() * Rect2(_edit.get_rect_at_line_column(line, column)).get_center()


## How far the words have scrolled, in pixels.
func _scrolled() -> float:
	return _edit.get_v_scroll_bar().value * _edit.get_line_height()


func _touch(at: Vector2, down: bool) -> void:
	var touched := InputEventScreenTouch.new()
	touched.position = at
	touched.pressed = down
	Input.parse_input_event(touched)
	await process_frame


## A finger drawn from a point by these steps, a frame each; lifted where it ends if asked.
func _drawn(at: Vector2, steps: Array, lifts: bool = true) -> void:
	await _touch(at, true)
	var now := at
	# every step, one drag a frame
	for step: Vector2 in steps:
		now += step
		var drag := InputEventScreenDrag.new()
		drag.position = now
		drag.relative = step
		Input.parse_input_event(drag)
		await process_frame
	if lifts:
		await _touch(now, false)


## The words not being typed in, drawn 240 pixels up: the words follow it
## the whole way, to the pixel, nothing is selected, the caret stays where
## it was, and the area never takes the focus a phone's keyboard comes up with.
func _a_finger_drawn_up_it_scrolls_the_words_with_it_selecting_nothing_and_giving_it_no_focus() -> void:
	await _written()
	_edit.release_focus()
	var at := _edit.get_global_rect().get_center()
	await _drawn(at, [Vector2(0, -60), Vector2(0, -60), Vector2(0, -60), Vector2(0, -60)], false)
	var held := _scrolled()
	var landed_focus := _edit.has_focus()
	await _touch(at + Vector2(0, -240), false)
	_verdict.check(absf(held - 240.0) < 1.0, "the words followed the finger 240 pixels up: %.1f" % held)
	_verdict.check(_edit.get_selected_text() == "" and _edit.get_caret_line() == 0, "and nothing was selected nor the caret moved: '%s', line %d" % [_edit.get_selected_text(), _edit.get_caret_line()])
	_verdict.check(not landed_focus and not _edit.has_focus(), "the area never took the focus, down or lifted")
	_done()


func _let_go_moving_the_words_glide_on_the_clock_and_reduced_they_stop_dead() -> void:
	await _written()
	var motion := _made.ui.motion
	motion.still = false
	var at := _edit.get_global_rect().get_center()
	await _drawn(at, [Vector2(0, -40), Vector2(0, -60), Vector2(0, -60)], false)
	var let_go := _scrolled()
	await _touch(at + Vector2(0, -160), false)
	var lifted := _scrolled()
	motion.step(1.0)
	var glided := _scrolled()
	_verdict.check(lifted == let_go and glided > let_go, "let go moving up, the words glide on further, on the clock and not before: %.1f, %.1f, then %.1f" % [let_go, lifted, glided])
	motion.told(motion.REDUCES, {"on": true})
	# drawn back down, from wherever the glide left it, so there is room to glide either way
	await _drawn(at, [Vector2(0, 40), Vector2(0, 60), Vector2(0, 60)], false)
	let_go = _scrolled()
	await _touch(at + Vector2(0, 160), false)
	motion.step(1.0)
	_verdict.check(let_go > 0.0 and _scrolled() == let_go, "with motion reduced, they stop dead where the finger left them: %.1f then %.1f" % [let_go, _scrolled()])
	motion.told(motion.REDUCES, {"on": false})
	_done()


## The words not being typed in, down and lifted on the seventh letter of
## the third line: the caret is there, the area has the focus, and nothing
## is selected.
func _a_tap_puts_the_caret_where_the_finger_landed() -> void:
	await _written()
	_edit.release_focus()
	await _touch(_at_letter(2, 7), true)
	await _touch(_at_letter(2, 7), false)
	_verdict.check(_edit.get_caret_line() == 2 and _edit.get_caret_column() == 7, "the caret is where the finger landed: line %d, column %d" % [_edit.get_caret_line(), _edit.get_caret_column()])
	_verdict.check(_edit.has_focus() and _edit.get_selected_text() == "", "the area has the focus, and nothing is selected")
	_done()


## Down on the word of the third line: nothing is selected just short of
## the look's long press, the word once it has passed, and it stays
## selected as the finger lifts.
func _a_finger_held_still_selects_the_word_under_it() -> void:
	await _written()
	var lasts := _edit.get_theme_constant(&"long_press", Touch.TYPE) / 1000.0
	await _touch(_at_letter(2, 8), true)
	_made.ui.motion.step(lasts - 0.01)
	await process_frame
	var short := _edit.get_selected_text()
	_made.ui.motion.step(0.02)
	await process_frame
	var held := _edit.get_selected_text()
	await _touch(_at_letter(2, 8), false)
	_verdict.check(lasts > 0.0 and short == "" and held == "word", "held just short of the long press nothing is selected, and held past it the word is: '%s', then '%s'" % [short, held])
	_verdict.check(_edit.get_selected_text() == "word" and _edit.has_focus(), "lifted, the word stays selected, the area with the focus: '%s'" % _edit.get_selected_text())
	_done()


## A mouse's event at a point of the window, as a mouse sends it: through
## Input, which takes where the pointer is from its global position - where
## the engine's drawn selection reads it from.
func _mouse(event: InputEventMouse, at: Vector2) -> void:
	event.position = at
	event.global_position = at
	Input.parse_input_event(event)
	await process_frame


## The mouse's button down on the first line and drawn to the third selects
## what it crossed, and scrolls nothing.
func _a_mouse_drawn_across_it_still_selects() -> void:
	await _written()
	await _mouse(InputEventMouseMotion.new(), _at_letter(0, 0))
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.button_mask = MOUSE_BUTTON_MASK_LEFT
	click.pressed = true
	await _mouse(click, _at_letter(0, 0))
	var move := InputEventMouseMotion.new()
	move.button_mask = MOUSE_BUTTON_MASK_LEFT
	move.relative = _at_letter(2, 4) - _at_letter(0, 0)
	await _mouse(move, _at_letter(2, 4))
	click.pressed = false
	click.button_mask = 0
	await _mouse(click, _at_letter(2, 4))
	_verdict.check(_edit.get_selected_text().begins_with("line 0 word\nline 1"), "the mouse drawn from the first line to the third selects what it crossed: '%s'" % _edit.get_selected_text())
	_verdict.check(_scrolled() == 0.0, "and scrolls nothing: %.1f" % _scrolled())
	_done()
