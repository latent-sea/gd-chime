extends RefCounted

const GdChime := preload("res://addons/gd_chime/gd_chime.gd")
const Hands := preload("res://tests/hands.gd")
const Operations := preload("res://demo/apps/console/operations.gd")
const Network := preload("res://demo/apps/console/network.gd")

## The operations console walked and judged, run by it with --probe and by
## checks/stalls_probe.py: everything the brief asks of a real-time console,
## done through the doors a reader's hands use, and then every arrangement
## looked at in three window shapes.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Walked: five hundred devices on the wall and events arriving at about two
## hundred a second; one device changing draws its one tile's mark and lays
## nothing out; the stream paused - nothing handed on, the events held, the
## status line saying so - and resumed, the held caught up on; the log and
## the incidents scrolled away, holding still as entries arrive and saying
## how many are new, the focus kept, then following again; an incident
## inspected in a pop-up while the stream runs on behind it, and a device
## from its tile; an alert standing in the tray, never more than one.
## Judged: the console and each pop-up over it, at 1920x1080, 1280x800 and
## 720x1280, for words cut off and anything drawn over anything else.

const SHAPES: Array[Vector2i] = [Vector2i(1920, 1080), Vector2i(1280, 800), Vector2i(720, 1280)]

var _app: SceneTree
var _hands: Hands
var _said: Dictionary = {}


func _init(app: SceneTree) -> void:
	_app = app
	_hands = Hands.new(app)


## The walk: every claim kept by name, all said, and the app quit on the answer.
func run() -> void:
	await _hands.seconds(3.0)
	var operations: Operations = _app.operations
	var stream: GdChime.Stream = _app.stream
	var tiles := _marks(_app.root)
	_said["five_hundred_devices"] = operations.devices.get_keys().size() == Network.COUNT and tiles.size() >= Network.COUNT
	var began: int = stream.handed_count
	await _hands.seconds(2.0)
	var rate := (stream.handed_count - began) / 2.0
	_said["streaming"] = rate > 120.0 and rate < 280.0 and stream.get_connection() == GdChime.Stream.CONNECTED
	await _one_tile(operations)
	await _paused(stream)
	await _feeds_hold(operations)
	await _inspected(operations, stream)
	_said["one_alert_at_a_time"] = _app.notifications.get_standing().size() <= 1 and operations.notices.folded_count >= 0
	await _whole()
	var failed: Array = _said.keys().filter(func(claim: String) -> bool: return not _said[claim])
	print("PROBE %s" % [_said])
	print("PROBE " + ("OK" if failed.is_empty() else "FAILED %s" % [failed]))
	_app.quit(0 if failed.is_empty() else 1)


## Every status mark's canvas under this node, in tree order.
static func _marks(node: Node) -> Array:
	var found: Array = []
	# every child, kept if a status mark's canvas, searched within either way
	for child: Node in node.get_children():
		if child is Control and (child as Control).theme_type_variation == &"StatusMark" and child.has_method(&"refresh"):
			found.append(child)
		found.append_array(_marks(child))
	return found


## The stream paused so nothing else moves; one device set; only its tile's mark drawn again, and the wall not placed.
func _one_tile(operations: Operations) -> void:
	_hands.does(GdChime.Chimes.GLOBAL, GdChime.Stream.HOLDS, {"on": true})
	await _hands.plain_frames(4)
	var tiles := _tiles(_app.root)
	var marks: Array = tiles.map(func(tile: Control) -> Control: return _marks(tile)[0])
	var drawn: Array = marks.map(func(mark: Control) -> int: return mark.refresh_count)
	var wall: Container = tiles[0].get_parent()
	var placed: int = wall.arrange_count
	var device := 7
	var status: String = Network.OFFLINE if operations.devices.get_item(device)["status"] != Network.OFFLINE else Network.HEALTHY
	operations.devices.set_field(device, &"status", status)
	await _hands.plain_frames(3)
	var again: Array = range(marks.size()).filter(func(at: int) -> bool: return marks[at].refresh_count != drawn[at])
	_said["one_device_one_tile"] = tiles.size() == Network.COUNT and again == [device] and wall.arrange_count == placed
	_hands.does(GdChime.Chimes.GLOBAL, GdChime.Stream.HOLDS, {"on": false})
	await _hands.plain_frames(2)


## Every tile of the wall, in order: a press inspecting a device.
static func _tiles(node: Node) -> Array:
	var found: Array = []
	# every child, kept if a tile, searched within otherwise
	for child: Node in node.get_children():
		if child.get(&"action") == Operations.INSPECTS_DEVICE and (child as Control).theme_type_variation == &"WallTile":
			found.append(child)
		else:
			found.append_array(_tiles(child))
	return found


