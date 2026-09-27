extends SceneTree

## What must be true of following what a piece of work read.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_follow.gd
##
## Two files together: reads.gd notes the address of every bell what a piece of
## work read moves on, and chimes.gd wires the worker to exactly those. Every
## draw of every control goes through this, so what it costs is a property as
## much as what it does: a work that read the same addresses as last time must
## leave its wires alone - neither cut nor made - and one whose reads moved
## must end wired to the new set and nothing else.
##
## What a bell is, what a strike reaches and what a dropped region takes are
## proved in test_belfry.gd and test_chimes.gd. Nothing here is a controller:
## the chimes know a follower only as something they can wire.

const Belfry := preload("res://addons/gd_chime/belfry.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Reads := preload("res://addons/gd_chime/reads.gd")
const Verdict := preload("res://tests/verdict.gd")

const KEY := &"drawn"

var _verdict := Verdict.new()


## A follower: it reads whatever it is pointed at, and counts what arrives.
class Reader extends RefCounted:
	var region: StringName = &""
	var reads: Array = []
	var runs: int = 0
	var arrivals: int = 0

	func work() -> void:
		runs += 1
		# every address this reader is pointed at now, read as a value would be
		for at: Array in reads:
			Reads.note(at[0], at[1])

	func moved() -> void:
		arrivals += 1

	func heard(_what: StringName) -> void:
		pass


func _init() -> void:
	await _verdict.states(_an_address_read_twice_is_noted_once_in_the_order_first_read)
	await _verdict.states(_a_follow_is_wired_to_exactly_what_the_work_read)
	await _verdict.states(_reading_the_same_addresses_again_leaves_the_wires_standing)
	await _verdict.states(_reads_that_moved_leave_the_new_set_wired_and_nothing_else)
	await _verdict.states(_a_work_that_reads_nothing_is_wired_to_nothing)
	await _verdict.states(_an_address_nobody_hung_is_passed_over)
	await _verdict.states(_one_name_in_two_regions_is_two_addresses)
	quit(_verdict.deliver(get_script()))


## Chimes over bells with these addresses hung, as whatever composes an
## application does.
func _hung(addresses: Array) -> Chimes:
	var belfry := Belfry.new()
	# each address, hung before anything can be wired to it
	for address: Array in addresses:
		belfry.register(address[0], address[1])
	return Chimes.new(belfry)


func _an_address_read_twice_is_noted_once_in_the_order_first_read() -> void:
	Reads.begin()
	Reads.note(&"purse", &"coins")
	Reads.note(&"stall", &"open")
	Reads.note(&"purse", &"coins")
	Reads.note(&"purse", &"seller")
	var read: Dictionary = Reads.end()

	_verdict.check(read.keys() == [Reads.hung(&"purse", &"coins"), Reads.hung(&"stall", &"open"), Reads.hung(&"purse", &"seller")], "each address read is noted once, in the order it was first read: %s" % [read.keys()])


func _a_follow_is_wired_to_exactly_what_the_work_read() -> void:
	var chimes := _hung([[&"purse", &"coins"], [&"stall", &"open"], [&"purse", &"seller"]])
	var reader := Reader.new()
	reader.reads = [[&"purse", &"coins"], [&"stall", &"open"]]

	chimes.follow(reader, KEY, reader.work, reader.moved)

	_verdict.check(chimes.followed_by(reader, KEY) == [[&"purse", &"coins"], [&"stall", &"open"]], "it follows what the work read, and in that order: %s" % [chimes.followed_by(reader, KEY)])
	_verdict.check(chimes.count() == 2, "and holds one wire for each: %d" % chimes.count())
	chimes.strike(&"purse", &"coins")
	chimes.strike(&"purse", &"seller")
	_verdict.check(reader.arrivals == 1, "a bell it read reaches it once, and one it did not read not at all: %d" % reader.arrivals)


## The common case, and the whole cost of a draw: a control reading the same
## values as last time must not have its wires taken down and put back up. A
## wire made a second time would arrive twice; one cut and remade would show
## as the work running again before the second follow returns.
func _reading_the_same_addresses_again_leaves_the_wires_standing() -> void:
	var chimes := _hung([[&"purse", &"coins"], [&"stall", &"open"]])
	var reader := Reader.new()
	reader.reads = [[&"purse", &"coins"], [&"stall", &"open"]]
	chimes.follow(reader, KEY, reader.work, reader.moved)
	var wires := chimes.count()

	chimes.follow(reader, KEY, reader.work, reader.moved)

	_verdict.check(chimes.count() == wires and wires == 2, "following the same reads again holds the same wires, not another set: %d, was %d" % [chimes.count(), wires])
	_verdict.check(chimes.followed_by(reader, KEY) == [[&"purse", &"coins"], [&"stall", &"open"]], "and the same addresses, once each: %s" % [chimes.followed_by(reader, KEY)])
	reader.arrivals = 0
	chimes.strike(&"purse", &"coins")
	_verdict.check(reader.arrivals == 1, "and a strike arrives once, not once per follow: %d" % reader.arrivals)


## What it stopped reading goes, what it still reads is left where it was, and
## what it has begun reading is added.
func _reads_that_moved_leave_the_new_set_wired_and_nothing_else() -> void:
	var chimes := _hung([[&"purse", &"coins"], [&"stall", &"open"], [&"purse", &"seller"]])
	var reader := Reader.new()
	reader.reads = [[&"purse", &"coins"], [&"stall", &"open"]]
	chimes.follow(reader, KEY, reader.work, reader.moved)

	reader.reads = [[&"stall", &"open"], [&"purse", &"seller"]]
	chimes.follow(reader, KEY, reader.work, reader.moved)

	_verdict.check(chimes.count() == 2, "it holds a wire for each address of the new set and no more: %d" % chimes.count())
	_verdict.check(chimes.followed_by(reader, KEY) == [[&"stall", &"open"], [&"purse", &"seller"]], "and follows exactly the new set: %s" % [chimes.followed_by(reader, KEY)])
	reader.arrivals = 0
	chimes.strike(&"purse", &"coins")
	_verdict.check(reader.arrivals == 0, "the one it stopped reading no longer reaches it: %d" % reader.arrivals)
	chimes.strike(&"stall", &"open")
	_verdict.check(reader.arrivals == 1, "the one it still reads reaches it once, its wire never remade: %d" % reader.arrivals)
	chimes.strike(&"purse", &"seller")
	_verdict.check(reader.arrivals == 2, "and the one it has begun reading reaches it too: %d" % reader.arrivals)


func _a_work_that_reads_nothing_is_wired_to_nothing() -> void:
	var chimes := _hung([[&"purse", &"coins"]])
	var reader := Reader.new()
	reader.reads = [[&"purse", &"coins"]]
	chimes.follow(reader, KEY, reader.work, reader.moved)

	reader.reads = []
	chimes.follow(reader, KEY, reader.work, reader.moved)

	_verdict.check(chimes.count() == 0 and chimes.followed_by(reader, KEY).is_empty(), "reading nothing, it is left following nothing: %d" % chimes.count())
	reader.arrivals = 0
	chimes.strike(&"purse", &"coins")
	_verdict.check(reader.arrivals == 0, "and the bell it used to read reaches it no more: %d" % reader.arrivals)


## A region dropped while something still reads into it: the address is read
## from nothing that can ring, so it is passed over rather than refused.
func _an_address_nobody_hung_is_passed_over() -> void:
	var chimes := _hung([[&"purse", &"coins"]])
	var reader := Reader.new()
	reader.reads = [[&"purse", &"coins"], [&"a_screen", &"gone"]]

	chimes.follow(reader, KEY, reader.work, reader.moved)

	_verdict.check(chimes.followed_by(reader, KEY) == [[&"purse", &"coins"]], "only the address something is hung at is followed: %s" % [chimes.followed_by(reader, KEY)])
	_verdict.check(reader.runs == 1, "and the work ran once: %d" % reader.runs)


## Every screen calls its own subject the same word, so the one name an address
## is known by has to carry the region as well as the name - otherwise a read
## of one screen's rows would wire the reader to another's.
func _one_name_in_two_regions_is_two_addresses() -> void:
	var chimes := _hung([[&"my_screen", &"rows"], [&"their_screen", &"rows"]])
	var reader := Reader.new()
	reader.reads = [[&"my_screen", &"rows"]]

	chimes.follow(reader, KEY, reader.work, reader.moved)

	_verdict.check(Reads.hung(&"my_screen", &"rows") != Reads.hung(&"their_screen", &"rows"), "the same name in two regions is two addresses: %s, %s" % [Reads.hung(&"my_screen", &"rows"), Reads.hung(&"their_screen", &"rows")])
	chimes.strike(&"their_screen", &"rows")
	_verdict.check(reader.arrivals == 0, "so the other region's bell of that name reaches nobody here: %d" % reader.arrivals)
	chimes.strike(&"my_screen", &"rows")
	_verdict.check(reader.arrivals == 1, "and the one that was read does: %d" % reader.arrivals)
