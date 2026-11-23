extends SceneTree

## What must be true of an application built over frames (chime_app.gd
## builds_over_msec, built_over_frames.gd), beside the same app built at once:
##   - what it built joins the tree a share of each frame at a time: no frame
##     is near as long as the one the app built at once enters in. Judged on
##     the best of PAIRS pairs, each the app built at once and then over
##     frames, alone in the tree one after the other: a share too big is in
##     every pair, while a machine loaded by other work stretches one frame
##     of one pair or another (six of these at once on four cores, 23 Nov:
##     a pair at 0.59, the best of each run's three never above 0.39);
##   - it is not started until all of it has joined: no first move is made;
##   - nothing is said out loud as it joins: a layout keeps what it was given
##     for each part that joins it late;
##   - built, it stands as the one built at once does: the same places in the
##     index, the reader at the same place, the focus on the same control;
##     moved away, Back brings the reader home as it does there;
##   - finished at once while it is being built, it is built and started now,
##     whole: as many nodes as the one built at once, the reader arrived;
##   - freed while it is being built, nothing it built is left standing.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_built_over_frames.gd

const ChimeApp := preload("res://addons/gd_chime/chime_app.gd")
const Fixture := preload("res://tests/fixture.gd")
const Verdict := preload("res://tests/verdict.gd")
const Actions := preload("res://addons/gd_chime/actions.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")

const PRESSES := &"presses"
const GOES_AWAY := &"goes_away"
## Rows of the home screen: each a press and a word its model's bell holds, thousands of nodes in all.
const ROWS := 400
## The share of a frame the build may spend joining, in milliseconds.
const BUDGET_MSEC := 4.0
const PATIENCE_FRAMES := 2000
## How many pairs of builds the longest frame is judged on, at once and over frames.
const PAIRS := 3


## An app of a big home screen, its first press focused as the reader arrives, and a screen away to go to and back from.
class Big extends ChimeApp:
	var counter: Fixture.Model

	func declare(register: Actions) -> void:
		register.declare_all({PRESSES: ["press"], GOES_AWAY: ["away"]})

	func describe() -> Desc:
		counter = Fixture.Model.new(chimes, &"home")
		counter.answering = [PRESSES]
		var rows: Array = [ui.button(GOES_AWAY, {goes_to = &"away"}).named(&"to_away")]
		# each row: a press and the word the bell holds
		for row: int in ROWS:
			rows.append(ui.column([ui.pressable(PRESSES, {"row": row}, [ui.text("press")]).named(StringName("press %d" % row)), ui.text(counter.of(&"said", "nothing yet"))]))
		var home := ui.screen(&"home", [ui.scroll(ui.column(rows)).grow()], counter)
		return ui.app(&"app", [home, ui.screen(&"away", [ui.text("away")])])


