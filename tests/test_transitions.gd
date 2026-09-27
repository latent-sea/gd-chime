extends SceneTree

## What must be true of arriving, going and travelling.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_transitions.gd
##
## Every transition reaches its end state, arriving and going; a thing
## going stays until its exit has run, out of its holder's content and out
## of reach, and is then freed; a reorder is planned - what stays in step
## slides, what would cross is lifted out and set down - and at no step of
## it, nor of one changed again mid-way, is anything drawn over anything
## else; pieces entering together enter one after another; reduced,
## nothing moves; over budget, nothing new does; and more arriving and going
## in one frame than the look's bulk are all at rest at once, while one
## alone still moves.

const Fixture := preload("res://tests/fixture.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Each := preload("res://addons/gd_chime/components/primitives/each.gd")
const FrameBudget := preload("res://addons/gd_chime/frame_budget.gd")
const Motion := preload("res://addons/gd_chime/motion.gd")
const MotionTokens := preload("res://addons/gd_chime/motion_tokens.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Reorder := preload("res://addons/gd_chime/components/primitives/reorder.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Transition := preload("res://addons/gd_chime/components/primitives/transition.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Going := preload("res://addons/gd_chime/components/primitives/going.gd")
const Verdict := preload("res://tests/verdict.gd")

var _verdict := Verdict.new()
var _made: Fixture
var _model: Fixture.Model


class Spent extends FrameBudget:
	func is_over() -> bool:
		return true


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(400, 400)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_every_transition_reaches_its_end_state_arriving_and_going)
	await _verdict.states(_a_thing_going_stays_until_its_exit_has_run_out_of_reach_and_is_then_freed)
	await _verdict.states(_the_plan_slides_what_stays_in_step_and_lifts_what_would_cross)
	await _verdict.states(_a_reorder_is_seen_and_nothing_is_ever_drawn_over_anything_else)
	await _verdict.states(_changed_again_mid_way_nothing_jumps_and_still_nothing_overlaps)
	await _verdict.states(_a_going_thing_never_leaves_the_tree_and_a_place_in_it_gives_up_its_name_at_once)
	await _verdict.states(_turned_round_mid_way_one_run_writes_each_property_and_nothing_flickers)
	await _verdict.states(_a_going_piece_stays_where_it_stood_and_the_layout_closes_up_without_it)
	await _verdict.states(_a_grid_a_stack_and_an_inset_close_up_without_a_going_thing_too)
	await _verdict.states(_a_slide_ends_where_the_layout_put_it_whatever_moved_meanwhile)
	await _verdict.states(_a_part_of_the_screen_under_its_own_look_moves_by_its_own_look)
	await _verdict.states(_pieces_entering_together_enter_one_after_another)
	await _verdict.states(_reduced_nothing_moves_and_over_budget_nothing_new_does)
	await _verdict.states(_many_shown_in_one_frame_are_at_rest_at_once_and_one_alone_still_moves)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


func _step(seconds: float) -> void:
	_made.ui.motion.step(seconds)
	await _a_frame_passes()


## A fixture whose clock moves, by hand, and a model in the app's region.
func _standing(declared: Dictionary = {}) -> void:
	_made = Fixture.new(root, declared)
	_made.ui.motion.by_hand = true
	_made.ui.motion.still = false
	_model = Fixture.Model.new(_made.chimes, &"app")


func _done() -> void:
	_model.free()
	_made.done()


## Three rows kept by id, each as tall as its words, down a column.
func _a_list(asked: StringName = &"") -> Each:
	var ui := _made.ui
	_model.set_value(&"items", [{"id": 1, "name": "ann"}, {"id": 2, "name": "bo"}, {"id": 3, "name": "cy"}])
	var row := func(item: Bound) -> Desc: return ui.text(item.field("name"))
	var listed := ui.each(_model.of(&"items"), row, func(item: Dictionary) -> int: return item["id"]).named(&"list")
	if asked != &"":
		listed.transition(asked)
	ui.start(ui.app(&"app", [ui.column([listed, ui.surface(Themes.SURFACE).grow()])]))
	await _a_frame_passes()
	return ui.node_named(&"list")


func _every_transition_reaches_its_end_state_arriving_and_going() -> void:
	# every transition there is, asked for on a when that swaps one side for the other
	for kind: StringName in Transition.KINDS:
		_standing()
		var ui := _made.ui
		_model.set_value(&"flag", true)
		ui.start(ui.app(&"app", [ui.when(_model.of(&"flag"), ui.text("first").named(&"first"), ui.text("second").named(&"second")).transition(kind).named(&"when")]))
		await _a_frame_passes()
		var first: Control = ui.node_named(&"first")
		_verdict.check(first.modulate == Color.WHITE and first.scale == Vector2.ONE and first.position == Vector2.ZERO, "%s: what is first shown is simply there" % kind)
		_model.set_value(&"flag", false)
		await _a_frame_passes()
		var second: Control = ui.node_named(&"second")
		var begun: bool = kind == Transition.NONE or second.modulate.a == 0.0
		await _step(0.5)
		_verdict.check(begun and second.modulate == Color.WHITE and second.scale == Vector2.ONE and second.position == Vector2.ZERO and not is_instance_valid(first) and ui.motion.get_running() == 0, "%s: arriving it begins unseen and ends exactly at rest; the one going is freed; nothing is left running" % kind)
		_done()


func _a_thing_going_stays_until_its_exit_has_run_out_of_reach_and_is_then_freed() -> void:
	_standing({&"adds": "add"})
	var ui := _made.ui
	_made.commands.register(&"app", &"adds", _model)
	_model.set_value(&"flag", true)
	ui.start(ui.app(&"app", [ui.when(_model.of(&"flag"), ui.pressable(&"adds", {}, [ui.text("add")]).named(&"going")).named(&"when")]))
	await _a_frame_passes()
	var going: Pressable = ui.node_named(&"going")
	var holder: Control = ui.node_named(&"when")
	_model.set_value(&"flag", false)
	await _a_frame_passes()
	_verdict.check(is_instance_valid(going) and going.get_parent() == holder and Going.is_going(going) and holder.get_child(-1) == going, "gone from the value, it is still drawn, where it was in the tree - marked as going, and last among its holder's children")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = going.global_position + going.size / 2.0
	root.push_input(click)
	await _a_frame_passes()
	_verdict.check(going.get_focus_mode_with_override() == Control.FOCUS_NONE and _model.told_actions.is_empty() and going.mouse_behavior_recursive == Control.MOUSE_BEHAVIOR_DISABLED, "and takes no focus and no press while it goes: %s" % [_model.told_actions])
	await _step(0.045)
	_verdict.check(is_instance_valid(going) and going.modulate.a > 0.0 and going.modulate.a < 1.0, "half way through the look's exit it is half gone: %s" % going.modulate.a)
	await _step(0.045)
	_verdict.check(not is_instance_valid(going), "its exit run, it is freed")
	_done()


## Every pair of things drawn under this list that are drawn over each other now: the pieces, and whatever is going.
func _overlapping(list: Control) -> Array:
	var seen: Array = list.get_children(true).filter(func(child: Node) -> bool: return child is Control and (child as Control).modulate.a > 0.01)
	var pairs: Array = []
	for a: int in seen.size():
		for b: int in range(a + 1, seen.size()):
			var one := Rect2(seen[a].position, seen[a].size * seen[a].scale)
			var other := Rect2(seen[b].position, seen[b].size * seen[b].scale)
			if one.intersects(other):
				pairs.append([_texts(seen[a]), _texts(seen[b])])
	return pairs


func _texts(node: Node) -> Array:
	var found: Array = []
	for child: Node in node.get_children():
		if child is Label:
			found.append((child as Label).text)
		found.append_array(_texts(child))
	return found


## The clock stepped in small steps through this long, the list looked at after every one: every overlap seen on the way.
func _watched(list: Control, seconds: float) -> Array:
	var seen: Array = []
	for tick: int in ceili(seconds / 0.01):
		await _step(0.01)
		seen.append_array(_overlapping(list))
	return seen


func _the_plan_slides_what_stays_in_step_and_lifts_what_would_cross() -> void:
	var rows := func(order: Array) -> Dictionary:
		var places: Dictionary = {}
		for index: int in order.size():
			places[order[index]] = Vector2(0, index * 10)
		return places
	var turned := Reorder.plan(rows.call([1, 2, 3]), rows.call([3, 2, 1]), [1, 2, 3], [3, 2, 1])
	_verdict.check(turned == {"slides": [], "lifts": [3, 1]}, "a list turned over: the one that has not moved stays, and the two that would cross it and each other are lifted: %s" % [turned])
	var shorter := Reorder.plan(rows.call([1, 2, 3]), rows.call([2, 3]), [1, 2, 3], [2, 3])
	_verdict.check(shorter == {"slides": [2, 3], "lifts": []}, "the first gone, the rest close up by sliding: they keep their order: %s" % [shorter])
	var sent_back := Reorder.plan(rows.call([1, 2, 3, 4]), rows.call([2, 3, 4, 1]), [1, 2, 3, 4], [2, 3, 4, 1])
	_verdict.check(sent_back == {"slides": [2, 3, 4], "lifts": [1]}, "one sent to the end: the many in step slide, the one that would cross them is lifted: %s" % [sent_back])
	var rewrapped := Reorder.plan({1: Vector2(0, 0), 2: Vector2(10, 0), 3: Vector2(0, 10)}, {2: Vector2(0, 0), 3: Vector2(10, 0)}, [1, 2, 3], [2, 3])
	_verdict.check(rewrapped == {"slides": [2], "lifts": [3]}, "in step but changing rows, a tile would cut across the others: it is lifted: %s" % [rewrapped])


func _a_reorder_is_seen_and_nothing_is_ever_drawn_over_anything_else() -> void:
	_standing()
	var list := await _a_list()
	var ann: Control = list.piece_for(1)
	var bo: Control = list.piece_for(2)
	var top: Vector2 = ann.position
	var second: Vector2 = bo.position
	var bottom: Vector2 = list.piece_for(3).position
	_model.set_value(&"items", [{"id": 2, "name": "bo"}, {"id": 3, "name": "cy"}, {"id": 1, "name": "ann"}])
	await _a_frame_passes()
	_verdict.check(list.piece_for(1) == ann and ann.get_index() == 2 and ann.position == top and bo.position == second, "sorted, the pieces are the same pieces in their new order, and every one is still drawn where it was: %s %s" % [ann.position, bo.position])
	var crossed: Array = await _watched(list, 0.09)
	_verdict.check(ann.modulate.a == 0.0 and bo.position == second, "first beat: the one that would cross the others has faded out where it stood, and nothing else has moved: %s" % ann.modulate.a)
	crossed.append_array(await _watched(list, 0.09))
	_verdict.check(bo.position.y < second.y and bo.position.y > top.y and ann.modulate.a == 0.0, "second beat: the ones in step slide, through room nothing is drawn in: %s" % bo.position)
	crossed.append_array(await _watched(list, 0.5))
	_verdict.check(bo.position == top and ann.position == bottom and ann.modulate == Color.WHITE and _made.ui.motion.get_running() == 0, "third beat: the lifted one is set down where it belongs; all at rest, nothing left running: %s" % ann.position)
	_verdict.check(crossed.is_empty(), "and at no step on the way was anything drawn over anything else: %s" % [crossed.slice(0, 3)])
	_done()


func _changed_again_mid_way_nothing_jumps_and_still_nothing_overlaps() -> void:
	_standing()
	var list := await _a_list()
	var crossed: Array = []
	var names := {1: "ann", 2: "bo", 3: "cy", 4: "dee"}
	# four changes, each landing part way through the one before: gone, arrived, turned about
	for order: Array in [[2, 3, 1], [3, 1, 2, 4], [4, 2], [1, 2, 3]]:
		var before: Dictionary = {}
		for key: int in [1, 2, 3, 4]:
			if list.piece_for(key) != null:
				before[key] = [list.piece_for(key).position, list.piece_for(key).modulate.a]
		_model.set_value(&"items", order.map(func(key: int) -> Dictionary: return {"id": key, "name": names[key]}))
		await _a_frame_passes()
		for key: int in before:
			if list.piece_for(key) != null:
				var piece: Control = list.piece_for(key)
				_verdict.check(piece.position == before[key][0] and piece.modulate.a == before[key][1], "%s, changed mid-way: %s is drawn exactly where and as it was the moment before: %s %s" % [order, names[key], piece.position, before[key][0]])
		crossed.append_array(await _watched(list, 0.13))
	crossed.append_array(await _watched(list, 1.0))
	var rests: Array = [1, 2, 3].map(func(key: int) -> float: return list.piece_for(key).position.y)
	_verdict.check(rests[0] < rests[1] and rests[1] < rests[2] and list.get_children(true).filter(func(child: Node) -> bool: return child is Control).size() == 3 and _made.ui.motion.get_running() == 0, "it all ends in order, whole, with nothing going and nothing running: %s" % [rests])
	_verdict.check([1, 2, 3].all(func(key: int) -> bool: return list.piece_for(key).modulate == Color.WHITE and list.piece_for(key).scale == Vector2.ONE), "every piece fully there")
	_verdict.check(crossed.is_empty(), "and at no step was anything drawn over anything else: %s" % [crossed.slice(0, 3)])
	_done()


## A when over two screens of ONE name - a layout swapped for another of
## the same places: the going one is never taken out of the tree, so
## nothing beneath it enters or exits again; its place gives up its name
## as it sets off, so the arriving one is the place of that name, with no
## second of a name refused.
func _a_going_thing_never_leaves_the_tree_and_a_place_in_it_gives_up_its_name_at_once() -> void:
	_standing()
	var ui := _made.ui
	_model.set_value(&"flag", true)
	var counts := {"first": [0, 0], "second": [0, 0]}
	var side := func(which: String) -> Desc: return ui.screen(&"page", [ui.text(which)], null, {on_fill = func(_token: Variant) -> void: counts[which][0] += 1, on_empty = func() -> void: counts[which][1] += 1}).named(StringName(which))
	ui.start(ui.app(&"app", [ui.when(_model.of(&"flag"), side.call("first"), side.call("second")).named(&"when")]))
	await _a_frame_passes()
	_made.commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": &"page"})
	await _a_frame_passes()
	var first: Node = ui.node_named(&"first")
	_verdict.check(_made.driver.index.place_named(&"page") == first and counts["first"] == [1, 0], "the first layout's place is the place of the name, and the reader is in it: %s" % [counts])
	_model.set_value(&"flag", false)
	await _a_frame_passes()
	var second: Node = ui.node_named(&"second")
	_verdict.check(is_instance_valid(first) and first.is_inside_tree() and _made.driver.index.place_named(&"page") == second and _made.driver.index.refused_names().is_empty(), "swapped, the going layout is still in the tree and the arriving one is the place of the name; none was refused: %s" % [_made.driver.index.refused_names()])
	_verdict.check(counts["first"] == [1, 1], "the going place was emptied once as it set off, and never filled again: %s" % [counts])
	await _step(0.5)
	_verdict.check(not is_instance_valid(first) and counts["first"] == [1, 1] and _made.driver.index.place_named(&"page") == second, "freed at last, it is emptied no second time and the name is still the arriving one's: %s" % [counts])
	_done()


## A when turned back before its entrance has finished, and an item taken
## away while it is still arriving: whatever was writing the opacity is
## taken over from the value it had reached, so it only ever goes down from
## there, and no property of a node is ever written by two runs.
func _turned_round_mid_way_one_run_writes_each_property_and_nothing_flickers() -> void:
	_standing()
	var ui := _made.ui
	_model.set_value(&"flag", false)
	ui.start(ui.app(&"app", [ui.when(_model.of(&"flag"), ui.text("shown").named(&"shown")).transition(Transition.SCALE).named(&"when")]))
	await _a_frame_passes()
	_model.set_value(&"flag", true)
	await _a_frame_passes()
	await _step(0.06)
	var shown: Control = ui.node_named(&"shown")
	var reached: float = shown.modulate.a
	var grown: Vector2 = shown.scale
	_model.set_value(&"flag", false)
	await _a_frame_passes()
	_verdict.check(reached > 0.0 and reached < 1.0 and shown.modulate.a == reached and shown.scale == grown and ui.motion.get_running() == 2, "turned back a third of the way in, it is exactly as it was, and one run writes its opacity and one its scale - the entrance's are stopped: %d running" % ui.motion.get_running())
	var seen: Array = [reached]
	# the way out, a hundredth of a second at a time: the opacity only ever falls
	for tick: int in 9:
		await _step(0.01)
		if is_instance_valid(shown):
			seen.append(shown.modulate.a)
	var falling: bool = range(1, seen.size()).all(func(at: int) -> bool: return seen[at] <= seen[at - 1])
	_verdict.check(falling and seen.back() < reached and not is_instance_valid(shown) or seen.back() == 0.0, "from there its opacity only ever falls - nothing writes it back up - to nothing: %s" % [seen])
	await _step(0.5)
	_verdict.check(not is_instance_valid(shown) and ui.motion.get_running() == 0, "and it is freed, nothing left running")
	_done()
	_standing()
	var list := await _a_list(Transition.FADE)
	_model.set_value(&"items", [{"id": 1, "name": "ann"}, {"id": 2, "name": "bo"}, {"id": 3, "name": "cy"}, {"id": 4, "name": "dee"}])
	await _a_frame_passes()
	await _step(0.06)
	var dee: Control = list.piece_for(4)
	var arrived: float = dee.modulate.a
	_model.set_value(&"items", [{"id": 1, "name": "ann"}, {"id": 2, "name": "bo"}, {"id": 3, "name": "cy"}])
	await _a_frame_passes()
	await _step(0.01)
	_verdict.check(arrived > 0.0 and arrived < 1.0 and is_instance_valid(dee) and dee.modulate.a < arrived and _made.ui.motion.get_running() == 1, "an item taken away while still arriving goes from the opacity it had, by the one run left writing it: %s then %s" % [arrived, dee.modulate.a])
	await _step(0.5)
	_verdict.check(not is_instance_valid(dee), "and is freed")
	_done()
	_standing()
	_model.set_value(&"flag", false)
	_made.ui.start(_made.ui.app(&"app", [_made.ui.when(_model.of(&"flag"), _made.ui.surface(Themes.SURFACE, [_made.ui.text("slid")]).named(&"slid")).transition(Transition.FROM_LEFT)]))
	await _a_frame_passes()
	_model.set_value(&"flag", true)
	await _a_frame_passes()
	await _step(0.06)
	var slid: Control = _made.ui.node_named(&"slid")
	var across: float = slid.position.x
	_model.set_value(&"flag", false)
	await _a_frame_passes()
	await _step(0.01)
	_verdict.check(across < 0.0 and slid.position.x < across and slid.position.x > across - slid.size.x * 0.5, "a slide turned back mid-way goes back out from where it had got to - it does not start again from its place: %s then %s" % [across, slid.position.x])
	await _step(0.5)
	_done()


## A piece sliding in while the layout moves under it - a row above grown
## taller mid-slide: the slide ends exactly where the layout has it now.
## A piece going is drawn where it stood, and the layout closes up without it.
func _a_going_piece_stays_where_it_stood_and_the_layout_closes_up_without_it() -> void:
	_standing()
	var list := await _a_list(Transition.FADE)
	var ann: Control = list.piece_for(1)
	var top: Vector2 = ann.position
	var tall: float = list.get_combined_minimum_size().y
	_model.set_value(&"items", [{"id": 2, "name": "bo"}, {"id": 3, "name": "cy"}])
	await _a_frame_passes()
	await _step(0.03)
	_verdict.check(is_instance_valid(ann) and ann.position == top and ann.size.y > 0.0, "the first item gone, its piece fades where it stood: neither placed again nor moved: %s" % ann.position)
	_verdict.check(list.get_combined_minimum_size().y < tall, "and the list needs only the room of what is left: %s then %s" % [tall, list.get_combined_minimum_size().y])
	await _step(1.0)
	_verdict.check(not is_instance_valid(ann) and list.piece_for(2).position == top, "it freed, what is left has closed up into its place")
	_done()


## Not the line alone: whatever arranges or measures its children leaves a
## going one where it stood and gives its room to the rest.
func _a_grid_a_stack_and_an_inset_close_up_without_a_going_thing_too() -> void:
	_standing()
	var ui := _made.ui
	var tall := func(named: StringName, words: String) -> Desc: return ui.column([ui.text(words), ui.text(words), ui.text(words)]).named(named)
	ui.start(ui.app(&"app", [ui.column([
		ui.grid([ui.text("one").named(&"cell_one"), ui.text("two").named(&"cell_two")], [0.5, 0.5]).named(&"grid"),
		ui.stack([tall.call(&"tall", "deep"), ui.text("short").named(&"short")]).named(&"stack"),
		ui.surface(Themes.SURFACE, [tall.call(&"held", "held"), ui.text("little").named(&"little")]).named(&"inset"),
	])]))
	await _a_frame_passes()
	var first: Control = ui.node_named(&"cell_one")
	var second: Control = ui.node_named(&"cell_two")
	var where: Vector2 = first.position
	var stack: Control = ui.node_named(&"stack")
	var inset: Control = ui.node_named(&"inset")
	var stacked: float = stack.get_combined_minimum_size().y
	var inside: float = inset.get_combined_minimum_size().y
	for going: StringName in [&"cell_one", &"tall", &"held"]:
		Going.mark(ui.node_named(going))
	(ui.node_named(&"grid") as Container).queue_sort()
	inset.queue_sort()
	await _a_frame_passes()
	_verdict.check(second.position == where and first.position == where, "in a grid, the going cell is left where it stood and the next takes its cell: %s" % second.position)
	_verdict.check(stack.get_combined_minimum_size().y < stacked, "a stack needs only the room of what is left: %s then %s" % [stacked, stack.get_combined_minimum_size().y])
	_verdict.check(inset.get_combined_minimum_size().y < inside, "and so does a surface's inset: %s then %s" % [inside, inset.get_combined_minimum_size().y])
	_done()


func _a_slide_ends_where_the_layout_put_it_whatever_moved_meanwhile() -> void:
	_standing()
	var list := await _a_list(Transition.FROM_LEFT)
	_model.set_value(&"items", [{"id": 1, "name": "ann"}, {"id": 2, "name": "bo"}, {"id": 3, "name": "cy"}, {"id": 4, "name": "dee"}])
	await _a_frame_passes()
	await _step(0.06)
	var dee: Control = list.piece_for(4)
	var before: Vector2 = dee.position
	_model.set_value(&"items", [{"id": 1, "name": "ann\nof two lines"}, {"id": 2, "name": "bo"}, {"id": 3, "name": "cy"}, {"id": 4, "name": "dee"}])
	await _a_frame_passes()
	_verdict.check(before.x < 0.0 and dee.position.x == before.x and dee.position.y > before.y, "mid-slide the row above grew: the sliding piece is as far across as it was, and down with the layout at once: %s then %s" % [before, dee.position])
	await _step(0.5)
	var ended: Vector2 = dee.position
	list.queue_sort()
	await _a_frame_passes()
	_verdict.check(ended.x == 0.0 and ended == dee.position and ended.y > before.y, "the slide over, it is exactly where the layout puts it - arranging again moves nothing: %s" % [ended])
	_done()


## The tokens are read from the node that moves: under a look of its own
## that is ten times slower, a thing is a tenth of the way when one under
## the window's look has arrived.
func _a_part_of_the_screen_under_its_own_look_moves_by_its_own_look() -> void:
	_standing()
	var ui := _made.ui
	_model.set_value(&"flag", false)
	ui.start(ui.app(&"app", [ui.column([ui.when(_model.of(&"flag"), ui.text("plain").named(&"plain")), ui.surface(Themes.SURFACE, [ui.when(_model.of(&"flag"), ui.text("slow").named(&"slow"))]).named(&"own")])]))
	await _a_frame_passes()
	var slower := Theme.new()
	MotionTokens.write(slower, {&"quick": 900, &"normal": 1800, &"slow": 3600}, {Motion.ENTER: [Tween.TRANS_LINEAR, Tween.EASE_IN, &"normal"]})
	Transition.defaults(slower, {&"when": Transition.FADE})
	(ui.node_named(&"own") as Control).theme = slower
	_model.set_value(&"flag", true)
	await _a_frame_passes()
	await _step(0.18)
	_verdict.check((ui.node_named(&"plain") as Control).modulate.a == 1.0 and is_equal_approx((ui.node_named(&"slow") as Control).modulate.a, 0.1), "the window's look has its thing there; the part under its own look is a tenth of the way: %s" % (ui.node_named(&"slow") as Control).modulate.a)
	_done()


func _pieces_entering_together_enter_one_after_another() -> void:
	_standing()
	var list := await _a_list(Transition.FADE)
	_verdict.check(list.piece_for(1).modulate == Color.WHITE and _made.ui.motion.get_running() == 0, "what is there as the list is built is simply there")
	_model.set_value(&"items", [{"id": 1, "name": "ann"}, {"id": 2, "name": "bo"}, {"id": 3, "name": "cy"}, {"id": 4, "name": "dee"}, {"id": 5, "name": "eve"}])
	await _a_frame_passes()
	var dee: Control = list.piece_for(4)
	var eve: Control = list.piece_for(5)
	await _step(0.04)
	_verdict.check(dee.modulate.a > 0.0 and eve.modulate.a == 0.0, "the look's stagger on, the first of two arriving has set off and the second has not: %s %s" % [dee.modulate.a, eve.modulate.a])
	await _step(0.14)
	_verdict.check(dee.modulate.a == 1.0 and eve.modulate.a > 0.0 and eve.modulate.a < 1.0, "the first there, the second is on its way")
	await _step(0.5)
	_verdict.check(eve.modulate == Color.WHITE, "and arrives")
	_done()


func _reduced_nothing_moves_and_over_budget_nothing_new_does() -> void:
	_standing()
	var list := await _a_list(Transition.FROM_LEFT)
	_made.ui.motion.told(Motion.REDUCES, {"on": true})
	var ann: Control = list.piece_for(1)
	var top: Vector2 = ann.position
	var bottom: Vector2 = list.piece_for(3).position
	_model.set_value(&"items", [{"id": 3, "name": "cy"}, {"id": 2, "name": "bo"}, {"id": 1, "name": "ann"}, {"id": 4, "name": "dee"}])
	await _a_frame_passes()
	var dee: Control = list.piece_for(4)
	_verdict.check(ann.position == bottom and dee.position.x == 0.0 and dee.scale == Vector2.ONE, "reduced, a sorted piece is in its new place at once and one arriving does not slide: %s" % ann.position)
	_verdict.check(dee.modulate.a == 0.0 and _made.ui.motion.get_running() == 1, "what is left of arriving is a fade")
	await _step(0.09)
	_verdict.check(dee.modulate == Color.WHITE, "a short one")
	_made.ui.motion.told(Motion.REDUCES, {"on": false})
	var budget := Spent.new(_made.chimes, 16.0, 0.5, 3)
	_made.ui.motion.budget = budget
	_model.set_value(&"items", [{"id": 1, "name": "ann"}, {"id": 2, "name": "bo"}, {"id": 3, "name": "cy"}])
	await _a_frame_passes()
	_verdict.check(ann.position == top and not is_instance_valid(dee) and _made.ui.motion.get_running() == 0, "over budget, new motion is at its end at once: sorted pieces in place, the one going gone: %s" % ann.position)
	_made.ui.motion.budget = null
	budget.free()
	_done()


func _many_shown_in_one_frame_are_at_rest_at_once_and_one_alone_still_moves() -> void:
	_standing()
	var ui := _made.ui
	_model.set_value(&"flag", false)
	_model.set_value(&"words", false)
	# fifty whens on one value, each swapping "off" for its own words, and one more on a value of its own
	var many: Array = range(50).map(func(at: int) -> Desc: return ui.when(_model.of(&"flag"), ui.text("on %d" % at).named(StringName("on %d" % at)), ui.text("off")).transition(Transition.FADE))
	ui.start(ui.app(&"app", [ui.column(many + [ui.when(_model.of(&"words"), ui.text("alone").named(&"alone"), ui.text("off")).transition(Transition.FADE)])]))
	await _a_frame_passes()
	_model.set_value(&"flag", true)
	await _a_frame_passes()
	var shown: Array = range(50).map(func(at: int) -> Control: return ui.node_named(StringName("on %d" % at)))
	_verdict.check(shown.all(func(one: Control) -> bool: return one.modulate == Color.WHITE) and _texts(root).count("off") == 1 and ui.motion.get_running() == 0, "fifty shown in one frame are all at rest at once, the fifty going gone, nothing running: %d running, %d off" % [ui.motion.get_running(), _texts(root).count("off")])
	_model.set_value(&"words", true)
	await _a_frame_passes()
	var alone: Control = ui.node_named(&"alone")
	_verdict.check(alone.modulate.a == 0.0 and ui.motion.get_running() > 0, "one shown alone still begins unseen and runs its entrance: %s" % alone.modulate.a)
	await _step(0.5)
	_verdict.check(alone.modulate == Color.WHITE and ui.motion.get_running() == 0, "and arrives")
	_done()
