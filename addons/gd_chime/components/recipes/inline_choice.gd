extends RefCounted

const Themes := preload("../../theme.gd")
const Ui := preload("../primitives/ui.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Local := preload("../primitives/local.gd")
const Pressables := preload("../../theme_pressables.gd")

## A short choice laid out inline, with no overlay: a RADIO GROUP, a column
## of options, and a SEGMENTED CONTROL, a row of joined ones.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## ONE OPTION IS SELECTED THROUGH A BOUND STYLE: each option wears the
## chosen look while its value is the one chosen and the plain look while it
## is not, re-read on the chosen value's bells and worn in place - the same
## options, never built again. The chosen look carries a mark as well as a
## ground (theme_pressables.gd), so the choice is never told by hue alone.
##
## A PICK GOES THROUGH THE DOOR OR SETS A LOCAL. Given an action, each
## option is a pressable carrying {"value"} - the payload a choice, a slider
## and a stepper carry - and what is chosen is the model's bound value,
## which the door may refuse to move, leaving the refused option inert and
## saying why as any pressable does. Given a local, the choice is the
## interface's alone - which of two views shows - and each option is a local
## press setting it, through no door, the local's own value what is chosen.
##
## The options are {value, words} entries of a bound array, kept by value,
## the words a phrase or the model's data. The pad and the keys move along
## the options as along any column or row, the engine doing the moving:
## up and down a radio group, left and right a segmented control.
##
## Deliberately absent: an option that holds more than its words.


## A column of options, one of them chosen: picking through the door with
## this action, or setting this local, whose own value is then the chosen one.
static func radios(ui: Ui, picks: Variant, offers: Bound, chosen: Bound = null) -> Desc:
	var options: Bound = offers
	var style := Themes.COLUMN
	return ui.each(options, _option(ui, picks, chosen, Pressables.RADIO, Pressables.RADIO_CHOSEN), _value_of, style)


## A row of joined options, one of them chosen, picked as a radio group's are.
static func segments(ui: Ui, picks: Variant, offers: Bound, chosen: Bound = null) -> Desc:
	var options: Bound = offers
	var style := Pressables.SEGMENTS
	return ui.each_across(options, _option(ui, picks, chosen, Pressables.SEGMENT, Pressables.SEGMENT_CHOSEN), _value_of, style)


## The template of one option: its words, worn chosen while its value is
## the chosen one, and a press through the door or of the local.
static func _option(ui: Ui, picks: Variant, chosen: Bound, style: StringName, chosen_style: StringName) -> Callable:
	# a local's value read on no bells of its own: its press hears the local already, and draws its look again as it does
	var picked: Bound = picks if picks is Local else chosen
	return func(item: Bound) -> Desc:
		var worn: Bound = Bound.both(item, picked, func(one: Variant, now: Variant) -> StringName: return chosen_style if one != null and one["value"] == now else style)
		var words := [ui.text(item.field("words"), Themes.FACE)]
		if picks is Local:
			return ui.press_local(picks, item.field("value"), words, worn)
		return ui.pressable(picks, item.map(func(one: Variant) -> Dictionary: return {} if one == null else {"value": one["value"]}), words, worn)


## What an option is kept by: its value.
static func _value_of(item: Dictionary) -> Variant:
	return item["value"]
