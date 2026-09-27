extends SceneTree

## What must be true of the text area: words over many lines the model
## holds, broken at the width, growing to the look's most lines and no
## further, sent by a press of their own and never by Enter.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_text_area.gd
##
## Typing is the engine's keys pushed at the window, so the words arrive as
## a reader's do - Enter included - and the engine reports them in its own
## time.

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Area := preload("res://addons/gd_chime/components/primitives/area.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const TextArea := preload("res://addons/gd_chime/components/recipes/text_area.gd")
const Verdict := preload("res://tests/verdict.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")

const CHANGES := &"writes_feedback"
const SENDS := &"sends_feedback"

var _verdict := Verdict.new()
var _hearing := Hearing.new()


## Counts what is pushed as an error, which is how a recipe says no.
class Hearing extends Logger:
	var refusals: int = 0

	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_ERROR:
			refusals += 1


## Feedback: it holds the words being written, refuses to send nothing, and
## once it has sent them, holds none.
class Feedback extends Fixture.Model:
	var sent: Array[String] = []

	func get_draft() -> Variant:
		return of(&"draft").read()

	func would(action: StringName, _payload: Dictionary) -> Phrase:
		if action == SENDS and str(of(&"draft").read()).strip_edges() == "":
			return Phrase.of("nothing written yet")
		return null

	func told(action: StringName, payload: Dictionary) -> Phrase:
		super(action, payload)
		if action == CHANGES:
			set_value(&"draft", payload["text"])
		else:
			sent.append(of(&"draft").read())
			set_value(&"draft", "")
		return null


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(500, 900)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_typing_goes_to_the_model_and_enter_breaks_the_words_without_sending_them)
	await _verdict.states(_the_words_are_sent_by_their_own_press_refused_while_there_are_none)
	await _verdict.states(_the_area_grows_with_its_lines_to_the_look_s_most_and_no_further)
	await _verdict.states(_tab_and_the_pad_walk_the_focus_out_and_type_nothing)
	await _verdict.states(_a_text_area_reports_an_option_it_does_not_know)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## A fixture with the feedback model answering both actions in the app, and
## a text area built over it, as {made, model, area, edit}.
func _written() -> Dictionary:
	var made := Fixture.new(root, {CHANGES: "write", SENDS: "send"})
	var ui := made.ui
	var model := Feedback.new(made.chimes, &"app")
	model.set_value(&"draft", "")
	made.commands.register(&"app", CHANGES, model)
	made.commands.register(&"app", SENDS, model)
	ui.start(ui.app(&"app", [ui.column([TextArea.make(ui, CHANGES, SENDS, {label = Phrase.of("feedback"), holds = Bound.new(model.get_draft), says = Phrase.of("what went well, and what did not")}).named(&"it"), ui.text("below")])]))
	await _a_frame_passes()
	var area: Area = ui.node_named(&"it").find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Area)[0]
	var edit: TextEdit = area.find_children("*", "TextEdit", true, false)[0]
	return {"made": made, "model": model, "area": area, "edit": edit}


func _done(written: Dictionary) -> void:
	(written["model"] as Feedback).free()
	(written["made"] as Fixture).done()


## A key pressed and let go on whatever has the focus, carrying a letter when it types one.
func _key(code: Key, letter: String = "") -> void:
	# the key going down, which types, and then up
	for down: bool in [true, false]:
		var key := InputEventKey.new()
		key.keycode = code
		key.physical_keycode = code
		key.unicode = letter.unicode_at(0) if letter != "" else 0
		key.pressed = down
		root.push_input(key)


## Every letter of these words typed, a space as a space.
func _type(words: String) -> void:
	# each letter in turn, as the key that makes it
	for letter: String in words:
		_key(KEY_SPACE if letter == " " else OS.find_keycode_from_string(letter.to_upper()), letter)


func _send_button() -> Pressable:
	return root.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable and (part as Pressable).action == SENDS)[0]


func _texts(node: Node) -> Array[String]:
	var found: Array[String] = []
	# every text beneath, its words
	for part: Node in node.find_children("*", "Control", true, false):
		if part is Text:
			found.append((part as Text).get_text())
	return found


## Every change is the change action through the door, so the model holds
## what is typed; Enter is a line break in the words and sends nothing.
func _typing_goes_to_the_model_and_enter_breaks_the_words_without_sending_them() -> void:
	var written := await _written()
	var model: Feedback = written["model"]
	(written["area"] as Area).start_typing()
	await _a_frame_passes()
	_type("ripe")
	_key(KEY_ENTER)
	_type("sweet")
	await _a_frame_passes()
	_verdict.check(model.get_draft() == "ripe\nsweet", "the model holds the words typed, Enter a line break in them: %s" % [JSON.stringify(model.get_draft())])
	_verdict.check(model.told_actions.has(CHANGES) and not model.told_actions.has(SENDS), "every change went through the door as the change action, and Enter sent nothing: %s" % [model.told_actions])
	_verdict.check((written["made"] as Fixture).commands.get_last()["payload"] == {"text": "ripe\nsweet"}, "a change carries the words as they stand: %s" % [(written["made"] as Fixture).commands.get_last()["payload"]])
	var caret: int = (written["edit"] as TextEdit).get_caret_column()
	model.set_value(&"draft", "ripe\nsweet")
	await _a_frame_passes()
	_verdict.check((written["edit"] as TextEdit).get_caret_column() == caret and caret == 5, "the model ringing with the words already typed leaves the caret where the reader left it: %d" % (written["edit"] as TextEdit).get_caret_column())
	model.set_value(&"draft", "damson")
	await _a_frame_passes()
	_verdict.check((written["area"] as Area).get_text() == "damson", "and the area shows the words the model holds, however they came to be held: %s" % (written["area"] as Area).get_text())
	_done(written)


