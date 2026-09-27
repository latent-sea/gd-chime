extends SceneTree

## What must be true of the confirm: the question blocks, it runs nothing
## until it is answered, the answer is the ordinary command, and the focus
## lands on the way out that is safe.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_confirm.gd

const Fixture := preload("res://tests/fixture.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Confirm := preload("res://addons/gd_chime/components/recipes/confirm.gd")
const Sheet := preload("res://addons/gd_chime/components/recipes/sheet.gd")
const Clipped := preload("res://addons/gd_chime/clipped_text.gd")
const Verdict := preload("res://tests/verdict.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")

const ASKS := &"asks_to_let_go"
const LETS_GO := &"lets_go"

var _verdict := Verdict.new()
var _made: Fixture
var _model: Fixture.Model
var _overlay: StringName  # the question's pop-up, named by the builder


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(400, 400)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_the_opener_raises_the_question_and_runs_nothing)
	await _verdict.states(_the_question_opens_with_the_focus_on_the_cancel)
	await _verdict.states(_cancelling_lowers_the_question_and_the_command_never_ran)
	await _verdict.states(_confirming_runs_the_ordinary_command_once_with_its_payload_and_lowers_the_question)
	await _verdict.states(_a_refused_command_leaves_the_question_up_and_the_confirm_says_why)
	await _verdict.states(_one_question_serves_every_row_and_acts_on_the_row_it_was_opened_as)
	await _verdict.states(_the_question_about_leaving_says_the_words_it_carries_and_goes_on_with_the_move_it_carries)
	await _verdict.states(_a_long_consequence_wraps_within_the_sheet_and_no_word_is_past_the_window)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## A confirm over one irreversible action, its button on the app opening it
## as the thing with id 7, with a model told that action from anywhere.
func _asked() -> void:
	_made = Fixture.new(root, {ASKS: "let it go", LETS_GO: "let go"})
	var ui := _made.ui
	_model = Fixture.Model.new(_made.chimes)
	_made.commands.register(_made.chimes.GLOBAL, LETS_GO, _model)
	var question := Confirm.make(ui, "this cannot be undone", LETS_GO)
	_overlay = question.get_place()
	ui.start(ui.app(&"app", [ui.button(ASKS, {opens = question, with = 7})]))
	await _a_frame_passes()


func _done() -> void:
	_model.free()
	_made.done()


func _pressables(node: Node) -> Array:
	return node.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable)


## The one pressable of this action, anywhere under the root.
func _button(does: StringName) -> Pressable:
	return _pressables(root).filter(func(part: Node) -> bool: return (part as Pressable).action == does)[0]


## The cancel: the question's own way out, the press beside the confirm - not the shade, which is the same way out.
func _cancel() -> Pressable:
	return _pressables(root).filter(func(part: Node) -> bool: return (part as Pressable).action == _made.ui.CLOSES and part.theme_type_variation != Sheet.SHADE)[0]


func _texts(node: Node) -> Array[String]:
	var found: Array[String] = []
	# every piece under this one, for the words it shows
	for child: Node in node.get_children():
		if child is Text:
			found.append((child as Text).get_text())
		found.append_array(_texts(child))
	return found


func _the_opener_raises_the_question_and_runs_nothing() -> void:
	await _asked()
	_verdict.check(_made.driver.get_top() == [&"app"], "before any press nothing is raised: %s" % [_made.driver.get_top()])
	_button(ASKS).pressed()
	await _a_frame_passes()
	_verdict.check(_made.driver.get_top() == [_overlay] and _made.driver.is_raised(), "the opener raises the question over everything: %s" % [_made.driver.get_top()])
	_verdict.check(_model.told_actions.is_empty(), "and the command it asks about has not run: %s" % [_model.told_actions])
	_verdict.check(_texts(_made.ui.root).has("this cannot be undone"), "the consequence stands in the question, in words: %s" % [_texts(_made.ui.root)])
	_done()


func _the_question_opens_with_the_focus_on_the_cancel() -> void:
	await _asked()
	_button(ASKS).pressed()
	await _a_frame_passes()
	_verdict.check(root.gui_get_focus_owner() == _cancel(), "the focus opens on the cancel, never on the confirm: %s" % [root.gui_get_focus_owner()])
	_done()


func _cancelling_lowers_the_question_and_the_command_never_ran() -> void:
	await _asked()
	_button(ASKS).pressed()
	await _a_frame_passes()
	_cancel().pressed()
	await _a_frame_passes()
	_verdict.check(not _made.driver.is_raised() and _made.driver.get_top() == [&"app"], "cancelling lowers the question: %s" % [_made.driver.get_top()])
	_verdict.check(_model.told_actions.is_empty(), "and the command never ran: %s" % [_model.told_actions])
	_done()


