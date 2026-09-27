extends "../../face.gd"

const Local := preload("local.gd")

## A local press: a face whose press sets a local, and does nothing else.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A press calls the local's set_value with the value it gives - a plain
## one, or a bound one read as the press lands, as a row's is - or, given
## a function, with the function's answer to the value as it is now, which
## is how one press turns a thing on and the next turns it off. IT IS NOT AN
## ACTION CONTROL: its place declares nothing for it, no door is asked, so
## it is never refused; no prompt names it, so it never glows; no input of
## the map reaches it, since it has no action to be reached by.
##
## Its states are its own, over the face's hover and normal: SELECTED, while
## the value it gives is the local's - the chosen option of a choice - or,
## giving a function, while the local reads true - a node opened out.
## Current, glowing and inert are the driver's, the prompts' and the door's,
## and none of them is here.

var _local: Local
var _gives: Variant


func _init(chimes: Chimes, in_region: StringName, local: Local, gives: Variant, style: Variant) -> void:
	super(chimes, in_region, style)
	_local = local
	_gives = gives


## Whether this is the one chosen, or the thing turned on.
func is_selected() -> bool:
	return is_same(_local.read(), true) if _gives is Callable else _local.read() == _given()


func pressed() -> void:
	_local.set_value(_gives.call(_local.read()) if _gives is Callable else _given())


## The value it gives: a bound one as it reads now.
func _given() -> Variant:
	return _gives.read() if _gives is Bound else _gives


func get_state() -> StringName:
	return &"selected" if is_selected() else super.get_state()


## The builder's door: a local press in the region of the place being built into.
static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"press_local").new(ui.chimes, ui.region(), desc.props["local"], desc.props["gives"], desc.props["style"])
	ui.attach(made, parent, desc.facts)
	return made
