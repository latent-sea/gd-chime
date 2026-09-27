extends "answers.gd"

const Driver := preload("driver.gd")
const Actions := preload("actions.gd")
const Notifications := preload("notifications.gd")
const Narrowing := preload("narrowing.gd")
const FormActions := preload("form_actions.gd")

## A form of many steps: its answers held through the door, a draft saved,
## the reader asked before unsaved answers are left, taken to a step or a
## question, and the form sent - or the reader taken to the first thing
## stopping it.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## What the answers say is answers.gd's, which this extends; this is what is
## done to them, through the actions form_actions.gd names from the
## questions. A question's answer carries what its control puts in -
## {"value"} from a choice, a stepper or a pick, {"line"} from a typed line,
## both from a typed day or sum - and the line is what is held where there
## is one (question.gd). Holding is refused only for an answer that cannot be
## held at all; a rule an answer breaks is a problem held beside it, so a
## mistake never loses what was put in. A searched choice's typing is its own
## narrowing's (narrowing.gd), made here over the choice's options.
##
## EVERY STEP IS A PLACE NAMED BY ITS KEY, and the step the reader is on is
## the driver's: this hears NAVIGATED, and the step left is checked. Going to
## a step, {"value": its key}, and to a question, {"value": its key} - the
## question's step entered as the key, where the focus lands on it
## (arrival_focus.gd) - are moves the door makes from inside the press, as a
## dev command's are; so a list of problems or of answers, built from one
## template, needs no press per step.
##
## DIRTY IS THE ANSWERS AGAINST THE DRAFT SAVED. Saving makes them one; the
## settings file keeps the draft (saved(), restore()), following what saved() reads.
## While they differ, leaving the form asks first (would(Driver.LEAVES)), and
## DISCARDS - the question's way on, leaving without saving - puts the
## answers back to the draft before the move goes on. It is a press, never
## the place's emptying, which the application's closing does as well.
##
## SENDING IS NEVER REFUSED BEFORE IT IS PRESSED: the reader must be able to
## press it to learn what stops it. Pressed with problems, every step is
## checked, the reader is taken to the first problem's question and the
## press is answered with how many there are; with none, the form is sent,
## its draft let go, and the reader taken where a sent form goes.

const SAVES_DRAFT := FormActions.SAVES_DRAFT
const SENDS := FormActions.SENDS
const STARTS_AFRESH := FormActions.STARTS_AFRESH
const SHOWS_STEP := FormActions.SHOWS_STEP
const SHOWS_QUESTION := FormActions.SHOWS_QUESTION
const DISCARDS := FormActions.LEAVES_WITHOUT_SAVING

var _notices: Notifications  # told of a draft saved and a form sent, when given
var _door: Object
var _keys: Dictionary = {}  # a question's action -> its key
var _narrowings: Dictionary = {}  # a searched choice's key -> the narrowing over its options
var _sent_to: StringName  # the place a sent form goes to
var _draft := value({})
var _on: StringName = &""  # the step the reader is on, as last moved
var _sent := value(false)


## The form asking these questions over these steps - [key, words] each -
## its moves through this door, a sent form going to this place.
func _init(chimes: Chimes, door: Object, questions: Array, steps: Array, sent_to: StringName, notices: Notifications = null) -> void:
	super(chimes, questions, steps)
	listen_to(Chimes.GLOBAL, Driver.NAVIGATED)
	_door = door
	_sent_to = sent_to
	_notices = notices
	# every question, found by its action; a searched choice given a narrowing over its options
	for question: Dictionary in questions:
		_keys[answering(question["key"])] = question["key"]
		if question["search"]:
			_narrowings[question["key"]] = Narrowing.new(chimes, options(question["key"]), 12)
			add_child(_narrowings[question["key"]])


## The action answering a question.
static func answering(key: StringName) -> StringName:
	return FormActions.answering(key)


## Every action declared, worded, on the inputs given for the form's own, and told from anywhere (form_actions.gd).
func declare(register: Actions, inputs: Dictionary = {}) -> void:
	FormActions.declare(self, register, _door, inputs)


## A searched choice's narrowing over its options.
func narrowing(key: StringName) -> Narrowing:
	return _narrowings[key]


## Whether a draft is saved to go back to.
func get_drafted() -> bool:
	return not _draft.read().is_empty()


