extends RefCounted

const Themes := preload("../../theme.gd")
const Question := preload("../../question.gd")
const Ui := preload("../primitives/ui.gd")
const Options := preload("../primitives/options.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")

## An amount field: where an amount the reader is committing is entered -
## and only where the reader sets the number. The unit's mark stands before
## the field, and Enter commits the line as the action.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## GIVEN WHAT THE MODEL HOLDS, the field shows it and every change goes
## through the door: {"value": the amount the line reads as, or null where it
## reads as none, "line": the line} - what a typed day carries too - so a
## model may hold a half-typed line and never lose it (a form's answer), or
## refuse a line that is no amount and have it said under the field. The
## line is read the language's way (question.gd's amount_of): its thousands
## marks set aside, its fraction mark a point. What the model holds is shown
## as it is: a line as typed, a number written plainly, as typing reads it.
## Given nothing, the field is as it always was: empty, and Enter commits
## the line as it stands.


## Its options: holds, a bound value the line shows, and style.
const OPTIONS: Array[String] = ["holds", Options.STYLE]

static func make(ui: Ui, action: StringName, mark: String, options: Dictionary = {}) -> Desc:
	Options.checked("an amount field", options, OPTIONS)
	var holds: Variant = options.get("holds")
	var style: StringName = options.get(Options.STYLE, &"AmountField")
	if holds == null:
		return ui.row([ui.text(mark, Themes.FACE), ui.field(action, &"Field").grow()], style)
	var shown: Bound = holds.map(func(held: Variant) -> String: return "" if held == null else held if held is String else String.num(held))
	var carries := func(line: String) -> Dictionary: return {"value": Question.amount_of(line), "line": line}
	return ui.row([ui.text(mark, Themes.FACE), ui.field(action, &"Field", {"shows": shown, "changes": action, "carries": carries}).grow()], style)
