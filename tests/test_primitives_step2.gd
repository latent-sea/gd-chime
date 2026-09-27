extends SceneTree

## What must be true of the primitives Step 2 added: a pulse, a canvas the
## reader pans, zooms and picks on, a scroll that reveals a named piece, a
## pressable absent while refused, and a line that wraps.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_primitives_step2.gd

const Fixture := preload("res://tests/fixture.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Pulse := preload("res://addons/gd_chime/components/primitives/pulse.gd")
const PanZoom := preload("res://addons/gd_chime/components/primitives/pan_zoom.gd")
const Scroll := preload("res://addons/gd_chime/components/primitives/scroll.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Layout := preload("res://addons/gd_chime/components/primitives/layout.gd")
const Verdict := preload("res://tests/verdict.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Pressables := preload("res://addons/gd_chime/theme_pressables.gd")

var _verdict := Verdict.new()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(400, 400)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_a_pulse_fades_while_its_value_holds_and_is_whole_while_it_does_not)
	await _verdict.states(_a_pan_zoom_canvas_dispatches_a_drag_a_wheel_and_a_pick_to_the_model)
	await _verdict.states(_a_scroll_reveals_the_piece_named_as_the_name_moves)
	await _verdict.states(_a_pressable_absent_when_refused_is_gone_not_inert)
	await _verdict.states(_tiles_wrap_onto_more_lines)
	await _verdict.states(_a_part_whose_words_arrive_late_takes_its_room_and_its_row_moves_the_rest)
	await _verdict.states(_a_bubble_sits_above_its_target_not_over_it)
	await _verdict.states(_a_style_the_look_does_not_know_is_laid_out_and_drawn_as_its_base)
	await _verdict.states(_a_bound_style_is_worn_in_place_and_a_pressable_keeps_its_focus)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


func _host(of: Vector2) -> Control:
	var host := Control.new()
	host.size = of
	root.add_child(host)
	return host


func _a_pulse_fades_while_its_value_holds_and_is_whole_while_it_does_not() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes)
	model.set_value(&"flag", true)
	# a pulse is a track of keyframes on the one clock, so the clock is turned by hand: no waiting on real time
	ui.motion.by_hand = true
	ui.motion.still = false
	var pulse: Pulse = ui.build(ui.pulse([ui.text("look here")], model.of(&"flag")), _host(Vector2(200, 100)))
	await _a_frame_passes()
	ui.motion.step(0.6)
	await _a_frame_passes()
	_verdict.check(pulse.is_pulsing() and pulse.modulate.a < 0.99, "while the value holds it pulses, fading part of the way: %s" % pulse.modulate.a)
	model.set_value(&"flag", false)
	await _a_frame_passes()
	ui.motion.step(0.0)
	_verdict.check(not pulse.is_pulsing() and pulse.modulate.a == 1.0, "the value gone, it is whole and still")
	pulse.get_parent().free()
	model.free()
	made.done()


func _a_pan_zoom_canvas_dispatches_a_drag_a_wheel_and_a_pick_to_the_model() -> void:
	var made := Fixture.new(root, {&"pans": "pan", &"zooms": "zoom", &"picks": "pick"})
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes)
	for action: StringName in [&"pans", &"zooms", &"picks"]:
		made.commands.register(Chimes.GLOBAL, action, model)
	var hit := func(at: Vector2) -> Variant: return "node" if at.x < 100.0 else null
	var canvas: PanZoom = ui.build(ui.pan_zoom(func(_control: Control, _value: Variant) -> void: pass, null, {"pans": &"pans", "zooms": &"zooms", "picks": &"picks"}, {hit = hit}), _host(Vector2(400, 400)))
	await _a_frame_passes()
	_mouse(MOUSE_BUTTON_LEFT, true, Vector2(200, 200))
	_motion(Vector2(230, 210), Vector2(30, 10))
	_mouse(MOUSE_BUTTON_LEFT, false, Vector2(230, 210))
	await _a_frame_passes()
	_verdict.check(model.told_actions == [&"pans"] and made.commands.get_last()["payload"] == {"by": Vector2(30, 10)}, "a drag on empty space pans the model by the movement, and picks nothing: %s" % [model.told_actions])
	_mouse(MOUSE_BUTTON_WHEEL_UP, true, Vector2(200, 200))
	await _a_frame_passes()
	_verdict.check(model.told_actions == [&"pans", &"zooms"] and made.commands.get_last()["payload"]["steps"] == 1, "the wheel zooms the model a step: %s" % [model.told_actions])
	_mouse(MOUSE_BUTTON_LEFT, true, Vector2(50, 50))
	_mouse(MOUSE_BUTTON_LEFT, false, Vector2(50, 50))
	await _a_frame_passes()
	_verdict.check(model.told_actions == [&"pans", &"zooms", &"picks"] and made.commands.get_last()["payload"] == {"picked": "node"}, "a press that never moved picks what the hit function answers: %s" % [model.told_actions])
	canvas.get_parent().free()
	var blind: PanZoom = ui.build(ui.pan_zoom(func(_control: Control, _value: Variant) -> void: pass, null, {"pans": &"pans", "zooms": &"zooms", "picks": &"picks"}), _host(Vector2(400, 400)))
	await _a_frame_passes()
	_mouse(MOUSE_BUTTON_LEFT, true, Vector2(50, 50))
	_mouse(MOUSE_BUTTON_LEFT, false, Vector2(50, 50))
	await _a_frame_passes()
	_verdict.check(model.told_actions.size() == 3, "given no hit function, a press picks nothing: %s" % [model.told_actions])
	blind.get_parent().free()
	model.free()
	made.done()


