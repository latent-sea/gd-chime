extends SceneTree

## What must be true of a form of many steps (form.gd, answers.gd,
## question.gd): every answer is held through the door as it was put in, a
## half-typed day and a rule broken included, so no mistake loses anything;
## a problem shows only once its step is checked - left, or sending tried -
## and then follows every change; a question asked while another answer
## holds keeps its answer while hidden, breaks no rule and is written in no
## review; a choice whose options moved under it is a problem; a file of a
## kind or size not taken is refused and never held; the answers are dirty
## against the draft saved, leaving asks
## while dirty and discarding puts the draft back; sending with problems
## checks every step and takes the reader to the first problem's step
## entered as its key, answered with how many, and sending with none sends,
## lets the draft go and takes the reader where a sent form goes; a draft
## kept in a settings file comes back into a fresh form clean, and an answer
## there that fits no question is left out; each step's state goes open,
## needs, done; the review writes every answer back the reader's way;
## starting again forgets everything; and a press goes to a step or to a
## question, never one not asked, while typing into a searched choice
## narrows its options.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_form.gd

const Fixture := preload("res://tests/fixture.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Form := preload("res://addons/gd_chime/form.gd")
const FormActions := preload("res://addons/gd_chime/form_actions.gd")
const Question := preload("res://addons/gd_chime/question.gd")
const Dates := preload("res://addons/gd_chime/dates.gd")
const SettingsFile := preload("res://addons/gd_chime/settings_file.gd")
const Verdict := preload("res://tests/verdict.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Reads := preload("res://addons/gd_chime/reads.gd")

const ABOUT := &"about"
const MONEY := &"money"
const CHECK := &"check"
const SENT := &"sent"
const KEPT := "user://test_form_draft.json"

var _verdict := Verdict.new()
var _made: Fixture
var _form: Form
var _kinds: Fixture.Model  # holds the choice's options, which move under it


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	await _verdict.states(_every_answer_is_held_as_it_was_put_in_and_a_broken_rule_never_stops_it)
	await _verdict.states(_a_problem_shows_only_once_its_step_is_checked_and_then_follows_every_change)
	await _verdict.states(_a_question_asked_while_another_answer_holds_keeps_its_answer_while_hidden)
	await _verdict.states(_a_choice_whose_options_moved_under_it_is_a_problem)
	await _verdict.states(_a_file_of_a_kind_or_size_not_taken_is_refused_and_never_held)
	await _verdict.states(_the_answers_are_dirty_against_the_draft_and_leaving_asks_while_they_are)
	await _verdict.states(_sending_with_problems_takes_the_reader_to_the_first_and_sends_nothing)
	await _verdict.states(_sending_with_none_sends_lets_the_draft_go_and_takes_the_reader_on)
	await _verdict.states(_a_draft_kept_in_a_settings_file_comes_back_clean_and_a_stranger_is_left_out)
	await _verdict.states(_each_step_goes_open_then_needs_then_done)
	await _verdict.states(_the_review_writes_every_answer_back_the_readers_way)
	await _verdict.states(_starting_again_forgets_everything)
	await _verdict.states(_a_press_goes_to_a_step_or_to_a_question_and_a_searched_choice_narrows)
	quit(_verdict.deliver(get_script()))


## The questions: a name and a day founded, needed, and a kind picked, about
## the business; whether it owns vans, how many - asked while it does - what
## it is worth, more than nothing, and its papers, a small PDF, about money.
func _questions() -> Array:
	var worth_something := func(worth: Variant, _form: Object) -> Phrase: return Phrase.of("the worth must be more than nothing") if worth != null and worth <= 0.0 else null
	return [
		Question.make(&"name", ABOUT, Phrase.of("name"), Question.TEXT, {"needed": true}),
		Question.make(&"founded", ABOUT, Phrase.of("founded"), Question.DAY, {"needed": true}),
		Question.make(&"kind", ABOUT, Phrase.of("kind"), Question.CHOICE, {"options": _kinds.of(&"items"), "search": true}),
		Question.make(&"sort", ABOUT, Phrase.of("sort"), Question.CHOICE, {"narrowed_by": [&"kind", {"shop": [{"value": "grocer", "words": "grocer"}], "cafe": [{"value": "bakery", "words": "bakery"}, {"value": "diner", "words": "a diner"}]}]}),
		Question.make(&"owns", MONEY, Phrase.of("owns vans"), Question.YES_NO),
		Question.make(&"vans", MONEY, Phrase.of("vans"), Question.QUANTITY, {"needed": true, "while": [&"owns", true]}),
		Question.make(&"worth", MONEY, Phrase.of("worth"), Question.AMOUNT, {"mark": "£", "rule": worth_something}),
		Question.make(&"papers", MONEY, Phrase.of("papers"), Question.FILE, {"kinds": ["pdf"], "most_bytes": 1048576}),
	]


## The app: the three steps and where a sent form goes, in a stack, and the
## form over them, entered at the first step.
func _built() -> void:
	_made = Fixture.new(root)
	_kinds = Fixture.Model.new(_made.chimes)
	_kinds.set_value(&"items", [{"value": "shop", "words": "shop"}, {"value": "cafe", "words": "cafe"}])
	_form = Form.new(_made.chimes, _made.commands, _questions(), [[ABOUT, Phrase.of("about")], [MONEY, Phrase.of("money")], [CHECK, Phrase.of("check")]], SENT)
	_form.declare(_made.actions)
	var ui := _made.ui
	var steps: Array = [ABOUT, MONEY, CHECK, SENT].map(func(named: StringName) -> RefCounted: return ui.screen(named, [ui.text(String(named))]))
	ui.build(ui.app(&"app", [ui.stack(steps)]), root)
	_made.commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": ABOUT})
	await process_frame


func _done() -> void:
	_form.free()
	_kinds.free()
	_made.done()


## An answer put in through the door, as its control carries it; the answer.
func _put(key: StringName, payload: Dictionary) -> Phrase:
	return _made.commands.dispatch(Chimes.GLOBAL, Form.answering(key), payload)


func _go(step: StringName) -> void:
	_made.commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": step})


## Every answer the needed questions want, and nothing wrong.
func _answer_all() -> void:
	_put(&"name", {"line": "Crate & Co"})
	_put(&"founded", {"value": null, "line": "01/02/2020"})
	_put(&"worth", {"value": null, "line": "12,500"})


func _every_answer_is_held_as_it_was_put_in_and_a_broken_rule_never_stops_it() -> void:
	await _built()
	var answers := [_put(&"name", {"line": "Crate"}), _put(&"founded", {"value": null, "line": "31/02/20"}), _put(&"kind", {"value": "cafe"}), _put(&"owns", {"value": true}), _put(&"vans", {"value": 3.0})]
	var held := _form.get_answers()
	_verdict.check(answers.all(func(answer: Variant) -> bool: return answer == null), "every answer is taken through the door, the day naming no day among them: %s" % [answers])
	_verdict.check(held == {&"name": "Crate", &"founded": "31/02/20", &"kind": "cafe", &"owns": true, &"vans": 3.0}, "and held as it was put in: the line typed, the half-typed day's line, the value picked: %s" % [held])
	_verdict.check(_form.get_errors().map(func(error: Dictionary) -> StringName: return error["value"]) == [&"founded"], "the day naming no day is a problem, held beside it: %s" % [_form.get_errors()])
	_put(&"founded", {"value": null, "line": "19/09/2026"})
	_verdict.check(_form.value_of(&"founded") == Dates.day_of(2026, 9, 19) and _form.get_errors().is_empty(), "typed on to a whole day, it reads as that day and the problem is gone")
	var needed_now := Question.make(&"needed_now", ABOUT, Phrase.of("needed now"), Question.TEXT, {"rule": func(given: Variant, _form: Object) -> Phrase: return Phrase.of("needed now") if given == null else null})
	_verdict.check(str(Question.problem(needed_now, null, _form)) == "needed now" and Question.problem(needed_now, "yes", _form) == null, "an answer not needed and not given is asked of the question's own rule, which may say it is needed now")
	_done()


func _a_problem_shows_only_once_its_step_is_checked_and_then_follows_every_change() -> void:
	await _built()
	_put(&"founded", {"value": null, "line": "nineteen"})
	_verdict.check(_form.get_errors().size() == 2 and _form.get_messages().is_empty() and _form.message(&"name").read() == null, "on the step, the name missing and the day wrong are problems, but none is shown yet: %s" % [_form.get_messages()])
	_go(MONEY)
	var shown := _form.get_messages()
	_verdict.check(shown.keys() == [&"name", &"founded"] and str(shown[&"name"]) == "This answer is needed" and str(shown[&"founded"]) == "Type a date as DD/MM/YYYY", "the step left, both show, each saying why: %s" % [shown])
	_put(&"name", {"line": "Crate"})
	_verdict.check(_form.message(&"name").read() == null and _form.get_messages().has(&"founded"), "and the name typed, its message goes at once, the other staying")
	_verdict.check(not _form.get_messages().has(&"worth"), "the step the reader is on is not checked by arriving: %s" % [_form.get_messages()])
	_done()


func _a_question_asked_while_another_answer_holds_keeps_its_answer_while_hidden() -> void:
	await _built()
	_put(&"owns", {"value": true})
	_verdict.check(_form.is_asked(&"vans") and _form.get_errors().any(func(error: Dictionary) -> bool: return error["value"] == &"vans"), "owning vans, how many is asked, and needed")
	_put(&"vans", {"value": 4.0})
	_put(&"owns", {"value": false})
	var reviewed: Array = _form.get_review().filter(func(step: Dictionary) -> bool: return step["value"] == MONEY)[0]["answers"].map(func(answer: Dictionary) -> StringName: return answer["value"])
	_verdict.check(not _form.is_asked(&"vans") and _form.get_answers()[&"vans"] == 4.0 and not reviewed.has(&"vans"), "owning none, it is not asked, yet its answer is kept, and the review leaves it out: %s" % [reviewed])
	_put(&"vans", {"value": null})
	_verdict.check(not _form.get_errors().any(func(error: Dictionary) -> bool: return error["value"] == &"vans"), "not asked, even empty it breaks no rule")
	_put(&"vans", {"value": 4.0})
	_put(&"owns", {"value": true})
	_verdict.check(_form.is_asked(&"vans") and _form.held(&"vans").read() == 4.0 and _form.holds(&"owns", true).read(), "asked again, it has what it had")
	_done()


func _a_choice_whose_options_moved_under_it_is_a_problem() -> void:
	await _built()
	_put(&"kind", {"value": "cafe"})
	_verdict.check(_form.get_errors().all(func(error: Dictionary) -> bool: return error["value"] != &"kind"), "a choice among the options is no problem")
	_kinds.set_value(&"items", [{"value": "shop", "words": "shop"}])
	await process_frame
	var problem: Array = _form.get_errors().filter(func(error: Dictionary) -> bool: return error["value"] == &"kind")
	_verdict.check(problem.size() == 1 and str(problem[0]["says"]) == "Choose again: this is not one of the options now" and _form.get_answers()[&"kind"] == "cafe", "the options moved under it, the choice held is a problem, and still held: %s" % [problem])
	_verdict.check(_form.options(&"sort").read().map(func(option: Dictionary) -> String: return option["value"]) == ["bakery", "diner"], "a choice narrowed by the kind offers the cafe's sorts alone: %s" % [_form.options(&"sort").read()])
	_put(&"sort", {"value": "diner"})
	_put(&"kind", {"value": "shop"})
	var stale: Array = _form.get_errors().filter(func(error: Dictionary) -> bool: return error["value"] == &"sort")
	_verdict.check(_form.options(&"sort").read().size() == 1 and stale.size() == 1 and _form.get_answers()[&"sort"] == "diner" and str(Question.written(_form.get_question(&"sort"), "diner")) == "a diner", "the kind changed to a shop, the diner is held still, is a problem, and is written by its words: %s" % [stale])
	_done()


func _a_file_of_a_kind_or_size_not_taken_is_refused_and_never_held() -> void:
	await _built()
	var wrong_kind := _put(&"papers", {"value": {"name": "photo.png", "size": 2048, "kind": "png"}})
	var too_big := _put(&"papers", {"value": {"name": "accounts.pdf", "size": 3145728, "kind": "PDF"}})
	_verdict.check(str(wrong_kind) == "Only pdf files are taken" and str(too_big) == "The file is 3.0 MB and at most 1.0 MB is taken" and not _form.get_answers().has(&"papers"), "a PNG and a PDF too large are refused, saying why, and nothing is held: %s / %s" % [wrong_kind, too_big])
	var taken := _put(&"papers", {"value": {"name": "accounts.pdf", "size": 524288, "kind": "pdf"}})
	_verdict.check(taken == null and _form.get_answers()[&"papers"]["name"] == "accounts.pdf", "a small PDF is held, its name, size and kind - never its bytes")
	_verdict.check(str(Question.written(_form.get_question(&"papers"), _form.get_answers()[&"papers"])) == "accounts.pdf, 512 KB", "and written back by its name and size: %s" % Question.written(_form.get_question(&"papers"), _form.get_answers()[&"papers"]))
	_done()


func _the_answers_are_dirty_against_the_draft_and_leaving_asks_while_they_are() -> void:
	await _built()
	var door := _made.commands
	_verdict.check(not _form.get_dirty() and _form.would(Driver.LEAVES, {}) == null, "nothing put in, the answers are the draft, and leaving asks nothing")
	_put(&"name", {"line": "Crate"})
	_verdict.check(_form.get_dirty() and str(_form.would(Driver.LEAVES, {})) == "Leave without saving? What changed since the draft was saved will be lost.", "an answer put in, they are dirty, and leaving asks: %s" % _form.would(Driver.LEAVES, {}))
	_verdict.check(door.dispatch(Chimes.GLOBAL, Form.SAVES_DRAFT, {}) == null and not _form.get_dirty() and _form.saved() == {"answers": {&"name": "Crate"}}, "saved, they are clean, and the draft holds them: %s" % [_form.saved()])
	_put(&"name", {"line": "Crates"})
	_made.commands.dispatch(Chimes.GLOBAL, Form.DISCARDS, {})
	_verdict.check(_form.get_answers() == {&"name": "Crate"} and not _form.get_dirty(), "changed again and discarded, the answers are the draft once more: %s" % [_form.get_answers()])
	_done()


func _sending_with_problems_takes_the_reader_to_the_first_and_sends_nothing() -> void:
	await _built()
	_go(CHECK)
	_put(&"worth", {"value": null, "line": "0"})
	var answer := _made.commands.dispatch(Chimes.GLOBAL, Form.SENDS, {})
	_verdict.check(str(answer) == "3 answers need attention" and not _form.get_sent(), "sent with the name, the day and a worthless worth wrong, it is answered with how many and nothing is sent: %s" % answer)
	_verdict.check(_made.driver.get_top() == [&"app", ABOUT] and _made.driver.get_parameter(ABOUT) == &"name", "the reader is taken to the first problem's step, entered as its key: %s %s" % [_made.driver.get_top(), _made.driver.get_parameter(ABOUT)])
	_verdict.check(_form.get_messages().keys() == [&"name", &"founded", &"worth"], "and every step is checked, so every problem shows: %s" % [_form.get_messages().keys()])
	_done()


func _sending_with_none_sends_lets_the_draft_go_and_takes_the_reader_on() -> void:
	await _built()
	_answer_all()
	_go(CHECK)
	var answer := _made.commands.dispatch(Chimes.GLOBAL, Form.SENDS, {})
	_verdict.check(answer == null and _form.get_sent() and _made.driver.get_top() == [&"app", SENT], "nothing wrong, the form is sent and the reader taken where a sent form goes: %s" % [_made.driver.get_top()])
	_verdict.check(_form.saved() == {"answers": {}} and not _form.get_dirty() and _form.would(Driver.LEAVES, {}) == null, "the draft is let go, and nothing asks before leaving: %s" % [_form.saved()])
	_verdict.check(str(_made.commands.refusal(Chimes.GLOBAL, Form.SENDS, {})) == "This form has been sent", "and it cannot be sent twice")
	_done()


func _a_draft_kept_in_a_settings_file_comes_back_clean_and_a_stranger_is_left_out() -> void:
	DirAccess.remove_absolute(KEPT)
	await _built()
	var file := SettingsFile.new(_made.chimes, KEPT)
	file.keep("draft", _form)
	_answer_all()
	_put(&"owns", {"value": true})
	_put(&"vans", {"value": 2.0})
	_made.commands.dispatch(Chimes.GLOBAL, Form.SAVES_DRAFT, {})
	# the draft rings at the frame's end, and the file follows it
	await process_frame
	file.write()
	var before := _form.get_answers()
	file.free()
	_done()
	await _built()
	var written := JSON.parse_string(FileAccess.get_file_as_string(KEPT)) as Dictionary
	written["draft"]["answers"]["vans"] = "two"
	written["draft"]["answers"]["unasked"] = "x"
	var stale := FileAccess.open(KEPT, FileAccess.WRITE)
	stale.store_string(JSON.stringify(written))
	stale.close()
	var again := SettingsFile.new(_made.chimes, KEPT)
	again.keep("draft", _form)
	before.erase(&"vans")
	_verdict.check(_form.get_answers() == before and not _form.get_dirty(), "a fresh form over the file has the draft back, clean, but for the answer that no longer fits and the one no question asks: %s" % [_form.get_answers()])
	again.free()
	_done()
	DirAccess.remove_absolute(KEPT)


func _each_step_goes_open_then_needs_then_done() -> void:
	await _built()
	var state_of := func(step: StringName) -> StringName: return _form.get_steps().filter(func(one: Dictionary) -> bool: return one["value"] == step)[0]["state"]
	_verdict.check(state_of.call(ABOUT) == &"open", "a step not yet left is open")
	_go(MONEY)
	_verdict.check(state_of.call(ABOUT) == &"needs" and _form.get_steps()[0]["count"] == 2, "left with two problems, it needs them: %s" % [_form.get_steps()[0]])
	_answer_all()
	_verdict.check(state_of.call(ABOUT) == &"done" and state_of.call(MONEY) == &"open", "answered, it is done; the step the reader is on is still open")
	_done()


func _the_review_writes_every_answer_back_the_readers_way() -> void:
	await _built()
	_answer_all()
	_put(&"kind", {"value": "cafe"})
	_put(&"owns", {"value": true})
	_put(&"vans", {"value": 2.0})
	var said: Dictionary = {}
	# every step reviewed, every answer as its words
	for step: Dictionary in _form.get_review():
		for answer: Dictionary in step["answers"]:
			said[answer["value"]] = str(answer["shown"])
	_verdict.check(_form.get_review().map(func(step: Dictionary) -> StringName: return step["value"]) == [ABOUT, MONEY], "the review holds the steps with questions asked, the check step asking none left out")
	_verdict.check(said == {&"name": "Crate & Co", &"founded": "1 February 2020", &"kind": "cafe", &"sort": "Not answered", &"owns": "Yes", &"vans": "2", &"worth": "£12,500", &"papers": "Not answered"}, "every answer written the reader's way - the day in words, the sum with its mark, yes, the choice's words - and one not given said so: %s" % [said])
	_done()


func _starting_again_forgets_everything() -> void:
	await _built()
	_answer_all()
	_made.commands.dispatch(Chimes.GLOBAL, Form.SAVES_DRAFT, {})
	_go(MONEY)
	_made.commands.dispatch(Chimes.GLOBAL, Form.STARTS_AFRESH, {})
	_verdict.check(_form.get_answers().is_empty() and _form.get_messages().is_empty() and _form.saved() == {"answers": {}} and not _form.get_dirty(), "started again, no answer, no message and no draft remain")
	_done()


func _a_press_goes_to_a_step_or_to_a_question_and_a_searched_choice_narrows() -> void:
	await _built()
	var door := _made.commands
	door.dispatch(Chimes.GLOBAL, Form.SHOWS_STEP, {"value": MONEY})
	var on_step := _made.driver.get_top()
	door.dispatch(Chimes.GLOBAL, Form.SHOWS_QUESTION, {"value": &"founded"})
	_verdict.check(on_step == [&"app", MONEY] and _made.driver.get_top() == [&"app", ABOUT] and _made.driver.get_parameter(ABOUT) == &"founded", "a press goes to a step, and another to a question - its step entered as its key: %s %s" % [on_step, _made.driver.get_parameter(ABOUT)])
	_verdict.check(str(door.refusal(Chimes.GLOBAL, Form.SHOWS_QUESTION, {"value": &"vans"})) == "This question is not asked now", "a question not asked now cannot be gone to")
	door.dispatch(Chimes.GLOBAL, FormActions.types(&"kind"), {"line": "CA"})
	_verdict.check(_form.narrowing(&"kind").get_options() == [{"value": "cafe", "words": "cafe"}] and _made.actions.has(FormActions.chooses(&"kind")), "typing into a searched choice narrows its options, and its opening is declared: %s" % [_form.narrowing(&"kind").get_options()])
	_put(&"name", {"line": "Crate"})
	var before := _form.get_drafted()
	door.dispatch(Chimes.GLOBAL, Form.SAVES_DRAFT, {})
	_verdict.check(not before and _form.get_drafted(), "until saved there is no draft to go back to; saved, there is")
	Reads.begin()
	door.refusal(Chimes.GLOBAL, Form.answering(&"name"), {"line": "Crates"})
	var answering: Dictionary = Reads.end()
	Reads.begin()
	door.refusal(Chimes.GLOBAL, Form.SENDS, {})
	var sending: Dictionary = Reads.end()
	_verdict.check(answering.is_empty() and not sending.is_empty(), "a press answering a question reads no value for its refusal, so no keystroke redraws the hundreds of them; sending's reads whether the form was sent: %s %s" % [answering, sending])
	var first := _form.get_review()
	_verdict.check(_form.get_review() == first and is_same(_form.get_review(), first), "a reading asked twice with nothing moved between is the one worked out, not worked out again")
	_put(&"name", {"line": "Crates"})
	_verdict.check(not is_same(_form.get_review(), first) and str(_form.get_review()).contains("Crates"), "an answer moved, it is worked out afresh")
	_done()
