extends SceneTree

## What must be true of models whoever sets them: a fact is a value, and a
## value cannot tell a press from a timer - so everything here moves its
## facts the way a game's own loop does, from a timer, a tick, a job
## landing or a signal, and never through a press.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_set_by_anyone.gd
##
## Proved here: a moment rises and falls at the end of the frame its fact
## moved in, whoever moved it, and a fact moving and moving back in one
## frame raises nothing; a freed model answers nothing and the model
## registered in its place answers; a place of one model tells it only what
## it answers - a press that only moves the reader reaches no model, and an
## action nobody answers is said at startup; what a place fills with is told
## only to ask again, and an answer landing after the reader left clears its
## loading; a refused change doubts its thing when a later change of it was
## sent, answered or not; a model following another's value has it by the
## end of the frame while a reading worked out from it has it at once; and a
## value set off the main thread is refused out loud and does not move.

const Fixture := preload("res://tests/fixture.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Controller := preload("res://addons/gd_chime/controller.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Reads := preload("res://addons/gd_chime/reads.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Fetched := preload("res://addons/gd_chime/fetched.gd")
const Provisional := preload("res://addons/gd_chime/provisional.gd")
const Notifications := preload("res://addons/gd_chime/notifications.gd")
const Moment := preload("res://addons/gd_chime/components/recipes/moment.gd")
const Verdict := preload("res://tests/verdict.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")

const DISMISSES := &"dismisses"
const COUNTS := &"counts"
const OPENS_LEDGER := &"opens_ledger"
const WAVES := &"waves"

var _verdict := Verdict.new()


## Keeps what the engine was told to say, so a complaint out loud is
## something a test can read.
class Complaints extends Logger:
	var said: Array[String] = []

	func _log_error(_function: String, _file: String, _line: int, code: String, rationale: String, _editor_notify: bool, _error_type: int, _traces: Array[ScriptBacktrace]) -> void:
		said.append(code if rationale.is_empty() else rationale)


## A game's own loop: each frame it runs what it was handed for that frame,
## as a market day's tick sets what the day has come to.
class Tick extends Node:
	var due: Array[Callable] = []

	func _process(_delta: float) -> void:
		# everything handed for this frame, run in order, then gone
		for work: Callable in due:
			work.call()
		due.clear()


## A tray standing for the notifications to be told to: every words fit it,
## as a tray must answer (tray_stand.gd).
class Tray extends Node:
	func fits(_words: Variant) -> bool:
		return true


## A far side that answers when the test says: each asking kept with its answer.
class FarSide extends RefCounted:
	signal answered
	var asked: Array = []  # every [request, answer] handed over, oldest first
	var read_back: Array = []  # every key read back

	func sends(request: Dictionary, answer: Callable) -> void:
		asked.append([request, answer])

	func reads(key: Variant, _answer: Callable) -> void:
		read_back.append(key)


## A model following another's value: a copy of it, taken as it moves.
class Follower extends Controller:
	var copy: Variant = null

	func _init(chimes: Chimes, followed: Value) -> void:
		super(chimes)
		follow(&"copies", func() -> void: copy = followed.read())


## A model with a reading worked out from its own value, kept with what it read.
class Takings extends Controller:
	var sold := value(1)
	var _doubled: Array = []  # the takings doubled, kept with what it read

	func get_doubled() -> int:
		return Reads.worked(_doubled, func() -> int: return sold.read() * 2)


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(600, 400)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_a_moment_rises_and_falls_at_the_end_of_the_frame_its_fact_moved_in_whoever_moved_it)
	await _verdict.states(_a_fact_moving_and_moving_back_in_one_frame_raises_nothing)
	await _verdict.states(_a_freed_model_answers_nothing_and_the_one_in_its_place_answers)
	await _verdict.states(_a_place_of_one_model_tells_it_only_what_it_answers)
	await _verdict.states(_what_a_place_fills_with_is_told_only_to_ask_again_and_a_late_answer_clears_its_loading)
	await _verdict.states(_a_refused_change_doubts_its_thing_when_a_later_change_of_it_was_sent_answered_or_not)
	await _verdict.states(_a_follower_has_a_moved_value_by_the_end_of_the_frame_and_a_worked_out_reading_has_it_at_once)
	await _verdict.states(_a_value_set_off_the_main_thread_is_refused_out_loud_and_does_not_move)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## An app with a moment presented while a model's flag holds, and the game's
