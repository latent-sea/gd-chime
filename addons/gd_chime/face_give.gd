extends RefCounted

const Motion := preload("motion.gd")

## How a face gives under a hand held on it: drawn a little smaller while a
## pointer's button or a finger is down on it, and sprung back as it lifts,
## so a touch is seen to land where a phone has no hover to show it.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE LOOK SAYS HOW FAR: its press scale under Motion, in thousandths of
## the face's size - a thousand, the floor's, gives nothing at all. It goes
## in by the restyle easing and comes back by the emphasis, which may
## overshoot, on the one clock, scaled about its middle; it is drawn smaller,
## never laid out smaller, so nothing beside it moves.
##
## IT IS A MOVE, so reduced motion gives nothing at all - though a face held
## as it was turned on still comes back, at once - and over the frame budget
## it snaps like any other (motion.gd). It drives the face's scale, the
## one run writing it, so a press landing on a face still scaling in turns
## that entrance round from where it had got to (transition.gd).
##
## It holds nothing and draws nothing: it is face.gd's alone, and a face
## built by hand, with no clock, gives nothing.

## The look's token: how small a face held down is drawn, in thousandths.
const TOKEN := &"press_scale"
## What it drives of the face: its scale, as an entrance's scale does.
const WHAT := &"scale"


## A hand down on this face, or lifted: its scale on its way to the look's
## press scale, or back to its whole size.
static func held(face: Control, motion: Motion, down: bool) -> void:
	if motion == null or (down and motion.get_reduced()):
		return
	var to := Vector2.ONE * face.get_theme_constant(TOKEN, Motion.TYPE) / 1000.0 if down else Vector2.ONE
	if to == face.scale:
		return
	face.pivot_offset_ratio = Vector2(0.5, 0.5)
	motion.drive(face, WHAT, face.scale, to, Motion.RESTYLE if down else Motion.EMPHASIS, face.set_scale)
