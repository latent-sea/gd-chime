extends Container

const ScrollFinger := preload("components/primitives/scroll_finger.gd")
const Touch := preload("touch.gd")

## Pieces laid where a plan puts them in the room this is given, at the type
## sizes it gives them: a screen that works out its own giving way - every
## length its own rule's, tried step by step until the screen fits (the
## templates of design/ui/layout) - standing on the floor like any other
## piece, its pieces pressed, focused and gone back from as theirs are.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE PLAN is asked, with the room and this (so it may read the look's
## fonts), what stands where: {"rects": a Rect2 for each piece in order,
## "types": a type size for each, the size all words in that piece are
## drawn at, 0 leaving them at their kind's, and "size": all of it}, every
## length in base pixels. It is asked again whenever the room moves. It may
## also say "shown", whether each piece shows, a piece it leaves out hidden;
## "aligns", how each piece's words line up across, a HorizontalAlignment;
## and "ground", a rect the look's `ground` box is drawn in under the
## pieces, which may reach past this into the room round it - a bar's colour
## running to the window's edges past the safe margin. IT FOLLOWS WHAT ITS
## PLAN READS (chimes.gd, follow): a value the plan read moving - the tab a
## page shows, a fact's words - lays it out again.
##
## WHAT DOES NOT FIT SCROLLS, WITH A BAR AND ITS ARROWS SHOWN. Where all of
## it is longer than the room on an axis, the bar's thickness (the look's
## `bar`) is set aside on that axis and the plan asked again in what is
## left, at most once for each axis; a bar set aside that the plan no
## longer needs gives its room back and is not shown. The arrows step by
## the look's `step`; a wheel steps the same, and a finger pans it (touch.gd).
##
## ITS LEAST IS WHAT IT IS BUILT WITH, nothing unless a height of its own
## is given - a bar's: it takes the room it is given and never asks for
## more, since whatever it holds that does not fit scrolls inside it. It
## clips what it holds only while it scrolls, so a ground may reach past it.
##
## IT STANDS WITH THE FLOOR'S OWN MACHINERY, not among the components, as
## fitted_text.gd does: it sets the size words are drawn at, which a
## component never does (convention_lint.py), and only as its plan says.

## The kind it is built as (ui.gd).
const KIND := &"planned"
## The two bars' kinds, the look's variations of the engine's scroll bars.
const DOWN_BAR := &"PlannedDown"
const ACROSS_BAR := &"PlannedAcross"

var _plan: Callable
var _look: StringName
var _down := VScrollBar.new()
var _across := HScrollBar.new()
var _finger: ScrollFinger
var _laid: Dictionary = {}  # what the plan said when it was last asked: rects, types and size
var _placing := false  # whether its pieces are being placed, when the bars' values moving lay nothing again
var _least: Vector2
var _chimes: RefCounted


func _init(ui: RefCounted, plan: Callable, look: StringName, least: Vector2) -> void:
	_plan = plan
	_look = look
	_least = least
	_chimes = ui.chimes
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_to_group(Touch.TAKES)
	# each bar its look's, behind the pieces in the tree and drawn over them
	for bar: ScrollBar in [_down, _across]:
		bar.theme_type_variation = DOWN_BAR if bar == _down else ACROSS_BAR
		# filling the rect it is fitted in, never shrunk to the engine's least
		bar.size_flags_horizontal = Control.SIZE_FILL
		bar.size_flags_vertical = Control.SIZE_FILL
		add_child(bar, false, Node.INTERNAL_MODE_FRONT)
	_down.value_changed.connect(_scrolled)
	_across.value_changed.connect(_scrolled)
	_finger = ScrollFinger.new(self, ui.motion, _down, _across)


## A bar moved, by its arrows, its thumb, a wheel or a finger: the pieces placed again where it now shows them.
func _scrolled(_to: float) -> void:
	if not _placing:
		queue_sort()


func _get_minimum_size() -> Vector2:
	return _least


## The pieces it lays, in the plan's order: every child but its bars.
func pieces() -> Array[Control]:
	var held: Array[Control] = []
	# the children added by the builder, which are the pieces; the bars are internal
	for child: Node in get_children():
		held.append(child as Control)
	return held


## Its two bars, down and across, shown or not.
func bars() -> Array[ScrollBar]:
	return [_down, _across]


## Every label in a piece, its own internal ones among them: a text keeps the label its words are drawn in inside it.
static func labels_in(piece: Node) -> Array[Label]:
	var found: Array[Label] = []
	# the piece and everything under it, internal children included
	for child: Node in piece.get_children(true):
		if child is Label:
			found.append(child)
		found.append_array(labels_in(child))
	return found


## What the plan said when it was last asked: {"rects", "types", "size"}, in base pixels.
func laid() -> Dictionary:
	return _laid


