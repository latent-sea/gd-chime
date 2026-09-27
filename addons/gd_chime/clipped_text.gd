extends RefCounted

const Going := preload("components/primitives/going.gd")
const Paragraph := preload("components/primitives/paragraph.gd")

## Whether any words in a built tree are cut off: drawn past the window, or
## past a parent that clips them, or set to cut themselves short.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## TEXT CUT OFF AT AN EDGE IS A BROKEN RENDER, so this is a property the
## suite asserts over every arrangement, not a thing anybody is asked to
## notice. It walks the tree once and hands back one sentence for each set
## of words it found cut - which words, where they are, by how much, and
## what cut them. It holds nothing, draws nothing and mends nothing.
##
## A LABEL'S BOX IS NEVER SMALLER THAN ITS WORDS. Measured on 4.6.2: a
## Control holds its own size to at least what it needs whatever it is
## asked, a Container fitting a part does the same, and a label that wraps
## needs the height of every line it wraps into at the width it has. So
## words are never cut inside their own box; they are cut when the box is
## put where the window or a clipping parent does not reach. That is how a
## row whose parts cannot all fit loses its last part's words: every part is
## held to the least it needs (flex_line.gd), the line overflows rather than
## a part becoming unreadable, and what hangs past the end is off the screen.
## So the box is the rect judged, and the one question is where it is.
##
## What is NOT a fault:
## - Words cut by the edge of a scroll that can still move that way, which
##   brings them in: a half row at the foot of a list that goes on is how
##   the reader sees there is more below. Words wholly out of view there
##   are the same. Words cut where the scroll cannot move further - past
##   its end, or across when it moves only down - are a fault wherever it is.
##   A scroll inside a scroll spares its own movable edges and keeps the
##   outer one's: words cut where the outer view ends are brought in by
##   moving the outer, whatever the inner can do.
## - Words wholly out of sight in a strip - a scroll across alone. A strip
##   shows whole things only (strip.gd), so words PART cut at its edge are a
##   fault, as was ruled (2026-09-19): "A flap cut in half ('cra') is
##   clipped text, whether or not the strip scrolls" - a word lost from a
##   short row of names, where a list's half row is only more to come.
##   So too inside a scroll the strip holds - a board's lane scrolled away.
## - Words in a view's own viewport, whose coordinates are its own.
## - A thing hidden, or going (going.gd): it is on its way out, drawn where
##   it stood, and nothing is laid out for it.
## - Anything mid-flight. Whoever asks holds the clock still and runs it
##   out first (motion.gd), so every part is at rest and this judges where
##   things ARE, not where they are passing through.
##
## Eliding words is not this framework's habit: no label clips its text,
## trims it to an ellipsis or caps its lines, and one that did would be
## shortening the words instead of making room for them. So that is said too.

## Every sentence about words cut off in this tree, and nothing when none are.
static func clipped(root: Node, window: Rect2) -> Array[String]:
	var found: Array[String] = []
	_look(root, window, "the window", false, {}, found)
	return found


## This node and everything under it, against the room its words may be
## drawn in: a parent that clips narrows that room and gives it its name; a
## strip spares words wholly out of sight; a scroll spares words cut by an
## edge it can still move toward - spared is that edge, by side, while the
## room still ends there; and a thing hidden or going is not drawn at all.
static func _look(node: Node, room: Rect2, named: String, out_of_sight: bool, spared: Dictionary, found: Array[String]) -> void:
	if node is CanvasItem and not (node as CanvasItem).visible:
		return
	if Going.is_going(node):
		return
	if node is Label:
		_judge(node as Label, room, named, out_of_sight, spared, found)
	if node is Paragraph:
		_judge_lines(node as Paragraph, room, named, out_of_sight, spared, found)
	var inside := room
	var inside_named := named
	# a control that clips draws nothing of its children outside its own rect; a strip shows only its whole things
	if node is Control and (node as Control).clip_contents:
		inside = room.intersection(node.get_shown() if node.has_method(&"get_shown") else (node as Control).get_global_rect())
		inside_named = String(node.get_path())
	var hidden := out_of_sight
	var sparing := spared
	# a view's viewport has coordinates of its own: no room judged, so nothing in it is in sight to be cut
	if node is SubViewportContainer:
		inside = Rect2()
		hidden = true
	# a strip spares only what is wholly out of sight, and so does a scroll a strip holds; any other scroll, whatever it or a scroll around it can still be moved to bring in
	if node is ScrollContainer:
		var strip := (node as ScrollContainer).vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED
		hidden = out_of_sight or strip
		sparing = {} if strip else spared.merged(_movable(node as ScrollContainer, inside), true)
	# everything this holds, in the room this leaves it
	for child: Node in node.get_children():
		_look(child, inside, inside_named, hidden, sparing, found)


