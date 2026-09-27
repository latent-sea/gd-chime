extends SceneTree

## What must be true of picking a thing up and dropping it somewhere else.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_drag_and_drop.gd
##
## A mouse drop on a target the door would take runs that target's action,
## once, with what was carried, in the target's region; a target the door
## refuses says why and takes nothing; a target's look follows the door
## while something is over it and is normal again after; the pad lifts,
## walks across drop targets and nothing else, shows each one's answer,
## drops on accept and puts it back on cancel with the focus home and
## nothing dispatched; the end of a mouse drag with nothing dropped puts it
## back too; a carry near a scroll's edge drags the scroll, and nothing else
## does; and after a drop nothing is carried, nothing is left running and
## nothing is drawn over anything else; and a card dropped into another lane
## still moves as it lands - one change is never many at once.
##
## THE MOUSE PATH IS DRIVEN THROUGH THE ENGINE'S OWN VIRTUAL METHODS -
## _get_drag_data, _can_drop_data, _drop_data - called with the data the
## engine would hand them, because the headless window routes no mouse press
## by position reliably and so will not begin a real drag. What that leaves
## untested here is the engine's own routing, which is the engine's; it was
## run once by hand in a real window (--resolution 1280x800, events
## synthesised with Input.parse_input_event) and what was seen is reported
## with the work. The end of a drag is sent the way the engine sends it, as
## NOTIFICATION_DRAG_END, which is what the engine turns Escape into.
##
## The pad path is driven with real keys pushed at the root, which the
## headless window does route to whatever holds the focus.

