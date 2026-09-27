extends SceneTree

## What must be true of when: one of two descriptions by a bound value.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_when.gd
##
## The first description is built while the value holds and the second
## while it does not, swapped as the value changes, the one not showing
## freed - nothing is kept for it; a second description of nothing shows
## nothing, and takes no gap in its line; and the focus is handed on before
## the piece holding it is freed. And what a hidden control's draw does: it
## waits until shown, unless its own draw shows it - and a control that hides
## itself as it draws without saying so is reported out loud.

const Fixture := preload("res://tests/fixture.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const When := preload("res://addons/gd_chime/components/primitives/when.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Verdict := preload("res://tests/verdict.gd")
const Going := preload("res://addons/gd_chime/components/primitives/going.gd")
const Presentation := preload("res://addons/gd_chime/presentation.gd")

var _verdict := Verdict.new()


func _init() -> void:
	await process_frame
	await _verdict.states(_it_swaps_the_descriptions_as_the_value_changes_freeing_the_other)
	await _verdict.states(_a_second_of_nothing_shows_nothing_and_the_focus_is_handed_on)
	await _verdict.states(_a_holder_that_is_no_line_gives_what_it_holds_its_whole_width)
	await _verdict.states(_holding_nothing_it_takes_no_gap_in_its_line)
	await _verdict.states(_hidden_a_draw_due_waits_and_shown_it_draws_once_measured_before_it_is_placed)
	await _verdict.states(_what_shows_itself_draws_though_it_is_hidden)
	await _verdict.states(_what_hides_itself_unsaid_is_reported_out_loud)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


func _it_swaps_the_descriptions_as_the_value_changes_freeing_the_other() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes)
	model.set_value(&"flag", true)
	var when: When = ui.build(ui.when(model.of(&"flag"), ui.text("yes"), ui.text("no")), root)
	await _a_frame_passes()
	_verdict.check(when.is_showing_first() and when.get_child_count() == 1 and (when.get_child(0) as Text).get_text() == "yes", "the value holding, the first is built and alone")
	model.set_value(&"flag", false)
	await _a_frame_passes()
	_verdict.check(not when.is_showing_first() and when.get_child_count() == 1 and (when.get_child(0) as Text).get_text() == "no", "the value gone, the second is built and the first freed: %d" % when.get_child_count())
	model.set_value(&"flag", false)
	await _a_frame_passes()
	_verdict.check(when.get_child_count() == 1, "the bell rung with the value the same, nothing is rebuilt")
	model.set_value(&"flag", "words")
	await _a_frame_passes()
	_verdict.check(when.is_showing_first(), "any value that is something holds: %s" % when.is_showing_first())
	when.free()
	model.free()
	made.done()


func _a_second_of_nothing_shows_nothing_and_the_focus_is_handed_on() -> void:
	var made := Fixture.new(root, {&"goes": "go", &"stays": "stay"})
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes)
	model.set_value(&"flag", true)
	# a place holding the when, with a pressable inside it that takes the focus, and one outside
	var app := ui.app(&"app", [ui.column([ui.when(model.of(&"flag"), ui.pressable(&"goes")).named(&"the_when"), ui.pressable(&"stays").named(&"other")])])
	made.answer([&"goes", &"stays"])
	ui.start(app)
	await _a_frame_passes()
	var when: When = ui.node_named(&"the_when")
	var inside: Control = when.get_child(0)
	inside.grab_focus()
	_verdict.check(root.gui_get_focus_owner() == inside, "the pressable inside holds the focus")
	model.set_value(&"flag", false)
	await _a_frame_passes()
	_verdict.check(when.get_child_count() == 0, "the value gone with nothing for the other side, it shows nothing: %d" % when.get_child_count())
	_verdict.check(root.gui_get_focus_owner() == ui.node_named(&"other"), "and the focus went on to the next control that takes it, not to nothing: %s" % root.gui_get_focus_owner())
	model.free()
	made.done()


