extends SceneTree

## The driver (driver.gd) with its applier (applier.gd) on a real tree:
## navigation through the command door, the fixed order carried out
## whichever way the places were built, blocking under an overlay, the
## focus given back to the opener - by key, by click, layer by layer, and
## to the default when the opener is gone - a state's remembered focus, the
## panel that blocks nothing, the tokens of a stay, and one bell per
## transition.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_driver.gd
##
## The tree is the guided demo's shape: an app with a strip of two buttons
## and a content place holding a home (SAVE) and a ledger whose tabs are the
## coins (COUNT, ZOOM) and the notes (JOT); a zoom (CLOSE) and a confirm
## (OK) beside the app, and a card whose tabs are the front (FLIP) and the
## rear (DONE); and a console (LINE) beside it that blocks nothing. Every
## place records its filling and emptying, and its children asked for, into
## one log.

const Belfry := preload("res://addons/gd_chime/belfry.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Commands := preload("res://addons/gd_chime/commands.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Place := preload("res://addons/gd_chime/place.gd")
const Index := preload("res://addons/gd_chime/index.gd")
const StandIn := preload("res://tests/stand_in.gd")
const Applier := preload("res://addons/gd_chime/applier.gd")
const Token := preload("res://addons/gd_chime/token.gd")
const Verdict := preload("res://tests/verdict.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")

const HOME := [&"app", &"content", &"home"]
const COINS := [&"app", &"content", &"ledger", &"coins"]
const NOTES := [&"app", &"content", &"ledger", &"notes"]
const OPENS := &"opens_the_ledger"

var _verdict := Verdict.new()
var _hearing := Hearing.new()
var _log: Array = []  # [name, "fill" or "empty"], in the order it happened


## Counts the refusals pushed as errors.
class Hearing extends Logger:
	var refusals: int = 0

	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array) -> void:
		if error_type == ERROR_TYPE_ERROR:
			refusals += 1


## A place that records its filling and emptying, and counts its children asked for.
class Recording extends "res://addons/gd_chime/place.gd":
	var _log: Array
	var asked: int = 0

	func places() -> Array:
		asked += 1
		return super()

	func _init(chimes: Chimes, named: StringName, driver: Node, log: Array) -> void:
		super(chimes, named, driver)
		_log = log

	func fill() -> void:
		_log.append([name, "fill"])

	func empty() -> void:
		_log.append([name, "empty"])


## Counts the times a bell rang.
class Ear extends RefCounted:
	var rings: int = 0

	func heard(_what: StringName) -> void:
		rings += 1


func _init() -> void:
	OS.add_logger(_hearing)
	# the tree starts on the first frame, and until it has nothing is in it
	await process_frame
	await _verdict.states(_an_arrival_through_the_door_shows_and_fills_outermost_first_and_lands_the_focus_on_the_default)
	await _verdict.states(_leaving_is_innermost_first_and_entering_outermost_first_whichever_order_the_places_were_built)
	await _verdict.states(_a_tab_switch_touches_nothing_above_the_split)
	await _verdict.states(_an_overlay_blocks_everything_beneath_even_a_control_added_while_it_is_up)
	await _verdict.states(_an_arrival_closes_the_overlays_top_first_before_the_path_moves)
	await _verdict.states(_the_focus_returns_to_the_opener_by_key_and_by_click_and_layer_by_layer)
	await _verdict.states(_an_opener_gone_sends_the_focus_to_the_default_of_the_state_on_top_never_the_strip)
	await _verdict.states(_a_state_re_entered_restores_the_control_it_remembers_else_its_default)
	await _verdict.states(_the_panel_blocks_nothing_and_leaves_the_top_path_and_back_alone)
	await _verdict.states(_a_stay_issues_a_token_and_leaving_cancels_it_and_what_was_issued_under_it)
	await _verdict.states(_navigation_is_a_command_seen_in_the_record_and_a_refusal_is_answered)
	await _verdict.states(_one_bell_rings_per_transition_and_none_for_a_refusal)
	await _verdict.states(_places_are_found_by_name_and_a_second_of_one_name_is_refused)
	await _verdict.states(_a_pop_up_lowered_by_an_arrival_is_live_the_next_time_it_is_raised)
	await _verdict.states(_a_screen_closed_under_the_player_is_emptied_as_it_goes_and_one_rebuilt_is_shown_and_filled_as_it_enters)
	await _verdict.states(_a_link_inside_a_pop_up_moves_within_it_and_the_history_stands)
	await _verdict.states(_the_chart_is_read_from_the_tree_once_and_again_only_as_a_place_enters_or_leaves)
	await _verdict.states(_the_bell_rings_once_after_the_effects_with_the_history_moved)
	await _verdict.states(_a_screen_entered_again_opens_on_the_tab_it_was_left_on)
	await _verdict.states(_a_link_with_no_handler_moves_the_reader_and_a_handler_s_refusal_stops_the_move)
	await _verdict.states(_a_prompt_about_to_name_an_action_must_have_something_to_press)
	await _verdict.states(_a_place_filled_with_a_parameter_knows_which_and_state_kept_with_the_entry_survives_a_detour)
	await _verdict.states(_a_kept_thing_is_let_go_with_its_entry_and_a_node_is_refused_on_the_way_in)
	OS.remove_logger(_hearing)
	quit(_verdict.deliver(get_script()))


