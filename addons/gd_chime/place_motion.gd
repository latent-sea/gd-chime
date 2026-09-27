extends RefCounted

const Motion := preload("motion.gd")
const Shift := preload("components/primitives/shift.gd")
const Transition := preload("components/primitives/transition.gd")

## How places are seen to come and go: what the applier does with motion
## where it would otherwise switch a place on and another off.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## IT ANIMATES WHAT THE CHART ALREADY SAID and decides nothing: it is handed
## the places that are arriving and the ones leaving, already worked out
## from the state, and which way the move went.
##
## TWO SCREENS ARE NEVER BOTH READABLE IN ONE ROOM. Where one place takes
## another's room - a screen for a screen, a tab for a tab - the move is a
## PUSH: the arriving one slides in from a side as the leaving one slides
## out of the other, both by the look's move easing over the same time, so
## their edges touch the whole way and neither is ever over the other. The
## room they share clips them WHILE THEY ARE ON THE MOVE, so neither is
## drawn over what stands beside it, and is given back as it was when they
## settle - the applier's to do, since it is told when (applier.gd): a room
## left clipping for good would cut off every focus ring, shadow, glow and
## bubble that ever reached past its edge. The
## side says which way the reader went: Back comes from the left and a
## forward move from the right, mirrored; between two places side by side
## under one holder - tabs - it is the way they lie. Turned round mid-way,
## each goes back from where it had got to (motion.gd drives), still edge to
## edge. A place arriving into room nothing is leaving, or leaving room
## nothing takes, fades.
##
## A ROOT over the rest is meant to be over it: a pop-up enters by the
## look's transition for a pop-up - a fade, shade and all - and the panel by
## the look's for the panel, a slide from its side. WHAT STANDS IN A PLACE
## MAY ARRIVE ITS OWN WAY each time the place is shown - a description says
## `.arrives(kind)` - which is how a pop-up's sheet scales in while the
## shade behind it only fades: scaling the whole pop-up would pull the
## shade's edges in off the screen's.
##
## Only the OUTERMOST place of what changed is moved: the places inside it
## go with it. INPUT NEVER WAITS: a leaving place is out of reach from the
## first frame, and the arriving one is live at once - the applier's own
## switches say so, and this only draws.
##
## Reduced motion, the frame budget and a look with no motion are the
## clock's: a push snaps, a fade is short or at once.

const FROM_THE_RIGHT := Vector2.RIGHT
const FROM_THE_LEFT := Vector2.LEFT


## Of these places, the ones no other of them holds.
static func outermost(changed: Array) -> Array:
	return changed.filter(func(place: Node) -> bool: return not changed.any(func(other: Node) -> bool: return other.is_ancestor_of(place)))


## The side an arriving place comes from: Back from the left; two that lie
## side by side, the way they lie; any other forward move, from the right.
static func side(arriving: Node, leaving: Node, back: bool) -> Vector2:
	if back:
		return FROM_THE_LEFT
	if arriving.get_parent() == leaving.get_parent():
		return FROM_THE_RIGHT if arriving.get_index() > leaving.get_index() else FROM_THE_LEFT
	return FROM_THE_RIGHT


## The two places of a push, [the one coming, the one going], when exactly
## one place that is no root takes the room of exactly one other; else nothing.
static func push_of(arriving: Array, leaving: Array, roots: Dictionary) -> Array:
	var coming: Array = outermost(arriving).filter(func(place: Node) -> bool: return not roots.has(place.name))
	var going: Array = outermost(leaving).filter(func(place: Node) -> bool: return not roots.has(place.name))
	return [coming[0], going[0]] if coming.size() == 1 and going.size() == 1 else []


## The places arriving shown and the ones leaving seen out, settled(place)
## called with each leaving one as it has gone - pushed(place) instead, with
## the one a push pushed out, as the push comes to rest. roots is the chart's own: the name of every
## place that stands over the rest -> its kind, which is also the name the
## look gives that kind's transition.
static func change(arriving: Array, leaving: Array, roots: Dictionary, back: bool, motion: Motion, settled: Callable, pushed: Callable) -> void:
	var push := push_of(arriving, leaving, roots)
	if not push.is_empty():
		var from: Vector2 = side(push[0], push[1], back)
		_slide(push[0], from, Vector2.ZERO, motion, Callable())
		_slide(push[1], Vector2.ZERO, -from, motion, _rested.bind(push[1], pushed.bind(push[1])))
	# what is not part of a push: every place that is no root, arriving into room nothing leaves or leaving room nothing takes
	var coming: Array = outermost(arriving).filter(func(place: Node) -> bool: return not roots.has(place.name) and not push.has(place))
	var going: Array = outermost(leaving).filter(func(place: Node) -> bool: return not roots.has(place.name) and not push.has(place))
	# every root arriving, by the look's transition for its kind; every other place with no room to take, faded in
	for place: Control in outermost(arriving):
		if roots.has(place.name):
			Transition.enter(place, Transition.named(&"", roots[place.name], place), motion)
		elif coming.has(place):
			Transition.enter(place, Transition.FADE, motion)
	# everything inside an arriving place that was described as arriving its own way, while it still stands
	for place: Node in arriving:
		place.arriving = place.arriving.filter(func(one: Array) -> bool: return is_instance_valid(one[0]))
		for one: Array in place.arriving:
			Transition.enter(one[0], one[1], motion)
	# every root leaving, and every place leaving room nothing takes, seen out and then settled
	for place: Control in outermost(leaving):
		if roots.has(place.name) or going.has(place):
			_see_out(place, Transition.named(&"", roots[place.name], place) if roots.has(place.name) else Transition.FADE, motion, settled.bind(place))


static func _slide(place: Control, from: Vector2, to: Vector2, motion: Motion, done: Callable) -> void:
	var shift: Shift = Shift.of(place)
	var run := motion.drive(place, Transition.WHAT_SLIDE, from, to, Motion.MOVE, shift.slide, false, done)
	# drawn where it sets off from before a frame is seen: at rest it would be over the place it is pushing out - unless it has arrived already, reduced, and been put where it rests
	if not run.is_over():
		shift.slide(run.value)


## A place seen out - pushed, faded, scaled away - come to rest where it
## went: put back as it rests, where it belongs, whole and full size, before
## it is settled hidden, in the same call, so no frame shows it so. Shown
## again by any move - inside a place arriving around it, which is what is
## moved then, or pushed where it was faded - it is not a room's width away,
## nor clear.
static func _rested(place: Control, then: Callable) -> void:
	Shift.of(place).slide(Vector2.ZERO)
	place.modulate = Color.WHITE
	place.scale = Vector2.ONE
	then.call()


## A place seen out by this transition's way of going, and not freed: it is a place, and will be back.
static func _see_out(place: Control, kind: StringName, motion: Motion, done: Callable) -> void:
	if Transition.SIDES.has(kind):
		_slide(place, Vector2.ZERO, Transition.SIDES[kind], motion, Callable())
	if kind == Transition.SCALE:
		motion.drive(place, Transition.WHAT_SCALE, place.scale, Transition.SMALL, Motion.EXIT, place.set_scale)
	motion.drive(place, Transition.WHAT_OPACITY, place.modulate, Transition.CLEAR, Motion.EXIT, place.set_modulate, true, _rested.bind(place, done))
