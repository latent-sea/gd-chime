extends RefCounted

const Going := preload("components/primitives/going.gd")
const Surface := preload("components/primitives/surface.gd")
const Canvas := preload("components/primitives/canvas.gd")
const Face := preload("face.gd")
const Sheet := preload("components/recipes/sheet.gd")
const Paragraph := preload("components/primitives/paragraph.gd")

## Whether anything the reader is meant to read or press is drawn over by
## something else, in a built tree at rest.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## NOTHING IS EVER DRAWN OVER ANYTHING ELSE. Words over words, a tray over
## a row of chips, a floating pill over the button beneath it: each is a
## broken render, so this is a property the suite asserts over every
## arrangement at every shape, beside clipped_text.gd. It walks the tree
## once and hands back one sentence for each thing covered - what, by what,
## and by how much. It holds nothing, draws nothing and mends nothing.
##
## WHAT IS JUDGED is what the reader is meant to read or press - words, a
## picture, a chart, a face, anything that takes the focus - against
## everything drawn after it that draws: those same things, and a ground
## (surface.gd, or the engine's panels and colour rects). Drawn after is
## the engine's order: by z, then as the tree is walked. Two are drawn over
## each other where the parts of them that are drawn meet by more than a
## pixel each way.
##
## What is NOT a fault:
## - One holding the other: words on their button, a button on its ground.
## - A ground under what stands on it. A ground is never judged; only what
##   is drawn over it may be.
## - What lies beneath a shade (sheet.gd): the shade is laid over
##   everything beneath it on purpose, and so is what stands on the shade.
## - What is switched off, under a pop-up that blocks it (applier.gd): it
##   takes nothing, and is not there to be read.
## - What a parent clips away or a scroll has scrolled out of view: only the
##   part drawn is judged. Words past the window are clipped_text.gd's.
## - A thing hidden, faded to nothing, or going (going.gd); and anything
##   mid-flight, since whoever asks holds the clock still and runs it out.

## One thing drawn: where, in what order, and whether it is judged or shades.
class Shown:
	var node: Control
	var rect: Rect2  # the part of it drawn, in the window
	var z: int
	var order: int  # its place as the tree is walked
	var judged: bool  # meant to be read or pressed, and not switched off
	var shade: bool


## Every sentence about something the reader should see drawn over by
## something else in this tree, and nothing when nothing is.
static func covered(root: Node, window: Rect2) -> Array[String]:
	var shown: Array[Shown] = []
	_walk(root, window, 0, false, shown)
	# the engine's order of drawing: by z, then as the tree is walked
	shown.sort_custom(func(a: Shown, b: Shown) -> bool: return a.z < b.z or (a.z == b.z and a.order < b.order))
	var shades: Array[int] = []
	# where in that order every shade is drawn
	for at: int in shown.size():
		if shown[at].shade:
			shades.append(at)
	var found: Array[String] = []
	var said: Array = []  # [what was covered, what covered it], each pair said once
	# every thing meant to be seen, against everything drawn after it
	for under_at: int in shown.size():
		var under := shown[under_at]
		if not under.judged:
			continue
		# everything drawn later, for what covers this and is not already said
		for over_at: int in range(under_at + 1, shown.size()):
			var over := shown[over_at]
			var both := under.rect.intersection(over.rect)
			if both.size.x <= 1.0 or both.size.y <= 1.0:
				continue
			if under.node.is_ancestor_of(over.node) or over.node.is_ancestor_of(under.node):
				continue
			if _shaded(shown, shades, under_at, over_at) or _said(said, under.node, over.node):
				continue
			said.append([under.node, over.node])
			found.append("%s is drawn over by %s, %d by %d pixels" % [_called(under.node), _called(over.node), roundi(both.size.x), roundi(both.size.y)])
	return found


