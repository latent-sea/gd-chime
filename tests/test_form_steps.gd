extends SceneTree

## What must be true of a form laid out from its data (form_steps.gd,
## form_field.gd, form_review.gd): every question stands on its step, in
## the order asked, with the floor's control for its kind; a section asked
## while an answer holds shows while it does, and hides keeping its answer;
## a question's message stands beside it, after its mark, once its step is
## left; the steps along the top go to their step, the one the reader is on
## drawn current and each saying what it needs; the summary lists every
## problem and each of its links lands the focus on its question; the
## review writes each answer back and its change lands on the question; a
## short choice's overlay is handed to the caller; and leaving the form with
## answers unsaved asks first, going on letting them go; and a step's page is
## no wider than a line is read on a wide window, the whole width on one on
## its end.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_form_steps.gd

const Fixture := preload("res://tests/fixture.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Fields := preload("res://addons/gd_chime/theme_fields.gd")
const Form := preload("res://addons/gd_chime/form.gd")
const FormActions := preload("res://addons/gd_chime/form_actions.gd")
const Question := preload("res://addons/gd_chime/question.gd")
const Calendar := preload("res://addons/gd_chime/calendar.gd")
const FormField := preload("res://addons/gd_chime/components/recipes/form_field.gd")
const FormSteps := preload("res://addons/gd_chime/components/recipes/form_steps.gd")
const Confirm := preload("res://addons/gd_chime/components/recipes/confirm.gd")
const CalendarSheet := preload("res://addons/gd_chime/components/recipes/calendar_sheet.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Verdict := preload("res://tests/verdict.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")

const ABOUT := &"about"
const OWNS := &"owns"
const CHECK := &"check"

const OUTSIDE := &"outside"


var _verdict := Verdict.new()
var _made: Fixture
var _form: Form
var _calendar: Calendar
var _leaving: StringName  # the question asked before the form is left, named by the builder



func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(1280, 800)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_every_question_stands_on_its_step_in_order_with_the_control_for_its_kind)
	await _verdict.states(_a_section_shows_while_its_answer_holds_and_hides_keeping_its_answer)
	await _verdict.states(_a_message_stands_beside_its_question_after_its_mark_once_its_step_is_left)
	await _verdict.states(_the_steps_go_to_their_step_and_say_what_each_needs)
	await _verdict.states(_the_summary_and_the_review_land_the_focus_on_their_question)
	await _verdict.states(_leaving_with_answers_unsaved_asks_and_going_on_lets_them_go)
	await _verdict.states(_a_page_is_no_wider_than_is_read_on_a_wide_window_and_the_whole_width_on_one_on_its_end)
	quit(_verdict.deliver(get_script()))


func _frames() -> void:
	# a few frames, and every move's motion run to its end
	for i: int in 3:
		await process_frame
	_made.ui.motion.step(10.0)
	await process_frame
	await process_frame


## A form of two steps and a review: a name, a day and a kind on the first;
## whether vans are owned and, while they are, how many, on the second.
func _built() -> void:
	_made = Fixture.new(root, {})
	var kinds := Bound.constant([{"value": "shop", "words": Phrase.of("shop")}, {"value": "cafe", "words": Phrase.of("cafe")}])
	var questions := [
		Question.make(&"name", ABOUT, Phrase.of("name"), Question.TEXT, {"needed": true}),
		Question.make(&"founded", ABOUT, Phrase.of("founded"), Question.DAY),
		Question.make(&"kind", ABOUT, Phrase.of("kind"), Question.CHOICE, {"options": kinds}),
		Question.make(&"vans", OWNS, Phrase.of("owns vans"), Question.YES_NO),
		Question.make(&"how_many", OWNS, Phrase.of("how many"), Question.QUANTITY, {"least": 1.0, "most": 9.0, "while": [&"vans", true]}),
	]
	_form = Form.new(_made.chimes, _made.commands, questions, [[ABOUT, Phrase.of("about")], [OWNS, Phrase.of("owns")], [CHECK, Phrase.of("check")]], OUTSIDE)
	_form.declare(_made.actions)
	_calendar = Calendar.new(_made.chimes, _made.commands)
	_calendar.declare(_made.actions)
	_made.inputs.restore_defaults()
	var ui := _made.ui
	# the question asked before the form is left and the calendar its days open: described here, lifted with the form
	var leaving := Confirm.for_leaving(ui, FormActions.LEAVES_WITHOUT_SAVING)
	_leaving = leaving.get_place()
	var form := FormSteps.make(ui, _form, &"form", {review = CHECK, asks = leaving, closes_to = OUTSIDE, calendar = CalendarSheet.make(ui, _calendar)})
	ui.build(ui.app(&"app", [ui.stack([ui.screen(OUTSIDE, [ui.text("outside")]), form])]), root)
	_made.commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": ABOUT})
	await _frames()


func _done() -> void:
	_calendar.free()
	_form.free()
	_made.done()


func _question(key: StringName) -> Control:
	return _made.ui.node_named(FormField.named(key))


func _press(action: StringName, value: Variant = null) -> Pressable:
	var found: Array = root.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable and (part as Pressable).action == action and (part as Pressable).is_visible_in_tree() and (value == null or (part as Pressable).payload().get("value") == value))
	return found[0] if not found.is_empty() else null