## tick beside it, as {made, act, moment, tick}.
func _with_a_moment() -> Dictionary:
	var made := Fixture.new(root, {DISMISSES: "carry on"})
	var act := Fixture.Model.new(made.chimes)
	act.answering = [DISMISSES]
	made.ui.also(act)
	made.commands.stand(Chimes.GLOBAL, act)
	var moment := Moment.make(made.ui, act.of(&"flag", false), [made.ui.text("the stall is sold out")], DISMISSES)
	made.ui.start(made.ui.app(&"app", [made.ui.stack([made.ui.text("the track"), moment])]))
	var tick := Tick.new()
	root.add_child(tick)
	await _a_frame_passes()
	return {"made": made, "act": act, "moment": moment.get_place(), "tick": tick}


## The stall sells out on a timer, is restocked on the game's tick, and
## sells out again from a signal the game raises: each time the moment
## follows its fact, at the end of the frame the fact moved in, with no press.
func _a_moment_rises_and_falls_at_the_end_of_the_frame_its_fact_moved_in_whoever_moved_it() -> void:
	var standing: Dictionary = await _with_a_moment()
	var made: Fixture = standing["made"]
	var act: Fixture.Model = standing["act"]
	var tick: Tick = standing["tick"]
	_verdict.check(not made.driver.is_raised(), "while its fact does not hold, nothing stands over the app: %s" % [made.driver.get_top()])
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = 0.05
	root.add_child(timer)
	timer.timeout.connect(func() -> void: act.set_value(&"flag", true))
	timer.start()
	await timer.timeout
	await _a_frame_passes()
	_verdict.check(made.driver.get_top() == [standing["moment"]], "a timer makes its fact hold, and it is raised with nothing pressed: %s" % [made.driver.get_top()])
	tick.due.append(func() -> void: act.set_value(&"flag", false))
	await _a_frame_passes()
	_verdict.check(not made.driver.is_raised(), "the game's tick makes it stop holding, and it is lowered: %s" % [made.driver.get_top()])
	var game := FarSide.new()
	game.answered.connect(func() -> void: act.set_value(&"flag", true))
	game.answered.emit.call_deferred()
	await _a_frame_passes()
	_verdict.check(made.driver.get_top() == [standing["moment"]] and made.driver.get_state()["history"].size() == 1, "a signal the game raises makes it hold again, raised again, and no history entered: %s" % [made.driver.get_top()])
	timer.free()
	tick.free()
	made.done()


## Within one tick the fact holds and stops holding: at the end of that
## frame it does not hold, so the moment never rose, and the reader's place
## never moved.
func _a_fact_moving_and_moving_back_in_one_frame_raises_nothing() -> void:
	var standing: Dictionary = await _with_a_moment()
	var made: Fixture = standing["made"]
	var act: Fixture.Model = standing["act"]
	var tick: Tick = standing["tick"]
	var moved := Fixture.Heard.new(made.chimes, made.driver.where)
	made.ui.also(moved)
	tick.due.append(func() -> void:
		act.set_value(&"flag", true)
		act.set_value(&"flag", false))
	await _a_frame_passes()
	await _a_frame_passes()
	_verdict.check(not made.driver.is_raised() and moved.rung == 0, "held and let go in one frame, nothing rose and the reader never moved: %d moves" % moved.rung)
	tick.due.append(func() -> void: act.set_value(&"flag", true))
	await _a_frame_passes()
	_verdict.check(made.driver.get_top() == [standing["moment"]], "and holding at the end of a frame, it rises: %s" % [made.driver.get_top()])
	tick.free()
	made.done()


