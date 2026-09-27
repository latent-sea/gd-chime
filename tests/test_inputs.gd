extends SceneTree

## What must be true of the two ways a person hands the door something
## they typed or pressed: a field, by option dispatching on every change
## and showing a bound value; and a binding, which listens for the next
## key or button, and says its words in the language on as it changes.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_inputs.gd

const Fixture := preload("res://tests/fixture.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Field := preload("res://addons/gd_chime/components/primitives/field.gd")
const KeyCapture := preload("res://addons/gd_chime/components/primitives/key_capture.gd")
const Verdict := preload("res://tests/verdict.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Language := preload("res://addons/gd_chime/language.gd")

var _verdict := Verdict.new()


func _init() -> void:
	await process_frame
	await _verdict.states(_a_field_dispatches_every_change_and_shows_what_the_model_holds)
	await _verdict.states(_a_binding_listens_for_the_next_key_and_hands_it_to_its_action)
	await _verdict.states(_a_binding_stops_listening_when_the_player_moves_on)
	await _verdict.states(_a_binding_follows_a_change_of_language)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## An event sent as the engine sends one, and the frames it takes to land.
func _sent(event: InputEvent) -> void:
	Input.parse_input_event(event)
	await _a_frame_passes()


## A model that keeps the last line of each action, and the words it holds.
class Keeper extends Fixture.Model:
	var lines: Dictionary = {}

	func told(action: StringName, payload: Dictionary) -> Phrase:
		lines[action] = payload.get("line", payload.get("words"))
		if action == &"names":
			set_value(&"words", payload["line"])
		if action == &"binds":
			set_value(&"words", payload["words"])
		return super(action, payload)


## A keeper that refuses J as a binding - and nothing else, so a binding is
## usable at rest and its key refused as it lands.
class RefusesJ extends Keeper:
	func would(_action: StringName, payload: Dictionary) -> Phrase:
		var j: bool = payload.has("event") and (payload["event"] as InputEventKey).keycode == KEY_J
		return Phrase.of("J is taken") if j else null


func _a_field_dispatches_every_change_and_shows_what_the_model_holds() -> void:
	var made := Fixture.new(root, {&"names": "name", &"narrows": "narrow"})
	var ui := made.ui
	var model := Keeper.new(made.chimes, &"app")
	model.set_value(&"words", "first")
	for action: StringName in [&"names", &"narrows"]:
		made.commands.register(&"app", action, model)
	ui.start(ui.app(&"app", [ui.field(&"names", &"", {changes = &"narrows", shows = model.of(&"words")}).named(&"it")]))
	await _a_frame_passes()
	var field: Field = ui.node_named(&"it")
	_verdict.check(field.get_line() == "first", "a field that shows a bound value shows what the model holds: %s" % field.get_line())
	field._changed("se")
	_verdict.check(model.lines.get(&"narrows") == "se" and not model.lines.has(&"names"), "every change goes through the door under the second action, and Enter's has not run")
	field._submitted("second")
	await _a_frame_passes()
	_verdict.check(model.lines.get(&"names") == "second" and field.get_line() == "second", "Enter dispatches the line, and the field then shows what the model holds: %s" % field.get_line())
	var place: Node = made.driver.index.place_named(&"app")
	_verdict.check(place.performs.has(&"names") and place.performs.has(&"narrows"), "and its place declares both its actions")
	model.free()
	made.done()


func _a_binding_listens_for_the_next_key_and_hands_it_to_its_action() -> void:
	var made := Fixture.new(root, {&"binds": "bind"})
	var ui := made.ui
	var model := Keeper.new(made.chimes, &"app")
	model.set_value(&"words", "Space")
	made.commands.register(&"app", &"binds", model)
	ui.start(ui.app(&"app", [ui.key_capture(&"binds", model.of(&"words"), "press a key...").named(&"it")]))
	await _a_frame_passes()
	var binding: KeyCapture = ui.node_named(&"it")
	_verdict.check(not binding.is_listening() and binding._words.text == "Space", "at rest it shows what is bound: %s" % binding._words.text)
	binding.pressed()
	await _a_frame_passes()
	_verdict.check(binding.is_listening() and binding.get_state() == &"listening" and binding._words.text == "press a key..." and model.told_actions.is_empty(), "pressed, it listens and says so, and nothing has run")
	var key := InputEventKey.new()
	key.keycode = KEY_J
	key.pressed = true
	binding._input(key)
	await _a_frame_passes()
	_verdict.check(not binding.is_listening() and model.told_actions == [&"binds"] and binding._words.text == model.of(&"words").read() and String(model.of(&"words").read()).contains("J"), "the next key is handed to the action with its words, and it shows the new binding: %s" % [model.of(&"words").read()])
	binding.pressed()
	var cancel := InputEventKey.new()
	cancel.keycode = KEY_ESCAPE
	cancel.pressed = true
	binding._input(cancel)
	_verdict.check(not binding.is_listening() and model.told_actions.size() == 1, "the cancel key ends the listening and binds nothing")
	binding.pressed()
	var button := InputEventJoypadButton.new()
	button.button_index = JOY_BUTTON_A
	button.pressed = true
	binding._input(button)
	_verdict.check(model.told_actions.size() == 2, "a pad button is bound the same way")
	model.free()
	made.done()


## The focus moved away, or the mouse pressed outside, and then a key:
## nothing is bound. Pressed, then a key: that key is bound. A headless
## window is 64 pixels and routes no mouse press by position, so the two
## presses are delivered here in the order the engine delivers them.
func _a_binding_stops_listening_when_the_player_moves_on() -> void:
	var made := Fixture.new(root, {&"binds": "bind", &"ticks": "tick"})
	var ui := made.ui
	var model := Keeper.new(made.chimes, &"app")
	model.set_value(&"words", "Space")
	for action: StringName in [&"binds", &"ticks"]:
		made.commands.register(&"app", action, model)
	ui.start(ui.app(&"app", [ui.row([ui.key_capture(&"binds", model.of(&"words"), "press a key...").named(&"it"), ui.pressable(&"ticks", {}, [ui.text("other")]).named(&"other")])]))
	await _a_frame_passes()
	var binding: KeyCapture = ui.node_named(&"it")
	var other: Control = ui.node_named(&"other")
	var key := InputEventKey.new()
	key.keycode = KEY_J
	key.pressed = true
	binding.pressed()
	_verdict.check(binding.is_listening() and binding.has_focus(), "listening, it holds the focus")
	other.grab_focus()
	await _a_frame_passes()
	await _sent(key)
	_verdict.check(not binding.is_listening() and model.told_actions.is_empty() and model.of(&"words").read() == "Space", "the focus moved away, then a key: nothing is bound")
	binding.pressed()
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	# a press elsewhere, as the engine delivers one: to every listening _input, and to this control's _gui_input never
	binding._input(click)
	await _a_frame_passes()
	await _sent(key)
	_verdict.check(not binding.is_listening() and not model.told_actions.has(&"binds") and model.of(&"words").read() == "Space", "a click outside, then a key: nothing is bound - the click was the other control's own")
	binding.pressed()
	var inside := InputEventMouseButton.new()
	inside.button_index = MOUSE_BUTTON_LEFT
	inside.pressed = true
	# a press on the binding, as the engine delivers one: to _input first, then handed to its own _gui_input
	binding._input(inside)
	binding._gui_input(inside)
	await _a_frame_passes()
	_verdict.check(binding.is_listening(), "a press on the binding itself leaves it listening")
	await _sent(key)
	_verdict.check(model.told_actions.count(&"binds") == 1 and String(model.of(&"words").read()).contains("J"), "press, then a key: that key is bound")
	model.free()
	made.done()


## The language changing while a binding rests, and again while it listens:
## its words are said in the language on each time, with nothing pressed or
## bound to move them - and a refusal it shows stands through the change.
func _a_binding_follows_a_change_of_language() -> void:
	var made := Fixture.new(root, {&"binds": "bind"})
	var ui := made.ui
	var model := RefusesJ.new(made.chimes, &"app")
	var bound := Phrase.of("Space")
	var asks := Phrase.of("Press a key")
	model.set_value(&"words", bound)
	made.commands.register(&"app", &"binds", model)
	ui.start(ui.app(&"app", [ui.key_capture(&"binds", model.of(&"words"), asks).named(&"it")]))
	await _a_frame_passes()
	var binding: KeyCapture = ui.node_named(&"it")
	made.commands.dispatch(Chimes.GLOBAL, Language.CHANGES_LANGUAGE, {"value": Language.PSEUDO})
	await _a_frame_passes()
	var resting := binding._words.text
	_verdict.check(resting == Text.said(bound) and resting != "Space", "resting, the language changed: it shows what is bound in the language now on: %s" % resting)
	binding.pressed()
	await _a_frame_passes()
	made.commands.dispatch(Chimes.GLOBAL, Language.CHANGES_LANGUAGE, {"value": Language.SOURCE})
	await _a_frame_passes()
	_verdict.check(binding.is_listening() and binding._words.text == "Press a key", "listening, the language changed back: it asks in English again: %s" % binding._words.text)
	var key := InputEventKey.new()
	key.keycode = KEY_J
	key.pressed = true
	binding._input(key)
	await _a_frame_passes()
	var refused := binding.get_refusal()
	made.commands.dispatch(Chimes.GLOBAL, Language.CHANGES_LANGUAGE, {"value": Language.PSEUDO})
	await _a_frame_passes()
	_verdict.check(refused != null and binding.get_refusal() == refused, "a key refused, the language changing leaves the refusal standing: %s, then %s" % [refused, binding.get_refusal()])
	made.commands.dispatch(Chimes.GLOBAL, Language.CHANGES_LANGUAGE, {"value": Language.SOURCE})
	await _a_frame_passes()
	model.free()
	made.done()
