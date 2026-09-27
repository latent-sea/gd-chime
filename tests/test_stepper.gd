extends SceneTree

## What must be true of a number stepper: the minus and the plus step the
## model's number through the door, held between its ends; a typed number
## is snapped to the step and held, a line that is no number changes
## nothing; a number the door refuses is not the model's, and the press that
## would ask for it is inert; and it is walked by the keys and the pad.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_stepper.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Field := preload("res://addons/gd_chime/components/primitives/field.gd")
const Stepper := preload("res://addons/gd_chime/components/recipes/stepper.gd")
const Verdict := preload("res://tests/verdict.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Fields := preload("res://addons/gd_chime/theme_fields.gd")

var _verdict := Verdict.new()


## A count: set to whatever it is told, refusing the one number it will not have.
class Count extends Fixture.Model:
	var said: Array = []  # every value it was told, in order
	var unlucky: float = -1.0

	func get_count() -> Variant:
		return of(&"count").read()

	func would(_action: StringName, payload: Dictionary) -> Phrase:
		return Phrase.of("not that one") if is_equal_approx(payload["value"], unlucky) else null

	func told(action: StringName, payload: Dictionary) -> Phrase:
		told_actions.append(action)
		said.append(payload["value"])
		set_value(&"count", payload["value"])
		return null


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(400, 400)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_the_minus_and_the_plus_step_the_model_s_number_through_the_door_held_between_its_ends)
	await _verdict.states(_a_typed_number_is_snapped_to_the_step_and_held_and_a_line_that_is_no_number_changes_nothing)
	await _verdict.states(_a_number_the_door_refuses_is_not_asked_and_the_press_that_would_ask_for_it_is_inert)
	await _verdict.states(_the_steps_alone_carry_what_a_press_worth_that_much_carries_around_what_shows)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## The app holding one stepper over the count, arrived at: its minus, its field and its plus.
func _app(made: Fixture, count: Count, minimum: float, maximum: float, step: float) -> Array:
	var ui := made.ui
	made.commands.register(&"app", &"counts", count)
	ui.start(ui.app(&"app", [Stepper.make(ui, &"counts", Bound.new(count.get_count), {minimum = minimum, maximum = maximum, step = step}).named(&"stepper")]))
	var stepper: Node = ui.node_named(&"stepper")
	var parts := stepper.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable or part is Field)
	return [stepper] + parts


## Typed as a person types it into the line, and Enter pressed there.
func _typed(field: Field, line: String) -> void:
	var edit: LineEdit = field.find_children("*", "LineEdit", true, false)[0]
	edit.grab_focus()
	edit.text = line
	var enter := InputEventKey.new()
	enter.keycode = KEY_ENTER
	enter.pressed = true
	root.push_input(enter)


## Whether two lists of numbers agree, each to within a hair.
func _near(a: Array, b: Array) -> bool:
	return a.size() == b.size() and range(a.size()).all(func(index: int) -> bool: return is_equal_approx(a[index], b[index]))


func _the_minus_and_the_plus_step_the_model_s_number_through_the_door_held_between_its_ends() -> void:
	var made := Fixture.new(root, {&"counts": "count"})
	var count := Count.new(made.chimes, &"app")
	count.set_value(&"count", 2.0)
	var parts := _app(made, count, 0.0, 3.0, 1.0)
	await _a_frame_passes()
	var minus: Pressable = parts[1]
	var field: Field = parts[2]
	var plus: Pressable = parts[3]
	_verdict.check(field.get_line() == "2", "the field shows the model's number: %s" % field.get_line())
	plus.pressed()
	await _a_frame_passes()
	_verdict.check(_near(count.said, [3.0]) and made.commands.get_last()["payload"].keys() == ["value"] and field.get_line() == "3", "the plus asks the door for a step up, as {value}, and the field shows what the model has now: %s %s" % [count.said, field.get_line()])
	plus.pressed()
	await _a_frame_passes()
	_verdict.check(_near(count.said, [3.0, 3.0]), "at the maximum, the plus carries the maximum and never past it: %s" % [count.said])
	# down from the top to past the bottom, a press at a time
	for press: int in range(4):
		minus.pressed()
		await _a_frame_passes()
	_verdict.check(_near(count.said, [3.0, 3.0, 2.0, 1.0, 0.0, 0.0]) and field.get_line() == "0", "the minus steps down, and at the minimum carries the minimum: %s" % [count.said])
	_verdict.check(made.ui.node_named(&"stepper").theme_type_variation == Fields.STEPPER, "the row wears the stepper's style")
	_verdict.check(minus.find_next_valid_focus() == field.find_children("*", "LineEdit", true, false)[0] and field.find_children("*", "LineEdit", true, false)[0].find_next_valid_focus() == plus, "the keys and the pad walk from the minus into the number and on to the plus")
	count.free()
	made.done()


