extends RefCounted

const GdChime := preload("res://addons/gd_chime/gd_chime.gd")
const Hands := preload("res://tests/hands.gd")
const DashboardView := preload("res://demo/apps/dashboard/dashboard_view.gd")

## The dashboard walked and reported: run by dashboard.gd started with
## --probe, and by checks/stalls_probe.py over every application.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## What the dashboard was asked to do, claim by claim: the figures land and are what a
## pass over the incidents finds; pressing a region on the map filters every
## figure and pressing it again restores them; a bar filters as the map does;
## the keys reach every region; each stretch pressed - today, 7 days, 30
## days, custom days - moves every figure, the map and the charts, the
## stretch before following; a figure pressed opens the very rows it counted
## in the data grid, the stretch's, and a bar's region does too; the storm's region is an
## alert in the tray; a stretch with no incidents says so on every figure;
## the areas re-flow for a window on its end. Then the whole at three window
## shapes, the drill's pop-up raised over it, judged for words cut off and
## for anything drawn over anything else.

const SHAPES: Array[Vector2i] = [Vector2i(1920, 1080), Vector2i(1280, 800), Vector2i(720, 1280)]
const PATIENCE := 900
## Every claim, false until the walk shows it.
const CLAIMS := ["figures_land", "region_filters_everything", "pressed_again_restores", "a_bar_filters_as_the_map_does", "keys_reach_every_region", "every_stretch_moves_every_figure", "the_stretch_before_follows", "nothing_says_so", "a_figure_opens_its_rows", "a_bars_region_opens_its_rows", "storm_is_an_alert", "reflows_on_its_end", "no_clipped_text", "nothing_drawn_over", "words_stand_out"]

var _app: SceneTree
var _hands: Hands
var _said: Dictionary = {}


func _init(app: SceneTree) -> void:
	_app = app
	_hands = Hands.new(app)
	# every claim, false until shown
	for claim: String in CLAIMS:
		_said[claim] = false


func _do(action: StringName, payload: Dictionary = {}) -> GdChime.Phrase:
	return _hands.does(_app.BOARD, action, payload)


## Frames until neither the figures nor the drill's grid have anything out.
func _landed() -> void:
	var frames := 0
	# a frame at a time, at least two, until nothing is out
	while frames < PATIENCE:
		await _app.process_frame
		frames += 1
		if frames > 2 and not _app.measures.get_busy() and not _app.behind.view.get_busy():
			break
	# two frames more, for what the answer moved to be drawn
	for drawn: int in 2:
		await _app.process_frame


## Every figure now against a rollup of the incidents under these clauses, by hand-made filter.
func _figures_are(base: Array) -> bool:
	return _app.measures.get_figures() == GdChime.Rollup.run(_app.rows, _app.SPEC, base, _app.filters.stretch.get_stretches(), {"opens": &"reported", "closes": &"restored"})["figures"]


## The comparison's toggle: the one local press wearing a toggle's look (dashboard_view.gd).
func _comparison() -> GdChime.PressLocal:
	return _app.root.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is GdChime.PressLocal and part.theme_type_variation in [GdChime.Pressables.TOGGLE_ON, GdChime.Pressables.TOGGLE_OFF])[0]


## Every press showing now that wears this look: a map's pin and a chart's
## bar pick the same region, so which is which is what they are drawn as.
func _wearing(variation: StringName) -> Array:
	return _app.root.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is GdChime.Pressable and part.theme_type_variation == variation and _hands.shown(part))


## The one press of that look picking this region.
func _picks_region(variation: StringName, region: String) -> GdChime.Pressable:
	return _wearing(variation).filter(func(press: GdChime.Pressable) -> bool: return press.payload() == {"picked": region})[0]


## The press on screen carrying this payload for this action.
func _press_of(action: StringName, payload: Dictionary) -> GdChime.Pressable:
	return _hands.press_of(action, {carrying = payload})