## Paused: nothing handed on, the events held and said; resumed: caught up on.
func _paused(stream: GdChime.Stream) -> void:
	_hands.does(GdChime.Chimes.GLOBAL, GdChime.Stream.HOLDS, {"on": true})
	var handed: int = stream.handed_count
	await _hands.seconds(1.5)
	var held := stream.get_held()
	var still: bool = stream.handed_count == handed and held > 100
	_said["pause_holds_and_says_so"] = still and _hands.shows_words_beginning("Paused:")
	_hands.does(GdChime.Chimes.GLOBAL, GdChime.Stream.HOLDS, {"on": false})
	var frames := 0
	# a frame at a time, as the stream catches up a frame's share at a time, until every held event is handed on
	while stream.handed_count < handed + held and frames < 120:
		await _app.process_frame
		frames += 1
	_said["resume_catches_up"] = stream.handed_count >= handed + held and stream.get_held() == 0


## The log and the incidents scrolled away hold still and count what is new; the focus stays; followed again.
func _feeds_hold(operations: Operations) -> void:
	var log: GdChime.Feed = operations.log
	var list := _list_of(_app.root, log)
	list.grab_focus()
	_hands.does(_app.LOG, GdChime.LongList.SCROLL_ROWS, {"by": -6})
	await _hands.plain_frames(2)
	var shown: Array = list.get_slots().map(func(slot: Control) -> Variant: return slot.get_rect())
	var first := log.get_first()
	await _hands.seconds(1.0)
	_said["log_holds_and_counts"] = log.get_first() == first and not log.get_following() and log.get_unseen() > 50 and _hands.words().any(func(one: String) -> bool: return one.ends_with("new - show the newest"))
	_said["focus_kept"] = _hands.focused() == list and list.get_slots().map(func(slot: Control) -> Variant: return slot.get_rect()) == shown
	_hands.does(_app.LOG, GdChime.Feed.FOLLOWS)
	await _hands.plain_frames(3)
	_said["log_follows_again"] = log.get_following() and log.get_first() >= log.count() - log.get_showing() - 5


## An incident inspected while the stream runs; closed; a device from its tile.
func _inspected(operations: Operations, stream: GdChime.Stream) -> void:
	_hands.does(_app.CONSOLE, GdChime.Feed.MOVES, {"by": -1})
	var on: Variant = operations.incidents.get_entry()
	_hands.does(_app.CONSOLE, Operations.INSPECTS_INCIDENT)
	await _hands.plain_frames(3)
	var handed: int = stream.handed_count
	await _hands.seconds(1.0)
	_said["incident_inspected_while_streaming"] = on != null and _app.driver.get_top().has(_app.view.incident.get_place()) and stream.handed_count > handed + 100 and operations.get_inspected()["name"] == on["name"]
	_hands.does(_app.view.incident.get_place(), _app.ui.CLOSES)
	await _hands.plain_frames(3)
	_said["closed_back_to_the_console"] = not _app.driver.get_top().has(_app.view.incident.get_place()) and stream.get_open()
	await _hands.plain_frames(3)
	_said["log_still_following_after"] = operations.log.get_following()
	_hands.does(_app.CONSOLE, GdChime.Feed.LETS_GO)
	_hands.does(_app.CONSOLE, Operations.INSPECTS_DEVICE, {"device": 42})
	await _hands.plain_frames(3)
	_said["device_inspected"] = _app.driver.get_top().has(_app.view.device.get_place()) and operations.get_inspected()["name"] == "D-042"
	_hands.does(_app.view.device.get_place(), _app.ui.CLOSES)
	await _hands.plain_frames(3)


## The virtual list showing this feed, under this node.
static func _list_of(node: Node, feed: GdChime.Feed) -> Control:
	# every child, itself the list or searched within
	for child: Node in node.get_children():
		if child.has_method(&"get_slots") and child.get(&"_list") == feed:
			return child
		var within := _list_of(child, feed)
		if within != null:
			return within
	return null


## The console and every pop-up at every shape, judged for words cut off and for anything drawn over.
func _whole() -> void:
	var cut: Array[String] = []
	var over: Array[String] = []
	_app.ui.motion.still = true
	_app.ui.motion.step(10.0)
	# every shape, each judged alike
	for shape: Vector2i in SHAPES:
		_app.root.size = shape
		await _hands.judged(&"the console", shape, cut, over)
		# every pop-up, raised over the console, judged, and taken down
		for overlay: StringName in [_app.view.incident.get_place(), _app.view.device.get_place()]:
			_hands.does(GdChime.Chimes.GLOBAL, GdChime.Driver.GO, {"place": overlay})
			await _hands.judged(overlay, shape, cut, over)
			_hands.does(GdChime.Chimes.GLOBAL, GdChime.Driver.GOES_BACK, {})
	_said["no_clipped_text"] = cut.is_empty()
	_said["nothing_drawn_over"] = over.is_empty()
	_said["words_stand_out"] = _hands.get_faint().is_empty()
	_hands.say_every(cut, over)
