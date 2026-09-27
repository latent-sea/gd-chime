extends RefCounted

const GdChime := preload("res://addons/gd_chime/gd_chime.gd")
const MobileRoute := preload("res://demo/apps/mobile/mobile_route.gd")
const MobileDepot := preload("res://demo/apps/mobile/mobile_depot.gd")
const MobileView := preload("res://demo/apps/mobile/mobile_view.gd")
const Hands := preload("res://tests/hands.gd")

## The mobile app walked and judged, run by it with --probe and by
## checks/stalls_probe.py: all the brief asks of a mobile app, done by a
## finger pushed as a touchscreen would and by the keys, in four shapes.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Walked: the route loading, loading's mark showing until it lands; a stop
## swiped right delivered and one left reported, one command each, and one
## swiped short left as it was; a stop tapped open, its delivery actions
## raised in a sheet from the foot and a problem reported from it, and
## Escape back; a stop's menu opened by the menu key, offering what its
## swipes do, and delivered from it; the list pulled to refresh, the depot's
## later route landing; the signal lost, a stop delivered and marked
## Awaiting sync, sent as the signal comes back; a delivery the depot
## refuses on sync rolled back, saying why; an asking failing with no
## signal, said the one way - a notification and the mark on the list -
## nothing lost, and asked again; the navigation a bar at a phone's foot
## and a rail beside a desktop's; and every touch target at least the look's
## least. Judged: the stops, a stop, its sheet, a menu and the offline
## stops, in every one of SHAPES, for words cut off or drawn over.

const SHAPES: Array[Vector2i] = [Vector2i(1920, 1080), Vector2i(1280, 800), Vector2i(1024, 1366), Vector2i(720, 1280)]
const PHONE := Vector2i(720, 1280)

var _app: SceneTree
var _said: Dictionary = {}
var _hands: Hands


func _init(app: SceneTree) -> void:
	_app = app
	_hands = Hands.new(app)


func _do(action: StringName, payload: Dictionary = {}) -> void:
	_hands.does(GdChime.Chimes.GLOBAL, action, payload)


## The swipe row showing this stop, or none.
func _row(id: int) -> Control:
	# every swipe row showing, for the one carrying this stop
	for node: Node in _app.root.find_children("*", "Control", true, false):
		if node.has_method(&"get_slid") and node.is_visible_in_tree() and node.payload().get("id") == id:
			return node
	return null


func _status(id: int) -> StringName:
	return _app.route.get_stops().filter(func(stop: Dictionary) -> bool: return stop["id"] == id)[0]["status"]


## A frame for what a move sends - it goes as its model rings - then the depot's answers landed.
func _settle() -> void:
	await _hands.frames(1)
	_app.depot.answer_all()
	await _hands.frames()


## The walk: every claim, then every shape; said, and the application quit on the answer.
func run() -> void:
	await _hands.frames(4)
	_app.root.size = PHONE
	# every run arriving at once: the walk reads where things are, not where they are on their way to
	_app.ui.motion.still = true
	# the depot's answers wait for the walk to ask for them, however slowly a headless frame goes
	_app.depot.held = true
	await _hands.frames(6)
	var loading: bool = _hands.words().has("Loading") and _app.route.stops.data.read() == null
	await _settle()
	_said["loads_then_lists"] = loading and _app.route.get_whole() == 24 and _hands.words(_row(1)).has("1. 3 Harbour Row")
	await _swiped()
	await _tapped_open_and_back()
	await _menu_by_keys()
	await _pulled_to_refresh()
	await _offline_awaiting_sync()
	await _refused_on_sync()
	await _failed_refresh_recovers()
	await _navigation()
	await _whole()
	var failed: Array = _said.keys().filter(func(claim: String) -> bool: return not _said[claim])
	print("PROBE %s" % [_said])
	print("PROBE " + ("OK" if failed.is_empty() else "FAILED %s" % [failed]))
	_app.quit(0 if failed.is_empty() else 1)


## Stop 3 swiped right delivered, stop 5 left reported, stop 6 swiped short and left as it was.
func _swiped() -> void:
	await _hands.drawn(_row(3), Vector2(_row(3).size.x * 0.6, 0), 6)
	var right: bool = _status(3) == MobileRoute.DELIVERED and _app.commands.get_last()["action"] == MobileRoute.DELIVERS
	await _hands.drawn(_row(5), Vector2(-_row(5).size.x * 0.6, 0), 6)
	await _hands.frames(1)
	var left: bool = _status(5) == MobileRoute.PROBLEM and _hands.words(_row(5)).has("A problem: Nobody home")
	await _hands.drawn(_row(6), Vector2(_row(6).size.x * 0.15, 0), 3)
	await _settle()
	_said["swipe_right_delivers_left_reports"] = right and left and _status(6) == MobileRoute.TO_DELIVER and _row(6).get_slid() == 0.0 and _app.provisional.get_pending().is_empty()


