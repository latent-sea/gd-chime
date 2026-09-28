extends "presentation.gd"

const Bound := preload("components/primitives/bound.gd")
const Inset := preload("components/primitives/inset.gd")
const Styled := preload("components/primitives/styled.gd")
const Motion := preload("motion.gd")
const Outgoing := preload("components/primitives/outgoing.gd")
const DrawnReach := preload("components/primitives/drawn_reach.gd")
const FaceInk := preload("face_ink.gd")

## A face: how a thing that can be pressed looks - one box and one ink for
## the state it is in, under its style, holding whatever content it has.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## IT KNOWS NOTHING OF ACTIONS. What a press does belongs to whatever
## extends this - an action control dispatches through the door, a local
## press sets a local - and so does the list of states: this knows hover
## and normal, and whatever extends it answers get_state() with its own first.
## The look is one stylebox and one ink per state under its style, a Theme
## name or a bound value reading one (styled.gd), worn again in place as the
## value moves; the focus box is drawn over it while the focus shows. A
## state the style draws no box for takes normal's; THE INK ITS WORDS ARE
## IN IS FACE_INK.GD'S, which says why words on a press are never the kind
## of words' own colour and why it stops at a press inside this one. A
## style the look does not know is drawn as a pressable. Its content sits
## across it, inside the box's padding, and takes no press: the engine
## decides a press landed here whichever part is under the pointer.
##
## A CHANGE OF LOOK BLENDS. When the box it is drawn in changes - its state
## moved, or its bound style did - the box it had is left fading over the
## new one (outgoing.gd); when its ink changes, even under one box two
## states share, its ink goes smoothly from the one colour to the other, by the look's restyle easing on the one clock, handed to it
## as motion by the builder. One built by hand has no clock, and switches.
## Content put in after it was first drawn is inked as it arrives. Words in
## the ink already are left alone: a label told its colour shapes its words again.
##
## IT RINGS THE MOMENTS OF A HAND. A press landing, the pointer arriving and
## focus starting to show are bells in the GLOBAL region, named by
## interaction.gd, which has no chimes; a face has, and every pressed thing in
## the framework is one, so this is where they sound. Nothing is carried:
## whoever hears one reads the control the press landed on, which the level
## below keeps, or the viewport for the one the focus is on. An address nobody
## hung is quiet, so an application that listens for none of them pays a lookup
## and nothing else.
##
## WHAT STANDS AROUND IT MAKES ROOM FOR THE BOX IT STAYS IN (drawn_reach.gd):
## its state's while it is chosen, current or inert, and its resting box
## while it is only passing through a state - pointed at, glowing, carried
## or under a carry - so a pointer passing never moves a layout. It answers
## for that reach itself (get_reach), worked out as it places its content -
## the box it stays in and the content's own, as placed - and, that
## changed, what holds it measures again; nothing else walks into it. Its
## state is asked as it refreshes, which every change of state brings about
## before the frame is drawn, and the box it settles on is kept: a layout
## placing it and a resize drawing it again - every frame of a pane dragged
## - ask the door nothing.
##
## Deliberately absent: anything a press does.

## The states it only passes through, drawn but never made room for.
const PASSING: Array[StringName] = [&"hover", &"glowing", &"lifted", &"accepting", &"refusing"]

var _lit: bool = false
var _focused: bool = false
var _style: Variant  # the style described - a name, or a Bound reading one - tried again on every look
var _said: StringName  # the name the style said when the look was last read
## The one clock, handed in by the builder; none, and a change of look switches.
var motion: Motion = null
var _last_box: StyleBox = null  # the box it was last drawn in
var _ink_now: Color  # the ink its words are in at this moment
var _inking: Motion.Run = null  # its ink on the way from one colour to another
var _reading: bool = false  # while the look is being read, so a fallback set here is not heard as another look
var _stays_in: StyleBox = null  # the box it stays in as last drawn, which what holds it makes room for
var _reach: Array[float] = [0.0, 0.0, 0.0, 0.0]  # how far it draws past each of its edges, as it last placed its content


func _init(chimes: Chimes, in_region: StringName, style: Variant) -> void:
	super(chimes, [], in_region)
	_style = style
	theme_type_variation = Styled.name_of(style)
	focus_mode = Control.FOCUS_ALL


func hovered(inside: bool) -> void:
	_lit = inside
	needs_refresh()


func focused(shown: bool) -> void:
	_focused = shown
	needs_refresh()


## One of interaction.gd's moments, sounded where the chimes are.
func _ring(moment: StringName) -> void:
	strike(Chimes.GLOBAL, moment)


## The one state the look draws it in - normal, hover, inert, current,
## glowing, lifted, accepting, refusing, selected, listening - what extends
## this answering its own first. PUBLIC because it is the only honest read of
## how a control is drawn: a test asserting a press shows as refused reads this.
func get_state() -> StringName:
	return &"hover" if _lit else &"normal"