func _words(under: Node) -> Array:
	return under.find_children("*", "Label", true, false).filter(func(label: Node) -> bool: return (label as Label).is_visible_in_tree()).map(func(label: Node) -> String: return (label as Label).text)


func _every_question_stands_on_its_step_in_order_with_the_control_for_its_kind() -> void:
	await _built()
	var about := _made.driver.index.place_named(ABOUT)
	var order: Array = [&"name", &"founded", &"kind"].map(func(key: StringName) -> float: return _question(key).get_global_rect().position.y)
	_verdict.check(about.is_ancestor_of(_question(&"name")) and about.is_ancestor_of(_question(&"kind")) and order[0] < order[1] and order[1] < order[2], "the first step's questions stand on it, down the page in the order asked: %s" % [order])
	var line: Array = _question(&"name").find_children("*", "LineEdit", true, false)
	var opener := _question(&"founded").find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable and (part as Pressable).action == Calendar.OPENS)
	var chooser := _question(&"kind").find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable and (part as Pressable).action == FormActions.chooses(&"kind"))
	_verdict.check(line.size() == 1 and opener.size() == 1 and chooser.size() == 1 and _words(_question(&"kind")).has("Choose"), "words are a typed line, a day a line with the calendar's opener, a choice a closed field saying choose while nothing is chosen")
	_verdict.check(_made.driver.index.has_place(_made.driver.goes_to(ABOUT, FormActions.chooses(&"kind"))), "and the choice's overlay stands beside the app, lifted by the builder from the field that opens it")
	_verdict.check(_words(_made.driver.index.place_named(ABOUT)).has("Step 1 of 3") and _words(_made.driver.index.place_named(ABOUT)).has("about"), "the page says which step of how many, and names it")
	_done()


func _a_section_shows_while_its_answer_holds_and_hides_keeping_its_answer() -> void:
	await _built()
	_made.commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": OWNS})
	await _frames()
	var hidden := not _question(&"how_many").is_visible_in_tree()
	_press(FormActions.answering(&"vans"), true).pressed()
	await _frames()
	var shown := _question(&"how_many").is_visible_in_tree()
	_press(FormActions.answering(&"how_many"), 2.0).pressed()
	_press(FormActions.answering(&"vans"), false).pressed()
	await _frames()
	_verdict.check(hidden and shown and not _question(&"how_many").is_visible_in_tree() and _form.get_answers()[&"how_many"] == 2.0, "the section is hidden until vans are owned, shown then, and hidden again keeping its answer: %s %s" % [hidden, shown])
	_done()


func _a_message_stands_beside_its_question_after_its_mark_once_its_step_is_left() -> void:
	await _built()
	var before := _words(_question(&"name"))
	_made.commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": OWNS})
	_made.commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": ABOUT})
	await _frames()
	_verdict.check(not before.has("! This answer is needed") and _words(_question(&"name")).has("! This answer is needed"), "the name's message is not there until the step is left, and then stands beside it after its mark: %s" % [_words(_question(&"name"))])
	_done()


