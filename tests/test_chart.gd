extends SceneTree

## The statechart (chart.gd) as a list of effects, without the engine: the
## fixed order of leaving and entering, nothing above the split touched,
## overlays closed top first before an arrival moves the path, moves within
## the layer on top, the panel beside it all, the history as a value - every
## arrival an entry of its own, Back retracing them, the cap, forgetting - the remembered last
## tab, GO as the one kind of move, and every refusal. A move to a path here
## is a GO to its last name.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_chart.gd
##
## The chart is the guided demo's shape: an app holding the content, which
## holds a home and a ledger, whose tabs are the coins and the notes; a zoom
## and a confirm beside the app as overlays, a card with two tabs of its own
## as a third, and the console as the panel. The strip is no state and never
## appears. Shown and live are facts of the state, so the effects say
## RECONCILE once between leaving and filling, and never show, hide or
## switch anything by name. Events and effects are typed (events.gd); a
## check reads an effect as an array.

const Chart := preload("res://addons/gd_chime/chart.gd")
const Events := preload("res://addons/gd_chime/events.gd")
const Verdict := preload("res://tests/verdict.gd")

const CHART := {
	"app": &"app",
	"children": {&"app": [&"content"], &"content": [&"home", &"ledger"], &"home": [], &"ledger": [&"coins", &"notes"], &"coins": [], &"notes": [], &"zoom": [], &"confirm": [], &"card": [&"front", &"rear"], &"front": [], &"rear": [], &"console": []},
	"parent": {&"app": &"", &"content": &"app", &"home": &"content", &"ledger": &"content", &"coins": &"ledger", &"notes": &"ledger", &"zoom": &"", &"confirm": &"", &"card": &"", &"front": &"card", &"rear": &"card", &"console": &""},
	"kind": {&"zoom": Chart.OVERLAY, &"confirm": Chart.OVERLAY, &"card": Chart.OVERLAY, &"console": Chart.PANEL},
}
const COINS := [&"app", &"content", &"ledger", &"coins"]
const NOTE := Events.Doing.NOTE_FOCUS
const OPENER := Events.Doing.NOTE_OPENER
const EMPTY := Events.Doing.EMPTY
const RECONCILE := Events.Doing.RECONCILE
const FILL := Events.Doing.FILL
const FOCUS := Events.Doing.FOCUS
const NOTIFY := Events.Doing.NOTIFY

var _verdict := Verdict.new()


func _init() -> void:
	await _verdict.states(_the_first_arrival_reconciles_then_fills_outermost_first_down_to_the_initial_children_and_notifies_last)
	await _verdict.states(_a_tab_switch_leaves_the_tab_and_enters_the_other_touching_nothing_above_the_split)
	await _verdict.states(_leaving_is_innermost_first_and_entering_outermost_first_in_the_fixed_order)
	await _verdict.states(_an_arrival_closes_every_overlay_top_first_before_the_path_changes_and_leaves_the_panel)
	await _verdict.states(_an_arrival_where_the_reader_is_with_a_pop_up_up_only_lowers_it)
	await _verdict.states(_a_path_starting_at_the_root_on_top_moves_within_it_and_touches_nothing_beneath)
	await _verdict.states(_go_is_the_one_move_into_the_app_a_pop_up_not_up_the_layer_on_top_or_the_panel)
	await _verdict.states(_a_place_entered_with_a_parameter_is_one_of_its_kind_and_the_history_keeps_which)
	await _verdict.states(_back_and_forward_across_entries_leaves_every_entry_s_parameters_as_walked)
	await _verdict.states(_an_overlay_raised_notes_its_opener_and_lowered_hands_the_focus_back)
	await _verdict.states(_overlays_stack_and_lower_one_at_a_time_onto_the_one_beneath)
	await _verdict.states(_the_panel_changes_nothing_beneath)
	await _verdict.states(_every_arrival_is_an_entry_of_its_own_and_back_retraces_them)
	await _verdict.states(_the_history_holds_its_newest_entries_up_to_its_cap)
	await _verdict.states(_back_lowers_the_top_overlay_else_arrives_at_the_path_behind_else_is_refused)
	await _verdict.states(_forget_keeps_the_path_the_reader_is_at_alone)
	await _verdict.states(_a_refusal_is_a_sentence_with_the_state_and_the_effects_untouched)
	await _verdict.states(_a_state_left_remembers_the_child_it_was_on_and_entered_again_enters_it)
	await _verdict.states(_a_link_to_the_screen_the_reader_is_on_lands_on_the_tab_they_are_on)
	quit(_verdict.deliver(get_script()))


