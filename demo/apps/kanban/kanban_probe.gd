extends RefCounted

const GdChime := preload("res://addons/gd_chime/gd_chime.gd")
const KanbanBoard := preload("res://demo/apps/kanban/kanban_board.gd")
const Hands := preload("res://tests/hands.gd")

## The kanban board walked and judged, run by it with --probe and by
## checks/stalls_probe.py: everything the brief asks of a kanban workspace,
## done through the doors a reader's hands use, and then every arrangement
## looked at in three window shapes.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Walked: the six lanes and their three hundred cards, each saying its
## number, title, person, priority and estimate; a card dragged by the
## pointer from Ready into Done - the engine's own drag, pushed as a hand
## makes it - landing where the gap showed and counted by the progress in
## the same frame; a card carried by the keys down its lane and across to
## the next, and another put back with the focus home; a lane at its limit
## refusing a card in words; a blocked card moved at once and, refused by the
## server, back where it stood, saying why on itself and in a notification,
## and moved again and retitled, the title the server kept read back to it;
## a card opened by a click and retitled in the pane; a card's menu opened
## by the menu key, renaming it in place, and by a right press; a search
## and the filters narrowing the board. Judged: the board, the card pane and
## a menu over it, at 1920x1080, 1280x800 and 720x1280, for words cut off
## and anything drawn over anything else.

const SHAPES: Array[Vector2i] = [Vector2i(1920, 1080), Vector2i(1280, 800), Vector2i(720, 1280)]

var _app: SceneTree
var _said: Dictionary = {}
var _hands: Hands


func _init(app: SceneTree) -> void:
	_app = app
	_hands = Hands.new(app)


func _do(action: StringName, payload: Dictionary = {}) -> GdChime.Phrase:
	return _hands.does(GdChime.Chimes.GLOBAL, action, payload)


func _lane_of(id: int) -> String:
	return _app.board.get_card(id)["lane"]


## The draggable a lane shows for a card, or none.
func _card(id: int) -> Control:
	# every lane, for the one showing the card
	for target: Node in _app.get_nodes_in_group(&"drop target"):
		var each: Node = target.find_children("*", "Container", true, false).filter(func(one: Node) -> bool: return one.has_method(&"piece_for"))[0]
		var piece: Node = each.piece_for(id)
		if piece != null:
			return piece.find_children("*", "Control", true, false).filter(func(one: Node) -> bool: return one.has_method(&"is_lifted"))[0]
	return null


## The cards these lanes show, as the reader sees them: every card whose piece is drawn.
func _drawn_cards(lanes: Array) -> Array:
	var cards: Array = []
	# every lane's cards, for those whose piece is drawn - scrolled out of sight or not
	for lane: Object in lanes:
		cards.append_array(lane.get_items().filter(func(one: Dictionary) -> bool: return _card(one["id"]).is_visible_in_tree()))
	return cards


## The walk: every claim, then every shape; said, and the application quit on the answer.
func run() -> void:
	await _hands.frames(4)
	_app.root.size = SHAPES[0]
	# every run arriving at once: the walk reads where things are, not where they are on their way to
	_app.ui.motion.still = true
	# the server's answers wait for the walk to ask for them, however slowly a headless frame goes
	_app.server.held = true
	await _hands.frames(6)
	var driver: GdChime.Driver = _app.driver
	_said["places"] = [&"kanban", _app.ui.menu_place, driver.goes_to(&"kanban", _app.OPENS_PEOPLE), driver.goes_to(&"kanban", _app.OPENS_ASSIGNING)].all(func(named: StringName) -> bool: return _hands.has_place(named))
	var counts: Array = _app.lanes.map(func(lane: Object) -> int: return lane.get_count())
	var first: Array = _hands.words(_card(211))
	_said["lanes_and_cards"] = counts == [110, 45, 35, 25, 25, 60] and _app.board.get_cards().size() == 300 and first.has("#211") and first.has("Retry team invites") and first.has("HS") and first.has("High") and first.has("3 points")
	await _dragged()
	await _carried_by_keys()
	await _refused_by_the_lane()
	await _rolled_back()
	await _opened_and_retitled()
	await _menu_by_keys()
	await _narrowed()
	await _whole()
	var failed: Array = _said.keys().filter(func(claim: String) -> bool: return not _said[claim])
	print("PROBE %s" % [_said])
	print("PROBE " + ("OK" if failed.is_empty() else "FAILED %s" % [failed]))
	_app.quit(0 if failed.is_empty() else 1)


