extends "res://addons/gd_chime/controller.gd"

## A gallery model: one whose facts are one value, and whose every command
## it answers itself.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Every read of a fact reads the value (value.gd), so whatever shows one
## follows this model; a fact changed in place is set again with moved().

var refusals: Dictionary = {}
## The facts by name: read through the value, so a read is followed.
var facts: Dictionary:
	get:
		return _facts.read()
var _facts := value({})


func _init(chimes: Chimes, first: Dictionary) -> void:
	super(chimes)
	_facts.set_value(first)


func would(action: StringName, _payload: Dictionary) -> Phrase:
	return refusals.get(action)


## A fact set, and the facts set again.
func set_fact(name: StringName, to: Variant) -> void:
	facts[name] = to
	moved()


## The facts changed in place: set again, for whatever reads them.
func moved() -> void:
	_facts.set_value(_facts.read())