## The state at this app path with these overlays up, nothing remembered.
func _at(path: Array, overlays: Array = [], panel: Array = []) -> Dictionary:
	return {"path": path, "overlays": overlays, "panel": panel, "last": {}, "history": [], "params": {}, "history_params": [], "history_ids": [], "serial": 0}


## A move to the last name of this path: the one kind of move, GO.
func _arrive(state: Dictionary, path: Array) -> Dictionary:
	return Chart.transition(CHART, state, Events.Event.go(path.back()))


func _raise(state: Dictionary, root: StringName) -> Dictionary:
	return Chart.transition(CHART, state, Events.Event.go(root))


func _lower(state: Dictionary, root: StringName) -> Dictionary:
	return Chart.transition(CHART, state, Events.Event.lower(root))


func _back(state: Dictionary) -> Dictionary:
	return Chart.transition(CHART, state, Events.Event.back())


func _forget(state: Dictionary) -> Dictionary:
	return Chart.transition(CHART, state, Events.Event.forget())


## The effects as arrays, in order: what each does and the state, and for a
## FOCUS the memory and the fallback too.
func _done(out: Dictionary) -> Array:
	var done: Array = []
	# every effect, read as an array
	for effect: Events.Effect in out["effects"]:
		done.append(effect.to_array())
	return done


## The effects as what each does and the state, in order.
func _kinds(out: Dictionary) -> Array:
	var kinds: Array = []
	# every effect, its doing and its state
	for effect: Events.Effect in out["effects"]:
		kinds.append([effect.doing, effect.state])
	return kinds


## Every name the effects empty or fill.
func _moved(out: Dictionary) -> Array:
	var names: Array = []
	# every effect that empties or fills, its state
	for effect: Events.Effect in out["effects"]:
		if [EMPTY, FILL].has(effect.doing) and not names.has(effect.state):
			names.append(effect.state)
	return names


func _the_first_arrival_reconciles_then_fills_outermost_first_down_to_the_initial_children_and_notifies_last() -> void:
	var out := _arrive(Chart.blank(), [&"app"])
	_verdict.check(out["refusal"] == null and out["state"]["path"] == [&"app", &"content", &"home"], "an arrival at the app lands on the content's first child, the home: %s" % [out["state"]["path"]])
	_verdict.check(_kinds(out) == [[RECONCILE, &""], [FILL, &"app"], [FILL, &"content"], [FILL, &"home"], [FOCUS, &"home"], [NOTIFY, &""]],
		"the state reconciled, then each entered state filled outermost first, then the focus, then one notification: %s" % [_kinds(out)])
	_verdict.check(_kinds(out).back() == [NOTIFY, &""] and _kinds(out).count([NOTIFY, &""]) == 1, "and the notification is last and once")


func _a_tab_switch_leaves_the_tab_and_enters_the_other_touching_nothing_above_the_split() -> void:
	var out := _arrive(_at(COINS), [&"app", &"content", &"ledger", &"notes"])
	_verdict.check(_kinds(out) == [[NOTE, &"coins"], [EMPTY, &"coins"], [RECONCILE, &""], [FILL, &"notes"], [FOCUS, &"notes"], [NOTIFY, &""]],
		"the coins noted and emptied, the state reconciled, the notes filled, the focus and the notification: %s" % [_kinds(out)])
	_verdict.check(_moved(out) == [&"coins", &"notes"], "and the ledger, the content and the app above the split are neither emptied nor filled: %s" % [_moved(out)])


