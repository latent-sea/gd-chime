extends SceneTree
const Fields := preload("res://addons/gd_chime/theme_fields.gd")

## What must be true of a chip (chip.gd), and of the filter set over it.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_chip.gd
##
## A chip says its words while it is on and the same words in brackets while
## it is off, drawn again in place as the model moves; its body toggles it
## and its x removes it, each carrying its payload through the door - by the
## mouse, the keyboard and the pad - and one given no remove has no x; the
## door refusing, the body is drawn inert and a press dispatches nothing;
## its words are a phrase said in the language on, brackets and all, and a
## model's data as it is; it is drawn in the look's Chip; and the filter
## set's chips are chips.

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Language := preload("res://addons/gd_chime/language.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Chip := preload("res://addons/gd_chime/components/recipes/chip.gd")
const FilterSet := preload("res://addons/gd_chime/components/recipes/filter_set.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Narrowing := preload("res://addons/gd_chime/narrowing.gd")
const Verdict := preload("res://tests/verdict.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")

const TOGGLES := &"toggles"
const REMOVES := &"removes"

var _verdict := Verdict.new()
var _own := Translation.new()


## The filters a filter set reads, holding nothing but the chips the test
## gives, and a narrowing over no options for each picker.
class Filters extends Fixture.Model:
	var picking: Narrowing

	func _init(chimes: Chimes, in_region: StringName) -> void:
		super(chimes, in_region)
		picking = Narrowing.new(chimes, Bound.new(get_options))

	func get_chips() -> Variant: return of(&"chips").read()
	func get_building() -> Variant: return null
	func get_count() -> Variant: return null
	func get_options() -> Array: return []
	func get_properties() -> Array: return []
	func get_property_narrowing() -> Narrowing: return picking
	func get_value_narrowing() -> Narrowing: return picking


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(600, 300)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	_own.locale = "fr"
	_own.add_message("ripe", "mûr")
	_own.add_message("won", "vainqueur")
	TranslationServer.add_translation(_own)
	await _verdict.states(_it_says_its_words_while_on_and_in_brackets_while_off_in_place)
	await _verdict.states(_its_body_toggles_and_its_x_removes_carrying_its_payload_by_mouse_key_and_pad)
	await _verdict.states(_the_door_refusing_its_body_is_inert_and_a_press_dispatches_nothing)
	await _verdict.states(_its_words_are_said_in_the_language_on_and_data_as_it_is)
	await _verdict.states(_the_filter_set_s_chips_are_chips)
	TranslationServer.remove_translation(_own)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## The app: a chip over the model's words and flag, with a remove, carrying
## which it is; and one with no remove.
func _built(words: Variant = null) -> Dictionary:
	var made := Fixture.new(root, {TOGGLES: "toggle", REMOVES: "remove"})
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes, &"app")
	model.set_value(&"words", "pears")
	model.set_value(&"flag", true)
	made.commands.register(&"app", TOGGLES, model)
	made.commands.register(&"app", REMOVES, model)
	var shown: Variant = model.of(&"words") if words == null else words
	ui.start(ui.app(&"app", [ui.column([Chip.make(ui, shown, model.of(&"flag"), {"id": 3}, {toggles = TOGGLES, removes = REMOVES}).named(&"chip"), Chip.make(ui, "plums", model.of(&"flag"), {"id": 4}, {toggles = TOGGLES}).named(&"bare")])]))
	await _a_frame_passes()
	return {"made": made, "model": model, "chip": ui.node_named(&"chip"), "bare": ui.node_named(&"bare")}


func _done(built: Dictionary) -> void:
	(built["model"] as Node).free()
	(built["made"] as Fixture).done()


func _pressables(node: Node) -> Array:
	return node.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable)


func _said(node: Node) -> Array:
	return node.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Text).map(func(text: Text) -> String: return text.get_text())


func _it_says_its_words_while_on_and_in_brackets_while_off_in_place() -> void:
	var built := await _built()
	var model: Fixture.Model = built["model"]
	var chip: Node = built["chip"]
	var parts := chip.find_children("*", "Node", true, false)
	var on := _said(chip)
	model.set_value(&"flag", false)
	await _a_frame_passes()
	var off := _said(chip)
	_verdict.check(on == ["pears", "x"] and off == ["(pears)", "x"], "on, it says its words, and off the same words in brackets, beside its x: %s then %s" % [on, off])
	_verdict.check(chip.find_children("*", "Node", true, false) == parts, "turned off in place: the very same nodes")
	var body: Pressable = _pressables(chip)[0]
	_verdict.check(body.theme_type_variation == Fields.CHIP and root.theme.get_type_variation_base(Fields.CHIP) == Themes.PRESSABLE and body.get_drawn()[0] == root.theme.get_stylebox(&"normal", Themes.PRESSABLE), "drawn in the look's Chip, a pressable until a look draws it otherwise")
	_done(built)


