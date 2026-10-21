extends RefCounted

const Going := preload("components/primitives/going.gd")
const PageScroll := preload("components/primitives/page_scroll.gd")
const WordMeasure := preload("components/primitives/word_measure.gd")
const Planned := preload("planned.gd")

## Whether anything in a built tree stands where the room it was given does
## not reach: past the safe rect, past a holder that cuts off what it holds
## on a way it never scrolls, or words set narrower than their widest word.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE WINDOW HOLDS THE PAGE (easel_canvas.gd, page_scroll.gd) AND EVERY
## LEAST IS HONEST (preferred.gd), so nothing should stand past the room it
## was given: one that does asks for more than it says, which is a fault in
## what it is made of and never in the window. This walks a tree at rest
## once and hands back one sentence for each piece it finds - which piece,
## past which side of what, by how much. It holds nothing it found, draws
## nothing and mends nothing: a test asserts it finds nothing.
##
## A PIECE IS JUDGED AGAINST THE NEAREST THING HOLDING IT THAT CUTS WHAT IT
## HOLDS OFF (clip_contents), or the safe rect where nothing does. Past a
## scroll on a way the scroll moves is only further down the page or along
## the strip, and no fault; past it any other way - a page across, a strip
## down, anything that cuts and never moves - is. Where that holder stands
## is judged against its own holder, and what stands in a piece found past
## its room is judged against the room grown to where that piece stands, so
## a piece is never blamed for where its holder stands: one sentence for
## each piece that reaches further than what holds it.
##
## WORDS ARE NEVER SET NARROWER THAN THEIR WIDEST WORD, NOR IN MORE LINES
## THAN THEY HAVE WORDS: words that wrap, set so, break a word across
## lines - a letter to a line at the worst (word_measure.gd). squeezed()
## finds those alone, for a test that holds that and no more.
##
## SAID ONCE FOR EACH PIECE: say() finds what found() finds and, in a debug
## build, says each piece out loud as an error the first time it finds it:
## for a sweep run while screens still overflow, whose findings are read
## and set aside rather than failed on.
##
## What is NOT judged: what is hidden or going (going.gd), and what stands
## in a view's own viewport, whose coordinates are its own. The root given
## is the ground the safe rect is on: only what stands on it is judged,
## against the safe rect given in the root's viewport's coordinates.

var _said: Dictionary = {}  # instance id -> true, for each piece already said out loud


## Every sentence about a piece standing past the room it was given, or
## words set narrower than their widest word, in this tree: none when
## nothing is.
static func found(root: Node, safe: Rect2) -> Array[String]:
	var findings: Array = []
	_walk(root, safe, "the safe rect", [false, false], findings, true)
	return _sentences(findings)


## Every sentence about words set narrower than their widest word, or in
## more lines than they have words, in this tree: none when no words are.
static func squeezed(root: Node) -> Array[String]:
	var findings: Array = []
	_walk(root, Rect2(), "", [true, true], findings, false)
	return _sentences(findings)


## What found() finds, each piece said out loud as an error the first time
## this finds it, in a debug build.
func say(root: Node, safe: Rect2) -> Array[String]:
	var findings: Array = []
	_walk(root, safe, "the safe rect", [false, false], findings, true)
	# every finding, said out loud where its piece is new to this
	for finding: Array in findings:
		if OS.is_debug_build() and not _said.has(finding[0].get_instance_id()):
			_said[finding[0].get_instance_id()] = true
			push_error(finding[1])
	return _sentences(findings)


## Everything standing on this node, against the room it stands in, which
## is named, and which ways it moves - across, then down. What cuts off
## what it holds is the room for what stands on it. A piece past its room
## on a way the room does not move, where pieces are judged as placed, and
## words that wrap set narrower than their widest word, are found.
static func _walk(node: Node, room: Rect2, named: String, moves: Array, findings: Array, placed: bool) -> void:
	# everything standing on it that is shown and staying
	for child: Node in node.get_children():
		if not child is Control or not (child as Control).visible or Going.is_going(child):
			continue
		var piece := child as Control
		var rect := piece.get_global_rect()
		# how far it stands past each edge of its room, by Side: the room's left and top less its own, its right and foot less the room's
		var over: Array[float] = [room.position.x - rect.position.x, room.position.y - rect.position.y, rect.end.x - room.end.x, rect.end.y - room.end.y]
		var past := false
		# every side, by Side, for the first past which it stands where its room does not move that way - across for left and right, down for top and bottom
		for side: int in (4 if placed else 0):
			if over[side] > 0.5 and not moves[side % 2]:
				findings.append([piece, "%s stands %d pixels past the %s of %s, which never moves that way to bring it in: something in it asks for more room than it was given" % [piece.get_path(), roundi(over[side]), ["left", "top", "right", "bottom"][side], named]])
				past = true
				break
		if piece is Label and (piece as Label).autowrap_mode != TextServer.AUTOWRAP_OFF:
			_judge_words(piece as Label, findings)
		if piece is SubViewportContainer:
			continue
		if piece.clip_contents:
			_walk(piece, rect, String(piece.get_path()), _moving(piece), findings, placed)
		else:
			# found past its room, what it holds is judged against the room grown to where it stands
			_walk(piece, room.merge(rect) if past else room, named, moves, findings, placed)


## Which ways a holder that cuts off what it holds moves to bring it in -
## across, then down: a scroll each way it scrolls, but a page never across
## (page_scroll.gd); a planned piece each way its bar shows (planned.gd);
## anything else neither.
static func _moving(holder: Control) -> Array:
	if holder is Planned:
		return [(holder as Planned).bars()[1].visible, (holder as Planned).bars()[0].visible]
	if not holder is ScrollContainer:
		return [false, false]
	var scroll := holder as ScrollContainer
	# across, a scroll moving that way and not a page; down, a scroll moving that way
	return [scroll.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED and not holder is PageScroll, scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED]


## Words that wrap, against their widest word and how many words they are:
## set narrower than the one, or in more lines than the other, a word is
## broken across lines.
static func _judge_words(label: Label, findings: Array) -> void:
	if label.text.strip_edges() == "":
		return
	var measure := WordMeasure.new()
	var font_size := label.get_theme_font_size(&"font_size")
	var room: float = label.size.x - label.get_theme_stylebox(&"normal").get_minimum_size().x
	if room + 0.5 < measure.widest(label, font_size) or label.get_line_count() > measure.words(label, font_size):
		findings.append([label, '"%s" is set %d pixels wide in %d lines, where its widest word needs %d and it is %d words, so a word is broken across lines, at %s' % [label.text.substr(0, 60), roundi(room), label.get_line_count(), roundi(measure.widest(label, font_size)), measure.words(label, font_size), label.get_path()]])


## The sentences of these findings, each [piece, sentence], in the order found.
static func _sentences(findings: Array) -> Array[String]:
	var sentences: Array[String] = []
	sentences.assign(findings.map(func(finding: Array) -> String: return finding[1]))
	return sentences
