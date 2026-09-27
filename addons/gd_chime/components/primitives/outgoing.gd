extends Control

const Motion := preload("../../motion.gd")

## The look going out: the box a thing was drawn in, laid over the box it
## is drawn in now and faded away, so a change of style blends and never
## switches.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A box is any StyleBox - flat, layered, painted - so two of them cannot
## be mixed part by part; what can always be done is to draw the old one
## over the new and let it go. It is a node of its own because only a node
## has an opacity. ONE PER CHANGE, each fading by itself, a later one laid
## UNDER the earlier: a change that comes mid-fade leaves what is showing
## exactly as it was - the older box still going, over the newer one now
## going too, over the newest - so an interrupted blend never jumps.
##
## It is an INTERNAL child, ahead of its host's content: a layout that
## fits the host's children never sees it, and neither does anything that
## walks them. It takes no press. It frees itself as it arrives. A fade is
## a fade to the clock: reduced, it is the short straight one; over budget
## or with no motion in the look, it is gone at once.

var _box: StyleBox


## The box this host was drawn in until now, left fading over it.
static func leave(host: Control, box: StyleBox, motion: Motion) -> void:
	var layer := new()
	layer._box = box
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(layer, false, Node.INTERNAL_MODE_FRONT)
	host.move_child(layer, 0)
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	motion.run(1.0, 0.0, Motion.RESTYLE, layer.fade, true, layer.queue_free)


func fade(opacity: float) -> void:
	modulate.a = opacity


func _draw() -> void:
	draw_style_box(_box, Rect2(Vector2.ZERO, size))