## The walk: every claim kept by name, all said, and the app quit on the answer.
func run() -> void:
	# a few frames, for the app to be entered and the figures to land
	for wait: int in 4:
		await _app.process_frame
	await _landed()
	var reported: int = GdChime.RowQuery.run(_app.rows, GdChime.Rollup.within(&"reported", _app.filters.stretch.get_stretches()["now"]), {}, &"")["order"].size()
	_said["figures_land"] = _app.measures.get_landed() and _app.measures.get_figures()[&"reported"]["now"] == float(reported) and _figures_are([])
	var everywhere: Dictionary = _app.measures.get_figures()
	var pin := _picks_region(GdChime.RegionMap.PIN, "North West")
	pin.pressed()
	await _landed()
	var north_west := [{"column": &"region", "test": GdChime.RowQuery.IS, "value": ["North West"]}]
	var bars_all: bool = _app.measures.get_splits()[&"by_region"].size() == 9
	_said["region_filters_everything"] = _app.filters.get_chosen(&"region") == "North West" and _figures_are(north_west) and _app.measures.get_figures() != everywhere and bars_all and pin.is_current()
	pin.pressed()
	await _landed()
	_said["pressed_again_restores"] = _app.filters.get_chosen(&"region") == "" and _app.measures.get_figures() == everywhere
	_picks_region(&"BarChartBar", "Wales").pressed()
	await _landed()
	_said["a_bar_filters_as_the_map_does"] = _app.filters.get_chosen(&"region") == "Wales" and _figures_are([{"column": &"region", "test": GdChime.RowQuery.IS, "value": ["Wales"]}])
	_do(GdChime.Filters.REMOVES, {"id": _app.filters.get_chips()[0]["id"]})
	await _landed()
	_said["keys_reach_every_region"] = _reached(pin) == 9
	await _stretches()
	await _drills()
	_said["storm_is_an_alert"] = _app.notifications.get_standing().any(func(one: Dictionary) -> bool: return one["payload"] == {"picked": "North West"} and str(one["words"]).begins_with("North West"))
	await _whole()
	var failed: Array = _said.keys().filter(func(claim: String) -> bool: return not _said[claim])
	print("PROBE %s" % [_said])
	print("PROBE " + ("OK" if failed.is_empty() else "FAILED %s" % [failed]))
	_app.quit(0 if failed.is_empty() else 1)


## How many regions' presses the keys walk to from this one.
func _reached(from: Control) -> int:
	var pins: Array = _wearing(GdChime.RegionMap.PIN)
	var reached: Dictionary = {from: true}
	var waiting: Array = [from]
	# from every press reached, each way the keys go, until nothing new is reached
	while not waiting.is_empty():
		var at: Control = waiting.pop_back()
		# every side, the press the keys would walk to
		for side: Side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			var to: Control = at.find_valid_focus_neighbor(side)
			if to != null and pins.has(to) and not reached.has(to):
				reached[to] = true
				waiting.append(to)
	return reached.size()


## What every figure, the map and the charts read now: each figure's value, the map's, and each chart's days.
func _reading() -> Array:
	var figures: Dictionary = _app.measures.get_figures()
	return figures.keys().map(func(name: StringName) -> Variant: return figures[name]["now"]) + [_app.measures.get_splits()[&"cut_off_by_region"].map(func(one: Dictionary) -> float: return one["now"]), figures[&"reported"]["days"].size()]