func _leaving_is_innermost_first_and_entering_outermost_first_in_the_fixed_order() -> void:
	var out := _arrive(_at(COINS), [&"app", &"content", &"home"])
	_verdict.check(_kinds(out) == [[NOTE, &"coins"], [NOTE, &"ledger"], [EMPTY, &"coins"], [EMPTY, &"ledger"], [RECONCILE, &""], [FILL, &"home"], [FOCUS, &"home"], [NOTIFY, &""]],
		"from the coins home: every focus noted, then every emptying innermost first, then the reconciling, then the home: %s" % [_kinds(out)])
	var back := _arrive(out["state"], [&"app", &"content", &"ledger"])
	_verdict.check(_kinds(back) == [[NOTE, &"home"], [EMPTY, &"home"], [RECONCILE, &""], [FILL, &"ledger"], [FILL, &"coins"], [FOCUS, &"coins"], [NOTIFY, &""]],
		"and back to the ledger: the home left, the ledger filled before its first tab: %s" % [_kinds(back)])


func _an_arrival_closes_every_overlay_top_first_before_the_path_changes_and_leaves_the_panel() -> void:
	var out := _arrive(_at(COINS, [[&"zoom"], [&"confirm"]], [&"console"]), [&"app", &"content", &"home"])
	_verdict.check(_kinds(out).slice(0, 4) == [[NOTE, &"confirm"], [NOTE, &"zoom"], [NOTE, &"coins"], [NOTE, &"ledger"]], "the confirm, then the zoom, then the coins and the ledger are left, in that order: %s" % [_kinds(out)])
	_verdict.check(_kinds(out).slice(4, 9) == [[EMPTY, &"confirm"], [EMPTY, &"zoom"], [EMPTY, &"coins"], [EMPTY, &"ledger"], [RECONCILE, &""]], "emptied top first, before the app's states beneath, then reconciled")
	_verdict.check(out["state"]["overlays"].is_empty() and out["state"]["panel"] == [&"console"] and not _moved(out).has(&"console"), "no overlay is up after, and the panel is left as it was: %s" % [out["state"]])


func _an_arrival_where_the_reader_is_with_a_pop_up_up_only_lowers_it() -> void:
	var same := _arrive(_at(COINS, [[&"zoom"]]), [&"app", &"content", &"ledger"])
	_verdict.check(same["refusal"] == null and same["state"]["overlays"].is_empty() and same["state"]["path"] == COINS, "an arrival where the reader is, with the zoom up, lowers it and is not refused: %s" % [same["state"]])
	_verdict.check(_kinds(same) == [[NOTE, &"zoom"], [EMPTY, &"zoom"], [RECONCILE, &""], [FOCUS, &"coins"], [NOTIFY, &""]], "the zoom left and the coins neither emptied nor filled, only focused: %s" % [_kinds(same)])


func _a_path_starting_at_the_root_on_top_moves_within_it_and_touches_nothing_beneath() -> void:
	var up := _raise(_at(COINS), &"card")
	_verdict.check(up["state"]["overlays"] == [[&"card", &"front"]], "the card raised lands on its first tab: %s" % [up["state"]["overlays"]])
	var flipped := _arrive(up["state"], [&"card", &"rear"])
	_verdict.check(flipped["refusal"] == null and _kinds(flipped) == [[NOTE, &"front"], [EMPTY, &"front"], [RECONCILE, &""], [FILL, &"rear"], [FOCUS, &"rear"], [NOTIFY, &""]], "a path starting at the card moves within it: the front left, the rear entered, the card and the app untouched: %s" % [_kinds(flipped)])
	_verdict.check(flipped["state"]["overlays"] == [[&"card", &"rear"]] and flipped["state"]["path"] == COINS, "the card is on its rear and the app's path stands: %s" % [flipped["state"]])
	var console := _raise(flipped["state"], &"console")
	var within := _arrive(console["state"], [&"card", &"front"])
	_verdict.check(within["refusal"] == null and within["state"]["overlays"] == [[&"card", &"front"]] and within["state"]["panel"] == [&"console"], "with the panel up too, the card on top still moves within itself: %s" % [within["state"]])