func _the_steps_go_to_their_step_and_say_what_each_needs() -> void:
	await _built()
	var about := _press(FormActions.SHOWS_STEP, ABOUT)
	var owns := _press(FormActions.SHOWS_STEP, OWNS)
	_verdict.check(about.get_state() == &"current" and owns.get_state() != &"current", "the step the reader is on is drawn current along the top")
	owns.pressed()
	await _frames()
	_verdict.check(_made.driver.get_top().has(OWNS) and owns.get_state() == &"current" and _words(about).has("1 to fix"), "pressed, a step's press goes to it, and the step left says what it needs: %s" % [_words(about)])
	var lowest: float = about.find_children("*", "Label", true, false).map(func(label: Node) -> float: return (label as Label).get_global_rect().end.y).max()
	_verdict.check(lowest <= about.get_global_rect().end.y - Fields.MARK, "a step's words stand clear of the bar along its foot, never drawn over it: words end at %.0f, the bar begins at %.0f" % [lowest, about.get_global_rect().end.y - Fields.MARK])
	_done()


func _the_summary_and_the_review_land_the_focus_on_their_question() -> void:
	await _built()
	_made.commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": CHECK})
	await _frames()
	var check := _made.driver.index.place_named(CHECK)
	var link := _press(FormActions.SHOWS_QUESTION, &"name")
	_verdict.check(_words(check).has("1 answer needs attention") and _words(check).has("name: This answer is needed"), "the review's summary says how many need attention, and each: %s" % [_words(check)])
	link.pressed()
	await _frames()
	_verdict.check(_made.driver.get_top().has(ABOUT) and _question(&"name").is_ancestor_of(root.gui_get_focus_owner()), "its link lands the focus on the question")
	_made.commands.dispatch(Chimes.GLOBAL, FormActions.answering(&"kind"), {"value": "cafe"})
	_made.commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": CHECK})
	await _frames()
	_verdict.check(_words(check).has("cafe") and _words(check).has("Not answered"), "the review writes each answer back, a choice by its words, one not given said so: %s" % [_words(check)])
	var changes: Array = check.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable and (part as Pressable).action == FormActions.SHOWS_QUESTION and (part as Pressable).payload().get("value") == &"kind" and not _words(part).has("kind: This answer is needed"))
	changes.back().pressed()
	await _frames()
	_verdict.check(_made.driver.get_top().has(ABOUT) and _question(&"kind").is_ancestor_of(root.gui_get_focus_owner()), "and its change lands the focus on the question: %s" % [root.gui_get_focus_owner()])
	_done()


func _leaving_with_answers_unsaved_asks_and_going_on_lets_them_go() -> void:
	await _built()
	_made.commands.dispatch(Chimes.GLOBAL, FormActions.answering(&"name"), {"line": "Crate"})
	_press(FormActions.CLOSES).pressed()
	await _frames()
	var asked := _made.driver.get_top() == [_leaving]
	_press(_made.ui.CLOSES).pressed()
	await _frames()
	var stayed := _made.driver.get_top().has(ABOUT) and _form.get_answers().has(&"name")
	_press(FormActions.CLOSES).pressed()
	await _frames()
	_press(FormActions.LEAVES_WITHOUT_SAVING).pressed()
	await _frames()
	_verdict.check(asked and stayed and _made.driver.get_top().has(OUTSIDE) and _form.get_answers().is_empty(), "closing with an answer unsaved asks; staying keeps it; leaving without saving lets it go and leaves: %s %s %s" % [asked, stayed, _made.driver.get_top()])
	_made.commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": ABOUT})
	_made.commands.dispatch(Chimes.GLOBAL, FormActions.SAVES_DRAFT, {})
	_press(FormActions.CLOSES).pressed()
	await _frames()
	_verdict.check(_made.driver.get_top().has(OUTSIDE), "with every answer in the draft, closing asks nothing")
	_done()


func _a_page_is_no_wider_than_is_read_on_a_wide_window_and_the_whole_width_on_one_on_its_end() -> void:
	await _built()
	var page: Control = _question(&"name")
	# up from the question to the sheet it stands on
	while page.theme_type_variation != Fields.PAGE:
		page = page.get_parent()
	var wide := page.size.x / float(root.size.x)
	root.size = Vector2i(720, 1280)
	await _frames()
	var tall := page.size.x / float(root.size.x)
	root.size = Vector2i(1280, 800)
	_verdict.check(wide <= FormSteps.READABLE + 0.01 and tall > 0.9, "the page takes at most %.2f of a wide window, and near all of one on its end: %.2f, %.2f" % [FormSteps.READABLE, wide, tall])
	_done()