## A Ready card dragged by the pointer into Done, over its second card: it
## lands there, one command, and the progress counts it in the same frame.
func _dragged() -> void:
	var card := _card(212)
	var over := _card(342)
	var at := _hands.middle_of(card)
	var to := _hands.middle_of(over) + Vector2(0, over.size.y * 0.3)
	_hands.move(at, false)
	await _hands.frames(2)
	await _hands.button(at, true)
	await _hands.frames(1)
	# the pointer carried across, a step a frame
	for step: int in 12:
		_hands.move(at.lerp(to, float(step + 1) / 12.0), true)
		await _hands.frames(1)
	await _hands.frames(2)
	# the gap has opened under the pointer: on to the lower part of the second card, wherever it stands now
	to = _hands.middle_of(over) + Vector2(0, over.size.y * 0.3)
	_hands.move(to, true)
	await _hands.frames(2)
	# the headless window routes a drag's later moves and its release unreliably by position, so the last move and the release are the engine's own calls
	over._can_drop_data(over.get_global_transform().affine_inverse() * (_app.ui.root.get_viewport().get_final_transform().affine_inverse() * to), {"payload": _app.ui.carried.get_payload()})
	var carrying: bool = _app.ui.carried.is_carrying() and _app.ui.carried.get_over() == {"into": "Done", "at": 2}
	var gap: bool = _card(212) != null and _lane_of(212) == "Ready"
	var done: int = _app.board.get_done()
	over._drop_data(Vector2.ZERO, {"payload": _app.ui.carried.get_payload()})
	var counted: bool = _app.board.get_done() == done + 1
	# the button let go, so the engine's own drag is over too: nothing is carried to take it
	await _hands.button(to, false)
	await _hands.frames(1)
	var progress: bool = _hands.shows_words("61 of 300, 20%")
	var last: Dictionary = _app.commands.get_last()
	_said["drag_by_mouse"] = carrying and gap and counted and progress and last["action"] == KanbanBoard.MOVES and _lane_of(212) == "Done" and _app.board.get_place_in_lane(212) == 2 and not _app.ui.carried.is_carrying()
	_app.server.answer_all()
	await _hands.frames()


## A card lifted by the keys, carried down its lane and across to the next,
## set down there; another lifted and put back, the focus home.
func _carried_by_keys() -> void:
	_card(213).grab_focus()
	await _hands.frames()
	await _hands.key(KEY_ENTER)
	await _hands.key(KEY_DOWN)
	await _hands.key(KEY_RIGHT)
	var over: Dictionary = _app.ui.carried.get_over()
	await _hands.key(KEY_ENTER)
	_said["carry_by_keys"] = over == {"into": "In progress", "at": 2} and _lane_of(213) == "In progress" and _app.board.get_place_in_lane(213) == 2
	_card(214).grab_focus()
	await _hands.frames()
	await _hands.key(KEY_ENTER)
	await _hands.key(KEY_RIGHT)
	await _hands.key(KEY_ESCAPE)
	_said["put_back_by_keys"] = _lane_of(214) == "Ready" and not _app.ui.carried.is_carrying() and _card(214).has_focus()
	_app.server.answer_all()
	await _hands.frames()


## Testing holds 26 at most: one more goes in; the next is refused, the lane saying why while the card is over it.
func _refused_by_the_lane() -> void:
	var taken: GdChime.Phrase = _do(KanbanBoard.MOVES_ON, {"id": _app.board.lane("Review").read()[0]["id"]})
	var next: int = _app.board.lane("Review").read()[0]["id"]
	_app.ui.carried.lift(_app.board.lane("Review").read()[0], {"into": "Testing", "at": 0}, false)
	await _hands.frames()
	var testing: Control = _app.get_nodes_in_group(&"drop target").filter(func(one: Node) -> bool: return one.get_into() == "Testing")[0]
	var says: bool = testing.get_state() == &"refusing" and _hands.words(testing).has("Testing holds 26 at most")
	testing.drop()
	_said["refused_by_the_lane"] = taken == null and says and _lane_of(next) == "Review" and _app.ui.carried.is_carrying()
	_app.ui.carried.put_back()
	_app.server.answer_all()
	await _hands.frames()


## A blocked card moved at once, refused by the server, back where it stood, saying why.
func _rolled_back() -> void:
	var blocked: Dictionary = _app.board.lane("In progress").read().filter(func(one: Dictionary) -> bool: return (one["labels"] as Array).has("blocked"))[0]
	var was: int = _app.board.get_place_in_lane(blocked["id"])
	_do(KanbanBoard.MOVES, blocked.merged({"into": "Review", "at": 0}))
	await _hands.frames()
	var at_once: bool = _lane_of(blocked["id"]) == "Review" and _hands.words(_card(blocked["id"])).has("Saving")
	_app.server.answer_all()
	await _hands.frames()
	var standing: Array = _app.notifications.get_standing().map(func(one: Dictionary) -> String: return str(one["words"]))
	var reason := "#%d is blocked by another card" % blocked["id"]
	_said["rolled_back"] = at_once and _lane_of(blocked["id"]) == "In progress" and _app.board.get_place_in_lane(blocked["id"]) == was and _hands.words(_card(blocked["id"])).has("Not kept: " + reason) and standing.has("#%d to Review was not kept: %s" % [blocked["id"], reason])
	_do(KanbanBoard.MOVES, blocked.merged({"into": "Review", "at": 0}))
	_do(KanbanBoard.RETITLES, {"id": blocked["id"], "title": "Kept by the server"})
	# the move refused undoes both, the retitle kept: answered, then the read back that yes sends answered
	for asked: int in 2:
		_app.server.answer_all()
	_said["settled_on_the_server"] = _app.board.get_card(blocked["id"])["title"] == "Kept by the server" and _app.server.get_card(blocked["id"])["title"] == "Kept by the server" and _lane_of(blocked["id"]) == "In progress" and _app.provisional.get_pending().is_empty()


