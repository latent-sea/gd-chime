extends "bound.gd"

const Chimes := preload("../../chimes.gd")
const Motion := preload("../../motion.gd")
const OwnBell := preload("own_bell.gd")

## An eased value: a bound value that goes smoothly to wherever its source
## has moved, rather than being there at once - a bar filling, a quantity
## rolling up, a line reaching its new point.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## It is a run on the one clock (motion.gd), by an easing the look names.
## Reading it reads the source, so a reader follows whatever the source
## read, and that read is where a moved source is noticed: the run is sent
## to the new value from wherever it has got to, so a change mid-flight
## never jumps; every step then rings this value's own bell (own_bell.gd),
## which the read notes too, and the reader reads the value on its way. It
## listens to nothing, so nothing holds it but its readers.
##
## Numbers, colours and vectors go smoothly. What cannot be gone between -
## nothing yet, words, a value of another type than the last - is simply
## there at once. Reduced motion and the frame budget are the clock's: it
## snaps there, and this knows nothing of either.

var _own := OwnBell.new("eased")
var _motion: Motion
var _source: Bound
var _easing: StringName
var _run: Motion.Run = null
var _value: Variant
var _target: Variant
var _begun: bool = false


func _init(chimes: Chimes, motion: Motion, source: Bound, easing: StringName) -> void:
	super(Callable())
	_own.hang(chimes)
	_motion = motion
	_source = source
	_easing = easing


## The value as it is now; a source that has moved is set off after here.
func read() -> Variant:
	_own.noted()
	var wanted: Variant = _source.read()
	if not _begun or typeof(wanted) != typeof(_target) or not typeof(wanted) in [TYPE_FLOAT, TYPE_INT, TYPE_COLOR, TYPE_VECTOR2]:
		_begun = true
		_target = wanted
		_value = wanted
		if _run != null:
			_run.stopped = true
			_run = null
	elif wanted != _target:
		_target = wanted
		if _run == null:
			_run = _motion.run(_value, wanted, _easing, _moved)
		else:
			_motion.retarget(_run, wanted)
	return _value


func _moved(value: Variant) -> void:
	_value = value
	_own.moved()