func _an_overlay_raised_notes_its_opener_and_lowered_hands_the_focus_back() -> void:
	var up := _raise(_at(COINS), &"zoom")
	_verdict.check(_done(up) == [[OPENER, &"zoom"], [RECONCILE, &""], [FILL, &"zoom"], [FOCUS, &"zoom", Events.Memory.OWN, &"zoom"], [NOTIFY, &""]],
		"raised: the opener noted first, the state reconciled, the zoom filled, its own focus else its default: %s" % [_done(up)])
	_verdict.check(up["state"]["overlays"] == [[&"zoom"]] and up["state"]["path"] == COINS, "the zoom is up and the app's path stands: %s" % [up["state"]])
	var down := _lower(up["state"], &"zoom")
	_verdict.check(_done(down) == [[NOTE, &"zoom"], [EMPTY, &"zoom"], [RECONCILE, &""], [FOCUS, &"zoom", Events.Memory.OPENER, &"coins"], [NOTIFY, &""]],
		"lowered: the zoom left, the state reconciled, the focus back on the zoom's opener else the coins' default: %s" % [_done(down)])
	_verdict.check(down["state"]["overlays"].is_empty(), "and nothing is up")
	var asked := Chart.transition(CHART, _at(COINS), Events.Event.go(&"zoom", 3))
	_verdict.check(asked["state"]["params"] == {&"zoom": 3}, "raised as one of its kind, the zoom carries 3: %s" % [asked["state"]["params"]])
	var lowered := _lower(asked["state"], &"zoom")
	_verdict.check(lowered["state"]["params"].is_empty() and asked["state"]["params"] == {&"zoom": 3}, "lowered, it has no view to be one of its kind in, and its parameter is let go - the state it came from untouched: %s" % [lowered["state"]["params"]])


func _overlays_stack_and_lower_one_at_a_time_onto_the_one_beneath() -> void:
	var zoom := _raise(_at(COINS), &"zoom")
	var confirm := _raise(zoom["state"], &"confirm")
	_verdict.check(confirm["state"]["overlays"] == [[&"zoom"], [&"confirm"]], "the confirm over the zoom: %s" % [confirm["state"]["overlays"]])
	var down := _lower(confirm["state"], &"confirm")
	_verdict.check(_done(down).has([FOCUS, &"confirm", Events.Memory.OPENER, &"zoom"]) and down["state"]["overlays"] == [[&"zoom"]], "the confirm lowered hands the focus back onto the zoom: %s" % [_done(down)])


func _the_panel_changes_nothing_beneath() -> void:
	var up := _raise(_at(COINS, [[&"zoom"]]), &"console")
	_verdict.check(_done(up) == [[OPENER, &"console"], [RECONCILE, &""], [FILL, &"console"], [FOCUS, &"console", Events.Memory.OWN, &"console"], [NOTIFY, &""]], "the console raised empties and fills nothing but itself: %s" % [_done(up)])
	_verdict.check(up["state"]["panel"] == [&"console"] and up["state"]["overlays"] == [[&"zoom"]] and up["state"]["path"] == COINS, "and the zoom and the app's path stand: %s" % [up["state"]])
	var down := _lower(up["state"], &"console")
	_verdict.check(_done(down) == [[NOTE, &"console"], [EMPTY, &"console"], [RECONCILE, &""], [FOCUS, &"console", Events.Memory.OPENER, &"zoom"], [NOTIFY, &""]] and down["state"]["panel"].is_empty(), "lowered, the focus goes back to its opener else the top layer's default: %s" % [_done(down)])


