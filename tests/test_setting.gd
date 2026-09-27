extends SceneTree

## What must be true of the settings controls: the row, the toggle, the
## choice and its overlay, and the binding.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_setting.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const KeyCapture := preload("res://addons/gd_chime/components/primitives/key_capture.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Setting := preload("res://addons/gd_chime/components/recipes/setting.gd")
const Sheet := preload("res://addons/gd_chime/components/recipes/sheet.gd")
const Inputs := preload("res://addons/gd_chime/input_map.gd")
const Verdict := preload("res://tests/verdict.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")

var _verdict := Verdict.new()


## The settings a reader changes: what is on, what is chosen among the
## options, and what is bound - each set by what it is told.
class Settings extends Fixture.Model:
	func get_on() -> Variant:
		return of(&"on").read()

	func get_options() -> Variant:
		return of(&"options", []).read()

	func get_chosen() -> Variant:
		return of(&"chosen").read()

	func get_bound_to() -> Variant:
		return of(&"bound_to", "").read()

	func told(action: StringName, payload: Dictionary) -> Phrase:
		told_actions.append(action)
		if payload.has("on"):
			set_value(&"on", payload["on"])
		if payload.has("value"):
			set_value(&"chosen", payload["value"])
		if payload.has("words"):
			set_value(&"bound_to", payload["words"])
		return null


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(400, 400)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_a_row_states_its_name_and_what_it_does_and_its_toggle_turns_the_setting_wearing_a_mark)
	await _verdict.states(_a_choice_opens_an_overlay_of_every_option_marks_the_chosen_one_and_picking_closes_it)
	await _verdict.states(_a_binding_listens_after_a_press_takes_the_next_key_and_the_cancel_key_binds_nothing)
	await _verdict.states(_a_binding_over_the_input_map_asks_about_its_action_at_rest_and_writes_the_map)
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


## The words a binding shows: its own label's.
func _said(binding: KeyCapture) -> String:
	return (binding.find_children("*", "Label", false, false)[0] as Label).text


func _pressables(node: Node) -> Array:
	return node.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable and part.theme_type_variation != Sheet.SHADE)


func _a_row_states_its_name_and_what_it_does_and_its_toggle_turns_the_setting_wearing_a_mark() -> void:
	var made := Fixture.new(root, {&"switches": "switch"})
	var ui := made.ui
	var model := Settings.new(made.chimes, &"app")
	model.set_value(&"on", false)
	made.commands.register(&"app", &"switches", model)
	var toggle := Setting.toggle(ui, &"switches", Bound.new(model.get_on))
	ui.start(ui.app(&"app", [Setting.row(ui, "the sounds", "plays a sound as things happen", toggle).named(&"row")]))
	await _a_frame_passes()
	var stated: Node = ui.node_named(&"row")
	_verdict.check(_texts(stated) == ["the sounds", "plays a sound as things happen", Setting.OFF], "the row states its name, the line saying what it does, and its control: %s" % [_texts(stated)])
	var pressed: Pressable = _pressables(stated)[0]
	pressed.pressed()
	_verdict.check(model.told_actions == [&"switches"] and made.commands.get_last()["payload"] == {"on": true}, "a press asks the door for the other way: %s" % [made.commands.get_last()["payload"]])
	await _a_frame_passes()
	var turned: Control = _pressables(stated)[0]
	_verdict.check(model.of(&"on").read() == true and _texts(stated).has(Setting.ON) and turned.theme_type_variation == Setting.TOGGLE_ON, "the model's value turned: the word says On and the control wears the on look, in place: %s %s" % [_texts(stated), turned.theme_type_variation])
	pressed.pressed()
	await _a_frame_passes()
	_verdict.check(model.of(&"on").read() == false and _texts(stated).has(Setting.OFF) and _pressables(stated)[0] == turned and turned.theme_type_variation == Setting.TOGGLE_OFF, "and turns back: the same control, the off look: %s" % [_texts(stated)])
	model.free()
	made.done()


