extends SceneTree

## What must be true of what is kept with each history entry (kept.gd), on
## the chart's own states, no tree: a thing kept is found with its entry and
## no other; the entry being left can be written before the state moves on
## and is found again on Back; the same place entered as another one of its
## kind is another entry; whatever was kept with an entry the history no
## longer holds is let go and freed, and what it holds stays; and a Node is
## refused out loud and never kept.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_kept.gd

const Chart := preload("res://addons/gd_chime/chart.gd")
const Events := preload("res://addons/gd_chime/events.gd")
const Kept := preload("res://addons/gd_chime/kept.gd")
const Verdict := preload("res://tests/verdict.gd")

## An app holding a home and a ledger, the ledger's tabs the coins and the notes.
const CHART := {
	"app": &"app",
	"children": {&"app": [&"home", &"ledger"], &"home": [], &"ledger": [&"coins", &"notes"], &"coins": [], &"notes": []},
	"parent": {&"app": &"", &"home": &"app", &"ledger": &"app", &"coins": &"ledger", &"notes": &"ledger"},
	"kind": {},
}

var _verdict := Verdict.new()
var _hearing := Hearing.new()


## Counts the refusals pushed as errors.
class Hearing extends Logger:
	var refusals: int = 0

	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array) -> void:
		if error_type == ERROR_TYPE_ERROR:
			refusals += 1


## Something kept with a view: a half-typed amount.
class Amount extends RefCounted:
	var typed: String = ""


func _init() -> void:
	OS.add_logger(_hearing)
	await _verdict.states(_a_thing_kept_with_an_entry_is_found_with_it_and_no_other)
	await _verdict.states(_the_entry_being_left_is_written_before_the_state_moves_and_found_again_on_back)
	await _verdict.states(_what_the_history_no_longer_holds_is_let_go_and_freed_and_what_it_holds_stays)
	await _verdict.states(_two_visits_to_one_view_are_two_entries_each_with_its_own)
	await _verdict.states(_what_was_kept_with_an_entry_dropped_past_the_cap_is_let_go)
	await _verdict.states(_a_node_is_refused_out_loud_and_never_kept)
	OS.remove_logger(_hearing)
	quit(_verdict.deliver(get_script()))


## The state after this move from that one.
func _moved(state: Dictionary, event: Events.Event) -> Dictionary:
	return Chart.transition(CHART, state, event)["state"]


func _a_thing_kept_with_an_entry_is_found_with_it_and_no_other() -> void:
	var kept := Kept.new()
	var home := _moved(Chart.blank(), Events.Event.go(&"home"))
	var as_seven := _moved(home, Events.Event.go(&"coins", 7))
	var as_eight := _moved(as_seven, Events.Event.go(&"coins", 8))
	var amount := Amount.new()
	kept.keep(Kept.entry_of(as_seven), &"amount", amount)
	_verdict.check(kept.kept(Kept.entry_of(as_seven), &"amount") == amount and kept.kept(Kept.entry_of(home), &"amount") == null, "kept with the coins as 7, it is found there and not at home")
	_verdict.check(Kept.entry_of(as_eight) != Kept.entry_of(as_seven) and kept.kept(Kept.entry_of(as_eight), &"amount") == null, "the coins as 8 are another entry, with nothing kept: %s / %s" % [Kept.entry_of(as_eight), Kept.entry_of(as_seven)])


func _the_entry_being_left_is_written_before_the_state_moves_and_found_again_on_back() -> void:
	var kept := Kept.new()
	var coins := _moved(_moved(Chart.blank(), Events.Event.go(&"home")), Events.Event.go(&"coins"))
	var leaving := Kept.entry_of(coins)
	var notes := _moved(coins, Events.Event.go(&"notes"))
	var amount := Amount.new()
	kept.keep(leaving, &"amount", amount)
	kept.let_go(notes)
	var back := _moved(notes, Events.Event.back())
	kept.let_go(back)
	_verdict.check(kept.kept(Kept.entry_of(back), &"amount") == amount, "written to the coins' entry as the reader leaves for the notes, it is found on Back: %s" % Kept.entry_of(back))