## A model freed answers nothing, however it was registered, and whatever
## asks is told nothing handles it; one standing in its place - registered
## while the one it replaces waits to be freed, or after - answers.
func _a_freed_model_answers_nothing_and_the_one_in_its_place_answers() -> void:
	var made := Fixture.new(root, {COUNTS: "count"})
	var complaints := Complaints.new()
	var first := Fixture.Model.new(made.chimes)
	first.answering = [COUNTS]
	made.ui.also(first)
	made.commands.stand(Chimes.GLOBAL, first)
	first.free()
	OS.add_logger(complaints)
	var answer := made.commands.dispatch(Chimes.GLOBAL, COUNTS, {})
	OS.remove_logger(complaints)
	_verdict.check(not made.commands.handles(Chimes.GLOBAL, COUNTS) and answer != null and str(answer).contains("Nothing handles"), "freed, it answers nothing, and a press of its action is refused out loud: %s" % [answer])
	var second := Fixture.Model.new(made.chimes)
	second.answering = [COUNTS]
	made.ui.also(second)
	OS.add_logger(complaints)
	made.commands.stand(Chimes.GLOBAL, second)
	OS.remove_logger(complaints)
	_verdict.check(made.commands.dispatch(Chimes.GLOBAL, COUNTS, {}) == null and second.told_actions == [COUNTS], "the model registered in its place answers: %s" % [second.told_actions])
	second.queue_free()
	var third := Fixture.Model.new(made.chimes)
	third.answering = [COUNTS]
	made.ui.also(third)
	OS.add_logger(complaints)
	made.commands.stand(Chimes.GLOBAL, third)
	OS.remove_logger(complaints)
	_verdict.check(made.commands.dispatch(Chimes.GLOBAL, COUNTS, {}) == null and third.told_actions == [COUNTS] and second.told_actions == [COUNTS], "one registered while the model it replaces waits to be freed answers in its stead: %s" % [third.told_actions])
	_verdict.check(complaints.said.size() == 1, "and only the press nobody handled was said out loud, never a replacement: %s" % [complaints.said])
	await _a_frame_passes()
	_verdict.check(made.commands.dispatch(Chimes.GLOBAL, COUNTS, {}) == null and third.told_actions == [COUNTS, COUNTS], "and it still answers once the one it replaced is gone: %s" % [third.told_actions])
	third.free()
	made.done()


## A screen handed one model that answers counting: a press opening the
## ledger moves the reader and reaches no model; and a screen declaring an
## action its one model does not answer is said at startup.
func _a_place_of_one_model_tells_it_only_what_it_answers() -> void:
	var made := Fixture.new(root, {COUNTS: "count", OPENS_LEDGER: "open the ledger"})
	var ui := made.ui
	var counter := Fixture.Model.new(made.chimes, &"home")
	counter.answering = [COUNTS]
	ui.start(ui.app(&"app", [ui.stack([ui.screen(&"home", [ui.column([ui.button(COUNTS), ui.button(OPENS_LEDGER, {goes_to = &"ledger"})])], counter), ui.screen(&"ledger", [ui.text("the ledger")])])]))
	await _a_frame_passes()
	made.commands.dispatch(&"home", COUNTS, {})
	made.commands.dispatch(&"home", OPENS_LEDGER, {})
	_verdict.check(counter.told_actions == [COUNTS] and made.driver.get_top() == [&"app", &"ledger"], "its one model is told what it answers, and a press that only moves the reader moves the reader and tells it nothing: %s" % [counter.told_actions])
	counter.free()
	made.done()
	var faults: Array = []
	var again := Fixture.new(root, {COUNTS: "count", WAVES: "wave"})
	var waver := Fixture.Model.new(again.chimes, &"home")
	waver.answering = [COUNTS]
	again.ui.start(again.ui.app(&"app", [again.ui.screen(&"home", [again.ui.column([again.ui.button(COUNTS), again.ui.button(WAVES)])], waver)]), func(wrong: Array) -> void: faults.append_array(wrong))
	await _a_frame_passes()
	_verdict.check(faults.has("nothing answers waves in home"), "an action its one model does not answer, going nowhere, is said at startup rather than swallowed: %s" % [faults])
	waver.free()
	again.done()


## What the stops screen fills with is its one model: a press opening the
## ledger never asks again, and an answer landing after the reader left
## lands nothing but no longer leaves it loading.
func _what_a_place_fills_with_is_told_only_to_ask_again_and_a_late_answer_clears_its_loading() -> void:
	var made := Fixture.new(root, {Fetched.ASKS_AGAIN: "ask again", OPENS_LEDGER: "open the ledger"})
	var ui := made.ui
	var notices := Notifications.new(made.chimes, made.commands, root)
	root.add_child(notices)
	var answers: Array[Callable] = []
	var stops: Fetched = ui.fetched(func(answer: Callable) -> void: answers.append(answer), notices, Phrase.of("The stops"))
	ui.start(ui.app(&"app", [ui.stack([ui.screen(&"stops", [ui.column([ui.button(Fetched.ASKS_AGAIN), ui.button(OPENS_LEDGER, {goes_to = &"ledger"})])], stops, {on_fill = stops.fill}), ui.screen(&"ledger", [ui.text("the ledger")])])]))
	await _a_frame_passes()
	_verdict.check(answers.size() == 1 and stops.loading.read(), "entering, it asks once and is loading: %d" % answers.size())
	made.commands.dispatch(&"stops", OPENS_LEDGER, {})
	await _a_frame_passes()
	_verdict.check(answers.size() == 1 and made.driver.get_top() == [&"app", &"ledger"], "a press opening the ledger moves the reader and asks nothing again: %d askings" % answers.size())
	var tick := Tick.new()
	root.add_child(tick)
	tick.due.append(func() -> void: answers[0].call(["the mill", "the quay"], null))
	await _a_frame_passes()
	_verdict.check(stops.data.read() == null and not stops.loading.read(), "the answer landing after the reader left lands nothing, and it is loading no longer: %s" % [stops.loading.read()])
	tick.free()
	notices.free()
	made.done()


