extends SceneTree

## What must be true of a toggle in the floor's look: turned on it is as tall
## and as wide as turned off, so a toggle turning - the pause of a live
## screen - moves nothing beside it.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_toggle_steady.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Verdict := preload("res://tests/verdict.gd")
const Pressables := preload("res://addons/gd_chime/theme_pressables.gd")

const TURNS := &"turns_it"

var _verdict := Verdict.new()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	await _verdict.states(_turned_on_a_toggle_needs_the_room_it_needed_off)
	quit(_verdict.deliver(get_script()))


func _turned_on_a_toggle_needs_the_room_it_needed_off() -> void:
	var made := Fixture.new(root, {TURNS: "turn it"})
	var model := Fixture.Model.new(made.chimes)
	root.add_child(model)
	made.commands.register(Fixture.Chimes.GLOBAL, TURNS, model)
	model.set_value(&"flag", false)
	var ui := made.ui
	var worn: RefCounted = model.of(&"flag").map(func(on: Variant) -> StringName: return Pressables.TOGGLE_ON if on else Pressables.TOGGLE_OFF)
	var toggle := ui.pressable(TURNS, {}, [ui.text("pause", Themes.FACE)], worn).named(&"toggle")
	ui.start(ui.app(&"app", [ui.column([toggle, ui.text("under it").named(&"under")])]))
	await process_frame
	await process_frame
	var pressed: Control = ui.node_named(&"toggle")
	var off := pressed.get_combined_minimum_size()
	var under: Vector2 = (ui.node_named(&"under") as Control).global_position
	model.set_value(&"flag", true)
	await process_frame
	await process_frame
	_verdict.check(pressed.theme_type_variation == Pressables.TOGGLE_ON and pressed.get_combined_minimum_size() == off and (ui.node_named(&"under") as Control).global_position == under, "turned on, the toggle needs the room it needed off, and what is under it stays: %s from %s" % [pressed.get_combined_minimum_size(), off])
	made.done()
