extends Container

const Chimes := preload("../../chimes.gd")
const Motion := preload("../../motion.gd")
const Shift := preload("shift.gd")
const Property := preload("keyframe_property.gd")

## Keyframes: what it holds carried through a track of frames - opacity,
## scale, slide and turn moving together - on the one clock.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A TRACK IS DATA a recipe writes: frames, each one where it falls in the
## track - at, from 0 to 1 - the properties it sets there, and how long it
## holds there before moving on, in the same fractions. It goes by an
## easing of the look, by name, over a duration of the look, by name, that
## many passes or for ever: never seconds, so the look says how the whole
## interface moves and a recipe writes no number of its own.
##
## EVERY FRAME SAYS EVERY PROPERTY the track moves, so they arrive
## together and a pass begins them all again from the first frame. The LAST
## FRAME IS THE RESTING FRAME - where this is left the moment the track
## stops: the passes run out, what holds it lets go, it is hidden, it
## leaves the tree. A track that loops is written to rest whole.
##
## EVERY STEP DRIVES what it writes (motion.gd), under the same names the
## transitions use, so a track and an entrance never write one property
## frame about: whichever began later takes over from where the other got to.
##
## IT IS MAIN-THREAD WORK and asks for none of its own. A step the clock
## gives no time to - held still, over the frame budget, a look that moves
## nothing - rests the track there and then with nothing left running, so a
## NEW track on a struggling frame is simply the state it ends in. While
## motion is REDUCED nothing scales, slides or turns: those rest at once,
## and a track that loops rests whole - so whatever a loop was saying must
## be said by a mark or a word beside it too, never by the motion alone -
## while a fade goes on as the short fade the look makes of it. A track
## that runs for ever follows reduced motion, a value of the clock's, and moves with it
## there and then; one of a set number of passes is over soon enough.

## What a frame may set (keyframe_property.gd), by the names a track is written in.
const OPACITY := Property.OPACITY
const SCALE := Property.SCALE
const SLIDE := Property.SLIDE
const TURN := Property.TURN
## A track that runs until what holds it lets go.
const FOREVER := 0

var motion: Motion = null  # the one clock, given to this by the builder

var _track: Dictionary  # the frames, the easing and the duration by name, the Theme type that duration is under, the passes, and the staggers waited first
var _held: Variant  # a Bound whose holding is when this runs, or null for always

var _moved: Array[StringName] = []  # every property the frames say
var _driven: Array[StringName] = []  # the ones this pass is running: all of them, or the fades alone while motion is reduced
var _runs: Dictionary = {}  # property -> the run writing it now
var _frame: int = 0  # the frame the step now running is moving to
var _waiting: int = 0  # how many of the step's runs have yet to arrive, and one for the step still being set off
var _left: int = 0  # passes still to go
var _was_held: bool = false  # whether the value held when this last looked
var _chimes: Chimes  # what reduced motion is followed through
var _reduced: Variant = null  # whether motion was reduced as last followed, none before


func _init(chimes: Chimes, track: Dictionary, held: Variant, style: StringName) -> void:
	_chimes = chimes
	_track = track
	_held = held
	theme_type_variation = style
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	set_process(held != null)


## The frames of the track. A track built out of the look's own numbers - a
## pulse's depth - is worked out here, where the look is known and a change
## of look asks again.
func get_frames() -> Array:
	return _track[&"frames"]


## Whether the value this is held by holds - something rather than nothing,
## true, not zero, not empty - or there is none and it runs always.
func is_holding() -> bool:
	if _held == null:
		return true
	var value: Variant = _held.read()
	match typeof(value):
		TYPE_NIL: return false
		TYPE_BOOL: return value
		TYPE_INT, TYPE_FLOAT: return value != 0
		TYPE_STRING, TYPE_STRING_NAME, TYPE_ARRAY, TYPE_DICTIONARY: return not value.is_empty()
	return true


## In the tree, shown, or looking different: the track begins again from
## the look as it now is. Out of the tree or hidden, it rests: what cannot
## be seen must not be moving.
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE, NOTIFICATION_THEME_CHANGED, NOTIFICATION_VISIBILITY_CHANGED:
			_restart() if is_visible_in_tree() else _rest()
			if what == NOTIFICATION_ENTER_TREE:
				_chimes.follow(self, &"reduced", _reduced_moved)
		NOTIFICATION_EXIT_TREE:
			_rest()
		NOTIFICATION_PREDELETE:
			_chimes.stop_all(self)
		NOTIFICATION_SORT_CHILDREN:
			# a track wraps a piece without altering where it sits: what it holds is given all of its room, as its motion has left it
			for child: Node in get_children():
				if child is Control:
					Shift.fit(self, child, Rect2(Vector2.ZERO, size))


