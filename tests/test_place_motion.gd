extends SceneTree

## What must be true of places seen to come and go.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_place_motion.gd
##
## Where one place takes another's room the move is a push: at every step
## the two are edge to edge, never one over the other and never apart; a
## forward move and Back are mirrored, and two places side by side go the
## way they lie; input and the focus are the new state's from the first
## frame; turned round mid-way, nothing jumps; a pop-up fades in over the
## app, which stays, and out again; the panel slides from its side; only
## the outermost place of what changed is moved; reduced, places switch.

const Fixture := preload("res://tests/fixture.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Motion := preload("res://addons/gd_chime/motion.gd")
const PlaceMotion := preload("res://addons/gd_chime/place_motion.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Transition := preload("res://addons/gd_chime/components/primitives/transition.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Verdict := preload("res://tests/verdict.gd")

const WIDE := 400.0

var _verdict := Verdict.new()
var _asking: StringName  # the pop-up over the app, named by the builder
var _drawer: StringName  # the panel beside it, named by the builder

var _made: Fixture
var _model: Fixture.Model


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(400, 400)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_which_places_move_and_from_which_side)
	await _verdict.states(_a_forward_move_is_a_push_edge_to_edge_and_input_is_the_new_state_s_at_once)
	await _verdict.states(_back_is_the_mirror_and_two_side_by_side_go_the_way_they_lie)
	await _verdict.states(_turned_round_mid_way_nothing_jumps_and_they_stay_edge_to_edge)
	await _verdict.states(_a_pop_up_fades_in_over_the_app_and_out_and_the_panel_slides_from_its_side)
	await _verdict.states(_only_the_outermost_place_of_what_changed_is_moved)
	await _verdict.states(_a_move_coming_to_rest_settles_only_what_it_moved)
	await _verdict.states(_a_room_clips_until_the_latest_push_through_it_rests)
	await _verdict.states(_reduced_places_switch)
	await _verdict.states(_a_place_pushed_out_and_shown_again_inside_an_arriving_one_stands_at_rest)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


func _step(seconds: float) -> void:
	_made.ui.motion.step(seconds)
	await _a_frame_passes()


func _go(place: StringName) -> void:
	_made.commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": place})
	await _a_frame_passes()


func _back() -> void:
	_made.commands.dispatch(Chimes.GLOBAL, Driver.GOES_BACK, {})
	await _a_frame_passes()


func _place(named: StringName) -> Control:
	return _made.driver.index.place_named(named)


## Three screens side by side in one room, each with a button; a pop-up and
## a panel beside the app; inner holds two screens of its own. The clock by hand.
func _standing() -> void:
	_made = Fixture.new(root, {&"adds": "add"})
	var ui := _made.ui
	_model = Fixture.Model.new(_made.chimes)
	_made.commands.register(Chimes.GLOBAL, &"adds", _model)
	var screen := func(named: StringName) -> RefCounted: return ui.screen(named, [ui.pressable(&"adds", {}, [ui.text(named)]).named(StringName("button_" + named))])
	var inner := ui.screen(&"inner", [ui.stack([screen.call(&"deep_a"), screen.call(&"deep_b")])])
	var asking := ui.pop_up(&"asking", func(_which: Bound) -> Desc: return ui.surface(Themes.SURFACE, [ui.pressable(&"adds", {}, [ui.text("asked")]).named(&"button_asking")]).arrives(Transition.SCALE).named(&"sheet"))
	var drawer := ui.pop_up(&"drawer", func(_which: Bound) -> Desc: return ui.text("drawer"), null).blocks_nothing()
	_asking = asking.get_place()
	_drawer = drawer.get_place()
	ui.start(ui.app(&"app", [ui.stack([screen.call(&"a"), screen.call(&"b"), screen.call(&"c"), inner]), asking, drawer]))
	await _a_frame_passes()
	await _go(&"a")
	ui.motion.by_hand = true
	ui.motion.still = false


func _done() -> void:
	_model.free()
	_made.done()


## How far two places in one room are from edge to edge: nothing, while one pushes the other.
func _between(left: Control, right: Control) -> float:
	return right.position.x - (left.position.x + left.size.x)


func _which_places_move_and_from_which_side() -> void:
	await _standing()
	var inner := _place(&"inner")
	_verdict.check(PlaceMotion.outermost([inner, _place(&"deep_a"), _place(&"b")]) == [inner, _place(&"b")], "of the places that changed, the ones no other of them holds")
	_verdict.check(PlaceMotion.side(_place(&"b"), _place(&"a"), false) == Vector2.RIGHT and PlaceMotion.side(_place(&"a"), _place(&"b"), false) == Vector2.LEFT, "two side by side: the later one comes from the right, the earlier from the left")
	_verdict.check(PlaceMotion.side(_place(&"a"), _place(&"b"), true) == Vector2.LEFT and PlaceMotion.side(_place(&"c"), _place(&"a"), true) == Vector2.LEFT, "Back comes from the left whichever way they lie")
	_verdict.check(PlaceMotion.side(_place(&"deep_a"), _place(&"a"), false) == Vector2.RIGHT, "a forward move between places not side by side comes from the right")
	_done()


func _a_forward_move_is_a_push_edge_to_edge_and_input_is_the_new_state_s_at_once() -> void:
	await _standing()
	var a := _place(&"a")
	var b := _place(&"b")
	await _go(&"b")
	_verdict.check(a.visible and b.visible and is_equal_approx(b.position.x, WIDE) and a.position.x == 0.0, "moved on, before a frame of it is seen: the old place still where it was, the new one wholly outside to the right: %s %s" % [a.position.x, b.position.x])
	var focused := root.gui_get_focus_owner()
	_verdict.check(focused == _made.ui.node_named(&"button_b") and a.mouse_behavior_recursive == Control.MOUSE_BEHAVIOR_DISABLED and a.focus_behavior_recursive == Control.FOCUS_BEHAVIOR_DISABLED and b.mouse_behavior_recursive == Control.MOUSE_BEHAVIOR_INHERITED, "and input is the new state's already: the focus is in the new place, the old one out of reach")
	(_made.ui.node_named(&"button_b") as Pressable).pressed()
	_verdict.check(_model.told_actions == [&"adds"], "a press in the arriving place runs at once, not when it has arrived")
	var room: Control = a.get_parent()
	_verdict.check(room.clip_contents, "and the room they share clips them while they move: a place on its way is never drawn over what stands beside the room")
	var apart: Array = []
	var crossed := false
	# the whole push, a hundredth of a second at a time: the gap between the two, and whether both are in the room at rest
	for tick: int in 17:
		await _step(0.01)
		apart.append(absf(_between(a, b)))
		crossed = crossed or (a.position.x == 0.0 and b.position.x == 0.0)
	_verdict.check(apart.max() < 0.01 and not crossed and a.position.x < 0.0 and b.position.x > 0.0, "at every step the two are edge to edge - never over each other, never apart - and both on the move: %s" % [apart.max()])
	await _step(0.5)
	_verdict.check(not a.visible and b.visible and b.position.x == 0.0 and a.focus_behavior_recursive == Control.FOCUS_BEHAVIOR_INHERITED and _made.ui.motion.get_running() == 0, "arrived: the new place at rest, the old one hidden and no longer switched off, nothing running")
	_verdict.check(not room.clip_contents, "and the room clips no longer: a focus ring, a shadow or a bubble reaching past its edge is whole again")
	room.clip_contents = true
	await _go(&"c")
	await _step(0.5)
	_verdict.check(room.clip_contents, "a room that clipped before a push clips after it: it is given back as it was")
	room.clip_contents = false
	await _go(&"a")
	await _step(0.5)
	_verdict.check(a.visible and a.position.x == 0.0 and a.modulate == Color.WHITE, "come back to, the place that was seen out stands at rest, whole")
	_done()


func _back_is_the_mirror_and_two_side_by_side_go_the_way_they_lie() -> void:
	await _standing()
	var a := _place(&"a")
	var b := _place(&"b")
	var c := _place(&"c")
	await _go(&"c")
	await _step(0.06)
	_verdict.check(c.position.x > 0.0 and a.position.x < 0.0, "to a later one of those side by side: it comes from the right")
	await _step(0.5)
	await _go(&"b")
	await _step(0.06)
	_verdict.check(b.position.x < 0.0 and c.position.x > 0.0 and absf(_between(b, c)) < 0.01, "to an earlier one: it comes from the left, pushing the other out to the right: %s %s" % [b.position.x, c.position.x])
	await _step(0.5)
	await _back()
	await _step(0.06)
	_verdict.check(c.visible and c.position.x < 0.0 and b.position.x > 0.0, "Back to the later one comes from the LEFT all the same - Back is the mirror of going on, whichever way they lie: %s" % c.position.x)
	await _step(0.5)
	_done()


func _turned_round_mid_way_nothing_jumps_and_they_stay_edge_to_edge() -> void:
	await _standing()
	var a := _place(&"a")
	var b := _place(&"b")
	await _go(&"b")
	await _step(0.06)
	var was: Array = [a.position.x, b.position.x]
	await _back()
	_verdict.check(absf(a.position.x - was[0]) < 0.01 and absf(b.position.x - was[1]) < 0.01 and a.visible and b.visible, "turned back a third of the way, both are exactly where they were: %s then %s %s, shown %s %s" % [was, a.position.x, b.position.x, a.visible, b.visible])
	_verdict.check(root.gui_get_focus_owner() == _made.ui.node_named(&"button_a") and b.mouse_behavior_recursive == Control.MOUSE_BEHAVIOR_DISABLED, "and input is the first place's again at once")
	var apart: Array = []
	for tick: int in 17:
		await _step(0.01)
		apart.append(absf(_between(a, b)))
	_verdict.check(apart.max() < 0.01 and a.position.x > was[0], "and go back the way they came, edge to edge all the way: %s" % [apart.max()])
	await _step(0.5)
	_verdict.check(a.position.x == 0.0 and a.visible and not b.visible and _made.ui.motion.get_running() == 0, "to rest: the first place whole, the other hidden, nothing running")
	_verdict.check(not (a.get_parent() as Control).clip_contents, "and the room, clipped through both halves of the turn, is given back as it was before the first")
	_done()


func _a_pop_up_fades_in_over_the_app_and_out_and_the_panel_slides_from_its_side() -> void:
	await _standing()
	var a := _place(&"a")
	var asking := _place(_asking)
	var drawer := _place(_drawer)
	await _go(_asking)
	_verdict.check(asking.visible and asking.modulate.a == 0.0 and a.visible and a.position.x == 0.0 and root.gui_get_focus_owner() == _made.ui.node_named(&"button_asking"), "raised: the pop-up begins unseen over the app, which stays where it is; the focus is the pop-up's at once")
	var sheet: Control = _made.ui.node_named(&"sheet")
	_verdict.check(sheet.scale == Transition.SMALL and asking.scale == Vector2.ONE, "what stands in it described as arriving its own way begins small - the sheet - while the pop-up itself, shade and all, is never scaled: %s" % sheet.scale)
	await _step(0.09)
	_verdict.check(asking.modulate.a > 0.0 and asking.modulate.a < 1.0 and asking.position.x == 0.0 and sheet.scale.x > Transition.SMALL.x and sheet.scale.x < 1.0 and asking.scale == Vector2.ONE, "it fades in and does not slide, its sheet scaling in over it: %s %s" % [asking.modulate.a, sheet.scale])
	await _step(0.5)
	_verdict.check(sheet.scale == Vector2.ONE and asking.modulate == Color.WHITE, "to rest")
	await _back()
	_verdict.check(asking.visible and asking.mouse_behavior_recursive == Control.MOUSE_BEHAVIOR_DISABLED and root.gui_get_focus_owner() == _made.ui.node_named(&"button_a"), "lowered: still drawn, out of reach, the focus back in the app at once")
	await _step(0.5)
	_verdict.check(not asking.visible and _made.ui.motion.get_running() == 0, "faded out, it is hidden")
	await _go(_asking)
	_verdict.check(sheet.scale == Transition.SMALL, "raised again, its sheet arrives again")
	await _step(0.5)
	await _back()
	await _step(0.5)
	await _go(_drawer)
	_verdict.check(drawer.visible and is_equal_approx(drawer.position.x, WIDE) and a.visible and a.position.x == 0.0, "the panel begins outside to the right - the look's side for it - and the app does not move: %s" % drawer.position.x)
	await _step(0.5)
	_verdict.check(drawer.position.x == 0.0 and drawer.modulate == Color.WHITE, "and slides in to rest")
	_done()


func _only_the_outermost_place_of_what_changed_is_moved() -> void:
	await _standing()
	var inner := _place(&"inner")
	var deep := _place(&"deep_a")
	await _go(&"deep_a")
	await _step(0.06)
	_verdict.check(inner.position.x > 0.0 and deep.visible and deep.position == Vector2.ZERO and deep.modulate == Color.WHITE and _place(&"a").position.x < 0.0, "into a place two deep: the outer one is pushed in, and the one inside it simply goes with it: %s" % inner.position.x)
	await _step(0.5)
	await _go(&"deep_b")
	await _step(0.06)
	_verdict.check(inner.position.x == 0.0 and _place(&"deep_b").position.x > 0.0 and absf(_between(deep, _place(&"deep_b"))) < 0.01, "then between the two inside it: they push, and the outer one stays")
	await _step(0.5)
	_done()


## Two moves on their way at once, each through a room of its own: the
## first coming to rest settles only what it moved - never the screen the
## second is still pushing out, which would vanish part way.
func _a_move_coming_to_rest_settles_only_what_it_moved() -> void:
	await _standing()
	var inner := _place(&"inner")
	await _go(&"deep_a")
	await _step(0.5)
	await _go(&"deep_b")
	await _step(0.02)
	await _go(&"c")
	await _step(0.17)
	_verdict.check(inner.visible and inner.position.x > 0.0 and inner.position.x < WIDE, "the push between the inner two has rested while the screens' is on its way: the screen being pushed out is still drawn, part way out to the right, the way they lie: %s at %s" % [inner.visible, inner.position.x])
	await _step(0.5)
	_verdict.check(not inner.visible and not _place(&"deep_a").visible and not _place(&"deep_b").visible and _place(&"c").visible and _made.ui.motion.get_running() == 0, "and at rest, everything that was moved out is hidden")
	_done()


## A pop-up raised mid-push fades out the place being pushed out, which is
## gone before its push ends, so a second push through the same room may
## begin while the first is on its way: the room clips until the LATER one
## rests, and the earlier resting neither gives the room back nor errs.
func _a_room_clips_until_the_latest_push_through_it_rests() -> void:
	await _standing()
	var room: Control = _place(&"a").get_parent()
	await _go(&"b")
	await _step(0.02)
	await _go(_asking)
	await _step(0.1)
	await _back()
	await _go(&"c")
	await _step(0.08)
	_verdict.check(room.clip_contents and _place(&"c").position.x > 0.0, "the first push has rested and the second is on its way: the room still clips: %s, the arriving place at %s" % [room.clip_contents, _place(&"c").position.x])
	await _step(0.5)
	_verdict.check(not room.clip_contents and _made.ui.motion.get_running() == 0, "and is given back as it was once the later push has rested")
	_done()


func _reduced_places_switch() -> void:
	await _standing()
	_made.ui.motion.told(Motion.REDUCES, {"on": true})
	await _go(&"b")
	_verdict.check(not _place(&"a").visible and _place(&"b").visible and _place(&"b").position.x == 0.0 and _made.ui.motion.get_running() == 0, "reduced, a move is a switch: the old place hidden and the new at rest, at once")
	await _go(_asking)
	_verdict.check(_place(_asking).modulate.a == 0.0 and (_made.ui.node_named(&"sheet") as Control).scale == Vector2.ONE and _made.ui.motion.get_running() > 0, "a pop-up still fades, and its sheet does not scale")
	await _step(0.09)
	_verdict.check(_place(_asking).modulate == Color.WHITE, "a short fade")
	_done()


## A place pushed out of its room, then shown again inside a place that
## arrives around it - so the outer one is what is pushed - stands at rest
## in its room: after a push that ran its course, one left part way by a
## second move elsewhere, and one reduced to a switch. The form's steps,
## left for another step and then the form left and come back to.
func _a_place_pushed_out_and_shown_again_inside_an_arriving_one_stands_at_rest() -> void:
	# every way the inner push may end: run its course, left part way, and reduced
	for way: String in ["run", "left part way", "reduced"]:
		await _standing()
		if way == "reduced":
			_made.ui.motion.told(Motion.REDUCES, {"on": true})
		await _go(&"deep_a")
		await _step(0.5)
		await _go(&"deep_b")
		await _step(0.06 if way == "left part way" else 0.5)
		await _go(&"a")
		await _step(0.5)
		await _go(&"deep_a")
		await _step(0.5)
		var deep := _place(&"deep_a")
		_verdict.check(deep.visible and deep.position == Vector2.ZERO and _place(&"inner").position == Vector2.ZERO and _made.ui.motion.get_running() == 0, "%s, deep_a pushed out by deep_b, the screens left, and deep_a come back to inside the arriving screen: it stands at rest in its room: %s" % [way, deep.position])
		_done()
	# a move made while another is on its way leaves two places at once, so each fades out; come back to by a push, the faded one is whole
	await _standing()
	await _go(&"b")
	await _step(0.06)
	await _go(&"c")
	await _step(0.5)
	await _go(&"a")
	await _step(0.5)
	_verdict.check(_place(&"a").visible and _place(&"a").modulate == Color.WHITE and _place(&"a").position == Vector2.ZERO, "a place faded out as two left at once, pushed back in later, is whole, not clear: %s" % _place(&"a").modulate)
	_done()
