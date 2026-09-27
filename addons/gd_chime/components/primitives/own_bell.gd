extends RefCounted

const Chimes := preload("../../chimes.gd")
const Reads := preload("../../reads.gd")

## A bell of one's own: the one a model's values ring, a local's, an eased
## value's - noted as what it rings for is read, and rung at most once a
## frame however often that moves.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The bell is hung at an address nothing else has - a region and a bell of
## one name, made from a count - so what reads through it hears it and
## nothing else does, and one reader may read any number of them.
##
## MOVED, IT RINGS ONCE THE FRAME'S WORK IS DONE, and once however many times
## it was moved in the frame: the ring is deferred to the end of the frame,
## so a model setting ten values rings once, and whoever hears it reads all
## ten as they ended. A reader draws on the frame after, as ever.
##
## IT IS HELD BY WHAT READS THROUGH IT AND BY NOTHING ELSE - the values, or
## the local, or the eased value - so it goes when they go, and takes its
## bell down as it does. It is made before the chimes are known - a model
## declares its values as it is made, before its own constructor runs - and
## hung once they are.

static var _made: int = 0

var _chimes: Chimes = null
var _address: StringName  # the region and the bell both
var _at: StringName  # the one name of that address, made here so that a read never makes one
var _due: bool = false  # whether a ring is waiting for the end of this frame


func _init(kind: String) -> void:
	_made += 1
	_address = StringName("%s_%d" % [kind, _made])
	_at = Reads.hung(_address, _address)


## Hang the bell, on the chimes of whatever it rings for.
func hang(chimes: Chimes) -> void:
	_chimes = chimes
	_chimes.register(_address, _address)


## The address it hangs at: the region and the bell both.
func get_address() -> StringName:
	return _address


## The one name of the address it hangs at: what a value notes by, directly,
## since a value's read is the hottest call there is and this would be a
## hop on the way.
func get_at() -> StringName:
	return _at


## What it rings for was read: noted for whoever is reading.
func noted() -> void:
	Reads.note_at(_at)


## What it rings for moved: counted at once, so a reading kept with a read of
## it is worked out afresh the moment it is asked for (reads.gd) rather than a
## frame late; and a ring at the end of this frame, unless one is waiting already.
func moved() -> void:
	Reads.moved(_address, _address)
	if _due:
		return
	_due = true
	_ring.call_deferred()


func _ring() -> void:
	_due = false
	_chimes.strike(_address, _address)


## Freed: its bell taken down, if it was ever hung.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _chimes != null:
		_chimes.drop_region(_address)