## Reduced motion read, so it is followed: turned on or off, a track that
## runs for ever follows it at once, resting whole or running again, without
## waiting to be shown anew.
func _reduced_moved() -> void:
	var reduced := motion.get_reduced()
	if _reduced != null and reduced != _reduced and _track[&"loops"] == FOREVER:
		_restart()
	_reduced = reduced


## The value it is held by, looked at once a frame: it starts the track and it stops it.
func _process(_delta: float) -> void:
	var holds := is_holding()
	if holds == _was_held:
		return
	_was_held = holds
	_restart() if holds else _rest()


func _get_minimum_size() -> Vector2:
	var least := Vector2.ZERO
	# as much room as any part of its content needs
	for child: Node in get_children():
		if child is Control:
			least = least.max((child as Control).get_combined_minimum_size())
	return least


## The track from its first frame: every property it moves set there, and
## the first step of the first pass set off.
func _restart() -> void:
	_was_held = is_holding()
	if not is_inside_tree() or not is_visible_in_tree() or not _was_held:
		return
	_moved = Property.EVERY.filter(func(what: StringName) -> bool: return get_frames()[0].has(what))
	_driven = _moved
	if _moved.has(SCALE) or _moved.has(TURN):
		pivot_offset_ratio = Vector2(0.5, 0.5)
	_write(0)
	# reduced, a loop is motion nobody asked for: it rests, and what it was saying is said beside it in words
	if motion.get_reduced():
		if _track[&"loops"] != 1:
			_rest()
			return
		_driven = _moved.filter(func(what: StringName) -> bool: return not Property.MOVES.has(what))
		# what would move is at its rest before anything is seen; what fades still fades
		for what: StringName in Property.MOVES:
			if _moved.has(what):
				Property.writes(self, what).call(Property.value(self, get_frames()[-1], what))
	if _driven.is_empty():
		_rest()
		return
	_left = _track[&"loops"]
	_frame = 1
	_begin_step()


## One step of the track set off: every property it drives, from the frame
## before to the frame now due, each one driven so nothing else writes it
## meanwhile - set off as far in as the last step was carried past its end,
## so no time of the clock's is lost between them.
func _begin_step(past: float = 0.0) -> void:
	var from: Dictionary = get_frames()[_frame - 1]
	var to: Dictionary = get_frames()[_frame]
	var whole: float = float(get_theme_constant(_track[&"lasts"], _track[&"timed_by"])) / 1000.0
	# the frame it is leaving holds for part of the way to the next, and the rest of that way is the move
	var held_for: float = from.get(&"hold", 0.0) * whole
	var seconds: float = (to[&"at"] - from[&"at"]) * whole - held_for
	var waited: float = held_for
	# the first step of the first pass waits its turn among the things arriving together
	if _frame == 1 and _left == _track[&"loops"]:
		waited += motion.stagger(self) * _track[&"after"]
	# one more than the runs, so none of them arriving carries the track on before the rest are set off
	_waiting = _driven.size() + 1
	for what: StringName in _driven:
		var one: Motion.Run = motion.drive(self, what, Property.value(self, from, what), Property.value(self, to, what), _track[&"easing"], Property.writes(self, what), what == OPACITY, _arrived)
		_runs[what] = one
		# a step the clock will give no time to: the track is over, and its resting frame is all of it that is seen
		if one.lasts == 0.0:
			_rest()
			return
		if not motion.get_reduced():
			one.lasts = seconds
		one.wait(waited - past)
		# set off part way in, it is drawn where it has got to now rather than a frame late
		one.step(0.0)
	_arrived()


## One of a step's runs has arrived. The step is over once every one of
## them has: then the next frame, or another pass from the first, or rest.
func _arrived() -> void:
	_waiting -= 1
	if _waiting > 0:
		return
	# the step's runs set off and arrive together, so any of them says how far past its end the clock carried it
	var past: float = _runs[_driven[0]].get_past()
	_frame += 1
	if _frame < get_frames().size():
		_begin_step(past)
		return
	_left -= 1
	if _track[&"loops"] != FOREVER and _left <= 0:
		_rest()
		return
	_frame = 1
	_begin_step(past)


## Stopped exactly on the resting frame - the last - with nothing of it left running.
func _rest() -> void:
	_waiting = 0
	_frame = 0
	for one: Motion.Run in _runs.values():
		one.stopped = true
	_runs.clear()
	_write(-1)


## Every property the track moves set to what this frame of it says.
func _write(frame: int) -> void:
	# every property the track moves, at this frame
	for what: StringName in _moved:
		Property.writes(self, what).call(Property.value(self, get_frames()[frame], what))


static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"keyframes").new(ui.chimes, desc.props["track"], desc.props["held"], desc.props["style"])
	ui.attach(made, parent, desc.facts)
	return made
