extends SceneTree

## What must be true of a surface whose style is bound: a ring of what the
## style read that leaves the style's name as it was lays nothing out again
## (dynasty-stability's measure, 2026-11-21: thirty blocks laid out again on
## every ring of the model, about half of each ring); a ring that changes
## the name wears the new style.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_surface_restyle.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Verdict := preload("res://tests/verdict.gd")
const Surface := preload("res://addons/gd_chime/components/primitives/surface.gd")

var _verdict := Verdict.new()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	await _verdict.states(_a_ring_leaving_the_style_as_it_was_lays_nothing_out_and_one_changing_it_wears_the_new)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


func _a_ring_leaving_the_style_as_it_was_lays_nothing_out_and_one_changing_it_wears_the_new() -> void:
	var made := Fixture.new(root, {})
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes, &"app")
	model.set_value(&"picked", false)
	model.set_value(&"other", 0)
	# the style read off the model, as a block's ground reads whether it is picked: one bell rings for every value of the model
	var style := ui.bound(func() -> StringName: return Themes.CARD if model.of(&"picked").read() else Themes.SURFACE)
	ui.start(ui.app(&"app", [ui.screen(&"first", [ui.surface(style, [ui.text("words")]).named(&"ground")], model)]))
	await _a_frame_passes()
	var ground: Surface = ui.node_named(&"ground")
	var sorted := [0]
	ground.sort_children.connect(func() -> void: sorted[0] += 1)
	model.set_value(&"other", 1)
	model.set_value(&"picked", false)
	await _a_frame_passes()
	var after_same: int = sorted[0]
	model.set_value(&"picked", true)
	await _a_frame_passes()
	_verdict.check(after_same == 0, "a ring that leaves the style's name as it was lays the surface out no more: %d sorts" % after_same)
	_verdict.check(ground.theme_type_variation == Themes.CARD and sorted[0] > 0, "a ring that changes it wears the new style, laid out again: %s, %d sorts" % [ground.theme_type_variation, sorted[0]])
	model.free()
	made.done()
