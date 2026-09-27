extends RefCounted

const Belfry := preload("belfry.gd")

## The wires: which listener is connected to which bell, and under what key.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Held by the chimes and by nothing else. Nothing here decides anything:
## what to wire and what to cut is theirs, and this is the record.
##
## THE WIRES ARE KEPT BY LISTENER, then by the KEY they were made under - the
## key of the work whose reads they follow, or none for a bell simply
## listened to - then by the ONE NAME OF THE ADDRESS the bell hangs at. So
## the wires under one key ARE a set of addresses, with the arrival beside
## each: what a piece of work read is compared with them as one set against
## another, which is what every draw of every control does, and a listener
## asked about, stopped, or cut loose as it is freed touches nothing but its
## own, however many thousand others there are.
##
## AN ADDRESS READ WHERE NO BELL HANGS YET IS KEPT ALL THE SAME, its arrival
## waiting: so what a work read and what is kept still compare equal, and a
## draw that reads it again changes nothing; and when a bell is hung there
## (hung) the arrival is connected, so the next ring reaches the reader.
##
## A FOLLOWED KEY KEEPS ITS WORK (Follow): the work, what a ring there runs
## instead of it, and the one arrival every wire of the key is connected
## with, which reads the other two as it arrives. Following again with new
## work writes the record; nothing is wired again, and a ring runs the work
## handed last. The record holds the key's addresses too, the same
## dictionary its wires are kept in, so a draw reaches into this script once.
##
## WHO IS WIRED AT AN ADDRESS IS THE BELL'S OWN RECORD - its connections, each
## a follow's record or a listener's heard() - and the listeners are kept by
## the region they belong to (_members): so a region taken down costs the
## wires it cuts, found through the bells hung in it and the listeners
## belonging to it, never a walk of every wire held, and making a wire - on
## the path of a draw whose reads moved - keeps no index of its own. Only an
## address waiting for a bell is kept apart (_waiting), for hung() to find.
##
## A listener holding nothing is not held: its last wire takes its key, and
## its last key takes the listener, so asking about one that hears nothing
## leaves nothing behind.

## The key a bell simply listened to is kept under: it follows no work, so it keeps no record.
const LISTENED := &""


## What a followed key keeps: the addresses it read - the very dictionary its
## wires are kept in - the work handed last, what a ring runs instead, and
## the chimes' following again; and arrive(), the one arrival every wire of
## the key is connected with. A method of this record rather than a function
## of the chimes: a Callable holds its object weakly, so the record held here
## is the only thing keeping it, and nothing it holds holds the chimes.
class Follow extends RefCounted:
	var at: Dictionary = {}  # address -> the arrival: the key's wires themselves
	var work: Callable
	var moved: Callable
	var listener: Object  # who follows, found again from a bell's connection to this
	var key: StringName  # the key it follows under
	var _again: Callable  # the chimes' follow of this listener under this key, handed the work

	func _init(follower: Object, under: StringName, again: Callable) -> void:
		listener = follower
		key = under
		_again = again

	## A ring at something the work read: moved, if it was handed one, else the work again, which follows again.
	func arrive() -> void:
		if moved.is_valid():
			moved.call()
			return
		_again.call(work)


var _belfry: Belfry
var _held: Dictionary = {}  # listener -> key -> address -> the arrival, connected wherever a bell hangs there
var _follows: Dictionary = {}  # listener -> a followed key -> its record (Follow), held here and nowhere else
var _homes: Dictionary = {}  # listener -> the region it belongs to
var _members: Dictionary = {}  # region -> the listeners belonging to it, used as a set
var _waiting: Dictionary = {}  # an address no bell hangs at yet -> listener -> the keys waiting there, used as a set


func _init(belfry: Belfry) -> void:
	_belfry = belfry


## The wires one listener holds under one key, by the address each hangs at.
## Holding none, an empty one that is NOT kept, so asking never leaves a key
## behind. Written the long way round because get(key, {}) would make that
## empty one on every draw.
func under(listener: Variant, key: StringName) -> Dictionary:
	var keys: Variant = _held.get(listener)
	return {} if keys == null or not keys.has(key) else keys[key]


## What a followed key keeps, or nothing: the one reach here on every draw's path.
func followed(listener: Object, key: StringName) -> Follow:
	var keys: Variant = _follows.get(listener)
	return null if keys == null else keys.get(key)


## What a followed key keeps, kept before its first wire is made; it goes with the key's last wire.
func keep_follow(record: Follow) -> void:
	if not _follows.has(record.listener):
		_follows[record.listener] = {}
	_follows[record.listener][record.key] = record


