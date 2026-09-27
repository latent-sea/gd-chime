extends SceneTree

## What must be true of a change shown at once and confirmed later.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_provisional.gd
##
## A change begun stands at once and is sent; while it waits the thing is
## pending; a yes keeps it, moves nothing
## and says nothing; a no undoes it once, keeps the reason against the
## thing and says it in one notification by the change's words; a no to the
## first of two changes on one thing undoes both, newest first, while a
## change to another thing stands; changing a refused thing again clears
## its reason; and the bell rings as each moves. Nothing ends silently
## different from the far side: a thing whose later changes were undone is
## read back once every answer is in - a late yes among them lands - and
## the far side's record wins over what the screen held; a read overtaken by
## a new change is let go and the thing read again; and with no way to read
## back, the reader is told the thing may differ.
##
## The far side is a stand-in answered by hand, so what the answers are and
## when they come is the test's.

const Belfry := preload("res://addons/gd_chime/belfry.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Commands := preload("res://addons/gd_chime/commands.gd")
const Notifications := preload("res://addons/gd_chime/notifications.gd")
const Provisional := preload("res://addons/gd_chime/provisional.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Verdict := preload("res://tests/verdict.gd")
const Fixture := preload("res://tests/fixture.gd")

var _verdict := Verdict.new()
var _chimes: Chimes
var _commands: Commands
var _notices: Notifications
var _far: Far
var _provisional: Provisional
var _tray: Node
var _heard: Fixture.Heard  # counts the provisional changes moving


## A far side answered by hand: every request kept with its answer, in the
## order sent; the record of where each thing stands, moved by every yes;
## and every read of it, answered from the record when the test says.
class Far extends RefCounted:
	var sent: Array = []  # [request, answer]
	var record: Dictionary = {"a": 1, "b": 1}  # thing -> where the far side has it
	var asked: Array = []  # [thing, answer], every read in the order asked

	func send(request: Dictionary, answer: Callable) -> void:
		sent.append([request, answer])

	func answer(index: int, refusal: Variant) -> void:
		if refusal == null:
			record[sent[index][0]["thing"]] = sent[index][0]["to"]
		sent[index][1].call(refusal)

	func reads(thing: Variant, answer: Callable) -> void:
		asked.append([thing, answer])

	func read(index: int) -> void:
		asked[index][1].call(record[asked[index][0]])


## A tray standing for the notifications to be told to: every words fit it,
## as a tray must answer (tray_stand.gd).
class Tray extends Node:
	func fits(_words: Variant) -> bool:
		return true


## Where things stand, as a model keeps them: thing -> its place.
var _places: Dictionary = {}
var _undone: Array = []  # every undo, in the order made


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	await _verdict.states(_a_change_is_shown_at_once_sent_and_pending_until_answered)
	await _verdict.states(_a_yes_keeps_it_and_moves_and_says_nothing)
	await _verdict.states(_a_no_undoes_it_once_and_says_why_on_the_thing_and_in_a_notification)
	await _verdict.states(_a_no_to_the_first_of_two_changes_undoes_both_newest_first_and_another_thing_stands)
	await _verdict.states(_changing_a_refused_thing_again_clears_its_reason)
	await _verdict.states(_refused_first_and_kept_second_the_screen_ends_where_the_far_side_has_it)
	await _verdict.states(_the_far_sides_record_wins_over_what_the_screen_held_and_a_read_overtaken_is_let_go)
	await _verdict.states(_with_no_way_to_read_back_a_thing_in_doubt_is_said)
	quit(_verdict.deliver(get_script()))


func _standing() -> void:
	_chimes = Chimes.new(Belfry.new())
	_commands = Commands.new(_chimes)
	_notices = Notifications.new(_chimes, _commands, root)
	_notices.by_hand = true
	_tray = Tray.new()
	_notices.add_tray(_tray)
	_far = Far.new()
	_provisional = Provisional.new(_chimes, _far.send, _notices, _far.reads, func(thing: Variant, place: Variant) -> void: _places[thing] = place)
	_heard = Fixture.Heard.new(_chimes, _provisional.get_pending)
	_places = {"a": 1, "b": 1}
	_undone = []


func _done() -> void:
	_notices.remove_tray(_tray)
	_tray.free()
	for node: Node in [_heard, _provisional, _notices, _commands]:
		node.free()


## A thing moved at once, as a model's told() moves it, and handed over with how to undo it.
func _move(thing: String, to: int) -> void:
	var was: int = _places[thing]
	_places[thing] = to
	_provisional.begin(thing, Phrase.with("%s to %d", [thing, to]), {"thing": thing, "to": to}, func() -> void: _places[thing] = was; _undone.append([thing, was]))


func _a_change_is_shown_at_once_sent_and_pending_until_answered() -> void:
	_standing()
	_move("a", 4)
	_verdict.check(_places["a"] == 4 and _far.sent.size() == 1 and _far.sent[0][0] == {"thing": "a", "to": 4}, "the change stands at once and its request is sent: %s" % [_far.sent.map(func(one: Array) -> Dictionary: return one[0])])
	await process_frame
	_verdict.check(_provisional.get_pending() == {"a": 1} and _heard.rung == 1, "until it is answered the thing is pending, and the bell rang once: %s, %d" % [_provisional.get_pending(), _heard.rung])
	_done()


func _a_yes_keeps_it_and_moves_and_says_nothing() -> void:
	_standing()
	_move("a", 4)
	await process_frame
	_far.answer(0, null)
	await process_frame
	_verdict.check(_places["a"] == 4 and _undone.is_empty() and _provisional.get_pending().is_empty(), "a yes keeps the change and undoes nothing, and nothing is pending")
	_verdict.check(_notices.get_standing().is_empty() and _provisional.get_refused().is_empty() and _heard.rung == 2, "and says nothing: no notification, no reason, the bell rung as it settled")
	_done()


func _a_no_undoes_it_once_and_says_why_on_the_thing_and_in_a_notification() -> void:
	_standing()
	_move("a", 4)
	_far.answer(0, Phrase.of("the far side is closed"))
	_verdict.check(_places["a"] == 1 and _undone == [["a", 1]], "a no undoes the change, once: %s" % [_undone])
	_verdict.check(str(_provisional.get_refused().get("a")) == "the far side is closed" and _provisional.get_pending().is_empty(), "its reason is kept against the thing, and nothing is pending: %s" % [_provisional.get_refused()])
	var said: Array = _notices.get_standing().map(func(one: Dictionary) -> String: return str(one["words"]))
	_verdict.check(said == ["a to 4 was not kept: the far side is closed"], "and one notification says it, by the change's words: %s" % [said])
	_done()


func _a_no_to_the_first_of_two_changes_undoes_both_newest_first_and_another_thing_stands() -> void:
	_standing()
	_move("a", 4)
	_move("b", 7)
	_move("a", 9)
	_verdict.check(_provisional.get_pending() == {"a": 2, "b": 1}, "two changes to one thing and one to another, all pending: %s" % [_provisional.get_pending()])
	_far.answer(0, Phrase.of("no"))
	_verdict.check(_undone == [["a", 4], ["a", 1]] and _places["a"] == 1, "the no to the first undoes both, newest first, back to where it stood before them: %s" % [_undone])
	_verdict.check(_places["b"] == 7 and _provisional.get_pending() == {"b": 1}, "the other thing's change stands, still pending: %s" % [_provisional.get_pending()])
	_far.answer(2, Phrase.of("no"))
	_verdict.check(_places["a"] == 1 and _undone.size() == 2 and _notices.get_standing().size() == 1, "the second's answer, a no too, undoes nothing again and says nothing more")
	_far.read(0)
	_verdict.check(_far.asked.size() == 1 and _places["a"] == _far.record["a"] and _places["a"] == 1, "and read back, the thing is where the far side has it - where it stood: %s, %s" % [_places, _far.record])
	_done()


func _refused_first_and_kept_second_the_screen_ends_where_the_far_side_has_it() -> void:
	_standing()
	_move("a", 4)
	_move("a", 9)
	_far.answer(0, Phrase.of("no"))
	_verdict.check(_places["a"] == 1 and _far.asked.is_empty() and _provisional.get_pending() == {}, "the no to the first undoes both at once, and nothing is read while the second's request is on its way: %s" % [_far.asked])
	_far.answer(1, null)
	_verdict.check(_far.record["a"] == 9 and _far.asked.size() == 1 and _provisional.get_pending() == {"a": 1}, "the far side kept the second: its yes is not dropped - the thing is read back, pending while it is: %s" % [_provisional.get_pending()])
	_far.read(0)
	_verdict.check(_places["a"] == 9 and _places == _far.record and _provisional.get_pending().is_empty(), "the late yes lands: the screen ends where the far side has it, and nothing is pending: %s, %s" % [_places, _far.record])
	_done()


func _the_far_sides_record_wins_over_what_the_screen_held_and_a_read_overtaken_is_let_go() -> void:
	_standing()
	_move("a", 4)
	_move("a", 9)
	_far.answer(0, Phrase.of("no"))
	_far.answer(1, Phrase.of("no"))
	_far.record["a"] = 7
	_far.read(0)
	_verdict.check(_places["a"] == 7, "the read's answer wins over what the screen held - the far side had it elsewhere: %s" % [_places])
	_move("b", 3)
	_move("b", 6)
	_far.answer(2, Phrase.of("no"))
	_far.answer(3, null)
	_move("b", 5)
	_far.read(1)
	_verdict.check(_places["b"] == 5 and _far.asked.size() == 2, "a read overtaken by a new change is let go, and the new change stands: %s" % [_places])
	_far.answer(4, null)
	_far.read(2)
	_verdict.check(_far.asked.size() == 3 and _places == _far.record and _places["b"] == 5, "once that change is answered the thing is read again, and ends where the far side has it: %s, %s" % [_places, _far.record])
	_done()


func _with_no_way_to_read_back_a_thing_in_doubt_is_said() -> void:
	_standing()
	# made again with no way to read back, which is what a model that cannot hands in
	_provisional.free()
	_provisional = Provisional.new(_chimes, _far.send, _notices)
	_move("a", 4)
	_move("a", 9)
	_far.answer(0, Phrase.of("no"))
	_far.answer(1, null)
	var said: Array = _notices.get_standing().map(func(one: Dictionary) -> String: return str(one["words"]))
	_verdict.check(said == ["a to 4 was not kept: no", "a to 9 may not be as the server has it"], "a model that cannot read back is told the thing may differ, once every answer is in: %s" % [said])
	_done()


func _changing_a_refused_thing_again_clears_its_reason() -> void:
	_standing()
	_move("a", 4)
	_far.answer(0, Phrase.of("no"))
	_move("a", 5)
	_verdict.check(not _provisional.get_refused().has("a") and _provisional.get_pending() == {"a": 1}, "changed again, a refused thing's reason is gone, and the new change pending")
	_done()
