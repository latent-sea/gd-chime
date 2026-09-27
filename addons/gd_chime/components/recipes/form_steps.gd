extends RefCounted

const Themes := preload("../../theme.gd")
const Fields := preload("../../theme_fields.gd")
const Chimes := preload("../../chimes.gd")
const Driver := preload("../../driver.gd")
const FormActions := preload("../../form_actions.gd")
const Shape := preload("../../shape.gd")
const Phrase := preload("../../phrase.gd")
const Ui := preload("../primitives/ui.gd")
const Options := preload("../primitives/options.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const FormField := preload("form_field.gd")
const FormReview := preload("form_review.gd")
const Pressables := preload("../../theme_pressables.gd")

## A form of many steps, whole: the steps along the top, each saying how far
## the reader is through it, and one screen per step - its questions, a
## section shown while an answer holds, what needs attention on it, and the
## ways back, on, out and to save - the last step the review and sending.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## IT IS DESCRIBED FROM THE FORM'S DATA (form.gd, question.gd): every
## question of a step, in the order asked (form_field.gd); the questions
## asked while one answer holds - [key, value] - standing together in a
## section shown while it holds - built once and kept hidden while it does
## not, so a hand's place in it is kept too - its answers kept by the form.
## So a second form is its questions and nothing else.
##
## EVERY STEP IS A SCREEN NAMED BY ITS KEY, so where the reader is is the
## driver's: the history retraces the steps, the focus and the scroll are
## kept with each, and a question's step entered as its key puts the focus
## on it. The steps stand in one screen, the form, which asks before it is
## left while the form's answers differ from its draft (leave_guard.gd),
## its question going on by the form's DISCARDS, which lets them go.
##
## THE STEPS ALONG THE TOP ARE PRESSES OF ONE ACTION carrying a step's key
## (SHOWS_STEP), drawn current on the step the reader is on and worn by the
## step's state - open, done, needing attention - its words saying which, so
## the state is never told by colour alone. They wrap onto more lines where
## the window is narrow.
##
## A STEP'S WAYS ON ARE ITS OWN: back and next go to the steps either side,
## each place declaring where its presses go; save as draft is the form's;
## close goes where the caller says. The review step sends instead of
## going on - what stops it said by the summary, each a link - and a sent
## form goes where the form was made to send it.
##
## Deliberately absent: a step skipped by an answer - a whole step asked
## while an answer holds - and a question repeated per item of a list.

## The most of a wide window's width a step's page takes, so its lines stay readable.
const READABLE := 0.72


## The form as the screen of this name over the form's steps - the review
## step the one named so - asking this pop-up before it is left, closing to
## this place, its days opening this calendar (calendar_sheet.gd). The
## overlays its choices stand in travel on their fields.
## Its options: review, the step that is the review; asks, the pop-up put
## before the form is left; closes_to, where closing goes; and calendar,
## the calendar its day fields open (calendar_sheet.gd).
const OPTIONS: Array[String] = ["review", "asks", "closes_to", "calendar"]

static func make(ui: Ui, form: Object, named: StringName, options: Dictionary = {}) -> Desc:
	Options.checked("a form's steps", options, OPTIONS)
	var review: StringName = options["review"]
	var asks: Desc = options["asks"]
	var closes_to: StringName = options["closes_to"]
	var calendar: Desc = options["calendar"]
	var steps: Array = form.get_steps()
	var screens: Array = []
	# every step, a screen of its own with its ways on
	for at: int in steps.size():
		var key: StringName = steps[at]["value"]
		var content: Array = [FormReview.summary(ui, ui.bound(form.get_errors)), FormReview.review(ui, form)] if key == review else _questions(ui, form, key, calendar)
		var heading := ui.text(Phrase.with("Step %d of %d", [at + 1, steps.size()]), Themes.REASON)
		var page := ui.column([heading, ui.text(steps[at]["words"], Fields.HEADING).wraps(), FormReview.summary(ui, FormReview.shown_on(form, key))] + content + [_ways_on(ui, steps, at, key == review, closes_to)])
		# the page on its sheet: on a wide window no wider than a line is comfortably read, on one on its end the whole width
		var sheet := ui.by_shape({&"page": ui.surface(Fields.PAGE, [page])}, {Shape.LANDSCAPE: _across(ui, {"grow": 1.0, "max": READABLE}), Shape.PORTRAIT: _across(ui, {"grow": 1.0})})
		screens.append(ui.screen(key, [ui.scroll(sheet).grow()]))
	var along := ui.each_across(ui.bound(form.get_steps), func(step: Bound) -> Desc: return _step(ui, step), func(step: Dictionary) -> Variant: return step["value"], Fields.STEPS)
	var whole := ui.column([along, ui.stack(screens).grow()])
	return ui.screen(named, [whole], form, {on_fill = Callable(), on_empty = Callable(), asks_before_leaving = asks})


## A step's questions in the order asked, those asked while an answer holds
## standing together in a section shown while it does.
static func _questions(ui: Ui, form: Object, step: StringName, calendar: Desc) -> Array:
	var parts: Array = []
	var section: Array = []
	var asked_while: Array = []
	# every question of the step, gathered into a section while its condition is the one before's
	for question: Dictionary in form.get_questions().filter(func(one: Dictionary) -> bool: return one["step"] == step):
		if question["while"] != asked_while:
			parts.append_array(_section(ui, form, section, asked_while))
			section = []
			asked_while = question["while"]
		section.append(FormField.make(ui, form, question["key"], calendar))
	parts.append_array(_section(ui, form, section, asked_while))
	return parts


## The page's arrangement in a shape of window: across, with these facts.
static func _across(ui: Ui, facts: Dictionary) -> Dictionary:
	return ui.row_of([&"page"], {&"page": facts})


## Questions asked always, as they are; asked while an answer holds, a section shown while it does.
static func _section(ui: Ui, form: Object, questions: Array, asked_while: Array) -> Array:
	if asked_while.is_empty() or questions.is_empty():
		return questions
	return [ui.when(form.holds(asked_while[0], asked_while[1]), ui.surface(Fields.SECTION, [ui.column(questions)]), null).keeps()]


## The ways on from a step: back, save as draft, and next - or, on the review, send - and close.
static func _ways_on(ui: Ui, steps: Array, at: int, reviewing: bool, closes_to: StringName) -> Desc:
	var ways: Array = []
	if at > 0:
		ways.append(_press(ui, FormActions.PREVIOUS, steps[at - 1]["value"]))
	ways.append(_press(ui, FormActions.SAVES_DRAFT, &""))
	ways.append(_press(ui, FormActions.SENDS, &"") if reviewing else _press(ui, FormActions.NEXT, steps[at + 1]["value"]))
	ways.append(_press(ui, FormActions.CLOSES, closes_to))
	return ui.row(ways, Themes.TILES)


## A press of an action in its words, going where it says; why a send was
## refused is the summary's to say, a list of links, never words under a press.
static func _press(ui: Ui, action: StringName, goes_to: StringName) -> Desc:
	return ui.pressable(action, {}, [ui.text(ui.words(action), Themes.FACE)], Pressables.BUTTON).goes_to(goes_to)


## One step along the top: its number and words, and what state it is in,
## worn by that state and current while the reader is on it.
static func _step(ui: Ui, step: Bound) -> Desc:
	var driver: Driver = ui.driver
	var said: Bound = step.map(func(one: Variant) -> Variant: return null if one == null else Phrase.joined(["%d. " % one["number"], one["words"]]))
	var state: Bound = step.map(func(one: Variant) -> Variant: return null if one == null or one["state"] == &"open" else Phrase.of("Done") if one["state"] == &"done" else Phrase.counted("%d to fix", "%d to fix", one["count"]))
	var worn: Bound = step.map(func(one: Variant) -> StringName: return Fields.STEP if one == null or one["state"] == &"open" else Fields.STEP_DONE if one["state"] == &"done" else Fields.STEP_NEEDS)
	var on_it: Bound = Bound.both(step, Bound.new(driver.get_top), func(one: Variant, top: Array) -> bool: return one != null and top.has(one["value"]))
	var carried: Bound = step.map(func(one: Variant) -> Dictionary: return {} if one == null else {"value": one["value"]})
	return ui.pressable(FormActions.SHOWS_STEP, carried, [ui.column([ui.text(said, Themes.FACE), ui.text(state, Themes.REASON).hides_empty()])], worn).current_while(on_it)
