extends SceneTree

## What must be true of a split and the grip between its panes: the panes
## stand at the model's share, each held to its least; a folded pane is
## hidden with the grip at the edge; the pointer dragging the grip takes the
## share with it exactly; the keys and the pad step it by the look's step,
## along its way only, a step out of a folded side opening it; accept and a
## double press fold; the direction turns with a bound value; and a grip in a
## holder that says no share carries how far it moved as a share of that
## holder's own width.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_split.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Panels := preload("res://addons/gd_chime/panels.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Layout := preload("res://addons/gd_chime/components/primitives/layout.gd")
const Split := preload("res://addons/gd_chime/components/primitives/split.gd")
const Grip := preload("res://addons/gd_chime/components/primitives/grip.gd")
const Verdict := preload("res://tests/verdict.gd")

const FOLDS := &"folds_the_list"

var _verdict := Verdict.new()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(808, 400)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_the_panes_stand_at_the_share_each_held_to_its_least)
	await _verdict.states(_a_folded_pane_is_hidden_and_the_grip_stays_at_the_edge)
	await _verdict.states(_the_pointer_dragging_the_grip_takes_the_share_with_it)
	await _verdict.states(_the_keys_step_it_along_its_way_only_and_a_step_opens_a_folded_side)
	await _verdict.states(_accept_and_a_double_press_fold_the_pane_and_the_direction_turns_with_its_value)
	await _verdict.states(_a_grip_in_a_holder_that_says_no_share_carries_a_share_of_the_holder_s_own_width)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## A split of a list and a page over a panels model, the grip folding the
## list, in an app that fills the window: 808 wide, so the room past the
## grip's 8 is 800.
func _built(least_list: float = 0.0, down: Variant = false) -> Dictionary:
	var made := Fixture.new(root, {Panels.RESIZES: "resize", FOLDS: "fold the list"})
	var panels := Panels.new(made.chimes, {&"main": 0.25}, {&"list": [&"main", Panels.FIRST], &"page": [&"main", Panels.SECOND]}, {FOLDS: &"list"})
	root.add_child(panels)
	for action: StringName in [Panels.RESIZES, FOLDS]:
		made.commands.register(Chimes.GLOBAL, action, panels)
	var ui := made.ui
	var list := ui.surface(Themes.SURFACE, [ui.text("list")]).named(&"list")
	# a list that needs at least this much room across, by a column that wide
	if least_list > 0.0:
		list = ui.grid([ui.text("list")], [], Themes.GRID).named(&"list")
	var page: Desc = ui.surface(Themes.SURFACE, [ui.text("page")]).named(&"page")
	# which way the panes run, as the split now says it: read on where a bound value was given
	var way: Variant = down.map(func(on: Variant) -> int: return Layout.COLUMN if on else Layout.ROW) if down is Bound else (Layout.COLUMN if down else Layout.ROW)
	ui.start(ui.app(&"app", [ui.split(list, page, panels.share(&"main"), {resizes = Panels.RESIZES, carries = {"split": "main"}, folded = panels.folded(&"main"), runs = way, folds = FOLDS}).named(&"split")]))
	return {"made": made, "panels": panels}


func _grip(ui: RefCounted) -> Grip:
	return (ui.node_named(&"split") as Split).get_child(1)


func _done(built: Dictionary) -> void:
	(built["panels"] as Node).free()
	(built["made"] as Fixture).done()


func _the_panes_stand_at_the_share_each_held_to_its_least() -> void:
	var built := _built()
	var ui: RefCounted = built["made"].ui
	await _a_frame_passes()
	var list: Control = ui.node_named(&"list")
	var page: Control = ui.node_named(&"page")
	var grip := _grip(ui)
	_verdict.check(is_equal_approx(list.size.x, 200.0) and is_equal_approx(grip.position.x, 200.0) and is_equal_approx(grip.size.x, 8.0) and is_equal_approx(page.position.x, 208.0) and is_equal_approx(page.size.x, 600.0), "the list takes a quarter of the room past the grip, the grip the look's thickness after it, the page the rest: %s %s %s" % [list.size, grip.position, page.position])
	_verdict.check(is_equal_approx(list.size.y, 400.0) and is_equal_approx(grip.size.y, 400.0), "all three the whole way across")
	built["panels"].told(Panels.RESIZES, {"split": "main", "by": -0.25, "to": 0.0})
	await _a_frame_passes()
	var least: float = list.get_combined_minimum_size().x
	_verdict.check(least > 0.0 and is_equal_approx(list.size.x, least) and is_equal_approx(grip.position.x, least) and is_equal_approx(page.position.x, least + 8.0), "a share of nothing leaves the list the least it needs, the grip and the page after it: %s of %s, the grip at %s" % [list.size.x, least, grip.position.x])
	built["panels"].told(Panels.RESIZES, {"split": "main", "by": 1.0, "to": 1.0})
	await _a_frame_passes()
	_verdict.check(is_equal_approx(page.size.x, page.get_combined_minimum_size().x), "and a share of all of it leaves the page its least: %s" % page.size.x)
	_done(built)