## The press beneath is the send action; the door refuses it while there
## is nothing to send and its face says why; sent, the model holds nothing
## and the area follows.
func _the_words_are_sent_by_their_own_press_refused_while_there_are_none() -> void:
	var written := await _written()
	var model: Feedback = written["model"]
	var send := _send_button()
	_verdict.check(not send.is_usable() and _texts(send).has("nothing written yet"), "with nothing written the send press is refused, the reason on its face: %s" % [_texts(send)])
	(written["area"] as Area).start_typing()
	await _a_frame_passes()
	_type("more plums")
	await _a_frame_passes()
	_verdict.check(send.is_usable() and not _texts(send).has("nothing written yet"), "with words written it can be pressed, and says no reason: %s" % [_texts(send)])
	send.grab_focus()
	await _a_frame_passes()
	_key(KEY_ENTER)
	await _a_frame_passes()
	_verdict.check(model.sent == ["more plums"], "the press sent the words the model held: %s" % [model.sent])
	_verdict.check((written["area"] as Area).get_text() == "" and not send.is_usable(), "and sent, the area is empty again and the press refused once more: %s" % (written["area"] as Area).get_text())
	_done(written)


## One line or three is the least; as the words take more lines - broken
## by Enter or at the width - it grows a line at a time; past the most, it
## stays that tall and scrolls inside itself, pushing nothing further.
func _the_area_grows_with_its_lines_to_the_look_s_most_and_no_further() -> void:
	var written := await _written()
	var model: Feedback = written["model"]
	var area: Area = written["area"]
	var edit: TextEdit = written["edit"]
	var least := edit.get_theme_constant(&"least_lines")
	var most := edit.get_theme_constant(&"most_lines")
	var box := edit.get_theme_stylebox(&"normal").get_minimum_size().y
	_verdict.check(least > 1 and most > least, "the look allows more than one line, and more at most than at least: %d %d" % [least, most])
	_verdict.check(is_equal_approx(area.size.y, box + least * edit.get_line_height()), "empty, it is its least lines tall: %f" % area.size.y)
	model.set_value(&"draft", "\n".join(["a", "b", "c", "d", "e"]))
	await _a_frame_passes()
	_verdict.check(area.get_lines_shown() == 5 and is_equal_approx(area.size.y, box + 5 * edit.get_line_height()), "five lines, and it is five lines tall: %d %f" % [area.get_lines_shown(), area.size.y])
	model.set_value(&"draft", "the crates of plums came in this morning and every one of them was ripe and sweet and sound ".repeat(3))
	await _a_frame_passes()
	_verdict.check(edit.get_line_count() == 1 and area.get_lines_shown() > least, "one line far longer than its width is broken onto more than the least, and it grows for them: %d lines at %s" % [area.get_lines_shown(), edit.size])
	var below: Control = root.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Text and (part as Text).get_text() == "below")[0]
	model.set_value(&"draft", "\n".join(range(most + 6).map(func(n: int) -> String: return str(n))))
	await _a_frame_passes()
	var at_most := area.size.y
	var below_at := below.global_position.y
	_verdict.check(area.get_lines_shown() == most and is_equal_approx(at_most, box + most * edit.get_line_height()), "past the most, it is the most lines tall: %d %f" % [area.get_lines_shown(), at_most])
	model.set_value(&"draft", "\n".join(range(most + 20).map(func(n: int) -> String: return str(n))))
	await _a_frame_passes()
	_verdict.check(area.size.y == at_most and below.global_position.y == below_at, "and more lines still push nothing further: %f %f" % [area.size.y, below.global_position.y])
	_done(written)


## Tab walks the focus on out of the area as from any control, typing no
## tab; the pad's direction walks out of it too.
func _tab_and_the_pad_walk_the_focus_out_and_type_nothing() -> void:
	var written := await _written()
	var edit: TextEdit = written["edit"]
	(written["area"] as Area).start_typing()
	await _a_frame_passes()
	_key(KEY_TAB)
	await _a_frame_passes()
	_verdict.check(root.gui_get_focus_owner() == _send_button() and not edit.text.contains("\t"), "Tab moved the focus to the send press and typed nothing: %s %s" % [root.gui_get_focus_owner(), JSON.stringify(edit.text)])
	(written["area"] as Area).start_typing()
	await _a_frame_passes()
	# the pad's direction down, pressed and let go
	for down: bool in [true, false]:
		var pad := InputEventJoypadButton.new()
		pad.button_index = JOY_BUTTON_DPAD_DOWN
		pad.pressed = down
		root.push_input(pad)
	await _a_frame_passes()
	_verdict.check(root.gui_get_focus_owner() == _send_button(), "the pad's direction walked out of it to the press below: %s" % [root.gui_get_focus_owner()])
	_done(written)


## A misspelt option would be silently ignored, so it is said out loud.
func _a_text_area_reports_an_option_it_does_not_know() -> void:
	var made := Fixture.new(root, {CHANGES: "write", SENDS: "send"})
	var model := Feedback.new(made.chimes, &"app")
	model.set_value(&"draft", "")
	OS.add_logger(_hearing)
	TextArea.make(made.ui, CHANGES, SENDS, {label = "feedback", holds = Bound.new(model.get_draft), says = "what went well"})
	var before := _hearing.refusals
	TextArea.make(made.ui, CHANGES, SENDS, {label = "feedback", holds = Bound.new(model.get_draft), sayz = "what went well"})
	_verdict.check(before == 0 and _hearing.refusals == 1, "an option the area does not know is reported out loud, and a known one is not: %d" % _hearing.refusals)
	OS.remove_logger(_hearing)
	model.free()
	made.done()
