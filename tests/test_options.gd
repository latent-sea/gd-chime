extends SceneTree

## What must be true of the named options every description past its first
## few takes, and of the chained names that mark a description already made.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_options.gd
##
## A misspelt option would otherwise be silently ignored - the caller asks
## for a thing and gets the default, with nothing said - so an option none
## of them knows is reported out loud, naming what it was given to and the
## ones it does know, while every option a description does know passes in
## silence. And a chained name marks the description it is chained onto,
## and only that one: two made the same way, one marked, differ.

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Verdict := preload("res://tests/verdict.gd")
const Card := preload("res://addons/gd_chime/components/recipes/card.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")

var _verdict := Verdict.new()
var _hearing := Hearing.new()


## Counts what is pushed as an error, which is how an option check says no.
class Hearing extends Logger:
	var refusals: int = 0
	var said: String = ""

	func _log_error(_function: String, _file: String, _line: int, code: String, _rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_ERROR:
			refusals += 1
			said = code


func _init() -> void:
	await process_frame
	await _verdict.states(_an_option_a_description_does_not_know_is_said_out_loud_naming_the_ones_it_does)
	await _verdict.states(_an_option_a_recipe_does_not_know_is_said_out_loud_too)
	await _verdict.states(_a_chained_name_marks_the_description_it_is_chained_onto_and_no_other)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## A button and a screen, each given an option it knows and then one it
## does not: the first says nothing, the second says what it was given, to
## what, and what it could have been given instead.
func _an_option_a_description_does_not_know_is_said_out_loud_naming_the_ones_it_does() -> void:
	var made := Fixture.new(root, {&"saves": "save"})
	var ui := made.ui

	OS.add_logger(_hearing)
	ui.button(&"saves", {goes_to = &"home"})
	var known := _hearing.refusals
	ui.button(&"saves", {goes_two = &"home"})
	var button_said := _hearing.said
	ui.screen(&"page", [ui.text("a page")], null, {on_fill = Callable()})
	var screens_known := _hearing.refusals
	ui.screen(&"page", [ui.text("a page")], null, {when_filled = Callable()})
	OS.remove_logger(_hearing)

	_verdict.check(known == 0 and screens_known == 1, "an option a button or a screen does know passes in silence")
	_verdict.check(_hearing.refusals == 2, "an option neither knows is said out loud, once each: %d" % _hearing.refusals)
	_verdict.check(button_said.contains("goes_two") and button_said.contains("goes_to"), "and it names the key given and the keys there are: %s" % button_said)
	made.done()


## The same for a recipe, which is where most of the options are.
func _an_option_a_recipe_does_not_know_is_said_out_loud_too() -> void:
	var made := Fixture.new(root, {&"opens": "open"})
	var ui := made.ui
	var thing := Bound.constant({"id": 1, "name": "a pear crate"})

	OS.add_logger(_hearing)
	var before := _hearing.refusals
	Card.list(ui, &"opens", thing, [ui.text("a pear crate")], {goes_to = &"detail"})
	var known := _hearing.refusals
	Card.list(ui, &"opens", thing, [ui.text("a pear crate")], {goes_too = &"detail"})
	OS.remove_logger(_hearing)

	_verdict.check(known == before, "an option a card does know passes in silence")
	_verdict.check(_hearing.refusals == known + 1 and _hearing.said.contains("a list card"), "one it does not is said out loud, naming what took it: %s" % _hearing.said)
	made.done()


## Two texts described the same way, one told to hide while empty: only
## that one is hidden, so the name marked the description it was chained
## onto and nothing else.
func _a_chained_name_marks_the_description_it_is_chained_onto_and_no_other() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes)
	model.set_value(&"words", "")

	var plain: Text = ui.build(ui.text(model.of(&"words")), root)
	var marked: Text = ui.build(ui.text(model.of(&"words")).hides_empty(), root)
	await _a_frame_passes()

	_verdict.check(not marked.visible, "the text told to hide while empty is hidden")
	_verdict.check(plain.visible, "and the one described the same way, without the name, is not")
	plain.queue_free()
	marked.queue_free()
	model.free()
	made.done()
