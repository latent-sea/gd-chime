extends RefCounted

const Going := preload("components/primitives/going.gd")
const Surface := preload("components/primitives/surface.gd")
const Paragraph := preload("components/primitives/paragraph.gd")

## Whether any words in a built tree are too faint to read: their ink
## against the ground they stand on, in a look.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## WORDS THAT DO NOT STAND OUT FROM THEIR GROUND ARE A BROKEN RENDER, as
## surely as words cut off (clipped_text.gd) or drawn over (drawn_over.gd),
## and nothing else in the suite sees it: a look inks a kind of words for
## the ground it expected, another look or a later recipe puts them on a
## different ground, and every probe still passes while nobody can read
## them. That is how the form's status line came to be a pale tan on pale
## tan for a whole round. So this is a property the suite asserts, in every
## look. It walks the tree once and hands back one sentence for each set of
## words too faint - which words, the kind of words they are, the ink, the
## piece whose ground they stand on and its colour, the ratio they make and
## the least they owed. The kind and the ground's piece are the pair a look
## has to mend, so a finding can be acted on without opening the window. It
## holds nothing, draws nothing and mends nothing.
##
## THE RATIO IS WCAG 2.1's, § 1.4.3: each colour's relative luminance, the
## lighter plus 0.05 over the darker plus 0.05. The least is AA's - 4.5 to
## 1, and 3 to 1 for LARGE words, which a reader reads at a glance. Ink and
## ground are compared as drawn: an ink given part of an alpha is laid over
## its ground first, and so is every ground over the one behind it.
##
## THE GROUND IS THE NEAREST ONE THAT DRAWS, and what is behind that: the
## box a face is drawn in for the state it is in (face.gd), a surface
## (surface.gd) or one of the engine's panels whose box fills, a field's
## resting box, a colour rect - each laid over the next out to the window's
## own colour. Words on a press stand on the press, not on the pane. A
## box drawn only by painters (painted_box.gd) - a bevel, a rule, a hatch -
## fills nothing and lays no ground, so the ground behind it is what the
## words are read against, which is what the eye sees through it too.
##
## What is NOT a fault:
## - Words on something switched off or inert: a press that cannot be
##   pressed is drawn faint ON PURPOSE, which is how a reader sees it is
##   not for them, and WCAG exempts it for the same reason.
## - A thing hidden, faded to nothing, or going (going.gd), and anything
##   mid-flight: whoever asks holds the clock still and runs it out first
##   (motion.gd), so the ink judged is the ink at rest, not one part way
##   from a kind of words to another.
## - Words with nothing to read: none, or spaces.
##
## Deliberately absent: the words a canvas draws itself - a chart's numbers
## along its axes - which are drawn by the same look's ink on the same
## look's ground, and are not a Control to walk to.

## The least a ratio may be, and the least for large words, WCAG 2.1 AA's.
const LEAST := 4.5
const LEAST_LARGE := 3.0
## From how many base pixels words count as large.
const LARGE := 24


## Every sentence about words too faint against their ground in this tree,
## and nothing when none are.
static func faint(root: Node) -> Array[String]:
	var found: Array[String] = []
	_look(root, [RenderingServer.get_default_clear_color(), &"the window"], false, found)
	return found


## This node and everything under it, against the ground it stands on -
## [the colour, the name of the piece that laid it]: a ground that draws
## becomes the ground for what it holds, something switched off or inert
## stays so for all it holds, and a thing hidden, faded out or going is not
## drawn at all.
static func _look(node: Node, ground: Array, off: bool, found: Array[String]) -> void:
	if node is SubViewport or Going.is_going(node):
		return
	if node is CanvasItem and (not (node as CanvasItem).visible or (node as CanvasItem).modulate.a <= 0.0):
		return
	var under := ground
	var here_off := off
	if node is Control:
		var control := node as Control
		here_off = off or control.mouse_behavior_recursive == Control.MOUSE_BEHAVIOR_DISABLED or (control.has_method(&"get_state") and control.get_state() == &"inert")
		var fill := _fill_under(control)
		if fill.a > 0.0:
			under = [(ground[0] as Color).blend(fill), _kind_of(control)]
		if not here_off and _words_of(control) != "":
			_judge(control, ground, found)
	# everything this holds, on the ground this leaves it
	for child: Node in node.get_children():
		_look(child, under, here_off, found)


