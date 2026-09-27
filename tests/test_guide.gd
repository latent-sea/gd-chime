extends SceneTree

## What must be true of the guide.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_guide.gd
##
## Entering the tree, the guide raises its first step: the step's action when
## a control that can be reached performs it, else the first action on the
## way there - Back among them - however far the step is, in the register's
## words for whatever is raised; arriving elsewhere, it raises the way from
## there. The step's action done moves it on to the next, and a reader of
## the step hears it move; refused, or another action, it stays. Past the
## last step it withdraws, is finished, and stays so whatever runs. A saved
## step is resumed and pointed at. A step that is no action is refused out
## loud and left out, the rest kept. With no way from where the player is,
## nothing is raised until an arrival with one. Beneath a pop-up nothing is
## pointed at but what is inside it, and the way out of one is its Back.
## It hears the commands run, follows where the driver is and what the game
## refuses, in the global region.
##
## The tree is the one test_queries.gd walks, real, with the
## layers. A link is a control carrying its action and where it goes, in its
## action's group. The doer registered for every action does or refuses as
## set. A refusal is heard through a logger that counts only what is pushed
## as an error.

const Belfry := preload("res://addons/gd_chime/belfry.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Commands := preload("res://addons/gd_chime/commands.gd")
const Actions := preload("res://addons/gd_chime/actions.gd")
const Prompts := preload("res://addons/gd_chime/prompts.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Place := preload("res://addons/gd_chime/place.gd")
const Guide := preload("res://addons/gd_chime/guide.gd")
const Verdict := preload("res://tests/verdict.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")

const GUIDE := &"guide"
const REMINDER := &"reminder"
const STEPS := [&"saves_the_day", &"counts_a_coin", &"inspects"]
## Every action and its words, declared once.
const WORDS := {&"saves_the_day": "save the day", &"opens_the_ledger": "open the ledger", &"opens_settings": "open the settings", &"shows_coins": "show the coins", &"counts_a_coin": "count a coin in the ledger", &"opens_details": "open the details", &"inspects": "inspect the details", &"opens_details_from_settings": "open the details", &"leaves_settings": "leave the settings", &"goes_back": "go back", &"goes_home": "go home", &"opens_feedback": "open the feedback", &"sends_feedback": "send the feedback", &"finds": "find", &"closes_the_zoom": "close the zoom"}

var _verdict := Verdict.new()
var _hearing := Hearing.new()


## Counts what is pushed as an error, which is how the guide says no.
class Hearing extends Logger:
	var refusals: int = 0

	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_ERROR:
			refusals += 1


## A control that performs an action and may take the reader somewhere.
class Link extends "res://tests/stand_in.gd":
	pass


## A model that does whatever it is told, or refuses everything, as set; and
## an action the game refuses, a value, refused before it is pressed.
class Doer extends "res://addons/gd_chime/controller.gd":
	var refusing: bool = false
	var _refused := value({})  # action -> true while the game refuses it

	func would(action: StringName, _payload: Dictionary) -> Phrase:
		return Phrase.of("not now") if _refused.read().has(action) else null

	func told(_action: StringName, _payload: Dictionary) -> Phrase:
		return Phrase.of("not now") if refusing else null

	## The game refusing this action, or no longer.
	func refuse(action: StringName, refused: bool) -> void:
		var now: Dictionary = _refused.read()
		if refused:
			now[action] = true
		else:
			now.erase(action)
		_refused.set_value(now)


## Counts the times what a read reads moved: it follows the read.
class Ear extends RefCounted:
	var rings: int = 0
	var _chimes: Chimes
	var _read: Callable

	func _init(chimes: Chimes, read: Callable) -> void:
		_chimes = chimes
		_read = read
		chimes.follow(self, &"heard", read, _moved)

	func _moved() -> void:
		rings += 1
		_chimes.follow(self, &"heard", _read, _moved)


func _init() -> void:
	OS.add_logger(_hearing)
	# the tree starts on the first frame, and until it has nothing is in it
	await process_frame
	await _verdict.states(_entering_it_raises_its_first_step_or_the_way_there_in_the_register_s_words)
	await _verdict.states(_arriving_elsewhere_it_raises_the_way_from_there_back_among_them)
	await _verdict.states(_the_step_s_action_done_moves_it_on_and_rings_refused_or_another_leaves_it)
	await _verdict.states(_past_the_last_step_it_withdraws_and_stays_finished)
	await _verdict.states(_a_saved_step_is_resumed_and_pointed_at)
	await _verdict.states(_a_step_that_is_no_action_is_refused_out_loud_and_left_out)
	await _verdict.states(_with_no_way_from_where_the_player_is_nothing_is_raised_until_an_arrival_with_one)
	await _verdict.states(_beneath_a_pop_up_nothing_is_pointed_at_but_what_is_inside_it)
	await _verdict.states(_it_listens_where_the_commands_and_the_driver_ring)
	await _verdict.states(_an_action_the_game_refuses_is_no_way_and_no_step)
	await _verdict.states(_on_a_place_entered_as_one_of_its_kind_the_way_on_is_kept_not_withdrawn)
	OS.remove_logger(_hearing)
	quit(_verdict.deliver(get_script()))


## Everything the guide is built with, in the tree, with these steps and the
## reader arrived at this path, as a dictionary: the doer answers every
## action, an ear counts STEP_MOVED, and the tree is the routes test's.
func _made(steps: Array = STEPS, arrived: Array[StringName] = [&"app", &"content", &"home"]) -> Dictionary:
	var chimes := Chimes.new(Belfry.new())
	var driver := Driver.new(chimes)
	var commands := Commands.new(chimes, driver)
	root.add_child(commands)
	var actions := Actions.new()
	# every action declared with its words, and answered by the doer - but Back, which is the driver's
	var doer := Doer.new(chimes)
	root.add_child(doer)
	var table: Dictionary = {}
	for action: StringName in WORDS:
		table[action] = [WORDS[action]]
		if action != Driver.GOES_BACK:
			commands.register(Chimes.GLOBAL, action, doer)
	actions.declare_all(table)
	var prompts := Prompts.new(chimes, actions, [GUIDE, REMINDER])
	root.add_child(driver)
	var places: Dictionary = {}
	# every place, named
	for named: StringName in [&"app", &"content", &"home", &"ledger", &"coins", &"details", &"settings", &"feedback", &"lost", &"zoom"]:
		places[named] = Place.new(chimes, named, driver)
	var strip := Control.new()
	places[&"app"].add_child(strip)
	strip.add_child(Link.new(chimes, commands, places[&"app"], &"goes_home", &"home"))
	strip.add_child(Link.new(chimes, commands, places[&"app"], &"opens_feedback", &"feedback"))
	strip.add_child(Link.new(chimes, commands, places[&"app"], &"goes_back", Driver.BACK))
	places[&"app"].add_child(places[&"content"])
	places[&"content"].add_child(places[&"home"])
	places[&"home"].add_child(Link.new(chimes, commands, places[&"home"], &"saves_the_day"))
	places[&"home"].add_child(Link.new(chimes, commands, places[&"home"], &"opens_the_ledger", &"ledger"))
	places[&"home"].add_child(Link.new(chimes, commands, places[&"home"], &"opens_settings", &"settings"))
	places[&"content"].add_child(places[&"ledger"])
	places[&"ledger"].add_child(Link.new(chimes, commands, places[&"ledger"], &"shows_coins", &"coins"))
	places[&"ledger"].add_child(places[&"coins"])
	places[&"coins"].add_child(Link.new(chimes, commands, places[&"coins"], &"counts_a_coin"))
	var panel := Control.new()
	places[&"ledger"].add_child(panel)
	panel.add_child(places[&"details"])
	places[&"details"].add_child(Link.new(chimes, commands, places[&"details"], &"inspects"))
	places[&"ledger"].add_child(Link.new(chimes, commands, places[&"ledger"], &"opens_details", &"details"))
	places[&"content"].add_child(places[&"settings"])
	places[&"settings"].add_child(Link.new(chimes, commands, places[&"settings"], &"opens_details_from_settings", &"details"))
	places[&"settings"].add_child(Link.new(chimes, commands, places[&"settings"], &"leaves_settings", &"home"))
	places[&"content"].add_child(places[&"feedback"])
	places[&"feedback"].add_child(Link.new(chimes, commands, places[&"feedback"], &"sends_feedback"))
	places[&"content"].add_child(places[&"lost"])
	places[&"lost"].add_child(Link.new(chimes, commands, places[&"lost"], &"finds"))
	places[&"zoom"].add_child(Link.new(chimes, commands, places[&"zoom"], &"closes_the_zoom", Driver.BACK))
	driver.index.app = places[&"app"]
	root.add_child(places[&"app"])
	root.add_child(places[&"zoom"])
	commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": arrived.back()})
	var guide := Guide.new(chimes, commands, actions, prompts, GUIDE, steps, driver)
	var moved := Ear.new(chimes, guide.get_step)
	root.add_child(guide)
	return {"chimes": chimes, "commands": commands, "prompts": prompts, "doer": doer, "guide": guide, "moved": moved, "driver": driver, "places": places}


func _done(made: Dictionary) -> void:
	(made["guide"] as Node).free()
	(made["doer"] as Node).free()
	(made["places"][&"app"] as Node).free()
	(made["places"][&"zoom"] as Node).free()
	(made["driver"] as Node).free()
	(made["prompts"] as Node).free()
	(made["commands"] as Node).free()


func _current(made: Dictionary) -> Array:
	var prompts: Prompts = made["prompts"]
	return [prompts.get_source(), prompts.get_glowing(), prompts.get_words()]


## The reader taken to this path, a pop-up raised or lowered, through the
## command door, as the buttons do it.
func _go(made: Dictionary, path: Array) -> Phrase:
	return (made["commands"] as Commands).dispatch(Chimes.GLOBAL, Driver.GO, {"place": path.back()})


func _raise(made: Dictionary, named: StringName) -> Phrase:
	return (made["commands"] as Commands).dispatch(Chimes.GLOBAL, Driver.GO, {"place": named})


func _lower(made: Dictionary, named: StringName) -> Phrase:
	return (made["commands"] as Commands).dispatch(Chimes.GLOBAL, Driver.LOWERS, {"place": named})


func _entering_it_raises_its_first_step_or_the_way_there_in_the_register_s_words() -> void:
	var made := _made()
	_verdict.check(_current(made) == [GUIDE, &"saves_the_day", "save the day"], "on home, the first step is raised as itself, with its words: %s" % [_current(made)])
	_done(made)

	var elsewhere := _made([STEPS[1]])
	_verdict.check(_current(elsewhere) == [GUIDE, &"opens_the_ledger", "open the ledger"], "a step in the ledger is raised as the way there - opening it - in the hop's words: %s" % [_current(elsewhere)])
	_done(elsewhere)

	var far := _made([STEPS[2]])
	_verdict.check(_current(far) == [GUIDE, &"opens_the_ledger", "open the ledger"], "a step two hops away is raised as the first hop, in that hop's words: %s" % [_current(far)])
	_done(far)


func _arriving_elsewhere_it_raises_the_way_from_there_back_among_them() -> void:
	var made := _made([STEPS[1]], [&"app", &"content", &"settings"])
	_verdict.check(_current(made) == [GUIDE, &"goes_home", "go home"], "in the settings, the way to the count starts with the strip's home link: %s" % [_current(made)])

	_go(made, [&"app", &"content", &"ledger"])
	_verdict.check(_current(made) == [GUIDE, &"counts_a_coin", "count a coin in the ledger"], "arrived at the ledger, on its coins, the step itself is raised: %s" % [_current(made)])
	_go(made, [&"app", &"content", &"ledger", &"details"])
	_verdict.check(_current(made)[1] == &"goes_back", "wandered on to the details, the way back to the coins is Back: %s" % [_current(made)])
	_done(made)


func _the_step_s_action_done_moves_it_on_and_rings_refused_or_another_leaves_it() -> void:
	var made := _made()
	var commands: Commands = made["commands"]
	var guide: Guide = made["guide"]
	var moved: Ear = made["moved"]

	commands.dispatch(&"home", &"counts_a_coin", {})
	await process_frame
	_verdict.check(guide.get_step() == 0 and moved.rings == 0, "another action done leaves the step: %d" % guide.get_step())
	(made["doer"] as Doer).refusing = true
	commands.dispatch(&"home", &"saves_the_day", {})
	await process_frame
	_verdict.check(guide.get_step() == 0 and moved.rings == 0, "the step's action refused leaves it: %d" % guide.get_step())
	(made["doer"] as Doer).refusing = false
	commands.dispatch(&"home", &"saves_the_day", {})
	await process_frame
	_verdict.check(guide.get_step() == 1 and moved.rings == 1, "the step's action done moves it on and rings: %d" % guide.get_step())
	_verdict.check(_current(made) == [GUIDE, &"opens_the_ledger", "open the ledger"], "and the next step is raised as the way to it: %s" % [_current(made)])
	_done(made)


func _past_the_last_step_it_withdraws_and_stays_finished() -> void:
	var made := _made([STEPS[0]])
	var commands: Commands = made["commands"]
	var guide: Guide = made["guide"]

	commands.dispatch(&"home", &"saves_the_day", {})
	_verdict.check(guide.is_finished() and _current(made) == [&"", &"", ""], "past the last step, finished and withdrawn: %s" % [_current(made)])
	commands.dispatch(&"home", &"saves_the_day", {})
	_go(made, [&"app", &"content", &"ledger"])
	_verdict.check(guide.is_finished() and guide.get_step() == 1 and _current(made) == [&"", &"", ""], "and stays so whatever runs: %s" % [_current(made)])
	_done(made)


func _a_saved_step_is_resumed_and_pointed_at() -> void:
	var made := _made()
	var guide: Guide = made["guide"]

	guide.start_at(2)
	_verdict.check(guide.get_step() == 2, "resumed at the third step")
	_verdict.check(_current(made) == [GUIDE, &"opens_the_ledger", "open the ledger"], "and pointed at, as the first hop of the way there from home: %s" % [_current(made)])
	_done(made)


func _a_step_that_is_no_action_is_refused_out_loud_and_left_out() -> void:
	var before := _hearing.refusals
	var made := _made([&"flies", STEPS[0]])
	var guide: Guide = made["guide"]

	_verdict.check(_hearing.refusals == before + 1, "a step that is no action is refused out loud")
	_verdict.check(_current(made)[1] == &"saves_the_day", "and left out, the rest kept: %s" % [_current(made)])
	(made["commands"] as Commands).dispatch(&"home", &"saves_the_day", {})
	_verdict.check(guide.is_finished(), "one step, then finished: %d" % guide.get_step())
	_done(made)


## No link reaches the lost screen and nothing behind the player leads there,
## so a step to find is pointed at nothing until the player arrives at the
## lost screen by some other means.
func _with_no_way_from_where_the_player_is_nothing_is_raised_until_an_arrival_with_one() -> void:
	var made := _made([&"finds"])
	_verdict.check(_current(made) == [&"", &"", ""], "at home, with no way to the lost screen, nothing is raised: %s" % [_current(made)])

	_go(made, [&"app", &"content", &"lost"])
	_verdict.check(_current(made)[1] == &"finds", "arrived at the lost screen, the step is raised: %s" % [_current(made)])
	_done(made)


## The count is on screen under the zoom, but a pop-up borrows the player:
## the step to count is pointed at through the zoom's Back while it is up,
## and at the count itself once it is given back.
func _beneath_a_pop_up_nothing_is_pointed_at_but_what_is_inside_it() -> void:
	var made := _made([STEPS[1]], [&"app", &"content", &"ledger"])
	var driver: Driver = made["driver"]
	_verdict.check(_current(made)[1] == &"counts_a_coin", "on the coins, the count is pointed at: %s" % [_current(made)])

	_raise(made, &"zoom")
	_verdict.check(_current(made) == [GUIDE, &"closes_the_zoom", "close the zoom"], "the zoom up, the way to the count beneath is the zoom's Back: %s" % [_current(made)])
	_lower(made, &"zoom")
	_verdict.check(_current(made)[1] == &"counts_a_coin", "given back, the count is pointed at again: %s" % [_current(made)])
	_done(made)


func _it_listens_where_the_commands_and_the_driver_ring() -> void:
	var made := _made()
	var guide: Guide = made["guide"]

	_verdict.check(guide.region == Chimes.GLOBAL, "the guide is in the global region: %s" % guide.region)
	var follows: Array = (made["chimes"] as Chimes).followed_by(guide, &"way")
	_verdict.check(guide.listening_to() == [Commands.COMMAND_RAN] and follows.has([Chimes.GLOBAL, Driver.NAVIGATED]) and follows.has([(made["doer"] as Doer)._values.get_address(), (made["doer"] as Doer)._values.get_address()]), "and hears the commands run, and follows where the driver is and what the game refuses, read as the way was worked out: %s %s" % [guide.listening_to(), follows])
	_done(made)


## An action the game refuses is no hop: the way goes round it, through the
## settings and the details, and comes back as the game allows it; the
## refusal read as the way was worked out, its moving points the guide again.
func _an_action_the_game_refuses_is_no_way_and_no_step() -> void:
	var made := _made([STEPS[1]])
	var doer: Doer = made["doer"]
	_verdict.check(_current(made)[1] == &"opens_the_ledger", "on home, the way to the count is the home's ledger link: %s" % [_current(made)])
	doer.refuse(&"opens_the_ledger", true)
	await process_frame
	_verdict.check(_current(made)[1] == &"opens_settings", "the ledger refused by the game, the way goes round through the settings: %s" % [_current(made)])
	doer.refuse(&"opens_the_ledger", false)
	await process_frame
	_verdict.check(_current(made)[1] == &"opens_the_ledger", "shown again, the way is back: %s" % [_current(made)])
	_done(made)


## The reader on the details entered as 5 - through a link carrying the
## entity - with the ledger's own link back to the details on the screen:
## the way to the count is the coins tab, never withdrawn and never a link
## to the details as none, and the step after the inspection is pointed at.
func _on_a_place_entered_as_one_of_its_kind_the_way_on_is_kept_not_withdrawn() -> void:
	var made := _made([STEPS[2], STEPS[1]])
	var commands: Commands = made["commands"]
	commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": &"details", "parameter": 5})
	_verdict.check(_current(made) == [GUIDE, &"inspects", "inspect the details"], "on the details as 5, the inspection is the step: %s" % [_current(made)])
	commands.dispatch(&"details", &"inspects", {})
	_verdict.check(_current(made) == [GUIDE, &"shows_coins", "show the coins"] and (made["driver"] as Driver).get_parameter(&"details") == 5, "done, the way to the count is the coins tab, the prompt kept and the details still 5: %s" % [_current(made)])
	commands.dispatch(&"ledger", &"shows_coins", {})
	_verdict.check(_current(made) == [GUIDE, &"counts_a_coin", "count a coin in the ledger"], "and on the coins the count is the step: %s" % [_current(made)])
	_done(made)
