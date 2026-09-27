extends RefCounted

const Themes := preload("../../theme.gd")
const Fields := preload("../../theme_fields.gd")
const Chimes := preload("../../chimes.gd")
const Question := preload("../../question.gd")
const FormActions := preload("../../form_actions.gd")
const Phrase := preload("../../phrase.gd")
const Ui := preload("../primitives/ui.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const DateField := preload("date_field.gd")
const AmountField := preload("amount_field.gd")
const Stepper := preload("stepper.gd")
const Combo := preload("combo.gd")
const InlineChoice := preload("inline_choice.gd")

## One question of a form laid out: its words, what it says under them, the
## control its kind is answered with, and its message beside it - the whole
## taking the focus as its step is entered as its key.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE CONTROL IS THE FLOOR'S FOR ITS KIND, over the answer the form holds,
## pressing the question's own action (form_actions.gd): words, a typed line
## (field); a day, a date field and the one calendar (date_field.gd); a sum,
## an amount field (amount_field.gd); a number, a stepper; yes or no, a
## segmented control; a choice, a combo - its short list, or a type-ahead
## over the form's narrowing where it is searched; a file, a press picking
## one (file_pick.gd) beside the name and size of the one held. A combo's
## choosing stands in an overlay, which travels on its closed field and is
## lifted beside the app by the builder; a date field opens the one
## calendar it is handed.
##
## THE MESSAGE IS THE FORM'S: the problem its answer breaks, once its step
## is checked (answers.gd), after the mark that says it is one, so it is
## never told by its colour alone; it takes no room while there is none.
##
## A QUESTION ENTERED AS ITS KEY TAKES THE FOCUS (arrival_focus.gd): its
## control, the first thing under it that takes the focus, so a problem
## listed elsewhere and an answer on the review both land the reader on it.


## A question laid out, a day's opening this calendar (calendar_sheet.gd).
static func make(ui: Ui, form: Object, key: StringName, calendar: Desc) -> Desc:
	var question: Dictionary = form.get_question(key)
	var parts: Array = [ui.text(question["words"], Themes.FACE).wraps()]
	if question["says"] != null:
		parts.append(ui.text(question["says"], Themes.REASON).wraps())
	parts.append(_control(ui, form, question, calendar))
	# the problem, after its mark, while there is one shown
	parts.append(ui.text(form.message(key).map(func(says: Variant) -> Variant: return null if says == null else Phrase.joined([Fields.MESSAGE_MARK, says])), Fields.MESSAGE).hides_empty().wraps())
	var entered: Bound = ui.parameter(question["step"]).map(func(on: Variant) -> bool: return on == key)
	return ui.arrival_focus(entered, [ui.column(parts, Fields.QUESTION)]).named(named(key))


## The name a question's laid-out node is found by (ui.node_named): a test's, a probe's.
static func named(key: StringName) -> StringName:
	return StringName("question " + key)


## The control a question's kind is answered with, over the answer held.
static func _control(ui: Ui, form: Object, question: Dictionary, calendar: Desc) -> Desc:
	var key: StringName = question["key"]
	var action := FormActions.answering(key)
	var held: Bound = form.held(key)
	match question["kind"]:
		Question.DAY:
			return DateField.make(ui, action, held, calendar)
		Question.AMOUNT:
			return AmountField.make(ui, action, question["mark"], {style = &"AmountField", holds = held})
		Question.QUANTITY:
			var shown: Bound = held.map(func(number: Variant) -> Variant: return question["least"] if number == null else number)
			return Stepper.make(ui, action, shown, {minimum = question["least"], maximum = question["most"], step = question["step_by"]})
		Question.YES_NO:
			return InlineChoice.segments(ui, action, Bound.new(yes_or_no), held)
		Question.CHOICE:
			return _choice(ui, form, question, action, held)
		Question.FILE:
			var picks := ui.file_pick(action, question["kinds"], [ui.column([ui.text(Phrase.of("Choose a file"), Themes.FACE), ui.reason(Themes.REASON)])])
			var chosen := ui.text(held.map(func(file: Variant) -> Variant: return Question.written(question, file)), Themes.REASON).wraps()
			return ui.row([picks, chosen.grow()])
	var line: Bound = held.map(func(words: Variant) -> String: return "" if words == null else words)
	return ui.field(action, Fields.FIELD, {"shows": line, "changes": action})


## A choice: a combo over its short list, or over a type-ahead of its
## narrowing where it is searched, its overlay the question's own pop-up.
static func _choice(ui: Ui, form: Object, question: Dictionary, action: StringName, held: Bound) -> Desc:
	var key: StringName = question["key"]
	# the words of the option held, or the word asking for one: a closed field with nothing in it would be no field at all
	var shown: Bound = held.map(func(value: Variant) -> Variant: return Phrase.of("Choose") if value == null else Question.written(question, value))
	if not question["search"]:
		var short := Combo.short(ui, action, FormActions.chooses(key), {offers = form.options(key), chosen = held, title = question["words"]})
		return ui.pressable(FormActions.chooses(key), {}, [ui.text(shown, Themes.FACE)], Fields.COMBO).opens(short.props["overlay"])
	return Combo.long(ui, action, FormActions.chooses(key), shown, {narrowing = form.narrowing(key), types = FormActions.types(key), title = question["words"]})


## Yes and no, as a choice's options.
static func yes_or_no() -> Array:
	return [{"value": true, "words": Phrase.of("Yes")}, {"value": false, "words": Phrase.of("No")}]
