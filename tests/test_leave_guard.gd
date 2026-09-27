extends SceneTree

## What must be true of a place that asks before it is left (leave_guard.gd):
## a move that would empty it is stopped before any of it runs and its
## question raised with the move as the parameter, the reader where they
## were, the press paused - not done, and refused by nobody, its button
## showing nothing; only a command that moves the reader is ever asked
## about; answered onward, the move - a GO with a parameter, a Back, a
## lowering, a press that changes something - lands exactly as it does with
## no guard; cancelled, everything is as it was; a place not asking now is
## left without a word, and one asking is asked afresh each time; a guard
## two levels inside the place left counts; raising and lowering a pop-up,
## the question included, never counts as leaving; routing never leads out
## of such a place, whose buttons stay pressable; one leaving confirmed
## passes the guard once; nothing is seen leaving until it is confirmed; and
## an application with such a place starts, its startup check reporting a
## question that is no pop-up.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_leave_guard.gd
##
## The tree is built and first entered by hand, as test_sequences.gd builds
## its own. Each place counts its filling and emptying, and the two models
## record what they are told, so "as it was" and "as with no guard" are
## compared whole.

const Fixture := preload("res://tests/fixture.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Token := preload("res://addons/gd_chime/token.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Confirm := preload("res://addons/gd_chime/components/recipes/confirm.gd")
const Sheet := preload("res://addons/gd_chime/components/recipes/sheet.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")

const Verdict := preload("res://tests/verdict.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")


const HOME := &"home"
const DESK := &"desk"
const TRAY := &"tray"
const DRAFT := &"draft"
const NOTE := &"note"
const LEDGER := &"ledger"

const SKETCH := &"sketch"

const GOES_BACK := &"goes_back"
const OPENS := &"opens_the_ledger"
const WRITES := &"writes"
const FILES := &"files_and_goes_home"
const JOTS := &"jots"
const COUNTS := &"counts"
const SCRIBBLES := &"scribbles"
const LEAVES_ANYWAY := &"leaves_anyway"

const WORDS := "Leave without saving?"
## Every kind of leaving a confirm must complete, each named for what it is.
const KINDS: Array[String] = ["a GO with a parameter", "a Back", "a lowering", "a press that changes something"]

var _verdict := Verdict.new()
var _leaving: StringName  # the question asked before a place is left, named by the builder
var _zoom: StringName  # the pop-up asking nothing, named by the builder
var _pad: StringName  # the pop-up holding a screen that asks, named by the builder

var _made: Fixture
var _drafts: Counting  # answers for the draft: told its actions, asked whether it may be left
var _sketches: Counting  # answers for the sketch in the pad, the same way
var _counts: Dictionary = {}  # place -> [times filled, times emptied]


## A model that counts the times it is asked whether its place may be left.
class Counting extends Fixture.Model:
	var asked_to_leave: int = 0

	func would(action: StringName, payload: Dictionary) -> Phrase:
		if action == Driver.LEAVES:
			asked_to_leave += 1
		return super(action, payload)


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(400, 400)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_a_leaving_asked_first_raises_the_question_with_the_move_as_its_parameter_and_leaves_the_reader_where_they_were)
	await _verdict.states(_a_press_paused_into_the_question_shows_no_refusal_on_its_button_and_the_record_says_it_was_not_done)
	await _verdict.states(_only_a_command_that_moves_the_reader_asks_whether_a_place_may_be_left)
	await _verdict.states(_confirmed_every_kind_of_leaving_lands_exactly_as_it_does_with_no_guard)
	await _verdict.states(_cancelled_every_kind_of_leaving_leaves_everything_as_it_was)
	await _verdict.states(_a_place_not_asking_now_is_left_without_a_word_and_one_asking_is_asked_afresh)
	await _verdict.states(_a_place_two_levels_inside_the_one_left_asks_and_only_a_move_emptying_it_is_stopped)
	await _verdict.states(_raising_and_lowering_a_pop_up_never_counts_as_leaving_and_nor_does_the_question)
	await _verdict.states(_routing_never_leads_out_of_a_place_asking_first_whose_buttons_stay_pressable)
	await _verdict.states(_one_leaving_confirmed_passes_the_guard_once_and_the_next_asks_again)
	await _verdict.states(_nothing_is_seen_leaving_until_the_question_is_answered_onward)
	await _verdict.states(_an_application_with_a_place_asking_first_starts_and_a_question_that_is_no_pop_up_is_reported)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## A screen counting its filling and emptying, answered for by this model and
