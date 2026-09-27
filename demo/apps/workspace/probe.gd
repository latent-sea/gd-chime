extends RefCounted

const GdChime := preload("res://addons/gd_chime/gd_chime.gd")
const Hands := preload("res://tests/hands.gd")
const Workbench := preload("res://demo/apps/workspace/workbench.gd")

## The workspace walked and judged, run by it with --probe and by
## checks/stalls_probe.py: everything the brief asks of a desktop-style
## command centre, done through the same doors a reader's hands use, and
## then every arrangement looked at in three window shapes.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Walked: three queries opened and one run, its rows answered; Ctrl+K
## raising the palette, typing narrowing 2,400 datasets, Enter showing the
## first; a right press on a dataset of the explorer opening its menu and
## a pick previewing it in a new query; the explorer's grip dragged and
## the explorer folded by Ctrl+B and the results expanded by Shift+F11; and
## the settings file read back by a fresh set of models, which stand as
## this run left them - the layout restored on the next launch. Judged: the
## workspace, the palette over it and a menu over it, at 1920x1080,
## 1280x800 and 720x1280, for words cut off and anything drawn over
## anything else (clipped_text.gd, drawn_over.gd).

const SHAPES: Array[Vector2i] = [Vector2i(1920, 1080), Vector2i(1280, 800), Vector2i(720, 1280)]

var _app: SceneTree
var _hands: Hands
var _said: Dictionary = {}


func _init(app: SceneTree) -> void:
	_app = app
	_hands = Hands.new(app)


func _do(action: StringName, payload: Dictionary = {}) -> GdChime.Phrase:
	return _hands.does(GdChime.Chimes.GLOBAL, action, payload)


## The walk: every claim, then every shape; said, and the application quit on the answer.
func run() -> void:
	await _hands.frames(4)
	# walked at the base the project is written at, as a desktop's window, once the window stands
	_app.root.size = SHAPES[0]
	await _hands.frames(4)
	var driver: GdChime.Driver = _app.driver
	_said["places"] = [&"workspace", _app.palette.get_place(), _app.ui.menu_place].all(func(named: StringName) -> bool: return _hands.has_place(named))
	# three saved queries opened, the last in front, and run
	for named: String in ["daily_revenue.sql", "top_customers.sql", "late_shipments.sql"]:
		_do(GdChime.Documents.OPENS, {"value": named})
	await _hands.key(KEY_F5)
	var ran: Dictionary = _app.bench.get_results()
	_said["tabs_and_run"] = _app.documents.get_open().size() == 3 and _app.documents.get_front() == "late_shipments.sql" and ran["ran"] and ran["rows"].size() == 100 and ran["columns"].size() == 4
	await _notified()
	await _hands.key(KEY_K, "", [&"ctrl"])
	var raised: bool = driver.get_top().has(_app.palette.get_place())
	_app.commands.dispatch(_app.palette.get_place(), GdChime.CommandSearch.TYPES, {"line": "orders_2024"})
	var found: int = _app.search.get_count()
	await _hands.key(KEY_ENTER)
	_said["palette"] = raised and found == 20 and _app.bench.get_shown() == "sales.orders_2024" and not driver.is_raised()
	await _menu()
	await _layout()
	_said["restored"] = _restored()
	# the results back, so every shape is judged with all four panes and rows in them
	await _hands.key(KEY_J, "", [&"ctrl"])
	await _whole()
	var failed: Array = _said.keys().filter(func(claim: String) -> bool: return not _said[claim])
	print("PROBE %s" % [_said])
	print("PROBE " + ("OK" if failed.is_empty() else "FAILED %s" % [failed]))
	_app.quit(0 if failed.is_empty() else 1)


## The run says so in the shell's tray; results folded, its offer brings them back and the notice goes.
func _notified() -> void:
	var standing: Array = _app.notifications.get_standing()
	var said: bool = standing.size() == 1 and standing[0]["offer"] == Workbench.SHOWS_RESULTS and str(standing[0]["words"]).contains("late_shipments.sql finished")
	var offer := _hands.saying("Show the results")
	said = said and offer != null
	await _hands.key(KEY_J, "", [&"ctrl"])
	var folded: bool = not _app.panels.is_shown(&"results")
	var press: Node = offer
	# up from the offer's words to the press they are on
	while not press.has_method(&"payload"):
		press = press.get_parent()
	press.pressed()
	await _hands.frames()
	# the notice answered has gone, and its words with it
	_said["notified"] = said and folded and _app.panels.is_shown(&"results") and _app.notifications.get_standing().is_empty()


