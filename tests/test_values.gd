extends SceneTree

## What must be true of a model's values, and of whatever reads them.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_values.gd
##
## Nothing here lists a bell. A pressable whose refusal reads two models'
## values is drawn again when either moves; a value read through a map is
## tracked, and a text reading it is drawn again when it moves and not when
## a value it did not read does; however many values a model sets in one
## frame, its bell rings once; a value worked out every frame, with no
## model, is read again each frame; a value read off the main thread is said
## out loud and tracked for nobody; and a reading kept with what it read is
## worked out once and lets itself go as what it read moves.

const Fixture := preload("res://tests/fixture.gd")
const Controller := preload("res://addons/gd_chime/controller.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Reads := preload("res://addons/gd_chime/reads.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Value := preload("res://addons/gd_chime/components/primitives/value.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Verdict := preload("res://tests/verdict.gd")

const BUYS := &"buys"

var _verdict := Verdict.new()


## A purse: how many coins it holds.
class Purse extends Controller:
	var coins := value(0)
	var seller := value({"name": "ann", "town": "leeds"})


## A stall: whether it is open.
class Stall extends Controller:
	var open := value(true)


## A buyer, refusing a crate while the purse holds under three coins or
## the stall is shut: its refusal reads both, and lists neither.
class Buyer extends Controller:
	var _purse: Purse
	var _stall: Stall

	func _init(chimes: Chimes, purse: Purse, stall: Stall) -> void:
		super(chimes)
		_purse = purse
		_stall = stall

	func would(_action: StringName, _payload: Dictionary) -> Phrase:
		if _purse.coins.read() < 3:
			return Phrase.of("Not enough coins")
		if not _stall.open.read():
			return Phrase.of("The stall is shut")
		return null

	func told(_action: StringName, _payload: Dictionary) -> Phrase:
		return null


## A till whose takings doubled is worked out once and kept with what it read
## (reads.gd), with nothing emptying it: how often the work actually ran is
## what a test counts.
class Till extends Controller:
	var takings := value(2)
	var workings: int = 0
	var _doubled: Array = []  # what the takings came to, kept with the addresses it read

	func get_doubled() -> int:
		return Reads.worked(_doubled, func() -> int:
			workings += 1
			return takings.read() * 2)


## A crier: how many times it has called out, hung on a bell of its own and
## read through it, so a reading kept with that read has a bell to let go on
## rather than a value.
class Crier extends Controller:
	const CALLED := &"called"

	var workings: int = 0
	var _calls: int = 0
	var _said: Array = []  # what the calls came to, kept with the address it read

	func _init(chimes: Chimes) -> void:
		super(chimes)
		register_bell(CALLED)

	func get_calls() -> int:
		return Reads.worked(_said, func() -> int:
			workings += 1
			Reads.note(region, CALLED)
			return _calls)

	## It calls out once more, and says so.
	func calls_out() -> void:
		_calls += 1
		strike(region, CALLED)


## Keeps what the engine was told to say, so a complaint out loud is something
## a test can read rather than something a person has to spot in the output.
class Complaints extends Logger:
	var said: Array[String] = []

	func _log_error(_function: String, _file: String, _line: int, code: String, rationale: String, _editor_notify: bool, _error_type: int, _traces: Array[ScriptBacktrace]) -> void:
		said.append(code if rationale.is_empty() else rationale)


## Counts every time its work runs: the work reads a purse's coins.
class Counting extends Controller:
	var runs: int = 0

	func _init(chimes: Chimes, purse: Purse) -> void:
		super(chimes)
		follow(&"coins", func() -> void:
			runs += 1
			purse.coins.read())


func _init() -> void:
	await process_frame
	await _verdict.states(_a_refusal_reading_two_models_is_drawn_again_when_either_moves)
	await _verdict.states(_a_value_read_through_a_map_is_tracked_and_nothing_else_is)
	await _verdict.states(_a_model_rings_once_a_frame_however_many_sets)
	await _verdict.states(_a_value_worked_out_every_frame_needs_no_model)
	await _verdict.states(_a_value_read_off_the_main_thread_is_said_out_loud_and_tracked_for_nobody)
	await _verdict.states(_a_reading_kept_with_what_it_read_lets_itself_go_as_that_moves)
	await _verdict.states(_a_reading_kept_with_a_bell_it_read_lets_go_as_that_bell_rings)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


func _a_refusal_reading_two_models_is_drawn_again_when_either_moves() -> void:
	var made := Fixture.new(root, {BUYS: "buy a crate"})
	var ui := made.ui
	root.theme = Themes.new(Themes.NEUTRAL)
	var purse := Purse.new(made.chimes)
	var stall := Stall.new(made.chimes)
	var buyer := Buyer.new(made.chimes, purse, stall)
	for model: Node in [purse, stall, buyer]:
		ui.also(model)
	made.commands.register(Chimes.GLOBAL, BUYS, buyer)
	ui.start(ui.app(&"app", [ui.pressable(BUYS, {}, [ui.reason().named(&"why")]).named(&"buy")]))
	await _a_frame_passes()
	var buy: Pressable = ui.node_named(&"buy")
	var why: Text = ui.node_named(&"why")
	var inert := buy._box_of(&"inert")
	var normal := buy._box_of(&"normal")
	_verdict.check(inert != normal and buy._last_box == inert and why.get_text() == "Not enough coins", "with the purse short it is drawn refused, in the look's inert box, saying why: %s" % why.get_text())
	purse.coins.set_value(5)
	await _a_frame_passes()
	_verdict.check(buy._last_box == normal and why.get_text() == "", "the purse filled, it was drawn usable: %s" % why.get_text())
	stall.open.set_value(false)
	await _a_frame_passes()
	_verdict.check(buy._last_box == inert and why.get_text() == "The stall is shut", "the stall shut - the other model - it was drawn refused again: %s" % why.get_text())
	made.done()


func _a_value_read_through_a_map_is_tracked_and_nothing_else_is() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var purse := Purse.new(made.chimes)
	var stall := Stall.new(made.chimes)
	for model: Node in [purse, stall]:
		ui.also(model)
	ui.start(ui.app(&"app", [
		ui.text(purse.coins.map(func(held: int) -> String: return "%d coins" % held)).named(&"coins"),
		ui.text(purse.seller.field("town")).named(&"town"),
	]))
	await _a_frame_passes()
	var coins: Text = ui.node_named(&"coins")
	var town: Text = ui.node_named(&"town")
	purse.coins.set_value(7)
	purse.seller.set_value({"name": "ann", "town": "york"})
	await _a_frame_passes()
	_verdict.check(coins.get_text() == "7 coins" and town.get_text() == "york", "read through a map and a field, each is drawn again as its value moves: %s, %s" % [coins.get_text(), town.get_text()])
	var drawn := coins.refresh_count
	stall.open.set_value(false)
	await _a_frame_passes()
	_verdict.check(coins.refresh_count == drawn, "a value of another model, which it did not read, moves: it is not drawn again: %d" % (coins.refresh_count - drawn))
	made.done()


func _a_model_rings_once_a_frame_however_many_sets() -> void:
	var made := Fixture.new(root)
	var purse := Purse.new(made.chimes)
	var counting := Counting.new(made.chimes, purse)
	for model: Node in [purse, counting]:
		made.ui.also(model)
	var before := counting.runs
	# five sets in the one frame, of two of its values
	for coins: int in 5:
		purse.coins.set_value(coins)
		purse.seller.set_value({"name": "bo", "town": "hull"})
	_verdict.check(counting.runs == before, "set, nothing is heard until the frame is over: %d" % (counting.runs - before))
	await _a_frame_passes()
	_verdict.check(counting.runs == before + 1, "ten sets in one frame, its bell rang once: %d" % (counting.runs - before))
	purse.coins.set_value(9)
	await _a_frame_passes()
	_verdict.check(counting.runs == before + 2, "one more set in a later frame, it rang once more: %d" % (counting.runs - before))
	made.done()


func _a_value_worked_out_every_frame_needs_no_model() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var purse := Purse.new(made.chimes)
	ui.also(purse)
	ui.start(ui.app(&"app", [
		ui.text(ui.every_frame(func() -> String: return "frame %d" % Engine.get_process_frames())).named(&"frame"),
		ui.text(ui.bound(func() -> String: return "%d each" % (purse.coins.read() * 2))).named(&"doubled"),
	]))
	await _a_frame_passes()
	var frame: Text = ui.node_named(&"frame")
	var doubled: Text = ui.node_named(&"doubled")
	var shown := frame.get_text()
	await _a_frame_passes()
	_verdict.check(frame.get_text() != shown and frame.get_text().begins_with("frame "), "read every frame, it is drawn again with nothing set: %s then %s" % [shown, frame.get_text()])
	purse.coins.set_value(4)
	await _a_frame_passes()
	_verdict.check(doubled.get_text() == "8 each", "worked out from a model's value, with no model of its own, it follows the value: %s" % doubled.get_text())
	made.done()


## A job in the background reads nothing bound. One that does is said out
## loud, naming the bell it read, and what the main thread is working out at
## that moment is left alone - so no listener is ever wired to a job's read.
func _a_value_read_off_the_main_thread_is_said_out_loud_and_tracked_for_nobody() -> void:
	var made := Fixture.new(root)
	var purse := Purse.new(made.chimes)
	made.ui.also(purse)
	var complaints := Complaints.new()
	OS.add_logger(complaints)
	Reads.begin()
	var job := WorkerThreadPool.add_task(func() -> void: purse.coins.read())
	WorkerThreadPool.wait_for_task_completion(job)
	var read := Reads.end()
	OS.remove_logger(complaints)
	_verdict.check(read.is_empty(), "the job's read is not among what the main thread was working out: %s" % [read])
	_verdict.check(complaints.said.size() == 1 and complaints.said[0].contains("off the main thread"), "and it was said out loud, once: %s" % [complaints.said])
	_verdict.check(not complaints.said.is_empty() and complaints.said[0].contains("values_"), "naming the bell that was read: %s" % [complaints.said])
	made.done()


## A reading worked out once and kept with what it read: asked for over and
## over it is worked out once, it lets itself go the moment a value it read
## is set - at once, not a frame later - a value it never read leaves it
## alone, and whoever reads it follows what the work read. Nothing empties it.
func _a_reading_kept_with_what_it_read_lets_itself_go_as_that_moves() -> void:
	var made := Fixture.new(root)
	var till := Till.new(made.chimes)
	var stall := Stall.new(made.chimes)
	var heard := Fixture.Heard.new(made.chimes, till.get_doubled)
	for model: Node in [till, stall, heard]:
		made.ui.also(model)
	# the same reading asked for over and over with nothing moved between
	for again: int in 3:
		till.get_doubled()
	_verdict.check(till.get_doubled() == 4 and till.workings == 1, "asked for over and over with nothing moved, it is worked out once: %d" % till.workings)
	stall.open.set_value(false)
	_verdict.check(till.get_doubled() == 4 and till.workings == 1, "a value it never read set, it is not worked out again: %d" % till.workings)
	var rang := heard.rung
	till.takings.set_value(10)
	_verdict.check(till.get_doubled() == 20 and till.workings == 2, "the value it read set, it is worked out afresh at once, with nothing emptying it by hand: %d" % till.workings)
	await _a_frame_passes()
	_verdict.check(heard.rung == rang + 1 and till.get_doubled() == 20, "and whoever read it was woken by what the work read, the frame over: %d" % (heard.rung - rang))
	made.done()


## A reading kept with a read of a bell rather than of a value: struck, it is
## worked out afresh, so what a model rings for itself lets a reading go too.
func _a_reading_kept_with_a_bell_it_read_lets_go_as_that_bell_rings() -> void:
	var made := Fixture.new(root)
	var crier := Crier.new(made.chimes)
	made.ui.also(crier)
	# the same reading asked for over and over with the bell quiet
	for again: int in 3:
		crier.get_calls()
	_verdict.check(crier.get_calls() == 0 and crier.workings == 1, "the bell quiet, it is worked out once: %d" % crier.workings)
	crier.calls_out()
	_verdict.check(crier.get_calls() == 1 and crier.workings == 2, "the bell it read struck, it is worked out afresh: %d" % crier.workings)
	made.done()
