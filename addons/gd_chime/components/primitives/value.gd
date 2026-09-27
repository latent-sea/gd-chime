extends "bound.gd"

const OwnBell := preload("own_bell.gd")

## A value: one fact a model declares, and holds.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
##     var count := value(0)
##
## IT IS A BOUND VALUE ITSELF: handed to a primitive as it is, mapped, read
## through a field - there is no getter to name and no bell to list. Read,
## it notes its model's bell (reads.gd), so whatever read it - a control
## drawing, a refusal asked, another bound value - listens there and nowhere
## else. Set, it asks that bell to ring (own_bell.gd), which rings once a
## frame however many of the model's values were set in it: the bell still
## carries nothing, and whoever hears it reads the model again.
##
## SET ONLY FROM THE MAIN THREAD, SAID OUT LOUD, as a read is (reads.gd): a
## job in the background hands what it made to the main thread, and a set
## from the job itself is refused and moves nothing.
##
## Setting rings whether or not the value is different: a value holding an
## array or a dictionary may have been changed in place and set again as
## the same one, and a set that rang nothing then would leave a reader
## showing what is gone, silently.
##
## Deliberately absent: a name. A reader never asks for one; it reads.
##
## A READ NOTES THE BELL'S ADDRESS ITSELF, by the one name taken from the
## bell as this is made, rather than asking the bell to: a call into another
## script is the dearest thing on a draw's path - measured - and this is
## the call every draw of every control makes most.

var _bell: OwnBell
var _at: StringName  # the one name of the bell's address, noted here directly
var _held: Variant


func _init(bell: OwnBell, initial: Variant) -> void:
	super(Callable())
	_bell = bell
	_at = bell.get_at()
	_held = initial


## The value as it is now, its model's bell noted for whoever is reading.
func read() -> Variant:
	Reads.note_at(_at)
	return _held


## The value from now on, its model's bell asked to ring - from the main
## thread; set from any other, it is refused out loud and does not move.
func set_value(to: Variant) -> void:
	if not Reads.is_main_thread():
		push_error("%s was set off the main thread: set it where the job's answer lands, on the main thread - a value set from a job would move with no reader told, and count its move in what the main thread is reading" % _at)
		return
	_held = to
	_bell.moved()