func get_dirty() -> bool:
	return _answers.read() != _draft.read()


func get_sent() -> bool:
	return _sent.read()


## A refusal reads only what it must: a file's refusal is the payload's
## alone and reads no value, and only sending's reads whether it was sent -
## so a keystroke re-reads no press's refusal, of the hundreds a form draws.
func would(action: StringName, payload: Dictionary) -> Phrase:
	if _keys.has(action):
		return Question.refusal(_by_key[_keys[action]], _put_in(payload))
	match action:
		Driver.LEAVES:
			return Phrase.of("Leave without saving? What changed since the draft was saved will be lost.") if get_dirty() else null
		SENDS:
			return Phrase.of("This form has been sent") if _sent.read() else null
		SHOWS_QUESTION:
			# a press whose item has gone carries nothing, and is refused nothing
			return null if payload.is_empty() or is_asked(payload["value"]) else Phrase.of("This question is not asked now")
	return null


func told(action: StringName, payload: Dictionary) -> Phrase:
	if _keys.has(action):
		var answers: Dictionary = _answers.read()
		answers[_keys[action]] = _put_in(payload)
		_answers.set_value(answers)
		return null
	match action:
		SAVES_DRAFT:
			_draft.set_value(get_answers())
			_notify(Phrase.of("The draft is saved"))
		DISCARDS:
			_answers.set_value(_draft.read().duplicate(true))
		SENDS:
			return _send()
		SHOWS_STEP:
			return _door.dispatch(Chimes.GLOBAL, Driver.GO, {"place": payload["value"]})
		SHOWS_QUESTION:
			return _door.dispatch(Chimes.GLOBAL, Driver.GO, {"place": _by_key[payload["value"]]["step"], "parameter": payload["value"]})
		STARTS_AFRESH:
			_answers.set_value({})
			_checked.set_value({})
			_draft.set_value({})
			_sent.set_value(false)
	return null


## Sent, or taken to the first problem with every step checked.
func _send() -> Phrase:
	var errors := get_errors()
	if not errors.is_empty():
		var checked: Dictionary = _checked.read()
		# every step checked, so every problem shows
		for step: Array in _steps:
			checked[step[0]] = true
		_checked.set_value(checked)
		told(SHOWS_QUESTION, {"value": errors[0]["value"]})
		return Phrase.counted("%d answer needs attention", "%d answers need attention", errors.size())
	_sent.set_value(true)
	_draft.set_value(get_answers())
	_notify(Phrase.of("The form is sent"))
	_door.dispatch(Chimes.GLOBAL, Driver.GO, {"place": _sent_to})
	return null


## Moved: the step the reader was on, if they left it, is checked.
func heard(_what: StringName) -> void:
	var path: Array = _door.mover.get_state()["path"]
	var now: StringName = &""
	# every step, for the one on the reader's path
	for step: Array in _steps:
		if path.has(step[0]):
			now = step[0]
	if now == _on:
		return
	if _on != &"":
		var checked: Dictionary = _checked.read()
		checked[_on] = true
		_checked.set_value(checked)
	_on = now


## The draft, as the settings file keeps it: none once the form is sent.
func saved() -> Dictionary:
	return {"answers": {} if _sent.read() else _draft.read()}


## A draft read back off a disk: every answer that fits a question of this
## form held, and made the draft; anything else said out loud and left out.
func restore(from: Dictionary) -> void:
	if not from.get("answers") is Dictionary:
		push_error("a form's draft holds its answers, and this holds none: %s" % [from])
		return
	var answers: Dictionary = _answers.read()
	# every answer the file held, kept where it fits a question
	for key: String in from["answers"]:
		if not _by_key.has(StringName(key)) or not Question.fits(_by_key[StringName(key)], from["answers"][key]):
			push_error("the draft's answer to %s is no answer this form asks for; it is left out" % key)
			continue
		answers[StringName(key)] = from["answers"][key]
	_answers.set_value(answers)
	_draft.set_value(answers.duplicate(true))


## What a control put in: the line, where it carries one, else the value.
static func _put_in(payload: Dictionary) -> Variant:
	return payload["line"] if payload.has("line") else payload.get("value")


func _notify(words: Phrase) -> void:
	if _notices != null:
		_notices.notify(words)