## A click opens a card in the pane; its title typed there changes it.
func _opened_and_retitled() -> void:
	var card := _card(215)
	var at := _hands.middle_of(card) + Vector2(0, -card.size.y * 0.3)
	_hands.move(at, false)
	await _hands.frames(1)
	await _hands.button(at, true)
	await _hands.button(at, false)
	await _hands.frames(4)
	var open: bool = _app.board.get_open_card() != null and _app.board.get_open_card()["id"] == 215 and _app.panels.is_shown(&"detail")
	_do(KanbanBoard.RETITLES, {"line": "Paginate billing webhook for everyone"})
	await _hands.frames()
	_said["opened_and_retitled"] = open and _app.board.get_card(215)["title"] == "Paginate billing webhook for everyone" and _hands.words(_card(215)).has("Paginate billing webhook for everyone")
	_app.server.answer_all()


## The menu key on a card opens its menu, each item refused as its press
## would be; rename there opens its title for typing in the card itself,
## the line taking the focus, and Enter writes it.
func _menu_by_keys() -> void:
	_card(101).grab_focus()
	await _hands.frames()
	await _hands.key(KEY_MENU)
	var up: Array = _app.menu.items_of(_app.driver.get_parameter(_app.ui.menu_place))
	var menu: bool = up.map(func(item: Dictionary) -> StringName: return item["action"]) == [KanbanBoard.OPENS, KanbanBoard.RENAMES, KanbanBoard.MOVES_ON, KanbanBoard.MOVES_BACK, KanbanBoard.RAISES, KanbanBoard.LOWERS] and str(_app.commands.refusal(_app.ui.menu_place, GdChime.OpenMenu.PICKS, {"item": up[3]})) == "It is in the first lane already"
	_hands.does(_app.ui.menu_place, GdChime.OpenMenu.PICKS, {"item": up[1]})
	await _hands.frames()
	var focus: Control = _hands.focused()
	var typing: bool = _app.board.get_editing() == 101 and focus is LineEdit and _card(101).is_ancestor_of(focus)
	(focus as LineEdit).text = "Renamed in place"
	await _hands.key(KEY_ENTER)
	_said["menu_by_keys_and_rename_in_place"] = menu and typing and _app.board.get_card(101)["title"] == "Renamed in place" and _app.board.get_editing() == null and _hands.words(_card(101)).has("Renamed in place")
	_app.server.answer_all()


## A search narrows the board and its count; a label and a person narrow it further; cleared, all come back.
func _narrowed() -> void:
	_do(GdChime.Filters.SEARCHES, {"line": "paginate"})
	await _hands.frames()
	var searched: int = _app.board.get_shown_count()
	var drawn: Array = _drawn_cards(_app.lanes)
	var all_match: bool = drawn.size() == searched and _hands.words().has("Showing %d of 300 cards" % searched) and drawn.all(func(one: Dictionary) -> bool: return (one["title"] as String).to_lower().contains("paginate"))
	_do(GdChime.Filters.SEARCHES, {"line": ""})
	_do(GdChime.Filters.TOGGLES, {"column": &"labels", "value": "bug"})
	_do(GdChime.Filters.PICKS, {"column": &"person", "value": "Ana Lopez"})
	await _hands.frames()
	var narrowed: int = _app.board.get_shown_count()
	var both: bool = _app.board.get_cards().filter(func(one: Dictionary) -> bool: return one["person"] == "Ana Lopez" and (one["labels"] as Array).has("bug")).size() == narrowed and _drawn_cards(_app.lanes).size() == narrowed
	_do(GdChime.Filters.CLEARS)
	await _hands.frames()
	_said["search_and_filters"] = searched > 0 and searched < 300 and all_match and narrowed > 0 and both and _drawn_cards(_app.lanes).size() == 300


## Every shape: the board with the card pane open, and a menu over it, judged for words cut and things drawn over.
func _whole() -> void:
	var cut: Array[String] = []
	var over: Array[String] = []
	var menus: Array = []
	_app.ui.motion.still = true
	_app.ui.motion.step(10.0)
	# every shape, each judged alike
	for shape: Vector2i in SHAPES:
		_app.root.size = shape
		await _hands.judged(&"the board", shape, cut, over)
		await _hands.right_click(_card(211))
		menus.append(_app.driver.get_top() == [_app.ui.menu_place])
		await _hands.judged(&"a menu", shape, cut, over)
		_do(GdChime.Driver.GOES_BACK)
	_said["menu_by_pointer"] = menus.all(func(up: bool) -> bool: return up)
	_said["no_clipped_text"] = cut.is_empty()
	_said["nothing_drawn_over"] = over.is_empty()
	_said["words_stand_out"] = _hands.get_faint().is_empty()
	_hands.say_every(cut.slice(0, 20), over.slice(0, 20))
