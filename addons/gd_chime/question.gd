extends RefCounted

const Options := preload("components/primitives/options.gd")
const Phrase := preload("phrase.gd")
const Dates := preload("dates.gd")
const Formats := preload("formats.gd")
const Language := preload("language.gd")

## A question a form asks, as plain data, and the one reading of its answer:
## what the answer held means, whether it breaks a rule, whether it can be
## held at all, and how it is written back to the reader.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A QUESTION IS A DICTIONARY, made by make(): its key, the step it is asked
## in, its words, its kind, and by name whatever else its kind needs - the
## options of a choice - or, NARROWED BY another question, [key, {that
## answer: its options}], a dependent choice offering only the options of
## the answer given - and whether it is SEARCHED by typing, a sum's mark,
## a number's ends and step, the kinds and size a file may be, what it SAYS
## under its words - and
## the answer it is asked WHILE ([key, value]: while that question's answer
## is that value), whether it is NEEDED, and a RULE of its own, a function of
## the value and the form answering a phrase or null. Data, so a form is
## written as a list of them and never as code per question.
##
## WHAT IS HELD IS WHAT WAS PUT IN, never a reading of it: a typed day and a
## typed sum are held as the line the reader typed (dates.gd reads the day,
## amount_of the sum), so a half-typed line is kept as it stands and nothing
## the reader typed is ever lost to a rule. value() is the reading - the
## day, the sum, else what is held - and the rules read that.
##
## TWO KINDS OF NO. A PROBLEM is a rule the answer breaks - needed and
## empty, a line that is no day, a choice no longer among the options (a
## dependent question whose options moved under it) - said beside the
## question once it is checked, and never stopping the reader holding the
## answer. A REFUSAL is an answer that cannot be held at all - a file of a
## kind or a size not taken - the door's no, and nothing is held.
##
## Deliberately absent: a question repeated per item of a list, and rules
## reading anything but the form's answers.

## The kinds of question: words, a day, a sum of money, a number, a choice, yes or no, a file.
const TEXT := &"text"
const DAY := &"day"
const AMOUNT := &"amount"
const QUANTITY := &"quantity"
const CHOICE := &"choice"
const YES_NO := &"yes_no"
const FILE := &"file"
## What make() takes by name beside its four, and what each is when it is not given.
const OPTIONS := {"needed": false, "while": [], "rule": null, "search": false, "narrowed_by": [], "says": null, "options": null, "mark": "", "places": 0, "kinds": [], "most_bytes": 0, "least": 0.0, "most": 0.0, "step_by": 1.0}
const MEGABYTE := 1048576.0


## A question: its key, the step it is asked in, its words, its kind, and by name the rest.
static func make(key: StringName, step: StringName, words: Variant, kind: StringName, with: Dictionary = {}) -> Dictionary:
	Options.checked("a question", with, OPTIONS.keys())
	var question := OPTIONS.duplicate()
	question.merge(with, true)
	question.merge({"key": key, "step": step, "words": words, "kind": kind}, true)
	return question


## What an answer held means: a typed day read as the day, a typed sum as
## the amount - null where the line names none - and anything else as held.
static func value(question: Dictionary, held: Variant) -> Variant:
	if held == null:
		return null
	match question["kind"]:
		DAY: return Dates.parsed(held)
		AMOUNT: return amount_of(held)
	return held


## Whether nothing is held: no answer, or an empty line.
static func is_empty(held: Variant) -> bool:
	return held == null or (held is String and (held as String).strip_edges() == "")


