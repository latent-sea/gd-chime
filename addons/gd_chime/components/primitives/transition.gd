extends RefCounted

const Motion := preload("../../motion.gd")
const Shift := preload("shift.gd")
const Going := preload("going.gd")

## The transitions: how a thing arrives, and how it goes.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A transition is a name - NONE, FADE, SCALE, GROW, or a slide FROM a side
## - asked for where a thing is described, or left to the look, which names
## one for each thing that swaps (the Theme type Motion: `when`, `each`,
## and the rest, written by defaults()). Arriving runs by the look's enter
## easing and going by its exit, on the one clock, so every one of them
## answers to reduced motion and the frame budget without knowing of
## either: a slide, a scale and a growing are MOVES, and snap; the fade
## that goes with them is a FADE, and is what is left - a short cross-fade.
##
## GOING, a thing stays until its exit has run and is then freed - and it
## never leaves the tree to be kept (going.gd): it is marked, which takes
## it out of its holder's layout, out of reach, and tells every place
## beneath it to give up its name and its stay there and then.
##
## EVERY RUN HERE DRIVES what it writes (motion.gd): this node's opacity,
## its scale, its slide. So a thing sent out while it is still arriving, or
## asked for again mid-way, turns round from where it has got to, and no
## two runs ever write the same thing frame about.

const WHAT_OPACITY := &"opacity"
const WHAT_SCALE := &"scale"
const WHAT_SLIDE := &"slide"

const NONE := &"none"
const FADE := &"fade"
const SCALE := &"scale"
const GROW := &"grow"
const FROM_LEFT := &"from_left"
const FROM_RIGHT := &"from_right"
const FROM_TOP := &"from_top"
const FROM_BOTTOM := &"from_bottom"
const KINDS: Array[StringName] = [NONE, FADE, SCALE, GROW, FROM_LEFT, FROM_RIGHT, FROM_TOP, FROM_BOTTOM]
const SIDES := {FROM_LEFT: Vector2.LEFT, FROM_RIGHT: Vector2.RIGHT, FROM_TOP: Vector2.UP, FROM_BOTTOM: Vector2.DOWN}
## The slide that mirrors each: what came from the left goes back to it when the way is reversed.
const MIRRORED := {FROM_LEFT: FROM_RIGHT, FROM_RIGHT: FROM_LEFT, FROM_TOP: FROM_BOTTOM, FROM_BOTTOM: FROM_TOP}
## How small a scaled thing starts, and where it and a growing one are pinned.
const SMALL := Vector2(0.85, 0.85)
const FLAT := Vector2(1.0, 0.0)
const CLEAR := Color.TRANSPARENT


## The transition the look names for this kind of thing; what was asked for where it was described wins.
static func named(asked: StringName, what: StringName, under: Control) -> StringName:
	return asked if asked != &"" else KINDS[under.get_theme_constant(what, Motion.TYPE)]


## A look's transitions written into its Theme: what swaps -> the transition's name.
static func defaults(theme: Theme, by_what: Dictionary) -> void:
	for what: StringName in by_what:
		theme.set_constant(what, Motion.TYPE, KINDS.find(by_what[what]))


## This thing arriving, after a wait if it is one of several entering together.
static func enter(node: Control, kind: StringName, motion: Motion, wait: float = 0.0) -> void:
	if kind == NONE:
		return
	node.modulate = CLEAR
	motion.drive(node, WHAT_OPACITY, CLEAR, Color.WHITE, Motion.ENTER, node.set_modulate, true).wait(wait)
	if kind == SCALE or kind == GROW:
		node.pivot_offset_ratio = Vector2(0.5, 0.5) if kind == SCALE else Vector2(0.5, 0.0)
		node.scale = SMALL if kind == SCALE else FLAT
		motion.drive(node, WHAT_SCALE, node.scale, Vector2.ONE, Motion.ENTER, node.set_scale).wait(wait)
	if SIDES.has(kind):
		var shift: Shift = Shift.of(node)
		shift.slide(SIDES[kind])
		motion.drive(node, WHAT_SLIDE, SIDES[kind], Vector2.ZERO, Motion.ENTER, shift.slide).wait(wait)


## This thing going: marked as going (going.gd) at once, freed when its
## exit has run - from wherever an entrance had got it to. Going with no
## exit, it is freed at the end of the frame, not at once: it may be the very
## thing whose press sent it away - a menu's item, lowering its menu - and a
## node cannot be freed from inside its own call.
static func exit(node: Control, kind: StringName, motion: Motion) -> void:
	if kind == NONE:
		Going.mark(node)
		node.queue_free()
		return
	Going.mark(node)
	if kind == SCALE or kind == GROW:
		node.pivot_offset_ratio = Vector2(0.5, 0.5) if kind == SCALE else Vector2(0.5, 0.0)
		motion.drive(node, WHAT_SCALE, node.scale, SMALL if kind == SCALE else FLAT, Motion.EXIT, node.set_scale)
	if SIDES.has(kind):
		motion.drive(node, WHAT_SLIDE, Vector2.ZERO, SIDES[kind], Motion.EXIT, Shift.of(node).slide)
	# the fade is the one that frees it: the last to arrive, or the only one left when reduced
	motion.drive(node, WHAT_OPACITY, node.modulate, CLEAR, Motion.EXIT, node.set_modulate, true, node.queue_free)