func _a_choice_opens_an_overlay_of_every_option_marks_the_chosen_one_and_picking_closes_it() -> void:
	var made := Fixture.new(root, {&"picks": "pick", &"opens": "open"})
	var ui := made.ui
	var model := Settings.new(made.chimes, &"app")
	model.set_value(&"options", [{"value": "small", "words": "small"}, {"value": "large", "words": "large"}])
	model.set_value(&"chosen", "small")
	var choice := Setting.choice(ui, &"picks", &"opens", {offers = Bound.new(model.get_options), chosen = Bound.new(model.get_chosen), title = "how big?"})
	var chooser: StringName = (choice.props["overlay"] as Desc).named(&"overlay").get_place()
	# the option pressables live in the overlay, so the model answers there too
	for region: StringName in [&"app", chooser]:
		made.commands.register(region, &"picks", model)
	ui.start(ui.app(&"app", [choice.named(&"control")]))
	await _a_frame_passes()
	var shown: Pressable = ui.node_named(&"control")
	_verdict.check(_texts(shown) == ["small"], "the control wears the chosen option's words: %s" % [_texts(shown)])
	shown.pressed()
	await _a_frame_passes()
	var overlay: Node = ui.node_named(&"overlay")
	_verdict.check(made.driver.get_top().has(chooser), "pressed, the overlay is the layer that takes input: %s" % [made.driver.get_top()])
	var small: Pressable = _pressables(overlay)[0]

	var large: Pressable = _pressables(overlay)[1]
	_verdict.check(_texts(overlay) == ["how big?", "small", "large"] and small.theme_type_variation == Setting.CHOSEN and large.theme_type_variation == Setting.OPTION, "the overlay holds the title and every option, the chosen one in the chosen look as it opens: %s %s" % [_texts(overlay), small.theme_type_variation])
	large.pressed()
	_verdict.check(model.told_actions == [&"picks"] and made.commands.get_last()["payload"] == {"value": "large"}, "picking an option dispatches its value: %s" % [made.commands.get_last()["payload"]])
	await _a_frame_passes()
	_verdict.check(not made.driver.get_top().has(chooser), "and the overlay is lowered by the picking: %s" % [made.driver.get_top()])
	_verdict.check(_texts(shown) == ["large"] and model.of(&"chosen").read() == "large", "the control follows what is chosen now: %s" % [_texts(shown)])
	# a lowered overlay is hidden, and a hidden option draws as it is shown (presentation.gd): the looks are read where a reader meets them, open
	shown.pressed()
	await _a_frame_passes()
	_verdict.check(made.driver.get_top().has(chooser) and _pressables(overlay) == [small, large] and small.theme_type_variation == Setting.OPTION and large.theme_type_variation == Setting.CHOSEN, "opened again, the looks follow what is chosen now, the same options in place: %s %s" % [small.theme_type_variation, large.theme_type_variation])
	model.free()
	made.done()


func _a_binding_listens_after_a_press_takes_the_next_key_and_the_cancel_key_binds_nothing() -> void:
	var made := Fixture.new(root, {&"binds": "bind"})
	var ui := made.ui
	var model := Settings.new(made.chimes, &"app")
	model.set_value(&"bound_to", "Space")
	made.commands.register(&"app", &"binds", model)
	ui.start(ui.app(&"app", [Setting.binding(ui, &"binds", Bound.new(model.get_bound_to)).named(&"binding")]))
	await _a_frame_passes()
	var binding: KeyCapture = ui.node_named(&"binding")
	_verdict.check(not binding.is_listening(), "at rest it is not listening")
	binding.pressed()
	_verdict.check(binding.is_listening(), "pressed, it waits for the next key or button")
	_press_key(KEY_A)
	await _a_frame_passes()
	_verdict.check(model.told_actions == [&"binds"] and model.of(&"bound_to").read() == "A" and not binding.is_listening(), "the next key is handed to the model in words, and the waiting ends: %s" % [model.of(&"bound_to").read()])
	binding.pressed()
	_press_key(KEY_ESCAPE)
	await _a_frame_passes()
	_verdict.check(model.told_actions == [&"binds"] and model.of(&"bound_to").read() == "A" and not binding.is_listening(), "the cancel key ends the waiting and binds nothing: %s" % [model.told_actions])
	model.free()
	made.done()


## A binding naming the action it binds, over the application's own map: at
## rest the door is asked about that action alone - an action the register
## lacks is refused and says so before any key - and a key pressed is put on
## the action in the map, which the binding then shows.
func _a_binding_over_the_input_map_asks_about_its_action_at_rest_and_writes_the_map() -> void:
	var made := Fixture.new(root, {Inputs.BINDS: "bind", &"adds": "add"})
	var ui := made.ui
	made.answer([&"adds"])
	ui.start(ui.app(&"app", [ui.pressable(&"adds"), Setting.binding(ui, Inputs.BINDS, made.inputs.hint(&"adds"), {rebinds = &"adds"}).named(&"binding"), Setting.binding(ui, Inputs.BINDS, made.inputs.hint(&"adds"), {rebinds = &"no_such_action"}).named(&"stray")]))
	await _a_frame_passes()
	var binding: KeyCapture = ui.node_named(&"binding")
	var stray: KeyCapture = ui.node_named(&"stray")
	_verdict.check(binding.payload() == {"action": &"adds"} and binding.is_usable(), "at rest it asks the door about the action it binds, and the map would take it: %s" % [binding.payload()])
	_verdict.check(not stray.is_usable() and str(stray.get_reason()) == "no_such_action is no action to bind", "one binding an action the register lacks is refused at rest, in words: %s" % [stray.get_reason()])
	var before: Dictionary = made.commands.get_last()
	_press_key(KEY_K)
	await _a_frame_passes()
	_verdict.check(made.commands.get_last() == before and made.inputs.get_inputs(&"adds").is_empty(), "a key pressed while no binding listens binds nothing, anywhere: %s" % [made.commands.get_last()])
	binding.pressed()
	_press_key(KEY_M)
	await _a_frame_passes()
	_verdict.check(made.inputs.get_inputs(&"adds") == [{Inputs.KEY: KEY_M}] and _said(binding) == "M", "a key pressed is put on that action in the map, and the binding shows it: %s %s" % [made.inputs.get_inputs(&"adds"), _said(binding)])
	made.done()


## One key pressed, as the engine would deliver it.
func _press_key(keycode: Key) -> void:
	var key := InputEventKey.new()
	key.keycode = keycode
	key.pressed = true
	Input.parse_input_event(key)
