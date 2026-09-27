extends Container

const Bound := preload("bound.gd")
const Shift := preload("shift.gd")

## A piece set down beside a rect a bound value reads - under it, or over
## it where there is no room below, and never past the window - with the
## rest of the room around it a press that sends it away: a context menu
## beside what it was opened over.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## It takes the whole of what holds it - a pop-up, the window - and sets
## what it holds at the least size that piece needs, its top-left corner at
## the rect's bottom-left: moved left as far as keeps it inside, and above
## the rect instead where below would run past the foot. The rect is read
## again as its value moves, and the piece placed there. SET DOWN, IT TAKES
## THE FOCUS into what it holds, its first control that takes one, while the
## focus is outside it: what it holds may only have been built as it opened,
## after the move had given the focus out - a menu's items are - and a menu
## opened is walked from its first item.
##
## A PRESS ANYWHERE BUT ON THE PIECE - left or right, with the pointer - is
## the action it was described with, through the door: the pop-up's way
## back, which its place declares as going BACK. So a menu goes away as a
## reader clicks past it, and the same action on a key sends it away from
## the keyboard. What it holds is pressed as ever. It draws nothing.
##
## Deliberately absent: an arrow pointing at the rect, and a side chosen
## by the look.

var _ui: RefCounted
var _rect: Bound
var _sends_away: StringName  # the action a press past the piece dispatches
var _region: StringName  # the place it stands in


func _init(ui: RefCounted, rect: Bound, sends_away: StringName) -> void:
	_ui = ui
	_rect = rect
	_sends_away = sends_away
	_region = ui.region()
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.chimes.follow(self, &"rect", _rect_moved)


## The rect read, so what it read is followed, and the piece placed again under it.
func _rect_moved() -> void:
	_rect.read()
	queue_sort()


## A press past the piece sends it away.
func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or (click.button_index != MOUSE_BUTTON_LEFT and click.button_index != MOUSE_BUTTON_RIGHT):
		return
	accept_event()
	_ui.commands.dispatch(_region, _sends_away, {})


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN and get_child_count() > 0:
		_place(get_child(0))
	if what == NOTIFICATION_PREDELETE:
		_ui.chimes.stop_all(self)


## The piece at its least size under the rect, or over it where the foot
## is too near, held inside this every way.
func _place(piece: Control) -> void:
	var rect: Rect2 = _rect.read()
	var at := rect.position - get_global_rect().position
	var least := piece.get_combined_minimum_size()
	var under := at.y + rect.size.y
	var y := under if under + least.y <= size.y else at.y - least.y
	Shift.fit(self, piece, Rect2(clampf(at.x, 0.0, maxf(0.0, size.x - least.x)), clampf(y, 0.0, maxf(0.0, size.y - least.y)), least.x, least.y))
	var focus := get_viewport().gui_get_focus_owner()
	if is_visible_in_tree() and (focus == null or not is_ancestor_of(focus)):
		var first := _first_to_focus(piece)
		if first != null:
			first.grab_focus()


## The first control in what it holds that takes the focus now, in tree
## order - its own mode as its layer lets it, so none while the layer is
## shut to the focus; none where none does.
static func _first_to_focus(node: Node) -> Control:
	# every child, itself or searched within
	for child: Node in node.get_children():
		if child is Control and (child as Control).visible and (child as Control).get_focus_mode_with_override() != Control.FOCUS_NONE:
			return child
		var within := _first_to_focus(child)
		if within != null:
			return within
	return null


## It needs what the piece needs, and is given the whole of its holder.
func _get_minimum_size() -> Vector2:
	return get_child(0).get_combined_minimum_size() if get_child_count() > 0 else Vector2.ZERO


## The builder's door: set beside the rect, what it holds built into it.
static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"anchored_at").new(ui, desc.props["rect"], desc.props["sends_away"])
	ui.attach(made, parent, desc.facts)
	return made