## asking this question first, if given.
func _screen(named: StringName, content: Array, model: Object = null, asks: Desc = null) -> Desc:
	_counts[named] = [0, 0]
	return _made.ui.screen(named, content, model, {on_fill = func(_token: Token) -> void: _counts[named][0] += 1, on_empty = func() -> void: _counts[named][1] += 1, asks_before_leaving = asks})


## The app: a strip with Back and a link to the ledger as 7; a stack of the
## home, a desk whose tray holds the draft - two levels inside the desk,
## asking before it is left while its model refuses - beside a note, and the
## ledger. Beside the app: the one question, a zoom, and a pad whose sketch
## asks too. Entered at the home.
func _built() -> void:
	_made = Fixture.new(root, {GOES_BACK: "go back", OPENS: "open the ledger", WRITES: "write", FILES: "file it and go home", JOTS: "jot", COUNTS: "count", SCRIBBLES: "scribble", LEAVES_ANYWAY: "leave anyway"})
	var ui := _made.ui
	_counts.clear()
	_drafts = Counting.new(_made.chimes, &"drafts")
	_drafts.refuse(Driver.LEAVES, Phrase.of(WORDS))
	_sketches = Counting.new(_made.chimes, &"sketches")
	_sketches.refuse(Driver.LEAVES, Phrase.of(WORDS))
	var question := Confirm.for_leaving(ui, LEAVES_ANYWAY)
	_leaving = question.get_place()
	var strip := ui.row([ui.button(GOES_BACK, {goes_to = Driver.BACK}), ui.button(OPENS, {payload = {"parameter": 7}, goes_to = LEDGER})])
	var draft := _screen(DRAFT, [ui.column([ui.button(WRITES), ui.button(FILES, {goes_to = HOME})])], _drafts, question)
	var tray := _screen(TRAY, [ui.stack([draft, _screen(NOTE, [ui.button(JOTS)])])])
	var stack := ui.stack([_screen(HOME, [ui.text("home")]), _screen(DESK, [tray]), _screen(LEDGER, [ui.button(COUNTS)])])
	ui.build(ui.app(&"app", [ui.column([strip, stack.grow()])]), root)
	# a pop-up asking nothing, and a pop-up holding a screen asking the same question; the question itself is lifted with what asks it
	var zoom := ui.pop_up(&"zoom", func(_which: Bound) -> Desc: return ui.text("zoomed"))
	var pad := ui.pop_up(&"pad", func(_which: Bound) -> Desc: return _screen(SKETCH, [ui.button(SCRIBBLES)], _sketches, question))
	_zoom = zoom.get_place()
	_pad = pad.get_place()
	for description: Desc in [zoom, pad]:
		ui.build(description, root)
	_made.commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": &"app"})
	await _a_frame_passes()


func _done() -> void:
	_drafts.free()
	_sketches.free()
	_made.done()


func _place(named: StringName) -> Control:
	return _made.driver.index.place_named(named)


## A GO through the door, with a parameter if given; the answer.
func _go(named: StringName, parameter: Variant = null) -> Phrase:
	var payload: Dictionary = {"place": named} if parameter == null else {"place": named, "parameter": parameter}
	return _made.commands.dispatch(Chimes.GLOBAL, Driver.GO, payload)


## The one pressable of this action, anywhere under the root.
func _button(does: StringName) -> Pressable:
	var found: Array = root.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable and (part as Pressable).action == does)
	return found[0]