func _a_refusal_is_a_sentence_with_the_state_and_the_effects_untouched() -> void:
	var here := _at(COINS, [[&"zoom"]])
	var refused := {
		"Already at": _arrive(_at(COINS), [&"app", &"content", &"ledger"]),
		"within, Already at": _arrive(_at(COINS, [[&"card", &"front"]]), [&"card", &"front"]),
		"is no state": _arrive(here, [&"app", &"content", &"attic"]),
		"Already at zoom": _raise(here, &"zoom"),
		"is not on top": _lower(here, &"confirm"),
		"is not up": _lower(here, &"console"),
	}
	# every refusal, its sentence and nothing done
	for words: String in refused:
		var out: Dictionary = refused[words]
		_verdict.check(str(out["refusal"]).contains(words.trim_prefix("within, ")) and out["effects"].is_empty(), "%s: refused with %s and nothing done" % [words, out["refusal"]])
	_verdict.check(refused["is not on top"]["state"] == here and refused["is not up"]["state"] == here, "and the state stands as it was")
	_verdict.check(str(refused["Already at"]["refusal"]) == "Already at coins", "an arrival at the ledger, which lands on the coins where the reader is, says so: %s" % refused["Already at"]["refusal"])


func _a_state_left_remembers_the_child_it_was_on_and_entered_again_enters_it() -> void:
	var notes := _arrive(_at(COINS), [&"app", &"content", &"ledger", &"notes"])
	var home := _arrive(notes["state"], [&"app", &"content", &"home"])
	_verdict.check(home["state"]["last"] == {&"app": &"content", &"content": &"ledger", &"ledger": &"notes"}, "gone home from the notes, every state left remembers the one beneath it: the ledger the notes, the content the ledger: %s" % [home["state"]["last"]])
	var back := _arrive(home["state"], [&"app", &"content", &"ledger"])
	_verdict.check(back["state"]["path"] == [&"app", &"content", &"ledger", &"notes"] and _kinds(back).has([FILL, &"notes"]), "the ledger entered again enters the notes, not its first tab: %s" % [back["state"]["path"]])
	var named := _arrive(back["state"], [&"app", &"content", &"ledger", &"coins"])
	_verdict.check(named["state"]["path"] == COINS, "and a path naming the coins goes there: %s" % [named["state"]["path"]])

	var card := _raise(_at(COINS), &"card")
	var rear := _arrive(card["state"], [&"card", &"rear"])
	var down := _lower(rear["state"], &"card")
	var up := _raise(down["state"], &"card")
	_verdict.check(down["state"]["last"][&"card"] == &"rear" and up["state"]["overlays"] == [[&"card", &"rear"]], "a pop-up lowered on its rear comes back up on its rear: %s" % [up["state"]["overlays"]])
	var gone := CHART.duplicate(true)
	gone["children"][&"ledger"] = [&"coins"]
	var without := Chart.transition(gone, home["state"], Events.Event.go(&"ledger"))
	_verdict.check(without["state"]["path"] == COINS, "the notes gone from the chart meanwhile, the ledger enters its first tab: %s" % [without["state"]["path"]])


## Where the reader is is remembered before the landing is worked out: on the
## notes with the coins remembered from long ago, a link to the ledger lands
## on the notes and is refused as already there, never on the coins.
func _a_link_to_the_screen_the_reader_is_on_lands_on_the_tab_they_are_on() -> void:
	var stale := _at([&"app", &"content", &"ledger", &"notes"])
	stale["last"] = {&"ledger": &"coins"}
	var out := _arrive(stale, [&"app", &"content", &"ledger"])
	_verdict.check(str(out["refusal"]) == "Already at notes", "on the notes, a link to the ledger lands on the notes and is refused as already there: %s" % out["refusal"])
	var card := _raise(_at(COINS), &"card")
	var rear := _arrive(card["state"], [&"card", &"rear"])
	rear["state"]["last"] = {&"card": &"front"}
	var again := _arrive(rear["state"], [&"card"])
	_verdict.check(str(again["refusal"]) == "Already at rear", "and within a pop-up the same: %s" % again["refusal"])


