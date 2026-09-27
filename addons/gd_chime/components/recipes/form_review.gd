extends RefCounted

const Themes := preload("../../theme.gd")
const Fields := preload("../../theme_fields.gd")
const FormActions := preload("../../form_actions.gd")
const Phrase := preload("../../phrase.gd")
const Ui := preload("../primitives/ui.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Pressables := preload("../../theme_pressables.gd")

## What a form says back to its reader: the SUMMARY of what needs
## attention, each problem a press taking the reader to its question, and
## the REVIEW of every answer, step by step, each a press taking the reader
## to change it.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## EVERY ITEM IS A PRESS OF ONE ACTION carrying the question's key, or the
## step's (form_actions.gd, SHOWS_QUESTION and SHOWS_STEP): the form takes
## the reader to the question's step entered as its key, where the focus
## lands on it (arrival_focus.gd). One template serves every problem and
## every answer, so a list built from the form's reads needs no press of
## its own per step. Pressed in the order they are read, the Tab key and
## the pad walk them as they stand.
##
## THE SUMMARY TAKES NO ROOM WHILE NOTHING NEEDS ATTENTION, and says how
## many things do; a step's own summary lists only the problems shown on it.
## The review writes each answer the reader's way (question.gd, written) -
## and, given no presses, is a record of what was sent.


## The summary of these problems - a bound list of {value, words, says} -
## under how many there are; nothing at all while there are none.
static func summary(ui: Ui, errors: Bound) -> Desc:
	var count: Bound = errors.map(func(all: Array) -> Variant: return Phrase.counted("%d answer needs attention", "%d answers need attention", all.size()))
	var listed := ui.each(errors, func(error: Bound) -> Desc: return _problem(ui, error), func(error: Dictionary) -> Variant: return error["value"])
	var box := ui.surface(Fields.SUMMARY, [ui.column([ui.text(count, Themes.FACE).wraps(), listed])])
	return ui.when(errors.map(func(all: Array) -> bool: return not all.is_empty()), box)


## The problems shown on one step of the form, in the order asked.
static func shown_on(form: Object, step: StringName) -> Bound:
	return Bound.both(Bound.new(form.get_errors), Bound.new(form.get_messages), func(errors: Array, shown: Dictionary) -> Array: return errors.filter(func(error: Dictionary) -> bool: return error["step"] == step and shown.has(error["value"])))


## Every answer of the form, step by step, each written back, a step's
## heading and each answer taking the reader to change it.
static func review(ui: Ui, form: Object) -> Desc:
	return _steps(ui, form, true)


## The same as the record of what was sent: nothing on it is pressed,
## because there is nothing left to change.
static func record(ui: Ui, form: Object) -> Desc:
	return _steps(ui, form, false)


## Every step written back, its heading and answers pressed or not.
static func _steps(ui: Ui, form: Object, presses: bool) -> Desc:
	var step := func(one: Bound) -> Desc:
		var heading: Array = [ui.text(one.field("words"), Themes.FACE).wraps().grow()]
		if presses:
			heading.append(ui.pressable(FormActions.SHOWS_STEP, one.map(_carried), [ui.text(ui.words(FormActions.SHOWS_STEP), Themes.FACE)], Pressables.BUTTON))
		var answers := ui.each(one.field("answers"), func(answer: Bound) -> Desc: return _answer(ui, answer, presses), func(answer: Dictionary) -> Variant: return answer["value"])
		return ui.surface(Fields.REVIEW_STEP, [ui.column([ui.row(heading), answers])])
	return ui.each(ui.bound(form.get_review), step, func(one: Dictionary) -> Variant: return one["value"])


## One problem: the question's words and what is wrong, pressed to go to it.
static func _problem(ui: Ui, error: Bound) -> Desc:
	var said: Bound = error.map(func(one: Variant) -> Variant: return null if one == null else Phrase.joined([one["words"], ": ", one["says"]]))
	return ui.pressable(FormActions.SHOWS_QUESTION, error.map(_carried), [ui.text(said, &"Paragraph").wraps()], &"Link")


## One answer: the question's words, the answer written back, and - given presses - the press to change it.
static func _answer(ui: Ui, answer: Bound, presses: bool) -> Desc:
	var parts: Array = [ui.text(answer.field("words"), Themes.REASON).wraps().basis(0.35), ui.text(answer.field("shown"), Themes.FACE).wraps().grow()]
	if presses:
		parts.append(ui.pressable(FormActions.SHOWS_QUESTION, answer.map(_carried), [ui.text(ui.words(FormActions.SHOWS_QUESTION), Themes.FACE)], Pressables.BUTTON))
	return ui.row(parts)


## What a press of an item carries: the key of its question or step.
static func _carried(item: Variant) -> Dictionary:
	return {} if item == null else {"value": item["value"]}