func _mouse(button: MouseButton, pressed: bool, at: Vector2) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = button
	click.pressed = pressed
	click.position = at
	root.push_input(click)


func _motion(at: Vector2, by: Vector2) -> void:
	var move := InputEventMouseMotion.new()
	move.position = at
	move.relative = by
	move.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(move)


func _a_scroll_reveals_the_piece_named_as_the_name_moves() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes)
	model.set_value(&"words", &"row_2")
	var rows: Array = []
	for index: int in range(30):
		rows.append(ui.surface(Themes.SURFACE, [ui.text("row %d" % index)]).named(StringName("row_%d" % index)))
	var scroll: Scroll = ui.build(ui.scroll(ui.column(rows), model.of(&"words")), _host(Vector2(200, 100)))
	await _a_frame_passes()
	await _a_frame_passes()
	_verdict.check(_within(scroll, ui.node_named(&"row_2")), "built naming a row near the top, the window shows it: %d" % scroll.scroll_vertical)
	model.set_value(&"words", &"row_25")
	await _a_frame_passes()
	await _a_frame_passes()
	_verdict.check(_within(scroll, ui.node_named(&"row_25")), "the name moved to a row far down, the scroll brought it into view: %d" % scroll.scroll_vertical)
	scroll.get_parent().free()
	model.free()
	made.done()


## Whether the piece lies within the scroll's window.
func _within(scroll: Scroll, piece: Control) -> bool:
	return Rect2(Vector2.ZERO, scroll.size).encloses(Rect2(piece.global_position - scroll.global_position, piece.size))


func _a_pressable_absent_when_refused_is_gone_not_inert() -> void:
	var made := Fixture.new(root, {&"advances": "advance"})
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes, &"app")
	made.commands.register(&"app", &"advances", model)
	ui.start(ui.app(&"app", [ui.row([ui.pressable(&"advances").absent_when_refused().named(&"it")])]))
	var pressed: Pressable = ui.node_named(&"it")
	await _a_frame_passes()
	_verdict.check(pressed.visible, "usable, it is there")
	model.refuse(&"advances", Phrase.of("you owe the world a decision"))
	await _a_frame_passes()
	_verdict.check(not pressed.visible, "refused, it is absent rather than inert")
	model.refuse_nothing()
	await _a_frame_passes()
	_verdict.check(pressed.visible, "allowed again, it is back")
	model.free()
	made.done()


func _tiles_wrap_onto_more_lines() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var tiles: Array = []
	for index: int in range(6):
		tiles.append(ui.surface(Themes.SURFACE, [ui.text("tile %d" % index)]).basis(0.4))
	var line: Layout = ui.build(ui.row(tiles, Themes.TILES), _host(Vector2(400, 300)))
	await _a_frame_passes()
	var rows: Dictionary = {}
	for tile: Control in line.get_children():
		rows[tile.position.y] = true
	_verdict.check(rows.size() == 3, "six tiles two fifths wide each wrap onto three lines: %d" % rows.size())
	line.get_parent().free()
	made.done()


## Two pressables in a row, each showing a bound word that is empty at the
## build: the words arrive on the bell, the first grows to fit them, and
## the second is moved along, never drawn over the first.
func _a_part_whose_words_arrive_late_takes_its_room_and_its_row_moves_the_rest() -> void:
	var made := Fixture.new(root, {&"ticks": "tick"})
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes, &"app")
	model.set_value(&"words", "")
	made.commands.register(&"app", &"ticks", model)
	var word: Bound = model.of(&"words")
	ui.start(ui.app(&"app", [ui.row([ui.pressable(&"ticks", {}, [ui.surface(Themes.SURFACE, [ui.text(word)])]).named(&"first"), ui.pressable(&"ticks", {}, [ui.text("second")]).named(&"second")])]))
	var first: Pressable = ui.node_named(&"first")
	var second: Pressable = ui.node_named(&"second")
	await _a_frame_passes()
	var before := second.position.x
	model.set_value(&"words", "a long line of words arriving after the build")
	await _a_frame_passes()
	_verdict.check(first.size.x >= first.get_combined_minimum_size().x and first.get_combined_minimum_size().x > 100.0, "the first grew to fit its words: %s" % [first.size])
	_verdict.check(second.position.x >= first.position.x + first.size.x and second.position.x > before, "and the second was moved along, not drawn over it: %s after %s" % [second.position.x, first.size.x])
	model.free()
	made.done()