## The tree, built screen-first or tab-first as asked, in the tree with the
## commands and the driver, and the reader arrived at the home, as {chimes,
## commands, driver, places, buttons}.
func _made(screen_first: bool = true, arrive: bool = true) -> Dictionary:
	_log.clear()
	var chimes := Chimes.new(Belfry.new())
	var driver := Driver.new(chimes)
	var commands := Commands.new(chimes, driver)
	root.add_child(commands)
	root.add_child(driver)
	var places: Dictionary = {}
	var names: Array = [&"app", &"content", &"home", &"ledger", &"coins", &"notes", &"zoom", &"confirm", &"card", &"front", &"rear", &"console"]
	if not screen_first:
		names.reverse()
	# every place, made in the order asked
	for named: StringName in names:
		places[named] = Recording.new(chimes, named, driver, _log)
	var buttons: Dictionary = {}
	# every button, built for the place it sits in
	var sits_in := {"back": &"app", "ledger": &"app", "save": &"home", "count": &"coins", "zoom": &"coins", "jot": &"notes", "close": &"zoom", "ok": &"confirm", "flip": &"front", "done": &"rear", "line": &"console"}
	for named: String in sits_in:
		buttons[named] = StandIn.new(chimes, commands, places[sits_in[named]], StringName(named))
	var strip := Control.new()
	places[&"app"].add_child(strip)
	strip.add_child(buttons["back"])
	strip.add_child(buttons["ledger"])
	places[&"app"].add_child(places[&"content"])
	places[&"content"].add_child(places[&"home"])
	places[&"home"].add_child(buttons["save"])
	places[&"content"].add_child(places[&"ledger"])
	var tabs := Control.new()
	places[&"ledger"].add_child(tabs)
	tabs.add_child(places[&"coins"])
	places[&"coins"].add_child(buttons["count"])
	places[&"coins"].add_child(buttons["zoom"])
	tabs.add_child(places[&"notes"])
	places[&"notes"].add_child(buttons["jot"])
	places[&"zoom"].add_child(buttons["close"])
	places[&"confirm"].add_child(buttons["ok"])
	places[&"card"].add_child(places[&"front"])
	places[&"front"].add_child(buttons["flip"])
	places[&"card"].add_child(places[&"rear"])
	places[&"rear"].add_child(buttons["done"])
	places[&"console"].add_child(buttons["line"])
	places[&"console"].blocks = false
	driver.index.app = places[&"app"]
	# every root into the tree
	for named: StringName in [&"app", &"zoom", &"confirm", &"card", &"console"]:
		root.add_child(places[named])
	var made := {"chimes": chimes, "commands": commands, "driver": driver, "places": places, "buttons": buttons}
	if arrive:
		_go(made, HOME)
	return made


func _done(made: Dictionary) -> void:
	# every root before the driver they leave, then the rest
	for named: StringName in [&"app", &"zoom", &"confirm", &"card", &"console"]:
		(made["places"][named] as Node).free()
	(made["driver"] as Node).free()
	(made["commands"] as Node).free()


## The reader taken to the last place of this path through the door, the
## answer handed back.
func _go(made: Dictionary, path: Array) -> Phrase:
	return (made["commands"] as Commands).dispatch(Chimes.GLOBAL, Driver.GO, {"place": path.back()})


func _raise(made: Dictionary, named: StringName) -> Phrase:
	return (made["commands"] as Commands).dispatch(Chimes.GLOBAL, Driver.GO, {"place": named})


func _lower(made: Dictionary, named: StringName) -> Phrase:
	return (made["commands"] as Commands).dispatch(Chimes.GLOBAL, Driver.LOWERS, {"place": named})