func _a_typed_number_is_snapped_to_the_step_and_held_and_a_line_that_is_no_number_changes_nothing() -> void:
	var made := Fixture.new(root, {&"counts": "count"})
	var count := Count.new(made.chimes, &"app")
	count.set_value(&"count", 1.0)
	var parts := _app(made, count, 0.0, 10.0, 0.5)
	await _a_frame_passes()
	var field: Field = parts[2]
	_typed(field, "7.3")
	await _a_frame_passes()
	_verdict.check(_near(count.said, [7.5]) and made.commands.get_last()["payload"].keys() == ["value"] and field.get_line() == "7.5", "a typed number goes through the door as {value}, snapped to the step: %s %s" % [count.said, field.get_line()])
	_typed(field, "a lot")
	await _a_frame_passes()
	_verdict.check(_near(count.said, [7.5, 7.5]) and count.get_count() == 7.5, "a line that is no number carries the number as it stands: %s" % [count.said])
	_typed(field, "42")
	await _a_frame_passes()
	_typed(field, "-3")
	await _a_frame_passes()
	_verdict.check(_near(count.said, [7.5, 7.5, 10.0, 0.0]), "a number typed past an end is held at that end: %s" % [count.said])
	count.free()
	made.done()


func _a_number_the_door_refuses_is_not_asked_and_the_press_that_would_ask_for_it_is_inert() -> void:
	var made := Fixture.new(root, {&"counts": "count"})
	var count := Count.new(made.chimes, &"app")
	count.set_value(&"count", 12.0)
	count.unlucky = 13.0
	var parts := _app(made, count, 0.0, 20.0, 1.0)
	await _a_frame_passes()
	var minus: Pressable = parts[1]
	var field: Field = parts[2]
	var plus: Pressable = parts[3]
	_verdict.check(plus.get_state() == &"inert" and str(plus.get_reason()) == "not that one" and minus.get_state() != &"inert", "the plus would ask for a number the door refuses: it is inert, and says why: %s" % plus.get_state())
	plus.pressed()
	_typed(field, "13")
	await _a_frame_passes()
	_verdict.check(count.said.is_empty() and str(made.commands.get_last()["answer"]) == "not that one" and count.get_count() == 12.0, "neither the press nor the typing changes the model: the door refused it: %s" % [count.said])
	count.free()
	made.done()


## The steps on their own over a basket line: each press carries the line's
## id and how many more, a word standing between the two.
func _the_steps_alone_carry_what_a_press_worth_that_much_carries_around_what_shows() -> void:
	var made := Fixture.new(root, {&"counts": "count"})
	var lines := Fixture.Model.new(made.chimes, &"app")
	var ui := made.ui
	made.commands.register(&"app", &"counts", lines)
	var carries := func(by: float) -> Dictionary: return {"id": 4, "by": int(by)}
	ui.start(ui.app(&"app", [Stepper.steps(ui, &"counts", {shows = ui.text("four figs"), carries = carries, step = 2.0}).named(&"steps")]))
	await _a_frame_passes()
	var parts: Array = ui.node_named(&"steps").find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable)
	_verdict.check(parts.size() == 2 and parts[0].payload() == {"id": 4, "by": -2} and parts[1].payload() == {"id": 4, "by": 2}, "the two presses carry what a press worth a step down and a step up carries: %s" % [parts.map(func(part: Pressable) -> Dictionary: return part.payload())])
	var words: Array = ui.node_named(&"steps").find_children("*", "Label", true, false).map(func(label: Label) -> String: return label.text)
	_verdict.check(words == [Stepper.DOWN, "four figs", Stepper.UP], "what shows stands between the minus and the plus: %s" % [words])
	parts[1].pressed()
	await _a_frame_passes()
	_verdict.check(made.commands.get_last()["payload"] == {"id": 4, "by": 2} and lines.told_actions == [&"counts"], "pressed, it is that payload that goes through the door: %s" % [made.commands.get_last()["payload"]])
	lines.free()
	made.done()