func _its_body_toggles_and_its_x_removes_carrying_its_payload_by_mouse_key_and_pad() -> void:
	var built := await _built()
	var made: Fixture = built["made"]
	var model: Fixture.Model = built["model"]
	var chip: Node = built["chip"]
	var body: Pressable = _pressables(chip)[0]
	var x: Pressable = _pressables(chip)[1]
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = body.get_global_rect().get_center()
	root.push_input(click)
	await _a_frame_passes()
	var clicked: Dictionary = made.commands.get_last()["payload"]
	x.grab_focus()
	var enter := InputEventKey.new()
	enter.keycode = KEY_ENTER
	enter.physical_keycode = KEY_ENTER
	enter.pressed = true
	root.push_input(enter)
	await _a_frame_passes()
	var keyed: Dictionary = made.commands.get_last()["payload"]
	body.grab_focus()
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_A
	pad.pressed = true
	root.push_input(pad)
	await _a_frame_passes()
	_verdict.check(model.told_actions == [TOGGLES, REMOVES, TOGGLES] and clicked == {"id": 3} and keyed == {"id": 3} and made.commands.get_last()["payload"] == {"id": 3}, "clicked, its body toggles it; Enter on its x removes it; the pad's A on its body toggles it - each carrying which chip: %s" % [model.told_actions])
	_verdict.check(_pressables(built["bare"]).size() == 1 and _said(built["bare"]) == ["plums"], "a chip given no remove has its body alone: %s" % [_said(built["bare"])])
	_done(built)


func _the_door_refusing_its_body_is_inert_and_a_press_dispatches_nothing() -> void:
	var built := await _built()
	var model: Fixture.Model = built["model"]
	var body: Pressable = _pressables(built["chip"])[0]
	model.refuse(TOGGLES, Phrase.of("not while the stall is shut"))
	await _a_frame_passes()
	body.pressed()
	_verdict.check(body.get_state() == &"inert" and str(body.get_reason()) == "not while the stall is shut" and model.told_actions.is_empty(), "the door refusing a toggle, the body is drawn inert with the door's reason, and a press dispatches nothing: %s" % [body.get_state()])
	_done(built)


func _its_words_are_said_in_the_language_on_and_data_as_it_is() -> void:
	var built := await _built(Phrase.of("ripe"))
	var made: Fixture = built["made"]
	var model: Fixture.Model = built["model"]
	model.set_value(&"flag", false)
	made.commands.dispatch(Chimes.GLOBAL, Language.CHANGES_LANGUAGE, {"value": &"fr"})
	await _a_frame_passes()
	var french := _said(built["chip"])
	made.commands.dispatch(Chimes.GLOBAL, Language.CHANGES_LANGUAGE, {"value": Language.SOURCE})
	_done(built)
	var data := await _built()
	(data["model"] as Fixture.Model).set_value(&"words", "won")
	(data["made"] as Fixture).commands.dispatch(Chimes.GLOBAL, Language.CHANGES_LANGUAGE, {"value": &"fr"})
	await _a_frame_passes()
	var kept := _said(data["chip"])
	(data["made"] as Fixture).commands.dispatch(Chimes.GLOBAL, Language.CHANGES_LANGUAGE, {"value": Language.SOURCE})
	_verdict.check(french == ["(mûr)", "x"] and kept == ["won", "x"], "in French, a phrase is said in French, in its brackets while off, and a model's word is as the model holds it though the catalogue translates it: %s %s" % [french, kept])
	_done(data)


func _the_filter_set_s_chips_are_chips() -> void:
	var declared := {TOGGLES: "toggle", REMOVES: "remove", &"picks_property": "property", &"types_property": "find a property", &"picks_comparison": "comparison", &"picks_value": "pick a value", &"types_value": "find a value", &"sets_value": "value"}
	var made := Fixture.new(root, declared)
	var ui := made.ui
	var filters := Filters.new(made.chimes, &"app")
	filters.set_value(&"chips", [{"id": 1, "words": "won is over 100", "on": true}, {"id": 2, "words": "kind is soft", "on": false}])
	var actions := {"toggles": TOGGLES, "removes": REMOVES}
	# every action the filter set draws, by its own name, answered by the filters but for the typing, which the narrowing answers
	for action: StringName in declared:
		actions[String(action)] = action
		made.commands.register(&"app", action, filters.picking if String(action).begins_with("types") else filters)
	var on := func(_none: Variant) -> bool: return true
	var off := func(_none: Variant) -> bool: return false
	var alone := ui.column([Chip.make(ui, "won is over 100", Bound.new(filters.get_chips).map(on), {"id": 1}, {toggles = TOGGLES, removes = REMOVES}), Chip.make(ui, "kind is soft", Bound.new(filters.get_chips).map(off), {"id": 2}, {toggles = TOGGLES, removes = REMOVES})])
	ui.start(ui.app(&"app", [ui.column([FilterSet.make(ui, filters, actions).named(&"set"), alone.named(&"alone")])]))
	await _a_frame_passes()
	var chips: Array = _pressables(ui.node_named(&"set")).filter(func(part: Pressable) -> bool: return part.action in [TOGGLES, REMOVES])
	var shape := func(pressables: Array) -> Array: return pressables.map(func(part: Pressable) -> Array: return [part.action, part.payload(), part.theme_type_variation, _said(part), part.get_parent().theme_type_variation])
	_verdict.check(chips.size() == 4 and shape.call(chips) == shape.call(_pressables(ui.node_named(&"alone"))), "each of the filter set's chips is a chip: the same pressables, carrying the same, saying the same - the one off in brackets - in the same looks: %s" % [shape.call(chips)])
	filters.picking.free()
	filters.free()
	made.done()