## This node and everything under it, in the room it may be drawn in: a
## parent that clips narrows that room, a node switched off stays off for
## all it holds, and a thing hidden, faded out or going is not drawn at all.
static func _walk(node: Node, room: Rect2, z: int, off: bool, into: Array[Shown]) -> void:
	if node is SubViewport or Going.is_going(node):
		return
	var here_z := z
	if node is CanvasItem:
		var item := node as CanvasItem
		if not item.visible or item.modulate.a <= 0.0:
			return
		here_z = z + item.z_index if item.z_as_relative else item.z_index
	var inside := room
	var here_off := off
	if node is Control:
		var control := node as Control
		here_off = off or control.mouse_behavior_recursive == Control.MOUSE_BEHAVIOR_DISABLED
		var drawn := control.get_global_rect().intersection(room)
		var meant := _meant(control)
		if drawn.has_area() and control.self_modulate.a > 0.0 and (meant or _grounds(control)):
			var one := Shown.new()
			one.node = control
			one.rect = drawn
			one.z = here_z
			one.order = into.size()
			# a shade by what it was described as, whether or not the look dresses one: the press every sheet stands on, or a moment's ground, and never judged
			one.shade = (control as Surface).get_style() == Sheet.SHADE if control is Surface else control is Face and control.theme_type_variation == Sheet.SHADE
			one.judged = meant and not here_off and not one.shade
			into.append(one)
		# a control that clips draws nothing of what it holds outside its own rect
		if control.clip_contents:
			inside = drawn
	# everything this holds, in the room this leaves it
	for child: Node in node.get_children():
		_walk(child, inside, here_z, here_off, into)


## Meant to be read or pressed: words, a picture, a chart or a view, a
## face, or anything else that takes the focus - but not a scroll, which
## holds what is read.
static func _meant(control: Control) -> bool:
	if control is Label:
		return (control as Label).text.strip_edges() != ""
	if control is RichTextLabel:
		return (control as RichTextLabel).get_parsed_text().strip_edges() != ""
	if control is Paragraph:
		return (control as Paragraph).get_text().strip_edges() != ""
	if control is TextureRect:
		return (control as TextureRect).texture != null
	if control is Canvas or control is SubViewportContainer or control is Face:
		return true
	return control.focus_mode != Control.FOCUS_NONE and not (control is ScrollContainer)


## A ground something may stand on: a surface or one of the engine's
## panels with a box that draws, or a colour rect that is not clear.
static func _grounds(control: Control) -> bool:
	if control is Surface or control is Panel or control is PanelContainer:
		return not (control.get_theme_stylebox(&"panel") is StyleBoxEmpty)
	if control is ColorRect:
		return (control as ColorRect).color.a > 0.0
	return false


## Whether a shade drawn between the two lies over the one beneath: then it
## is beneath on purpose, and so is everything standing on the shade.
static func _shaded(shown: Array[Shown], shades: Array[int], under_at: int, over_at: int) -> bool:
	return shades.any(func(at: int) -> bool: return at > under_at and at <= over_at and shown[at].rect.encloses(shown[under_at].rect))


## Whether this pair, or one holding both of its sides, was said already: a
## button drawn over is said once, not again for each of its words.
static func _said(said: Array, under: Node, over: Node) -> bool:
	return said.any(func(pair: Array) -> bool: return (pair[0] == under or pair[0].is_ancestor_of(under)) and (pair[1] == over or pair[1].is_ancestor_of(over)))


## A thing as a reader would find it: its first words, where it has any,
## and where it is in the tree.
static func _called(node: Node) -> String:
	var words := _words_in(node)
	return '"%s" at %s' % [words.substr(0, 60), node.get_path()] if words != "" else String(node.get_path())


## The first words drawn in this node, or nothing.
static func _words_in(node: Node) -> String:
	if node is Label:
		return (node as Label).text.strip_edges()
	# everything it holds, in the order it is drawn, until some words are found
	for child: Node in node.get_children():
		var words := _words_in(child)
		if words != "":
			return words
	return ""
