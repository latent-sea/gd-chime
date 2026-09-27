extends Node

const Motion := preload("motion.gd")
const Look := preload("look.gd")
const Options := preload("components/primitives/options.gd")

## Whatever is asked for any number of times in a frame, done once: at the
## end of the frame it was first asked in, no oftener than a token of the
## look - PACED - or once the asking has rested for one - SETTLED.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A MODEL CHANGING HUNDREDS OF TIMES A SECOND rings its bell through one of
## these: every change asks, and the bell sounds once, after the last change
## of the frame. A bell rung twice runs every listener's heard() twice - an
## each re-reads its whole array on each ring - and the second ring says
## nothing the first did not, since a bell carries nothing and the listener
## reads the model as it stands. So the model's state is always current,
## only the news of it is gathered. This is the one form of the floor's
## pending flag and deferred call (sounds.gd's moves, cells.gd's placing,
## settings_file.gd's writing), with the deed handed in: a strike, or a
## model's own flush of what it gathered.
##
## PACED, the deed is done no oftener than its token, in milliseconds, read
## from the window's look as it is due - a counter a reader glances at every
## quarter second rather than sixty times. A pace never loses the last ask:
## one asked for inside the token is done as the token ends, so what the
## model settles on is always heard. Asked for nothing, it does nothing: it
## processes only while a paced deed waits.
##
## SETTLED, the deed is done once the asking has RESTED for its token, and
## every ask puts it further off: ten letters typed quickly run it once, of
## the line as it stood at the last. That wait is on the one clock
## (motion.gd), never on real time, so a test steps it by hand as it steps
## every other timed thing. It is the one debounce: nothing else may count
## keystrokes or hold a timer of its own. forget() drops what waits without
## doing it, for a caller that has gone ahead and done the deed itself.
##
## It is a child of the model it serves, freed with it; a deed waiting when
## it is freed is dropped with it, since whoever would have heard it has gone.

## How the deed is paced, by name; neither given and it is done at the frame's end.
const PACED_BY := "paced_by"
const SETTLES_BY := "settles_by"
## The one clock a settling wait runs on.
const ON := "on"
const OPTIONS: Array[String] = [PACED_BY, SETTLES_BY, ON]

## How long a paced deed waits after the last one, in milliseconds: a Motion token, read from the window's look.
const CADENCE := &"live_cadence"

## How many times the deed has been done, so coalescing is something a test reads.
var done_count: int = 0
## The time in milliseconds, asked of the engine unless a test holds it.
var clock: Callable = Time.get_ticks_msec

var _deed: Callable
var _paced_by: StringName  # the token a paced deed waits by, or none
var _settles_by: StringName  # the token the asking must rest for, or none
var _motion: Motion  # the one clock a settling wait runs on, or none
var _wait: Motion.Run = null  # the settling wait under way, or none
var _due: bool = false  # asked for, and not yet done
var _last: int = -1  # when the deed was last done, in the clock's milliseconds; never, at first


## Paced by a token of the look - paced_by, notifications' own pace
## (paced_notices.gd) or the cadence - or settling after the asking rests
## for one - settles_by, with on, the clock it waits on.
func _init(deed: Callable, options: Dictionary = {}) -> void:
	Options.checked("a throttle", options, OPTIONS)
	_deed = deed
	_paced_by = options.get(PACED_BY, &"")
	_settles_by = options.get(SETTLES_BY, &"")
	_motion = options.get(ON)


## Entering the tree switches processing on by itself for a script with
## _process: off, until a paced deed waits.
func _ready() -> void:
	set_process(false)


## Asked for: done at the end of this frame, as the pace ends, or once the
## asking has rested - once, however many times it is asked before then.
func ask() -> void:
	if _settles_by != &"":
		_rest_again()
		return
	if _due:
		return
	_due = true
	_end_of_frame.call_deferred()


## Whether an ask is waiting to be done.
func is_due() -> bool:
	return _due


## Whatever waits let go, never done: whoever asked has done it themselves.
func forget() -> void:
	_stop_waiting()
	_due = false


## The settling wait begun again from now, so each ask puts the deed further off.
func _rest_again() -> void:
	_stop_waiting()
	_due = true
	_wait = _motion.after(_settles_by, _settled)


## The wait under way, if any, stopped: it will never say it is over.
func _stop_waiting() -> void:
	if _wait != null:
		_wait.stopped = true
	_wait = null


## The asking has rested for its token: the deed done.
func _settled() -> void:
	_wait = null
	_do()


## The frame's end: done now, unless the pace says wait - then waited for, a frame at a time.
func _end_of_frame() -> void:
	if not _due or not is_inside_tree():
		return
	if _paced_by != &"" and _last >= 0 and clock.call() - _last < _cadence():
		set_process(true)
		return
	_do()


func _process(_delta: float) -> void:
	if clock.call() - _last >= _cadence():
		set_process(false)
		_do()


func _do() -> void:
	_due = false
	_last = clock.call()
	done_count += 1
	_deed.call()


func _cadence() -> int:
	return Look.wearer(self).get_theme_constant(_paced_by, Motion.TYPE)
