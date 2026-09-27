extends SceneTree

## What must be true of the text field: a named line of words showing what
## the model holds, refused by the model out loud.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_text_field.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Field := preload("res://addons/gd_chime/components/primitives/field.gd")
const TextField := preload("res://addons/gd_chime/components/recipes/text_field.gd")
const Verdict := preload("res://tests/verdict.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Reads := preload("res://addons/gd_chime/reads.gd")

var _verdict := Verdict.new()
var _hearing := Hearing.new()


## Counts what is pushed as an error, which is how a recipe says no.
class Hearing extends Logger:
	var refusals: int = 0

	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_ERROR:
			refusals += 1


## A model holding words: it takes a line as the words it now holds, and
## keeps the refusal of the last line it was offered.
class Named extends Fixture.Model:
	func get_refusal() -> Variant:
		return of(&"refusal").read()

	func would(action: StringName, payload: Dictionary) -> Phrase:
		var no: Phrase = super(action, payload)
		# kept apart from whatever asks: a press following its refusal must not follow this keeping, or it answers itself
		Reads.apart(func() -> void:
			if no != get_refusal():
				set_value(&"refusal", no))
		return no

	func told(action: StringName, payload: Dictionary) -> Phrase:
		set_value(&"words", payload["line"])
		return super(action, payload)


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	await _verdict.states(_a_text_field_shows_what_the_model_holds_takes_a_line_and_says_a_refusal)
	await _verdict.states(_a_text_field_reports_an_option_it_does_not_know)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


func _texts(node: Node) -> Array[String]:
	var found: Array[String] = []
	for child: Node in node.get_children():
		if child is Text:
			found.append((child as Text).get_text())
		found.append_array(_texts(child))
	return found


func _field_under(node: Node) -> Field:
	return node.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Field)[0]


## The engine on Enter: the line as it stands goes through the door.
func _typed_and_submitted(field: Field, line: String) -> void:
	var edit: LineEdit = field.find_children("*", "LineEdit", true, false)[0]
	edit.text = line
	field._submitted(line)


func _a_text_field_shows_what_the_model_holds_takes_a_line_and_says_a_refusal() -> void:
	var made := Fixture.new(root, {&"names": "name"})
	var ui := made.ui
	var model := Named.new(made.chimes, &"app")
	model.set_value(&"words", "pear")
	model.set_value(&"refusal", "")
	made.commands.register(&"app", &"names", model)
	var made_field := TextField.make(ui, &"names", "what it is called", {holds = model.of(&"words"), says = "the words it goes by", refusal = Bound.new(model.get_refusal)}).named(&"it")
	ui.start(ui.app(&"app", [made_field]))
	await _a_frame_passes()
	var it: Node = ui.node_named(&"it")
	var field := _field_under(it)
	_verdict.check(_texts(it).has("what it is called") and _texts(it).has("the words it goes by") and field.get_line() == "pear", "the label, what it is for, and the words held show: %s in %s" % [field.get_line(), _texts(it)])
	_verdict.check(not _texts(it).has("that name is taken"), "nothing refused, no refusal shows")
	_typed_and_submitted(field, "plum")
	await _a_frame_passes()
	_verdict.check(model.told_actions == [&"names"] and made.commands.get_last()["payload"] == {"line": "plum"}, "a line submitted goes through the door as the action: %s %s" % [model.told_actions, made.commands.get_last()["payload"]])
	# out of the line, as a reader who has moved on: the line is the model's again
	field.find_children("*", "LineEdit", true, false)[0].release_focus()
	model.set_value(&"words", "damson")
	await _a_frame_passes()
	_verdict.check(model.get_words() == "damson" and field.get_line() == "damson", "the field shows the words the model holds, however they came to be held: %s" % [field.get_line()])
	model.refuse(&"names", Phrase.of("that name is taken"))
	_typed_and_submitted(field, "quince")
	await _a_frame_passes()
	_verdict.check(model.told_actions == [&"names"] and model.get_words() == "damson", "a refused name leaves the words held as they were: %s" % [model.get_words()])
	_verdict.check(_texts(it).has("that name is taken"), "and the refusal is said under the field: %s" % [_texts(it)])
	model.free()
	made.done()


## A misspelt option would be silently ignored, so it is said out loud.
func _a_text_field_reports_an_option_it_does_not_know() -> void:
	var made := Fixture.new(root, {&"names": "name"})
	var ui := made.ui
	var model := Named.new(made.chimes, &"app")
	model.set_value(&"words", "pear")
	OS.add_logger(_hearing)
	TextField.make(ui, &"names", "what it is called", {holds = model.of(&"words"), says = "the words it goes by"})
	var before := _hearing.refusals
	TextField.make(ui, &"names", "what it is called", {holds = model.of(&"words"), sayz = "the words it goes by"})
	_verdict.check(before == 0 and _hearing.refusals == 1, "an option the field does not know is reported out loud, and a known one is not: %d" % _hearing.refusals)
	OS.remove_logger(_hearing)
	model.free()
	made.done()