## The rule an answer breaks, or null: needed and empty; a line that reads
## as no day or no sum; a choice not among the options now; the question's
## own - which is asked of an empty answer too, given null, so a question
## may be needed only while another answer says so.
static func problem(question: Dictionary, held: Variant, form: Object) -> Phrase:
	if is_empty(held) and question["needed"]:
		return Phrase.of("This answer is needed")
	# an answer not needed and not given is asked of the question's own rule alone: needed only while another answer says so
	if is_empty(held):
		return question["rule"].call(null, form) if question["rule"] != null else null
	var read: Variant = value(question, held)
	match question["kind"]:
		DAY:
			if read == null:
				return Phrase.with("Type a date as %s", [Dates.shape()])
		AMOUNT:
			if read == null:
				return Phrase.of("Type an amount in figures")
		CHOICE:
			if not (form.options(question["key"]).read() as Array).any(func(option: Dictionary) -> bool: return option["value"] == held):
				return Phrase.of("Choose again: this is not one of the options now")
	return question["rule"].call(read, form) if question["rule"] != null else null


## Why an answer cannot be held at all, or null: a file of a kind the
## question does not take, or larger than it takes.
static func refusal(question: Dictionary, held: Variant) -> Phrase:
	if question["kind"] != FILE or held == null:
		return null
	if not question["kinds"].has(String(held["kind"]).to_lower()):
		return Phrase.with("Only %s files are taken", [", ".join(question["kinds"])])
	if held["size"] > question["most_bytes"]:
		return Phrase.with("The file is %s and at most %s is taken", [size_of(held["size"]), size_of(question["most_bytes"])])
	return null


## An answer written back to the reader: the words of a choice, a day and a
## sum the language's way, yes or no, a file's name and size - and the line
## as typed where it reads as nothing yet.
static func written(question: Dictionary, held: Variant) -> Variant:
	if is_empty(held):
		return Phrase.of("Not answered")
	var read: Variant = value(question, held)
	match question["kind"]:
		DAY: return held if read == null else Dates.written(read)
		AMOUNT: return held if read == null else Phrase.written(func() -> String: return Formats.written_money(read, question["mark"], question["places"]))
		QUANTITY: return Phrase.written(func() -> String: return Formats.written_number(read, question["places"]))
		YES_NO: return Phrase.of("Yes" if read else "No")
		CHOICE: return _words_of(every_option(question), held)
		FILE: return Phrase.with("%s, %s", [held["name"], size_of(held["size"])])
	return held


## Whether an answer read back off a disk is one this question could hold:
## a line for words, a day and a sum; a number; yes or no; a file's name,
## size and kind; a plain value for a choice. A saved draft is not ours.
static func fits(question: Dictionary, held: Variant) -> bool:
	match question["kind"]:
		TEXT, DAY, AMOUNT: return held is String
		QUANTITY: return held is float or held is int
		YES_NO: return held is bool
		FILE: return held is Dictionary and held.get("name") is String and held.get("kind") is String and (held.get("size") is float or held.get("size") is int)
	return held is String or held is float or held is int or held is bool


## A sum typed in the language's way read back as a number - its thousands
## marks set aside, its fraction mark a point - or null where it is none.
static func amount_of(line: String) -> Variant:
	var bare := line.strip_edges().replace(Language.written(",", Formats.THOUSANDS), "").replace(Language.written(".", Formats.FRACTION), ".")
	return bare.to_float() if bare.is_valid_float() else null


## A size in bytes, as the reader reads one: megabytes to one place, kilobytes under one.
static func size_of(bytes: float) -> Phrase:
	if bytes < MEGABYTE:
		return Phrase.with("%s KB", [Phrase.written(func() -> String: return Formats.written_number(bytes / 1024.0))])
	return Phrase.with("%s MB", [Phrase.written(func() -> String: return Formats.written_number(bytes / MEGABYTE, 1))])


## Every option a choice could offer: its options, or - narrowed by another
## answer - the options of every answer that one may be.
static func every_option(question: Dictionary) -> Array:
	if question["narrowed_by"].is_empty():
		return question["options"].read()
	var every: Array = []
	# every answer's options, one after another
	for options: Array in question["narrowed_by"][1].values():
		every.append_array(options)
	return every


## The words of the option holding this value, else the value as it is.
static func _words_of(options: Array, held: Variant) -> Variant:
	# every option, for the one holding the value
	for option: Dictionary in options:
		if option["value"] == held:
			return option["words"]
	return held
