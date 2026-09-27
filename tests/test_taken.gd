extends SceneTree

## What must be true of the record of what the player has taken.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_taken.gd
##
## An action taken from any part performing it is one fact. What is untaken is
## what was tracked and never taken, in the order it was tracked, and an action
## is no action cannot be tracked; what an action does is the register's, so
## nothing here says it. A command the model
## did is its action taken, one it refused is not, and one no part performs
## records nothing; the record hears the commands and nothing tells it. Taking
## before tracking does not make an action never done; what the database held
## counts as taken, and handed in again it replaces what was held. The bell
## rings the first time an action is taken and never again for it, nor for
## tracking or for what the database held. Everything taken is handed back,
## once each. And the record stands in the global region, a reader of it
## hearing it move.
##
## A refusal is heard through a logger that counts only what is pushed as an
## error, as test_actions.gd does. Nothing here is in the tree; a ring comes
## at the frame's end, so a count of them is read a frame on.

const Fixture := preload("res://tests/fixture.gd")
const Belfry := preload("res://addons/gd_chime/belfry.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Commands := preload("res://addons/gd_chime/commands.gd")
const Actions := preload("res://addons/gd_chime/actions.gd")
const Taken := preload("res://addons/gd_chime/taken.gd")
const Verdict := preload("res://tests/verdict.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")

var _verdict := Verdict.new()
var _hearing := Hearing.new()


## Counts what is pushed as an error, which is how the record says no.
class Hearing extends Logger:
	var refusals: int = 0

	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_ERROR:
			refusals += 1


## Stands in for a model told a command: does it, or refuses as it was set to.
class Doer extends RefCounted:
	var refusal: Phrase = null

	func would(_action: StringName, _payload: Dictionary) -> Phrase:
		return null

	func told(_action: StringName, _payload: Dictionary) -> Phrase:
		return refusal


func _init() -> void:
	OS.add_logger(_hearing)
	await _verdict.states(_an_action_taken_from_any_part_performing_it_is_one_fact)
	await _verdict.states(_untaken_is_what_was_tracked_and_never_taken_in_the_order_tracked)
	await _verdict.states(_an_action_no_part_performs_cannot_be_tracked)
	await _verdict.states(_a_command_the_model_did_is_its_action_taken_and_one_refused_is_not)
	await _verdict.states(_taking_before_tracking_does_not_make_it_never_done)
	await _verdict.states(_what_the_database_held_counts_as_taken)
	await _verdict.states(_handing_in_the_flags_again_replaces_what_was_held)
	await _verdict.states(_the_bell_rings_the_first_time_an_action_is_taken_and_never_again)
	await _verdict.states(_everything_taken_is_handed_back_once_each)
	await _verdict.states(_the_record_rings_in_the_global_region)
	OS.remove_logger(_hearing)
	quit(_verdict.deliver(get_script()))


## A register of these actions, each declared once, the record over it, an
## ear on the record's bell, and the commands it hears, as {actions, taken,
## ear, chimes, commands}.
func _performing(named: Array) -> Dictionary:
	var chimes := Chimes.new(Belfry.new())
	var commands := Commands.new(chimes)
	var actions := Actions.new()
	var table: Dictionary = {}
	# every action, declared once with the words of its own name
	for action: StringName in named:
		table[action] = [String(action)]
	actions.declare_all(table)
	var taken := Taken.new(chimes, actions, commands)
	var ear := Fixture.Heard.new(chimes, taken.get_taken)
	return {"actions": actions, "taken": taken, "ear": ear, "chimes": chimes, "commands": commands}


func _done(made: Dictionary) -> void:
	(made["ear"] as Node).free()
	(made["taken"] as Node).free()
	(made["commands"] as Node).free()


## Three parts that start the same thing are one fact, not three: taken from each
## of them in turn, the action is done, and it is handed back once.
func _an_action_taken_from_any_part_performing_it_is_one_fact() -> void:
	var made := _performing([&"opens a record"])
	var taken: Taken = made["taken"]
	taken.track(&"opens a record")

	# three parts performing the one action, each taking it in turn
	for _part: int in 3:
		taken.take(&"opens a record")

	_verdict.check(taken.untaken().is_empty(), "the action is done: %s" % [taken.untaken()])
	_verdict.check(taken.get_taken() == [&"opens a record"], "and handed back once: %s" % [taken.get_taken()])
	_done(made)


## Only what is tracked is asked about, so the list stays a short chosen one, and
## taking one action leaves the others on it in the order they were tracked.
func _untaken_is_what_was_tracked_and_never_taken_in_the_order_tracked() -> void:
	var made := _performing([&"opens a record", &"starts a run", &"changes a setting", &"never tracked"])
	var taken: Taken = made["taken"]
	taken.track(&"opens a record")
	taken.track(&"starts a run")
	taken.track(&"changes a setting")

	taken.take(&"starts a run")
	taken.take(&"never tracked")

	_verdict.check(taken.untaken() == [&"opens a record", &"changes a setting"],
		"the tracked actions never taken, in the order tracked: %s" % [taken.untaken()])
	_done(made)


## An action is tracked only once it is in the register, so a
## misspelt action cannot sit untaken forever with nothing to point at. A part
## that does nothing performs no action, so nothing can be tracked through it.
func _an_action_no_part_performs_cannot_be_tracked() -> void:
	var made := _performing([&"opens one"])
	var taken: Taken = made["taken"]

	var before := _hearing.refusals
	taken.track(&"opens two")
	_verdict.check(_hearing.refusals == before + 1, "an action no part performs is refused out loud")
	taken.track(&"")
	_verdict.check(_hearing.refusals == before + 2, "and so is the nothing a part without an action does")
	_verdict.check(taken.untaken().is_empty(), "and neither is asked about: %s" % [taken.untaken()])

	(made["actions"] as Actions).declare_all({&"opens two": ["open the second"]})
	taken.track(&"opens two")
	_verdict.check(taken.untaken() == [&"opens two"], "once it is an action, it is tracked: %s" % [taken.untaken()])
	_done(made)


## The record hears the commands and reads the one that ran: done, its action is
## taken and the bell rings; refused, nothing is taken; done but no part's
## action, nothing is recorded. Nothing tells the record, and it holds no control.
func _a_command_the_model_did_is_its_action_taken_and_one_refused_is_not() -> void:
	var made := _performing([&"opens a record"])
	var taken: Taken = made["taken"]
	var ear: Fixture.Heard = made["ear"]
	var commands: Commands = made["commands"]
	var doer := Doer.new()
	commands.register(Chimes.GLOBAL, &"opens a record", doer)
	commands.register(Chimes.GLOBAL, &"scroll_rows", doer)

	doer.refusal = Phrase.of("not now")
	commands.dispatch(&"home", &"opens a record", {})
	await process_frame
	_verdict.check(taken.get_taken().is_empty() and ear.rung == 0, "a command the model refused takes nothing: %s" % [taken.get_taken()])
	doer.refusal = null
	commands.dispatch(&"home", &"opens a record", {})
	await process_frame
	_verdict.check(taken.get_taken() == [&"opens a record"] and ear.rung == 1, "a command the model did is its action taken, and rings: %s" % [taken.get_taken()])
	commands.dispatch(&"home", &"scroll_rows", {"by": 3})
	await process_frame
	_verdict.check(taken.get_taken() == [&"opens a record"] and ear.rung == 1, "a command no part in the map performs - a wheel's scroll - is not recorded: %s" % [taken.get_taken()])
	_done(made)


## Something done before anyone asked about it has still been done.
func _taking_before_tracking_does_not_make_it_never_done() -> void:
	var made := _performing([&"starts a run"])
	var taken: Taken = made["taken"]
	taken.take(&"starts a run")

	taken.track(&"starts a run")

	_verdict.check(not taken.untaken().has(&"starts a run"), "tracking later does not undo taking: %s" % [taken.untaken()])
	_done(made)


## What the database held is what the player has taken: the record starts from
## the flags it is handed, not from nothing.
func _what_the_database_held_counts_as_taken() -> void:
	var made := _performing([&"opens a record", &"starts a run"])
	var taken: Taken = made["taken"]
	taken.set_taken([&"opens a record"])
	taken.track(&"opens a record")
	taken.track(&"starts a run")

	_verdict.check(taken.untaken() == [&"starts a run"], "an action the database held is not untaken: %s" % [taken.untaken()])
	_verdict.check(taken.get_taken() == [&"opens a record"], "and is handed back as taken: %s" % [taken.get_taken()])
	_done(made)


## Handing in the flags again replaces what was held, so one player's record is
## never added to another's.
func _handing_in_the_flags_again_replaces_what_was_held() -> void:
	var made := _performing([&"opens a record", &"starts a run"])
	var taken: Taken = made["taken"]
	taken.set_taken([&"opens a record"])

	taken.set_taken([&"starts a run"])
	taken.track(&"opens a record")

	_verdict.check(taken.get_taken() == [&"starts a run"], "only the flags handed in last are held: %s" % [taken.get_taken()])
	_verdict.check(taken.untaken() == [&"opens a record"], "so the action held before is untaken again: %s" % [taken.untaken()])
	_done(made)


## A flag changes only the first time an action is taken, so after the flags
## handed in that is the only time the bell rings: whatever keeps the database
## is never woken for a repeat or for tracking.
func _the_bell_rings_the_first_time_an_action_is_taken_and_never_again() -> void:
	var made := _performing([&"opens a record", &"starts a run", &"changes a setting"])
	var taken: Taken = made["taken"]
	var ear: Fixture.Heard = made["ear"]

	taken.set_taken([&"opens a record"])
	await process_frame
	var handed := ear.rung
	taken.track(&"starts a run")
	await process_frame
	_verdict.check(ear.rung == handed, "tracking rang nothing: %d" % (ear.rung - handed))
	taken.take(&"opens a record")
	await process_frame
	_verdict.check(ear.rung == handed, "an action the database held rang nothing: %d" % (ear.rung - handed))
	taken.take(&"starts a run")
	await process_frame
	_verdict.check(ear.rung == handed + 1, "the first time an action is taken rang once: %d" % (ear.rung - handed))
	taken.take(&"starts a run")
	await process_frame
	_verdict.check(ear.rung == handed + 1, "and taking it again rang nothing: %d" % (ear.rung - handed))
	taken.take(&"changes a setting")
	await process_frame
	_verdict.check(ear.rung == handed + 2, "while another action's first time rang again: %d" % (ear.rung - handed))
	_done(made)


## Whatever keeps the database is handed every flag: what it held and what was
## taken since, tracked or not, each once.
func _everything_taken_is_handed_back_once_each() -> void:
	var made := _performing([&"opens a record", &"starts a run", &"never tracked"])
	var taken: Taken = made["taken"]
	taken.set_taken([&"opens a record"])
	taken.track(&"starts a run")

	taken.take(&"starts a run")
	taken.take(&"never tracked")
	taken.take(&"never tracked")

	var held := taken.get_taken()
	_verdict.check(held.size() == 3 and held.has(&"opens a record") and held.has(&"starts a run") and held.has(&"never tracked"),
		"everything taken, once each: %s" % [held])
	_done(made)


## There is one record and it outlives every screen, so it stands in the
## global region, with nothing said about a region when it was made, and a
## reader of what was taken hears it move.
func _the_record_rings_in_the_global_region() -> void:
	var made := _performing([&"opens one"])
	var taken: Taken = made["taken"]
	var ear: Fixture.Heard = made["ear"]

	taken.take(&"opens one")
	await process_frame

	_verdict.check(taken.region == Chimes.GLOBAL, "the record is in the global region: %s" % taken.region)
	_verdict.check(ear.rung == 1, "and a reader of it hears it move: %d" % ear.rung)
	_done(made)