## A tap opens stop 7, everything about it said; Escape goes back to the stops.
func _tapped_open_and_back() -> void:
	await _hands.tap(_row(7))
	await _hands.frames()
	var open: bool = _app.driver.get_top().has(MobileView.STOP) and _app.driver.get_parameter(MobileView.STOP) == 7
	var place: Node = _hands.place(MobileView.STOP)
	var told: bool = _hands.words(place).any(func(line: String) -> bool: return line.begins_with("For "))
	await _sheet()
	await _hands.key(KEY_ESCAPE)
	_said["tap_opens_and_escape_returns"] = open and told and _app.driver.get_top().has(MobileView.TODAY)


## Stop 7's delivery actions in a sheet from the foot: raised by a tap, its
## sheet standing on the window's foot and spanning its width, as a bottom
## sheet on a phone does; a problem reported from it closes it.
func _sheet() -> void:
	var acts: Control = _hands.place(MobileView.STOP).find_children("*", "Control", true, false).filter(func(one: Node) -> bool: return one.get(&"action") == MobileView.SHOWS_DELIVERY_ACTIONS)[0]
	await _hands.tap(acts)
	await _hands.frames(4)
	var raised: bool = _app.driver.get_top() == [_app.view.delivery.get_place()] and _app.driver.get_parameter(_app.view.delivery.get_place()) == 7
	var sheet: Control = _hands.place(_app.view.delivery.get_place()).find_children("*", "Control", true, false).filter(func(one: Node) -> bool: return one.get(&"theme_type_variation") == &"Drawer")[0]
	var footed: bool = is_equal_approx(sheet.get_global_rect().end.y, _app.ui.root.get_viewport().get_visible_rect().end.y)
	# a bottom sheet on a phone is edge to edge, never capped in the middle as a desk's window caps it
	var spans: bool = is_equal_approx(sheet.get_global_rect().size.x, _app.ui.root.get_viewport().get_visible_rect().size.x)
	var offered: Array = _hands.words(sheet)
	var no_way_in: Control = sheet.find_children("*", "Control", true, false).filter(func(one: Node) -> bool: return one.get(&"action") == MobileRoute.REPORTS and _hands.words(one).has("No way in"))[0]
	await _hands.tap(no_way_in)
	await _settle()
	_said["sheet_of_delivery_actions"] = raised and footed and spans and offered.has("Mark delivered") and offered.has("Parcel damaged") and _status(7) == MobileRoute.PROBLEM and not _app.driver.is_raised()


## Stop 8's menu by the menu key offers what its swipes do; delivered from it.
func _menu_by_keys() -> void:
	_row(8).grab_focus()
	await _hands.frames()
	await _hands.key(KEY_MENU)
	var items: Array = _app.menu.items_of(_app.driver.get_parameter(_app.ui.menu_place))
	_hands.does(_app.ui.menu_place, GdChime.OpenMenu.PICKS, {"item": items[1]})
	await _settle()
	_said["keys_reach_the_swipes"] = items.map(func(item: Dictionary) -> StringName: return item["action"]) == [MobileView.OPENS, MobileRoute.DELIVERS, MobileRoute.REPORTS] and _status(8) == MobileRoute.DELIVERED


## The list pulled down past its top: a refresh, and the depot's later route lands.
func _pulled_to_refresh() -> void:
	var pull: Control = _app.root.find_children("*", "Container", true, false).filter(func(one: Node) -> bool: return one.has_method(&"get_open") and one.is_visible_in_tree())[0]
	var at := pull.get_global_rect().position + Vector2(pull.size.x * 0.5, 60.0)
	await _hands.touch(at, true)
	at = await _hands.draws_on(at, Vector2(0, 400), 8)
	await _hands.touch(at, false)
	var asked: bool = _app.route.stops.loading.read() and pull.get_open() > 0.0
	await _settle()
	_said["pull_to_refresh"] = asked and _app.route.get_whole() == 25 and pull.get_open() == 0.0 and _status(3) == MobileRoute.DELIVERED


## No signal: stop 10 delivered at once and marked Awaiting sync; sent as the signal comes back.
func _offline_awaiting_sync() -> void:
	_do(MobileDepot.SETS_SIGNAL, {"on": false})
	await _hands.drawn(_row(10), Vector2(_row(10).size.x * 0.6, 0), 6)
	await _settle()
	var waiting: bool = _status(10) == MobileRoute.DELIVERED and _hands.words(_row(10)).has("Awaiting sync") and _app.outbox.get_held() == 1
	var line: bool = _hands.words().has("Offline: 1 change awaiting sync")
	_do(MobileDepot.SETS_SIGNAL, {"on": true})
	await _settle()
	_said["offline_awaiting_sync"] = waiting and line and _app.outbox.get_held() == 0 and not _hands.words(_row(10)).has("Awaiting sync") and _status(10) == MobileRoute.DELIVERED


## Stop 9, delivered offline, is refused on sync: back as it was, saying why.
func _refused_on_sync() -> void:
	_do(MobileDepot.SETS_SIGNAL, {"on": false})
	await _hands.drawn(_row(9), Vector2(_row(9).size.x * 0.6, 0), 6)
	var kept_offline: bool = _status(9) == MobileRoute.DELIVERED
	_do(MobileDepot.SETS_SIGNAL, {"on": true})
	await _settle()
	var standing: Array = _app.notifications.get_standing().map(func(one: Dictionary) -> String: return str(one["words"]))
	_said["refused_on_sync_rolls_back"] = kept_offline and _status(9) == MobileRoute.TO_DELIVER and _hands.words(_row(9)).has("Not kept: The sender cancelled stop 9") and standing.has("Stop 9, delivered was not kept: The sender cancelled stop 9")