## Hears everything said out loud as an error.
class Hearing extends Logger:
	var said: Array[String] = []

	func _log_error(_function: String, _file: String, _line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type != ERROR_TYPE_WARNING:
			said.append("%s %s" % [code, rationale])


var _verdict := Verdict.new()
var _hearing := Hearing.new()


func _init() -> void:
	OS.add_logger(_hearing)
	await process_frame
	root.size = Vector2i(1280, 720)
	await process_frame
	await _verdict.states(_built_over_frames_it_joins_a_share_at_a_time_and_stands_as_one_built_at_once)
	await _verdict.states(_finished_at_once_while_building_it_is_whole_and_started_now)
	await _verdict.states(_freed_while_building_nothing_it_built_is_left)
	OS.remove_logger(_hearing)
	quit(_verdict.deliver(get_script()))


## A Big app under the root, built at once or over frames: [the app, the milliseconds the frame it was added in took].
func _added(over_msec: float) -> Array:
	var app := Big.new()
	app.set_anchors_preset(Control.PRESET_FULL_RECT)
	app.builds_over_msec = over_msec
	await process_frame
	var began := Time.get_ticks_usec()
	root.add_child(app)
	await process_frame
	return [app, (Time.get_ticks_usec() - began) / 1000.0]


## Frames until the reader has arrived in `app`: the frames waited, and the longest of them in milliseconds.
func _arrived(app: Big) -> Array:
	var frames := 0
	var longest := 0.0
	var last := Time.get_ticks_usec()
	# each frame until the first move has been made
	while app.driver.get_top().is_empty() and frames < PATIENCE_FRAMES:
		await process_frame
		longest = maxf(longest, (Time.get_ticks_usec() - last) / 1000.0)
		last = Time.get_ticks_usec()
		frames += 1
	# a few more, the arrival's settling done in the driver's step of the next frame
	for frame: int in 3:
		await process_frame
	return [frames, longest]


## One pair: the app built at once, then over frames, each alone in the tree and freed after: the longest frame of the
## one over frames - the one it is added in, or one it joins in - over the frame the one at once is added in.
func _longest_against_at_once() -> float:
	var at_once: Array = await _added(0.0)
	await _arrived(at_once[0])
	at_once[0].free()
	var over: Array = await _added(BUDGET_MSEC)
	var built: Array = await _arrived(over[0])
	over[0].free()
	return maxf(over[1], built[1]) / at_once[1]


## How `app` stands: the places its index holds, where the reader is, and the focused control by what it performs.
func _standing(app: Big) -> Array:
	var focused: Control = app.ui.root.get_viewport().gui_get_focus_owner()
	var performs: Array = [focused.get("action"), focused.payload()] if focused != null and focused.has_method("payload") else []
	return [app.driver.index.by_name().keys().map(func(named: StringName) -> String: return String(named)), app.driver.get_top(), performs]


func _built_over_frames_it_joins_a_share_at_a_time_and_stands_as_one_built_at_once() -> void:
	var at_once: Array = await _added(0.0)
	await _arrived(at_once[0])
	var once_stands := _standing(at_once[0])
	var heard := _hearing.said.size()
	var over: Array = await _added(BUDGET_MSEC)
	var app: Big = over[0]
	var started_early := not app.driver.get_top().is_empty()
	var built: Array = await _arrived(app)
	var over_stands := _standing(app)
	_verdict.check(at_once[1] > BUDGET_MSEC * 4, "built at once, the app enters in a long frame, or this proves nothing: %.1f ms" % at_once[1])
	_verdict.check(not started_early, "and no first move is made until all of it has joined")
	_verdict.check(_hearing.said.size() == heard, "and nothing is said out loud as it joins: %s" % [_hearing.said.slice(heard, heard + 3)])
	_verdict.check(once_stands == over_stands and not (once_stands[0] as Array).is_empty() and not (once_stands[2] as Array).is_empty(),
		"built, it stands as the one built at once: the same places, the reader at the same place, the same control focused: %s against %s" % [over_stands, once_stands])
	var back_home: Array = []
	# each app: moved away, then Back, the place it comes back to
	for one: Big in [at_once[0], app]:
		one.commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": &"away"})
		await _arrived(one)
		var away := one.driver.get_top()
		one.commands.dispatch(Chimes.GLOBAL, Driver.GOES_BACK, {})
		await _arrived(one)
		back_home.append([away, one.driver.get_top()])
	_verdict.check(back_home[0] == back_home[1] and back_home[0][0] != back_home[0][1],
		"moved away and Back, it comes home as the one built at once does: %s against %s" % [back_home[1], back_home[0]])
	for one: Big in [at_once[0], app]:
		one.free()
	var ratios: Array[float] = []
	# each pair, built at once and over frames with nothing else standing, the share of the one at once its longest frame is
	for pair: int in PAIRS:
		ratios.append(await _longest_against_at_once())
	ratios.sort()
	_verdict.check(built[0] > 2 and ratios[0] < 0.5,
		"built over frames, it joins over %d frames, and its longest frame is under half the frame of building it at once, in the best of %d pairs: %s" % [built[0], PAIRS, ratios.map(func(ratio: float) -> String: return "%.2f" % ratio)])


func _finished_at_once_while_building_it_is_whole_and_started_now() -> void:
	var at_once: Array = await _added(0.0)
	await _arrived(at_once[0])
	var whole: int = (at_once[0] as Big).find_children("*", "", true, false).size()
	var over: Array = await _added(BUDGET_MSEC)
	var app: Big = over[0]
	var partial: int = app.find_children("*", "", true, false).size()
	app.finish_building()
	await process_frame
	var started := not app.driver.get_top().is_empty()
	await _arrived(app)
	var now: int = app.find_children("*", "", true, false).size()
	_verdict.check(partial < whole and now == whole and started,
		"finished at once while being built, it is whole and started a frame later: %d of %d nodes, then %d, the reader at %s" % [partial, whole, now, app.driver.get_top()])
	for one: Big in [at_once[0], app]:
		one.free()


func _freed_while_building_nothing_it_built_is_left() -> void:
	await process_frame
	var orphans := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	var over: Array = await _added(BUDGET_MSEC)
	var app: Big = over[0]
	var partial: int = app.find_children("*", "", true, false).size()
	app.free()
	await process_frame
	var left := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	_verdict.check(partial > 0 and left == orphans, "freed while being built, nothing it built is left standing off the tree: %d orphans, %d before" % [left, orphans])