func _back(made: Dictionary) -> Phrase:
	return (made["commands"] as Commands).dispatch(Chimes.GLOBAL, Driver.GOES_BACK, {})


## This place declaring the action goes there, and the action pressed in it.
func _link(made: Dictionary, from: StringName, action: StringName, to: StringName) -> Phrase:
	(made["places"][from] as Place).performs[action] = to
	return (made["commands"] as Commands).dispatch(from, action, {})


## Which places are shown, in one fixed order.
func _shown(made: Dictionary) -> Array:
	var shown: Array = []
	# every place, kept if visible
	for named: StringName in [&"app", &"content", &"home", &"ledger", &"coins", &"notes", &"zoom", &"confirm", &"card", &"front", &"rear", &"console"]:
		if (made["places"][named] as Control).visible:
			shown.append(named)
	return shown


## The name of the button holding the focus.
func _focused(made: Dictionary) -> String:
	# every button, for the one with the focus
	for named: String in made["buttons"]:
		if (made["buttons"][named] as StandIn).has_focus():
			return named
	return "nothing"


func _an_arrival_through_the_door_shows_and_fills_outermost_first_and_lands_the_focus_on_the_default() -> void:
	var made := _made(true, false)
	_verdict.check(_shown(made).is_empty() and _log.is_empty(), "before the first arrival nothing is shown and nothing filled: %s" % [_shown(made)])
	var answer := _go(made, [&"app"])
	_verdict.check(answer == null and (made["driver"] as Driver).get_top() == HOME, "an arrival at the app lands on the home: %s" % [(made["driver"] as Driver).get_top()])
	_verdict.check(_shown(made) == [&"app", &"content", &"home"], "the app, the content and the home are shown: %s" % [_shown(made)])
	_verdict.check(_log == [[&"app", "fill"], [&"content", "fill"], [&"home", "fill"]], "and filled outermost first: %s" % [_log])
	_verdict.check(_focused(made) == "save", "with the focus on the home's default, SAVE: %s" % _focused(made))
	_verdict.check((made["driver"] as Driver).get_state()["history"] == [HOME], "and the history in the state holds the path it landed on, resolved: %s" % [(made["driver"] as Driver).get_state()["history"]])
	_done(made)


func _leaving_is_innermost_first_and_entering_outermost_first_whichever_order_the_places_were_built() -> void:
	# both build orders, the same story
	for screen_first: bool in [true, false]:
		var made := _made(screen_first)
		_log.clear()
		_go(made, COINS)
		_verdict.check(_log == [[&"home", "empty"], [&"ledger", "fill"], [&"coins", "fill"]], "built %s, home to coins: the home emptied, the ledger filled before its tab: %s" % ["screen-first" if screen_first else "tab-first", _log])
		_log.clear()
		_go(made, HOME)
		_verdict.check(_log == [[&"coins", "empty"], [&"ledger", "empty"], [&"home", "fill"]], "and back home: the tab emptied before its screen, then the home filled: %s" % [_log])
		_done(made)


func _a_tab_switch_touches_nothing_above_the_split() -> void:
	var made := _made()
	_go(made, COINS)
	_log.clear()
	var was_shown := _shown(made)
	_go(made, NOTES)
	_verdict.check(_log == [[&"coins", "empty"], [&"notes", "fill"]], "coins to notes: the coins emptied, the notes filled, the ledger and above untouched: %s" % [_log])
	_verdict.check(_shown(made) == [&"app", &"content", &"ledger", &"notes"] and was_shown == [&"app", &"content", &"ledger", &"coins"], "the notes in the coins' place, the rest as it was: %s" % [_shown(made)])
	_done(made)


func _an_overlay_blocks_everything_beneath_even_a_control_added_while_it_is_up() -> void:
	var made := _made()
	_go(made, COINS)
	var count: StandIn = made["buttons"]["count"]
	var close: StandIn = made["buttons"]["close"]
	_raise(made, &"zoom")
	var added := Button.new()
	(made["places"][&"coins"] as Node).add_child(added)
	_verdict.check(count.get_focus_mode_with_override() == Control.FOCUS_NONE and count.get_mouse_filter_with_override() == Control.MOUSE_FILTER_IGNORE, "the zoom up, the count beneath takes neither the keys nor the mouse")
	_verdict.check(added.get_focus_mode_with_override() == Control.FOCUS_NONE and added.get_mouse_filter_with_override() == Control.MOUSE_FILTER_IGNORE, "nor does a button added beneath while it is up")
	_verdict.check(close.get_focus_mode_with_override() == Control.FOCUS_ALL and close.find_next_valid_focus() == close, "the zoom's close is live, and a Tab from it goes nowhere else")
	_verdict.check((made["driver"] as Driver).is_reachable(close.action) and not (made["driver"] as Driver).is_reachable(count.action), "and only the zoom can be reached")
	_lower(made, &"zoom")
	_verdict.check(count.get_focus_mode_with_override() == Control.FOCUS_ALL and added.get_focus_mode_with_override() == Control.FOCUS_ALL, "lowered, both are live again")
	_done(made)