## The styleboxes drawn over its whole rect, in order: its state's, as it
## settled, and the focus while the focus shows. PUBLIC for the same reason
## get_state() is: what is drawn over a control is a thing a test has to read.
func get_drawn() -> Array[StyleBox]:
	var boxes: Array[StyleBox] = [_settled_box()]
	if _focused:
		boxes.append(get_theme_stylebox(&"focus"))
	return boxes


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		Inset.fit(self, _settled_box())
		var reach := DrawnReach.walked(self, get_drawn_box())
		# its reach moved: what holds it measures again, making room for this one
		if reach != _reach:
			_reach = reach
			DrawnReach.tell_holder(self)
	# content put in after it was first drawn - a piece built into a live list - inked once it is all built
	if what == NOTIFICATION_CHILD_ORDER_CHANGED and is_node_ready():
		_ink_words.call_deferred()
	if (what == NOTIFICATION_ENTER_TREE or what == NOTIFICATION_THEME_CHANGED) and not _reading:
		_read_look()


## The style it says now, worn in place; a pressable's where the look does not know it.
func _read_look() -> void:
	_reading = true
	_said = Styled.name_of(_style)
	_wear(_said)
	if not has_theme_stylebox(&"normal"):
		_wear(Themes.PRESSABLE)
	_reading = false


func _draw() -> void:
	var whole := Rect2(Vector2.ZERO, size)
	for box: StyleBox in get_drawn():
		draw_style_box(box, whole)


func refresh() -> void:
	# a bound style that moved is worn before anything is drawn from it
	if _style is Bound and _said != Styled.name_of(_style):
		_read_look()
	var before := _last_box
	var stayed := _stays_in
	var state := get_state()
	_blend(state)
	_stays_in = get_theme_stylebox(&"normal") if PASSING.has(state) else _box_of(state)
	queue_redraw()
	# drawn in a box keeping other room round its content, or staying in another: measured, its content placed again and its reach worked out again - never for an ink or a box that keeps the same room
	if before == null or [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM].any(func(side: int) -> bool: return before.get_margin(side) != _last_box.get_margin(side)) or _stays_in != stayed:
		update_minimum_size()
		queue_sort()


## How far it draws past its edge on this side, as it last placed its content.
func get_reach(side: int) -> float:
	return _reach[side]


## The look it has now against the one it was last drawn in: the old box
## left fading over the new, and every word in its content sent to the
## state's ink - or, with no clock or nothing drawn yet, simply there.
func _blend(state: StringName) -> void:
	var box := _box_of(state)
	var ink := FaceInk.of_state(self, state)
	if motion == null or _last_box == null or not is_visible_in_tree():
		_inked(ink)
	# the box moved, or the ink did under one box two states share: the ink it is heading for is a running blend's end, else the one it is in
	elif box != _last_box or ink != (_inking.to if _inking != null and not _inking.is_over() else _ink_now):
		if box != _last_box:
			Outgoing.leave(self, _last_box, motion)
		if _inking == null:
			_inking = motion.run(_ink_now, ink, Motion.RESTYLE, _inked, true)
		else:
			motion.retarget(_inking, ink)
	_last_box = box


func _inked(colour: Color) -> void:
	if _last_box != null and colour == _ink_now:
		return
	_ink_now = colour
	FaceInk.on_words(self, colour)


## Its words in the ink it is on now, deferred: measured on 4.6.2, a static
## function's Callable taking a node cannot be deferred - the engine
## refuses to convert the argument - so the deferred call is this one's.
func _ink_words() -> void:
	FaceInk.on_words(self, _ink_now)


## The box of the state it is in now.
func _box() -> StyleBox:
	return _box_of(get_state())


## A state's box: its style's, else normal's for a state no look draws.
func _box_of(state: StringName) -> StyleBox:
	return get_theme_stylebox(state) if has_theme_stylebox(state) else get_theme_stylebox(&"normal")


## The box it is drawn in for as long as it stays as it is, as it last
## refreshed: its state's, but its resting one while it only passes through
## a state - or, before its first refresh, worked out now.
func get_drawn_box() -> StyleBox:
	if _stays_in != null:
		return _stays_in
	return get_theme_stylebox(&"normal") if PASSING.has(get_state()) else _box()


## The ink of the state it is in now.
func _colour() -> Color:
	return FaceInk.of_state(self, get_state())


## Its content sits inside its box's padding: as much room as any part needs, plus the padding.
func _get_minimum_size() -> Vector2:
	return Inset.least(self, _settled_box())


## The box its state settled on as it was last refreshed - its state asked
## once a refresh, never again by a layout placing it or a resize drawing
## it - or, before its first refresh, its state's now.
func _settled_box() -> StyleBox:
	return _last_box if _last_box != null else _box()


## The variation set only when it changes, and never while a look is
## being read: setting it tells this the theme changed, and that is where
## this is asked from.
func _wear(variation: StringName) -> void:
	if theme_type_variation != variation:
		theme_type_variation = variation