## A state with these paths walked, the last being where the reader is.
func _walked(paths: Array) -> Dictionary:
	var state := _at(paths.back())
	state["history"] = paths
	state["history_params"] = paths.map(func(_path: Array) -> Dictionary: return {})
	state["history_ids"] = range(1, paths.size() + 1)
	state["serial"] = paths.size()
	return state


## As a browser's history: home, the ledger, home again by a link - three
## entries, each its own - and Back retraces them exactly.
func _every_arrival_is_an_entry_of_its_own_and_back_retraces_them() -> void:
	var home_path := [&"app", &"content", &"home"]
	var first := _arrive(Chart.blank(), [&"app"])
	_verdict.check(first["state"]["history"] == [home_path], "the first arrival at the app is walked as the path landed on, resolved: %s" % [first["state"]["history"]])
	var coins := _arrive(first["state"], [&"app", &"content", &"ledger"])
	var home := _arrive(coins["state"], home_path)
	_verdict.check(home["state"]["history"] == [home_path, COINS, home_path] and home["state"]["history_ids"] == [1, 2, 3], "home again by a link is an entry of its own, with a serial of its own - nothing is cut back: %s %s" % [home["state"]["history"], home["state"]["history_ids"]])
	var back := _back(home["state"])
	_verdict.check(back["state"]["path"] == COINS and back["state"]["history_ids"] == [1, 2], "Back arrives at the ledger: %s" % [back["state"]["path"]])
	var back_again := _back(back["state"])
	_verdict.check(back_again["state"]["path"] == home_path and back_again["state"]["history_ids"] == [1], "and Back again at home: %s" % [back_again["state"]["path"]])
	var zoom := _raise(coins["state"], &"zoom")
	var within := _arrive(_raise(coins["state"], &"card")["state"], [&"card", &"rear"])
	_verdict.check(zoom["state"]["history"] == coins["state"]["history"] and within["state"]["history"] == coins["state"]["history"], "a pop-up raised, and a move within it, leave the history alone")
	var lowered := _arrive(zoom["state"], COINS)
	_verdict.check(lowered["refusal"] == null and lowered["state"]["history_ids"] == coins["state"]["history_ids"], "arriving where the reader already is - a pop-up lowered by it - adds no entry: %s" % [lowered["state"]["history_ids"]])
	var pressed_again := Chart.transition(CHART, coins["state"], Events.Event.go(&"coins"))
	_verdict.check(pressed_again["refusal"] != null and pressed_again["state"]["history_ids"] == coins["state"]["history_ids"], "the tab the reader is on pressed again adds no entry")
	_verdict.check(Chart.can_go_back(coins["state"]) and not Chart.can_go_back(first["state"]) and Chart.can_go_back(_raise(first["state"], &"zoom")["state"]), "Back can act with an entry behind or a pop-up up, and not otherwise")


## Sixty arrivals leave the newest fifty: Back walks through exactly those,
## newest to oldest, and is refused past the last.
func _the_history_holds_its_newest_entries_up_to_its_cap() -> void:
	var state: Dictionary = _arrive(Chart.blank(), [&"app"])["state"]
	# sixty arrivals, each the coins as another one of their kind
	for at: int in 60:
		state = Chart.transition(CHART, state, Events.Event.go(&"coins", at))["state"]
	_verdict.check(state["history"].size() == Chart.HISTORY_CAP and state["history_ids"].front() == 12 and state["history_ids"].back() == 61, "past the cap, the oldest are dropped: %d entries, %s to %s" % [state["history"].size(), state["history_ids"].front(), state["history_ids"].back()])
	var seen: Array = [state["params"][&"coins"]]
	# Back as many times as there are entries behind, noting which one of its kind each lands on
	for step: int in Chart.HISTORY_CAP - 1:
		state = _back(state)["state"]
		seen.append(state["params"][&"coins"])
	_verdict.check(seen == range(59, 9, -1), "Back walks through exactly the newest fifty, newest first: %s" % [seen])
	_verdict.check(_back(state)["refusal"] != null, "and past the oldest kept, Back is refused")