func _an_arrival_closes_the_overlays_top_first_before_the_path_moves() -> void:
	var made := _made()
	_go(made, COINS)
	_raise(made, &"zoom")
	_raise(made, &"confirm")
	_log.clear()
	_go(made, HOME)
	_verdict.check(_log == [[&"confirm", "empty"], [&"zoom", "empty"], [&"coins", "empty"], [&"ledger", "empty"], [&"home", "fill"]], "the confirm, then the zoom, then the coins and the ledger emptied, then the home filled: %s" % [_log])
	_verdict.check(not (made["driver"] as Driver).is_raised() and _shown(made) == [&"app", &"content", &"home"], "nothing is up and the home is shown: %s" % [_shown(made)])
	_verdict.check((made["buttons"]["count"] as StandIn).get_focus_mode_with_override() == Control.FOCUS_ALL, "and the app is live")
	_done(made)


func _the_focus_returns_to_the_opener_by_key_and_by_click_and_layer_by_layer() -> void:
	var made := _made()
	_go(made, COINS)
	(made["buttons"]["count"] as StandIn).grab_focus()
	_raise(made, &"zoom")
	_verdict.check(_focused(made) == "close", "the zoom up by key from COUNT, its default CLOSE has the focus: %s" % _focused(made))
	_lower(made, &"zoom")
	_verdict.check(_focused(made) == "count", "lowered, the focus is back on COUNT, which opened it: %s" % _focused(made))

	# a click: the button takes the focus and raises in the same frame
	(made["buttons"]["zoom"] as StandIn).grab_focus()
	_raise(made, &"zoom")
	_lower(made, &"zoom")
	_verdict.check(_focused(made) == "zoom", "opened by a click on ZOOM, lowered, the focus is on ZOOM: %s" % _focused(made))

	_raise(made, &"zoom")
	_raise(made, &"confirm")
	_verdict.check(_focused(made) == "ok", "the confirm over the zoom, OK has the focus: %s" % _focused(made))
	_lower(made, &"confirm")
	_verdict.check(_focused(made) == "close", "the confirm lowered, back on CLOSE: %s" % _focused(made))
	_lower(made, &"zoom")
	_verdict.check(_focused(made) == "zoom", "and the zoom lowered, back on ZOOM: %s" % _focused(made))
	_done(made)


func _an_opener_gone_sends_the_focus_to_the_default_of_the_state_on_top_never_the_strip() -> void:
	var made := _made()
	_go(made, COINS)
	(made["buttons"]["count"] as StandIn).grab_focus()
	_raise(made, &"zoom")
	(made["buttons"]["count"] as StandIn).free()
	made["buttons"].erase("count")
	_lower(made, &"zoom")
	_verdict.check(_focused(made) == "zoom", "COUNT gone while the zoom was up, the focus goes to the coins' default, ZOOM, not the strip: %s" % _focused(made))
	_done(made)


func _a_state_re_entered_restores_the_control_it_remembers_else_its_default() -> void:
	var made := _made()
	_go(made, COINS)
	(made["buttons"]["zoom"] as StandIn).grab_focus()
	_go(made, NOTES)
	_verdict.check(_focused(made) == "jot", "on the notes, the focus is on its default, JOT: %s" % _focused(made))
	_back(made)
	_verdict.check(_focused(made) == "zoom", "Back on the coins, the focus is on ZOOM, where it was in that entry: %s" % _focused(made))
	_go(made, NOTES)
	(made["buttons"]["zoom"] as StandIn).free()
	made["buttons"].erase("zoom")
	_back(made)
	_verdict.check(_focused(made) == "count", "ZOOM gone meanwhile, Back on the coins finds their default COUNT: %s" % _focused(made))
	_done(made)


