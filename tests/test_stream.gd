extends SceneTree

## What must be true of a stream: the source is open exactly while the
## reader stays at the place that took it - through a pop-up raised over it,
## not after the place is left - and a push under a stay that is over lands
## nowhere and closes it; events pushed in a frame are handed on once, at
## its end, oldest first, to every sink; paused, nothing is handed on and
## the newest are held up to the capacity, the oldest counted as missed;
## resumed, the held are handed on first; pausing twice is refused. Running
## and outrun, the same capacity holds: what waits past a frame's share is
## kept to the newest, the oldest counted as missed; how far behind it is
## rises under a flood and falls back once it stops, the last ring saying so.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_stream.gd

const Fixture := preload("res://tests/fixture.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Token := preload("res://addons/gd_chime/token.gd")
const Stream := preload("res://addons/gd_chime/stream.gd")
const Verdict := preload("res://tests/verdict.gd")

const CAPACITY := 3

var _verdict := Verdict.new()


## A source that remembers where it pushes and how often it was opened and closed.
class Source extends RefCounted:
	var push: Callable
	var opened: int = 0
	var closed: int = 0

	func open(to: Object) -> void:
		push = to.push
		opened += 1

	func close() -> void:
		closed += 1


## A reader of how far behind the stream is, keeping what it read each time that moved.
class Ear extends RefCounted:
	var behind: Array[int] = []
	var _chimes: Chimes
	var _stream: Object

	func _init(chimes: Chimes, stream: Object) -> void:
		_chimes = chimes
		_stream = stream
		chimes.follow(self, &"heard", stream.get_behind, _moved)

	func _moved() -> void:
		behind.append(_stream.get_behind())
		_chimes.follow(self, &"heard", _stream.get_behind, _moved)


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	await _verdict.states(_the_source_is_open_exactly_while_the_reader_stays_at_the_place)
	await _verdict.states(_a_frame_s_events_are_handed_on_once_at_its_end_oldest_first)
	await _verdict.states(_paused_the_newest_are_held_and_resumed_they_are_handed_on_first)
	await _verdict.states(_a_backlog_past_a_frame_s_share_is_handed_on_over_frames_in_order)
	await _verdict.states(_a_flood_outrunning_the_hand_on_is_capped_and_the_let_go_counted)
	await _verdict.states(_how_far_behind_rises_under_a_flood_and_falls_back_once_it_stops)
	quit(_verdict.deliver(get_script()))


func _a_flood_outrunning_the_hand_on_is_capped_and_the_let_go_counted() -> void:
	var made := Fixture.new(root)
	var source := Source.new()
	var batches: Array = []
	var stream := _made(made, source, batches, 2)
	stream.open(Token.new())
	# twenty in one frame, running, two a frame handed on and three the capacity
	for at: int in 20:
		source.push.call(at)
	await process_frame
	_verdict.check(stream.get_behind() <= CAPACITY and stream.get_missed() == 15, "outrun, what waits is kept to the capacity and the rest counted as missed: behind %d, missed %d" % [stream.get_behind(), stream.get_missed()])
	# frames enough for the three kept, nothing more pushed
	for frame: int in 4:
		await process_frame
	var every: Array = []
	# every batch, its events in the order handed
	for batch: Array in batches:
		every.append_array(batch)
	_verdict.check(every == [0, 1, 17, 18, 19] and stream.get_behind() == 0, "the frame's share and then the newest are handed on, the oldest waiting let go: %s" % [every])
	made.done()


func _how_far_behind_rises_under_a_flood_and_falls_back_once_it_stops() -> void:
	var made := Fixture.new(root)
	var source := Source.new()
	var batches: Array = []
	var stream := _made(made, source, batches, 2, 1000)
	var ear := Ear.new(made.chimes, stream)
	stream.open(Token.new())
	var behind: Array[int] = []
	# four frames of ten, two a frame handed on: more behind each frame
	for frame: int in 4:
		for at: int in 10:
			source.push.call(frame * 10 + at)
		await process_frame
		behind.append(stream.get_behind())
	_verdict.check(behind[0] > 0 and behind[1] > behind[0] and behind[2] > behind[1] and behind[3] > behind[2], "under a flood, how far behind it is rises each frame: %s" % [behind])
	# quiet past two cadences, so the next ring is not held back by the last
	await create_timer(0.6).timeout
	_verdict.check(stream.get_behind() == 0 and stream.get_missed() == 0, "the flood stopped, it falls back to nothing, none missed within the capacity: behind %d" % stream.get_behind())
	# a quiet spell, then one frame's flood rung at once as it arrives
	ear.behind.clear()
	for at: int in 30:
		source.push.call(at)
	await create_timer(0.4).timeout
	_verdict.check(ear.behind.size() >= 2 and ear.behind[0] > 0 and ear.behind[-1] == 0, "the bell rings as it falls back, the last ring reading nothing behind: %s" % [ear.behind])
	made.done()


func _a_backlog_past_a_frame_s_share_is_handed_on_over_frames_in_order() -> void:
	var made := Fixture.new(root)
	var source := Source.new()
	var batches: Array = []
	var stream := _made(made, source, batches, 2)
	stream.open(Token.new())
	made.commands.dispatch(Chimes.GLOBAL, Stream.HOLDS, {"on": true})
	# three held, the capacity, then resumed with seven more arriving in the frames after
	for at: int in 3:
		source.push.call(at)
	made.commands.dispatch(Chimes.GLOBAL, Stream.HOLDS, {"on": false})
	# four frames, a push or two in each
	for frame: int in 4:
		source.push.call(10 + frame * 2)
		source.push.call(11 + frame * 2)
		await process_frame
	# frames enough for whatever still waits, nothing more pushed
	for frame: int in 8:
		await process_frame
	var every: Array = []
	# every batch, its events in the order handed
	for batch: Array in batches:
		every.append_array(batch)
	_verdict.check(batches.all(func(batch: Array) -> bool: return batch.size() <= 2) and every == [0, 1, 2, 10, 11, 12, 13, 14, 15, 16, 17], "no frame hands on more than its share, and over the frames every event is handed on once, oldest first: %s" % [batches])
	_verdict.check(not stream.is_processing(), "nothing waiting, it does not process")
	made.done()


## A stream over a new source, handing on into the batches given, begun in a fixture.
func _made(made: Fixture, source: Source, batches: Array, most: int = 100, capacity: int = CAPACITY) -> Stream:
	var sinks: Array[Callable] = [func(batch: Array) -> void: batches.append(batch)]
	var stream := Stream.new(made.chimes, source, sinks, capacity, most)
	root.add_child(stream)
	made.commands.register(Chimes.GLOBAL, Stream.HOLDS, stream)
	return stream


func _the_source_is_open_exactly_while_the_reader_stays_at_the_place() -> void:
	var made := Fixture.new(root)
	var source := Source.new()
	var batches: Array = []
	var stream := _made(made, source, batches)
	var ui := made.ui
	var watched := ui.screen(&"watched", [ui.text("live")], null, {on_fill = stream.open, on_empty = stream.close})
	var detail: Desc = ui.pop_up(&"detail", func(_which: Bound) -> Desc: return ui.text("one of them"))
	ui.start(ui.app(&"app", [watched, ui.screen(&"elsewhere", [ui.text("quiet")]), detail]))
	await process_frame
	await process_frame
	_verdict.check(source.opened == 1 and source.closed == 0 and stream.get_open(), "the place entered, its stay opens the source: opened %d, closed %d" % [source.opened, source.closed])
	made.commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": detail.get_place()})
	await process_frame
	source.push.call("while the detail is up")
	await process_frame
	_verdict.check(source.closed == 0 and batches == [["while the detail is up"]], "a pop-up raised over the place leaves the stay alone, and events go on arriving: %s" % [batches])
	made.commands.dispatch(Chimes.GLOBAL, Driver.GOES_BACK, {})
	made.commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": &"elsewhere"})
	await process_frame
	var pushed := source.push
	pushed.call("after leaving")
	await process_frame
	_verdict.check(source.closed == 1 and not stream.get_open() and batches.size() == 1, "the place left, the source is closed and a push lands nowhere: closed %d, %s" % [source.closed, batches])
	var stay := Token.new()
	stream.open(stay)
	stay.cancel()
	source.push.call("under a stay that is over")
	await process_frame
	_verdict.check(source.closed == 2 and batches.size() == 1, "a push under a stay that is over closes the source and lands nowhere: closed %d, %s" % [source.closed, batches])
	made.done()


func _a_frame_s_events_are_handed_on_once_at_its_end_oldest_first() -> void:
	var made := Fixture.new(root)
	var source := Source.new()
	var batches: Array = []
	var stream := _made(made, source, batches)
	stream.open(Token.new())
	# a hundred events in one frame
	for at: int in 100:
		source.push.call(at)
	_verdict.check(batches.is_empty(), "nothing is handed on before the frame's end: %d batches" % batches.size())
	await process_frame
	_verdict.check(batches.size() == 1 and batches[0] == range(100) and stream.handed_count == 100, "a frame's hundred events are one batch at its end, oldest first: %d batches" % batches.size())
	made.done()


func _paused_the_newest_are_held_and_resumed_they_are_handed_on_first() -> void:
	var made := Fixture.new(root)
	var source := Source.new()
	var batches: Array = []
	var stream := _made(made, source, batches)
	stream.open(Token.new())
	source.push.call(0)
	made.commands.dispatch(Chimes.GLOBAL, Stream.HOLDS, {"on": true})
	await process_frame
	_verdict.check(batches.is_empty() and stream.get_held() == 1, "paused in the frame an event arrived, it is held, not handed on: %s, held %d" % [batches, stream.get_held()])
	# four more while paused, past a capacity of three
	for at: int in range(1, 5):
		source.push.call(at)
	await process_frame
	_verdict.check(batches.is_empty() and stream.get_paused() and stream.get_held() == CAPACITY and stream.get_missed() == 2, "paused, nothing is handed on and the newest three are held, two missed: held %d, missed %d" % [stream.get_held(), stream.get_missed()])
	var refused: Variant = made.commands.dispatch(Chimes.GLOBAL, Stream.HOLDS, {"on": true})
	_verdict.check(refused != null, "pausing what is paused is refused")
	made.commands.dispatch(Chimes.GLOBAL, Stream.HOLDS, {"on": false})
	source.push.call(5)
	await process_frame
	_verdict.check(batches == [[2, 3, 4, 5]] and stream.get_held() == 0 and stream.get_missed() == 2, "resumed, the held are handed on first, oldest first, then what is new, the missed still counted this stay: %s" % [batches])
	made.done()