## A bubble anchored to a control sits just above the control's rect, as
## wide as it, and never over its words.
func _a_bubble_sits_above_its_target_not_over_it() -> void:
	var made := Fixture.new(root, {&"ticks": "tick"})
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes, &"app")
	made.commands.register(&"app", &"ticks", model)
	ui.start(ui.app(&"app", [ui.stack([ui.column([ui.text("above"), ui.pressable(&"ticks", {}, [ui.text("the target")]).named(&"target")]), ui.anchored(&"target", [ui.surface(Themes.SURFACE, [ui.text("a bubble")])]).named(&"bubble")])]))
	var target: Control = ui.node_named(&"target")
	var bubble: Control = ui.node_named(&"bubble")
	await _a_frame_passes()
	await _a_frame_passes()
	var target_rect := target.get_global_rect()
	var bubble_rect := bubble.get_global_rect()
	_verdict.check(bubble_rect.size.y > 0.0 and is_equal_approx(bubble_rect.end.y, target_rect.position.y) and is_equal_approx(bubble_rect.size.x, target_rect.size.x), "the bubble ends where the target begins, as wide as it: %s over %s" % [bubble_rect, target_rect])
	model.free()
	made.done()


## A recipe names its own style; the look defines the bases alone. A column
## styled by a name the look does not know still stretches its parts
## across and keeps the row gap, and a pressable so styled still has a
## ground and a surface a panel.
func _a_style_the_look_does_not_know_is_laid_out_and_drawn_as_its_base() -> void:
	var made := Fixture.new(root, {&"ticks": "tick"})
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes, &"app")
	made.commands.register(&"app", &"ticks", model)
	ui.start(ui.app(&"app", [ui.column([ui.surface(&"NobodyKnows", [ui.text("a")]).named(&"ground"), ui.pressable(&"ticks", {}, [ui.text("b")], &"NobodyKnows").named(&"press")], &"NobodyKnows").named(&"column")]))
	await _a_frame_passes()
	var column: Layout = ui.node_named(&"column")
	var ground: Control = ui.node_named(&"ground")
	var press: Pressable = ui.node_named(&"press")
	_verdict.check(column.align == Layout.STRETCH and is_equal_approx(ground.size.x, column.size.x) and press.position.y > ground.size.y, "the column stretches its parts across and keeps a gap: %s of %s, then %s" % [ground.size.x, column.size.x, press.position.y])
	_verdict.check(press.has_theme_stylebox(&"normal") and ground.has_theme_stylebox(&"panel"), "the pressable has a ground and the surface a panel")
	model.free()
	made.done()


## A style may be a bound value: a text's kind, a surface's ground and a
## pressable's style each follow it on its bell, worn in place - the same
## nodes before and after, and a pressable holding the focus still holds it.
func _a_bound_style_is_worn_in_place_and_a_pressable_keeps_its_focus() -> void:
	var made := Fixture.new(root, {&"ticks": "tick"})
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes, &"app")
	model.set_value(&"flag", false)
	made.commands.register(&"app", &"ticks", model)
	var on: Bound = model.of(&"flag")
	var kind: Bound = on.map(func(flag: Variant) -> StringName: return Themes.FACE if flag else Themes.REASON)
	var ground: Bound = on.map(func(flag: Variant) -> StringName: return Themes.SURFACE if flag else &"NobodyKnows")
	var dress: Bound = on.map(func(flag: Variant) -> StringName: return Pressables.BUTTON if flag else Themes.PRESSABLE)
	ui.start(ui.app(&"app", [ui.column([ui.surface(ground, [ui.text("words", kind).named(&"words")]).named(&"ground"), ui.pressable(&"ticks", {}, [ui.text("press")], dress).named(&"press")])]))
	await _a_frame_passes()
	var words: Control = ui.node_named(&"words")
	var under: Control = ui.node_named(&"ground")
	var press: Pressable = ui.node_named(&"press")
	press.grab_focus()
	_verdict.check((words.get_child(0) as Label).theme_type_variation == Themes.REASON and under.theme_type_variation == Themes.SURFACE and press.theme_type_variation == Themes.PRESSABLE, "at rest each wears what its bound style says - the unknown ground its base")
	model.set_value(&"flag", true)
	await _a_frame_passes()
	_verdict.check((words.get_child(0) as Label).theme_type_variation == Themes.FACE and press.theme_type_variation == Pressables.BUTTON, "the value moved and each wears the new style: %s %s" % [(words.get_child(0) as Label).theme_type_variation, press.theme_type_variation])
	_verdict.check(ui.node_named(&"words") == words and ui.node_named(&"ground") == under and ui.node_named(&"press") == press and press.has_focus(), "in place: the same nodes, and the pressable still holds the focus")
	model.free()
	made.done()
