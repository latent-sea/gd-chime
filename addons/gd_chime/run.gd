extends RefCounted

## A run: one value on its way from where it was to where it is wanted, by
## a curve, over so long, handed on every step to the function that writes it.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## IT KEEPS NO CLOCK OF ITS OWN: the one clock (motion.gd) steps every run
## there is, in order, by the time that passed, and decides how long this
## lasts and by what curve as it begins. It never steps itself, never reads
## the look, and never writes anything but through apply. Asked to stop, it
## is simply never stepped again, and never says it arrived.
##
## TIME IS NEVER LOST AT ITS END. A step rarely lands exactly on its end: it
## arrives on the step that carries it past, and how far past is kept and
## read (get_past), so whoever sets the next run going on its arrival - the
## next frame of a track - starts it that far in, and a track repeating for
## ever stays exactly on the clock.

var value: Variant
var to: Variant
var easing: StringName
var fades: bool
var under: Control = null  # the node whose look says how it moves, or none for the window's
var drives: Array = []  # [the node's id, what of it] when it is the one run that writes that, or nothing
var lasts: float
var curve: Array  # [Tween.TransitionType, Tween.EaseType]
var apply: Callable
var done: Callable
var stopped: bool = false
var _from: Variant  # where it set off from
var _elapsed: float = 0.0  # how long it has been on its way, less any wait still to come


## Set going again from this value, its time begun again.
func restart(from: Variant) -> void:
	_from = from
	_elapsed = 0.0


## Whether it has arrived.
func is_over() -> bool:
	return stopped or _elapsed >= lasts


## How far past its end it was stepped: nothing until it has arrived.
func get_past() -> float:
	return maxf(0.0, _elapsed - lasts)


## Set off only after this long: for things entering one after another. A
## wait of less than nothing sets it off that far in already.
func wait(seconds: float) -> RefCounted:
	_elapsed = -seconds
	return self


func step(seconds: float) -> void:
	_elapsed += seconds
	if _elapsed < 0.0:
		return
	value = to if _elapsed >= lasts else Tween.interpolate_value(_from, to - _from, _elapsed, lasts, curve[0], curve[1])
	apply.call(value)


## A WAIT: a run that moves nothing - it writes through its own _rests -
## lasting these seconds, then done: time passing on the one clock
## (motion.gd, after), stepped by hand in a test like any run. Nothing still,
## reduced or over budget shortens it, since it moves nothing.
static func waiting(seconds: float, done: Callable) -> RefCounted:
	var made: RefCounted = new()
	made.value = 0.0
	made.restart(0.0)
	made.to = 1.0
	made.curve = [Tween.TRANS_LINEAR, Tween.EASE_IN]
	made.lasts = seconds
	made.apply = made._rests
	made.done = done
	return made


## What a wait writes on its way: nothing.
func _rests(_value: Variant) -> void:
	pass
