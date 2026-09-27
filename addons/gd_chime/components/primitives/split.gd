extends Container

const Bound := preload("bound.gd")
const Shift := preload("shift.gd")

## A split: two panes side by side, or one over the other, and a grip
## between them that shares the room out - the resizable panels of an
## application shell.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## IT HOLDS NO SHARE. How much of the room the FIRST pane takes is a bound
## value, and which side is folded away - first, second or neither - is
## another; both are a model's (panels.gd). The grip (grip.gd), its middle
## child, is what the reader moves, and it moves the model through the door;
## this places the three wherever the model now says, and is placed again as
## either value moves.
##
## EVERY PANE KEEPS THE ROOM IT NEEDS. The first pane takes its share of the
## room the grip leaves, but never less than its own least size and never so
## much that the second has less than its own: so no pane is squeezed past
## what it can show, whatever the share says. A folded pane is hidden and
## takes nothing - its grip stays, at the edge, so a drag or a step brings it
## back. What the split needs itself is the grip and both least sizes along
## it, and the larger of the two across.
##
## ITS DIRECTION may be a bound value - a row in a wide window and a column
## in one on its end - read again as it moves; the grip turns with it.
##
## Deliberately absent: a least share of its own, and more than two panes,
## which is a split inside a pane.

const FIRST := &"first"
const SECOND := &"second"

var _ui: RefCounted
var _share: Bound
var _folded: Bound
var _down: Variant  # whether the panes stand one over the other: a bool, or a Bound reading one
var _room: float = 0.0  # the room the panes shared as last placed: the whole length but the grip


func _init(ui: RefCounted, share: Bound, folded: Bound, down: Variant) -> void:
	_ui = ui
	_share = share
	_folded = folded
	_down = down
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.chimes.follow(self, &"placing", _placing_moved)


## Whether the panes stand one over the other now.
func is_down() -> bool:
	return _down.read() if _down is Bound else _down


## The share the first pane takes now, as it is placed: the model's share
## held to each pane's least, over the room - nothing folded first, all of
## it folded second. Read from the model, not from the last placing, so a
## second key in one frame steps on from the first.
func get_placed_share() -> float:
	if _room <= 0.0:
		return 0.0
	var folded: StringName = _folded.read()
	return 0.0 if folded == FIRST else 1.0 if folded == SECOND else _within(_share.read() * _room) / _room


## What the placing reads, read, so it is followed; moved, placed again, and
## measured again, since which panes show moves what it needs.
func _placing_moved() -> void:
	is_down()
	_share.read()
	_folded.read()
	update_minimum_size()
	queue_sort()


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_place()
	if what == NOTIFICATION_PREDELETE:
		_ui.chimes.stop_all(self)


## The two panes and the grip placed along the split: the folded pane hidden,
## the first pane at its share of the room held between the two least sizes.
func _place() -> void:
	var folded: StringName = _folded.read()
	var first: Control = get_child(0)
	var second: Control = get_child(2)
	first.visible = folded != FIRST
	second.visible = folded != SECOND
	_grip().set(&"down", is_down())
	var thick := _along(_grip().get_combined_minimum_size())
	_room = maxf(0.0, _along(size) - thick)
	var first_length := get_placed_share() * _room
	Shift.fit(self, first, _rect(0.0, first_length))
	Shift.fit(self, _grip(), _rect(first_length, thick))
	Shift.fit(self, second, _rect(first_length + thick, _room - first_length))


## A length for the first pane held so each pane keeps the least it needs.
func _within(length: float) -> float:
	var least_first := _along(get_child(0).get_combined_minimum_size())
	var least_second := _along(get_child(2).get_combined_minimum_size())
	return clampf(length, least_first, maxf(least_first, _room - least_second))


## The grip, the middle one of the three.
func _grip() -> Control:
	return get_child(1)


## The grip and the least size of each pane showing along the split; the most any needs across it.
func _get_minimum_size() -> Vector2:
	if get_child_count() < 3:
		return Vector2.ZERO
	var along := 0.0
	var across := 0.0
	# the three, each one shown adding its least along and raising the least across
	for part: Control in [get_child(0), _grip(), get_child(2)]:
		if part.visible:
			along += _along(part.get_combined_minimum_size())
			across = maxf(across, _across(part.get_combined_minimum_size()))
	return Vector2(across, along) if is_down() else Vector2(along, across)


## The rect along the split from this far for this long, the whole way across.
func _rect(from: float, length: float) -> Rect2:
	return Rect2(0.0, from, size.x, length) if is_down() else Rect2(from, 0.0, length, size.y)


func _along(of: Vector2) -> float:
	return of.y if is_down() else of.x


func _across(of: Vector2) -> float:
	return of.x if is_down() else of.y


## The builder's door: the two panes and the grip described are its three children.
static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"split").new(ui, desc.props["share"], desc.props["folded"], desc.props["down"])
	ui.attach(made, parent, desc.facts)
	return made
