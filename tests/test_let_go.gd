extends SceneTree

## What must be true of an application let go while everything else goes on
## (chime_app.gd let_go, take_down.gd): a big one, hidden and stopped, is
## taken down a share of each frame at a time, never in one long frame as
## freeing it whole is; everything it built is freed in the end, and the app
## with it; the moment it is let go nothing it built holds a wire to a bell,
## so its bells rung every frame it is taken down reach nothing and nothing is
## said out loud; and the same app stood again beside it while
## it goes stands and answers its own presses, the first still going.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_let_go.gd

const ChimeApp := preload("res://addons/gd_chime/chime_app.gd")
const Fixture := preload("res://tests/fixture.gd")
const Verdict := preload("res://tests/verdict.gd")
const Actions := preload("res://addons/gd_chime/actions.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")

const PRESSES := &"presses"
## Rows of the app's one big screen: each a press and a word its model's bell holds, thousands of nodes in all.
const ROWS := 400
## The share of a frame the take-down may spend, in milliseconds.
const BUDGET_MSEC := 4.0
const PATIENCE_FRAMES := 2000


## An app of one big screen, each row a press and a word that follows its model's bell.
class Big extends ChimeApp:
	var counter: Fixture.Model

	func declare(register: Actions) -> void:
		register.declare_all({PRESSES: ["press"]})

	func describe() -> Desc:
		counter = Fixture.Model.new(chimes, &"home")
		counter.answering = [PRESSES]
		var rows: Array = []
		# each row: a press and the word the bell holds
		for row: int in ROWS:
			rows.append(ui.column([ui.pressable(PRESSES, {"row": row}, [ui.text("press")]).named(StringName("press %d" % row)), ui.text(counter.of(&"said", "nothing yet"))]))
		return ui.app(&"app", [ui.screen(&"home", [ui.scroll(ui.column(rows)).grow()], counter)])


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
	await _verdict.states(_a_big_app_let_go_is_taken_down_a_share_of_each_frame_and_all_of_it_freed)
	await _verdict.states(_the_same_app_stood_again_while_the_first_goes_stands_and_answers_its_own)
	OS.remove_logger(_hearing)
	quit(_verdict.deliver(get_script()))


## A Big app stood under the root, its frames passed until it stands.
func _stood() -> Big:
	var app := Big.new()
	app.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(app)
	# frames until the app stands and is laid out
	for frame: int in 4:
		await process_frame
	return app


## `app` hidden, stopped and let go, as a host lets a game go.
func _let_go(app: Big) -> void:
	app.visible = false
	app.process_mode = Node.PROCESS_MODE_DISABLED
	app.let_go(BUDGET_MSEC)


func _a_big_app_let_go_is_taken_down_a_share_of_each_frame_and_all_of_it_freed() -> void:
	var whole: Big = await _stood()
	var began := Time.get_ticks_usec()
	root.remove_child(whole)
	whole.free()
	var whole_msec := (Time.get_ticks_usec() - began) / 1000.0
	var app: Big = await _stood()
	var built: Array = app.find_children("*", "", true, false)
	var bell: RefCounted = app.counter.of(&"said")
	var heard := _hearing.said.size()
	var longest := 0.0
	var frames := 0
	var chimes: RefCounted = app.chimes
	var wired: int = chimes.count_listeners()
	_let_go(app)
	var wired_after: Array = built.filter(func(node: Node) -> bool: return chimes._wires._held.has(node))
	var last := Time.get_ticks_usec()
	# each frame while it is taken down: its bell rung, the frame timed
	while is_instance_valid(app) and frames < PATIENCE_FRAMES:
		bell.set_value("rung %d" % frames)
		await process_frame
		longest = maxf(longest, (Time.get_ticks_usec() - last) / 1000.0)
		last = Time.get_ticks_usec()
		frames += 1
	_verdict.check(built.size() > ROWS * 4 and whole_msec > BUDGET_MSEC * 4,
		"freed whole, the app is a long frame of its own, or this proves nothing: %d nodes in %.1f ms" % [built.size(), whole_msec])
	_verdict.check(frames > 2 and longest < whole_msec / 2.0,
		"let go, it is taken down over %d frames, the longest %.1f ms, under half the %.1f ms of freeing it whole" % [frames, longest, whole_msec])
	_verdict.check(not is_instance_valid(app) and built.all(func(node: Variant) -> bool: return not is_instance_valid(node)),
		"and in the end the app and everything it built are freed: %d of %d still stand" % [built.filter(func(node: Variant) -> bool: return is_instance_valid(node)).size(), built.size()])
	_verdict.check(wired > 0 and wired_after.is_empty(), "let go, nothing it built holds a wire to a bell: of %d listeners, %d built still wired" % [wired, wired_after.size()])
	_verdict.check(_hearing.said.size() == heard, "its bell rung every frame it went reached nothing freed, and nothing was said out loud: %s" % [_hearing.said.slice(heard)])


func _the_same_app_stood_again_while_the_first_goes_stands_and_answers_its_own() -> void:
	var first: Big = await _stood()
	var told_first := first.counter
	var heard := _hearing.said.size()
	_let_go(first)
	var again: Big = await _stood()
	var going := is_instance_valid(first)
	again.ui.node_named(&"press 7").pressed()
	await process_frame
	_verdict.check(going and again.counter.told_actions == [PRESSES],
		"stood again while the first is still being taken down, the app stands and answers its own press: going %s, told %s" % [going, again.counter.told_actions])
	var frames := 0
	# frames until the first is gone
	while is_instance_valid(first) and frames < PATIENCE_FRAMES:
		await process_frame
		frames += 1
	again.ui.node_named(&"press 9").pressed()
	await process_frame
	_verdict.check(not is_instance_valid(first) and not is_instance_valid(told_first) and again.counter.told_actions == [PRESSES, PRESSES],
		"and the first goes in the end, its model with it, the second answering as before: %s" % [again.counter.told_actions])
	_verdict.check(_hearing.said.size() == heard, "with nothing said out loud: %s" % [_hearing.said.slice(heard)])
	again.queue_free()
	await process_frame
