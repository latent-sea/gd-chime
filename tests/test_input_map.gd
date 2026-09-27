extends SceneTree
const Actions := preload("res://addons/gd_chime/actions.gd")

## What must be true of the input map and the shortcuts over it: a key
## presses the action it is on, in the nearest place on the top path that
## declares it and through the very button that draws it; one that reaches
## nothing does nothing; a refused one goes no further than the button's own
## face; a line being typed into takes the key first; a rebinding moves the
## shortcut and the hint together, in place; the defaults come back; a save
## goes out and comes in again, from a Dictionary and from a file, and a
## corrupt one is said out loud with the defaults kept; two actions on one
## input that can be reached at once are reported and two that cannot are
## not; an action whose press carries what it is about is reported rather
## than pressed about the wrong thing; and a pad button no pad names is words
## said in the language on, its number kept as it is.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_input_map.gd
##
## What is said out loud is heard through a logger that counts and keeps what
## is pushed as an error.

const Fixture := preload("res://tests/fixture.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Inputs := preload("res://addons/gd_chime/input_map.gd")
const Hint := preload("res://addons/gd_chime/components/recipes/hint.gd")
const Field := preload("res://addons/gd_chime/components/primitives/field.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Verdict := preload("res://tests/verdict.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Language := preload("res://addons/gd_chime/language.gd")

const SAVE := "user://test_input_map.json"

var _verdict := Verdict.new()
var _hearing := Hearing.new()


## Keeps every sentence pushed as an error, which is how a conflict, a
## corrupt save and a press that cannot be made are said.
class Hearing extends Logger:
	var said: Array[String] = []

	func _log_error(_function: String, _file: String, _line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_ERROR:
			said.append(code + rationale)


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(400, 400)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	OS.add_logger(_hearing)
	await _verdict.states(_a_shortcut_presses_its_action_in_the_nearest_place_that_declares_it_through_its_own_button)
	await _verdict.states(_a_shortcut_that_reaches_nothing_or_is_refused_or_carries_a_payload_presses_nothing)
	await _verdict.states(_a_line_being_typed_into_takes_the_key_before_any_shortcut)
	await _verdict.states(_rebinding_moves_the_shortcut_and_the_hint_in_place_and_the_hint_follows_the_device)
	await _verdict.states(_the_defaults_come_back_and_a_save_goes_out_and_in_again_a_corrupt_one_keeping_them)
	await _verdict.states(_two_actions_on_one_input_are_reported_only_when_they_can_be_reached_at_once)
	await _verdict.states(_a_pad_button_no_pad_names_is_words_in_the_language_on_with_its_number_kept)
	await _verdict.states(_a_chord_presses_its_own_action_and_the_bare_key_another_and_its_hint_names_both_keys)
	OS.remove_logger(_hearing)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## One key pressed, as a keyboard delivers one into the window: with the
## character it stands for, which is what a line being typed into takes.
func _pressing(code: Key) -> void:
	var key := InputEventKey.new()
	key.keycode = code
	key.unicode = OS.get_keycode_string(code).to_lower().unicode_at(0)
	key.pressed = true
	root.push_input(key)
	await _a_frame_passes()


## Whatever was said out loud since this many sentences had been.
func _said_since(before: int) -> Array[String]:
	return _hearing.said.slice(before)


## A screen inside the app, with a button for each of the actions, and the
## map and the shortcuts wired as an application wires them.
func _a_tree() -> Dictionary:
	var made := Fixture.new(root, {})
	made.actions.declare_all({&"counts": ["count", Actions.keys(KEY_S)]})
	made.actions.declare_all({&"stalls": ["stall", Actions.keys(KEY_D)]})
	made.actions.declare_all({&"opens": ["open", Actions.keys(KEY_F)]})
	made.actions.declare_all({&"picks": ["pick", Actions.keys(KEY_G)]})
	var model := Fixture.Model.new(made.chimes, Chimes.GLOBAL)
	model.refuse(&"stalls", Phrase.of("not now"))
	for action: StringName in [&"counts", &"stalls", &"opens", &"picks"]:
		made.commands.register(Chimes.GLOBAL, action, model)
	# the fixture's own map, as an application's: it takes the register's defaults again now they are declared
	var map: Inputs = made.inputs
	map.restore_defaults()
	var ui := made.ui
	ui.start(ui.app(&"app", [
		ui.pressable(&"counts", {}, [ui.text("outer")]).named(&"outer"),
		ui.screen(&"inner", [
			ui.pressable(&"counts", {}, [ui.text("inner")]).named(&"inner_button"),
			ui.pressable(&"stalls", {}, [ui.text("stall")]).named(&"stall"),
			ui.pressable(&"picks", {"row": 1}, [ui.text("pick")]).named(&"pick"),
		]),
		ui.pop_up(&"away", func(_which: Bound) -> Desc: return ui.pressable(&"opens", {}, [ui.text("open")])),
	]))
	return {"made": made, "model": model, "map": map}


func _a_shortcut_presses_its_action_in_the_nearest_place_that_declares_it_through_its_own_button() -> void:
	var built := _a_tree()
	var made: Fixture = built["made"]
	var model: Fixture.Model = built["model"]
	await _a_frame_passes()
	_verdict.check(made.driver.get_top() == [&"app", &"inner"], "the reader is in the screen inside the app: %s" % [made.driver.get_top()])
	await _pressing(KEY_S)
	_verdict.check(model.told_actions == [&"counts"], "the key presses the action it is on, once: %s" % [model.told_actions])
	_verdict.check(made.commands.get_last()["region"] == &"inner", "in the nearest place on the top path that declares it, not the one behind it: %s" % [made.commands.get_last()["region"]])
	_verdict.check(made.commands.get_last()["payload"] == {}, "carrying nothing, since no key can say what a press is about: %s" % [made.commands.get_last()["payload"]])
	model.free()
	made.done()


func _a_shortcut_that_reaches_nothing_or_is_refused_or_carries_a_payload_presses_nothing() -> void:
	var built := _a_tree()
	var made: Fixture = built["made"]
	var model: Fixture.Model = built["model"]
	await _a_frame_passes()
	# the arrival in the app is the last command there has been; nothing below may add to it
	var arrival: Dictionary = made.commands.get_last()
	await _pressing(KEY_F)
	_verdict.check(model.told_actions.is_empty() and made.commands.get_last() == arrival, "an action no place on the screen declares is pressed by nothing: %s" % [model.told_actions])
	await _pressing(KEY_D)
	var stall: Pressable = made.ui.node_named(&"stall")
	_verdict.check(model.told_actions.is_empty() and made.commands.get_last() == arrival, "a refused one goes nowhere near the door: %s" % [made.commands.get_last()])
	_verdict.check(str(stall.get_reason()) == "not now" and stall.get_state() == &"inert", "and the reason stands on its own button: %s" % stall.get_reason())
	var before := _hearing.said.size()
	await _pressing(KEY_G)
	_verdict.check(model.told_actions.is_empty(), "a press that carries which row it is about is not made by a key")
	_verdict.check(_said_since(before).size() == 1 and _said_since(before)[0].contains("picks"), "and is said out loud instead: %s" % [_said_since(before)])
	model.free()
	made.done()


func _a_line_being_typed_into_takes_the_key_before_any_shortcut() -> void:
	var made := Fixture.new(root, {})
	made.actions.declare_all({&"counts": ["count", Actions.keys(KEY_S)]})
	made.actions.declare_all({&"names": ["name"]})
	var model := Fixture.Model.new(made.chimes, Chimes.GLOBAL)
	for action: StringName in [&"counts", &"names"]:
		made.commands.register(Chimes.GLOBAL, action, model)
	# the fixture's own map, as an application's: it takes the register's defaults again now they are declared
	var map: Inputs = made.inputs
	map.restore_defaults()
	var ui := made.ui
	ui.start(ui.app(&"app", [
		ui.pressable(&"counts", {}, [ui.text("count")]).named(&"button"),
		ui.field(&"names").named(&"line"),
	]))
	await _a_frame_passes()
	await _pressing(KEY_S)
	_verdict.check(model.told_actions == [&"counts"], "with nothing being typed into, the key presses its action: %s" % [model.told_actions])
	var line: Field = ui.node_named(&"line")
	line.start_typing()
	await _a_frame_passes()
	await _pressing(KEY_S)
	_verdict.check(model.told_actions == [&"counts"], "with the caret in a line, the same key presses nothing: %s" % [model.told_actions])
	_verdict.check(line.get_line() == "s", "it is typed instead: %s" % line.get_line())
	model.free()
	made.done()


func _rebinding_moves_the_shortcut_and_the_hint_in_place_and_the_hint_follows_the_device() -> void:
	var made := Fixture.new(root, {})
	made.actions.declare_all({&"counts": ["count", Actions.keys(KEY_S)]})
	var model := Fixture.Model.new(made.chimes, Chimes.GLOBAL)
	made.commands.register(Chimes.GLOBAL, &"counts", model)
	# the fixture's own map, as an application's: it takes the register's defaults again now they are declared
	var map: Inputs = made.inputs
	map.restore_defaults()
	var ui := made.ui
	ui.start(ui.app(&"app", [ui.pressable(&"counts", {}, [ui.text("count"), Hint.make(ui, &"counts").named(&"hint")])]))
	await _a_frame_passes()
	var hint: Text = ui.node_named(&"hint")
	_verdict.check(hint.get_text() == "S", "the hint says the key the action is on: %s" % hint.get_text())
	map.bind(&"counts", Actions.keys(KEY_J))
	await _a_frame_passes()
	_verdict.check(ui.node_named(&"hint") == hint and hint.get_text() == "J", "rebound, the very same hint says the new key: %s" % hint.get_text())
	await _pressing(KEY_S)
	_verdict.check(model.told_actions.is_empty(), "the key it was on presses nothing now: %s" % [model.told_actions])
	await _pressing(KEY_J)
	_verdict.check(model.told_actions == [&"counts"], "and the key it is on presses it: %s" % [model.told_actions])
	map.bind(&"counts", Actions.pad(JOY_BUTTON_Y))
	await _a_frame_passes()
	_verdict.check(hint.get_text() == "J" and map.get_inputs(&"counts").size() == 2, "a pad button bound leaves the key alone, and the hint stays on the device in hand: %s" % [map.get_inputs(&"counts")])
	map.used(Actions.pad(JOY_BUTTON_Y))
	await _a_frame_passes()
	_verdict.check(map.get_device() == Inputs.PAD and hint.get_text() == "Y", "the pad used, the hint says the button: %s" % hint.get_text())
	map.used(Actions.keys(KEY_J))
	await _a_frame_passes()
	_verdict.check(map.get_device() == Inputs.KEY and hint.get_text() == "J", "the keyboard used, it says the key again: %s" % hint.get_text())
	model.free()
	made.done()


func _the_defaults_come_back_and_a_save_goes_out_and_in_again_a_corrupt_one_keeping_them() -> void:
	var made := Fixture.new(root, {})
	made.actions.declare_all({&"counts": ["count", Actions.keys(KEY_S)]})
	made.actions.declare_all({&"opens": ["open", Actions.keys(KEY_F), Actions.pad(JOY_BUTTON_A)]})
	var model := Fixture.Model.new(made.chimes, Chimes.GLOBAL)
	for action: StringName in [&"counts", &"opens"]:
		made.commands.register(Chimes.GLOBAL, action, model)
	# the fixture's own map, as an application's: it takes the register's defaults again now they are declared
	var map: Inputs = made.inputs
	map.restore_defaults()
	var ui := made.ui
	ui.start(ui.app(&"app", [ui.pressable(&"counts", {}, [ui.text("count")]), ui.pressable(&"opens", {}, [ui.text("open")])]))
	await _a_frame_passes()
	map.bind(&"counts", Actions.keys(KEY_J))
	_verdict.check(map.get_actions(Actions.keys(KEY_J)) == [&"counts"] and map.get_actions(Actions.keys(KEY_S)).is_empty(), "an input bound presses its action, and the one it replaced presses none")
	var save := map.saved()
	map.restore_defaults()
	_verdict.check(map.get_actions(Actions.keys(KEY_S)) == [&"counts"] and map.get_inputs(&"counts") == [Actions.keys(KEY_S)], "the defaults restored put every action back on what it was declared with: %s" % [map.get_inputs(&"counts")])
	map.restore(save)
	_verdict.check(map.get_inputs(&"counts") == [Actions.keys(KEY_J)] and map.get_inputs(&"opens") == [Actions.keys(KEY_F), Actions.pad(JOY_BUTTON_A)], "a save read back is what was saved, every device of it: %s" % [map.saved()])
	map.restore_defaults()
	var file := FileAccess.open(SAVE, FileAccess.WRITE)
	file.store_string(JSON.stringify(save))
	file.close()
	var read: Variant = JSON.parse_string(FileAccess.open(SAVE, FileAccess.READ).get_as_text())
	map.restore(read)
	_verdict.check(map.get_inputs(&"counts") == [Actions.keys(KEY_J)] and map.get_inputs(&"opens") == [Actions.keys(KEY_F), Actions.pad(JOY_BUTTON_A)], "and the same through a file, where every number has been text: %s" % [map.saved()])
	DirAccess.remove_absolute(SAVE)
	var before := _hearing.said.size()
	map.restore({"counts": "a key, honest"})
	_verdict.check(_said_since(before).size() == 1, "a save that is not bindings is said out loud: %s" % [_said_since(before)])
	_verdict.check(map.get_inputs(&"counts") == [Actions.keys(KEY_S)], "and the defaults are kept whole: %s" % [map.saved()])
	before = _hearing.said.size()
	map.restore({"counts": [Actions.keys(KEY_J)], "flies": [Actions.keys(KEY_K)]})
	_verdict.check(_said_since(before).size() == 1 and map.get_inputs(&"counts") == [Actions.keys(KEY_S)], "one naming an action there is none of is refused whole, its good half too: %s" % [map.saved()])
	before = _hearing.said.size()
	map.restore({"counts": [{"key": KEY_J, "pad": JOY_BUTTON_A}]})
	_verdict.check(_said_since(before).size() == 1 and map.get_inputs(&"counts") == [Actions.keys(KEY_S)], "and so is an input naming two devices at once: %s" % [map.saved()])
	model.free()
	made.done()


func _two_actions_on_one_input_are_reported_only_when_they_can_be_reached_at_once() -> void:
	var made := Fixture.new(root, {})
	made.actions.declare_all({&"counts": ["count", Actions.keys(KEY_S)]})
	made.actions.declare_all({&"stalls": ["stall", Actions.keys(KEY_S)]})
	made.actions.declare_all({&"picks": ["pick", Actions.keys(KEY_D)]})
	made.actions.declare_all({&"opens": ["open", Actions.keys(KEY_D)]})
	var model := Fixture.Model.new(made.chimes, Chimes.GLOBAL)
	for action: StringName in [&"counts", &"stalls", &"picks", &"opens"]:
		made.commands.register(Chimes.GLOBAL, action, model)
	# the fixture's own map, as an application's: it takes the register's defaults again now they are declared
	var map: Inputs = made.inputs
	map.restore_defaults()
	var ui := made.ui
	ui.start(ui.app(&"app", [
		ui.pressable(&"counts", {}, [ui.text("count")]),
		ui.tabs(&"pages", [
			ui.screen(&"first", [ui.pressable(&"stalls", {}, [ui.text("stall")]), ui.pressable(&"picks", {}, [ui.text("pick")])]),
			ui.screen(&"second", [ui.pressable(&"opens", {}, [ui.text("open")])]),
		]),
	]))
	await _a_frame_passes()
	var before := _hearing.said.size()
	map.report_conflicts()
	var said := _said_since(before)
	_verdict.check(said.size() == 1, "of the two pairs on one input each, exactly one is reported: %s" % [said])
	_verdict.check(said.size() == 1 and said[0].contains("counts") and said[0].contains("stalls") and said[0].contains("S"), "the pair in a screen and the app above it, named with the input: %s" % [said])
	_verdict.check(not str(said).contains("picks"), "and the pair in two tabs of one set, which are never on top together, is no conflict")
	model.free()
	made.done()


## A pad button no pad we know of names is words with its number in them, so
## a catalogue says the words and the number stays as it is; a named button
## and a key are names, as they are.
func _a_pad_button_no_pad_names_is_words_in_the_language_on_with_its_number_kept() -> void:
	var made := Fixture.new(root)
	made.commands.dispatch(Chimes.GLOBAL, Language.CHANGES_LANGUAGE, {"value": &"fr"})
	var unnamed := Text.said(Inputs.words_of(Actions.pad(JOY_BUTTON_MISC1)))
	_verdict.check(unnamed == "Bouton %d" % JOY_BUTTON_MISC1, "in French, a button no pad names reads in French, its number kept: %s" % unnamed)
	_verdict.check(Text.said(Inputs.words_of(Actions.pad(JOY_BUTTON_A))) == "A" and Text.said(Inputs.words_of(Actions.keys(KEY_S))) == "S", "a named button and a key are their names")
	made.commands.dispatch(Chimes.GLOBAL, Language.CHANGES_LANGUAGE, {"value": Language.SOURCE})
	made.done()


## A key held with Ctrl is an input of its own: Ctrl+K presses the action on
## it and not the one on K, K alone presses the one on K and not the chord's,
## and the hint of the chord names the modifier with the key.
func _a_chord_presses_its_own_action_and_the_bare_key_another_and_its_hint_names_both_keys() -> void:
	var made := Fixture.new(root, {})
	made.actions.declare_all({&"finds": ["find", Actions.keys(KEY_K, KEY_MASK_CTRL)]})
	made.actions.declare_all({&"keeps": ["keep", Actions.keys(KEY_K)]})
	var model := Fixture.Model.new(made.chimes, Chimes.GLOBAL)
	for action: StringName in [&"finds", &"keeps"]:
		made.commands.register(Chimes.GLOBAL, action, model)
	made.inputs.restore_defaults()
	var ui := made.ui
	ui.start(ui.app(&"app", [ui.pressable(&"finds", {}, [ui.text("find"), Hint.make(ui, &"finds").named(&"hint")]), ui.pressable(&"keeps", {}, [ui.text("keep")])]))
	await _a_frame_passes()
	var held := InputEventKey.new()
	held.keycode = KEY_K
	held.ctrl_pressed = true
	held.pressed = true
	root.push_input(held)
	await _a_frame_passes()
	_verdict.check(model.told_actions == [&"finds"], "Ctrl+K presses the action on the chord, not the one on K: %s" % [model.told_actions])
	await _pressing(KEY_K)
	_verdict.check(model.told_actions == [&"finds", &"keeps"], "and K alone the one on K: %s" % [model.told_actions])
	var hint: Text = ui.node_named(&"hint")
	_verdict.check(hint.get_text() == "Ctrl+K", "the chord's hint names the modifier with the key: %s" % hint.get_text())
	model.free()
	made.done()