const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Carried := preload("res://addons/gd_chime/carried.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Draggable := preload("res://addons/gd_chime/components/primitives/draggable.gd")
const DropTarget := preload("res://addons/gd_chime/components/primitives/drop_target.gd")
const Fixture := preload("res://tests/fixture.gd")
const Lane := preload("res://addons/gd_chime/lane.gd")
const Scroll := preload("res://addons/gd_chime/components/primitives/scroll.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Verdict := preload("res://tests/verdict.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")

## The actions the board declares: one the model takes, one it refuses, and
## one that is an ordinary press, so the focus walk has something to step
## past. They are declared on the place by hand rather than in the register,
## because the board is filled after the app has started and the startup
## check asks that every action in the register is performed somewhere.
const DECLARED: Array[StringName] = [&"puts_here", &"refuses_it", &"presses"]
const WHY := "the crate is full"

var _verdict := Verdict.new()
var _made: Fixture
var _carried: Carried
var _model: Fixture.Model


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(400, 400)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_a_mouse_drop_on_a_target_that_takes_it_runs_its_action_once_with_what_was_carried)
	await _verdict.states(_a_target_the_door_refuses_says_why_and_takes_nothing)
	await _verdict.states(_the_look_of_a_target_follows_the_door_while_something_is_carried_and_is_normal_after)
	await _verdict.states(_the_pad_lifts_walks_across_targets_alone_and_drops)
	await _verdict.states(_the_pad_walks_between_targets_side_by_side_over_a_wide_control)
	await _verdict.states(_cancel_puts_it_back_with_the_focus_home_and_nothing_dispatched)
	await _verdict.states(_the_end_of_a_mouse_drag_with_nothing_dropped_puts_it_back)
	await _verdict.states(_a_carry_near_an_edge_drags_the_scroll_and_nothing_else_does)
	await _verdict.states(_after_a_drop_nothing_is_carried_nothing_runs_and_nothing_is_drawn_over_anything_else)
	await _verdict.states(_a_drag_over_a_list_lands_between_its_pieces_and_a_drop_on_a_piece_is_the_lists_one_command)
	await _verdict.states(_lifted_from_a_list_it_would_land_where_it_stood_and_the_pointer_leaves_a_hole)
	await _verdict.states(_the_keys_step_a_carry_along_its_list_across_to_the_next_and_drop_it_there)
	await _verdict.states(_a_click_on_a_draggable_presses_it_and_a_drag_does_not)
	await _verdict.states(_a_lane_shows_the_carried_thing_where_it_would_land_and_nothing_else_moves)
	await _verdict.states(_a_lane_rings_only_when_what_it_shows_changed)
	await _verdict.states(_a_card_carried_by_keys_travels_between_lanes_and_lands_without_moving_again)
	await _verdict.states(_a_card_dropped_into_another_lane_moves_as_it_lands)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## A fixture, the one carry beside the app, a model in the app's region, and
## the two primitives registered as a game registers its own.
func _standing() -> void:
	_made = Fixture.new(root)
	_carried = _made.ui.carried
	_model = Fixture.Model.new(_made.chimes, &"app")


func _done() -> void:
	_model.free()
	_made.done()


## A key pushed at the root, down then up, as a reader presses it.
func _key(code: Key) -> void:
	# the key going down, then up
	for down: bool in [true, false]:
		var press := InputEventKey.new()
		press.keycode = code
		press.physical_keycode = code
		press.pressed = down
		root.push_input(press)


func _drag(payload: Dictionary, id: StringName) -> Desc:
	return _made.ui.draggable(payload, [_made.ui.text("crate")]).named(id)


func _target(action: StringName, id: StringName) -> Desc:
	return _made.ui.drop_target(action, [_made.ui.text(str(id)), _made.ui.reason().named(StringName("why %s" % id))]).named(id)


## A board: an app holding a column, its actions declared by hand - the
## builder declares a pressable's, and this stands in for the one line that
## declares a drop target's - and then a crate, an ordinary press and two
## targets built into it, as a place filling builds into itself.
func _a_board() -> Dictionary:
	var ui := _made.ui
	ui.start(ui.app(&"app", [ui.column([]).named(&"board")]))
	await _a_frame_passes()
	var place: Node = _made.driver.index.place_named(&"app")
	# every action the board performs, declared on the place and answered by the model
	for action: StringName in DECLARED:
		place.performs[action] = &""
		_made.commands.register(&"app", action, _model)
	_model.refuse(&"refuses_it", Phrase.of(WHY))
	var board: Control = ui.node_named(&"board")
	for described: Desc in [_drag({"id": 1}, &"crate"), ui.pressable(&"presses", {}, [ui.text("press")]).named(&"plain"), _target(&"puts_here", &"shelf"), _target(&"refuses_it", &"full")]:
		ui.build(described, board, place)
	await _a_frame_passes()
	return {"board": board, "crate": ui.node_named(&"crate"), "plain": ui.node_named(&"plain"), "shelf": ui.node_named(&"shelf"), "full": ui.node_named(&"full")}


## What the last command that ran was, as a region, an action and a payload.
func _last() -> Array:
	var last := _made.commands.get_last()
	return [last.get("region"), last.get("action"), last.get("payload")]


func _a_mouse_drop_on_a_target_that_takes_it_runs_its_action_once_with_what_was_carried() -> void:
	_standing()
	var made := await _a_board()
	var crate: Control = made["crate"]
	var shelf: Control = made["shelf"]
	var place: Node = _made.driver.index.place_named(&"app")
	# the same crate drawn a second time, and another crate
	for described: Desc in [_drag({"id": 1}, &"again"), _drag({"id": 2}, &"other")]:
		_made.ui.build(described, made["board"], place)
	await _a_frame_passes()
	var other_drawn: int = _made.ui.node_named(&"other").refresh_count
	var data: Variant = crate._get_drag_data(Vector2.ZERO)
	await _a_frame_passes()
	_verdict.check(_made.ui.node_named(&"other").refresh_count == other_drawn, "a draggable that is not the one lifted is not drawn again for the lift: every draggable hears every carry")
	_verdict.check(_carried.is_carrying() and _carried.get_payload() == {"id": 1} and _carried.is_lifted({"id": 1}) and crate.get_state() == &"lifted", "the drag begun, the crate is what is carried and is drawn lifted: %s" % [_carried.get_payload()])
	_verdict.check(_made.ui.node_named(&"again").get_state() == &"lifted" and _made.ui.node_named(&"other").get_state() != &"lifted", "a thing carried is its payload: the same crate drawn elsewhere is lifted with it, and another crate is not")
	_verdict.check(shelf._can_drop_data(Vector2.ZERO, data) == true, "the shelf tells the engine it would take it")
	shelf._drop_data(Vector2.ZERO, data)
	await _a_frame_passes()
	_verdict.check(_model.told_actions == [&"puts_here"], "dropped, the shelf's action ran once: %s" % [_model.told_actions])
	_verdict.check(_last() == [&"app", &"puts_here", {"id": 1}], "in the shelf's own region, carrying what was dragged: %s" % [_last()])
	_verdict.check(not _carried.is_carrying() and crate.get_state() != &"lifted", "and nothing is carried any more, the crate set down")
	_done()


func _a_target_the_door_refuses_says_why_and_takes_nothing() -> void:
	_standing()
	var made := await _a_board()
	var crate: Control = made["crate"]
	var full: Control = made["full"]
	var data: Variant = crate._get_drag_data(Vector2.ZERO)
	var before := _last()
	full.hovered(true)
	await _a_frame_passes()
	var why: Text = _made.ui.node_named(&"why full")
	_verdict.check(full._can_drop_data(Vector2.ZERO, data) == false, "the full shelf tells the engine it would not take it")
	_verdict.check(full.get_state() == &"refusing" and why.get_text() == WHY, "it is drawn refusing, and says why in words: %s, %s" % [full.get_state(), why.get_text()])
	full._drop_data(Vector2.ZERO, data)
	full.pressed()
	await _a_frame_passes()
	_verdict.check(_model.told_actions.is_empty() and _last() == before, "dropped on all the same, and pressed, it takes nothing: %s, %s" % [_model.told_actions, _last()])
	_verdict.check(_carried.is_carrying(), "and what was carried is still carried")
	_done()


func _the_look_of_a_target_follows_the_door_while_something_is_carried_and_is_normal_after() -> void:
	_standing()
	var made := await _a_board()
	var crate: Control = made["crate"]
	var shelf: Control = made["shelf"]
	var why: Text = _made.ui.node_named(&"why shelf")
	shelf.hovered(true)
	await _a_frame_passes()
	_verdict.check(shelf.get_state() == &"hover" and why.get_text() == "", "with nothing carried, a target under the pointer is an ordinary face and says nothing: %s" % shelf.get_state())
	var drawn: int = shelf.refresh_count
	crate._get_drag_data(Vector2.ZERO)
	await _a_frame_passes()
	_verdict.check(shelf.refresh_count > drawn and shelf.get_state() == &"accepting" and why.get_text() == "", "something carried over it, it is drawn again - told, not looking - and draws accepting with nothing to say: %s" % shelf.get_state())
	_model.refuse(&"puts_here", Phrase.of(WHY))
	_model.set_value(&"any", true)
	await _a_frame_passes()
	_verdict.check(shelf.get_state() == &"refusing" and why.get_text() == WHY, "the door's answer changing under it, it follows without the carry moving: %s, %s" % [shelf.get_state(), why.get_text()])
	_model.refuse(&"puts_here", null)
	_carried.put_back()
	await _a_frame_passes()
	_verdict.check(shelf.get_state() == &"hover" and why.get_text() == "", "the carry over, it is an ordinary face again: %s" % shelf.get_state())
	_done()


func _the_pad_lifts_walks_across_targets_alone_and_drops() -> void:
	_standing()
	var made := await _a_board()
	var crate: Control = made["crate"]
	var plain: Control = made["plain"]
	var shelf: Control = made["shelf"]
	var full: Control = made["full"]
	crate.grab_focus()
	await _a_frame_passes()
	_key(KEY_ENTER)
	await _a_frame_passes()
	_verdict.check(_carried.is_lifted({"id": 1}) and _carried.is_by_keys() and crate.get_state() == &"lifted" and crate.has_focus(), "accept on the crate lifts it, and the focus is still on it")
	_key(KEY_DOWN)
	await _a_frame_passes()
	_verdict.check(shelf.has_focus() and not plain.has_focus() and shelf.get_state() == &"accepting", "down walks past the ordinary press to the first target, which shows it would take it: %s" % shelf.get_state())
	_key(KEY_DOWN)
	await _a_frame_passes()
	_verdict.check(full.has_focus() and full.get_state() == &"refusing" and (_made.ui.node_named(&"why full") as Text).get_text() == WHY, "down again reaches the full one, which shows it would not and why: %s" % full.get_state())
	_key(KEY_UP)
	await _a_frame_passes()
	_verdict.check(shelf.has_focus() and not plain.has_focus(), "up comes back to the shelf, past the ordinary press again")
	_key(KEY_ENTER)
	await _a_frame_passes()
	_verdict.check(_model.told_actions == [&"puts_here"] and _last() == [&"app", &"puts_here", {"id": 1}], "accept there drops it: the shelf's action, once, with what was carried: %s" % [_last()])
	_verdict.check(not _carried.is_carrying() and crate.get_state() != &"lifted", "and nothing is carried any more")
	_done()


## Two targets side by side, a wide ordinary press under both, and the
## engine's own neighbour to the side of the first that press - as a layout
## makes it where the press is nearer by an edge; it is set so here, since
## the engine's scoring is its own - with nothing beyond it: the carry still
## reaches the second.
func _the_pad_walks_between_targets_side_by_side_over_a_wide_control() -> void:
	_standing()
	var ui := _made.ui
	ui.start(ui.app(&"app", [ui.column([]).named(&"board")]))
	await _a_frame_passes()
	var place: Node = _made.driver.index.place_named(&"app")
	# every action the board performs, declared on the place and answered by the model
	for action: StringName in DECLARED:
		place.performs[action] = &""
		_made.commands.register(&"app", action, _model)
	var board: Control = ui.node_named(&"board")
	_model.refuse(&"refuses_it", Phrase.of(WHY))
	# the two targets side by side, the press under the whole of them
	for described: Desc in [_drag({"id": 1}, &"crate"), ui.row([_target(&"puts_here", &"shelf").grow(), _target(&"refuses_it", &"full").grow()]), ui.pressable(&"presses", {}, [ui.text("press")]).named(&"plain")]:
		ui.build(described, board, place)
	await _a_frame_passes()
	var shelf: Control = ui.node_named(&"shelf")
	var full: Control = ui.node_named(&"full")
	shelf.focus_neighbor_right = shelf.get_path_to(ui.node_named(&"plain"))
	(ui.node_named(&"crate") as Control).grab_focus()
	await _a_frame_passes()
	_key(KEY_ENTER)
	await _a_frame_passes()
	_key(KEY_DOWN)
	await _a_frame_passes()
	_verdict.check(shelf.has_focus(), "down from the crate reaches the first target")
	_verdict.check(shelf.find_valid_focus_neighbor(SIDE_RIGHT) == ui.node_named(&"plain"), "the engine's own neighbour to its side is the wide press under both, not the other target: %s" % [shelf.find_valid_focus_neighbor(SIDE_RIGHT)])
	_key(KEY_RIGHT)
	await _a_frame_passes()
	_verdict.check(full.has_focus() and full.get_state() == &"refusing" and _carried.is_carrying(), "right reaches the target beside it all the same, still carrying: %s" % full.get_state())
	_key(KEY_LEFT)
	await _a_frame_passes()
	_verdict.check(shelf.has_focus() and _carried.is_carrying(), "and left comes back to the first")
	_done()


func _cancel_puts_it_back_with_the_focus_home_and_nothing_dispatched() -> void:
	_standing()
	var made := await _a_board()
	var crate: Control = made["crate"]
	var shelf: Control = made["shelf"]
	crate.grab_focus()
	var before := _last()
	await _a_frame_passes()
	_key(KEY_ENTER)
	await _a_frame_passes()
	_key(KEY_DOWN)
	await _a_frame_passes()
	_verdict.check(shelf.has_focus() and _carried.is_carrying(), "lifted and carried as far as the shelf")
	_key(KEY_ESCAPE)
	await _a_frame_passes()
	_verdict.check(not _carried.is_carrying() and _carried.get_put_back(), "cancel there puts it back rather than setting it down")
	_verdict.check(crate.has_focus() and crate.get_state() != &"lifted" and shelf.get_state() != &"accepting", "the focus is home on the crate, which is no longer lifted, and the shelf is an ordinary face")
	_verdict.check(_model.told_actions.is_empty() and _last() == before, "and nothing was dispatched at all: %s, %s" % [_model.told_actions, _last()])
	_done()


func _the_end_of_a_mouse_drag_with_nothing_dropped_puts_it_back() -> void:
	_standing()
	var made := await _a_board()
	var crate: Control = made["crate"]
	crate._get_drag_data(Vector2.ZERO)
	await _a_frame_passes()
	_verdict.check(_carried.is_carrying(), "the drag begun, something is carried")
	crate.notification(Control.NOTIFICATION_DRAG_END)
	await _a_frame_passes()
	_verdict.check(not _carried.is_carrying() and _carried.get_put_back() and crate.get_state() != &"lifted", "the engine's end of the drag - a release over nothing, or Escape - puts it back")
	_verdict.check(_model.told_actions.is_empty(), "and nothing was dispatched: %s" % [_model.told_actions])
	crate._get_drag_data(Vector2.ZERO)
	crate.free()
	await _a_frame_passes()
	_carried.notification(Node.NOTIFICATION_DRAG_END)
	await _a_frame_passes()
	_verdict.check(not _carried.is_carrying() and _carried.get_put_back() and _carried.get_returned() == {"id": 1}, "and a drag whose piece has gone since - built again elsewhere - is put back by the engine's end of it reaching the carry itself")
	_done()


func _a_carry_near_an_edge_drags_the_scroll_and_nothing_else_does() -> void:
	_standing()
	var ui := _made.ui
	var rows: Array = []
	# enough rows to be taller than the window, so there is somewhere to scroll to
	for row: int in 30:
		rows.append(ui.text("row %d" % row))
	ui.start(ui.app(&"app", [ui.scroll(ui.column(rows)).named(&"window")]))
	await _a_frame_passes()
	var window: Scroll = ui.node_named(&"window")
	var foot := Vector2(window.size.x / 2.0, window.size.y - 4.0)
	window.toward_the_edge(foot, 0.1)
	_verdict.check(window.size.y > 0.0 and window.scroll_vertical == 0, "with nothing carried, the pointer at the foot moves it nowhere: %s" % window.scroll_vertical)
	window.notification(Control.NOTIFICATION_DRAG_BEGIN)
	window.toward_the_edge(foot, 0.1)
	_verdict.check(window.scroll_vertical == roundi(Scroll.SPEED * 0.1), "a carry on, the same point drags it toward that edge at the look's speed: %s" % window.scroll_vertical)
	var reached := window.scroll_vertical
	window.toward_the_edge(Vector2(window.size.x / 2.0, window.size.y / 2.0), 0.1)
	_verdict.check(window.scroll_vertical == reached, "a point in the middle, outside the band, moves it nowhere: %s" % window.scroll_vertical)
	window.toward_the_edge(Vector2(window.size.x / 2.0, 2.0), 0.1)
	_verdict.check(window.scroll_vertical < reached, "a point at the head drags it back the other way: %s" % window.scroll_vertical)
	reached = window.scroll_vertical
	window.notification(Control.NOTIFICATION_DRAG_END)
	window.toward_the_edge(foot, 0.1)
	_verdict.check(window.scroll_vertical == reached, "and the carry over, the same point moves it nowhere again: %s" % window.scroll_vertical)
	_done()


## Every pair of things drawn on the board that are drawn over each other.
func _overlapping(board: Control) -> Array:
	var seen: Array = board.get_children(true).filter(func(child: Node) -> bool: return child is Control and (child as Control).visible)
	var pairs: Array = []
	# every pair of parts on the board, kept when their rects meet
	for a: int in seen.size():
		for b: int in range(a + 1, seen.size()):
			if Rect2(seen[a].position, seen[a].size).intersects(Rect2(seen[b].position, seen[b].size)):
				pairs.append([seen[a].name, seen[b].name])
	return pairs


func _after_a_drop_nothing_is_carried_nothing_runs_and_nothing_is_drawn_over_anything_else() -> void:
	_standing()
	var made := await _a_board()
	var crate: Control = made["crate"]
	var shelf: Control = made["shelf"]
	var data: Variant = crate._get_drag_data(Vector2.ZERO)
	await _a_frame_passes()
	shelf._drop_data(Vector2.ZERO, data)
	crate.notification(Control.NOTIFICATION_DRAG_END)
	await _a_frame_passes()
	_verdict.check(not _carried.is_carrying() and _carried.get_payload().is_empty() and _carried.get_over().is_empty(), "the drop done, nothing is carried and nothing is left held: %s" % [_carried.get_payload()])
	_verdict.check(_made.ui.motion.get_running() == 0, "nothing is left running on the clock: %d" % _made.ui.motion.get_running())
	_verdict.check(_overlapping(made["board"]).is_empty(), "and nothing on the board is drawn over anything else: %s" % [_overlapping(made["board"])])
	_done()


## --- lists ---

## Two lists a model holds, recording every command it is told and whether
## anything was still carried as it was told it.
class Lists extends Fixture.Model:
	var carried: Carried
	var told_payloads: Array = []
	var carrying_as_told: Array = []

	func told(action: StringName, payload: Dictionary) -> Phrase:
		told_actions.append(action)
		told_payloads.append(payload)
		carrying_as_told.append(carried.is_carrying())
		return null


## Two list targets side by side, a: cards 1, 2 and 3, b: cards 11 and 12,
## each card a draggable opening itself when clicked; the moves and the
## opening answered by the lists' model.
func _lists() -> Lists:
	_made = Fixture.new(root, {&"moves_it": "move it", &"opens_it": "open it"})
	_carried = _made.ui.carried
	var lists := Lists.new(_made.chimes, &"app")
	lists.carried = _carried
	_model = lists
	lists.set_value(&"items", [{"id": 1}, {"id": 2}, {"id": 3}])
	lists.set_value(&"words", [{"id": 11}, {"id": 12}])
	var ui := _made.ui
	var card := func(item: Bound) -> Desc: return ui.draggable(item, [ui.text(item.map(func(one: Variant) -> String: return "" if one == null else "card %d" % one["id"]))], &"Pressable", &"opens_it")
	var list := func(into: String, named: StringName) -> Desc: return ui.drop_target(&"moves_it", [ui.each(lists.of(named), card, func(one: Dictionary) -> int: return one["id"]).pieces_named(&"card ")], &"Pressable", into).named(StringName(into))
	ui.start(ui.app(&"app", [ui.row([list.call("a", &"items").grow(), list.call("b", &"words").grow()])]))
	await _a_frame_passes()
	# both commands of the lists, answered by their model
	for action: StringName in [&"moves_it", &"opens_it"]:
		_made.commands.register(&"app", action, lists)
	await _a_frame_passes()
	return lists


## A point within a control, as a share of its size, in its own terms: what the engine hands _can_drop_data.
func _within(control: Control, across: float, down: float) -> Vector2:
	return Vector2(control.size.x * across, control.size.y * down)


func _a_drag_over_a_list_lands_between_its_pieces_and_a_drop_on_a_piece_is_the_lists_one_command() -> void:
	var lists := await _lists()
	var ui := _made.ui
	var one: Control = ui.node_named(&"card 1")
	var two: Control = ui.node_named(&"card 2")
	var three: Control = ui.node_named(&"card 3")
	var data: Variant = one._get_drag_data(Vector2.ZERO)
	_verdict.check(_carried.get_over() == {"into": "a", "at": 0}, "lifted from the head of its list, it would land where it stood: %s" % [_carried.get_over()])
	three._can_drop_data(_within(three, 0.5, 0.75), data)
	_verdict.check(_carried.get_over() == {"into": "a", "at": 2}, "over the lower half of the last piece, it would land after it - the carried one left out of the places: %s" % [_carried.get_over()])
	two._can_drop_data(_within(two, 0.5, 0.25), data)
	_verdict.check(_carried.get_over() == {"into": "a", "at": 0}, "over the upper half of the piece now first, it would land before it: %s" % [_carried.get_over()])
	var twelve: Control = ui.node_named(&"card 12")
	var takes: bool = twelve._can_drop_data(_within(twelve, 0.5, 0.25), data)
	await _a_frame_passes()
	_verdict.check(takes and _carried.get_over() == {"into": "b", "at": 1}, "over the other list's second piece, the engine is told it would take it there: %s" % [_carried.get_over()])
	_verdict.check(ui.node_named(&"b").get_state() == &"accepting" and ui.node_named(&"a").get_state() == &"normal", "the list it would land in draws accepting, the one it left an ordinary face: %s, %s" % [ui.node_named(&"b").get_state(), ui.node_named(&"a").get_state()])
	twelve._drop_data(_within(twelve, 0.5, 0.25), data)
	await _a_frame_passes()
	_verdict.check(lists.told_actions == [&"moves_it"] and lists.told_payloads == [{"id": 1, "into": "b", "at": 1}], "dropped on a piece of the list, the list's action ran once, carrying the thing and where among the list it landed: %s" % [lists.told_payloads])
	_verdict.check(lists.carrying_as_told == [true] and not _carried.is_carrying(), "told while the thing was still carried - so it moves to where it is already shown - and set down after")
	_done()


func _lifted_from_a_list_it_would_land_where_it_stood_and_the_pointer_leaves_a_hole() -> void:
	await _lists()
	var ui := _made.ui
	var two: Control = ui.node_named(&"card 2")
	var words: Control = two.get_child(0)
	two._get_drag_data(Vector2.ZERO)
	await _a_frame_passes()
	_verdict.check(_carried.get_over() == {"into": "a", "at": 1} and two.get_state() == &"lifted", "lifted from the middle, it would land where it stood, and is drawn lifted")
	_verdict.check(words.modulate.a == 0.0, "lifted by the pointer it is a hole: its content is not drawn, its likeness travels under the pointer: %s" % words.modulate.a)
	_carried.put_back()
	await _a_frame_passes()
	_verdict.check(words.modulate.a == 1.0, "put back, its content is drawn again")
	two.grab_focus()
	await _a_frame_passes()
	_key(KEY_ENTER)
	await _a_frame_passes()
	_verdict.check(_carried.is_by_keys() and _carried.get_over() == {"into": "a", "at": 1} and words.modulate.a == 1.0 and two.has_focus(), "lifted by the keys it is the thing itself, drawn where it would land, holding the focus")
	_done()


func _the_keys_step_a_carry_along_its_list_across_to_the_next_and_drop_it_there() -> void:
	var lists := await _lists()
	var ui := _made.ui
	var one: Control = ui.node_named(&"card 1")
	one.grab_focus()
	await _a_frame_passes()
	_key(KEY_RIGHT)
	await _a_frame_passes()
	_verdict.check(ui.node_named(&"card 11").has_focus() and (ui.node_named(&"card 3") as Control).find_next_valid_focus() == ui.node_named(&"card 11"), "at rest, right and the next focus walk from a card to a card of the next list, past the list itself: %s" % [(ui.node_named(&"card 3") as Control).find_next_valid_focus()])
	one.grab_focus()
	await _a_frame_passes()
	_key(KEY_ENTER)
	await _a_frame_passes()
	var seen: Array = [_carried.get_over()]
	# down three times, past the last place, and up once
	for code: Key in [KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_UP]:
		_key(code)
		await _a_frame_passes()
		seen.append(_carried.get_over()["at"])
	_verdict.check(seen == [{"into": "a", "at": 0}, 1, 2, 2, 1], "accept lifts it where it stood; down steps it a place at a time, held at the last; up steps back: %s" % [seen])
	_key(KEY_RIGHT)
	await _a_frame_passes()
	_verdict.check(_carried.get_over() == {"into": "b", "at": 1} and one.has_focus() and ui.node_named(&"b").get_state() == &"accepting", "right takes it across to the next list at the same place, the focus still on the thing carried: %s" % [_carried.get_over()])
	_key(KEY_RIGHT)
	await _a_frame_passes()
	_verdict.check(_carried.get_over() == {"into": "b", "at": 1} and _carried.is_carrying(), "with no list further that way, it stays where it is, still carried")
	_key(KEY_ENTER)
	await _a_frame_passes()
	_verdict.check(lists.told_payloads == [{"id": 1, "into": "b", "at": 1}] and not _carried.is_carrying(), "accept drops it there: one command, carrying where it landed: %s" % [lists.told_payloads])
	var two: Control = ui.node_named(&"card 2")
	two.grab_focus()
	await _a_frame_passes()
	_key(KEY_ENTER)
	await _a_frame_passes()
	_key(KEY_DOWN)
	await _a_frame_passes()
	_key(KEY_ESCAPE)
	await _a_frame_passes()
	_verdict.check(not _carried.is_carrying() and _carried.get_put_back() and two.has_focus() and lists.told_payloads.size() == 1, "cancel puts it back with the focus home and nothing told")
	_done()


func _a_click_on_a_draggable_presses_it_and_a_drag_does_not() -> void:
	var lists := await _lists()
	var one: Control = _made.ui.node_named(&"card 1")
	# the button down on it and up again, with no drag between
	for down: bool in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = down
		one._gui_input(click)
	_verdict.check(lists.told_actions == [&"opens_it"] and lists.told_payloads == [{"id": 1}], "a click presses it: its action, once, with its payload: %s" % [lists.told_payloads])
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	one._gui_input(press)
	one._get_drag_data(Vector2.ZERO)
	var release: InputEventMouseButton = press.duplicate()
	release.pressed = false
	one._gui_input(release)
	_verdict.check(lists.told_actions == [&"opens_it"], "a press that became a drag presses nothing: %s" % [lists.told_actions])
	_carried.put_back()
	_done()


## --- lanes ---

## Two lanes of a board that moves what is dropped - out of its lane, into
## the one named, at the place named - and whatever hears a lane, counted.
class Board extends Lists:
	func told(action: StringName, payload: Dictionary) -> Phrase:
		super.told(action, payload)
		if action != &"moves_it":
			return null
		var thing := {"id": payload["id"]}
		var lanes := {"a": (of(&"items").read() as Array).filter(func(one: Dictionary) -> bool: return one != thing), "b": (of(&"words").read() as Array).filter(func(one: Dictionary) -> bool: return one != thing)}
		lanes[payload["into"]].insert(payload["at"], thing)
		set_value(&"items", lanes["a"])
		set_value(&"words", lanes["b"])
		return null


## A test of what a lane shows, a value of a model of its own, as a search's is.
class Narrowed extends Fixture.Controller:
	var _shows := value(func(_one: Dictionary) -> bool: return true)

	func _init(chimes: Chimes) -> void:
		super(chimes, [], &"tests")

	func get_shows() -> Callable:
		return _shows.read()

	func narrow(to: Callable) -> void:
		_shows.set_value(to)


func _a_lane_shows_the_carried_thing_where_it_would_land_and_nothing_else_moves() -> void:
	var key := func(one: Dictionary) -> int: return one["id"]
	var items: Array = [{"id": 1}, {"id": 2}, {"id": 3}]
	var every := func(_one: Dictionary) -> bool: return true
	_verdict.check(Lane.shown(items, key, {}, {}, "a", every) == items, "with nothing carried, a lane shows its items as they are")
	_verdict.check(Lane.shown(items, key, {"id": 1}, {"into": "a", "at": 2}, "a", every) == [{"id": 2}, {"id": 3}, {"id": 1}], "the thing carried is shown at the place it is over, taken out of where it stood")
	_verdict.check(Lane.shown(items, key, {"id": 2}, {"into": "b", "at": 0}, "a", every) == [{"id": 1}, {"id": 3}], "over another lane, the lane it came from closes up")
	_verdict.check(Lane.shown(items, key, {"id": 9}, {"into": "a", "at": 7}, "a", every) == [{"id": 1}, {"id": 2}, {"id": 3}, {"id": 9}], "a thing from elsewhere comes in at the place it is over, held to the end")
	_verdict.check(Lane.shown(items, key, {"id": 9}, {}, "a", every) == items, "carried and over no lane, nothing is shown of it")
	var narrowed: Array = [{"id": 1}, {"id": 2}, {"id": 3}, {"id": 4}]
	var evens := func(one: Dictionary) -> bool: return one["id"] % 2 == 0
	var landed: Array = [0, 1, 2].map(func(at: int) -> Array: return Lane.shown(narrowed, key, {"id": 10}, {"into": "a", "at": at}, "a", evens).map(func(one: Dictionary) -> int: return one["id"]))
	_verdict.check(landed == [[1, 10, 2, 3, 4], [1, 2, 3, 10, 4], [1, 2, 3, 4, 10]], "a place is among the items shown: before the first shown, before the second, after the last - those turned away stepped over: %s" % [landed])


func _a_lane_rings_only_when_what_it_shows_changed() -> void:
	var lists := await _lists()
	var key := func(one: Dictionary) -> int: return one["id"]
	var tests := Narrowed.new(_made.chimes)
	var a := Lane.new(_made.chimes, _carried, lists.of(&"items"), Bound.new(tests.get_shows), "a", key)
	var b := Lane.new(_made.chimes, _carried, lists.of(&"words"), Bound.new(tests.get_shows), "b", key)
	# the lanes' first working out heard, before anything is counted
	await _a_frame_passes()
	var heard_a := Fixture.Heard.new(_made.chimes, a.get_items)
	var heard_b := Fixture.Heard.new(_made.chimes, b.get_items)
	_carried.lift({"id": 2}, {"into": "a", "at": 1}, false)
	await _a_frame_passes()
	_verdict.check(heard_a.rung == 0 and heard_b.rung == 0 and a.get_items() == [{"id": 1}, {"id": 2}, {"id": 3}], "lifted where it stood, neither lane rings: nothing they show changed")
	_carried.move_over("a", 2)
	await _a_frame_passes()
	_verdict.check(heard_a.rung == 1 and heard_b.rung == 0 and a.get_items() == [{"id": 1}, {"id": 3}, {"id": 2}], "moved on a place, its own lane rings once and the other not at all: %s" % [a.get_items()])
	_carried.move_over("b", 0)
	await _a_frame_passes()
	_verdict.check(heard_a.rung == 2 and heard_b.rung == 1 and b.get_items() == [{"id": 2}, {"id": 11}, {"id": 12}] and a.get_count() == 2, "across to the other lane, each rings once: the one it left closes, the one it is over opens")
	_carried.put_back()
	await _a_frame_passes()
	_verdict.check(a.get_items() == [{"id": 1}, {"id": 2}, {"id": 3}] and b.get_count() == 2, "put back, both show their source again")
	var counted := Fixture.Heard.new(_made.chimes, a.get_count)
	tests.narrow(func(one: Dictionary) -> bool: return one["id"] != 1)
	await _a_frame_passes()
	_verdict.check(heard_a.rung == 3 and a.get_items() == [{"id": 1}, {"id": 2}, {"id": 3}] and a.get_count() == 2 and counted.rung == 1, "the test of what is shown moving, the lane's items stay as they were - it rings for none of them - while a reader of its count hears the test move: %s of %s" % [a.get_count(), a.get_items()])
	_carried.lift({"id": 12}, {"into": "a", "at": 0}, false)
	await _a_frame_passes()
	tests.narrow(func(_one: Dictionary) -> bool: return true)
	await _a_frame_passes()
	_verdict.check(heard_a.rung == 5 and a.get_items() == [{"id": 12}, {"id": 1}, {"id": 2}, {"id": 3}], "but with something carried over the lane, the test moving alone moves where it would land - the lane hears the test: %s" % [a.get_items()])
	_carried.put_back()
	for node: Node in [tests, a, b, heard_a, heard_b, counted]:
		node.free()
	_done()


## A board of two list targets whose eaches show two lanes, its model moving what is dropped.
func _board() -> Board:
	_made = Fixture.new(root, {&"moves_it": "move it"})
	_carried = _made.ui.carried
	var board := Board.new(_made.chimes, &"app")
	board.carried = _carried
	_model = board
	board.set_value(&"items", [{"id": 1}, {"id": 2}, {"id": 3}])
	board.set_value(&"words", [{"id": 11}, {"id": 12}])
	var ui := _made.ui
	var key := func(one: Dictionary) -> int: return one["id"]
	var card := func(item: Bound) -> Desc: return ui.draggable(item, [ui.text(item.map(func(one: Variant) -> String: return "" if one == null else "card %d" % one["id"]))])
	var every := Bound.new(func() -> Callable: return func(_one: Dictionary) -> bool: return true)
	var lanes: Array = [["a", &"items"], ["b", &"words"]].map(func(one: Array) -> Lane: return Lane.new(_made.chimes, _carried, board.of(one[1]), every, one[0], key))
	# every lane beside the app, freed with the fixture
	for lane: Lane in lanes:
		ui.also(lane)
	var list := func(lane: Lane) -> Desc: return ui.drop_target(&"moves_it", [ui.each(Bound.new(lane.get_items), card, key)], &"Pressable", lane.get_into()).named(StringName(lane.get_into()))
	ui.start(ui.app(&"app", [ui.row([list.call(lanes[0]).grow(), list.call(lanes[1]).grow()])]))
	await _a_frame_passes()
	_made.commands.register(&"app", &"moves_it", board)
	await _a_frame_passes()
	return board


## The piece the each of this list target holds for this key.
func _piece(target: StringName, key: int) -> Control:
	return (_made.ui.node_named(target).find_children("*", "Container", true, false).filter(func(inside: Node) -> bool: return inside.has_method(&"piece_for"))[0]).piece_for(key)


func _a_card_carried_by_keys_travels_between_lanes_and_lands_without_moving_again() -> void:
	var board := await _board()
	_piece(&"a", 1).grab_focus()
	await _a_frame_passes()
	_key(KEY_ENTER)
	await _a_frame_passes()
	_key(KEY_DOWN)
	await _a_frame_passes()
	_verdict.check(_piece(&"a", 1).get_index() == 1 and _piece(&"a", 1).has_focus(), "down, the card itself moves a place down its lane, the focus on it")
	_key(KEY_RIGHT)
	await _a_frame_passes()
	var there: Control = _piece(&"b", 1)
	_verdict.check(there != null and _piece(&"a", 1) == null and there.get_index() == 1 and there.has_focus() and there.get_state() == &"lifted", "right, the card is built in the next lane at its place, the lane it left closes, and the focus follows it")
	_key(KEY_ENTER)
	await _a_frame_passes()
	_verdict.check(board.of(&"words").read() == [{"id": 11}, {"id": 1}, {"id": 12}] and not _carried.is_carrying(), "accept drops it: the model moves it there: %s" % [board.of(&"words").read()])
	_verdict.check(_piece(&"b", 1) == there and there.get_index() == 1 and there.get_state() != &"lifted", "and the piece it was shown as is the one that stays, where it was - nothing is built again and nothing moves")
	_piece(&"a", 2).grab_focus()
	await _a_frame_passes()
	_key(KEY_ENTER)
	await _a_frame_passes()
	_key(KEY_RIGHT)
	await _a_frame_passes()
	_key(KEY_ESCAPE)
	await _a_frame_passes()
	_verdict.check(_piece(&"b", 2) == null and _piece(&"a", 2) != null and _piece(&"a", 2).has_focus(), "carried across and put back, the card is built again where it stood and the focus comes home to it")
	_done()


func _a_card_dropped_into_another_lane_moves_as_it_lands() -> void:
	await _board()
	_made.ui.motion.by_hand = true
	_made.ui.motion.still = false
	var leaving: Control = _piece(&"a", 1)
	# the drop's one command, as a drop on the lane sends it
	_made.commands.dispatch(&"app", &"moves_it", {"id": 1, "into": "b", "at": 1})
	await _a_frame_passes()
	var landed: Control = _piece(&"b", 1)
	_verdict.check(landed.modulate.a < 1.0 and is_instance_valid(leaving) and leaving.modulate.a > 0.0 and _made.ui.motion.get_running() > 0, "dropped, the card arrives in its new lane and goes from its old one, both on their way: arriving at %s, %d running" % [landed.modulate.a, _made.ui.motion.get_running()])
	_made.ui.motion.step(1.0)
	await _a_frame_passes()
	_verdict.check(landed.modulate == Color.WHITE and not is_instance_valid(leaving) and _made.ui.motion.get_running() == 0, "and comes to rest there")
	_done()
