extends "controller.gd"

const Question := preload("question.gd")

## What a form's answers say: the questions asked now, the rules the
## answers break, which of those the reader has been shown, how far through
## each step the reader is, and every answer written back step by step.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The reading half of a form: form.gd, which extends this, is what is done
## to the answers - held, saved as a draft, sent. Nothing here changes
## anything; every read is worked out from the answers and the steps checked.
##
## EACH READING IS WORKED OUT ONCE PER CHANGE, however often it is read: a
## review, a summary and the steps are templates whose every item reads the
## whole reading, so worked out on each read a keystroke cost a hundred
## reviews. What is worked out is kept with what it read (reads.gd), and
## every read of it notes that again, so its reader follows the answers and
## the options as though it had worked it out itself. IT LETS ITSELF GO as
## anything it read moves - the answers, the steps checked, a choice's
## options - so nothing here empties it, and a new writer cannot forget to.
##
## A QUESTION ASKED WHILE ANOTHER'S ANSWER HOLDS ([key, value]) keeps its
## answer while it is not asked: hidden, it breaks no rule and is written in
## no review, and shown again it has what it had.
##
## A PROBLEM IS SHOWN ONCE ITS STEP IS CHECKED - left by the reader, or
## every step, once sending was tried - so nobody is told off mid-word;
## after, its message follows every change of the answers.

const Reads := preload("reads.gd")

var _questions: Array = []  # every question, in the order asked
var _by_key: Dictionary = {}  # key -> the question
var _steps: Array = []  # every step, [key, words], in order
var _answers := value({})  # key -> what was put in
var _checked := value({})  # step -> true, once its problems are shown
var _worked: Dictionary = {}  # each reading worked out since what it reads last moved, by name: [what it is, the addresses it read] (reads.gd)


func _init(chimes: Chimes, questions: Array, steps: Array) -> void:
	super(chimes, [], Chimes.GLOBAL)
	_questions = questions
	_steps = steps
	# every question, found by its key
	for question: Dictionary in questions:
		_by_key[question["key"]] = question
	follow(&"options", _options_moved)


## Every choice's own options read, so they are followed: moved, every
## reading kept with a read of them works out afresh as it is next read.
func _options_moved() -> void:
	# every question with options of its own
	for question: Dictionary in _questions:
		if question["options"] != null:
			question["options"].read()


## Every question, in the order asked.
func get_questions() -> Array:
	return _questions


## One question, by its key.
func get_question(key: StringName) -> Dictionary:
	return _by_key[key]


func get_answers() -> Dictionary:
	return _answers.read().duplicate(true)


## One question's answer as held, re-read as any answer moves.
func held(key: StringName) -> Bound:
	return Bound.new(func() -> Variant: return _answers.read().get(key))


## Whether a question's answer is this value, re-read as any answer moves:
## what a section asked while that answer holds is shown by.
func holds(key: StringName, value: Variant) -> Bound:
	return Bound.new(func() -> bool: return _answers.read().get(key) == value)


## A choice's options now: its own, or those of the answer it is narrowed
## by, re-read as that answer moves - a dependent question; that one not
## answered yet, none.
func options(key: StringName) -> Bound:
	var narrowed_by: Array = _by_key[key]["narrowed_by"]
	if narrowed_by.is_empty():
		return _by_key[key]["options"]
	return Bound.new(func() -> Array: return narrowed_by[1].get(_answers.read().get(narrowed_by[0]), []))


## One question's problem while it is shown, else nothing.
func message(key: StringName) -> Bound:
	return Bound.new(func() -> Variant: return get_messages().get(key))


## Whether a question is asked now: always, or while the answer it is asked while holds.
func is_asked(key: StringName) -> bool:
	var asked_while: Array = _by_key[key]["while"]
	return asked_while.is_empty() or _answers.read().get(asked_while[0]) == asked_while[1]


## One answer read as its question reads it: a day, a sum, else as held - for a question's own rule.
func value_of(key: StringName) -> Variant:
	return Question.value(_by_key[key], _answers.read().get(key))


## Every problem of a question asked now, in the order asked: {value - its key, words, says, step}.
func get_errors() -> Array:
	return _once(&"errors", func() -> Array:
		var errors: Array = []
		# every question asked now, for the rule its answer breaks
		for question: Dictionary in _questions:
			var says: Phrase = Question.problem(question, _answers.read().get(question["key"]), self) if is_asked(question["key"]) else null
			if says != null:
				errors.append({"value": question["key"], "words": question["words"], "says": says, "step": question["step"]})
		return errors)


## The problems shown - those of the steps checked - by key.
func get_messages() -> Dictionary:
	return _once(&"messages", func() -> Dictionary:
		var shown: Dictionary = {}
		# every problem, kept where its step is checked
		for error: Dictionary in get_errors():
			if _checked.read().has(error["step"]):
				shown[error["value"]] = error["says"]
		return shown)


## Every step as the reader goes through it: {value, words, number, state, count -
## its problems}; its state open until it is checked, then needs while it
## has problems and done once it has none.
func get_steps() -> Array:
	return _once(&"steps", func() -> Array:
		var errors := get_errors()
		var steps: Array = []
		# every step, its problems counted and its state from whether it is checked
		for step: Array in _steps:
			var count := errors.filter(func(error: Dictionary) -> bool: return error["step"] == step[0]).size()
			# a step asking nothing - the review - is never done, only gone through
			var asks := _questions.any(func(question: Dictionary) -> bool: return question["step"] == step[0])
			var state := &"open" if not _checked.read().has(step[0]) or not asks else &"needs" if count > 0 else &"done"
			steps.append({"value": step[0], "words": step[1], "number": steps.size() + 1, "state": state, "count": count})
		return steps)


## Every step with a question asked now, each answer written back:
## [{value, words, answers: [{value, words, shown}]}].
func get_review() -> Array:
	return _once(&"review", func() -> Array:
		var review: Array = []
		# every step, with the questions asked in it
		for step: Array in _steps:
			var answered: Array = []
			# every question of the step asked now, its answer written back
			for question: Dictionary in _questions:
				if question["step"] == step[0] and is_asked(question["key"]):
					answered.append({"value": question["key"], "words": question["words"], "shown": Question.written(question, _answers.read().get(question["key"]))})
			if not answered.is_empty():
				review.append({"value": step[0], "words": step[1], "answers": answered})
		return review)


## A reading worked out once since what it reads last moved, and what it
## read noted for whoever reads it (reads.gd).
func _once(named: StringName, work: Callable) -> Variant:
	if not _worked.has(named):
		_worked[named] = []
	return Reads.worked(_worked[named], work)