func _the_panel_blocks_nothing_and_leaves_the_top_path_and_back_alone() -> void:
	var made := _made()
	_go(made, COINS)
	var driver: Driver = made["driver"]
	var count: StandIn = made["buttons"]["count"]
	count.grab_focus()
	_raise(made, &"console")
	_verdict.check(_focused(made) == "line" and (made["places"][&"console"] as Control).visible, "the console up, its line has the focus")
	_verdict.check(count.get_focus_mode_with_override() == Control.FOCUS_ALL and driver.is_reachable(count.action) and not driver.is_reachable((made["buttons"]["line"] as StandIn).action), "and the count beneath is live and reachable, the line not: the top path is the app's")
	_verdict.check(driver.get_top() == COINS and not driver.is_raised(), "the top path is the coins and nothing is raised: %s" % [driver.get_top()])
	_back(made)
	_verdict.check(driver.get_top() == HOME and (made["places"][&"console"] as Control).visible, "Back takes the history back and leaves the console up: %s" % [driver.get_top()])
	_lower(made, &"console")
	_verdict.check(_focused(made) == "save", "the console lowered, the focus goes to the home's default, COUNT being hidden: %s" % _focused(made))
	_done(made)


func _a_stay_issues_a_token_and_leaving_cancels_it_and_what_was_issued_under_it() -> void:
	var made := _made()
	var home: Place = made["places"][&"home"]
	var token: Token = home.token
	_verdict.check(token != null and token.is_live(), "arrived at the home, its token is live")
	var loading := Token.new(token)
	_go(made, COINS)
	_verdict.check(not token.is_live() and not loading.is_live(), "left, the token is dead and so is one issued under it")
	_go(made, HOME)
	_verdict.check(home.token != token and home.token.is_live(), "entered again, a new token is live")
	_done(made)


func _navigation_is_a_command_seen_in_the_record_and_a_refusal_is_answered() -> void:
	var made := _made()
	var commands: Commands = made["commands"]
	var before := _hearing.refusals
	_go(made, COINS)
	_verdict.check(commands.get_last()["action"] == Driver.GO and commands.get_last()["answer"] == null, "an arrival is in the record as a command that ran: %s" % [commands.get_last()])
	var again := _go(made, COINS)
	_verdict.check(str(again) == "Already at coins" and commands.get_last()["answer"] == again, "an arrival where the reader is is answered with a refusal, in the record too: %s" % again)
	_verdict.check(str(_lower(made, &"zoom")) == "zoom is not on top" and str(_raise(made, &"attic")) == "attic is no state", "lowering what is not up and going to no state are refused")
	_go(made, HOME)
	_verdict.check(_back(made) == null and (made["driver"] as Driver).get_top() == COINS, "home again by a link is an entry of its own, so Back returns to the coins: %s" % [(made["driver"] as Driver).get_top()])
	_verdict.check(_back(made) == null and str(_back(made)) == "There is nothing to go back to", "then Back to the first home, then refused")
	_verdict.check(_hearing.refusals == before, "and none of it was pushed as an error: %d" % (_hearing.refusals - before))
	_done(made)


func _one_bell_rings_per_transition_and_none_for_a_refusal() -> void:
	var made := _made()
	var ear := Ear.new()
	(made["chimes"] as Chimes).listen(ear, Chimes.GLOBAL, Driver.NAVIGATED)
	_go(made, COINS)
	_raise(made, &"zoom")
	_raise(made, &"confirm")
	_go(made, HOME)
	_verdict.check(ear.rings == 4, "an arrival, two raisings and an arrival that lowered both: four rings, one each: %d" % ear.rings)
	_go(made, HOME)
	_verdict.check(ear.rings == 4, "and a refused arrival rings nothing")
	_done(made)


func _places_are_found_by_name_and_a_second_of_one_name_is_refused() -> void:
	var made := _made()
	var driver: Driver = made["driver"]
	var before := _hearing.refusals
	_verdict.check(driver.index.place_named(&"coins") == made["places"][&"coins"], "a place is found by its name")
	var twin := Place.new(made["chimes"], &"coins", driver)
	root.add_child(twin)
	_verdict.check(_hearing.refusals == before + 1 and driver.index.place_named(&"coins") == made["places"][&"coins"], "a second of the name is refused out loud and the first keeps it")
	twin.free()
	_verdict.check(driver.index.place_named(&"attic") == null and _hearing.refusals == before + 2, "a name that is no place is refused out loud")
	_verdict.check(driver.path_of(made["buttons"]["save"]) == HOME and driver.path_of(made["buttons"]["close"]).is_empty(), "the path of a node is its layer's, and nothing for a root not up")
	_done(made)


