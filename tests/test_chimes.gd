extends SceneTree

## What must be true of the chimes.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_chimes.gd
##
## Nothing here is a controller. The chimes know a listener only as something
## with heard, so what stands in for one is the smallest thing that counts.
##
## What a bell is and how an address answers is proved in test_belfry.gd.
## Everything below is about what a connection does: where a strike arrives,
## what stops it, what a dropped region takes with it - its own listeners,
## whatever listens into it, and its bells - and that listening at an address
## nobody has hung is refused out loud.

const Belfry := preload("res://addons/gd_chime/belfry.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Verdict := preload("res://tests/verdict.gd")

var _verdict := Verdict.new()
var _hearing := Hearing.new()


## Counts what is pushed as an error, which is how the chimes and the belfry say no.
class Hearing extends Logger:
	var refusals: int = 0

	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_ERROR:
			refusals += 1


## A listener with the region it belongs to, as a controller has; left empty,
## it belongs to none.
class Ear extends RefCounted:
	var region: StringName = &""
	var arrivals: Array[StringName] = []

	func heard(what: StringName) -> void:
		arrivals.append(what)


## A listener that asks whether a bell is sounding as it is heard, strikes
## another bell from there, and asks again inside that one.
class Asker extends RefCounted:
	var chimes: Chimes
	var sounding: Array[bool] = []
	var _inner := false

	func _init(given: Chimes) -> void:
		chimes = given

	func heard(_what: StringName) -> void:
		sounding.append(chimes.is_striking())
		if not _inner:
			_inner = true
			chimes.listen(self, &"a_screen", &"shown")
			chimes.strike(&"a_screen", &"shown")


## A listener that can be destroyed on demand. The chimes hold a listener, so
## only a Node can be; a controller is a Node, so this is the real shape of it.
class NodeEar extends Node:
	var region: StringName = &""

	func heard(_what: StringName) -> void:
		pass


func _init() -> void:
	OS.add_logger(_hearing)
	await _verdict.states(_a_wake_carries_the_name_in_its_address)
	await _verdict.states(_a_name_means_one_thing_per_listener)
	await _verdict.states(_two_listeners_at_one_address_both_hear)
	await _verdict.states(_stopping_by_name_leaves_the_rest)
	await _verdict.states(_stopping_a_listener_takes_everything_it_heard)
	await _verdict.states(_a_region_is_dropped_whole_across_listeners)
	await _verdict.states(_dropping_a_region_takes_what_the_belfry_held)
	await _verdict.states(_dropping_one_region_leaves_the_others)
	await _verdict.states(_it_can_say_what_reaches_what)
	await _verdict.states(_a_freed_listener_does_not_break_a_drop)
	await _verdict.states(_a_bell_hung_through_the_chimes_is_hung_in_the_belfry)
	await _verdict.states(_listening_at_an_address_nobody_hung_is_refused_out_loud)
	await _verdict.states(_a_bell_is_sounding_while_its_listeners_run_and_not_after)
	await _verdict.states(_dropping_a_region_cuts_whatever_listens_into_it_from_elsewhere)
	await _verdict.states(_a_freed_node_leaves_no_wires_and_the_wires_are_kept_by_listener)
	OS.remove_logger(_hearing)
	quit(_verdict.deliver(get_script()))


## Chimes over bells with these addresses hung, which is what whatever composes
## an application does. Every strike below goes through the chimes' own door.
func _hung(addresses: Array) -> Chimes:
	var belfry := Belfry.new()
	# each address, hung before anything can listen to it
	for address: Array in addresses:
		belfry.register(address[0], address[1])
	return Chimes.new(belfry)


func _a_wake_carries_the_name_in_its_address() -> void:
	var chimes := _hung([[&"a_screen", &"price_changed"]])
	var ear := Ear.new()
	chimes.listen(ear, &"a_screen", &"price_changed")

	chimes.strike(&"a_screen", &"price_changed")

	_verdict.check(ear.arrivals == [&"price_changed"], "the wake arrives under the name in its address")
	_verdict.check(chimes.count() == 1, "and one connection is held")


## A listener matches on the name alone, so two things arriving under one word
## are indistinguishable once they get there - even from different regions.
func _a_name_means_one_thing_per_listener() -> void:
	var chimes := _hung([[&"my_screen", &"price_changed"], [&"their_screen", &"price_changed"]])
	var ear := Ear.new()
	chimes.listen(ear, &"my_screen", &"price_changed")

	chimes.listen(ear, &"their_screen", &"price_changed")

	_verdict.check(chimes.count() == 1, "a second thing under a taken name is refused")
	chimes.strike(&"their_screen", &"price_changed")
	_verdict.check(ear.arrivals.is_empty(), "and it never reaches the listener")


## One bell and many listeners: the shape an event makes.
func _two_listeners_at_one_address_both_hear() -> void:
	var chimes := _hung([[&"a_screen", &"price_changed"]])
	var screen := Ear.new()
	var row := Ear.new()
	chimes.listen(screen, &"a_screen", &"price_changed")
	chimes.listen(row, &"a_screen", &"price_changed")

	chimes.strike(&"a_screen", &"price_changed")

	_verdict.check(screen.arrivals == [&"price_changed"], "one of them hears it")
	_verdict.check(row.arrivals == [&"price_changed"], "and so does the other")


func _stopping_by_name_leaves_the_rest() -> void:
	var chimes := _hung([[&"a_screen", &"price_changed"], [&"a_screen", &"shown"]])
	var ear := Ear.new()
	chimes.listen(ear, &"a_screen", &"price_changed")
	chimes.listen(ear, &"a_screen", &"shown")

	chimes.stop(ear, &"price_changed")

	chimes.strike(&"a_screen", &"price_changed")
	chimes.strike(&"a_screen", &"shown")
	_verdict.check(ear.arrivals == [&"shown"], "only the other one still arrives")
	_verdict.check(chimes.count() == 1, "and only one connection is held")


func _stopping_a_listener_takes_everything_it_heard() -> void:
	var chimes := _hung([[&"a_screen", &"price_changed"], [&"a_screen", &"shown"]])
	var ear := Ear.new()
	chimes.listen(ear, &"a_screen", &"price_changed")
	chimes.listen(ear, &"a_screen", &"shown")

	chimes.stop_all(ear)

	chimes.strike(&"a_screen", &"price_changed")
	chimes.strike(&"a_screen", &"shown")
	_verdict.check(ear.arrivals.is_empty(), "nothing reaches it any more")
	_verdict.check(chimes.count() == 0, "and nothing is held")


## The reason regions exist: a screen and everything under it are separate
## objects, and closing it has to take all of them in one call.
func _a_region_is_dropped_whole_across_listeners() -> void:
	var chimes := _hung([[&"a_screen", &"price_changed"]])
	var screen := Ear.new()
	var row := Ear.new()
	var cell := Ear.new()
	# all three belong to the screen, as its parts do
	for ear: Ear in [screen, row, cell]:
		ear.region = &"a_screen"
	chimes.listen(screen, &"a_screen", &"price_changed")
	chimes.listen(row, &"a_screen", &"price_changed")
	chimes.listen(cell, &"a_screen", &"price_changed")
	_verdict.check(chimes.count() == 3, "three listeners in one region")

	chimes.drop_region(&"a_screen")

	chimes.strike(&"a_screen", &"price_changed")
	_verdict.check(chimes.count() == 0, "the region went in one call")
	_verdict.check(screen.arrivals.is_empty() and row.arrivals.is_empty() and cell.arrivals.is_empty(), "and none of them hears anything")


## One call takes both halves. Connections dropped while the belfry went on
## holding the address would refuse the next screen opened under that name.
func _dropping_a_region_takes_what_the_belfry_held() -> void:
	var belfry := Belfry.new()
	belfry.register(&"a_screen", &"price_changed")
	var chimes := Chimes.new(belfry)

	chimes.drop_region(&"a_screen")

	_verdict.check(not belfry.has(&"a_screen", &"price_changed"), "the belfry lets go of the address too")
	chimes.register(&"a_screen", &"price_changed")
	var ear := Ear.new()
	chimes.listen(ear, &"a_screen", &"price_changed")
	chimes.strike(&"a_screen", &"price_changed")
	_verdict.check(ear.arrivals == [&"price_changed"], "and it is free to be taken again, and rings")


func _dropping_one_region_leaves_the_others() -> void:
	var chimes := _hung([[&"a_screen", &"price_changed"], [Belfry.GLOBAL, &"elsewhere"]])
	var mine := Ear.new()
	mine.region = &"a_screen"
	var theirs := Ear.new()
	chimes.listen(mine, &"a_screen", &"price_changed")
	chimes.listen(theirs, Belfry.GLOBAL, &"elsewhere")

	chimes.drop_region(&"a_screen")

	chimes.strike(&"a_screen", &"price_changed")
	chimes.strike(Belfry.GLOBAL, &"elsewhere")
	_verdict.check(mine.arrivals.is_empty(), "the dropped region is silent")
	_verdict.check(theirs.arrivals == [&"elsewhere"], "and the global one is untouched")


func _it_can_say_what_reaches_what() -> void:
	var chimes := _hung([[&"a_screen", &"price_changed"], [&"a_screen", &"shown"]])
	var ear := Ear.new()
	chimes.listen(ear, &"a_screen", &"price_changed")
	chimes.listen(ear, &"a_screen", &"shown")

	_verdict.check(chimes.heard_by(ear) == [&"price_changed", &"shown"], "it can say what reaches a listener")
	_verdict.check(chimes.listeners_of(&"a_screen", &"price_changed") == [ear], "and who an address reaches")


## The record outlives the listener: the engine has already dropped the
## connection itself, so a drop has to clear the entry without reaching through
## it to something that is gone.
func _a_freed_listener_does_not_break_a_drop() -> void:
	var chimes := _hung([[&"a_screen", &"price_changed"]])
	var ear := Ear.new()
	ear.region = &"a_screen"
	var doomed := NodeEar.new()
	doomed.region = &"a_screen"
	chimes.listen(ear, &"a_screen", &"price_changed")
	chimes.listen(doomed, &"a_screen", &"price_changed")
	_verdict.check(chimes.count() == 2, "two listeners are connected")

	doomed.free()

	chimes.strike(&"a_screen", &"price_changed")
	_verdict.check(ear.arrivals == [&"price_changed"], "the wake still reaches the one that is left")
	chimes.drop_region(&"a_screen")
	_verdict.check(chimes.count() == 0, "and the drop clears both records")


## A controller needs the chimes and nothing else: what it hangs through this
## door is the same bell a listener is connected to.
func _a_bell_hung_through_the_chimes_is_hung_in_the_belfry() -> void:
	var belfry := Belfry.new()
	var chimes := Chimes.new(belfry)
	var ear := Ear.new()

	chimes.register(&"a_screen", &"answered")
	chimes.listen(ear, &"a_screen", &"answered")
	chimes.strike(&"a_screen", &"answered")

	_verdict.check(belfry.has(&"a_screen", &"answered"), "the belfry holds it")
	_verdict.check(ear.arrivals == [&"answered"], "and it rings whoever listened")


## A mistake in an address is caught where the listening is set up, not found
## later as a wake that never comes.
func _listening_at_an_address_nobody_hung_is_refused_out_loud() -> void:
	var chimes := Chimes.new(Belfry.new())
	var ear := Ear.new()
	var before := _hearing.refusals

	chimes.listen(ear, &"a_screen", &"answered")
	_verdict.check(_hearing.refusals == before + 1, "listening at an address nobody hung is refused out loud")
	_verdict.check(chimes.count() == 0 and ear.arrivals.is_empty(), "and nothing is connected")
	chimes.register(&"a_screen", &"answered")
	chimes.listen(ear, &"a_screen", &"answered")
	chimes.strike(&"a_screen", &"answered")
	_verdict.check(_hearing.refusals == before + 1 and ear.arrivals == [&"answered"], "hung first, the same listening is taken without a word and hears the strike")


## What may not be done from inside heard() asks the chimes whether a bell is
## sounding; a listener that strikes another bell is still inside the first.
func _a_bell_is_sounding_while_its_listeners_run_and_not_after() -> void:
	var chimes := Chimes.new(Belfry.new())
	var asker := Asker.new(chimes)
	chimes.register(&"a_screen", &"answered")
	chimes.register(&"a_screen", &"shown")
	chimes.listen(asker, &"a_screen", &"answered")
	_verdict.check(not chimes.is_striking(), "nothing is sounding before a strike")

	chimes.strike(&"a_screen", &"answered")
	_verdict.check(asker.sounding == [true, true], "sounding while the listener runs, and still while a bell it strikes from there runs: %s" % [asker.sounding])
	_verdict.check(not chimes.is_striking(), "and not once the strike is over")
	# the asker holds the chimes and the chimes hold the asker: the cycle broken, so nothing is left at exit
	asker.chimes = null


## A closed screen leaves nothing behind: its own listeners are cut, so is
## anything outside listening into it, and its bells are forgotten, so the
## screen opened again hangs them without a word.
func _dropping_a_region_cuts_whatever_listens_into_it_from_elsewhere() -> void:
	var belfry := Belfry.new()
	var chimes := Chimes.new(belfry)
	var outside := Ear.new()
	outside.region = Belfry.GLOBAL
	var inside := Ear.new()
	inside.region = &"a_screen"
	chimes.register(&"a_screen", &"answered")
	chimes.listen(outside, &"a_screen", &"answered")
	chimes.listen(inside, &"a_screen", &"answered")

	chimes.drop_region(&"a_screen")

	_verdict.check(chimes.count() == 0 and not belfry.has(&"a_screen", &"answered"), "both connections and the bell are gone")
	var before := _hearing.refusals
	chimes.register(&"a_screen", &"answered")
	chimes.strike(&"a_screen", &"answered")
	_verdict.check(_hearing.refusals == before and outside.arrivals.is_empty() and inside.arrivals.is_empty(), "made again, the bell is hung without a word and reaches nobody the old one did")


## Hears as a node, so the engine tells it it is about to be freed.
class Listening extends "res://addons/gd_chime/controller.gd":
	func _init(chimes: Chimes, listening: Array) -> void:
		super(chimes, listening, Chimes.GLOBAL)


## A node freed cuts itself loose, with no call at the call site; and the
## wires are kept by listener, so a few thousand listeners are a few thousand
## keys, and one listener asked or stopped is one key touched.
func _a_freed_node_leaves_no_wires_and_the_wires_are_kept_by_listener() -> void:
	var chimes := _hung([[&"a_screen", &"price_changed"], [&"a_screen", &"shown"]])
	var node := Listening.new(chimes, [[&"a_screen", &"price_changed"], [&"a_screen", &"shown"]])
	_verdict.check(chimes.count() == 2 and chimes.count_listeners() == 1, "a node listening twice is one listener with two wires: %d, %d" % [chimes.count(), chimes.count_listeners()])
	node.free()
	_verdict.check(chimes.count() == 0 and chimes.count_listeners() == 0 and chimes.listeners_of(&"a_screen", &"shown").is_empty(), "freed, it left no wires and no key behind: %d, %d" % [chimes.count(), chimes.count_listeners()])

	var many: Array = []
	# a few thousand listeners, one wire each
	for index: int in range(3000):
		var ear := Ear.new()
		chimes.listen(ear, &"a_screen", &"shown")
		many.append(ear)
	_verdict.check(chimes.count() == 3000 and chimes.count_listeners() == 3000, "three thousand listeners are three thousand keys with a wire each: %d, %d" % [chimes.count(), chimes.count_listeners()])
	chimes.stop_all(many[1500])
	_verdict.check(chimes.count() == 2999 and chimes.count_listeners() == 2999 and chimes.heard_by(many[1500]).is_empty() and chimes.heard_by(many[1501]) == [&"shown"], "stopping one erases its key alone, and asking another reads its own wires")