## No signal, an asking fails, said the one way - a notification and the mark on the list - nothing lost; asked again, it lands.
func _failed_refresh_recovers() -> void:
	_do(MobileDepot.SETS_SIGNAL, {"on": false})
	_hands.does(MobileView.TODAY, GdChime.Fetched.ASKS_AGAIN, {})
	await _settle()
	var standing: Array = _app.notifications.get_standing().map(func(one: Dictionary) -> String: return str(one["words"]))
	var failed: bool = _hands.words().has("Could not be loaded: No connection") and standing.has("Today's stops could not be loaded: No connection") and _app.route.get_whole() == 25 and _status(3) == MobileRoute.DELIVERED
	_do(MobileDepot.SETS_SIGNAL, {"on": true})
	var again: Control = _app.root.find_children("*", "Control", true, false).filter(func(one: Node) -> bool: return one.get(&"action") == GdChime.Fetched.ASKS_AGAIN and one.is_visible_in_tree())[0]
	await _hands.tap(again)
	await _settle()
	_said["failed_refresh_recovers"] = failed and _app.route.stops.failure.read() == null and not _hands.words().has("Could not be loaded: No connection")


## The navigation a bar at a phone's foot, a rail beside a desktop's window; a tap on it moves.
func _navigation() -> void:
	var sync: Control = _destination(_app.GOES_WAITING)
	var screen: Control = _hands.place(&"route")
	var bar: bool = sync.get_global_rect().position.y >= screen.get_global_rect().end.y - 1.0
	var least := float(sync.get_theme_constant(&"least", GdChime.Touch.TYPE))
	var targets: Array = _app.root.get_tree().get_nodes_in_group(GdChime.Touch.TARGETS).filter(func(one: Control) -> bool: return one.is_visible_in_tree() and one.get_combined_minimum_size().y < least)
	await _hands.tap(sync)
	var moved: bool = _app.driver.get_top().has(MobileView.WAITING)
	_app.root.size = SHAPES[0]
	await _hands.frames(6)
	var rail: bool = sync.get_global_rect().end.x <= screen.get_global_rect().position.x + 1.0
	await _hands.tap(_destination(_app.GOES_TODAY))
	_app.root.size = PHONE
	await _hands.frames(6)
	_said["navigation_bar_then_rail"] = bar and moved and rail and _app.driver.get_top().has(MobileView.TODAY)
	_said["touch_targets_on_a_phone"] = targets.is_empty()
	# every target too small, said, so a failure names it
	for small: Control in targets.slice(0, 5):
		print("PROBE SMALL %s %s" % [small.get(&"action"), small.get_combined_minimum_size()])


func _destination(action: StringName) -> Control:
	return _hands.place(&"app").find_children("*", "Control", true, false).filter(func(one: Node) -> bool: return one.get(&"action") == action)[0]


## Every shape: the stops, a stop open, a menu, and the stops with no signal - judged.
func _whole() -> void:
	var cut: Array[String] = []
	var over: Array[String] = []
	_app.ui.motion.step(10.0)
	# every shape, each judged alike
	for shape: Vector2i in SHAPES:
		_app.root.size = shape
		await _hands.judged(&"the stops", shape, cut, over)
		_hands.does(MobileView.TODAY, MobileView.OPENS, {"id": 4, "parameter": 4})
		await _hands.judged(&"a stop", shape, cut, over)
		_hands.does(MobileView.STOP, MobileView.SHOWS_DELIVERY_ACTIONS, {"parameter": 4})
		await _hands.judged(&"its sheet", shape, cut, over)
		_hands.does(_app.view.delivery.get_place(), _app.ui.CLOSES, {})
		await _hands.key(KEY_ESCAPE)
		_row(2).grab_focus()
		await _hands.key(KEY_MENU)
		await _hands.judged(&"a menu", shape, cut, over)
		_hands.does(_app.ui.menu_place, _app.ui.CLOSES, {})
		_do(MobileDepot.SETS_SIGNAL, {"on": false})
		_do(MobileRoute.DELIVERS, {"id": 11 + SHAPES.find(shape)})
		await _hands.judged(&"no signal", shape, cut, over)
		_do(MobileDepot.SETS_SIGNAL, {"on": true})
		await _settle()
	_said["no_clipped_text"] = cut.is_empty()
	_said["nothing_drawn_over"] = over.is_empty()
	_said["words_stand_out"] = _hands.get_faint().is_empty()
	# every set of words cut and every thing drawn over, said one by one, so a failure names them
	for sentence: String in cut.slice(0, 20).map(func(one: String) -> String: return "CLIPPED " + one) + over.slice(0, 20).map(func(one: String) -> String: return "DRAWN OVER " + one):
		print("PROBE " + sentence)