func _a_pop_up_lowered_by_an_arrival_is_live_the_next_time_it_is_raised() -> void:
	var made := _made()
	_go(made, COINS)
	_raise(made, &"zoom")
	_raise(made, &"confirm")
	_go(made, HOME)
	_go(made, COINS)
	_raise(made, &"zoom")
	var close: StandIn = made["buttons"]["close"]
	_verdict.check(close.get_focus_mode_with_override() == Control.FOCUS_ALL and close.get_mouse_filter_with_override() == Control.MOUSE_FILTER_STOP, "the zoom, switched off under the confirm and lowered by an arrival, takes the keys and the mouse when raised again")
	_verdict.check(_focused(made) == "close", "and its default has the focus: %s" % _focused(made))
	_done(made)


func _a_screen_closed_under_the_player_is_emptied_as_it_goes_and_one_rebuilt_is_shown_and_filled_as_it_enters() -> void:
	var made := _made()
	_go(made, COINS)
	var old: Place = made["places"][&"coins"]
	var loading := Token.new(old.token)
	var tabs: Node = old.get_parent()
	_log.clear()
	tabs.remove_child(old)
	_verdict.check(_log == [[&"coins", "empty"]] and not loading.is_live(), "the coins taken out of the tree while the player is on them are emptied as they go, and what they set loading is dead: %s" % [_log])
	old.free()
	_log.clear()
	var rebuilt := Recording.new(made["chimes"], &"coins", made["driver"], _log)
	tabs.add_child(rebuilt)
	tabs.move_child(rebuilt, 0)
	made["places"][&"coins"] = rebuilt
	_verdict.check(rebuilt.visible and _log == [[&"coins", "fill"]] and rebuilt.token != null and rebuilt.token.is_live(), "the coins rebuilt while the player is on them are shown and filled as they enter, with a live token: %s" % [_log])
	var before := _hearing.refusals
	_go(made, HOME)
	_verdict.check(_log == [[&"coins", "fill"], [&"coins", "empty"], [&"ledger", "empty"], [&"home", "fill"]] and _hearing.refusals == before, "and leaving them empties the rebuilt coins without a word: %s" % [_log])
	_done(made)


func _a_link_inside_a_pop_up_moves_within_it_and_the_history_stands() -> void:
	var made := _made()
	var commands: Commands = made["commands"]
	var driver: Driver = made["driver"]
	_go(made, COINS)
	_raise(made, &"card")
	_verdict.check(driver.get_top() == [&"card", &"front"] and _focused(made) == "flip", "the card raised is on its front: %s" % [driver.get_top()])
	var walked: Array = driver.get_state()["history"]
	_log.clear()
	_verdict.check(_link(made, &"front", &"flips", &"rear") == null and driver.get_top() == [&"card", &"rear"], "a link to the rear moves within the card: %s" % [driver.get_top()])
	_verdict.check(_log == [[&"front", "empty"], [&"rear", "fill"]] and _focused(made) == "done", "the front emptied, the rear filled, its default focused: %s, %s" % [_log, _focused(made)])
	_verdict.check(driver.get_state()["history"] == walked and driver.path_of(made["buttons"]["count"]) == COINS, "and the history and the app beneath stand")
	_verdict.check(_link(made, &"rear", &"flips", &"front") == null and _lower(made, &"card") == null and _focused(made) == "count", "flipped back and lowered, the focus returns beneath: %s" % _focused(made))
	_done(made)


func _the_chart_is_read_from_the_tree_once_and_again_only_as_a_place_enters_or_leaves() -> void:
	var made := _made()
	var ledger: Recording = made["places"][&"ledger"]
	var asked := ledger.asked
	_go(made, COINS)
	_go(made, NOTES)
	_raise(made, &"zoom")
	_back(made)
	_verdict.check(ledger.asked == asked, "four moves after the first, the ledger is not asked for its children again: %d" % (ledger.asked - asked))
	var extra := Recording.new(made["chimes"], &"extra", made["driver"], _log)
	(made["places"][&"home"] as Node).add_child(extra)
	_go(made, HOME)
	_verdict.check(ledger.asked == asked + 1, "a place entered, the chart is read again on the next move, once: %d" % (ledger.asked - asked))
	_done(made)


## Hears the driver and notes whether the home was shown at the ring.
class Peek extends RefCounted:
	var home: Control
	var shown_at_ring: Array = []

	func _init(place: Control) -> void:
		home = place

	func heard(_what: StringName) -> void:
		shown_at_ring.append(home.visible)


