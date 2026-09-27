extends SceneTree

## The questions (queries.gd) on plain data, no engine: what can be reached,
## and the way to an action found by making the moves on copies of the
## state - a link then Back, Back then a link disabled where you started, a
## link to a tab inside a pop-up, an action only built as its place fills,
## and two states that differ only in a remembered tab; which place asking
## first stops a move, and routing that never leads out of one. Then, on a
## real tree: the driver answering reachable, and a button behind a pop-up
## not glowing.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_queries.gd
##
## The chart is the guided demo's shape - an app holding a content with a
## home and a ledger whose tabs are the coins and the notes, a zoom and a
## card with two tabs beside it, a console as the panel - and what each
## place declares is written here as the demo's places would set it. The
## game's refusals are a dictionary the test edits: an action in it is
## refused on every screen alike.

const Chart := preload("res://addons/gd_chime/chart.gd")
const Events := preload("res://addons/gd_chime/events.gd")
const Queries := preload("res://addons/gd_chime/queries.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Place := preload("res://addons/gd_chime/place.gd")
const Belfry := preload("res://addons/gd_chime/belfry.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Commands := preload("res://addons/gd_chime/commands.gd")
const Actions := preload("res://addons/gd_chime/actions.gd")
const Prompts := preload("res://addons/gd_chime/prompts.gd")
const ActionControl := preload("res://addons/gd_chime/action_control.gd")
const Verdict := preload("res://tests/verdict.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")

const BACK := Driver.BACK
const CHART := {
	"app": &"app",
	"children": {&"app": [&"content"], &"content": [&"home", &"ledger"], &"home": [], &"ledger": [&"coins", &"notes"], &"coins": [], &"notes": [], &"zoom": [], &"card": [&"front", &"rear"], &"front": [], &"rear": [], &"console": []},
	"parent": {&"app": &"", &"content": &"app", &"home": &"content", &"ledger": &"content", &"coins": &"ledger", &"notes": &"ledger", &"zoom": &"", &"card": &"", &"front": &"card", &"rear": &"card", &"console": &""},
	"kind": {&"zoom": Chart.OVERLAY, &"card": Chart.OVERLAY, &"console": Chart.PANEL},
}
## What each place declares: the strip's Back and ledger link on the app,
## the home's deeds, the ledger's tabs, the coins' count and zoom, the notes'
## jot - built only as the notes fill - the zoom's close, the card's flip.
const PERFORMS := {
	&"app": {&"goes_back": BACK, &"opens_the_ledger": &"ledger"},
	&"content": {},
	&"home": {&"saves_the_day": &"", &"opens_settings": &"", &"opens_the_rear": &"rear"},
	&"ledger": {&"shows_coins": &"coins", &"shows_notes": &"notes"},
	&"coins": {&"counts_a_coin": &"", &"zooms": &"zoom"},
	&"notes": {&"jots_a_note": &""},
	&"zoom": {&"closes_the_zoom": BACK},
	&"card": {},
	&"front": {&"flips": &"rear"},
	&"rear": {&"reads_the_rear": &""},
	&"console": {},
}
const HOME := [&"app", &"content", &"home"]
const COINS := [&"app", &"content", &"ledger", &"coins"]

var _verdict := Verdict.new()
var _refused: Dictionary = {}  # action -> the game's refusal, on every screen alike
var _guarded: Dictionary = {}  # place -> the words it asks before it is left, while it asks


func _init() -> void:
	await _verdict.states(_reachable_is_declared_on_the_screen_and_not_refused_by_the_game)
	await _verdict.states(_the_way_is_a_link_then_the_action_or_a_link_then_back)
	await _verdict.states(_back_then_a_link_that_was_not_on_the_screen_where_you_started)
	await _verdict.states(_a_link_to_a_tab_inside_a_pop_up_opens_the_pop_up_on_that_tab)
	await _verdict.states(_an_action_only_built_as_its_place_fills_is_routed_to_by_its_declaration)
	await _verdict.states(_two_states_that_differ_only_in_a_remembered_tab_are_both_searched)
	await _verdict.states(_a_refused_action_is_no_way_and_no_goal)
	await _verdict.states(_an_action_nowhere_to_be_reached_is_given_up_once_every_place_is_searched)
	await _verdict.states(_a_way_through_back_is_found_and_replays_with_a_history_at_its_cap)
	await _verdict.states(_a_simulated_press_keeps_the_parameter_the_place_has_and_invents_none)
	await _verdict.states(_a_move_is_stopped_by_the_first_place_it_empties_that_asks_first_and_a_pop_up_raised_or_lowered_empties_none)
	await _verdict.states(_routing_treats_a_place_asking_first_as_refused_to_leave)
	# the tree starts on the first frame, and until it has nothing is in it
	await process_frame
	await _verdict.states(_on_a_real_tree_the_driver_answers_reachable_and_a_button_behind_a_pop_up_does_not_glow)
	await _verdict.states(_a_way_through_a_link_that_carries_an_entity_is_found_and_replayed_press_by_press)
	quit(_verdict.deliver(get_script()))


## The game's refusal of an action in a place: the dictionary's, or none.
func _would(_place: StringName, action: StringName) -> Phrase:
	return _refused.get(action)


## A state at this path with these paths walked, the last being where the reader is.
func _at(path: Array, history: Array = [], overlays: Array = [], last: Dictionary = {}) -> Dictionary:
	var walked: Array = history if not history.is_empty() else [path]
	return {"path": path, "overlays": overlays, "panel": [], "last": last, "history": walked, "params": {}, "history_params": walked.map(func(_path: Array) -> Dictionary: return {}), "history_ids": range(1, walked.size() + 1), "serial": walked.size()}


func _route(state: Dictionary, action: StringName) -> Array[StringName]:
	return Queries.route(CHART, PERFORMS, state, action, _would, BACK, _guarded)


func _reachable(state: Dictionary, action: StringName) -> bool:
	return Queries.reachable(CHART, PERFORMS, state, action, _would, BACK, _guarded)


func _reachable_is_declared_on_the_screen_and_not_refused_by_the_game() -> void:
	_refused = {}
	_verdict.check(_reachable(_at(COINS), &"counts_a_coin") and _reachable(_at(COINS), &"opens_the_ledger"), "on the coins, the count and the strip's ledger link can be reached")
	_verdict.check(not _reachable(_at(COINS), &"saves_the_day"), "the home's save cannot, its place off the screen")
	_verdict.check(not _reachable(_at(COINS, [], [[&"zoom"]]), &"counts_a_coin") and _reachable(_at(COINS, [], [[&"zoom"]]), &"closes_the_zoom"), "the zoom up, only the zoom's own can be reached")
	_refused = {&"counts_a_coin": Phrase.of("no coins left")}
	_verdict.check(not _reachable(_at(COINS), &"counts_a_coin"), "and an action the game refuses cannot, wherever the reader is")


func _the_way_is_a_link_then_the_action_or_a_link_then_back() -> void:
	_refused = {}
	_verdict.check(_route(_at(HOME), &"counts_a_coin") == [&"opens_the_ledger", &"counts_a_coin"], "from home, the count is the ledger link then the count: %s" % [_route(_at(HOME), &"counts_a_coin")])
	_verdict.check(_route(_at(HOME), &"saves_the_day") == [&"saves_the_day"], "an action on the screen is the way by itself")
	var from_home_after_coins := _at(HOME, [COINS, HOME])
	_verdict.check(_route(from_home_after_coins, &"counts_a_coin") == [&"goes_back", &"counts_a_coin"], "come home from the coins, the count is one Back: %s" % [_route(from_home_after_coins, &"counts_a_coin")])
	_verdict.check(_route(_at(COINS, [HOME, COINS]), &"saves_the_day") == [&"goes_back", &"saves_the_day"], "and from the coins the home's save is Back then the save")


## From home with a lost screen behind - reached by no link - Back then the
## link on the screen behind: a link not on the screen where you started.
func _back_then_a_link_that_was_not_on_the_screen_where_you_started() -> void:
	_refused = {}
	var walked := _at(HOME, [COINS, HOME])
	_verdict.check(_route(walked, &"zooms") == [&"goes_back", &"zooms"], "from home, the zoom is Back to the coins then the zoom link - one not on the home: %s" % [_route(walked, &"zooms")])
	_verdict.check(_route(walked, &"closes_the_zoom") == [&"goes_back", &"zooms", &"closes_the_zoom"], "and closing the zoom is Back, the zoom, then closing: %s" % [_route(walked, &"closes_the_zoom")])


func _a_link_to_a_tab_inside_a_pop_up_opens_the_pop_up_on_that_tab() -> void:
	_refused = {}
	var out := Chart.transition(CHART, _at(HOME), Events.Event.go(&"rear"))
	_verdict.check(out["refusal"] == null and out["state"]["overlays"] == [[&"card", &"rear"]], "a move to the rear, a tab inside the card not up, raises the card on the rear: %s" % [out["state"]["overlays"]])
	_verdict.check(_route(_at(HOME), &"reads_the_rear") == [&"opens_the_rear", &"reads_the_rear"], "so the way to reading the rear is the home's link to it, then reading: %s" % [_route(_at(HOME), &"reads_the_rear")])
	var on_front := _at(HOME, [], [[&"card", &"front"]])
	_verdict.check(_route(on_front, &"reads_the_rear") == [&"flips", &"reads_the_rear"], "and on the card's front, the flip within the card: %s" % [_route(on_front, &"reads_the_rear")])


func _an_action_only_built_as_its_place_fills_is_routed_to_by_its_declaration() -> void:
	_refused = {}
	_verdict.check(_route(_at(HOME), &"jots_a_note") == [&"opens_the_ledger", &"shows_notes", &"jots_a_note"], "the jot, a button the notes build only as they fill, is routed to by the notes' declaration: %s" % [_route(_at(HOME), &"jots_a_note")])


## The ledger left on the notes lands on the notes again; left on the coins,
## on the coins: two states alike but for that tab reach the count by
## different ways, and the search keeps both.
func _two_states_that_differ_only_in_a_remembered_tab_are_both_searched() -> void:
	_refused = {}
	var on_coins := _at(HOME, [HOME], [], {&"ledger": &"coins"})
	var on_notes := _at(HOME, [HOME], [], {&"ledger": &"notes"})
	_verdict.check(_route(on_coins, &"counts_a_coin") == [&"opens_the_ledger", &"counts_a_coin"], "the ledger remembered on the coins, the count is the link then the count: %s" % [_route(on_coins, &"counts_a_coin")])
	_verdict.check(_route(on_notes, &"counts_a_coin") == [&"opens_the_ledger", &"shows_coins", &"counts_a_coin"], "remembered on the notes, the coins tab comes between: %s" % [_route(on_notes, &"counts_a_coin")])


## A way to an action nowhere to be reached is given up once every state the
## reader could get to has been searched from once: the history behind,
## which every move lengthens, never makes a state reached again one to
## search again - or a guide after an action refused everywhere would
## search every order of every move, and its frame never end.
func _an_action_nowhere_to_be_reached_is_given_up_once_every_place_is_searched() -> void:
	_refused = {}
	var tabs: Array[StringName] = [&"one", &"two", &"three", &"four"]
	var chart := {"app": &"app", "children": {&"app": [&"content"], &"content": tabs}, "parent": {&"app": &"", &"content": &"app"}, "kind": {}}
	var performs := {&"app": {&"goes_back": BACK}, &"content": {}}
	# four tabs side by side, each with a flap to every other, as a stall's are
	for tab: StringName in tabs:
		chart["children"][tab] = []
		chart["parent"][tab] = &"content"
		performs[tab] = {}
		for other: StringName in tabs.filter(func(named: StringName) -> bool: return named != tab):
			performs[tab][StringName("shows_" + other)] = other
	var asked: Array[int] = [0]
	var counting := func(place: StringName, action: StringName) -> Phrase:
		asked[0] += 1
		return _would(place, action)
	var way := Queries.route(chart, performs, _at([&"app", &"content", &"one"]), &"declared_nowhere", counting, BACK, _guarded)
	_verdict.check(way.is_empty() and asked[0] < 100, "no way to an action declared nowhere among four tabs that each show the others, given up after the game was asked %d times - each state searched once, not once for every order of flaps that reaches it" % asked[0])


## A history walked to its cap, home and the coins in turn, the reader home
## with the coins just behind: the way to the zoom is still Back then the
## zoom link, pressed on copies it lands where the zoom can be reached, and
## the search asks the game no more than on a history two long.
func _a_way_through_back_is_found_and_replays_with_a_history_at_its_cap() -> void:
	_refused = {}
	var walked: Array = []
	# the cap's worth of entries, the coins and home in turn, home the newest
	for at: int in Chart.HISTORY_CAP:
		walked.append(COINS if at % 2 == 0 else HOME)
	var long := _at(HOME, walked)
	var way := _route(long, &"zooms")
	_verdict.check(way == [&"goes_back", &"zooms"], "with a history at its cap, the zoom is still Back then the zoom link: %s" % [way])
	var state := long
	# every move of the way but the action itself, pressed on a copy
	for pressed: StringName in way.slice(0, -1):
		state = Queries.pressed(CHART, state, PERFORMS[&"app"][pressed], BACK)["state"]
	_verdict.check(_reachable(state, &"zooms") and state["history"].size() == Chart.HISTORY_CAP - 1, "pressed on copies, it lands on the coins with the zoom in reach, one entry fewer: %s" % [state["path"]])
	var asked: Array[int] = [0, 0]
	# the same search with nowhere to go, over the long history and over one two long
	for index: int in 2:
		var counting := func(place: StringName, action: StringName) -> Phrase:
			asked[index] += 1
			return _would(place, action)
		Queries.route(CHART, PERFORMS, long if index == 0 else _at(HOME, [COINS, HOME]), &"declared_nowhere", counting, BACK, _guarded)
	_verdict.check(asked[0] <= asked[1] * 2, "and the search asks the game about as often either way - %d over the cap's history, %d over two - never once per order of moves" % [asked[0], asked[1]])


func _a_refused_action_is_no_way_and_no_goal() -> void:
	_refused = {&"opens_the_ledger": Phrase.of("the ledger is locked")}
	_verdict.check(_route(_at(HOME), &"counts_a_coin").is_empty(), "the ledger link refused by the game, there is no way to the count: %s" % [_route(_at(HOME), &"counts_a_coin")])
	_refused = {&"counts_a_coin": Phrase.of("no coins left")}
	_verdict.check(_route(_at(HOME), &"counts_a_coin").is_empty(), "and the count refused, no way either")
	_refused = {}
	_verdict.check(_route(_at(HOME), &"nobody_performs_this").is_empty(), "an action no place declares has no way")


## Which place stops a move is asked of its outcome, made on a copy: the
## first place it empties, innermost first, that asks first - the tab left,
## or a place the tab is inside - and never one it leaves standing; a
## pop-up raised over the screen empties nothing, and lowered empties only
## itself; a refused move empties nothing.
func _a_move_is_stopped_by_the_first_place_it_empties_that_asks_first_and_a_pop_up_raised_or_lowered_empties_none() -> void:
	var on_notes := _at([&"app", &"content", &"ledger", &"notes"])
	var both := {&"notes": "leave the notes?", &"ledger": "leave the ledger?"}
	var home := Chart.transition(CHART, on_notes, Events.Event.go(&"home"))
	_verdict.check(Queries.stopping(home, both) == &"notes" and Queries.stopping(home, {&"ledger": "leave the ledger?"}) == &"ledger", "from the notes home, the notes and the ledger are left: the notes, innermost, stop it, and the ledger alone would")
	_verdict.check(Queries.stopping(Chart.transition(CHART, on_notes, Events.Event.go(&"coins")), {&"ledger": "leave the ledger?"}) == &"", "a move within the ledger leaves the ledger standing: its asking stops nothing")
	var zoomed := Chart.transition(CHART, on_notes, Events.Event.go(&"zoom"))
	_verdict.check(Queries.stopping(zoomed, both) == &"" and Queries.stopping(Chart.transition(CHART, zoomed["state"], Events.Event.lower(&"zoom")), both) == &"", "a pop-up raised over the notes empties nothing, and lowered only itself")
	_verdict.check(Queries.stopping(Chart.transition(CHART, on_notes, Events.Event.back()), both) == &"", "and a move the chart refuses - Back with nothing behind - empties nothing")


## A place asking first is refused to leave: no way leads out of it, and an
## action whose press there would leave it cannot be reached; one it leaves
## standing, and the same place not asking, are as ever.
func _routing_treats_a_place_asking_first_as_refused_to_leave() -> void:
	_refused = {}
	var on_notes := _at([&"app", &"content", &"ledger", &"notes"], [HOME, [&"app", &"content", &"ledger", &"notes"]])
	_guarded = {&"notes": "leave the notes?"}
	_verdict.check(_reachable(on_notes, &"jots_a_note") and not _reachable(on_notes, &"shows_coins") and not _reachable(on_notes, &"goes_back"), "on the notes asking first, the jot can be reached; the coins tab and Back, whose presses leave the notes, cannot")
	_verdict.check(_route(on_notes, &"counts_a_coin").is_empty() and _route(on_notes, &"saves_the_day").is_empty(), "and no way leads out of them: %s" % [_route(on_notes, &"counts_a_coin")])
	_verdict.check(_route(_at(COINS, [HOME, COINS]), &"saves_the_day") == [&"goes_back", &"saves_the_day"], "from the coins, the notes not on the path, the way home leaves them standing and is taken as ever")
	_guarded = {}
	_verdict.check(_route(on_notes, &"counts_a_coin") == [&"shows_coins", &"counts_a_coin"] and _reachable(on_notes, &"goes_back"), "the notes not asking, the way out is the coins tab, and Back can be reached")


## A tree in the demo's shape under a driver, arrived at the coins, with a
## real button drawing the count in the coins, glowing for the prompts.
func _on_a_real_tree_the_driver_answers_reachable_and_a_button_behind_a_pop_up_does_not_glow() -> void:
	var chimes := Chimes.new(Belfry.new())
	var driver := Driver.new(chimes)
	root.add_child(driver)
	var commands := Commands.new(chimes, driver)
	root.add_child(commands)
	var places: Dictionary = {}
	# every place, declaring as the pure data does
	for named: StringName in PERFORMS:
		places[named] = Place.new(chimes, named, driver)
		places[named].performs = PERFORMS[named].duplicate()
	places[&"app"].add_child(places[&"content"])
	places[&"content"].add_child(places[&"home"])
	places[&"content"].add_child(places[&"ledger"])
	places[&"ledger"].add_child(places[&"coins"])
	places[&"ledger"].add_child(places[&"notes"])
	places[&"card"].add_child(places[&"front"])
	places[&"card"].add_child(places[&"rear"])
	places[&"console"].blocks = false
	driver.index.app = places[&"app"]
	for named: StringName in [&"app", &"zoom", &"card", &"console"]:
		root.add_child(places[named])
	var actions := Actions.new()
	actions.declare_all({&"counts_a_coin": ["count a coin"]})
	var prompts := Prompts.new(chimes, actions, [&"guide"])
	root.add_child(prompts)
	var button := ActionControl.new(chimes, commands, places[&"coins"], &"counts_a_coin")
	places[&"coins"].add_child(button)
	button.prompts = prompts
	commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": &"coins"})
	prompts.raise(&"guide", &"counts_a_coin")
	_verdict.check(driver.is_reachable(&"counts_a_coin") and not driver.is_reachable(&"saves_the_day"), "on the coins, the driver says the count can be reached and the save cannot")
	_verdict.check(button.is_glowing(), "and the count button glows for the prompt")
	commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": &"zoom"})
	_verdict.check(not button.is_glowing() and not driver.is_reachable(&"counts_a_coin"), "the zoom up over it, it does not glow, since the count cannot be reached")
	commands.dispatch(Chimes.GLOBAL, Driver.LOWERS, {"place": &"zoom"})
	_verdict.check(button.is_glowing(), "and lowered, it glows again")
	_verdict.check(driver.route(&"jots_a_note") == [&"shows_notes", &"jots_a_note"], "and the driver finds the way to the jot from here: %s" % [driver.route(&"jots_a_note")])
	for named: StringName in [&"app", &"zoom", &"card", &"console"]:
		places[named].free()
	prompts.free()
	driver.free()
	commands.free()


## Routing goes to a place as a kind, never to one of it: a simulated press
## keeps the parameter the place has in the state searched, so a link to
## the screen the reader is on, as 7, is already there and no state with
## the 7 gone is imagined; a place with none yet stays with none.
func _a_simulated_press_keeps_the_parameter_the_place_has_and_invents_none() -> void:
	_refused = {}
	var at_seven := _at(COINS, [HOME, COINS])
	at_seven["params"] = {&"coins": 7}
	at_seven["history_params"] = [{}, {&"coins": 7}]
	var same := Queries.pressed(CHART, at_seven, &"coins", BACK)
	_verdict.check(str(same["refusal"]) == "Already at coins", "a link to the coins pressed on the coins as 7 is already there, not a move to the coins as none: %s" % [same["refusal"]])
	var strip := Queries.pressed(CHART, at_seven, &"ledger", BACK)
	_verdict.check(str(strip["refusal"]) == "Already at coins", "and so is the strip's ledger link, landing on the tab the reader is on")
	var away := Queries.pressed(CHART, at_seven, &"home", BACK)
	_verdict.check(away["refusal"] == null and not away["state"]["params"].has(&"coins") and at_seven["params"] == {&"coins": 7} and at_seven["history_params"][1] == {&"coins": 7}, "a press away lets the 7 go, and the state searched from is untouched: %s" % [at_seven["history_params"]])
	var fresh := Queries.pressed(CHART, _at(HOME), &"ledger", BACK)
	_verdict.check(fresh["refusal"] == null and fresh["state"]["params"] == {}, "a press to a place with no parameter yet gives it none: %s" % [fresh["state"]["params"]])
	_verdict.check(_route(at_seven, &"saves_the_day") == [&"goes_back", &"saves_the_day"], "and the way from the coins as 7 to the save is Back then the save: %s" % [_route(at_seven, &"saves_the_day")])


## On a real tree, the reader at home with a card to the coins carrying 7,
## the way to the count is found, and replaying it press by press - the
## card with its 7, then the count - reaches the count on the coins as 7.
func _a_way_through_a_link_that_carries_an_entity_is_found_and_replayed_press_by_press() -> void:
	var chimes := Chimes.new(Belfry.new())
	var driver := Driver.new(chimes)
	var commands := Commands.new(chimes, driver)
	root.add_child(commands)
	root.add_child(driver)
	var places: Dictionary = {}
	for named: StringName in [&"app", &"content", &"home", &"ledger", &"coins"]:
		places[named] = Place.new(chimes, named, driver)
	places[&"app"].add_child(places[&"content"])
	places[&"content"].add_child(places[&"home"])
	places[&"content"].add_child(places[&"ledger"])
	places[&"ledger"].add_child(places[&"coins"])
	places[&"home"].performs = {&"opens_a_coin": &"coins"}
	places[&"coins"].performs = {&"counts_a_coin": &""}
	var counter := Counter.new()
	commands.register(Chimes.GLOBAL, &"counts_a_coin", counter)
	driver.index.app = places[&"app"]
	root.add_child(places[&"app"])
	commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": &"home"})
	var way := driver.route(&"counts_a_coin")
	_verdict.check(way == [&"opens_a_coin", &"counts_a_coin"], "from home, the count is the card then the count: %s" % [way])
	# every step replayed as its press would go: the card carrying its 7
	commands.dispatch(&"home", way[0], {"parameter": 7})
	_verdict.check(driver.get_top() == COINS and driver.get_parameter(&"coins") == 7 and driver.is_reachable(way[1]), "the card pressed with 7 lands on the coins as 7, where the count can be reached")
	commands.dispatch(&"coins", way[1], {})
	_verdict.check(counter.counted == 1 and driver.route(&"counts_a_coin") == [&"counts_a_coin"], "and the count runs there, the way now the count alone")
	places[&"app"].free()
	driver.free()
	commands.free()


## A handler that counts.
class Counter extends RefCounted:
	var counted: int = 0

	func would(_action: StringName, _payload: Dictionary) -> Phrase:
		return null

	func told(_action: StringName, _payload: Dictionary) -> Phrase:
		counted += 1
		return null
