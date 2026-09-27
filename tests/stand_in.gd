extends "res://addons/gd_chime/action_control.gd"

## A stand-in for a button drawing an action, for the tests: a real control
## of its place that can take the focus, draws nothing, and, standing for the
## place's declaration too, writes its action and where it goes into the
## place as it is built - what a real place has set already, and a real
## button only reads. Nothing else.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.

var goes_to: StringName


func _init(chimes: Chimes, commands: Commands, place: Node, does: StringName, to: StringName = &"") -> void:
	goes_to = to
	if does != &"":
		place.performs[does] = to
		name = String(does)
	super(chimes, commands, place, does)
	focus_mode = Control.FOCUS_ALL


func _exit_tree() -> void:
	if action != &"":
		_place.performs.erase(action)


func refresh() -> void:
	pass