func _back_lowers_the_top_overlay_else_arrives_at_the_path_behind_else_is_refused() -> void:
	var with_zoom := _back(_raise(_walked([[&"app", &"content", &"home"], COINS]), &"zoom")["state"])
	_verdict.check(with_zoom["state"]["overlays"].is_empty() and with_zoom["state"]["path"] == COINS and with_zoom["state"]["history"] == [[&"app", &"content", &"home"], COINS], "with the zoom up, Back lowers it and the path and the history stand: %s" % [with_zoom["state"]])
	var behind := _back(_walked([[&"app", &"content", &"home"], COINS]))
	_verdict.check(behind["state"]["path"] == [&"app", &"content", &"home"] and behind["state"]["history"] == [[&"app", &"content", &"home"]] and _kinds(behind)[0] == [NOTE, &"coins"], "with none up, Back arrives at the path behind and the history is that path alone: %s" % [behind["state"]])
	var start := _back(_walked([COINS]))
	_verdict.check(str(start["refusal"]) == "There is nothing to go back to" and start["effects"].is_empty(), "with nothing behind, Back is refused: %s" % start["refusal"])


func _forget_keeps_the_path_the_reader_is_at_alone() -> void:
	var out := _forget(_walked([[&"app", &"content", &"home"], COINS]))
	_verdict.check(out["refusal"] == null and out["state"]["history"] == [COINS] and out["state"]["path"] == COINS and _kinds(out) == [[NOTIFY, &""]], "forgotten, the coins stand alone on the history, nothing moves, and it is said once: %s" % [out["state"]["history"]])
	var nothing := _forget(_walked([COINS]))
	_verdict.check(str(nothing["refusal"]) == "There is nothing behind to forget" and nothing["effects"].is_empty(), "with nothing behind, forgetting is refused: %s" % nothing["refusal"])


func _go_is_the_one_move_into_the_app_a_pop_up_not_up_the_layer_on_top_or_the_panel() -> void:
	var into_app := Chart.transition(CHART, _at(COINS), Events.Event.go(&"home"))
	_verdict.check(into_app["state"]["path"] == [&"app", &"content", &"home"] and into_app["state"]["overlays"].is_empty(), "GO to the home, in the app, arrives there: %s" % [into_app["state"]["path"]])
	var onto_tab := Chart.transition(CHART, _at(COINS), Events.Event.go(&"rear"))
	_verdict.check(onto_tab["state"]["overlays"] == [[&"card", &"rear"]] and _kinds(onto_tab)[0] == [OPENER, &"card"], "GO to the rear, a tab in the card not up, raises the card on the rear, its opener noted: %s" % [onto_tab["state"]["overlays"]])
	var within := Chart.transition(CHART, onto_tab["state"], Events.Event.go(&"front"))
	_verdict.check(within["state"]["overlays"] == [[&"card", &"front"]] and within["state"]["path"] == COINS, "GO to the front, in the card on top, moves within it: %s" % [within["state"]["overlays"]])
	var panel := Chart.transition(CHART, within["state"], Events.Event.go(&"console"))
	_verdict.check(panel["state"]["panel"] == [&"console"] and panel["state"]["overlays"] == [[&"card", &"front"]], "GO to the console raises the panel and leaves the card up: %s" % [panel["state"]])
	var beneath := Chart.transition(CHART, _at(COINS, [[&"zoom"], [&"confirm"]]), Events.Event.go(&"zoom"))
	_verdict.check(str(beneath["refusal"]) == "zoom is not on top", "GO into a pop-up up but not on top is refused: %s" % beneath["refusal"])