func _confirming_runs_the_ordinary_command_once_with_its_payload_and_lowers_the_question() -> void:
	await _asked()
	_button(ASKS).pressed()
	await _a_frame_passes()
	_button(LETS_GO).pressed()
	await _a_frame_passes()
	_verdict.check(_model.told_actions == [LETS_GO], "confirming runs the ordinary command, once: %s" % [_model.told_actions])
	_verdict.check(_made.commands.get_last()["payload"] == {"id": 7}, "carrying the id the question was opened as: %s" % [_made.commands.get_last()["payload"]])
	_verdict.check(not _made.driver.is_raised() and _made.driver.get_top() == [&"app"], "and the question is lowered once it is done: %s" % [_made.driver.get_top()])
	_done()


func _a_refused_command_leaves_the_question_up_and_the_confirm_says_why() -> void:
	await _asked()
	_button(ASKS).pressed()
	await _a_frame_passes()
	_model.refuse(LETS_GO, Phrase.of("it is not yours to let go"))
	await _a_frame_passes()
	_button(LETS_GO).pressed()
	await _a_frame_passes()
	_verdict.check(_model.told_actions.is_empty(), "a refused command does not run: %s" % [_model.told_actions])
	_verdict.check(_made.driver.is_raised() and _made.driver.get_top() == [_overlay], "the question stays up: %s" % [_made.driver.get_top()])
	_verdict.check(_texts(_button(LETS_GO)).has("it is not yours to let go"), "and the confirm says why on its own face: %s" % [_texts(_button(LETS_GO))])
	_done()


## Two rows, one question: each row's button opens the same overlay as that
## row, the words name the row it was opened as, confirming from each acts
## on its own row, and cancelling acts on neither.
func _one_question_serves_every_row_and_acts_on_the_row_it_was_opened_as() -> void:
	_made = Fixture.new(root, {ASKS: "let it go", LETS_GO: "let go"})
	var ui := _made.ui
	_model = Fixture.Model.new(_made.chimes)
	_model.set_value(&"items", [{"id": 3, "name": "third"}, {"id": 9, "name": "ninth"}])
	_made.commands.register(_made.chimes.GLOBAL, LETS_GO, _model)
	var rows: Bound = _model.of(&"items")
	var said := func(which: Bound) -> Bound: return which.map(func(id: Variant) -> String: return "let go of entry %s?" % [id])
	var question := Confirm.make(ui, said, LETS_GO)
	_overlay = question.get_place()
	var row := func(item: Bound) -> Desc: return ui.row([ui.text(item.field("name")), ui.button(ASKS, {opens = question, with = item.field("id")})])
	ui.start(ui.app(&"app", [ui.each(rows, row, func(item: Dictionary) -> int: return item["id"]).named(&"rows")]))
	await _a_frame_passes()
	var openers: Array = _pressables(ui.node_named(&"rows"))
	_verdict.check(openers.size() == 2, "an opener per row, and one question beside the app")
	(openers[1] as Pressable).pressed()
	await _a_frame_passes()
	_verdict.check(_made.driver.get_top() == [_overlay] and _made.driver.get_parameter(_overlay) == 9 and _texts(root).has("let go of entry 9?"), "the second row's opener raises the question as its row, and the words say which: %s" % [_made.driver.get_parameter(_overlay)])
	_cancel().pressed()
	await _a_frame_passes()
	_verdict.check(not _made.driver.is_raised() and _model.told_actions.is_empty(), "cancelled, the question is lowered and the command ran on neither row")
	(openers[0] as Pressable).pressed()
	await _a_frame_passes()
	_verdict.check(_made.driver.get_parameter(_overlay) == 3 and _texts(root).has("let go of entry 3?"), "the first row's opener raises the same question as its own row")
	_button(LETS_GO).pressed()
	await _a_frame_passes()
	_verdict.check(_model.told_actions == [LETS_GO] and _made.commands.get_last()["payload"] == {"id": 3} and not _made.driver.is_raised(), "confirmed, the ordinary command ran once on the row it was opened as: %s" % [_made.commands.get_last()["payload"]])
	(openers[1] as Pressable).pressed()
	await _a_frame_passes()
	_button(LETS_GO).pressed()
	await _a_frame_passes()
	_verdict.check(_made.commands.get_last()["payload"] == {"id": 9} and _model.told_actions.size() == 2, "and from the other row, on that row: %s" % [_made.commands.get_last()["payload"]])
	_done()


