extends SceneTree

## What must be true of the belfry.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_belfry.gd
##
## Every property below is about the address: that a bell hung there sounds
## from there and carries nothing, that a name belongs to its region, that an
## address nobody hung is quiet, that a region lets go, and that the record
## says who rang what. A test may connect to a bell by hand - it stands in for
## the chimes here - so that what the chimes do is proved in their own suite.

const Belfry := preload("res://addons/gd_chime/belfry.gd")
const Verdict := preload("res://tests/verdict.gd")

var _verdict := Verdict.new()


## Counts how often it was rung. The handler takes no arguments, so a bell that
## carried anything could not call it.
class Ear extends RefCounted:
	var heard := 0

	func handle() -> void:
		heard += 1


func _init() -> void:
	await _verdict.states(_a_struck_bell_reaches_whoever_is_connected_and_carries_nothing)
	await _verdict.states(_an_address_already_taken_is_refused)
	await _verdict.states(_the_same_name_in_two_regions_is_two_belfry)
	await _verdict.states(_striking_an_address_nobody_hung_is_quiet)
	await _verdict.states(_a_dropped_region_forgets_what_it_held)
	await _verdict.states(_a_freed_listener_is_dropped_by_the_engine)
	await _verdict.states(_the_record_names_who_rang_what_and_what_reached_nothing)
	quit(_verdict.deliver(get_script()))


## Belfry with one hung at an address, and an ear on it, as [belfry, ear].
func _hung(region: StringName, name: StringName) -> Array:
	var belfry := Belfry.new()
	belfry.register(region, name)
	var ear := Ear.new()
	belfry.at(region, name).changed.connect(ear.handle)
	return [belfry, ear]


func _a_struck_bell_reaches_whoever_is_connected_and_carries_nothing() -> void:
	var made := _hung(&"a_screen", &"price_changed")
	var belfry: Belfry = made[0]
	var ear: Ear = made[1]

	belfry.strike(&"a_screen", &"price_changed")
	belfry.strike(&"a_screen", &"price_changed")

	_verdict.check(ear.heard == 2, "every strike reaches a connected listener, with nothing in it")


## Hanging over an address silently would leave whatever already listened
## ringing on one bell while the address rang another.
func _an_address_already_taken_is_refused() -> void:
	var made := _hung(&"a_screen", &"price_changed")
	var belfry: Belfry = made[0]
	var ear: Ear = made[1]

	belfry.register(&"a_screen", &"price_changed")
	belfry.strike(&"a_screen", &"price_changed")

	_verdict.check(ear.heard == 1, "the bell that was there still rings whoever listened to it")


## A name is unique only within its region, which is what lets every screen
## call its own subject the same word.
func _the_same_name_in_two_regions_is_two_belfry() -> void:
	var mine := _hung(&"my_screen", &"price_changed")
	var belfry: Belfry = mine[0]
	belfry.register(&"their_screen", &"price_changed")
	var theirs := Ear.new()
	belfry.at(&"their_screen", &"price_changed").changed.connect(theirs.handle)

	belfry.strike(&"my_screen", &"price_changed")

	_verdict.check((mine[1] as Ear).heard == 1, "one region rings its own")
	_verdict.check(theirs.heard == 0, "and not the other's")


## A model rings the address a request carried, and the screen that asked may
## be gone. This must land nowhere without a word: the engine's own complaint
## about a missing key is one the run does not stop for, and it would be
## printed for every late answer.
##
## Quiet cannot be asserted from inside; it is carried by the harness, which
## fails a suite on any engine complaint that is not a push_error.
func _striking_an_address_nobody_hung_is_quiet() -> void:
	var belfry := Belfry.new()

	belfry.strike(&"nowhere", &"nothing")

	_verdict.check(not belfry.has(&"nowhere", &"nothing"), "and nothing was conjured up by the strike")


## A region that let go of its connections and kept its bells would refuse the
## next screen that opened under the same name.
func _a_dropped_region_forgets_what_it_held() -> void:
	var made := _hung(&"a_screen", &"price_changed")
	var belfry: Belfry = made[0]

	belfry.drop_region(&"a_screen")

	_verdict.check(not belfry.has(&"a_screen", &"price_changed"), "nothing is hung there any more")
	belfry.register(&"a_screen", &"price_changed")
	belfry.strike(&"a_screen", &"price_changed")
	_verdict.check(belfry.has(&"a_screen", &"price_changed"), "the address is free to be taken again")
	_verdict.check((made[1] as Ear).heard == 0, "and the new bell reaches nobody the old one did")


## Nobody unsubscribes. A listener can be destroyed having entirely forgotten
## it ever connected, and the engine drops the connection.
func _a_freed_listener_is_dropped_by_the_engine() -> void:
	var belfry := Belfry.new()
	belfry.register(&"a_screen", &"price_changed")
	var doomed := Ear.new()
	var gone_yet: WeakRef = weakref(doomed)
	belfry.at(&"a_screen", &"price_changed").changed.connect(doomed.handle)
	_verdict.check(belfry.at(&"a_screen", &"price_changed").changed.get_connections().size() == 1, "a live listener is connected")

	doomed = null

	_verdict.check(gone_yet.get_ref() == null, "connecting does not keep a listener alive")
	_verdict.check(belfry.at(&"a_screen", &"price_changed").changed.get_connections().is_empty(), "and the connection goes with it")
	belfry.strike(&"a_screen", &"price_changed")


## The record is for finding out what is ringing something. It names the
## address, the file and line that struck it, and - for an address nobody
## hung - that it reached nothing, which is how a misspelt address is found.
func _the_record_names_who_rang_what_and_what_reached_nothing() -> void:
	var path := "user://strikes_under_test.txt"
	var belfry := Belfry.new()
	belfry.register(&"a_screen", &"price_changed")
	belfry.record_to(path)

	belfry.strike(&"a_screen", &"price_changed")
	belfry.strike(&"nowhere", &"nothing")
	# freeing the belfry closes the file, so it can be read back whole
	belfry = null

	var record := FileAccess.get_file_as_string(path)
	_verdict.check(record.contains("a_screen/price_changed"), "the address that was struck is on the record")
	_verdict.check(record.contains("in _the_record_names_who_rang_what_and_what_reached_nothing"), "with the function that struck it")
	_verdict.check(record.contains("test_belfry.gd:"), "in the file it was struck from")
	_verdict.check(record.contains("nowhere/nothing   (nothing hung there)"), "and a strike that reached nothing says so")
