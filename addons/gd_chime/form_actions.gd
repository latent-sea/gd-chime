extends RefCounted

const Chimes := preload("chimes.gd")
const Actions := preload("actions.gd")
const Question := preload("question.gd")

## The actions a form's controls press, named and declared in one place:
## one per question, one opening each choice and one typing into each
## searched choice, and the form's own - going to a step, to a question, on
## and back, saving the draft, sending, starting again.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A FORM IS DATA, SO ITS ACTIONS ARE MADE FROM IT: a question's key names
## its action (answers_<key>) and, for a choice, the press opening its
## overlay (chooses_<key>, opening the question's pop-up) and, where
## it is searched, the typing its narrowing answers (types_<key>). Each is
## worded as the question is, so the palette, a hint and a translator read
## the question's own words. declare() puts every one in the register and
## has the door tell the form - or a searched choice's narrowing - from
## anywhere; a caller declares nothing per question.
##
## NEXT and PREVIOUS are presses going to a step, declared by each step's
## place where it is described, and CLOSES a press leaving the form for
## where the caller says, so none needs anyone to answer it; LEAVES_WITHOUT_SAVING is
## the way on from the question asked before unsaved answers are left
## (confirm.gd, for_leaving), the form letting them go as it goes; the caller
## gives their keys and pad buttons, as it gives the form's own.

const ANSWERS := "answers_"
const CHOOSES := "chooses_"
const TYPES := "types_"
const SAVES_DRAFT := &"saves_the_draft"
const SENDS := &"sends_the_form"
const STARTS_AFRESH := &"starts_afresh"
const SHOWS_STEP := &"shows_the_step"
const SHOWS_QUESTION := &"shows_the_question"
const NEXT := &"goes_to_the_next_step"
const PREVIOUS := &"goes_to_the_step_before"
const CLOSES := &"closes_the_form"
const LEAVES_WITHOUT_SAVING := &"leaves_without_saving"
## The form's own actions, which it answers.
const COMMANDS: Array[StringName] = [SAVES_DRAFT, SENDS, STARTS_AFRESH, SHOWS_STEP, SHOWS_QUESTION, LEAVES_WITHOUT_SAVING]
## The words of every action the form declares of its own, in English.
const OWN_WORDS := {SAVES_DRAFT: "Save as draft", SENDS: "Send", STARTS_AFRESH: "Start again", SHOWS_STEP: "Go to the step", SHOWS_QUESTION: "Change", NEXT: "Next", PREVIOUS: "Back", CLOSES: "Close", LEAVES_WITHOUT_SAVING: "Leave without saving"}


## The action answering a question.
static func answering(key: StringName) -> StringName:
	return StringName(ANSWERS + key)


## The press opening a choice's overlay, and the overlay's place.
static func chooses(key: StringName) -> StringName:
	return StringName(CHOOSES + key)


## The typing a searched choice's narrowing answers.
static func types(key: StringName) -> StringName:
	return StringName(TYPES + key)


## Every action of this form declared, worded, on the inputs given for the
## form's own, and told from anywhere: the form's to the form, a searched
## choice's typing to its narrowing.
static func declare(form: Object, register: Actions, door: Object, inputs: Dictionary) -> void:
	var table: Dictionary = {}
	# every question: its answer, and a choice's opening and typing
	for question: Dictionary in form.get_questions():
		var words := str(question["words"])
		table[answering(question["key"])] = [words]
		door.register(Chimes.GLOBAL, answering(question["key"]), form)
		if question["kind"] == Question.CHOICE:
			table[chooses(question["key"])] = [words]
		if question["search"]:
			table[types(question["key"])] = [words]
			door.register(Chimes.GLOBAL, types(question["key"]), form.narrowing(question["key"]))
	# the form's own, with the inputs the caller gives them
	for action: StringName in OWN_WORDS:
		table[action] = [OWN_WORDS[action]] + inputs.get(action, [])
		if COMMANDS.has(action):
			door.register(Chimes.GLOBAL, action, form)
	register.declare_all(table)
