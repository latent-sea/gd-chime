extends RefCounted

const Themes := preload("../../theme.gd")
const Driver := preload("../../driver.gd")
const Ui := preload("../primitives/ui.gd")
const Options := preload("../primitives/options.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Sheet := preload("sheet.gd")

## A confirm: asking "are you sure" before a press that cannot be undone -
## a pop-up holding the consequence in words and the two ways out of it,
## opened by a button of the asking action (describe_places.gd: button).
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE CONFIRMED PRESS IS THE ORDINARY COMMAND: the same action, the same
## handler. Nothing about it knows it was confirmed, so a command is never
## written twice, and whether a thing is confirmed is a question of how it
## is described and of nothing else.
##
## ONE CONFIRM SERVES EVERY ROW. The question is a pop-up, described once,
## and a pop-up is entered as one of its kind: a row's button opens it WITH
## THE ROW'S ID, and the confirmed press carries that id under the name the
## command expects - so a list of a hundred rows has a hundred buttons and
## one question. The consequence may read it too, as a function of which one
## it was opened as: "Delete the entry named so?". Opened as none, it asks
## about the one thing there is and the press carries nothing.
##
## The asking is a pop-up because it must block: an overlay takes the input
## and covers everything beneath, so the question cannot be walked around
## with the keys or the pad while it stands.
##
## The confirm and the cancel both go BACK, which lowers the question, so it
## closes itself either way and the reader lands on the opener again. THE
## CANCEL IS THE POP-UP'S OWN WAY OUT (describe_places.gd: CLOSES), which no
## model answers, as the shade is. A REFUSED COMMAND LEAVES THE QUESTION UP -
## the refusal is the door's answer and the move is the step after it, never
## reached - and the confirm says why on its own face.
##
## THE CANCEL IS FIRST, so the focus lands on it as the question opens: a
## place with nothing remembered focuses the first thing under it that can
## be focused, and the dangerous press is never the one under the thumb.
##
## THE WORDS WRAP at the width the sheet gives them, so a long consequence
## runs onto more lines inside the sheet, never past the window's edge nor
## stretching the sheet past its share, whatever the window's shape.
##
## ONE QUESTION SERVES EVERY PLACE THAT ASKS BEFORE IT IS LEFT (for_leaving),
## handed to each such screen, and it has no opener: the leave guard raises
## it (leave_guard.gd), entered as the move it stopped, which carries the
## words the guard asked. The cancel goes BACK, lowering the question and
## nothing else, and the confirm goes ONWARD carrying the stopped move, which
## the driver makes after all. Neither needs a handler.

## What a confirm's pop-up is of, in its name.
const KIND := &"confirm"


## The question: the consequence - a phrase, or a function of which one it
## was opened as, a bound value, answering the words - and the confirmed
## press of this action, carrying {carries: which one} where it was opened
## as one.
## Its options: carries, which key of the parameter the press carries, and
## style.
const OPTIONS: Array[String] = ["carries", Options.STYLE]

static func make(ui: Ui, consequence: Variant, action: StringName, options: Dictionary = {}) -> Desc:
	Options.checked("a confirmation", options, OPTIONS)
	var carries: String = options.get("carries", "id")
	var style: StringName = options.get(Options.STYLE, &"Confirm")
	return ui.pop_up(KIND, _question.bind(ui, consequence, action, carries, style))


## The one question every place asking before it is left may be handed: the
## words its guard asked as the move was stopped - none before any was - the
## cancel back where the reader stood, and the confirm going on with the
## move it was raised about.
static func for_leaving(ui: Ui, proceeds: StringName, style: StringName = &"Confirm") -> Desc:
	return ui.pop_up(KIND, _leaving.bind(ui, proceeds, style))


## The question for which one it was opened as.
static func _question(which: Bound, ui: Ui, consequence: Variant, action: StringName, carries: String, style: StringName) -> Desc:
	var carried: Bound = which.map(func(one: Variant) -> Dictionary: return {} if one == null else {carries: one})
	return _asked(ui, consequence.call(which) if consequence is Callable else consequence, ui.button(action, {payload = carried, goes_to = Driver.BACK}), style)


## The question for the move it stopped.
static func _leaving(stopped: Bound, ui: Ui, proceeds: StringName, style: StringName) -> Desc:
	var words: Bound = stopped.map(func(move: Variant) -> Variant: return null if move == null else move["asks"])
	var carried: Bound = stopped.map(func(move: Variant) -> Dictionary: return {"parameter": move})
	return _asked(ui, words, ui.button(proceeds, {payload = carried, goes_to = Driver.ONWARD}), style)


## The question on a sheet over everything (sheet.gd): the words - a phrase
## or a bound value reading one, wrapping at the width the sheet gives them -
## and the ways out, the pop-up's own first.
static func _asked(ui: Ui, words: Variant, confirmed: Desc, style: StringName) -> Desc:
	return Sheet.over(ui, [ui.text(words, Themes.WORDS).wraps(), ui.row([Sheet.close(ui), confirmed])], style)
