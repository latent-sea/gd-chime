extends RefCounted

const Themes := preload("../../theme.gd")
const Inputs := preload("../../input_map.gd")
const Ui := preload("../primitives/ui.gd")
const Desc := preload("../primitives/desc.gd")

## A hint: the key or button that presses an action, in words, beside the
## control that performs it.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## It reads the map (input_map.gd) through a bound value, so it is not a label
## written once: rebind the action and these words change where they stand,
## pick up a pad and every hint on the screen turns from the key to the button,
## and change the language and each names its key in it, the text saying the
## name as it draws - with nothing built again. An action on nothing for the device in hand says
## nothing at all, and the words are hidden rather than left empty, so a row
## does not hold a gap where a hint would be.
##
## It is words and no more. Which control it belongs beside, and whether that
## control shows one, is the caller's; a look for it is the Theme's, asked for
## by the style it is given.

## The input an action is on, in words, hidden while it is on none.
static func make(ui: Ui, action: StringName, style: StringName = Themes.REASON) -> Desc:
	return ui.text(ui.inputs.hint(action), style).hides_empty()