## Words that wrap, held straight inside a when and inside a stack in a
## room 300 wide: each is given the holder's whole width, so it wraps at
## 300 - a few lines - and is never left at its own least width, one letter
## to a line.
func _a_holder_that_is_no_line_gives_what_it_holds_its_whole_width() -> void:
	root.size = Vector2i(300, 600)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	# the floor's own look, whose column stretches what it holds across it
	root.theme = Themes.new(Themes.NEUTRAL)
	var made := Fixture.new(root)
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes, &"app")
	model.set_value(&"flag", true)
	var words := "a sentence long enough that it must break onto more than one line at this width"
	ui.start(ui.app(&"app", [ui.column([
		ui.when(model.of(&"flag"), ui.text(words, &"").wraps().named(&"in_when")).grow(),
		ui.stack([ui.text(words, &"").wraps().named(&"in_stack")]).grow(),
	])]))
	await _a_frame_passes()
	await _a_frame_passes()
	# each holder's words, for their width and how many lines they came to
	for named: StringName in [&"in_when", &"in_stack"]:
		var held: Control = ui.node_named(named)
		var label: Label = held.get_child(0)
		_verdict.check(is_equal_approx(held.size.x, 300.0) and label.get_line_count() > 1 and label.get_line_count() < 8, "%s: the words are given the holder's whole width and wrap at it, in a few lines - not one letter to a line: %s wide, %d lines" % [named, held.size.x, label.get_line_count()])
	model.free()
	made.done()
	root.theme = null


## A when holding nothing, first in a row with a gap: the part after it
## stands at the row's start, as if the when were not there - a hidden part
## takes no gap. Shown, it takes its width and the gap; its side going, that
## side is still seen while its exit runs; gone - run out and freed, and a
## kept side hidden - the part after is back at the start.
func _holding_nothing_it_takes_no_gap_in_its_line() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	var made := Fixture.new(root)
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes, &"app")
	model.set_value(&"flag", false)
	model.set_value(&"words", false)
	var freed := ui.when(model.of(&"flag"), ui.text("an offer").named(&"offer")).transition(&"fade")
	var kept := ui.when(model.of(&"words"), ui.text("kept").named(&"kept"), null).keeps()
	ui.start(ui.app(&"app", [ui.column([ui.row([freed, ui.text("after").named(&"after")]), ui.row([kept, ui.text("second").named(&"second")])])]))
	await _a_frame_passes()
	var after: Control = ui.node_named(&"after")
	var second: Control = ui.node_named(&"second")
	var gap := float(root.theme.get_constant(&"gap", Themes.ROW))
	_verdict.check(gap > 0.0 and after.position.x == 0.0 and second.position.x == 0.0, "holding nothing, a when takes no gap: what follows stands at the row's start, the gap %s: %s and %s" % [gap, after.position.x, second.position.x])
	model.set_value(&"flag", true)
	model.set_value(&"words", true)
	await _a_frame_passes()
	var offer: Control = ui.node_named(&"offer")
	_verdict.check(is_equal_approx(after.position.x, offer.size.x + gap) and is_equal_approx(second.position.x, ui.node_named(&"kept").size.x + gap), "showing, it takes its width and the gap: %s after %s, %s after %s" % [after.position.x, offer.size.x, second.position.x, ui.node_named(&"kept").size.x])
	ui.motion.still = false
	ui.motion.by_hand = true
	model.set_value(&"flag", false)
	model.set_value(&"words", false)
	await _a_frame_passes()
	_verdict.check(Going.is_going(offer) and offer.is_visible_in_tree(), "its side on its way out is still seen while its exit runs: going %s, seen %s" % [Going.is_going(offer), offer.is_visible_in_tree()])
	ui.motion.step(10.0)
	await _a_frame_passes()
	_verdict.check(after.position.x == 0.0 and second.position.x == 0.0, "its side gone, freed or kept hidden, what follows is back at the row's start: %s and %s" % [after.position.x, second.position.x])
	model.free()
	made.done()
	root.theme = null


