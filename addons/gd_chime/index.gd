extends RefCounted

const Chart := preload("chart.gd")
const ActionControl := preload("action_control.gd")

## The index: every place in the tree by name, what each declares it
## performs, and the chart read from them.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE TREE FILLS THE INDEX; NOBODY WRITES IT BY HAND. A place adds itself
## as it enters the tree and takes itself out as it leaves (place.gd), under
## its unique name - a second of one name is refused out loud, the first
## keeps it, and the refusal is kept for the startup check to report. THE
## INDEX HOLDS PLACES ONLY: what a place performs is the place's own
## declaration, read here by name for the questions (queries.gd), and no
## button is ever indexed, since routing never asks one.
##
## THE CHART is read from the places here: the app root's name, every
## place's child places in order, every place's parent, and the kind of
## every root beside the app; read again only once a place has entered or
## left. The app root is an attribute, set by whoever builds the window
## before the first arrival.
##
## Deliberately absent: where the reader is, which is the driver's state;
## what a move does, which is the chart's; and every question over a state.

## The root place of the application. Set before the first arrival.
var app: Control

var _places: Dictionary = {}  # name -> the place
var _refused: Array[String] = []  # every place name refused as a second of one name, in order
var _chart: Dictionary = {}  # the chart read from the places, read again once one has entered or left


## A place entering the tree, indexed by its name - refused out loud when
## another place has the name, which keeps it, and remembered as refused.
func add_place(place: Node) -> void:
	if _places.has(place.name):
		push_error("two places are named %s; the first keeps the name" % place.name)
		_refused.append(place.name)
		return
	_places[place.name] = place
	_chart = {}


## A place leaving the tree, taken out - unless another of the name kept it.
func remove_place(place: Node) -> void:
	if _places.get(place.name) == place:
		_places.erase(place.name)
		_chart = {}


## The place with this name - refused out loud for a name that is no place.
func place_named(named: StringName) -> Node:
	if not _places.has(named):
		push_error("%s is no place" % named)
		return null
	return _places[named]


func has_place(named: StringName) -> bool:
	return _places.has(named)


func is_place(node: Node) -> bool:
	return _places.get(node.name) == node


## Every place by its name, the one dictionary, for the applier to read.
func by_name() -> Dictionary:
	return _places


func places() -> Array:
	return _places.values()


## The names refused as a second place of one name, in order.
func refused_names() -> Array[String]:
	return _refused.duplicate()


## What every place declares it performs, by name: action to where it goes.
func performs() -> Dictionary:
	var declared: Dictionary = {}
	# every place, its declaration
	for named: StringName in _places:
		declared[named] = _places[named].performs
	return declared


## The nearest place above this node, or nothing at the root of a layer.
func place_above(node: Node) -> Node:
	var above := node.get_parent()
	# up the tree, for the first place
	while above != null and not is_place(above):
		above = above.get_parent()
	return above


## The chart read from the places: the app root, every place's child places
## and parent, and the kind of every root beside the app.
func chart() -> Dictionary:
	if not _chart.is_empty():
		return _chart
	var children: Dictionary = {}
	var parent: Dictionary = {}
	var kind: Dictionary = {}
	# every place: its children by name, its parent, and its kind when it is a root beside the app
	for place: Node in _places.values():
		var named: Array = []
		for child: Node in place.places():
			named.append(child.name)
		children[place.name] = named
		var above := place_above(place)
		parent[place.name] = above.name if above != null else &""
		if place != app and above == null:
			kind[place.name] = Chart.OVERLAY if place.blocks else Chart.PANEL
	_chart = {"app": app.name, "children": children, "parent": parent, "kind": kind}
	return _chart


## Whether a control under this place, not one under a place within it,
## draws the action.
func draws(place: Node, action: StringName) -> bool:
	return drawn_by(place, action) != null


## The control under this place, not one under a place within it, that
## draws the action - the first in tree order; nothing when none does.
func drawn_by(place: Node, action: StringName) -> Node:
	# every child that is not a place of its own, itself or searched within
	for child: Node in place.get_children():
		if is_place(child):
			continue
		if child is ActionControl and child.action == action:
			return child
		var within := drawn_by(child, action)
		if within != null:
			return within
	return null