## The question's own way out: the press beside the confirm, never the shade, which is the same way out.
func _cancel() -> Pressable:
	return root.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable and (part as Pressable).action == _made.ui.CLOSES and part.theme_type_variation != Sheet.SHADE)[0]


## A press of the button of this action, as a hand would land it; its answer.
func _press(does: StringName) -> Phrase:
	_button(does).pressed()
	return _made.commands.get_last()["answer"]


func _texts(node: Node) -> Array[String]:
	var found: Array[String] = []
	# every piece under this one, for the words it shows
	for child: Node in node.get_children():
		if child is Text:
			found.append((child as Text).get_text())
		found.append_array(_texts(child))
	return found


## Where the reader stands, as everything a leaving could change: the state -
## the question's own parameter set aside, which the chart keeps after a
## pop-up is lowered as it keeps every pop-up's - the action of the control
## holding the focus, what the models were told, and every filling and emptying.
func _standing() -> Dictionary:
	var state := _made.driver.get_state()
	state["params"].erase(_leaving)
	# every entry's parameters, the question's set aside there too
	for walked: Dictionary in state["history_params"]:
		walked.erase(_leaving)
	var focused := root.gui_get_focus_owner()
	return {"state": state, "focus": (focused as Pressable).action if focused is Pressable else &"", "told": _drafts.told_actions + _sketches.told_actions, "counts": _counts.duplicate(true)}


## The reader taken to where this kind of leaving starts, the focus on the
## control a hand would be on there.
func _walk_to(kind: String) -> void:
	match kind:
		"a GO with a parameter", "a Back":
			_go(DESK)
			_button(WRITES).grab_focus()
		"a lowering":
			_go(_pad)
			_button(SCRIBBLES).grab_focus()
		"a press that changes something":
			_go(DESK)
			_button(FILES).grab_focus()
	await _a_frame_passes()


## This kind of leaving, made; its answer.
func _leave(kind: String) -> Phrase:
	match kind:
		"a GO with a parameter":
			return _go(LEDGER, 7)
		"a Back":
			return _press(GOES_BACK)
		"a lowering":
			return _made.commands.dispatch(Chimes.GLOBAL, Driver.LOWERS, {"place": _pad})
	return _press(FILES)


func _a_leaving_asked_first_raises_the_question_with_the_move_as_its_parameter_and_leaves_the_reader_where_they_were() -> void:
	await _built()
	_go(DESK)
	await _a_frame_passes()
	_button(WRITES).grab_focus()
	var before := _standing()
	var token: Token = _place(DRAFT).token
	var answer := _go(HOME)
	await _a_frame_passes()
	var now := _standing()
	_verdict.check(before["state"]["path"] == [&"app", DESK, TRAY, DRAFT] and str(answer) == WORDS, "on the draft, a GO home is answered with the words its guard asks: %s" % answer)
	_verdict.check(_made.driver.get_top() == [_leaving] and _made.driver.get_parameter(_leaving) == {"region": Chimes.GLOBAL, "action": Driver.GO, "payload": {"place": HOME}, "asks": _made.driver.get_parameter(_leaving)["asks"]} and str(_made.driver.get_parameter(_leaving)["asks"]) == WORDS, "the question is raised, entered as the move it stopped and the words: %s" % [_made.driver.get_parameter(_leaving)])
	_verdict.check(now["state"]["path"] == before["state"]["path"] and now["state"]["history"] == before["state"]["history"] and now["counts"] == before["counts"] and token.is_live(), "and the reader is where they were: the path and the history as they were, nothing emptied, the draft's stay alive: %s" % [now["counts"]])
	_verdict.check(_texts(_place(_leaving)).has(WORDS) and root.gui_get_focus_owner() == _cancel(), "the question says the guard's words, the focus on its cancel")
	_done()


