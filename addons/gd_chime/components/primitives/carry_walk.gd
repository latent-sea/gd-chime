extends RefCounted

const Carried := preload("../../carried.gd")

## How the keys and the pad move a carry: across drop targets, or through
## the places of the lists a target stands for.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A CARRY WITH NO LIST - a crate lifted towards a basket - WALKS THE FOCUS
## across drop targets and NOTHING else: the engine's own neighbour that
## way where it is a target - geometry, the same answer arrows give anywhere
## else - and else the nearest target of the same layer whose centre lies
## more that way than across, since the engine's neighbour can be an
## ordinary control closer by an edge with no neighbour of its own beyond.
## The direction is spent whether one was found or not, so the walk cannot
## leave the targets. Cancel puts it back.
##
## A CARRY FROM A LIST - a card lifted out of a column - KEEPS THE FOCUS ON
## THE THING CARRIED and moves where it would land (carried.gd's over): along
## the list a direction steps it one place, held between the first place
## and the last; across it, it goes to the nearest list target that way, at
## the same place or the last there is. Accept drops it where it is over,
## and cancel puts it back. The thing is drawn where it would land, so the
## reader sees it travel under their hand.
##
## The targets are found by their mark, the engine's own group, in the layer
## the carry began in: nothing is held. A layer is a child of the root the
## builder builds under, where the carry itself stands (ui.gd) - the app, or
## a pop-up - so a carry never walks into another app, whose root is a canvas
## of its own, nor under a pop-up, which is a layer of its own.

## The mark every drop target wears, a list target's too; and the mark on the draggable being carried.
const TARGET := &"drop target"
const LIFTED := &"lifted piece"
## Each direction a carry moves, and the side of a control it moves from.
const SIDES := {&"ui_left": SIDE_LEFT, &"ui_right": SIDE_RIGHT, &"ui_up": SIDE_TOP, &"ui_down": SIDE_BOTTOM}
## The way each side lies, on the screen.
const WAYS := {SIDE_LEFT: Vector2.LEFT, SIDE_RIGHT: Vector2.RIGHT, SIDE_TOP: Vector2.UP, SIDE_BOTTOM: Vector2.DOWN}


## The carry moved from this control by the pad or the keys, with no list:
## cancel puts it back, and a direction takes the focus to the next drop
## target that way - and nowhere at all, rather than out, when there is
## none. Answers whether the event was the carry's.
static func walked(from: Control, event: InputEvent, carried: Carried) -> bool:
	if event.is_action_pressed(&"ui_cancel"):
		carried.put_back()
		return true
	# each direction there is, matched against the event that arrived
	for named: StringName in SIDES:
		if event.is_action_pressed(named):
			var neighbour := from.find_valid_focus_neighbor(SIDES[named])
			var next: Control = neighbour if neighbour != null and neighbour.is_in_group(TARGET) else nearest(from, SIDES[named], carried, func(_target: Control) -> bool: return true)
			if next != null:
				next.grab_focus()
			return true
	return false


## The carry of a list's piece moved by the pad or the keys: along the list
## a step, across it to the next list, accept to drop, cancel to put back.
## Answers whether the event was the carry's.
static func stepped(from: Control, event: InputEvent, carried: Carried) -> bool:
	if event.is_action_pressed(&"ui_cancel"):
		carried.put_back()
		return true
	var over := carried.get_over()
	var here := list_target(from, over["into"], carried)
	if event.is_action_pressed(&"ui_accept"):
		here.drop()
		return true
	# each direction there is, matched against the event that arrived
	for named: StringName in SIDES:
		if not event.is_action_pressed(named):
			continue
		var side: Side = SIDES[named]
		if here.runs_along(side):
			# a step toward the end of the list or back toward its start, held between its first place and its last
			var step := 1 if side == SIDE_RIGHT or side == SIDE_BOTTOM else -1
			carried.move_over(over["into"], clampi(over["at"] + step, 0, here.count_shown()))
		else:
			var next := nearest(here, side, carried, func(target: Control) -> bool: return target.is_list())
			if next != null:
				carried.move_over(next.get_into(), mini(over["at"], next.count_shown()))
		return true
	return false


## The list target standing for this list, in the layer this control stands in.
static func list_target(from: Control, into: Variant, carried: Carried) -> Control:
	# every target in the layer, for the list's own
	for target: Node in _in_layer(from, carried):
		if target.is_list() and target.get_into() == into:
			return target
	return null


## The nearest target in the layer, of those this takes, whose centre lies
## more that way than across from this control's - none, if none does.
static func nearest(from: Control, side: Side, carried: Carried, takes: Callable) -> Control:
	var way: Vector2 = WAYS[side]
	var centre := from.get_global_rect().get_center()
	var found: Control = null
	# every target standing in the layer, for the nearest lying that way
	for target: Control in _in_layer(from, carried):
		if target == from or not target.is_visible_in_tree() or not takes.call(target):
			continue
		var off: Vector2 = target.get_global_rect().get_center() - centre
		# more that way than across it: a target level with this, or beyond it, and not off to one side
		if off.dot(way) > absf(off.dot(Vector2(way.y, way.x))) and (found == null or off.length() < (found.get_global_rect().get_center() - centre).length()):
			found = target
	return found


## Every target marked in the layer this control stands in: under the same
## child of the builder's root - the app, or a pop-up - whose targets alone
## are reachable. The carry stands under that root, so its parent is it.
static func _in_layer(from: Control, carried: Carried) -> Array:
	var layer: Node = from
	# up to the child of the builder's root this stands in
	while layer.get_parent() != carried.get_parent():
		layer = layer.get_parent()
	return from.get_tree().get_nodes_in_group(TARGET).filter(func(target: Node) -> bool: return layer.is_ancestor_of(target))
