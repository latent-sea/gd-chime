extends SceneTree
const Actions := preload("res://addons/gd_chime/actions.gd")

## What must be true of the phone's recipes: a swipe row's actions are its
## menu's too, so the keys reach them; the navigation is a bar at a phone's
## foot and the same destinations a rail beside a wider window; a failed
## asking is said the one way - a notification and the mark on the thing -
## with a way to ask again and nothing lost; and the connection's line and
## each thing's words say what is syncing and what is awaiting sync.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_phone_recipes.gd

const Fixture := preload("res://tests/fixture.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Inputs := preload("res://addons/gd_chime/input_map.gd")
const OpenMenu := preload("res://addons/gd_chime/open_menu.gd")
const Fetched := preload("res://addons/gd_chime/fetched.gd")
const Connection := preload("res://addons/gd_chime/connection.gd")
const Outbox := preload("res://addons/gd_chime/outbox.gd")
const Provisional := preload("res://addons/gd_chime/provisional.gd")
const Notifications := preload("res://addons/gd_chime/notifications.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Status := preload("res://addons/gd_chime/components/recipes/status.gd")
const ContextMenu := preload("res://addons/gd_chime/components/recipes/context_menu.gd")
const SwipeRow := preload("res://addons/gd_chime/components/recipes/swipe_row.gd")
const AdaptiveNav := preload("res://addons/gd_chime/components/recipes/adaptive_nav.gd")
const PullToRefresh := preload("res://addons/gd_chime/components/recipes/pull_to_refresh.gd")
const ConnectionStatus := preload("res://addons/gd_chime/components/recipes/connection_status.gd")
const Verdict := preload("res://tests/verdict.gd")

const OPENS := &"opens"
const DELIVERS := &"delivers"
const REPORTS := &"reports"
const GOES_HOME := &"goes_home"
const GOES_AWAY := &"goes_away"

var _verdict := Verdict.new()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	await _verdict.states(_a_swipe_row_s_actions_are_its_menu_s_for_the_keys)
	await _verdict.states(_the_navigation_is_a_bar_at_a_phone_s_foot_and_the_same_a_rail_beside)
	await _verdict.states(_a_failed_asking_is_said_one_way_and_loses_nothing)
	await _verdict.states(_the_connection_s_line_and_each_thing_say_what_awaits_sync)
	quit(_verdict.deliver(get_script()))


func _frames(count: int = 4) -> void:
	# the frames asked for, each passing
	for frame: int in count:
		await process_frame


func _texts(node: Node) -> Array:
	return node.find_children("*", "Label", true, false).filter(func(label: Label) -> bool: return label.is_visible_in_tree()).map(func(label: Label) -> String: return label.text)


func _a_swipe_row_s_actions_are_its_menu_s_for_the_keys() -> void:
	var made := Fixture.new(root, {})
	var table: Dictionary = {}
	# every action, the menu opened on the menu key
	for action: StringName in [OPENS, DELIVERS, REPORTS, OpenMenu.OPENS, OpenMenu.PICKS]:
		table[action] = [String(action), Actions.keys(KEY_MENU)] if action == OpenMenu.OPENS else [String(action)]
	made.actions.declare_all(table)
	made.inputs.restore_defaults()
	var model := Fixture.Model.new(made.chimes)
	var menu := OpenMenu.new(made.chimes, made.commands, made.actions)
	root.add_child(model)
	root.add_child(menu)
	# the row's actions answered by the model, the menu's opening by the menu
	for action: StringName in [OPENS, DELIVERS, REPORTS]:
		made.commands.register(Chimes.GLOBAL, action, model)
	made.commands.register(Chimes.GLOBAL, OpenMenu.OPENS, menu)
	var ui := made.ui
	var sides := {SwipeRow.RIGHT: {"action": DELIVERS, "words": Phrase.of("delivered"), "state": Status.WELL}, SwipeRow.LEFT: {"action": REPORTS, "words": Phrase.of("report"), "state": Status.FAULT}}
	var places := ui.tabs(&"places", [ui.screen(&"list", [ui.column([SwipeRow.make(ui, OPENS, {"id": 7}, ui.text("stop 7"), {sides = sides, goes_to = &"stop"}).named(&"row")])]), ui.screen(&"stop", [ui.text("stop 7, open")])])
	ContextMenu.make(ui, menu)
	ui.start(ui.app(&"app", [places]))
	root.size = Vector2i(1920, 1080)
	await _frames(6)
	var row: Control = ui.node_named(&"row").find_children("*", "Control", true, false).filter(func(one: Node) -> bool: return one.has_method(&"get_slid"))[0]
	row.grab_focus()
	await _frames(2)
	var key := InputEventKey.new()
	key.keycode = KEY_MENU
	key.pressed = true
	root.push_input(key)
	await _frames(3)
	var up: StringName = ui.menu_place
	var items: Array = menu.items_of(made.driver.get_parameter(up))
	var offered: Array = items.map(func(item: Dictionary) -> StringName: return item["action"])
	_verdict.check(made.driver.get_top() == [up] and offered == [OPENS, DELIVERS, REPORTS], "the menu key on a swipe row opens its menu, offering its tap's action and both sides': %s" % [offered])
	made.commands.dispatch(up, OpenMenu.PICKS, {"item": items[1]})
	await _frames(2)
	_verdict.check(model.told_actions == [DELIVERS], "and a pick there does the side's action, no finger needed: %s" % [model.told_actions])
	row.grab_focus()
	await _frames(2)
	root.push_input(key)
	await _frames(3)
	made.commands.dispatch(up, OpenMenu.PICKS, {"item": menu.items_of(made.driver.get_parameter(up))[0]})

	await _frames(3)
	_verdict.check(made.driver.get_top().has(&"stop"), "and its tap's action picked from the menu goes where a tap goes: %s" % [made.driver.get_top()])
	made.done()


func _the_navigation_is_a_bar_at_a_phone_s_foot_and_the_same_a_rail_beside() -> void:
	var made := Fixture.new(root, {GOES_HOME: "home", GOES_AWAY: "away"})
	var ui := made.ui
	var destinations := [{"action": GOES_HOME, "goes_to": &"home"}, {"action": GOES_AWAY, "goes_to": &"away"}]
	var places := ui.tabs(&"places", [ui.screen(&"home", [ui.text("at home")]), ui.screen(&"away", [ui.text("away")])])
	ui.start(ui.app(&"app", [AdaptiveNav.make(ui, destinations, places)]))
	root.size = Vector2i(720, 1280)
	await _frames(6)
	made.commands.dispatch(Chimes.GLOBAL, made.driver.GO, {"place": &"home"})
	await _frames(3)
	var home: Control = made.driver.index.place_named(&"app").find_children("*", "Control", true, false).filter(func(one: Node) -> bool: return one.get(&"action") == GOES_HOME)[0]
	var away: Control = made.driver.index.place_named(&"app").find_children("*", "Control", true, false).filter(func(one: Node) -> bool: return one.get(&"action") == GOES_AWAY)[0]
	var content: Control = made.driver.index.place_named(&"places")
	_verdict.check(home.get_global_rect().position.y >= content.get_global_rect().end.y - 1.0 and is_equal_approx(home.get_global_rect().position.y, away.get_global_rect().position.y) and away.get_global_rect().position.x > home.get_global_rect().position.x, "on a phone's window the destinations are a bar side by side under what they open: %s %s %s" % [home.get_global_rect(), away.get_global_rect(), content.get_global_rect()])
	_verdict.check(home.call(&"get_state") == &"current" and away.call(&"get_state") != &"current", "the one the reader is at is drawn current")
	root.size = Vector2i(1920, 1080)
	await _frames(6)
	var still_home: Control = made.driver.index.place_named(&"app").find_children("*", "Control", true, false).filter(func(one: Node) -> bool: return one.get(&"action") == GOES_HOME)[0]
	_verdict.check(still_home == home and home.get_global_rect().end.x <= content.get_global_rect().position.x + 1.0 and away.get_global_rect().position.y > home.get_global_rect().position.y, "on a wide window the same destinations are a rail down the side, beside what they open: %s %s %s" % [home.get_global_rect(), away.get_global_rect(), content.get_global_rect()])
	made.done()


func _a_failed_asking_is_said_one_way_and_loses_nothing() -> void:
	var made := Fixture.new(root, {Fetched.ASKS_AGAIN: "Try again"})
	var asked: Array = []
	var notices := Notifications.new(made.chimes, made.commands, root)
	var fetched := Fetched.new(made.chimes, func(answer: Callable) -> void: asked.append(answer), notices, Phrase.of("The rows"))
	root.add_child(notices)
	root.add_child(fetched)
	made.commands.register(Chimes.GLOBAL, Fetched.ASKS_AGAIN, fetched)
	var ui := made.ui
	var rows := ui.column([ui.text("row 1"), ui.text("row 2")])
	ui.start(ui.app(&"app", [PullToRefresh.make(ui, fetched, ui.loading(fetched, rows, 2)).named(&"list")]))
	root.size = Vector2i(1920, 1080)
	await _frames(6)
	made.commands.dispatch(Chimes.GLOBAL, Fetched.ASKS_AGAIN, {})
	asked[0].call(["row 1", "row 2"], null)
	await _frames(3)
	var shown: Array = _texts(ui.node_named(&"list"))
	_verdict.check(not shown.has("Try again") and shown.has("row 1"), "landed, nothing is said of a failure: %s" % [shown])
	made.commands.dispatch(Chimes.GLOBAL, Fetched.ASKS_AGAIN, {})
	asked[1].call(null, Phrase.of("no connection"))
	await _frames(3)
	shown = _texts(ui.node_named(&"list"))
	var standing: Array = notices.get_standing().map(func(one: Dictionary) -> String: return str(one["words"]))
	_verdict.check(shown.has("Could not be loaded: no connection") and shown.has("Try again") and shown.has("row 2"), "failed, the mark on the thing says why over everything still shown, with a way to ask again: %s" % [shown])
	_verdict.check(standing == ["The rows could not be loaded: no connection"], "and a notification says it by the words the thing is known by, the other half of the one way: %s" % [standing])
	var again: Control = ui.node_named(&"list").find_children("*", "Control", true, false).filter(func(one: Node) -> bool: return one.get(&"action") == Fetched.ASKS_AGAIN and _texts(one).has("Try again"))[0]
	again.pressed()
	await _frames(3)
	_verdict.check(asked.size() == 3 and not _texts(ui.node_named(&"list")).has("Could not be loaded: no connection"), "asking again asks the far side, and the failure is gone as it begins: %d" % asked.size())
	made.done()


func _the_connection_s_line_and_each_thing_say_what_awaits_sync() -> void:
	var made := Fixture.new(root, {})
	var connection := Connection.new(made.chimes)
	var outbox := Outbox.new(made.chimes, connection, func(_request: Dictionary, _answer: Callable) -> void: pass)
	var notices := Notifications.new(made.chimes, made.commands, root)
	var provisional := Provisional.new(made.chimes, outbox.send, notices)
	for model: Node in [connection, outbox, notices, provisional]:
		root.add_child(model)
	var ui := made.ui
	var said := ConnectionStatus.of(connection, provisional, Bound.constant("stop 3"))
	ui.start(ui.app(&"app", [ui.column([ConnectionStatus.make(ui, connection, outbox), ui.text(said)]).named(&"line")]))
	root.size = Vector2i(1920, 1080)
	await _frames(6)
	provisional.begin("stop 3", Phrase.of("stop 3 delivered"), {"id": 3}, func() -> void: pass)
	await _frames(2)
	var shown: Array = _texts(ui.node_named(&"line"))
	_verdict.check(shown.has("Offline: 1 change awaiting sync") and shown.has("Awaiting sync"), "offline, the line counts what awaits sync and the thing says it awaits sync: %s" % [shown])
	connection.set_state(Connection.CONNECTED)
	await _frames(2)
	shown = _texts(ui.node_named(&"line"))
	_verdict.check(shown.has("Online") and shown.has("Syncing"), "back online, the line says so and the thing is syncing: %s" % [shown])
	made.done()