## One set of words against its ground: the ink as it is drawn, laid over
## that ground where it is part clear, and the ratio the two make - said
## with the kind of words and the piece whose ground they stand on, which
## between them are the pair a look has to mend.
static func _judge(control: Control, ground: Array, found: Array[String]) -> void:
	var on: Color = ground[0]
	var ink := on.blend(control.get_theme_color(&"font_color"))
	var least: float = LEAST_LARGE if control.get_theme_font_size(&"font_size") >= LARGE else LEAST
	var ratio := contrast(ink, on)
	if ratio < least:
		found.append('"%s" (%s) is drawn in %s on %s\'s %s, %.1f to 1, under the %.1f to 1 it owes, at %s' % [_words_of(control).substr(0, 60), _kind_of(control), ink.to_html(false), ground[1], on.to_html(false), ratio, least, control.get_path()])


## What a look calls this piece: the kind it is dressed as, or what it is
## where a look dresses it by no name of its own.
static func _kind_of(control: Control) -> StringName:
	return control.theme_type_variation if control.theme_type_variation != &"" else StringName(control.get_class())


## The ratio between two colours, WCAG 2.1 § 1.4.3: the lighter plus 0.05
## over the darker plus 0.05, so 1 is the same colour twice and 21 is black
## on white.
static func contrast(ink: Color, ground: Color) -> float:
	var lit := luminance(ink)
	var dark := luminance(ground)
	if dark > lit:
		var swap := lit
		lit = dark
		dark = swap
	return (lit + 0.05) / (dark + 0.05)


## A colour's relative luminance, WCAG 2.1's: each channel taken off the
## sRGB curve, then weighted as the eye weighs red, green and blue.
static func luminance(colour: Color) -> float:
	var channels := [colour.r, colour.g, colour.b]
	var linear: Array[float] = []
	# every channel, off the sRGB transfer curve and onto light
	for channel: float in channels:
		linear.append(channel / 12.92 if channel <= 0.04045 else pow((channel + 0.055) / 1.055, 2.4))
	return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]


## What this control fills under whatever stands on it, and nothing where
## it draws no ground: the boxes a face is drawn in, the state it is in
## first (face.gd), a surface's or a panel's box, a field's resting box, or
## a colour rect.
static func _fill_under(control: Control) -> Color:
	if control.has_method(&"get_drawn"):
		var fill := Color.TRANSPARENT
		# every box drawn over the whole of it, in the order they are drawn
		for box: StyleBox in control.get_drawn():
			fill = fill.blend(fill_of(box))
		return fill
	if control is Surface or control is Panel or control is PanelContainer:
		return fill_of(control.get_theme_stylebox(&"panel"))
	if control is LineEdit or control is TextEdit:
		return fill_of(control.get_theme_stylebox(&"normal"))
	if control is ColorRect:
		return (control as ColorRect).color
	return Color.TRANSPARENT


## The colour a box fills with: a flat box's own where it draws its centre,
## a layered box's layers laid one over another (painted_box.gd), and
## nothing for any other - a texture and a painter alike leave the ground
## behind them showing.
static func fill_of(box: StyleBox) -> Color:
	if box is StyleBoxFlat:
		# a box told not to draw its centre draws its border and its shadow alone, whatever fill it carries: a link's, which is a rule under words and no ground (theme_navigation.gd)
		return (box as StyleBoxFlat).bg_color if (box as StyleBoxFlat).draw_center else Color.TRANSPARENT
	if box.has_method(&"get_fill"):
		return box.get_fill()
	return Color.TRANSPARENT


## The words this control draws, and none where it draws none.
static func _words_of(control: Control) -> String:
	if control is Label:
		return (control as Label).text.strip_edges()
	if control is Paragraph:
		return (control as Paragraph).get_text().strip_edges()
	return ""
