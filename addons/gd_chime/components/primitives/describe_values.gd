extends "describe_rooms.gd"

const Frames := preload("../../frames.gd")
const Reads := preload("../../reads.gd")

## The values an interface makes for itself, with no model to hold them: a
## local, an eased value, a value worked out, one worked out once per change,
## and one read every frame.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The rest of the vocabulary is describe.gd's, which this extends, and the
## layers after, which extend this; the builder (ui.gd) extends them all.
## These stand apart because none of them describes a piece: each is a
## bound value a piece is given, and a bound value knows what it read
## (reads.gd), so nothing here lists what to listen to.

## The frames' bell (frames.gd), made with the builder and put under the root as it starts; running only once a value read every frame is asked for.
var frames: Frames


## A value of the interface's own, belonging to what is built from it
## (local.gd): never a fact of the game. Chain kept and it lives with the
## view instead, so a detour and Back find it as it was.
func local(initial: Variant) -> Local:
	return Local.new(chimes, driver, initial)


## A bound value that goes smoothly to wherever this one moves, by an
## easing the look names (eased.gd): a number, a colour or a vector.
func eased(source: Bound, easing: StringName = Motion.MOVE) -> Bound:
	return Eased.new(chimes, motion, source, easing)


## A value worked out by this function whenever it is read, on whatever
## the function read: a blend of models' values, a model's own reading.
func bound(work: Callable) -> Bound:
	return Bound.new(work)


## A value worked out by this function once, and again only when something
## it read has moved, however often it is read in between (reads.gd,
## worked): a list every piece of a page reads, which worked out on every
## read cost each piece's draw the whole list (the speed audit, 22 Nov:
## Dynasty's market, 4 s a visit). Whoever reads it follows what the
## function read, as a bound value's reader does. The function must read
## everything it depends on through a value: what it reads past one - the
## clock, a plain field - is not heard, and the value stands as it was.
func kept(work: Callable) -> Bound:
	var held: Array = []
	return Bound.new(func() -> Variant: return Reads.worked(held, work))


## A value worked out by this function again every frame, and on whatever
## else it read: the time, or a count the engine keeps.
func every_frame(work: Callable) -> Bound:
	frames.run()
	return Bound.new(func() -> Variant:
		Reads.note(Chimes.GLOBAL, Frames.FRAME_PASSED)
		return work.call())