## A right press on a dataset of the explorer opens its menu, and a pick of
## preview makes a new query of it and runs it.
func _menu() -> void:
	var row := _hands.saying("ops.shipments")
	await _hands.right_click(row)
	var items: Array = _app.menu.items_of(_app.driver.get_parameter(_app.ui.menu_place))
	var up: bool = _app.driver.get_top() == [_app.ui.menu_place] and items.map(func(item: Dictionary) -> StringName: return item["action"]) == [Workbench.PREVIEWS, Workbench.SHOWS, Workbench.PUTS_IN]
	_hands.does(_app.ui.menu_place, GdChime.OpenMenu.PICKS, {"item": items[0]})
	await _hands.frames()
	_said["context_menu"] = up and not _app.driver.is_raised() and str(_app.documents.get_front()).begins_with("query_") and _app.bench.get_results()["columns"].size() == 5


## The explorer's grip dragged a hundred pixels, the explorer folded by its
## key and the results expanded by theirs, and back.
func _layout() -> void:
	var grip: Control = _hands.saying("ops.shipments").get_parent()
	# up from a row of the explorer to the split whose first pane holds it
	while not grip.has_method(&"get_placed_share"):
		grip = grip.get_parent()
	grip = grip.get_child(1)
	var before: float = _app.panels.share(&"outer").read()
	var at := _hands.middle_of(grip)
	await _hands.drag(at, at + Vector2(100, 0))
	var dragged: bool = _app.panels.share(&"outer").read() > before
	await _hands.key(KEY_B, "", [&"ctrl"])
	var folded: bool = not _app.panels.is_shown(&"explorer")
	await _hands.key(KEY_F11, "", [&"shift"])
	var alone: bool = _app.panels.get_expanded() == &"results" and not _app.panels.is_shown(&"editor")
	await _hands.key(KEY_F11, "", [&"shift"])
	await _hands.key(KEY_B, "", [&"ctrl"])
	_said["layout"] = dragged and folded and alone and _app.panels.is_shown(&"explorer") and _app.panels.is_shown(&"editor")
	# folded again, so the run ends with a layout a fresh run must find
	await _hands.key(KEY_J, "", [&"ctrl"])


## A fresh set of models over the same file stands as this run left them.
func _restored() -> bool:
	_app.settings.write()
	var chimes: GdChime.Chimes = GdChime.Chimes.new(GdChime.Belfry.new())
	var bench := Workbench.new(chimes, _app.notifications, _app.bench.table)
	var panels := GdChime.Panels.new(chimes, {&"outer": 0.5, &"rest": 0.5, &"centre": 0.5}, {&"explorer": [&"outer", GdChime.Panels.FIRST], &"rest": [&"outer", GdChime.Panels.SECOND], &"centre": [&"rest", GdChime.Panels.FIRST], &"schema": [&"rest", GdChime.Panels.SECOND], &"editor": [&"centre", GdChime.Panels.FIRST], &"results": [&"centre", GdChime.Panels.SECOND]})
	var file := GdChime.SettingsFile.new(chimes, _app.settings.get_file_path())
	file.keep("queries", bench)
	file.keep("documents", bench.documents)
	file.keep("panels", panels)
	# the two panels as text with their keys in order: a dictionary read back from a file holds them in the file's
	var same: bool = JSON.stringify(panels.saved(), "", true) == JSON.stringify(_app.panels.saved(), "", true) and bench.documents.saved() == _app.documents.saved() and not panels.is_shown(&"results")
	# the queries open are the workbench's own child and go with it
	for made: Node in [bench, panels, file]:
		made.free()
	return same


## Every shape: the workspace, the palette over it and a menu over it, judged for words cut and things drawn over.
func _whole() -> void:
	var cut: Array[String] = []
	var over: Array[String] = []
	_app.ui.motion.still = true
	_app.ui.motion.step(10.0)
	# every shape, each judged alike
	for shape: Vector2i in SHAPES:
		_app.root.size = shape
		await _hands.judged(&"the workspace", shape, cut, over)
		_do(GdChime.Driver.GO, {"place": _app.palette.get_place()})
		_app.commands.dispatch(_app.palette.get_place(), GdChime.CommandSearch.TYPES, {"line": "sales"})
		await _hands.judged(&"the palette", shape, cut, over)
		_do(GdChime.Driver.GOES_BACK)
		await _hands.right_click(_hands.saying("finance.invoices"))
		await _hands.judged(&"a menu", shape, cut, over)
		_do(GdChime.Driver.GOES_BACK)
	_said["no_clipped_text"] = cut.is_empty()
	_said["nothing_drawn_over"] = over.is_empty()
	_said["words_stand_out"] = _hands.get_faint().is_empty()
	_hands.say_every(cut, over)
