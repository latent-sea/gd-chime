extends RefCounted

const Themes := preload("../../theme.gd")
const Ui := preload("../primitives/ui.gd")
const Options := preload("../primitives/options.gd")
const Desc := preload("../primitives/desc.gd")
const Fields := preload("../../theme_fields.gd")

## A text area: words a reader writes at length - feedback, a note - under
## its label, sent by a press of its own. Beside text_field.gd, which is
## the same shape for one line sent by Enter; here Enter breaks the words,
## so it cannot send them.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE MODEL HOLDS THE WORDS. Every change goes through the door as the
## change action, {"text": the words}, and the area shows what the model
## holds (area.gd); the press beneath is the send action, carrying nothing,
## since the model already holds what it sends - and once it has sent them
## it clears them, and the area follows. Whether the words may go is the
## model's would(): the button is a button (bell_button.gd), inert while
## the door refuses it, and its reason said on its face - nothing typed
## yet, too long, already sent - never in a tooltip a pad cannot reach.
## The label and what the area is for go to the text in English.

## Its options: label, the words over the area; holds, the bound value it
## shows; says, a line under the label saying what the area is for;
## takes_focus, for an area typed into as it is built; and style.
const OPTIONS: Array[String] = ["label", "holds", "says", "takes_focus", Options.STYLE]


## The area: the label, the line saying what it is for when there is one,
## the area showing the words held, and the press that sends them.
static func make(ui: Ui, changes: StringName, sends: StringName, options: Dictionary = {}) -> Desc:
	Options.checked("a text area", options, OPTIONS)
	var parts: Array = [ui.text(options["label"], Themes.FACE)]
	if options.get("says") != null:
		parts.append(ui.text(options["says"], Themes.REASON).wraps())
	var written: Desc = ui.area(changes, options["holds"], Fields.TEXT_AREA)
	parts.append(written.takes_focus() if options.get("takes_focus", false) else written)
	parts.append(ui.row([ui.button(sends)]))
	return ui.column(parts, options.get(Options.STYLE, &"Column"))
