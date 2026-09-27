extends SceneTree

## What must be true of an eased value.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_eased.gd
##
## Its source moved, it goes there over the look's duration and its reader
## - the same node - shows the values on the way and then the end; moved
## again mid-flight it goes on from where it is, never jumping; what cannot
## be gone between is there at once; reduced, so is everything; and its
## readers gone, nothing is left running.

const Fixture := preload("res://tests/fixture.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Motion := preload("res://addons/gd_chime/motion.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Verdict := preload("res://tests/verdict.gd")

var _verdict := Verdict.new()
var _made: Fixture
var _model: Fixture.Model
var _says: Text


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	await _verdict.states(_it_goes_to_where_its_source_moved_and_its_reader_shows_the_way_and_the_end)
	await _verdict.states(_moved_again_mid_flight_it_goes_on_from_where_it_is)
	await _verdict.states(_what_cannot_be_gone_between_is_there_at_once_and_reduced_so_is_everything)
	await _verdict.states(_its_readers_gone_nothing_is_left_running)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## A number in a model, shown eased by the move easing - 180ms - on a clock stepped by hand.
func _standing(first: Variant) -> void:
	_made = Fixture.new(root)
	_made.ui.motion.by_hand = true
	_made.ui.motion.still = false
	_model = Fixture.Model.new(_made.chimes, &"app")
	_model.set_value(&"items", first)
	var ui := _made.ui
	ui.start(ui.app(&"app", [ui.text(ui.eased(_model.of(&"items")).map(func(now: Variant) -> String: return str(now))).named(&"says")]))
	await _a_frame_passes()
	_says = ui.node_named(&"says")


## The clock moved on, and the frame in which its readers draw again.
func _step(seconds: float) -> void:
	_made.ui.motion.step(seconds)
	await _a_frame_passes()


func _done() -> void:
	_model.free()
	_made.done()


func _it_goes_to_where_its_source_moved_and_its_reader_shows_the_way_and_the_end() -> void:
	await _standing(0.0)
	_verdict.check(_says.get_text() == "0.0" and _made.ui.motion.get_running() == 0, "it begins where its source is, nothing running: %s" % _says.get_text())
	_model.set_value(&"items", 100.0)
	await _a_frame_passes()
	_verdict.check(_says.get_text() == "0.0" and _made.ui.motion.get_running() == 1, "its source moved, it has not jumped there: it is on its way: %s" % _says.get_text())
	await _step(0.09)
	_verdict.check(is_equal_approx(float(_says.get_text()), 50.0) and _made.ui.node_named(&"says") == _says, "halfway through the look's time, the same reader shows the halfway value: %s" % _says.get_text())
	await _step(0.09)
	_verdict.check(_says.get_text() == "100.0" and _made.ui.motion.get_running() == 0, "and then the end, exactly, nothing left running: %s" % _says.get_text())
	_done()


func _moved_again_mid_flight_it_goes_on_from_where_it_is() -> void:
	await _standing(0.0)
	_model.set_value(&"items", 100.0)
	await _a_frame_passes()
	await _step(0.09)
	var reached := float(_says.get_text())
	_model.set_value(&"items", 0.0)
	await _a_frame_passes()
	await _step(0.001)
	_verdict.check(absf(float(_says.get_text()) - reached) < 1.0 and _made.ui.motion.get_running() == 1, "sent back mid-flight, it is still beside the value it had reached, one run: %s then %s" % [reached, _says.get_text()])
	await _step(0.18)
	_verdict.check(_says.get_text() == "0.0", "and arrives where it was sent: %s" % _says.get_text())
	_done()


func _what_cannot_be_gone_between_is_there_at_once_and_reduced_so_is_everything() -> void:
	await _standing("few")
	_model.set_value(&"items", "many")
	await _a_frame_passes()
	_verdict.check(_says.get_text() == "many" and _made.ui.motion.get_running() == 0, "words are there at once: %s" % _says.get_text())
	_model.set_value(&"items", 10.0)
	await _a_frame_passes()
	_verdict.check(_says.get_text() == "10.0", "and so is a value of another type than the last: %s" % _says.get_text())
	_made.ui.motion.told(Motion.REDUCES, {"on": true})
	_model.set_value(&"items", 90.0)
	await _a_frame_passes()
	_verdict.check(_says.get_text() == "90.0" and _made.ui.motion.get_running() == 0, "reduced, a number is there at once too: %s" % _says.get_text())
	_done()


func _its_readers_gone_nothing_is_left_running() -> void:
	await _standing(0.0)
	_model.set_value(&"items", 100.0)
	await _a_frame_passes()
	_says.free()
	_made.ui.motion.step(0.01)
	_verdict.check(_made.ui.motion.get_running() == 0, "its one reader freed mid-flight, the eased value went with it and its run was dropped: %d" % _made.ui.motion.get_running())
	_done()
