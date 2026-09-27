extends RefCounted

## The floor's primitives by kind: the table the builder (ui.gd) fills its
## register from as it is made, each kind a script whose static build(ui,
## desc, parent) makes the node.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A table and nothing else, kept apart from the builder so the floor can
## grow a primitive without the builder growing: a kind added here is
## described in one of the describe files and built by its own script. A
## game's own kinds are never here - ui.register adds them.

const KINDS := {
	&"text": preload("text.gd"),
	&"reason": preload("text.gd"),
	&"image": preload("image.gd"),
	&"surface": preload("surface.gd"),
	&"paragraph": preload("paragraph.gd"),
	&"pressable": preload("pressable.gd"),
	&"press_local": preload("press_local.gd"),
	&"draggable": preload("draggable.gd"),
	&"drop_target": preload("drop_target.gd"),
	&"field": preload("field.gd"),
	&"area": preload("area.gd"),
	&"row": preload("layout.gd"),
	&"column": preload("layout.gd"),
	&"grid": preload("grid_layout.gd"),
	&"stack": preload("stack.gd"),
	&"scroll": preload("scroll.gd"),
	&"virtual_list": preload("virtual_list.gd"),
	&"cells": preload("cells.gd"),
	&"view": preload("view.gd"),
	# the two ways out of the described world (describe_escapes.gd)
	&"themed": preload("themed.gd"),
	&"embed": preload("embed.gd"),
	&"canvas": preload("canvas.gd"),
	&"anchored": preload("anchored.gd"),
	&"each": preload("each.gd"),
	&"when": preload("when.gd"),
	&"by_shape": preload("by_shape.gd"),
	&"by_width": preload("by_width.gd"),
	&"pulse": preload("pulse.gd"),
	&"keyframes": preload("keyframes.gd"),
	&"pan_zoom": preload("pan_zoom.gd"),
	&"pinned": preload("pinned.gd"),
	&"areas": preload("areas.gd"),
	&"key_capture": preload("key_capture.gd"),
	&"slider": preload("slider.gd"),
	&"swipe": preload("swipe.gd"),
	&"pull": preload("pull.gd"),
	&"tray_stand": preload("tray_stand.gd"),
	&"lazy_image": preload("lazy_image.gd"),
	&"nearing": preload("nearing.gd"),
	&"range_slider": preload("range_slider.gd"),
	# a form's pieces (describe_forms.gd)
	&"arrival_focus": preload("arrival_focus.gd"),
	&"file_pick": preload("file_pick.gd"),
	# the shell's pieces (describe_shell.gd)
	&"split": preload("split.gd"),
	&"grip": preload("grip.gd"),
	&"menu_target": preload("menu_target.gd"),
	&"anchored_at": preload("anchored_at.gd"),
	&"app": preload("place_builder.gd"),
	&"screen": preload("place_builder.gd"),
	&"tabs": preload("place_builder.gd"),
	&"pop_up": preload("place_builder.gd"),
}