## A press paused into the question is refused by nobody: the button pressed
## keeps no refusal and draws no reason - the words are the question's - and
## the door's record still says it was not done, and that it was paused.
func _a_press_paused_into_the_question_shows_no_refusal_on_its_button_and_the_record_says_it_was_not_done() -> void:
	await _built()
	_go(DESK)
	await _a_frame_passes()
	var files := _button(FILES)
	files.pressed()
	await _a_frame_passes()
	var last := _made.commands.get_last()
	_verdict.check(_made.driver.get_top() == [_leaving] and last["action"] == FILES and str(last["answer"]) == WORDS and last["paused"], "the press is paused into the question, and the door's record says it was not done, with the words, and paused: %s" % [last])
	_verdict.check(files.get_refusal() == null and files.is_usable() and files.reason().read() == null, "the button pressed keeps no refusal and draws no reason: the words are the question's alone: '%s'" % files.reason().read())
	_done()


## Only a command that moves the reader is put to the guard: presses going
## nowhere - each keystroke, each line typed - never ask any model whether its
## place may be left, and a press going somewhere asks, once.
func _only_a_command_that_moves_the_reader_asks_whether_a_place_may_be_left() -> void:
	await _built()
	_go(DESK)
	await _a_frame_passes()
	var asked := _drafts.asked_to_leave
	# five presses of the draft's writing, which goes nowhere
	for time: int in 5:
		_press(WRITES)
	_verdict.check(_drafts.told_actions.size() == 5 and _drafts.asked_to_leave == asked, "five presses going nowhere are told, and the draft's model is never asked whether it may be left: %d" % (_drafts.asked_to_leave - asked))
	_press(OPENS)
	_verdict.check(_drafts.asked_to_leave == asked + 1 and _made.driver.get_top() == [_leaving], "a press going somewhere asks it, once, and is stopped: %d" % (_drafts.asked_to_leave - asked))
	_done()


func _confirmed_every_kind_of_leaving_lands_exactly_as_it_does_with_no_guard() -> void:
	# every kind, made once with no guard and once asked and confirmed, and the two compared whole
	for kind: String in KINDS:
		await _built()
		_drafts.refuse(Driver.LEAVES, null)
		_sketches.refuse(Driver.LEAVES, null)
		await _walk_to(kind)
		var unguarded_answer := _leave(kind)
		await _a_frame_passes()
		var unguarded := _standing()
		_done()
		await _built()
		await _walk_to(kind)
		var answer := _leave(kind)
		await _a_frame_passes()
		var told_while_asked: Array = _drafts.told_actions + _sketches.told_actions
		_verdict.check(str(answer) == WORDS and _made.driver.get_top() == [_leaving] and told_while_asked.is_empty(), "%s from a place asking first is stopped, the question raised and nothing told: %s" % [kind, _made.driver.get_top()])
		var onward := _press(LEAVES_ANYWAY)
		await _a_frame_passes()
		var confirmed := _standing()
		_verdict.check(unguarded_answer == null and onward == null and confirmed == unguarded, "%s, confirmed, lands exactly as it does with no guard - the state, the history, the focus, what was told: %s / %s" % [kind, confirmed, unguarded])
		_verdict.check(not _made.driver.get_state()["history"].has([_leaving]), "and the question is in no history entry")
		_done()


func _cancelled_every_kind_of_leaving_leaves_everything_as_it_was() -> void:
	# every kind, asked and then cancelled
	for kind: String in KINDS:
		await _built()
		await _walk_to(kind)
		var before := _standing()
		var answer := _leave(kind)
		await _a_frame_passes()
		_verdict.check(str(answer) == WORDS and _made.driver.is_raised() and _made.driver.get_top() == [_leaving], "%s is stopped and asked: %s" % [kind, _made.driver.get_top()])
		_cancel().pressed()
		var cancelled: Phrase = _made.commands.get_last()["answer"]

		await _a_frame_passes()
		_verdict.check(cancelled == null and _standing() == before, "%s asked and cancelled: everything as it was - the state, the history, the focus back where it was, and nothing told: %s / %s" % [kind, _standing(), before])
		_done()


