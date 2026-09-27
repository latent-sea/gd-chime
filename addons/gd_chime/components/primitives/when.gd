extends "../../presentation.gd"

const Bound := preload("bound.gd")
const Going := preload("going.gd")
const Shift := preload("shift.gd")
const Transition := preload("transition.gd")

## One of two descriptions, by a bound value: the first while it is true,
## the other while it is not, swapped as the value changes.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The one showing is built when chosen and freed when the other is - the
## nodes are the truth, and nothing is kept for a side not showing. A
## description of nothing shows nothing, and takes nothing: holding nothing
## to see, this is hidden, so the line it stands in gives it no gap - a
## hidden part takes no room. If the piece being freed holds the
## focus, the focus is handed to the next control that takes it first, so a
## pad is never left with nothing selected. It needs as much room as what
## it shows.
##
## THE SWAP IS A TRANSITION (transition.gd), the one asked for where this
## was described or the one the look names for a when: the side arriving
## enters, and the side going stays until its exit has run, out of reach
## and out of the content from the moment it starts. What it first shows
## is simply there. A kept side is hidden, not freed, so it goes at once
## and only its arriving is seen.

var _bound: Bound
var _a: RefCounted  # a Desc, or null
var _b: RefCounted
var _ui: RefCounted
var _keeps: bool
var _showing_a: bool
var _shown: Control = null
var _kept: Array = [null, null]  # both sides built once, when kept
var _in_place: Node  # the place this was built in, for building again later
var _in_look: Theme  # the look this was built under, for building again later - either side may hold a place lifting pop-ups
var _asked: StringName  # the transition asked for where this was described, or none
var _begun: bool = false  # whether it has shown anything yet: the first is simply there


func _init(ui: RefCounted, bound: Bound, a: RefCounted, b: RefCounted, in_region: StringName, keeps: bool, asked: StringName = &"") -> void:
	super(chimes_of(ui), [], in_region)
	_ui = ui
	_bound = bound
	_a = a
	_b = b
	_keeps = keeps
	_asked = asked
	_in_place = ui.current_place()
	_in_look = ui.current_look()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_showing_a = _chosen()
	_show()
	_begun = true


## Whether the first description is the one showing.
func is_showing_first() -> bool:
	return _showing_a


func heard(_what: StringName) -> void:
	needs_refresh()


## Hidden while it holds nothing, its own draw is what shows it again (presentation.gd).
func shows_itself() -> bool:
	return true


func refresh() -> void:
	var chosen := _chosen()
	if chosen == _showing_a:
		return
	_showing_a = chosen
	_show()


## Placed again: every side it holds across the whole of it, as its motion
## has left it (shift.gd) - words that wrap need the width they are given,
## and a piece left at its own least width is one letter wide - but not a
## side going, which stays where it stood.
func _notification(what: int) -> void:
	# a side going freed at the end of its exit may leave nothing to see
	if what == NOTIFICATION_CHILD_ORDER_CHANGED:
		_seen()
	if what == NOTIFICATION_SORT_CHILDREN:
		# every side held, fitted to the whole of this unless it is on its way out
		for child: Node in get_children():
			if child is Control and not Going.is_going(child):
				Shift.fit(self, child, Rect2(Vector2.ZERO, size))


func _get_minimum_size() -> Vector2:
	return _shown.get_combined_minimum_size() if _shown != null else Vector2.ZERO


static func chimes_of(ui: RefCounted) -> Chimes:
	return ui.chimes


func _show_kept() -> void:
	for side: int in [0, 1]:
		var desc: RefCounted = _a if side == 0 else _b
		if _kept[side] == null and desc != null:
			_kept[side] = _ui.build(desc, self, _in_place, _in_look)
		if _kept[side] != null:
			_kept[side].visible = (side == 0) == _showing_a
	_shown = _kept[0] if _showing_a else _kept[1]
	_seen()
	_arrive()
	update_minimum_size()


## What is showing now enters, unless it is the first thing shown or nothing can be seen.
func _arrive() -> void:
	if _begun and _shown != null and is_visible_in_tree():
		Transition.enter(_shown, Transition.named(_asked, &"when", self), _ui.motion)


## Whether the value holds: something rather than nothing, true, not zero,
## not empty.
func _chosen() -> bool:
	var value: Variant = _bound.read()
	match typeof(value):
		TYPE_NIL: return false
		TYPE_BOOL: return value
		TYPE_INT, TYPE_FLOAT: return value != 0
		TYPE_STRING, TYPE_STRING_NAME, TYPE_ARRAY, TYPE_DICTIONARY: return not value.is_empty()
	return true


## The side chosen built, the other freed - its focus handed on first; or,
## kept, both built once and the chosen one shown, so a half-typed line
## survives a page turned away from.
func _show() -> void:
	if _keeps:
		_show_kept()
		return
	if _shown != null:
		var focused := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
		if focused != null and (focused == _shown or _shown.is_ancestor_of(focused)):
			var next := focused.find_next_valid_focus()
			if next != null and next != _shown and not _shown.is_ancestor_of(next):
				next.grab_focus()
		Transition.exit(_shown, Transition.named(_asked, &"when", self) if is_visible_in_tree() else Transition.NONE, _ui.motion)
		_shown = null
	var desc: RefCounted = _a if _showing_a else _b
	if desc != null:
		_shown = _ui.build(desc, self, _in_place, _in_look)
	_seen()
	_arrive()
	update_minimum_size()


## Shown while it holds something to see - the side chosen, or one still on
## its way out - and hidden while it holds nothing, so a when of nothing
## takes no gap in the line it stands in. Whether the side chosen is itself
## shown is not asked: a place in it is shown and hidden by the driver.
func _seen() -> void:
	visible = _shown != null or get_children().any(func(side: Node) -> bool: return Going.is_going(side))


static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"when").new(ui, desc.props["bound"], desc.props["a"], desc.props["b"], ui.region(), desc.props["keeps"], desc.props.get("transition", &""))
	ui.attach(made, parent, desc.facts)
	return made