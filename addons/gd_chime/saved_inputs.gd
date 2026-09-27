extends RefCounted

const SaveShape := preload("save_shape.gd")

## The bindings as plain data: what a save holds, and whether what came back
## is bindings at all.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## KEEPING SETTINGS IS THE GAME'S, so the map (input_map.gd) hands out a
## Dictionary and takes one back and never opens a file. This is the shape
## that travels: each action's name as a plain string, against a list of the
## inputs it is on, each of those one device name and one whole number. Every
## piece of it survives a text - a file, a save service, a message - which is
## why nothing here is a StringName, an enumeration or an object.
##
## WHAT COMES BACK OFF A DISK IS NOT OURS. A save may be from an older build,
## hand-edited, or half written, so what is read back is CHECKED BEFORE ANY OF
## IT IS USED: a name that is no action, a value that is not a list, an input
## that names no device or carries no number, and the whole save is refused -
## the shape declared here, checked where every kept model's is (save_shape.gd).
## That is all-or-nothing on purpose - a map half from a save and half from
## the defaults is a state nobody can reason about, and the player would find
## some of their bindings back and some not with nothing said. A number read
## out of text comes back as a float, so the codes are made whole numbers
## again on the way in.
##
## Deliberately absent: a version, a migration, and any file at all.

## The two devices, which are also the one key an input carries.
const KEY := "key"
const PAD := "pad"


## Every action that is on an input, as plain data.
static func written(bound: Dictionary) -> Dictionary:
	var save: Dictionary = {}
	# every action bound to something, under its name as a plain string
	for action: StringName in bound:
		if not (bound[action] as Array).is_empty():
			save[String(action)] = bound[action].duplicate(true)
	return save


## The shape of what written() writes, naming only actions that are bound
## now (save_shape.gd): every name an action, every value a list of inputs,
## each of them one device and one number.
static func shape(bound: Dictionary) -> Callable:
	var named := SaveShape.one_of(bound.keys().map(func(action: StringName) -> String: return String(action)))
	var input := SaveShape.either([SaveShape.record({KEY: SaveShape.number()}), SaveShape.record({PAD: SaveShape.number()})])
	return SaveShape.keyed(named, SaveShape.list_of(input))


## One action's saved inputs, as the map holds them: each device a plain
## string and each code a whole number, whatever a text made of them.
static func inputs_of(save: Array) -> Array:
	var inputs: Array = []
	# every saved input of the one action
	for input: Dictionary in save:
		var device: String = String(input.keys()[0])
		inputs.append({device: int(input[device])})
	return inputs