## One wire made: the arrival kept under the key at the address, and
## connected to the bell there if one hangs - else waiting for one (hung).
func make(listener: Object, at: StringName, arrival: Callable, key: StringName) -> void:
	var bell := _belfry.bell_at(at)
	if bell != null:
		bell.changed.connect(arrival)
	else:
		if not _waiting.has(at):
			_waiting[at] = {}
		if not _waiting[at].has(listener):
			_waiting[at][listener] = {}
		_waiting[at][listener][key] = true
	if not _held.has(listener):
		_held[listener] = {}
		# the region the listener belongs to, if it has one: dropping that region cuts this
		var home: StringName = listener.region if "region" in listener else &""
		_homes[listener] = home
		if not _members.has(home):
			_members[home] = {}
		_members[home][listener] = true
	var keys: Dictionary = _held[listener]
	# a followed key's addresses are its record's own, so the draw that compares them reaches nothing else
	if not keys.has(key):
		keys[key] = followed(listener, key).at if key != LISTENED else {}
	keys[key][at] = arrival


## A bell hung at an address wires were waiting at: each of their arrivals
## connected to it, and nothing waiting there any more.
func hung(bell: Object) -> void:
	# every listener waiting at the address, and every key it waits under
	for listener: Variant in _waiting.get(bell.at, {}):
		for key: StringName in _waiting[bell.at][listener]:
			bell.changed.connect(_held[listener][key][bell.at])
	_waiting.erase(bell.at)


## One wire cut: its connection and its record gone - with the last under a
## key the key and what it kept, and with the last key the listener.
func cut(listener: Variant, key: StringName, at: StringName) -> void:
	var bell := _belfry.bell_at(at)
	if bell == null:
		var there: Dictionary = _waiting[at]
		there[listener].erase(key)
		if there[listener].is_empty():
			there.erase(listener)
		if there.is_empty():
			_waiting.erase(at)
	# a freed end has already had its connection dropped by the engine
	elif is_instance_valid(listener):
		bell.changed.disconnect(_held[listener][key][at])
	var keys: Dictionary = _held[listener]
	keys[key].erase(at)
	if keys[key].is_empty():
		keys.erase(key)
		# a followed key's last wire: its record goes too
		if key != LISTENED:
			_follows[listener].erase(key)
			if _follows[listener].is_empty():
				_follows.erase(listener)
	if keys.is_empty():
		_held.erase(listener)
		_members[_homes[listener]].erase(listener)
		if _members[_homes[listener]].is_empty():
			_members.erase(_homes[listener])
		_homes.erase(listener)


## Every wire one listener holds under one key, cut.
func cut_key(listener: Variant, key: StringName) -> void:
	# every address wired under that key; the addresses are taken first, because cutting erases them
	for at: StringName in under(listener, key).keys():
		cut(listener, key, at)


## Every wire one listener holds at all, cut.
func cut_all(listener: Variant) -> void:
	if not _held.has(listener):
		return
	# every key this listener holds wires under, the wires under it cut
	for key: StringName in _held[listener].keys():
		cut_key(listener, key)


## Every wire at the bell hung at one address, whoever holds it, cut: the
## bell is being taken down. The bell's own connections say who: a follow's
## arrival is its record's, a listen's is the listener's own heard().
func cut_at(at: StringName) -> void:
	# every connection the bell holds, as the listener and the key it was made under; taken first, because cutting drops them
	for wire: Array in _wired_at(at):
		cut(wire[0], wire[1], at)


## Every wire connected to the bell hung at one address, as [listener, key].
func _wired_at(at: StringName) -> Array:
	var wires: Array = []
	# every connection the bell holds, its end a follow's record or a listener's heard()
	for connection: Dictionary in _belfry.bell_at(at).changed.get_connections():
		var end: Object = (connection["callable"] as Callable).get_object()
		wires.append([end.listener, end.key] if end is Follow else [end, LISTENED])
	return wires


## Every wire of a listener that belongs to this region, and every wire at
## a bell hanging in it, cut: found through the region's listeners and its
## bells, so it costs the wires cut and nothing else held.
func cut_region(region: StringName) -> void:
	# every listener belonging to the region, cut loose whole; taken first, because cutting erases them
	for listener: Variant in _members.get(region, {}).keys():
		cut_all(listener)
	# every bell hung in the region, the wires at it cut
	for bell: Object in _belfry.bells_in(region):
		cut_at(bell.at)


## Which listeners the bell known by this one name reaches: nobody, where no bell hangs.
func listeners_of(at: StringName) -> Array:
	if _belfry.bell_at(at) == null:
		return []
	var listeners: Array = []
	# every wire at the bell, its listener once
	for wire: Array in _wired_at(at):
		if not listeners.has(wire[0]):
			listeners.append(wire[0])
	return listeners


## How many connections are held, for a test to read growth: one waiting for a bell is not yet.
func count() -> int:
	var held := 0
	# every listener, the wires under each of its keys counted where a bell hangs
	for listener: Variant in _held:
		for key: StringName in _held[listener]:
			for at: StringName in _held[listener][key]:
				held += 1 if _belfry.bell_at(at) != null else 0
	return held


## How many listeners hold any connection, so a test can read the structure.
func count_listeners() -> int:
	return _held.size()