## The edges of what a scroll shows that it can still be moved toward -
## by side, where that edge stands - so what they cut, it brings in.
static func _movable(scroll: ScrollContainer, shows: Rect2) -> Dictionary:
	var edges: Dictionary = {}
	var across := scroll.get_h_scroll_bar()
	var down := scroll.get_v_scroll_bar()
	# every side, with whether the bar that moves toward it has room left to go - none, for a way it does not move, since what it holds is then as wide as it
	for side: Array in [[SIDE_LEFT, across.value > 0.5, shows.position.x], [SIDE_TOP, down.value > 0.5, shows.position.y], [SIDE_RIGHT, across.value < across.max_value - across.page - 0.5, shows.end.x], [SIDE_BOTTOM, down.value < down.max_value - down.page - 0.5, shows.end.y]]:
		if side[1]:
			edges[side[0]] = side[2]
	return edges


## One label's words: set to be cut short, or drawn where the room it is in
## does not reach - named by the side they reach furthest past.
static func _judge(label: Label, room: Rect2, named: String, out_of_sight: bool, spared: Dictionary, found: Array[String]) -> void:
	if label.text.strip_edges() == "":
		return
	var words := label.text.substr(0, 60)
	if label.clip_text or label.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING or label.max_lines_visible >= 0:
		found.append('"%s" is set to be cut short rather than given room, at %s' % [words, label.get_path()])
	var past := _past(label.get_global_rect(), room, out_of_sight, spared)
	if past[1] > 0.5:
		found.append('"%s" is drawn %d pixels past the %s of %s, at %s' % [words, roundi(past[1]), ["left", "top", "right", "bottom"][past[0]], named, label.get_path()])


## Where words drawn in this box reach furthest past the room, as [side,
## pixels] - nothing past, where they lie wholly out of sight in a strip or
## are cut only by an edge a scroll can still move toward, which brings them in.
static func _past(box: Rect2, room: Rect2, out_of_sight: bool, spared: Dictionary) -> Array:
	# in a strip, words with no part in the room judged are scrolled away; words partly in it are cut
	if out_of_sight and not box.intersects(room):
		return [0, 0.0]
	var over: Array[float] = [room.position.x - box.position.x, room.position.y - box.position.y, box.end.x - room.end.x, box.end.y - room.end.y]
	var edges: Array[float] = [room.position.x, room.position.y, room.end.x, room.end.y]
	# every side a scroll can still move toward, while the room ends where that scroll's view does: what it cuts there it brings in
	for side: int in spared:
		if is_equal_approx(edges[side], spared[side]):
			over[side] = 0.0
	var worst := 0
	# the side the words reach furthest past, which is the one worth naming
	for side: int in 4:
		if over[side] > over[worst]:
			worst = side
	return [worst, over[worst]]


## A paragraph's words (paragraph.gd), measured by the lines it laid rather
## than by a label's measure: a line past the box it was given means it
## needed more room than it has, and a line where the room does not reach
## is cut - a link on it with it, since a link lies inside its line.
static func _judge_lines(paragraph: Paragraph, room: Rect2, named: String, out_of_sight: bool, spared: Dictionary, found: Array[String]) -> void:
	var box := paragraph.get_global_rect()
	var words := paragraph.get_text().substr(0, 60)
	# every laid line where it is drawn, for the first that reaches past the box, then past the room
	for line: Rect2 in paragraph.get_lines():
		var drawn := Rect2(box.position + line.position, line.size)
		if not box.grow(0.5).encloses(drawn):
			found.append('"%s" needs more room than its box gives: its lines reach %s, past %s, at %s' % [words, drawn, box, paragraph.get_path()])
			return
		var past := _past(drawn, room, out_of_sight, spared)
		if past[1] > 0.5:
			found.append('"%s" has a line drawn %d pixels past the %s of %s, at %s' % [words, roundi(past[1]), ["left", "top", "right", "bottom"][past[0]], named, paragraph.get_path()])
			return