## The question every leaving asks, raised as the leave guard raises it -
## entered as a stopped move and the words to ask: before any move is
## stopped its confirm cannot be pressed; raised, it says the words it
## carries with the focus on the cancel; the cancel lowers it and does
## nothing else; and the confirm goes on with the move it carries. Built and
## entered by hand, as the leave guard's own test builds.
func _the_question_about_leaving_says_the_words_it_carries_and_goes_on_with_the_move_it_carries() -> void:
	_made = Fixture.new(root, {LETS_GO: "leave anyway"})
	var ui := _made.ui
	_model = Fixture.Model.new(_made.chimes)
	ui.build(ui.app(&"app", [ui.stack([ui.screen(&"here", [ui.text("here")]), ui.screen(&"there", [ui.text("there")])])]), root)
	var question := Confirm.for_leaving(ui, LETS_GO)
	_overlay = question.get_place()
	ui.build(question, root)
	_made.commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": &"app"})
	await _a_frame_passes()
	_verdict.check(not _button(LETS_GO).is_usable(), "before any move was stopped, its confirm cannot be pressed: %s" % _button(LETS_GO).get_reason())
	var stopped := {"region": Chimes.GLOBAL, "action": Driver.GO, "payload": {"place": &"there"}, "asks": "Leave the stall?"}
	_made.commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": _overlay, "parameter": stopped})
	await _a_frame_passes()
	_verdict.check(_texts(_made.driver.index.place_named(_overlay)).has("Leave the stall?") and root.gui_get_focus_owner() == _cancel() and _button(LETS_GO).is_usable(), "raised, it says the words it carries, the focus on the cancel: %s" % [_texts(_made.driver.index.place_named(_overlay))])
	_cancel().pressed()
	await _a_frame_passes()
	_verdict.check(not _made.driver.is_raised() and _made.driver.get_top() == [&"app", &"here"], "cancelled, it is lowered and the reader has not moved: %s" % [_made.driver.get_top()])
	_made.commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": _overlay, "parameter": stopped})
	await _a_frame_passes()
	_button(LETS_GO).pressed()
	await _a_frame_passes()
	_verdict.check(not _made.driver.is_raised() and _made.driver.get_top() == [&"app", &"there"] and _made.commands.get_last()["action"] == LETS_GO and _made.commands.get_last()["answer"] == null, "confirmed, it is lowered and the move it carries is made: %s" % [_made.driver.get_top()])
	root.theme.set_type_variation(&"Plainly", Themes.SURFACE)
	var plainly := Confirm.for_leaving(ui, LETS_GO, {style = &"Plainly"})
	ui.build(plainly, root)
	_made.commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": plainly.get_place(), "parameter": stopped})
	await _a_frame_passes()
	var styles: Array = _made.driver.index.place_named(plainly.get_place()).find_children("*", "Control", true, false).map(func(part: Node) -> StringName: return (part as Control).theme_type_variation)
	_verdict.check(styles.has(&"Plainly") and not styles.has(&"Confirm"),"given a style as its option, its sheet wears that style and not the confirm's own: %s" % [styles])
	_done()


## The words wrap at the width the sheet gives them: in a portrait window
## narrower than a long consequence, each question - the one about the one
## thing there is, the one serving every row, the one every leaving asks -
## says it on more lines than one, and no word stands past the window.
func _a_long_consequence_wraps_within_the_sheet_and_no_word_is_past_the_window() -> void:
	var long := "The day's takings will be thrown away. This cannot be undone."
	root.size = Vector2i(360, 720)
	await _a_frame_passes()
	# every kind of question, raised alone in the narrow window
	for kind: String in ["the one question", "the question for rows", "the question for leaving"]:
		_made = Fixture.new(root, {ASKS: "let it go", LETS_GO: "let go"})
		var ui := _made.ui
		_model = Fixture.Model.new(_made.chimes)
		_made.commands.register(_made.chimes.GLOBAL, LETS_GO, _model)
		var asked: Dictionary = {"the one question": Confirm.make(ui, long, LETS_GO), "the question for rows": Confirm.make(ui, func(_which: Bound) -> String: return long, LETS_GO), "the question for leaving": Confirm.for_leaving(ui, LETS_GO)}
		_overlay = (asked[kind] as Desc).get_place()
		ui.build(ui.app(&"app", [ui.text("here")]), root)
		ui.build(asked[kind], root)

		_made.commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": &"app"})
		_made.commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": _overlay, "parameter": {"region": Chimes.GLOBAL, "action": Driver.GO, "payload": {"place": &"app"}, "asks": long}})
		await _a_frame_passes()
		var said: Array = root.find_children("*", "Label", true, false).filter(func(label: Node) -> bool: return (label as Label).text == long)
		var cut := Clipped.clipped(root, root.get_visible_rect())
		_verdict.check(said.size() == 1 and (said[0] as Label).get_line_count() > 1 and cut.is_empty(), "%s says a long consequence on %d lines within the sheet, and no word is past the window: %s" % [kind, (said[0] as Label).get_line_count() if said.size() == 1 else 0, cut])
		_done()
	root.size = Vector2i(400, 400)
	await _a_frame_passes()
