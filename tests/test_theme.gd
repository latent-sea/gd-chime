extends SceneTree

## What must be true of the look.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_theme.gd
##
## The look is the engine's Theme built from our palette. Two things are ours
## to promise: every colour in the palette is in the theme under the one type
## a screen asks by, and a control under a root wearing it reads that colour.
## What a screen does with a colour it asks for is proved in test_controller.gd.

const Themes := preload("res://addons/gd_chime/theme.gd")
const Verdict := preload("res://tests/verdict.gd")

var _verdict := Verdict.new()


func _init() -> void:
	await _verdict.states(_every_colour_of_the_palette_is_in_the_look)
	await _verdict.states(_a_control_under_a_root_wearing_it_reads_the_look)
	quit(_verdict.deliver(get_script()))


func _every_colour_of_the_palette_is_in_the_look() -> void:
	# a whole palette, since the button's defaults are built from it, with two colours of our own
	var palette: Dictionary = Themes.NEUTRAL.duplicate()
	palette[&"ink"] = Color(1, 0, 0)
	palette[&"ground"] = Color(0, 0, 1)
	var look := Themes.new(palette)

	_verdict.check(look.get_color(&"ink", Themes.LOOK) == Color(1, 0, 0), "a colour is in under its name")
	_verdict.check(look.get_color(&"ground", Themes.LOOK) == Color(0, 0, 1), "and so is the other")
	_verdict.check(not look.has_color(&"nope", Themes.LOOK), "and a name the palette did not have is not")


## The root wears the look and the engine carries it down, so a control asks
## for a colour and never holds the theme.
func _a_control_under_a_root_wearing_it_reads_the_look() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	var control := Control.new()
	root.add_child(control)

	_verdict.check(control.get_theme_color(&"ink", Themes.LOOK) == Themes.NEUTRAL[&"ink"], "a control under the root reads the look")
	control.free()