## The plan asked in the room, with a bar's room set aside on an axis that
## overflows, and given back where it no longer needs it; then whether each
## bar shows. Returns [the plan's answer, the room it was asked in].
func _planned() -> Array:
	var thickness := float(get_theme_constant(&"bar", _look))
	var set_aside := Vector2.ZERO  # 1 on an axis whose bar's room is set aside
	var asked := {}
	var room := size
	# at most a pass for each axis: each sets aside room on one not yet set aside
	for _pass: int in 3:
		room = size - Vector2(set_aside.y, set_aside.x) * thickness
		var answer := {}
		# the plan asked, and followed: what it read moving lays this out again
		_chimes.follow(self, &"plan", func() -> void: answer["plan"] = _plan.call(room, self), queue_sort)
		asked = answer["plan"]
		var over := Vector2(1.0 if asked["size"].x > room.x + 0.5 else 0.0, 1.0 if asked["size"].y > room.y + 0.5 else 0.0)
		if over.x <= set_aside.x and over.y <= set_aside.y:
			break
		set_aside = Vector2(maxf(set_aside.x, over.x), maxf(set_aside.y, over.y))
	return [asked, room]


func _notification(what: int) -> void:
	# freed, it follows nothing more: a ring after would reach a piece no longer there
	if what == NOTIFICATION_PREDELETE:
		_chimes.unfollow(self, &"plan")
		return
	# laid out only once it has a room: there is no plan for nothing
	if what != NOTIFICATION_SORT_CHILDREN or size.x <= 0.0 or size.y <= 0.0:
		return
	var answer: Array = _planned()
	_laid = answer[0]
	var room: Vector2 = answer[1]
	var all: Vector2 = _laid["size"]
	var thickness := float(get_theme_constant(&"bar", _look))
	_placing = true
	_down.visible = all.y > room.y + 0.5
	_across.visible = all.x > room.x + 0.5
	# each bar along its edge, its length the room's on its axis, its range what overflows
	for bar: ScrollBar in [_down, _across]:
		var axis: int = 1 if bar == _down else 0
		bar.max_value = all[axis]
		bar.page = room[axis]
		bar.step = 0.0
		bar.custom_step = float(get_theme_constant(&"step", _look))
		bar.value = clampf(bar.value, 0.0, maxf(0.0, all[axis] - room[axis])) if bar.visible else 0.0
	clip_contents = _down.visible or _across.visible
	fit_child_in_rect(_down, Rect2(room.x, 0.0, thickness, room.y))
	fit_child_in_rect(_across, Rect2(0.0, room.y, room.x, thickness))
	var offset := Vector2(_across.value, _down.value)
	var held := pieces()
	# each piece at its type size, then where the plan puts it, less how far it is scrolled
	for at: int in held.size():
		var type: int = _laid["types"][at]
		# every word in the piece, sized as the plan says, or as its kind says where the plan leaves it
		for words: Label in labels_in(held[at]):
			var label := words
			# only where it moves: a size set again tells the words their look moved, which would lay this out again
			if type > 0 and (not label.has_theme_font_size_override(&"font_size") or label.get_theme_font_size(&"font_size") != type):
				label.add_theme_font_size_override(&"font_size", type)
			elif type == 0 and label.has_theme_font_size_override(&"font_size"):
				label.remove_theme_font_size_override(&"font_size")
		var rect: Rect2 = _laid["rects"][at]
		fit_child_in_rect(held[at], Rect2(rect.position - offset, rect.size))
		held[at].visible = _laid["shown"][at] if _laid.has("shown") else true
		# the piece's words lined up as the plan says, where it says
		for words: Label in labels_in(held[at]) if _laid.has("aligns") else []:
			words.horizontal_alignment = _laid["aligns"][at]
	_placing = false
	queue_redraw()


func _draw() -> void:
	if _laid.has("ground"):
		draw_style_box(get_theme_stylebox(&"ground", _look), _laid["ground"])


func _gui_input(event: InputEvent) -> void:
	var wheel := event as InputEventMouseButton
	if wheel == null or not wheel.pressed:
		return
	# the wheel a step down or up, or across with shift or a sideways wheel, on whichever bar shows that way
	var steps := {MOUSE_BUTTON_WHEEL_DOWN: 1.0, MOUSE_BUTTON_WHEEL_UP: -1.0, MOUSE_BUTTON_WHEEL_RIGHT: 1.0, MOUSE_BUTTON_WHEEL_LEFT: -1.0}
	if not steps.has(wheel.button_index):
		return
	var sideways: bool = wheel.button_index in [MOUSE_BUTTON_WHEEL_RIGHT, MOUSE_BUTTON_WHEEL_LEFT] or wheel.shift_pressed or not _down.visible
	var bar: ScrollBar = _across if sideways else _down
	if bar.visible:
		bar.value += steps[wheel.button_index] * bar.custom_step
		accept_event()


## A finger along its way, where it can move for it (touch.gd).
func takes_finger(axis: StringName, travel: Vector2) -> bool:
	return _finger.takes(axis, travel)


func finger_moved(_travel: Vector2, relative: Vector2) -> void:
	_finger.moved(relative)


func finger_ended(velocity: Vector2) -> void:
	_finger.ended(velocity)


static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(KIND).new(ui, desc.props["plan"], desc.props["look"], desc.props["least"])
	ui.attach(made, parent, desc.facts)
	return made