## A control that cannot be seen - hidden by what holds it, as a when's kept
## side is, or under something hidden - draws for nobody: what it read moving
## is a draw DUE, which waits, however many times it moves. Shown, it draws
## once, with the words as they now are, and inside the showing itself: the
## room those words need is asked again before anything is laid out around
## them, so what follows stands past their whole width (presentation.gd).
func _hidden_a_draw_due_waits_and_shown_it_draws_once_measured_before_it_is_placed() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	var made := Fixture.new(root)
	var ui := made.ui
	# the flag and the words on two models, so showing a side rings nothing the words read
	var model := Fixture.Model.new(made.chimes, &"app")
	var said := Fixture.Model.new(made.chimes)
	model.set_value(&"flag", false)
	said.set_value(&"words", "before")
	var side := ui.when(model.of(&"flag"), ui.text(said.of(&"words")).named(&"side"), null).keeps()
	var under := ui.when(model.of(&"flag"), ui.column([ui.text(said.of(&"words")).named(&"under")]), null).keeps()
	var by_hand := ui.column([ui.text(said.of(&"words")).named(&"held")]).named(&"by_hand")
	ui.start(ui.app(&"app", [ui.column([ui.row([side, ui.text("after").named(&"after")]), under, by_hand])]))
	(ui.node_named(&"by_hand") as Control).visible = false
	await _a_frame_passes()
	var names: Array[StringName] = [&"side", &"under", &"held"]
	var drawn := {}
	# each hidden text, for the draws it has made and the words it was built with
	for named: StringName in names:
		var words: Text = ui.node_named(named)
		drawn[named] = words.refresh_count
		_verdict.check(not words.is_visible_in_tree() and words.get_text() == "before", "%s is built hidden, drawn with its words: %s, %s" % [named, words.is_visible_in_tree(), words.get_text()])
	_verdict.check(drawn[&"side"] == 1 and (ui.node_named(&"after") as Text).refresh_count == 1, "built, each has drawn once, seen or not: %d and %d" % [drawn[&"side"], (ui.node_named(&"after") as Text).refresh_count])
	var narrow: float = (ui.node_named(&"side") as Text).get_combined_minimum_size().x
	# the words moving three times, a frame each
	for now: String in ["once", "twice", "words a good deal longer than before"]:
		said.set_value(&"words", now)
		await _a_frame_passes()
	# each hidden text, which drew for none of it
	for named: StringName in names:
		var words: Text = ui.node_named(named)
		_verdict.check(words.refresh_count == drawn[named] and words.get_text() == "before", "%s, its words moved three times while it is hidden, is not drawn: %d draws, %s" % [named, words.refresh_count - drawn[named], words.get_text()])
	var held: Text = ui.node_named(&"held")
	(ui.node_named(&"by_hand") as Control).visible = true
	_verdict.check(held.refresh_count == drawn[&"held"] + 1 and held.get_text() == "words a good deal longer than before" and held.get_combined_minimum_size().x > narrow, "its holder shown, it has drawn once with the words as they now are and needs their room, before a frame passes: %d draws, %s, %s against %s" % [held.refresh_count - drawn[&"held"], held.get_text(), held.get_combined_minimum_size().x, narrow])
	model.set_value(&"flag", true)
	await _a_frame_passes()
	# each side the when shows, drawn once with the words as they now are
	for named: StringName in [&"side", &"under"]:
		var words: Text = ui.node_named(named)
		_verdict.check(words.is_visible_in_tree() and words.refresh_count == drawn[named] + 1 and words.get_text() == "words a good deal longer than before", "%s shown by its when, it is drawn once, with the words as they now are: %d draws, %s" % [named, words.refresh_count - drawn[named], words.get_text()])
	var shown: Text = ui.node_named(&"side")
	var after: Control = ui.node_named(&"after")
	var gap := float(root.theme.get_constant(&"gap", Themes.ROW))
	_verdict.check(shown.size.x > narrow and is_equal_approx(after.position.x, shown.get_combined_minimum_size().x + gap), "and what follows it stands past the whole of the words it now has: %s after %s, which was %s" % [after.position.x, shown.get_combined_minimum_size().x, narrow])
	await _a_frame_passes()
	_verdict.check(held.refresh_count == drawn[&"held"] + 1 and shown.refresh_count == drawn[&"side"] + 1, "and no draw follows on the frames after: %d and %d" % [held.refresh_count - drawn[&"held"], shown.refresh_count - drawn[&"side"]])
	model.free()
	said.free()
	made.done()
	root.theme = null


