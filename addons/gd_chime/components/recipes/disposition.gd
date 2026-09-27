extends RefCounted

const Themes := preload("../../theme.gd")
const Ui := preload("../primitives/ui.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Phrase := preload("../../phrase.gd")

## A disposition: the single control on an item saying what it will do
## this cycle, with the second half that choice needs beside it - one per
## available choice, each with its own second half, and INERT where the
## phase does not allow that choice yet.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## One control because there is one disposition: the picker is a row of
## pressables, one per choice, each its own action the model answers and
## refuses by phase - an inert one says why. The second half is part of
## the choice: the description for the chosen one shows beside the picker,
## and the model says the control is not satisfied until it is answered.


## The picker over these choices, {action -> second half description or
## null}, and the second half of the one the model says is chosen.
static func make(ui: Ui, item: Object, choices: Dictionary, style: StringName = &"Disposition") -> Desc:
	var picker: Array = []
	for action: StringName in choices:
		picker.append(ui.button(action, {style = &"Choice"}).grow())
	var halves: Array = []
	var chosen: Bound = ui.bound(item.get_chosen)
	# the second half of each choice, shown while that choice is the one chosen
	for action: StringName in choices:
		if choices[action] != null:
			halves.append(ui.when(chosen.map(func(picked: Variant) -> bool: return picked == action), choices[action]))
	var unanswered: Bound = ui.bound(item.get_satisfied).map(func(done: Variant) -> Variant: return "" if done == null or done else Phrase.of("The choice is not finished"))
	return ui.column([ui.row(picker, &"Picker"), ui.stack(halves), ui.text(unanswered, Themes.REASON).hides_empty()], style)
