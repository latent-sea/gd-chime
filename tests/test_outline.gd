extends SceneTree

## What must be true of an outline: the one chosen is framed on all four
## sides, over whatever is laid to its edges, and choosing moves nothing.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## UI-007 and UI-004 (the QA of 2026-11-20): one chosen of several was
## outlined on some sides only, its picture drawn over the rest of its
## frame; and a table changed size as a row of it was chosen.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_outline.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Verdict := preload("res://tests/verdict.gd")
const Outline := preload("res://addons/gd_chime/components/primitives/outline.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const DrawnOver := preload("res://addons/gd_chime/drawn_over.gd")
const Look := preload("res://addons/gd_chime/look.gd")

var _verdict := Verdict.new()
var _hearing := Hearing.new()


## Counts what is pushed as an error, which is how an outline says its style fills.
class Hearing extends Logger:
	var refusals: int = 0

	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_ERROR:
			refusals += 1


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	await _verdict.states(_the_one_chosen_is_ringed_on_all_four_sides_over_what_is_laid_to_its_edges)
	await _verdict.states(_choosing_moves_nothing_and_what_is_under_the_outline_is_pressed_as_ever)
	await _verdict.states(_an_outline_whose_style_fills_its_middle_is_reported_and_draws_nothing)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## Two blocks side by side, each a press laid to all four of its edges with an outline over it, shown while the
## model's flag names it; and the model.
func _blocks(made: Fixture, style: StringName = Outline.TYPE) -> Fixture.Model:
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes, &"app")
	model.answering = [&"picks"]
	model.set_value(&"flag", 0)
	var block := func(at: int) -> RefCounted:
		return ui.stack([ui.pressable(&"picks", {"at": at}, [ui.text("block %d" % at)]).named(StringName("press%d" % at)),
			ui.outline(style, model.of(&"flag").map(func(chosen: Variant) -> bool: return chosen == at)).named(StringName("ring%d" % at))]).named(StringName("block%d" % at)).basis(0.3)
	ui.start(ui.app(&"app", [ui.screen(&"here", [ui.row([block.call(1), block.call(2), ui.surface(Themes.SURFACE).grow()]).named(&"row")], model)]))
	return model


func _the_one_chosen_is_ringed_on_all_four_sides_over_what_is_laid_to_its_edges() -> void:
	var made := Fixture.new(root, {&"picks": "pick"})
	var model := _blocks(made)
	model.set_value(&"flag", 1)
	await _a_frame_passes()
	var ui := made.ui
	var block: Control = ui.node_named(&"block1")
	var ring: Outline = ui.node_named(&"ring1")
	var other: Outline = ui.node_named(&"ring2")
	var press: Control = ui.node_named(&"press1")
	var panel := ring.get_theme_stylebox(&"panel") as StyleBoxFlat
	_verdict.check(ring.is_visible_in_tree() and not other.is_visible_in_tree(), "the one chosen is outlined and the other is not: %s %s" % [ring.visible, other.visible])
	_verdict.check(press.get_global_rect() == block.get_global_rect() and ring.get_global_rect() == block.get_global_rect(), "its outline is laid across the whole of what it frames, which is laid to every edge: %s over %s" % [ring.get_global_rect(), press.get_global_rect()])
	_verdict.check(ring.get_index() > press.get_index() and ring.z_index >= press.z_index, "and is drawn after it, so over it")
	_verdict.check(panel != null and not panel.draw_center and [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM].all(func(side: Side) -> bool: return panel.get_border_width(side) > 0 and panel.get_expand_margin(side) <= 0.0), "what it draws is a ring on all four sides, inside its own edges, with no middle")
	_verdict.check(DrawnOver.covered(root, Rect2(Vector2.ZERO, Vector2(root.size))).is_empty(), "and nothing the reader reads or presses is covered by it: %s" % [DrawnOver.covered(root, Rect2(Vector2.ZERO, Vector2(root.size)))])
	model.free()
	made.done()


func _choosing_moves_nothing_and_what_is_under_the_outline_is_pressed_as_ever() -> void:
	var made := Fixture.new(root, {&"picks": "pick"})
	var model := _blocks(made)
	await _a_frame_passes()
	var ui := made.ui
	var names: Array[StringName] = [&"row", &"block1", &"press1", &"block2", &"press2"]
	var rects := func() -> Array: return names.map(func(name: StringName) -> Rect2: return (ui.node_named(name) as Control).get_global_rect())
	var least := func() -> Array: return names.map(func(name: StringName) -> Vector2: return (ui.node_named(name) as Control).get_combined_minimum_size())
	var unchosen: Array = [rects.call(), least.call()]
	model.set_value(&"flag", 2)
	await _a_frame_passes()
	var chosen: Array = [rects.call(), least.call()]
	_verdict.check((ui.node_named(&"ring2") as Control).is_visible_in_tree() and chosen == unchosen, "one chosen, every piece stands where it stood and needs the room it needed: %s then %s" % [unchosen[0], chosen[0]])
	# a press on the outline's own edge, a pixel inside the block
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = (ui.node_named(&"block2") as Control).get_global_rect().position + Vector2(1, 1)
	root.push_input(click)
	await _a_frame_passes()
	_verdict.check(model.told_actions == [&"picks"], "a press on the outline's edge reaches the press under it: %s" % [model.told_actions])
	model.free()
	made.done()


func _an_outline_whose_style_fills_its_middle_is_reported_and_draws_nothing() -> void:
	Look.outline(root.theme, &"Filled", Look.flat(Color.WHITE))
	var made := Fixture.new(root, {&"picks": "pick"})
	OS.add_logger(_hearing)
	var model := _blocks(made, &"Filled")
	model.set_value(&"flag", 1)
	await _a_frame_passes()
	OS.remove_logger(_hearing)
	_verdict.check(_hearing.refusals >= 1, "a style that fills is said out loud as it is drawn: %d" % _hearing.refusals)
	model.free()
	made.done()