## Words hidden while empty are hidden by their own draw, so only their own
## draw shows them: what they read moving, they draw though hidden - under
## something hidden too, since the engine tells a control hidden by itself
## nothing when what holds it is shown, and it would wait for ever.
func _what_shows_itself_draws_though_it_is_hidden() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var said := Fixture.Model.new(made.chimes)
	said.set_value(&"words", "")
	ui.start(ui.app(&"app", [ui.column([ui.text(said.of(&"words")).hides_empty().named(&"alone"), ui.column([ui.text(said.of(&"words")).hides_empty().named(&"under")]).named(&"holder")])]))
	(ui.node_named(&"holder") as Control).visible = false
	await _a_frame_passes()
	var alone: Text = ui.node_named(&"alone")
	var under: Text = ui.node_named(&"under")
	_verdict.check(not alone.visible and not under.visible, "empty, the words are hidden: %s, %s" % [alone.visible, under.visible])
	said.set_value(&"words", "a reason")
	await _a_frame_passes()
	_verdict.check(alone.visible and alone.get_text() == "a reason", "words arriving, the one hidden only by itself draws and shows: %s, %s" % [alone.visible, alone.get_text()])
	(ui.node_named(&"holder") as Control).visible = true
	_verdict.check(under.is_visible_in_tree() and under.get_text() == "a reason", "and the one under something hidden drew too, so it is seen with its words as its holder is shown: %s, %s" % [under.is_visible_in_tree(), under.get_text()])
	await _a_frame_passes()
	var drawn: int = alone.refresh_count
	alone.needs_refresh()
	alone.visible = false
	_verdict.check(alone.refresh_count == drawn, "a draw due, being hidden is not being shown: it draws nothing as it hides, since what hid it may be taking it away: %d draws" % (alone.refresh_count - drawn))
	said.free()
	made.done()


## A control that hides itself as it draws, and does not say it shows itself.
class HidesItself extends Presentation:
	var _words: RefCounted  # the value whose emptiness hides it

	func _init(chimes: Chimes, words: RefCounted) -> void:
		super(chimes)
		_words = words

	func refresh() -> void:
		visible = _words.read() != ""


## Everything the engine is told is wrong, in its own words.
class Complaints extends Logger:
	var said: Array[String] = []

	func _log_error(_function: String, _file: String, _line: int, code: String, rationale: String, _editor_notify: bool, _error_type: int, _traces: Array[ScriptBacktrace]) -> void:
		said.append(code if rationale.is_empty() else rationale)


## A control whose own draw hides it, never saying its draw shows it
## (shows_itself), would wait hidden for a showing nothing brings - so it is
## reported out loud as it hides, naming it, once. Words hidden while empty,
## which say so, and a control hidden by what holds it - above it, or its
## own flag set by its holder, then drawn - are not.
func _what_hides_itself_unsaid_is_reported_out_loud() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var said := Fixture.Model.new(made.chimes)
	said.set_value(&"words", "a reason")
	var hides := HidesItself.new(made.chimes, said.of(&"words"))
	hides.name = &"hides_itself"
	ui.start(ui.app(&"app", [ui.column([ui.text(said.of(&"words")).hides_empty(), ui.column([ui.text(said.of(&"words"))]).named(&"holder"), ui.text(said.of(&"words")).named(&"kept_side")])]))
	root.add_child(hides)
	await _a_frame_passes()
	var complaints := Complaints.new()
	OS.add_logger(complaints)
	(ui.node_named(&"holder") as Control).visible = false
	said.set_value(&"words", "")
	await _a_frame_passes()
	said.set_value(&"words", "")
	await _a_frame_passes()
	# hidden by what holds it, as a when's kept side is, and drawn by hand: its draw hid nothing
	var kept_side: Text = ui.node_named(&"kept_side")
	kept_side.visible = false
	kept_side.refresh_now()
	OS.remove_logger(complaints)
	var naming: Array = complaints.said.filter(func(one: String) -> bool: return one.contains("hides_itself"))
	_verdict.check(not hides.visible and naming.size() == 1 and complaints.said.size() == 1, "a control hiding itself as it draws without saying so is reported out loud, once, by name - and nothing else is: %s" % [complaints.said])
	hides.free()
	said.free()
	made.done()