## A place entered with a parameter - which item, which round - is one of
## its kind: the same place with another parameter is a move that leaves it
## and enters it again, with the same one it is already there, the history
## keeps which one each entry was, Back returns the one it left, and one
## walked again is an entry of its own.
func _a_place_entered_with_a_parameter_is_one_of_its_kind_and_the_history_keeps_which() -> void:
	var first := Chart.transition(CHART, _at([&"app", &"content", &"home"]), Events.Event.go(&"coins", 1))
	_verdict.check(first["state"]["params"] == {&"coins": 1} and first["state"]["history_params"].back() == {&"coins": 1}, "entered with 1, the coins carry 1 and the entry remembers it: %s" % [first["state"]["params"]])
	var again := Chart.transition(CHART, first["state"], Events.Event.go(&"coins", 1))
	_verdict.check(str(again["refusal"]) == "Already at coins", "the same place with the same parameter is already there")
	var other := Chart.transition(CHART, first["state"], Events.Event.go(&"coins", 2))
	_verdict.check(other["refusal"] == null and _kinds(other).has([EMPTY, &"coins"]) and _kinds(other).has([FILL, &"coins"]) and not _kinds(other).has([EMPTY, &"ledger"]), "another parameter is a move: the coins left and entered again, the ledger untouched: %s" % [_kinds(other)])
	_verdict.check(other["state"]["history"].size() == 2 and other["state"]["history_params"][0] == {&"coins": 1} and other["state"]["history_params"][1] == {&"coins": 2}, "and the history holds both, each with its parameter: %s" % [other["state"]["history_params"]])
	var back := Chart.transition(CHART, other["state"], Events.Event.back())
	_verdict.check(back["state"]["params"] == {&"coins": 1} and _kinds(back).has([FILL, &"coins"]), "Back returns the coins as 1, filled again: %s" % [back["state"]["params"]])
	var walked := Chart.transition(CHART, other["state"], Events.Event.go(&"coins", 1))
	_verdict.check(walked["state"]["history"].size() == 3 and walked["state"]["params"] == {&"coins": 1}, "the coins as 1 walked again is a third entry, nothing cut back: %d" % walked["state"]["history"].size())
	var plain := Chart.transition(CHART, other["state"], Events.Event.go(&"home"))
	_verdict.check(not plain["state"]["params"].has(&"coins"), "leaving for a place of one, the coins' parameter is let go: %s" % [plain["state"]["params"]])


## Back hands the arrival a copy of the entry's parameters, never the
## record: back and forward across several entries, each entry's
## parameters are exactly what it was walked with.
func _back_and_forward_across_entries_leaves_every_entry_s_parameters_as_walked() -> void:
	var one := Chart.transition(CHART, _at([&"app", &"content", &"home"]), Events.Event.go(&"coins", 1))
	var two := Chart.transition(CHART, one["state"], Events.Event.go(&"notes", 2))
	var three := Chart.transition(CHART, two["state"], Events.Event.go(&"coins", 3))
	var walked: Array = [{&"coins": 1}, {&"notes": 2}, {&"coins": 3}]
	_verdict.check(three["state"]["history_params"] == walked, "three entries walked, each with its parameter: %s" % [three["state"]["history_params"]])
	var back := Chart.transition(CHART, three["state"], Events.Event.back())
	var back_again := Chart.transition(CHART, back["state"], Events.Event.back())
	_verdict.check(back_again["state"]["params"] == {&"coins": 1} and back_again["state"]["history_params"] == walked.slice(0, 1) and three["state"]["history_params"] == walked, "two Backs land on the coins as 1, and no entry is written: %s / %s" % [back_again["state"]["history_params"], three["state"]["history_params"]])
	_verdict.check(not is_same(back["state"]["params"], three["state"]["history_params"][1]) and not is_same(back_again["state"]["params"], three["state"]["history_params"][0]), "and the parameters Back lands with are a copy of the record, never the record itself")
	var forward := Chart.transition(CHART, back_again["state"], Events.Event.go(&"notes", 2))
	var forward_again := Chart.transition(CHART, forward["state"], Events.Event.go(&"coins", 3))
	_verdict.check(forward_again["state"]["history_params"] == walked and back["state"]["history_params"] == walked.slice(0, 2), "forward again, every entry is as walked: %s" % [forward_again["state"]["history_params"]])
