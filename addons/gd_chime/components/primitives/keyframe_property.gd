extends RefCounted

const Motion := preload("../../motion.gd")
const Shift := preload("shift.gd")

## What a keyframe may set - opacity, scale, slide and turn - and, for each,
## the value the engine takes for what a frame says, and what writes it.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## It holds nothing and runs nothing: a track (keyframes.gd) asks it, frame
## by frame, and drives what it answers on the one clock. A frame says a
## number or names a token of the look; a name is read where the look is,
## on the node that moves, so a part under a look of its own moves by it.
## WHAT WRITES A PROPERTY IS A METHOD OF THE NODE IT MOVES, never a function
## closed over it, so a run of a freed node is known to be gone (motion.gd).

const OPACITY := &"opacity"
const SCALE := &"scale"
const SLIDE := &"slide"
const TURN := &"turn"
## Every one, in the order a step writes them.
const EVERY: Array[StringName] = [OPACITY, SCALE, SLIDE, TURN]
## What moves a thing rather than fading it, and so does not run at all while motion is reduced.
const MOVES: Array[StringName] = [SCALE, SLIDE, TURN]


## What writes this property of this node.
static func writes(node: Control, what: StringName) -> Callable:
	match what:
		OPACITY: return node.set_modulate
		SCALE: return node.set_scale
		SLIDE: return Shift.of(node).slide
	return node.set_rotation_degrees


## What a frame says this property is, as the engine takes it: an opacity is
## the whole colour, a scale is both ways at once, a turn is in degrees.
static func value(node: Control, frame: Dictionary, what: StringName) -> Variant:
	if what == SLIDE:
		return frame[SLIDE]
	# a number is itself; a name is the look's: a Motion token, in thousandths, read from the node's look
	var said: float = node.get_theme_constant(frame[what], Motion.TYPE) / 1000.0 if frame[what] is StringName else float(frame[what])
	match what:
		SCALE: return Vector2.ONE * said
		TURN: return said
	# an opacity is the whole colour a modulate takes: white, carrying the alpha alone
	var shade := Color.WHITE
	shade.a = said
	return shade
