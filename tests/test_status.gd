extends SceneTree

## What must be true of a status: no two states share a shape, and every
## shape stands inside its mark; the mark is its look's size and stays so,
## and nothing around it moves, as its state changes; the words stand beside
## it; the look holds an ink for each state. That the painting takes that
## ink is not asserted: nothing headless reads a pixel back.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_status.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Status := preload("res://addons/gd_chime/components/recipes/status.gd")
const Verdict := preload("res://tests/verdict.gd")
const Feedback := preload("res://addons/gd_chime/theme_feedback.gd")

var _verdict := Verdict.new()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(800, 600)
	await _verdict.states(_no_two_states_share_a_shape_and_every_shape_stands_inside_its_mark)
	await _verdict.states(_the_mark_is_its_look_s_size_and_nothing_moves_as_its_state_changes)
	quit(_verdict.deliver(get_script()))


func _no_two_states_share_a_shape_and_every_shape_stands_inside_its_mark() -> void:
	var room := Rect2(10.0, 20.0, 18.0, 18.0)
	var shapes: Array = Status.STATES.map(func(state: StringName) -> String: return var_to_str(Status.outline(state, room)))
	var distinct: Array = []
	# every state's shape, kept once
	for shape: String in shapes:
		if not distinct.has(shape):
			distinct.append(shape)
	_verdict.check(distinct.size() == Status.STATES.size(), "the five states are five shapes: %d distinct" % distinct.size())
	var inside := true
	# every state, every point it fills or draws through
	for state: StringName in Status.STATES:
		var shape := Status.outline(state, room)
		for part: PackedVector2Array in shape["filled"] + shape["lines"]:
			for point: Vector2 in part:
				inside = inside and room.grow(0.01).has_point(point)
	_verdict.check(inside, "every shape stands inside its mark")


func _the_mark_is_its_look_s_size_and_nothing_moves_as_its_state_changes() -> void:
	var made := Fixture.new(root)
	var model := Fixture.Model.new(made.chimes)
	root.add_child(model)
	model.set_value(&"flag", Status.WELL)
	var ui := made.ui
	var line := Status.make(ui, model.of(&"flag"), model.of(&"flag").map(func(state: Variant) -> String: return "the state is %s" % state)).named(&"line")
	ui.start(ui.app(&"app", [ui.column([line, ui.text("under it").named(&"under")])]))
	await process_frame
	await process_frame
	var mark: Control = ui.node_named(&"line").get_child(0)
	var half := float(root.theme.get_constant(&"mark", Feedback.STATUS_MARK))
	var before := mark.get_global_rect()
	var under: Control = ui.node_named(&"under")
	var under_before := under.get_global_rect()
	_verdict.check(before.size == Vector2(half, half) * 2.0, "the mark is its look's size: %s" % before.size)
	var canvas: Control = _canvas_in(mark)
	_verdict.check(canvas.size == before.size, "the shape is drawn over the whole of the mark: %s in %s" % [canvas.size, before.size])
	var drawn: int = canvas.refresh_count
	model.set_value(&"flag", Status.FAULT)
	await process_frame
	await process_frame
	_verdict.check(canvas.refresh_count > drawn and mark.get_global_rect() == before and under.get_global_rect() == under_before, "its state changing draws the mark again and moves neither it nor what is under it: %s" % mark.get_global_rect())
	_verdict.check(Status.STATES.all(func(state: StringName) -> bool: return canvas.has_theme_color(state) and canvas.get_theme_color(state) == root.theme.get_color(Feedback.INKS[state], Themes.LOOK)), "the mark's look holds an ink for every state, the palette's by name")
	var words := ""
	# every part of the line, for the words beside the mark
	for part: Node in ui.node_named(&"line").get_children():
		if part.has_method(&"get_text"):
			words = part.get_text()
	_verdict.check(words == "the state is fault", "the words stand beside the mark and say the state: %s" % words)
	made.done()


## The canvas the shape is drawn on, wherever under the mark it stands.
static func _canvas_in(node: Node) -> Control:
	# every child, itself the canvas or searched within
	for child: Node in node.get_children():
		if child.get_script() != null and child.get_script().resource_path.ends_with("canvas.gd"):
			return child
		var within := _canvas_in(child)
		if within != null:
			return within
	return null