func _a_place_not_asking_now_is_left_without_a_word_and_one_asking_is_asked_afresh() -> void:
	await _built()
	_go(DESK)
	_drafts.refuse(Driver.LEAVES, null)
	_verdict.check(_go(HOME) == null and _made.driver.get_top() == [&"app", HOME] and not _made.driver.is_raised() and _made.driver.get_parameter(_leaving) == null, "the draft saved - its model refusing nothing - it is left without a word: %s" % [_made.driver.get_top()])
	_drafts.refuse(Driver.LEAVES, Phrase.of("Discard the note?"))
	_go(DESK)
	_verdict.check(str(_go(HOME)) == "Discard the note?" and str(_made.driver.get_parameter(_leaving)["asks"]) == "Discard the note?", "asking again, the model is asked at the moment of the move, and its words are the question's: %s" % [_made.driver.get_parameter(_leaving)])
	_done()


func _a_place_two_levels_inside_the_one_left_asks_and_only_a_move_emptying_it_is_stopped() -> void:
	await _built()
	_go(DESK)
	_verdict.check(_made.driver.get_top() == [&"app", DESK, TRAY, DRAFT] and str(_go(HOME)) == WORDS, "the desk left for the home empties the draft two levels inside it, and is stopped")
	_cancel().pressed()
	_verdict.check(str(_go(NOTE)) == WORDS, "a move within the tray, the draft to the note, empties the draft alone, and is stopped too")
	_cancel().pressed()
	_drafts.refuse(Driver.LEAVES, null)
	_go(NOTE)
	_drafts.refuse(Driver.LEAVES, Phrase.of(WORDS))
	_verdict.check(_go(HOME) == null and _made.driver.get_top() == [&"app", HOME], "from the note, the draft not on the path, a move home empties no place asking first and goes through: %s" % [_made.driver.get_top()])
	_done()


func _raising_and_lowering_a_pop_up_never_counts_as_leaving_and_nor_does_the_question() -> void:
	await _built()
	_go(DESK)
	_verdict.check(_go(_zoom) == null and _made.driver.get_top() == [_zoom] and _counts[DRAFT] == [1, 0], "a pop-up raised over the draft asking first is simply raised: raising empties nothing: %s" % [_counts[DRAFT]])
	_verdict.check(_made.commands.dispatch(Chimes.GLOBAL, Driver.LOWERS, {"place": _zoom}) == null and _counts[DRAFT] == [1, 0], "and lowered, only it is emptied")
	_go(HOME)
	_cancel().pressed()
	_go(HOME)
	_made.commands.dispatch(Chimes.GLOBAL, Driver.GOES_BACK, {})
	_verdict.check(_counts[DRAFT] == [1, 0] and _place(DRAFT).token.is_live() and _made.driver.get_top() == [&"app", DESK, TRAY, DRAFT], "the question raised and lowered, twice - by its cancel and by Back - and the draft was never emptied: %s" % [_counts[DRAFT]])
	_done()


func _routing_never_leads_out_of_a_place_asking_first_whose_buttons_stay_pressable() -> void:
	await _built()
	_go(DESK)
	var driver := _made.driver
	_verdict.check(not driver.is_reachable(OPENS) and not driver.is_reachable(FILES) and driver.is_reachable(WRITES), "on the draft asking first, a press that would leave it - the strip's link, the draft's filing - cannot be reached; the draft's writing can")
	_verdict.check(driver.route(COUNTS).is_empty(), "and there is no way to the ledger's count, every way out leaving the draft: %s" % [driver.route(COUNTS)])
	_verdict.check(_button(OPENS).is_usable() and _button(OPENS).get_state() != &"inert" and _button(FILES).is_usable(), "yet the buttons that would leave are pressable, never inert: pressing one asks")
	_drafts.refuse(Driver.LEAVES, null)
	_verdict.check(driver.is_reachable(OPENS) and driver.route(COUNTS) == [OPENS, COUNTS], "not asking, the link can be reached and the way to the count goes through it: %s" % [driver.route(COUNTS)])
	_done()


