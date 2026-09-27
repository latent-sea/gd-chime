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
## A WIRE IS THE ARRIVAL AND NOTHING MORE. Where it hangs is the key it is
## kept under; the bell is found by that address again, through the belfry,
## on the rare occasion there is something to disconnect. A few thousand
## wires are a few thousand Callables rather than a few thousand dictionaries
## of six keys, which is most of what they weighed.
##
## The region a LISTENER belongs to is kept once per listener rather than
## once per wire: dropping a region cuts everything of a listener that
## belongs to it, and a listener already freed can no longer be asked what
## its region was.
##
## A listener holding nothing is not held: its last wire takes its key, and
## its last key takes the listener, so asking about one that hears nothing
## leaves nothing behind.

var _belfry: Belfry
var _held: Dictionary = {}  # listener -> key -> address -> the arrival connected to the bell there
var _homes: Dictionary = {}  # listener -> the region it belongs to


func _init(belfry: Belfry) -> void:
	_belfry = belfry


## The wires one listener holds under one key, by the address each hangs at.
## Holding none, an empty one that is NOT kept, so asking never leaves a key
## behind. Written the long way round because get(key, {}) would make that
## empty one on every draw.
func under(listener: Object, key: StringName) -> Dictionary:
	var keys: Variant = _held.get(listener)
	return {} if keys == null or not keys.has(key) else keys[key]


## One wire made: the arrival connected to the bell and kept under the key it
## was made for, at the address the bell hangs at.
func make(listener: Object, bell: Object, arrival: Callable, key: StringName) -> void:
	bell.changed.connect(arrival)
	if not _held.has(listener):
		_held[listener] = {}
		# the region the listener belongs to, if it has one: dropping that region cuts this
		_homes[listener] = listener.region if "region" in listener else &""
	var keys: Dictionary = _held[listener]
	if not keys.has(key):
		keys[key] = {}
	keys[key][bell.at] = arrival


## One wire cut: its connection dropped and its record gone - and with the
## last wire under a key that key, and with the last key the listener.
func cut(listener: Variant, key: StringName, at: StringName) -> void:
	var bell := _belfry.bell_at(at)
	# a freed end has already had its connection dropped by the engine
	if bell != null and is_instance_valid(listener):
		bell.changed.disconnect(_held[listener][key][at])
	var keys: Dictionary = _held[listener]
	keys[key].erase(at)
	if keys[key].is_empty():
		keys.erase(key)
	if keys.is_empty():
		_held.erase(listener)
		_homes.erase(listener)


## Every wire one listener holds under one key, cut.
func cut_key(listener: Object, key: StringName) -> void:
	# every address wired under that key; the addresses are taken first, because cutting erases them
	for at: StringName in under(listener, key).keys():
		cut(listener, key, at)


## Every wire one listener holds at all, cut.
func cut_all(listener: Object) -> void:
	if not _held.has(listener):
		return
	# every key this listener holds wires under, the wires under it cut
	for key: StringName in _held[listener].keys():
		cut_key(listener, key)


## Every wire of a listener that belongs to this region, and every wire that
## hangs in it, cut. What is going is gathered before any of it is cut,
## because cutting a listener's last wire takes the record the walk reads.
func cut_region(region: StringName) -> void:
	var going: Array = []
	# every wire of every listener: those whose listener belongs to the region, and those hanging in it
	for listener: Variant in _held:
		var belongs: bool = _homes[listener] == region
		for key: StringName in _held[listener]:
			for at: StringName in _held[listener][key]:
				if belongs or _belfry.bell_at(at).region == region:
					going.append([listener, key, at])
	# each wire that is going, cut
	for one: Array in going:
		cut(one[0], one[1], one[2])


## Which listeners the bell known by this one name reaches.
func listeners_of(at: StringName) -> Array:
	var listeners: Array = []
	# every listener, kept if one of its keys holds a wire at that address
	for listener: Variant in _held:
		for key: StringName in _held[listener]:
			if _held[listener][key].has(at):
				listeners.append(listener)
				break
	return listeners


## How many connections are held, so that growth is something a test can read.
func count() -> int:
	var held := 0
	# every listener, the wires under each of its keys counted
	for listener: Variant in _held:
		for key: StringName in _held[listener]:
			held += _held[listener][key].size()
	return held


## How many listeners hold any connection, so a test can read the structure.
func count_listeners() -> int:
	return _held.size()