func _what_the_history_no_longer_holds_is_let_go_and_freed_and_what_it_holds_stays() -> void:
	var kept := Kept.new()
	var home := _moved(Chart.blank(), Events.Event.go(&"home"))
	var coins := _moved(home, Events.Event.go(&"coins"))
	var at_home := Amount.new()
	var on_coins := Amount.new()
	var weak: WeakRef = weakref(on_coins)
	kept.keep(Kept.entry_of(home), &"amount", at_home)
	kept.keep(Kept.entry_of(coins), &"amount", on_coins)
	on_coins = null
	_verdict.check(weak.get_ref() != null, "kept with the coins' entry, it lives while the entry does")
	var back := _moved(coins, Events.Event.back())
	kept.let_go(back)
	_verdict.check(kept.kept(Kept.entry_of(coins), &"amount") == null and weak.get_ref() == null, "Back past the coins: what was kept with them is let go, and freed")
	_verdict.check(kept.kept(Kept.entry_of(back), &"amount") == at_home, "and what was kept at home, an entry the history still holds, stays")
	var forgotten := _moved(_moved(back, Events.Event.go(&"notes")), Events.Event.forget())
	kept.let_go(forgotten)
	_verdict.check(kept.kept(Kept.entry_of(home), &"amount") == null, "the way back forgotten, home's entry is let go too")


## Home, the coins, home again by a link: two visits to home are two
## entries, each with its own, and Back to the first finds the first's.
func _two_visits_to_one_view_are_two_entries_each_with_its_own() -> void:
	var kept := Kept.new()
	var home := _moved(Chart.blank(), Events.Event.go(&"home"))
	var again := _moved(_moved(home, Events.Event.go(&"coins")), Events.Event.go(&"home"))
	var first := Amount.new()
	var second := Amount.new()
	kept.keep(Kept.entry_of(home), &"amount", first)
	kept.keep(Kept.entry_of(again), &"amount", second)
	_verdict.check(Kept.entry_of(again) != Kept.entry_of(home) and kept.kept(Kept.entry_of(again), &"amount") == second, "home again is an entry of its own, with its own: %s / %s" % [Kept.entry_of(again), Kept.entry_of(home)])
	var back_twice := _moved(_moved(again, Events.Event.back()), Events.Event.back())
	kept.let_go(back_twice)
	_verdict.check(kept.kept(Kept.entry_of(back_twice), &"amount") == first and kept.kept(Kept.entry_of(again), &"amount") == null, "Back twice finds the first visit's, and the second's is let go")


## Sixty arrivals, something kept with each: what was kept with the ten
## entries dropped past the cap is let go and freed, the newest fifty's stays.
func _what_was_kept_with_an_entry_dropped_past_the_cap_is_let_go() -> void:
	var kept := Kept.new()
	var state := _moved(Chart.blank(), Events.Event.go(&"home"))
	var held: Array[WeakRef] = []
	# sixty arrivals, the coins as another one each time, an amount kept with each and the dropped let go
	for at: int in 60:
		state = _moved(state, Events.Event.go(&"coins", at))
		var amount := Amount.new()
		held.append(weakref(amount))
		kept.keep(Kept.entry_of(state), &"amount", amount)
		kept.let_go(state)
	var gone := held.slice(0, 10).all(func(weak: WeakRef) -> bool: return weak.get_ref() == null)
	var alive := held.slice(10).all(func(weak: WeakRef) -> bool: return weak.get_ref() != null)
	_verdict.check(gone and alive, "the first ten, dropped past the cap, are let go and freed; the newest fifty stay: %s %s" % [gone, alive])


func _a_node_is_refused_out_loud_and_never_kept() -> void:
	var kept := Kept.new()
	var home := _moved(Chart.blank(), Events.Event.go(&"home"))
	var before := _hearing.refusals
	var node := Node.new()
	kept.keep(Kept.entry_of(home), &"node", node)
	_verdict.check(_hearing.refusals == before + 1 and kept.kept(Kept.entry_of(home), &"node") == null, "a Node handed in is refused out loud and not kept")
	node.free()