## Two changes of one crate are sent; the later is kept first, then the
## earlier is refused: undoing the earlier undoes what the kept one stood on,
## so the crate is in doubt and read back from the far side.
func _a_refused_change_doubts_its_thing_when_a_later_change_of_it_was_sent_answered_or_not() -> void:
	var made := Fixture.new(root)
	var notices := Notifications.new(made.chimes, made.commands, root)
	root.add_child(notices)
	var tray := Tray.new()
	notices.add_tray(tray)
	var far := FarSide.new()
	var undone: Array[String] = []
	var changes := Provisional.new(made.chimes, far.sends, notices, far.reads, func(_key: Variant, _state: Variant) -> void: pass)
	made.ui.also(changes)
	changes.begin(&"crate 7", Phrase.of("Crate seven"), {"to": "the quay"}, func() -> void: undone.append("to the quay"))
	changes.begin(&"crate 7", Phrase.of("Crate seven"), {"to": "the mill"}, func() -> void: undone.append("to the mill"))
	var tick := Tick.new()
	root.add_child(tick)
	tick.due.append(func() -> void: far.asked[1][1].call(null))
	await _a_frame_passes()
	tick.due.append(func() -> void: far.asked[0][1].call(Phrase.of("The quay is closed")))
	await _a_frame_passes()
	_verdict.check(undone == ["to the quay"], "refused, the earlier change is undone: %s" % [undone])
	_verdict.check(far.read_back == [&"crate 7"], "and the crate is read back from the far side, since the kept change stood on it: %s" % [far.read_back])
	tick.free()
	notices.remove_tray(tray)
	tray.free()
	notices.free()
	made.done()


## A model following another's value has it once the frame's work is done -
## it is rung at the end of the frame - and a reading worked out from the
## value and kept with what it read has it the moment it is set.
func _a_follower_has_a_moved_value_by_the_end_of_the_frame_and_a_worked_out_reading_has_it_at_once() -> void:
	var made := Fixture.new(root)
	var takings := Takings.new(made.chimes)
	var follower := Follower.new(made.chimes, takings.sold)
	for model: Node in [takings, follower]:
		made.ui.also(model)
	var doubled_before := takings.get_doubled()
	var seen: Array = []
	var tick := Tick.new()
	root.add_child(tick)
	tick.due.append(func() -> void:
		takings.sold.set_value(5)
		seen.append_array([follower.copy, takings.get_doubled()]))
	await _a_frame_passes()
	_verdict.check(doubled_before == 2 and seen == [1, 10], "the instant it is set, the worked-out reading has it and the follower does not yet: %s" % [seen])
	_verdict.check(follower.copy == 5, "and by the end of the frame the follower has it: %s" % [follower.copy])
	tick.free()
	made.done()


## A job in the background setting a model's value is refused out loud, and
## the value stays as the main thread left it: a set from a job lands through
## the main thread, as a job's answer does.
func _a_value_set_off_the_main_thread_is_refused_out_loud_and_does_not_move() -> void:
	var made := Fixture.new(root)
	var takings := Takings.new(made.chimes)
	made.ui.also(takings)
	var complaints := Complaints.new()
	OS.add_logger(complaints)
	var job := WorkerThreadPool.add_task(func() -> void: takings.sold.set_value(9))
	WorkerThreadPool.wait_for_task_completion(job)
	OS.remove_logger(complaints)
	_verdict.check(takings.sold.read() == 1, "set from a job, the value does not move: %s" % [takings.sold.read()])
	_verdict.check(complaints.said.size() == 1 and complaints.said[0].contains("off the main thread"), "and it is said out loud, once: %s" % [complaints.said])
	made.done()