## Each stretch pressed as a reader presses it - today, 7 days, 30 days,
## then days set by hand - moves every figure, the map and the charts, the
## stretch before following; then a stretch with nothing in it says so.
func _stretches() -> void:
	_comparison().pressed()
	var readings: Array = []
	# every preset, its segment pressed, what everything reads then kept
	for stretch: StringName in [DashboardView.TODAY, DashboardView.WEEK, DashboardView.MONTH]:
		_press_of(GdChime.Stretch.PICKS, {"value": stretch}).pressed()
		await _landed()
		readings.append(_reading() if _figures_are([]) else [])
	var today: int = _app.filters.stretch.get_today()
	_press_of(GdChime.Stretch.PICKS, {"value": DashboardView.BY_HAND}).pressed()
	_do(GdChime.Stretch.SETS_FIRST_DAY, {"value": today - 20})
	_do(GdChime.Stretch.SETS_LAST_DAY, {"value": today - 14})
	await _landed()
	readings.append(_reading() if _figures_are([]) else [])
	# every stretch against the one before it, each of their readings apart
	var moved := range(1, readings.size()).all(func(at: int) -> bool: return not readings[at].is_empty() and range(readings[at].size()).all(func(one: int) -> bool: return readings[at][one] != readings[at - 1][one]))
	_said["every_stretch_moves_every_figure"] = moved and readings.map(func(reading: Array) -> Variant: return reading[-1] if not reading.is_empty() else null) == [1, 7, 30, 7]
	_said["the_stretch_before_follows"] = _hands.texts().has("The 7 days before") and _hands.texts().any(func(words: String) -> bool: return words.contains("on the 7 days before"))
	_do(GdChime.Stretch.SETS_FIRST_DAY, {"value": today - 130})
	_do(GdChime.Stretch.SETS_LAST_DAY, {"value": today - 120})
	await _landed()
	_said["nothing_says_so"] = _app.measures.get_figures()[&"reported"]["now"] == 0.0 and _hands.texts().has("Nothing was repaired") and _hands.texts().has("No incidents in this stretch") and _hands.texts().has("Nobody was cut off in this stretch")
	_press_of(GdChime.Stretch.PICKS, {"value": DashboardView.MONTH}).pressed()
	_comparison().pressed()
	await _landed()


## A figure's rows, and a bar's region's rows, in the drill's grid.
func _drills() -> void:
	var card := _press_of(GdChime.Drills.SHOWS_ROWS_BEHIND, {"figure": &"reported"})
	card.pressed()
	await _landed()
	var up: bool = _app.driver.get_top().has(_app.drill.get_place())
	_said["a_figure_opens_its_rows"] = up and float(_app.behind.view.get_kept()) == _app.measures.get_figures()[&"reported"]["now"]
	_hands.does(GdChime.Chimes.GLOBAL, GdChime.Driver.GOES_BACK, {})
	await _landed()
	_do(GdChime.Drills.SHOWS_ROWS_BEHIND, {"picked": "London"})
	await _landed()
	var london: Dictionary = _app.measures.get_splits()[&"by_region"].filter(func(one: Dictionary) -> bool: return one["key"] == "London")[0]
	_said["a_bars_region_opens_its_rows"] = float(_app.behind.view.get_kept()) == london["now"] and _app.driver.get_top().has(_app.drill.get_place())


## The dashboard and the drill at every shape, each judged for words cut off and for anything drawn over.
func _whole() -> void:
	var cut: Array[String] = []
	var over: Array[String] = []
	var worn: Array = []
	_app.ui.motion.still = true
	_app.ui.motion.step(10.0)
	# every shape, each judged alike
	for shape: Vector2i in SHAPES:
		_app.root.size = shape
		await _judged_here(&"the dashboard", shape, cut, over)
		worn.append((_app.root.find_children("*", "Container", true, false).filter(func(part: Node) -> bool: return part is GdChime.Areas)[0] as GdChime.Areas).get_worn())
		_hands.does(_app.BOARD, GdChime.Drills.SHOWS_ROWS_BEHIND, {"figure": &"cut_off"})
		await _judged_here(_app.drill.get_place(), shape, cut, over)
		_hands.does(GdChime.Chimes.GLOBAL, GdChime.Driver.GOES_BACK, {})
	_said["reflows_on_its_end"] = worn == [&"wide", &"wide", &"narrow"]
	_said["no_clipped_text"] = cut.is_empty()
	_said["nothing_drawn_over"] = over.is_empty()
	_said["words_stand_out"] = _hands.get_faint().is_empty()
	_hands.say_every(cut, over)


## Judged once the figures this shape set going again have landed.
func _judged_here(showing: StringName, shape: Vector2i, cut: Array[String], over: Array[String]) -> void:
	await _landed()
	await _hands.judged(showing, shape, cut, over)