func _one_leaving_confirmed_passes_the_guard_once_and_the_next_asks_again() -> void:
	await _built()
	_go(DESK)
	_go(HOME)
	_verdict.check(_press(LEAVES_ANYWAY) == null and _made.driver.get_top() == [&"app", HOME] and not _made.driver.is_raised(), "asked and confirmed, the reader is home: %s" % [_made.driver.get_top()])
	_go(DESK)
	_verdict.check(str(_go(LEDGER)) == WORDS and _made.driver.get_top() == [_leaving], "back on the draft, the next leaving asks again: %s" % [_made.driver.get_top()])
	_done()


func _step(seconds: float) -> void:
	_made.ui.motion.step(seconds)
	await _a_frame_passes()


func _nothing_is_seen_leaving_until_the_question_is_answered_onward() -> void:
	await _built()
	_go(DESK)
	await _a_frame_passes()
	_made.ui.motion.by_hand = true
	_made.ui.motion.still = false
	var desk := _place(DESK)
	var home := _place(HOME)
	_go(HOME)
	await _step(0.06)
	var asking := _place(_leaving)
	_verdict.check(asking.visible and asking.modulate.a > 0.0 and asking.modulate.a < 1.0, "stopped, the question fades in: %s" % asking.modulate.a)
	await _step(0.5)
	_verdict.check(desk.visible and _place(DRAFT).visible and desk.position == Vector2.ZERO and desk.modulate == Color.WHITE and not home.visible, "while it stands the desk and its draft stay where they stand, whole, and the home never comes: %s %s" % [desk.position, home.visible])
	_press(LEAVES_ANYWAY)
	await _step(0.06)
	_verdict.check(desk.position.x != 0.0 and home.visible and home.position.x != 0.0, "answered onward, the desk is pushed out as the home comes: %s %s" % [desk.position.x, home.position.x])
	await _step(0.5)
	_verdict.check(not desk.visible and home.visible and home.position == Vector2.ZERO and not asking.visible, "and at rest the home stands alone, the question gone")
	_done()


## Started as an application starts - checked, then entered - a tree with a
## place asking first and its question stands: the startup check knows where
## a press going ONWARD goes. A place asking a question that is no pop-up,
## or with no model to say when, is reported, and nothing starts.
func _an_application_with_a_place_asking_first_starts_and_a_question_that_is_no_pop_up_is_reported() -> void:
	var faults: Array = []
	var told := func(wrong: Array) -> void: faults.append_array(wrong)
	var made := Fixture.new(root, {LEAVES_ANYWAY: "leave anyway"})
	var model := Fixture.Model.new(made.chimes)
	var ui := made.ui
	ui.start(ui.app(&"app", [ui.screen(DRAFT, [ui.text("draft")], model, {on_fill = Callable(), on_empty = Callable(), asks_before_leaving = Confirm.for_leaving(ui, LEAVES_ANYWAY)})]), told)
	await _a_frame_passes()
	_verdict.check(faults.is_empty() and made.driver.get_top() == [&"app", DRAFT], "the tree stands and the application starts: %s" % [faults])
	model.free()
	made.done()
	made = Fixture.new(root, {LEAVES_ANYWAY: "leave anyway"})
	model = Fixture.Model.new(made.chimes)
	ui = made.ui
	# a question that is no pop-up: a screen handed as one, which the check names
	var attic := ui.screen(&"attic", [ui.text("attic")])
	ui.start(ui.app(&"app", [ui.stack([ui.screen(DRAFT, [ui.text("draft")], model, {on_fill = Callable(), on_empty = Callable(), asks_before_leaving = attic}), ui.screen(NOTE, [ui.text("note")], null, {on_fill = Callable(), on_empty = Callable(), asks_before_leaving = Confirm.for_leaving(ui, LEAVES_ANYWAY)})])]), told)
	await _a_frame_passes()
	_verdict.check(faults.has("draft asks attic before it is left, which is no pop-up") and faults.has("note asks before it is left and has no model to say when") and made.driver.get_top().is_empty(), "a question that is no pop-up, and a place with no model to ask, are reported, and nothing starts: %s" % [faults])
	model.free()
	made.done()
