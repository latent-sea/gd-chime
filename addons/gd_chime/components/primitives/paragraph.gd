extends "../../presentation.gd"

const Bound := preload("bound.gd")
const Desc := preload("desc.gd")
const Text := preload("text.gd")
const Language := preload("../../language.gd")

## Running words: spans one after another, wrapped as a paragraph at the
## width it is given - phrases, a model's data, and links among them, each
## link a pressable laid in the line where its words fall.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## ITS WORDS ARE SAID AS A TEXT SAYS THEM (text.gd): a phrase in the language
## on as it is laid, data as it is, a bound value read again whenever what
## it read moves, and every one of them again when the language changes. A
## link's words are a text of its own, inside the link, said the same way.
##
## THE ENGINE LAYS IT OUT: the words are shaped into one TextParagraph with
## each link an inline object as big as the link needs, so the lines break
## where the language's own rules break them, in any script, and a link
## falls where its words fall. The words are drawn here; each link is fitted
## to the room the shaping left for it, so nothing is drawn over anything.
## A link is never broken across two lines: it is one thing to press.
##
## LAID AGAIN IN PLACE, NEVER BUILT AGAIN: the language changing, a bound
## span moving, a link needing more room, the width changing - each shapes
## the same spans again and moves the same links. Nothing is freed or made,
## so a focused link keeps the focus.
##
## THE PAD WALKS THE LINKS IN READING ORDER. The engine walks by geometry,
## and a link at the end of one line is not beside the link that starts the
## next; so each link's right and next are the link after it, and its left
## and previous the link before, as the spans give them. Up and down, and
## out past the first and the last link, stay the engine's.
##
## It takes no press: its links do. It needs the height its lines need at
## the width it has, and no less wide than its widest link.
##
## Deliberately absent: a link across two lines, and a sentence whose parts
## a language would put in another order - the spans are said in the order
## they are given, as a phrase's joined parts are. And a link's up and down
## to the link on the line above or below: the links chain left and right
## alone, so down from a link goes where the engine's walk goes, which can
## leave the paragraph with a link still on the line below; that link is
## reached by right, in reading order.

## Where a line may break - at a line's end, between words, and inside a word too long for a whole line - with the spaces at a break dropped.
const BREAKS := TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE | TextServer.BREAK_TRIM_EDGE_SPACES

var _spans: Array  # a phrase, data, or a Bound reading either; null where the next link goes
var _shaped := TextParagraph.new()
var _needs := Vector2.ZERO  # its widest link, and the height of its lines at the width it has
var _said: String = ""  # its own words as last said


func _init(chimes: Chimes, spans: Array, style: StringName, in_region: StringName) -> void:
	super(chimes, [], in_region)
	_spans = spans
	theme_type_variation = style
	# the words take no press: its links do
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Its own words, as they were last said: a link's are the link's.
func get_text() -> String:
	return _said


## Each line as it was laid, in its own rect: where the words and links of
## that line are drawn.
func get_lines() -> Array[Rect2]:
	var lines: Array[Rect2] = []
	var top := 0.0
	# every line, one under the other
	for line: int in _shaped.get_line_count():
		lines.append(Rect2(Vector2(0.0, top), _shaped.get_line_size(line)))
		top += _shaped.get_line_size(line).y
	return lines


func heard(_what: StringName) -> void:
	needs_refresh()


## The words may say something else now: every bound span read, so what it
## read is followed, and the whole laid again.
func refresh() -> void:
	# every bound span, read for what it reads; the laying says them
	for span: Variant in _spans:
		if span is Bound:
			span.read()
	queue_sort()


func _get_minimum_size() -> Vector2:
	return _needs


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_lay()


## The spans shaped at the width it has, each link fitted where the words
## left room for it and walked in reading order, and the room it needs said
## again when that moved.
func _lay() -> void:
	var links := get_children().filter(func(child: Node) -> bool: return child is Control)
	var widest := 0.0
	# every link, for the widest: no line may be narrower than a link it must hold
	for link: Control in links:
		widest = maxf(widest, link.get_combined_minimum_size().x)
	_shaped.clear()
	_shaped.break_flags = BREAKS
	_shaped.width = maxf(size.x, widest)
	var font := get_theme_font(&"font")
	var font_size := get_theme_font_size(&"font_size")
	var next := 0
	_said = ""
	# every span in order: words shaped as they are said now, a link as room of its size
	for span: Variant in _spans:
		if span == null:
			_shaped.add_object(next, (links[next] as Control).get_combined_minimum_size(), INLINE_ALIGNMENT_CENTER)
			next += 1
			continue
		var words := Text.said(span.read() if span is Bound else span)
		_said += words
		_shaped.add_string(words, font, font_size, TranslationServer.get_locale())
	# every line, and on it every link, fitted to the room left for it
	for line: int in _shaped.get_line_count():
		for key: int in _shaped.get_line_objects(line):
			fit_child_in_rect(links[key], _shaped.get_line_object_rect(line, key))
	# every link, pointed at the links either side of it in the order it is read
	for at: int in links.size():
		var link: Control = links[at]
		link.focus_neighbor_right = link.get_path_to(links[at + 1]) if at + 1 < links.size() else NodePath()
		link.focus_next = link.focus_neighbor_right
		link.focus_neighbor_left = link.get_path_to(links[at - 1]) if at > 0 else NodePath()
		link.focus_previous = link.focus_neighbor_left
	var needs := Vector2(widest, _shaped.get_size().y)
	if needs != _needs:
		_needs = needs
		update_minimum_size()
	queue_redraw()


func _draw() -> void:
	_shaped.draw(get_canvas_item(), Vector2.ZERO, get_theme_color(&"font_color"))


## The builder's door: the spans kept in order, a link's place held by
## nothing, the links built into it after as its content; and it reads again
## when the language changes.
static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var spans: Array = desc.props["spans"].map(func(span: Variant) -> Variant: return null if span is Desc else span)
	var made: Control = ui.primitive(&"paragraph").new(ui.chimes, spans, desc.props["style"], ui.region())
	made.listen_to(Chimes.GLOBAL, Language.LANGUAGE_CHANGED)
	ui.attach(made, parent, desc.facts)
	return made