func _a_folded_pane_is_hidden_and_the_grip_stays_at_the_edge() -> void:
	var built := _built()
	var ui: RefCounted = built["made"].ui
	await _a_frame_passes()
	built["panels"].told(FOLDS, {})
	await _a_frame_passes()
	var page: Control = ui.node_named(&"page")
	_verdict.check(not (ui.node_named(&"list") as Control).visible and is_equal_approx(_grip(ui).position.x, 0.0) and is_equal_approx(page.position.x, 8.0) and is_equal_approx(page.size.x, 800.0), "folded, the list is hidden, the grip at the edge and the page all the rest: %s %s" % [_grip(ui).position, page.size])
	_verdict.check(is_equal_approx((ui.node_named(&"split") as Split).get_placed_share(), 0.0), "and the split says its first pane takes nothing")
	_done(built)


func _the_pointer_dragging_the_grip_takes_the_share_with_it() -> void:
	var built := _built()
	var ui: RefCounted = built["made"].ui
	await _a_frame_passes()
	var grip := _grip(ui)
	_press_at(Vector2(204, 100), true)
	# the pointer dragged right in three moves, 40 pixels each, within one frame
	for step: int in 3:
		_move_to(Vector2(204 + 40 * (step + 1), 100), Vector2(40, 0))
	await _a_frame_passes()
	var last: Dictionary = built["made"].commands.get_last()
	_verdict.check(last["action"] == Panels.RESIZES and last["payload"]["split"] == "main" and is_equal_approx(last["payload"]["by"], 40.0 / 808.0), "each move dispatches the resize, naming the split, by the share of the split's width it moved: %s" % [last["payload"]])
	_verdict.check(is_equal_approx(built["panels"].share(&"main").read(), 0.25 + 120.0 / 808.0) and is_equal_approx(grip.position.x, 200.0 + 120.0 * 800.0 / 808.0), "three moves in one frame take the share the whole way the pointer went, and the grip with it: %s at %s" % [built["panels"].share(&"main").read(), grip.position.x])
	_press_at(Vector2(324, 100), false)
	_move_to(Vector2(400, 100), Vector2(76, 0))
	await _a_frame_passes()
	_verdict.check(is_equal_approx(built["panels"].share(&"main").read(), 0.25 + 120.0 / 808.0), "released, the pointer moving moves nothing")
	# taken far past the list's least and back a little: the edge waits for the pointer to come back to it
	_press_at(Vector2(324, 100), true)
	_move_to(Vector2(4, 100), Vector2(-320, 0))
	_move_to(Vector2(14, 100), Vector2(10, 0))
	await _a_frame_passes()
	_verdict.check(is_equal_approx(built["panels"].share(&"main").read(), 0.25 + (120.0 - 320.0 + 10.0) / 808.0), "dragged past a pane's least and back, the share is where the pointer is, not where the pane stopped: %s" % built["panels"].share(&"main").read())
	_press_at(Vector2(44, 100), false)
	_done(built)


func _the_keys_step_it_along_its_way_only_and_a_step_opens_a_folded_side() -> void:
	var built := _built()
	var ui: RefCounted = built["made"].ui
	await _a_frame_passes()
	var grip := _grip(ui)
	grip.grab_focus()
	await _a_frame_passes()
	_action(&"ui_right")
	await _a_frame_passes()
	_verdict.check(is_equal_approx(built["panels"].share(&"main").read(), 0.275) and grip.has_focus(), "right steps the share on by the look's step, and the grip keeps the focus: %s" % built["panels"].share(&"main").read())
	_action(&"ui_left")
	_action(&"ui_left")
	await _a_frame_passes()
	_verdict.check(is_equal_approx(built["panels"].share(&"main").read(), 0.225), "left steps it back, a step each: %s" % built["panels"].share(&"main").read())
	var before: Dictionary = built["made"].commands.get_last()
	_action(&"ui_down")
	await _a_frame_passes()
	_verdict.check(built["made"].commands.get_last() == before, "across its way, the key is not its own and moves nothing")
	built["panels"].told(FOLDS, {})
	await _a_frame_passes()
	grip.grab_focus()
	_action(&"ui_right")
	await _a_frame_passes()
	_verdict.check(built["panels"].folded(&"main").read() == Panels.NEITHER and (ui.node_named(&"list") as Control).visible and is_equal_approx(built["panels"].share(&"main").read(), 0.025), "a step out of a folded side opens it, a step from the edge: %s %s" % [built["panels"].folded(&"main").read(), built["panels"].share(&"main").read()])
	_done(built)