func _a_screen_entered_again_opens_on_the_tab_it_was_left_on() -> void:
	var made := _made()
	var driver: Driver = made["driver"]
	_go(made, NOTES)
	_go(made, HOME)
	_go(made, [&"app", &"content", &"ledger"])
	_verdict.check(driver.get_top() == NOTES and _focused(made) == "jot", "the ledger left on the notes opens on the notes again, JOT focused: %s" % [driver.get_top()])
	_go(made, HOME)
	var notes: Node = made["places"][&"notes"]
	notes.get_parent().remove_child(notes)
	notes.free()
	made["places"].erase(&"notes")
	_go(made, [&"app", &"content", &"ledger"])
	_verdict.check(driver.get_top() == COINS, "the notes closed meanwhile, the ledger opens on its first tab: %s" % [driver.get_top()])
	_done(made)


## A button that answers whether it can be used.
class Gated extends Button:
	var usable := true

	func is_usable() -> bool:
		return usable


func _the_bell_rings_once_after_the_effects_with_the_history_moved() -> void:
	var made := _made()
	_go(made, COINS)
	var peek := Peek.new(made["places"][&"home"])
	(made["chimes"] as Chimes).listen(peek, Chimes.GLOBAL, Driver.NAVIGATED)
	_go(made, HOME)
	_verdict.check(peek.shown_at_ring == [true], "when the driver rings for the arrival home, the home is already shown: %s" % [peek.shown_at_ring])
	_verdict.check((made["driver"] as Driver).get_state()["history"] == [HOME, COINS, HOME], "and the history has moved by then, the home added: %s" % [(made["driver"] as Driver).get_state()["history"]])
	_done(made)


## Refuses every command asked of it, and is never told one.
class Refusing extends RefCounted:
	var told_count: int = 0

	func would(_action: StringName, _payload: Dictionary) -> Phrase:
		return Phrase.of("not now")

	func told(_action: StringName, _payload: Dictionary) -> Phrase:
		told_count += 1
		return null


func _a_link_with_no_handler_moves_the_reader_and_a_handler_s_refusal_stops_the_move() -> void:
	var made := _made()
	var commands: Commands = made["commands"]
	var driver: Driver = made["driver"]
	var before := _hearing.refusals
	_verdict.check(_link(made, &"app", OPENS, &"ledger") == null and driver.get_top() == COINS, "a link with no handler registered moves the reader where the app declares, with no word: %s" % [driver.get_top()])
	_verdict.check(commands.get_last()["action"] == OPENS and _hearing.refusals == before, "and the record names the link's action")
	_verdict.check(_link(made, &"app", OPENS, &"zoom") == null and driver.is_raised(), "a link to a root beside the app raises it")
	_verdict.check(_link(made, &"zoom", &"closes", Driver.BACK) == null and not driver.is_raised(), "and a link back lowers it")
	_verdict.check(str(_link(made, &"app", OPENS, &"attic")) == "attic is no place to go to", "a link to no place is refused")
	_verdict.check(str(commands.dispatch(&"app", OPENS, {"goes_to": &"ledger"})) == "attic is no place to go to", "and a payload saying where to go changes nothing: the declaration decides")
	var refusing := Refusing.new()
	commands.register(Chimes.GLOBAL, &"leaves", refusing)
	_verdict.check(str(_link(made, &"app", &"leaves", &"home")) == "not now" and driver.get_top() == COINS and refusing.told_count == 0, "a handler refusing stops the move, its refusal is the answer, and it is never told: %s" % [driver.get_top()])
	_verdict.check(str(_link(made, &"app", OPENS, &"coins")) == "Already at coins" and str(commands.get_last()["answer"]) == "Already at coins", "and a move the chart refuses is the answer too")
	_done(made)


