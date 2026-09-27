extends SceneTree

## What must be true of the reminders.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_reminders.gd
##
## With no control the player can reach, a reminder raises nothing. Only an
## action tracked and never taken with a control that can be reached is ever
## raised, in the register's words. Among several such actions the choice is
## random - over many reminders each is raised - and the same seed chooses
## the same sequence. An action is raised while any control performing it can
## be reached, whichever it is, and not once none can. A control in a place
## off the path cannot be reached. An action never tracked is never reminded
## of. Taking the action being reminded of reminds again at once, of the
## next; taking another leaves it standing. The screen changing reminds.
## Beneath a pop-up nothing is chosen but what is inside it. And it follows
## the record and the driver, in the global region.
##
## The tree is real: an app holding a home and a ledger, a zoom pop-up beside
## it; a control performing an action is a Control in the action's group,
## put in a place. The random source is a generator with a fixed seed, so
## every choice here has one answer.

const Belfry := preload("res://addons/gd_chime/belfry.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Commands := preload("res://addons/gd_chime/commands.gd")
const Actions := preload("res://addons/gd_chime/actions.gd")
const Taken := preload("res://addons/gd_chime/taken.gd")
const Prompts := preload("res://addons/gd_chime/prompts.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Place := preload("res://addons/gd_chime/place.gd")
const Reminders := preload("res://addons/gd_chime/reminders.gd")
const Verdict := preload("res://tests/verdict.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Reads := preload("res://addons/gd_chime/reads.gd")

const SOURCE := &"reminder"
const GAME_MOVED := &"game_moved"
const SEED := 7
const NOTHING := [&"", ""]

var _verdict := Verdict.new()


## A control performing an action: in the action's group.
class Doer extends "res://tests/stand_in.gd":
	pass


## A model that does whatever it is told, and would refuse the actions set;
## what it refuses is a game fact, read as moving on the game's bell.
class Model extends RefCounted:
	var refused: Dictionary = {}  # action -> true while the game refuses it

	func would(action: StringName, _payload: Dictionary) -> Phrase:
		Reads.note(Chimes.GLOBAL, GAME_MOVED)
		return Phrase.of("not now") if refused.has(action) else null

	func told(_action: StringName, _payload: Dictionary) -> Phrase:
		return null


func _init() -> void:
	# the tree starts on the first frame, and until it has nothing is in it
	await process_frame
	await _verdict.states(_with_no_control_to_reach_nothing_is_raised)
	await _verdict.states(_only_an_action_with_a_control_that_can_be_reached_is_raised_in_the_register_s_words)
	await _verdict.states(_among_actions_that_can_be_reached_the_choice_is_random_and_a_seed_repeats_it)
	await _verdict.states(_an_action_is_raised_while_any_control_performing_it_can_be_reached)
	await _verdict.states(_an_action_never_tracked_is_never_reminded_of)
	await _verdict.states(_taking_the_action_reminded_of_reminds_again_at_once)
	await _verdict.states(_the_screen_changing_reminds)
	await _verdict.states(_beneath_a_pop_up_nothing_is_chosen_but_what_is_inside_it)
	await _verdict.states(_it_listens_where_the_record_and_the_driver_ring)
	await _verdict.states(_an_action_the_game_refuses_on_the_screen_is_never_reminded_of)
	await _verdict.states(_a_reminder_is_kept_while_it_can_still_be_reached)
	quit(_verdict.deliver(get_script()))


## The register of three actions, the record tracking two, the prompts, the
## history and the driver over an app holding a home and a ledger with a
## zoom pop-up beside it, and the reminders choosing with a generator of
## this seed, all in the tree. Controls are put in as each property needs.
func _made(seed_given: int = SEED) -> Dictionary:
	var chimes := Chimes.new(Belfry.new())
	var driver := Driver.new(chimes)
	var commands := Commands.new(chimes, driver)
	root.add_child(commands)
	var actions := Actions.new()
	actions.declare_all({&"opens a record": ["opens the record you chose"]})
	actions.declare_all({&"starts a run": ["starts one going"]})
	actions.declare_all({&"changes a setting": ["changes a setting"]})
	# every action, done by one model
	var model := Model.new()
	for action: StringName in actions.get_all():
		commands.register(Chimes.GLOBAL, action, model)
	var taken := Taken.new(chimes, actions, commands)
	taken.track(&"opens a record")
	taken.track(&"starts a run")
	var prompts := Prompts.new(chimes, actions, [SOURCE])
	var random := RandomNumberGenerator.new()
	random.seed = seed_given
	root.add_child(driver)
	var app := Place.new(chimes, &"app", driver)
	var home := Place.new(chimes, &"home", driver)
	var ledger := Place.new(chimes, &"ledger", driver)
	app.add_child(home)
	app.add_child(ledger)
	var zoom := Place.new(chimes, &"zoom", driver)
	driver.index.app = app
	root.add_child(app)
	root.add_child(zoom)
	chimes.register(Chimes.GLOBAL, GAME_MOVED)
	var reminders := Reminders.new(chimes, taken, prompts, SOURCE, random, driver)
	root.add_child(reminders)
	commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": [&"app", &"home"].back()})
	return {chimes = chimes, commands = commands, taken = taken, prompts = prompts, reminders = reminders, driver = driver, home = home, ledger = ledger, zoom = zoom, app = app, model = model}


func _done(made: Dictionary) -> void:
	(made["app"] as Node).free()
	(made["zoom"] as Node).free()
	(made["reminders"] as Node).free()
	(made["driver"] as Node).free()
	(made["prompts"] as Node).free()
	(made["taken"] as Node).free()
	(made["commands"] as Node).free()


## A control performing this action, put in this place.
func _put(made: Dictionary, action: StringName, place: Node) -> Doer:
	var doer := Doer.new(made["chimes"], made["commands"], place, action)
	place.add_child(doer)
	return doer


## What the prompts hold now: the action to glow and its words.
func _current(made: Dictionary) -> Array:
	var prompts: Prompts = made["prompts"]
	return [prompts.get_glowing(), prompts.get_words()]


## The reader taken to this path, a pop-up raised or lowered, through the
## command door, as the buttons do it.
func _go(made: Dictionary, path: Array) -> Phrase:
	return (made["commands"] as Commands).dispatch(Chimes.GLOBAL, Driver.GO, {"place": path.back()})


func _raise(made: Dictionary, named: StringName) -> Phrase:
	return (made["commands"] as Commands).dispatch(Chimes.GLOBAL, Driver.GO, {"place": named})


func _lower(made: Dictionary, named: StringName) -> Phrase:
	return (made["commands"] as Commands).dispatch(Chimes.GLOBAL, Driver.LOWERS, {"place": named})


## The action prompted by each of this many reminders, in order.
func _prompted_by(made: Dictionary, reminders_asked: int) -> Array[StringName]:
	var reminders: Reminders = made["reminders"]
	var prompted: Array[StringName] = []
	# one reminder after another, noting the action each prompted
	for _asked: int in range(reminders_asked):
		reminders.remind()
		prompted.append((made["prompts"] as Prompts).get_glowing())
	return prompted


func _with_no_control_to_reach_nothing_is_raised() -> void:
	var made := _made()
	(made["reminders"] as Reminders).remind()
	_verdict.check(_current(made) == NOTHING, "with nothing to reach, nothing is raised: %s" % [_current(made)])
	_done(made)


func _only_an_action_with_a_control_that_can_be_reached_is_raised_in_the_register_s_words() -> void:
	var made := _made()
	_put(made, &"starts a run", made["home"])

	var prompted := _prompted_by(made, 20)
	_verdict.check(prompted.count(&"starts a run") == 20, "the opening has no control here, so every one of twenty reminders is the run: %s" % [prompted])
	_verdict.check(_current(made) == [&"starts a run", "starts one going"], "in the register's words: %s" % [_current(made)])
	_done(made)


func _among_actions_that_can_be_reached_the_choice_is_random_and_a_seed_repeats_it() -> void:
	var made := _made()
	_put(made, &"opens a record", made["home"])
	_put(made, &"starts a run", made["home"])
	var prompted := _prompted_by(made, 20)
	_verdict.check(prompted.has(&"opens a record") and prompted.has(&"starts a run"), "over twenty reminders both actions are raised: %s" % [prompted])
	_done(made)

	var again := _made()
	_put(again, &"opens a record", again["home"])
	_put(again, &"starts a run", again["home"])
	_verdict.check(_prompted_by(again, 20) == prompted, "and the same seed chooses the same sequence")
	_done(again)


func _an_action_is_raised_while_any_control_performing_it_can_be_reached() -> void:
	var made := _made()
	var reminders: Reminders = made["reminders"]
	_put(made, &"opens a record", made["home"])
	_put(made, &"opens a record", made["ledger"])

	reminders.remind()
	_verdict.check(_current(made)[0] == &"opens a record", "at home, the opening is raised through the home's control: %s" % [_current(made)])
	_go(made, [&"app", &"ledger"])
	_verdict.check(_current(made)[0] == &"opens a record", "at the ledger, through the ledger's: %s" % [_current(made)])
	(made["ledger"] as Node).get_child(0).free()
	reminders.remind()
	_verdict.check(_current(made) == NOTHING, "the ledger's control gone and the home's off the path, nothing can be reached: %s" % [_current(made)])
	_done(made)


func _an_action_never_tracked_is_never_reminded_of() -> void:
	var made := _made()
	_put(made, &"changes a setting", made["home"])

	_verdict.check(_prompted_by(made, 5).count(&"") == 5, "a setting change here but never tracked is never raised")
	_done(made)


func _taking_the_action_reminded_of_reminds_again_at_once() -> void:
	var made := _made()
	var taken: Taken = made["taken"]
	var reminders: Reminders = made["reminders"]
	_put(made, &"opens a record", made["home"])
	_put(made, &"starts a run", made["home"])
	reminders.remind()
	var first: StringName = _current(made)[0]
	var other: StringName = &"starts a run" if first == &"opens a record" else &"opens a record"

	taken.take(other)
	await process_frame
	_verdict.check(_current(made)[0] == first, "taking the other action leaves the reminder standing: %s" % [_current(made)])
	taken.take(first)
	await process_frame
	_verdict.check(_current(made) == NOTHING, "taking the action reminded of reminds again as the record rings - of nothing, both being done: %s" % [_current(made)])
	_done(made)


func _the_screen_changing_reminds() -> void:
	var made := _made()
	_put(made, &"starts a run", made["ledger"])
	_verdict.check(_current(made) == NOTHING, "at home, the run in the ledger is not raised: %s" % [_current(made)])

	_go(made, [&"app", &"ledger"])
	_verdict.check(_current(made) == [&"starts a run", "starts one going"], "arrived at the ledger, the screen changing reminds of it: %s" % [_current(made)])
	_done(made)


## The opening's control is on the home under the zoom, and the zoom has a
## start of its own: with the zoom up, the run is reminded of through the
## zoom's own control and the opening beneath never is; given back, the
## zoom's start is off the top and the opening is what is left.
func _beneath_a_pop_up_nothing_is_chosen_but_what_is_inside_it() -> void:
	var made := _made()
	var driver: Driver = made["driver"]
	_put(made, &"opens a record", made["home"])
	_put(made, &"starts a run", made["zoom"])
	_raise(made, &"zoom")

	var prompted := _prompted_by(made, 20)
	_verdict.check(prompted.count(&"starts a run") == 20, "the zoom up, twenty reminders are all the run, never the opening beneath: %s" % [prompted])
	_lower(made, &"zoom")
	_verdict.check(_current(made) == [&"opens a record", "opens the record you chose"], "given back, the opening is what is left: %s" % [_current(made)])
	_done(made)


func _it_listens_where_the_record_and_the_driver_ring() -> void:
	var made := _made()
	var reminders: Reminders = made["reminders"]

	_verdict.check(reminders.region == Chimes.GLOBAL, "the reminders are in the global region: %s" % reminders.region)
	var follows: Array = (made["chimes"] as Chimes).followed_by(reminders, &"reachable")
	_verdict.check(follows.has([Chimes.GLOBAL, Driver.NAVIGATED]) and follows.has([(made["taken"] as Taken)._values.get_address(), (made["taken"] as Taken)._values.get_address()]), "and follow the record and the driver, read as the reminder was worked out: %s" % [follows])
	_done(made)


## An action on the screen the game refuses is not one that can be
## reached, so it is never chosen; and the game's bell, handed to the
## reminders, reminds again.
func _an_action_the_game_refuses_on_the_screen_is_never_reminded_of() -> void:
	var made := _made()
	var chimes: Chimes = made["chimes"]
	var model: Model = made["model"]
	_put(made, &"opens a record", made["home"])
	_put(made, &"starts a run", made["home"])
	model.refused[&"opens a record"] = true
	_verdict.check(_prompted_by(made, 20).count(&"starts a run") == 20, "the opening refused by the game, twenty reminders are all the run")
	model.refused[&"starts a run"] = true
	chimes.strike(Chimes.GLOBAL, GAME_MOVED)
	_verdict.check(_current(made)[0] == &"", "and the run refused too, the bell rung, nothing is reminded of: %s" % [_current(made)])
	model.refused.erase(&"opens a record")
	chimes.strike(Chimes.GLOBAL, GAME_MOVED)
	_verdict.check(_current(made)[0] == &"opens a record", "the opener shown again, it is: %s" % [_current(made)])
	_done(made)


## Whatever changes, the reminder standing is kept while some control
## performing it can still be reached, so it does not swap under the
## player's eyes; only when none is left is another chosen.
func _a_reminder_is_kept_while_it_can_still_be_reached() -> void:
	var made := _made()
	var chimes: Chimes = made["chimes"]
	_put(made, &"opens a record", made["home"])
	_put(made, &"starts a run", made["home"])
	(made["reminders"] as Reminders).remind()
	var standing: StringName = _current(made)[0]
	var stood := true
	# twenty changes of controls, the reminder read after each
	for change: int in range(20):
		chimes.strike(Chimes.GLOBAL, GAME_MOVED)
		stood = stood and _current(made)[0] == standing
	_verdict.check(stood, "twenty controls changing, the reminder stood through every one: %s" % [_current(made)])
	_go(made, [&"app", &"ledger"])
	_verdict.check(_current(made)[0] == &"", "arrived where neither can be reached, it withdraws")
	_go(made, [&"app", &"home"])
	_verdict.check(_current(made)[0] != &"", "and back home, one is chosen again")
	_done(made)
