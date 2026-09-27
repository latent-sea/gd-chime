extends SceneTree

## What must be true of working offline: the connection says whether the
## far side can be reached (connection.gd); what is sent while it cannot is
## held, and sent in order as it comes back (outbox.gd); and a model's
## provisional changes (provisional.gd) stand at once, pending, the whole
## time - kept on a yes, rolled back with their reason on a refusal.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_offline.gd
##
## The far side is a stand-in answered by hand, so what reaches it and when
## it answers is the test's.

const Belfry := preload("res://addons/gd_chime/belfry.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Commands := preload("res://addons/gd_chime/commands.gd")
const Notifications := preload("res://addons/gd_chime/notifications.gd")
const Provisional := preload("res://addons/gd_chime/provisional.gd")
const Connection := preload("res://addons/gd_chime/connection.gd")
const Outbox := preload("res://addons/gd_chime/outbox.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Verdict := preload("res://tests/verdict.gd")
const Fixture := preload("res://tests/fixture.gd")

var _verdict := Verdict.new()
var _chimes: Chimes
var _commands: Commands
var _notices: Notifications
var _tray: Node
var _connection: Connection
var _outbox: Outbox
var _provisional: Provisional
var _far: Far
var _heard: Fixture.Heard  # counts the connection's state moving
var _places: Dictionary = {}  # thing -> where it stands, as a model keeps it


## A tray every notification's words fit, so one stands wherever it is said.
class Tray extends Node:
	func fits(_words: String) -> bool:
		return true


## A far side answered by hand: every request kept with its answer, in the order it arrived.
class Far extends RefCounted:
	var sent: Array = []  # [request, answer]

	func send(request: Dictionary, answer: Callable) -> void:
		sent.append([request, answer])


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	await _verdict.states(_a_connection_is_lost_until_told_and_rings_once_a_change)
	await _verdict.states(_online_a_send_goes_at_once)
	await _verdict.states(_offline_a_change_stands_at_once_pending_and_nothing_is_sent)
	await _verdict.states(_back_online_what_was_held_is_sent_oldest_first_and_kept_on_a_yes)
	await _verdict.states(_refused_on_sync_it_rolls_back_saying_why)
	quit(_verdict.deliver(get_script()))


func _standing() -> void:
	_chimes = Chimes.new(Belfry.new())
	_commands = Commands.new(_chimes)
	_notices = Notifications.new(_chimes, _commands, root)
	_notices.by_hand = true
	_tray = Tray.new()
	_notices.add_tray(_tray)
	_connection = Connection.new(_chimes)
	_far = Far.new()
	_outbox = Outbox.new(_chimes, _connection, _far.send)
	_provisional = Provisional.new(_chimes, _outbox.send, _notices)
	_heard = Fixture.Heard.new(_chimes, _connection.state.read)
	_places = {"a": 1, "b": 1}


func _done() -> void:
	_notices.remove_tray(_tray)
	_tray.free()
	for node: Node in [_heard, _provisional, _outbox, _connection, _notices, _commands]:
		node.free()


## A thing moved at once, as a model's told() moves it, and handed over with how to undo it.
func _move(thing: String, to: int) -> void:
	var was: int = _places[thing]
	_places[thing] = to
	_provisional.begin(thing, Phrase.with("%s to %d", [thing, to]), {"thing": thing, "to": to}, func() -> void: _places[thing] = was)


func _a_connection_is_lost_until_told_and_rings_once_a_change() -> void:
	_standing()
	_verdict.check(_connection.state.read() == Connection.LOST and not _connection.get_online(), "built, it is lost and not online")
	_connection.set_state(Connection.CONNECTED)
	_connection.set_state(Connection.CONNECTED)
	await process_frame
	_verdict.check(_connection.get_online() and _heard.rung == 1, "told connected it is online, rung once however often it is told: %d" % _heard.rung)
	_connection.set_state(Connection.RECONNECTING)
	await process_frame
	_verdict.check(not _connection.get_online() and _heard.rung == 2, "reconnecting is not online: %d" % _heard.rung)
	_done()


func _online_a_send_goes_at_once() -> void:
	_standing()
	_connection.set_state(Connection.CONNECTED)
	_move("a", 4)
	_verdict.check(_far.sent.size() == 1 and _outbox.get_held() == 0, "online, a change is sent at once and nothing is held")
	_done()


func _offline_a_change_stands_at_once_pending_and_nothing_is_sent() -> void:
	_standing()
	_move("a", 4)
	_move("b", 7)
	_verdict.check(_places == {"a": 4, "b": 7} and _provisional.get_pending() == {"a": 1, "b": 1}, "offline, changes stand at once and are pending: %s %s" % [_places, _provisional.get_pending()])
	_verdict.check(_far.sent.is_empty() and _outbox.get_held() == 2, "and nothing reaches the far side, two held: %d" % _outbox.get_held())
	_done()


func _back_online_what_was_held_is_sent_oldest_first_and_kept_on_a_yes() -> void:
	_standing()
	_move("a", 4)
	_move("b", 7)
	_connection.set_state(Connection.CONNECTED)
	await process_frame
	var arrived: Array = _far.sent.map(func(one: Array) -> Dictionary: return one[0])
	_verdict.check(arrived == [{"thing": "a", "to": 4}, {"thing": "b", "to": 7}] and _outbox.get_held() == 0, "back online, what the outbox follows moved: everything held is sent at the frame's end, oldest first, and nothing is held: %s" % [arrived])
	_connection.set_state(Connection.LOST)
	await process_frame
	_connection.set_state(Connection.CONNECTED)
	await process_frame
	_verdict.check(_far.sent.size() == 2, "and nothing is sent twice: %d" % _far.sent.size())
	_far.sent[0][1].call(null)
	_far.sent[1][1].call(null)
	_verdict.check(_places == {"a": 4, "b": 7} and _provisional.get_pending().is_empty(), "the far side's yes keeps them, and nothing is pending: %s" % [_provisional.get_pending()])
	_done()


func _refused_on_sync_it_rolls_back_saying_why() -> void:
	_standing()
	_move("a", 4)
	_connection.set_state(Connection.CONNECTED)
	await process_frame
	_far.sent[0][1].call(Phrase.of("a was moved by someone else"))
	var said: Array = _notices.get_standing().map(func(one: Dictionary) -> String: return str(one["words"]))
	_verdict.check(_places["a"] == 1 and str(_provisional.get_refused().get("a")) == "a was moved by someone else", "refused on sync, the change rolls back and its reason is kept on it: %s" % [_places])
	_verdict.check(said == ["a to 4 was not kept: a was moved by someone else"], "and a notification says it: %s" % [said])
	_done()