## The guide would send the reader to a place and name an action with
## nothing to press: asked as a prompt is about to name an action, a place
## on the screen declaring it that nothing under it draws is reported -
## unless the game refuses it, an empty shop's buy or a place still
## loading, which is the handler's to refuse; and a place off the screen is
## nobody's business yet.
func _a_prompt_about_to_name_an_action_must_have_something_to_press() -> void:
	var made := _made()
	var commands: Commands = made["commands"]
	var driver: Driver = made["driver"]
	(made["places"][&"home"] as Place).performs[&"dances"] = &""
	(made["places"][&"home"] as Place).performs[&"buys"] = &""
	(made["places"][&"coins"] as Place).performs[&"dances"] = &""
	commands.register(Chimes.GLOBAL, &"buys", Refusing.new())
	var before := _hearing.refusals
	driver.check_drawn(&"save")
	driver.check_drawn(&"buys")
	_verdict.check(_hearing.refusals == before, "at home, the save is drawn and the buy refused: nothing reported: %d" % (_hearing.refusals - before))
	driver.check_drawn(&"dances")
	_verdict.check(_hearing.refusals == before + 1, "the dance declared and nothing drawing it: reported once: %d" % (_hearing.refusals - before))
	(made["places"][&"app"] as Place).performs[&"count"] = &""
	driver.check_drawn(&"count")
	_verdict.check(_hearing.refusals == before + 2, "the app declaring the count that only the coins, a place within, draw: reported, a place within is its own: %d" % (_hearing.refusals - before))
	_raise(made, &"zoom")
	driver.check_drawn(&"dances")
	_verdict.check(_hearing.refusals == before + 2, "the zoom up, the home is off the screen: not reported: %d" % (_hearing.refusals - before))
	_done(made)


## A half-typed amount, kept with the view: the reader goes elsewhere and
## comes Back, and it is there; gone Back past, it is gone.
class Entry extends RefCounted:
	var amount: String = ""


func _a_place_filled_with_a_parameter_knows_which_and_state_kept_with_the_entry_survives_a_detour() -> void:
	var made := _made()
	var commands: Commands = made["commands"]
	var driver: Driver = made["driver"]
	var coins: Place = made["places"][&"coins"]
	commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": &"coins", "parameter": 7})
	_verdict.check(coins.parameter == 7 and driver.get_parameter(&"coins") == 7, "the coins entered as 7 know which they are: %s" % [coins.parameter])
	var entry := Entry.new()
	entry.amount = "12"
	driver.keep(&"entry", entry)
	_verdict.check(driver.kept(&"entry") == entry, "an entry kept with the view is read back")
	commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": &"notes"})
	_verdict.check(driver.kept(&"entry") == null, "on another view, nothing is kept under the name")
	commands.dispatch(Chimes.GLOBAL, Driver.GOES_BACK, {})
	_verdict.check(driver.get_top() == COINS and coins.parameter == 7 and driver.kept(&"entry") == entry and entry.amount == "12", "Back returns the coins as 7 with the entry intact: %s" % [driver.kept(&"entry")])
	commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": &"notes"})
	commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": &"coins", "parameter": 7})
	_verdict.check(driver.get_state()["history"].size() == 4 and driver.kept(&"entry") == null, "walked to again by a link, the coins as 7 are an entry of their own, fresh, with nothing kept")
	commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": &"coins", "parameter": 8})
	_verdict.check(driver.kept(&"entry") == null and coins.parameter == 8, "the coins as 8 are another view, with nothing kept")
	# Back through the 8, the second 7 and the notes, to the first visit
	for step: int in 3:
		commands.dispatch(Chimes.GLOBAL, Driver.GOES_BACK, {})
	_verdict.check(coins.parameter == 7 and driver.kept(&"entry") == entry, "and Back through them to the first visit finds its entry again")
	commands.dispatch(Chimes.GLOBAL, Driver.GOES_BACK, {})
	commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": &"coins", "parameter": 7})
	_verdict.check(driver.kept(&"entry") == null, "gone Back past that visit, what was kept with it is let go: the next is fresh")
	_done(made)


## A kept thing is a RefCounted: let go with its entry, it is freed, seen
## through a weak reference; a Node handed in would leak, and is refused
## out loud and not kept.
func _a_kept_thing_is_let_go_with_its_entry_and_a_node_is_refused_on_the_way_in() -> void:
	var made := _made()
	var commands: Commands = made["commands"]
	var driver: Driver = made["driver"]
	commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": &"coins", "parameter": 7})
	var entry := Entry.new()
	var weak: WeakRef = weakref(entry)
	driver.keep(&"entry", entry)
	entry = null
	_verdict.check(weak.get_ref() != null, "kept, the entry lives while its history entry does")
	commands.dispatch(Chimes.GLOBAL, Driver.GOES_BACK, {})
	commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": &"coins", "parameter": 7})
	_verdict.check(driver.get_state()["history"].size() == 2 and driver.kept(&"entry") == null and weak.get_ref() == null, "gone Back past it and walked again, the entry is gone and freed")
	var before := _hearing.refusals
	var node := Node.new()
	driver.keep(&"node", node)
	_verdict.check(_hearing.refusals == before + 1 and driver.kept(&"node") == null, "a Node is refused out loud and not kept")
	node.free()
	_done(made)
