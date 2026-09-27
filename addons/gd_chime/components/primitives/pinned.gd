extends "canvas.gd"

const Commands := preload("../../commands.gd")
const Going := preload("going.gd")
const Shift := preload("shift.gd")

## A drawing with parts pinned on it: a map, and a press standing on each
## of its regions. The drawing is a recipe's painter, as a canvas's is; each
## part stands centred on its own point of the drawing; and a press on the
## drawing itself picks whatever its hit function says lies there.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## POINTS ARE IN A UNIT SQUARE, (0, 0) its top left, so the data says where
## a thing is and never how big the screen is. The square is FITTED - the
## largest square this holds, in its middle - so a map is never stretched
## out of its shape by a wide or a tall window, and the painter draws into
## the same square (fitted()). A part is placed at its least size with its
## middle on its point, moved in where it would cross this one's edge.
##
## THE PARTS ARE WHAT THE KEYS AND THE PAD REACH: a region's press pinned
## on it is walked to by the engine's geometry like any other, so every
## region is reached without a pointer. The pointer may press the region's
## ground instead: a press here, on no part, dispatches the picks action
## with {"picked": what hit(point) answers, point in the unit square} - the
## payload a region's own press carries - or nothing on empty ground. Its
## place declares the picks action as it declares a pan_zoom's.
##
## The parts are this one's children, so nothing standing on the drawing is
## drawn over it: a part stands in its holder, as words on their button.

var _points: Array  # each part's point in the unit square, in the order built
var _commands: Commands
var _picks: StringName
var _hit: Callable


func _init(ui: RefCounted, paint: Callable, content: Variant, points: Array, picks: StringName, hit: Callable, in_region: StringName, style: StringName) -> void:
	super(ui.chimes, paint, content, in_region, style)
	_points = points
	_commands = ui.commands
	_picks = picks
	_hit = hit


## The square the unit square is drawn in: the largest this holds, in its middle.
static func fitted(size: Vector2) -> Rect2:
	var side := minf(size.x, size.y)
	return Rect2((size - Vector2(side, side)) / 2.0, Vector2(side, side))


## Where a part of this least size stands with its middle on this point,
## moved in to lie wholly within a rect of this size.
static func standing(point: Vector2, least: Vector2, size: Vector2) -> Rect2:
	var square := fitted(size)
	var middle := square.position + point * square.size
	var corner := (middle - least / 2.0).clamp(Vector2.ZERO, (size - least).max(Vector2.ZERO))
	return Rect2(corner, least)


## Sorted, every part stands on its point.
func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		var at := 0
		# every part, in the order built, on the point given for it
		for child: Node in get_children():
			if child is Control and not Going.is_going(child):
				Shift.fit(self, child, standing(_points[at], (child as Control).get_combined_minimum_size(), size))
				at += 1


## A press on the drawing - no part took it - picks what lies under it.
func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT):
		return
	var square := fitted(size)
	var picked: Variant = _hit.call(((event as InputEventMouseButton).position - square.position) / square.size)
	if picked != null:
		_commands.dispatch(region, _picks, {"picked": picked})


static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"pinned").new(ui, desc.props["paint"], desc.props["content"], desc.props["points"], desc.props["picks"], desc.props["hit"], ui.region(), desc.props["style"])
	ui.attach(made, parent, desc.facts)
	return made
