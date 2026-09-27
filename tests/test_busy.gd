extends SceneTree

## What must be true of the busy gate.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_busy.gd
##
## Busy is counted, not a boolean, and its two bells sound only on the
## crossings. Each property below is one a holder or a listener relies on: a
## second hold keeps it busy through the first release; it names what is
## keeping it busy; BUSY_BEGAN and BUSY_ENDED each sound once across a whole sequence; a
## name is held once; a doubled release neither takes it below what is
## really running nor reopens it under live work; and the gate rings in the
## global region, where anything can hear it without being told.
##
## Nothing here is a controller. The chimes know a listener only as something
## with heard, so what stands in for one is the smallest thing that counts.
## This test hangs the belfry and wires the ears by hand, standing in for
## whatever composes an application.

const Belfry := preload("res://addons/gd_chime/belfry.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Busy := preload("res://addons/gd_chime/busy.gd")
const Verdict := preload("res://tests/verdict.gd")

var _verdict := Verdict.new()


class Ear extends RefCounted:
	var arrivals: Array[StringName] = []

	func heard(what: StringName) -> void:
		arrivals.append(what)


func _init() -> void:
	await _verdict.states(_two_holds_and_one_release_is_still_busy)
	await _verdict.states(_it_names_what_is_keeping_it_busy_oldest_first)
	await _verdict.states(_busy_began_on_the_first_hold_busy_ended_on_the_last_release_and_nothing_between)
	await _verdict.states(_a_name_is_held_once)
	await _verdict.states(_a_doubled_release_neither_underflows_nor_reopens)
	await _verdict.states(_the_gate_rings_in_the_global_region)
	quit(_verdict.deliver(get_script()))


## A gate, an ear on the bells asked for, and the chimes over them, as
## [busy, ear, chimes].
func _made(hearing: Array) -> Array:
	var chimes := Chimes.new(Belfry.new())
	var busy := Busy.new(chimes)
	var ear := Ear.new()
	# each bell asked for, listened to under its own name
	for name: StringName in hearing:
		chimes.listen(ear, Chimes.GLOBAL, name)
	return [busy, ear, chimes]


func _two_holds_and_one_release_is_still_busy() -> void:
	var made := _made([])
	var busy: Busy = made[0]

	busy.hold(&"binding")
	busy.hold(&"tally")
	busy.release(&"binding")

	_verdict.check(busy.is_busy(), "still busy on the hold that remains")
	_verdict.check(busy.get_holds() == [&"tally"], "and it is the one that remains")
	busy.free()


## A stuck-busy hunt is reading this list, so it names them oldest first: the
## oldest is the likeliest leak.
func _it_names_what_is_keeping_it_busy_oldest_first() -> void:
	var made := _made([])
	var busy: Busy = made[0]
	_verdict.check(not busy.is_busy() and busy.get_holds().is_empty(), "before any hold it is idle and names nothing")

	busy.hold(&"binding")
	busy.hold(&"tally")
	busy.hold(&"autoplay")

	_verdict.check(busy.get_holds() == [&"binding", &"tally", &"autoplay"], "the names, in the order taken")
	busy.release(&"tally")
	_verdict.check(busy.get_holds() == [&"binding", &"autoplay"], "and a release leaves the others in their order")
	busy.free()


## The whole cost to a listener: two wakes across a whole sequence, one per
## crossing. A listener that cares about one direction hears only that one.
func _busy_began_on_the_first_hold_busy_ended_on_the_last_release_and_nothing_between() -> void:
	var made := _made([Busy.BUSY_BEGAN, Busy.BUSY_ENDED])
	var busy: Busy = made[0]
	var both: Ear = made[1]
	var settling := Ear.new()
	(made[2] as Chimes).listen(settling, Chimes.GLOBAL, Busy.BUSY_ENDED)

	busy.hold(&"binding")
	_verdict.check(both.arrivals == [Busy.BUSY_BEGAN], "the first hold sounds BUSY_BEGAN")
	busy.hold(&"tally")
	busy.release(&"binding")
	_verdict.check(both.arrivals == [Busy.BUSY_BEGAN], "a second hold and a first release sound nothing")
	busy.release(&"tally")
	_verdict.check(both.arrivals == [Busy.BUSY_BEGAN, Busy.BUSY_ENDED], "and the last release sounds BUSY_ENDED")
	_verdict.check(settling.arrivals == [Busy.BUSY_ENDED], "a listener on BUSY_ENDED alone heard only that")
	busy.free()


## Holding a held name is refused rather than counted twice, so one release
## frees it. Two things busy at once name themselves apart.
func _a_name_is_held_once() -> void:
	var made := _made([Busy.BUSY_BEGAN, Busy.BUSY_ENDED])
	var busy: Busy = made[0]
	var ear: Ear = made[1]

	busy.hold(&"binding")
	busy.hold(&"binding")
	busy.release(&"binding")

	_verdict.check(not busy.is_busy(), "one release frees a name however often it was held")
	_verdict.check(ear.arrivals == [Busy.BUSY_BEGAN, Busy.BUSY_ENDED], "and the refused hold sounded nothing")
	busy.free()


## The lab's failure: a count taken below what is really running, reopening
## the application under live work. A release of a name not held is refused
## and moves nothing.
func _a_doubled_release_neither_underflows_nor_reopens() -> void:
	var made := _made([Busy.BUSY_ENDED])
	var busy: Busy = made[0]
	var ear: Ear = made[1]
	busy.hold(&"binding")
	busy.hold(&"tally")
	busy.release(&"binding")

	busy.release(&"binding")

	_verdict.check(busy.is_busy(), "still busy on the other")
	_verdict.check(busy.get_holds() == [&"tally"], "which is still named")
	_verdict.check(ear.arrivals.is_empty(), "and BUSY_ENDED has not sounded")
	busy.release(&"tally")
	_verdict.check(ear.arrivals == [Busy.BUSY_ENDED], "until the real last release")
	busy.free()


## There is one gate and it outlives every screen, so its bells hang in the
## global region: a listener that knows only a bell's name and the global region
## hears it, with nothing said about a region when the gate was made.
func _the_gate_rings_in_the_global_region() -> void:
	var made := _made([Busy.BUSY_BEGAN])
	var busy: Busy = made[0]
	var ear: Ear = made[1]

	busy.hold(&"binding")

	_verdict.check(busy.region == Chimes.GLOBAL, "the gate is in the global region: %s" % busy.region)
	_verdict.check(ear.arrivals == [Busy.BUSY_BEGAN], "and its bell is heard there: %s" % [ear.arrivals])
	busy.free()
