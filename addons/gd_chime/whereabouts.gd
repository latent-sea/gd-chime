extends "controller.gd"

const Index := preload("index.gd")
const Chart := preload("chart.gd")
const Kept := preload("kept.gd")

## Where the reader is: the index, the state, and every read of them - the
## layer that takes input, whether a pop-up is up, the layer a node is in,
## which one of its kind a place is entered as, whether Back can act - and
## what is kept with the view the reader is on.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE DRIVER (driver.gd) EXTENDS THIS AND IS THE ONE THING THAT MOVES THE
## STATE: a move it runs through the chart replaces the state whole, and
## lets go of what was kept with every entry the history no longer holds
## (kept.gd). Everything here reads, and every listener that hears the
## driver's bell asks here where the reader is now - a pressable whether it
## is current, the sounds whether a pop-up came up, a scroll where it stood
## on this view, a question which move it was raised about - so how a move
## is made and how the result is read never share a line. It extends the
## controller only because the driver is one.
##
## EVERY READ OF WHERE THE READER IS NOTES NAVIGATED (reads.gd), the bell the
## driver rings once a move is carried out: a control drawing from here, or a
## refusal asked of the chart as it draws, is drawn again as the reader
## moves, and lists nothing. The state is read through where() for that.

const Reads := preload("reads.gd")

## Rung once a move is carried out, every effect of it done.
const NAVIGATED := &"navigated"

## What exists: every place, kept by the tree.
var index := Index.new()

var _state: Dictionary = Chart.blank()  # where the reader is and has been, one plain value, replaced whole by every move - read through where()
var _kept := Kept.new()  # what is kept with each history entry


## The state, for a read of it: NAVIGATED noted for whoever is reading.
func where() -> Dictionary:
	Reads.note(region, NAVIGATED)
	return _state


## Which one of its kind a place is entered as now, or nothing.
func get_parameter(place: StringName) -> Variant:
	return where()["params"].get(place)


## IN-PROGRESS STATE KEPT WITH THE HISTORY ENTRY: a plain value kept under
## a name for the entry the reader is on now, so a detour and Back find it
## intact; let go with the entry when the history drops it - gone Back
## past, over the cap, forgotten (kept.gd). A kept thing is a RefCounted, freed by being let go; a Node
## would leak, and is refused out loud and not kept.
func keep(name: StringName, kept: Object) -> void:
	_kept.keep(Kept.entry_of(_state), name, kept)


## What was kept under this name for the view the reader is on, or nothing.
func kept(name: StringName) -> RefCounted:
	return _kept.kept(Kept.entry_of(where()), name)


## The state, as a copy: where the reader is and has been.
func get_state() -> Dictionary:
	return where().duplicate(true)


## The path of the layer this node is in: the overlay or the panel whose
## root is above it or is it, else the app's - and nothing for a root not up.
func path_of(node: Node) -> Array[StringName]:
	# every layer up, for the one whose root holds this node
	for layer: Array in where()["overlays"] + [_state["panel"]]:
		if not layer.is_empty() and _holds(index.place_named(layer[0]), node):
			return _typed(layer)
	if _holds(index.app, node):
		return _typed(_state["path"])
	return _typed([])


## The path of the layer that takes input: the top overlay's, else the app's.
func get_top() -> Array[StringName]:
	return _typed(where()["overlays"].back() if is_raised() else _state["path"])


func is_raised() -> bool:
	return not where()["overlays"].is_empty()


func can_go_back() -> bool:
	return Chart.can_go_back(where())


func _is_active(named: StringName) -> bool:
	# every active path, for the name
	for path: Array in _state["overlays"] + [_state["panel"], _state["path"]]:
		if path.has(named):
			return true
	return false


static func _holds(root: Node, node: Node) -> bool:
	return root == node or root.is_ancestor_of(node)


static func _typed(path: Array) -> Array[StringName]:
	var typed: Array[StringName] = []
	typed.assign(path)
	return typed