func _accept_and_a_double_press_fold_the_pane_and_the_direction_turns_with_its_value() -> void:
	var made_down := Fixture.Model.new(Chimes.new(preload("res://addons/gd_chime/belfry.gd").new()))
	var turned := Bound.new(func() -> bool: return made_down.values.get(&"down", false))
	var built := _built(0.0, false)
	var ui: RefCounted = built["made"].ui
	await _a_frame_passes()
	var grip := _grip(ui)
	grip.grab_focus()
	_action(&"ui_accept")
	await _a_frame_passes()
	_verdict.check(built["panels"].folded(&"main").read() == Panels.FIRST and built["made"].commands.get_last()["action"] == FOLDS, "accept on the grip dispatches its fold: %s" % built["panels"].folded(&"main").read())
	var twice := InputEventMouseButton.new()
	twice.button_index = MOUSE_BUTTON_LEFT
	twice.pressed = true
	twice.double_click = true
	twice.position = Vector2(4, 100)
	root.push_input(twice)
	await _a_frame_passes()
	_verdict.check(built["panels"].folded(&"main").read() == Panels.NEITHER, "and a double press folds it back: %s" % built["panels"].folded(&"main").read())
	_done(built)
	made_down.free()
	var down := _built(0.0, turned_value())
	ui = down["made"].ui
	await _a_frame_passes()
	var split: Split = ui.node_named(&"split")
	_verdict.check(split.is_down() and _grip(ui).down and is_equal_approx((ui.node_named(&"list") as Control).size.y, 98.0) and is_equal_approx((ui.node_named(&"list") as Control).size.x, 808.0), "down, the list stands over the page at its share of the height, the whole width across: %s" % (ui.node_named(&"list") as Control).size)
	_done(down)


## A direction read from a value: down, always, and bound.
func turned_value() -> Bound:
	return Bound.new(func() -> bool: return true)


func _a_grip_in_a_holder_that_says_no_share_carries_a_share_of_the_holder_s_own_width() -> void:
	var made := Fixture.new(root, {&"widens": "widen"})
	var model := Fixture.Model.new(made.chimes, Chimes.GLOBAL)
	made.commands.register(Chimes.GLOBAL, &"widens", model)
	var ui := made.ui
	# a heading row twice the window's width, as a heading scrolled across is
	ui.start(ui.app(&"app", [ui.scroll(ui.row([ui.text("name").basis(0.2), ui.grip(&"widens", {"column": "name"}).named(&"edge"), ui.text("kind").grow()]))]))
	await _a_frame_passes()
	var edge: Control = ui.node_named(&"edge")
	var holder: Control = edge.get_parent()
	holder.custom_minimum_size = Vector2(1616, 0)
	await _a_frame_passes()
	var at := edge.get_global_rect().get_center()
	_press_at(at, true)
	_move_to(at + Vector2(101, 0), Vector2(101, 0))
	await _a_frame_passes()
	var last: Dictionary = made.commands.get_last()
	_verdict.check(last["action"] == &"widens" and last["payload"]["column"] == "name" and is_equal_approx(last["payload"]["by"], 101.0 / holder.size.x) and not last["payload"].has("to"), "a move carries what it resizes and how far, a share of its holder's own width, and no share it was never told: %s over %s" % [last["payload"], holder.size.x])
	_press_at(at + Vector2(101, 0), false)
	model.free()
	made.done()


func _press_at(at: Vector2, down: bool) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = down
	click.position = at
	click.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	root.push_input(click)


func _move_to(at: Vector2, relative: Vector2) -> void:
	var move := InputEventMouseMotion.new()
	move.position = at
	move.relative = relative
	move.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(move)


func _action(named: StringName) -> void:
	var pressed := InputEventAction.new()
	pressed.action = named
	pressed.pressed = true
	root.push_input(pressed)
