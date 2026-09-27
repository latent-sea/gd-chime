extends SceneTree

## What must be true of a track of keyframes.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_keyframes.gd
##
## Every track reaches every frame of it exactly and rests on its last; a
## track that loops begins again from its first frame each pass; a frame
## that holds holds; several properties move together off the one track;
## reduced, nothing moves and what the motion was saying is still said;
## over budget, a new track is simply its resting frame; hidden or freed, a
## track rests and leaves nothing running; the moment's entrance ends whole
## with nothing drawn over anything else on the way; and a pulse is still a
## pulse.

const Fixture := preload("res://tests/fixture.gd")
const Ui := preload("res://addons/gd_chime/components/primitives/ui.gd")
const Keyframes := preload("res://addons/gd_chime/components/primitives/keyframes.gd")
const Pulse := preload("res://addons/gd_chime/components/primitives/pulse.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Motion := preload("res://addons/gd_chime/motion.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const FrameBudget := preload("res://addons/gd_chime/frame_budget.gd")
const Countdown := preload("res://addons/gd_chime/components/recipes/countdown.gd")
const Moment := preload("res://addons/gd_chime/components/recipes/moment.gd")
const Attention := preload("res://addons/gd_chime/components/recipes/attention.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Verdict := preload("res://tests/verdict.gd")

## A track of three frames over the look's slow duration: whole, gone, whole.
const BLINKS := [
	{&"at": 0.0, Keyframes.OPACITY: 1.0},
	{&"at": 0.5, Keyframes.OPACITY: 0.0},
	{&"at": 1.0, Keyframes.OPACITY: 1.0},
]
## A track of four properties, the middle frame holding a quarter of the way.
const TOGETHER := [
	{&"at": 0.0, Keyframes.OPACITY: 1.0, Keyframes.SCALE: 1.0, Keyframes.SLIDE: Vector2.ZERO, Keyframes.TURN: 0.0},
	{&"at": 0.5, Keyframes.OPACITY: 0.5, Keyframes.SCALE: 2.0, Keyframes.SLIDE: Vector2(1.0, 0.0), Keyframes.TURN: 90.0, &"hold": 0.25},
	{&"at": 1.0, Keyframes.OPACITY: 1.0, Keyframes.SCALE: 1.0, Keyframes.SLIDE: Vector2.ZERO, Keyframes.TURN: 0.0},
]

var _verdict := Verdict.new()
var _made: Fixture
var _ui: Ui
var _model: Fixture.Model


class Spent extends FrameBudget:
	func is_over() -> bool:
		return true


## What a moment is presented while: told to present, it holds; told to dismiss, it does not.
class Act extends Fixture.Model:
	func told(action: StringName, payload: Dictionary) -> Phrase:
		set_value(&"flag", action == &"presents")
		return super(action, payload)



func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(400, 400)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_every_track_reaches_each_frame_exactly_and_a_looping_one_begins_again_from_its_first)
	await _verdict.states(_a_repeating_track_keeps_time_with_the_clock_however_unevenly_it_is_stepped)
	await _verdict.states(_several_properties_move_together_from_the_one_track_and_a_frame_that_holds_holds)
	await _verdict.states(_reduced_nothing_moves_and_the_meaning_is_still_carried_and_over_budget_a_new_track_snaps)
	await _verdict.states(_hidden_or_freed_it_rests_on_its_resting_frame_and_leaves_nothing_running)
	await _verdict.states(_a_countdown_beats_through_its_last_seconds_and_stops_when_the_time_runs_out)
	await _verdict.states(_how_deep_how_long_and_how_many_seconds_a_beat_is_are_the_look_s_to_say)
	await _verdict.states(_the_moments_entrance_staggers_in_ends_whole_and_draws_nothing_over_anything_else)
	await _verdict.states(_a_pulse_fades_while_its_value_holds_and_is_whole_while_it_does_not)
	await _verdict.states(_a_running_pulse_follows_reduced_motion_turned_on_and_off_live)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


func _step(seconds: float) -> void:
	_ui.motion.step(seconds)
	await _a_frame_passes()


## A standing that knows the word keyframes, whose clock moves by hand.
func _standing(declared: Dictionary = {}) -> void:
	_made = Fixture.new(root, declared)
	_ui = _made.ui
	_ui.motion.by_hand = true
	_ui.motion.still = false
	_model = Fixture.Model.new(_made.chimes, &"app")


func _done() -> void:
	_model.free()
	_made.done()


## A control of this size under the root, to build a track into.
func _host(of: Vector2 = Vector2(200.0, 100.0)) -> Control:
	var host := Control.new()
	host.size = of
	root.add_child(host)
	return host


func _every_track_reaches_each_frame_exactly_and_a_looping_one_begins_again_from_its_first() -> void:
	_standing()
	var track: Control = _ui.build(_ui.keyframes([_ui.text("here")], BLINKS, &"slow", {easing = Motion.MOVE, timed_by = Motion.TYPE, loops = 2}), _host())
	await _a_frame_passes()
	_verdict.check(track.modulate.a == 1.0, "a track begins on its first frame: %s" % track.modulate.a)
	await _step(0.09)
	_verdict.check(track.modulate.a > 0.0 and track.modulate.a < 1.0, "half way to the second frame it is half way there: %s" % track.modulate.a)
	await _step(0.09)
	_verdict.check(track.modulate.a == 0.0, "the look's slow duration half gone, it is exactly on the second frame: %s" % track.modulate.a)
	await _step(0.18)
	_verdict.check(track.modulate.a == 1.0 and _ui.motion.get_running() == 1, "one pass over, it is exactly on its last frame and the next pass is already on its way")
	await _step(0.18)
	_verdict.check(track.modulate.a == 0.0, "and the second pass went through the first frame again to the second: %s" % track.modulate.a)
	await _step(0.18)
	_verdict.check(track.modulate.a == 1.0 and _ui.motion.get_running() == 0, "its passes run out, it rests on its resting frame with nothing left running")
	track.get_parent().free()
	_done()


## Stepped in uneven steps, as frames come, a track that repeats keeps time
## with the clock: what a step carries past the end of one frame of it is
## carried into the next, and into the next pass, so after ten passes it is
## exactly ten passes on - where it was a quarter into the first.
func _a_repeating_track_keeps_time_with_the_clock_however_unevenly_it_is_stepped() -> void:
	_standing()
	var track: Control = _ui.build(_ui.keyframes([_ui.text("here")], BLINKS, &"slow", {easing = Motion.MOVE, timed_by = Motion.TYPE, loops = Keyframes.FOREVER}), _host())
	await _a_frame_passes()
	await _step(0.05)
	await _step(0.04)
	var quarter: float = track.modulate.a
	# ten passes of the look's slow duration, in steps that fall across its frames
	for period: int in 10:
		for seconds: float in [0.07, 0.11, 0.05, 0.13]:
			await _step(seconds)
	_verdict.check(absf(track.modulate.a - quarter) < 0.001,"ten passes on in uneven steps, a repeating track is exactly where it was a quarter into its first: %s against %s" % [track.modulate.a, quarter])
	track.get_parent().free()
	_done()


func _several_properties_move_together_from_the_one_track_and_a_frame_that_holds_holds() -> void:
	_standing()
	var track: Control = _ui.build(_ui.keyframes([_ui.text("here")], TOGETHER, &"slow", {easing = Motion.MOVE}), _host())
	await _a_frame_passes()
	var across: float = track.position.x
	await _step(0.18)
	var middle := [track.modulate.a, track.scale, track.position.x - across, track.rotation_degrees]
	_verdict.check(middle[0] == 0.5 and middle[1] == Vector2(2.0, 2.0) and is_equal_approx(middle[2], track.size.x) and middle[3] == 90.0, "four properties off the one track are all exactly on the middle frame at once: %s" % [middle])
	await _step(0.09)
	_verdict.check(track.modulate.a == 0.5 and track.scale == Vector2(2.0, 2.0) and track.rotation_degrees == 90.0, "a quarter of the track later the frame is still holding: nothing has moved on: %s" % track.modulate.a)
	await _step(0.09)
	_verdict.check(track.modulate.a == 1.0 and track.scale == Vector2.ONE and track.rotation_degrees == 0.0 and is_equal_approx(track.position.x, across), "the hold over, the rest of the track ran in what was left of it and every property is home: %s" % track.position)
	_verdict.check(_ui.motion.get_running() == 0, "with nothing left running")
	var breathing: Control = _ui.build(Attention.breathing(_ui, [_ui.text("waiting")]), _host())
	await _a_frame_passes()
	await _step(0.6)
	_verdict.check(breathing.modulate.a < 1.0 and breathing.scale.x > 1.0, "the idle breathe is that same shape: it fades and grows together off the one track: %s %s" % [breathing.modulate.a, breathing.scale])
	track.get_parent().free()
	breathing.get_parent().free()
	_done()


func _reduced_nothing_moves_and_the_meaning_is_still_carried_and_over_budget_a_new_track_snaps() -> void:
	_standing({&"saves": "save the day"})
	_ui.motion.told(Motion.REDUCES, {"on": true})
	var looping: Control = _ui.build(_ui.keyframes([_ui.text("here")], TOGETHER, &"slow", {easing = Motion.MOVE, timed_by = Motion.TYPE, loops = Keyframes.FOREVER}), _host())
	await _a_frame_passes()
	await _step(0.09)
	_verdict.check(looping.modulate.a == 1.0 and looping.scale == Vector2.ONE and looping.rotation_degrees == 0.0 and _ui.motion.get_running() == 0, "reduced, a track that loops is simply its resting state: %s" % looping.modulate.a)
	var once: Control = _ui.build(_ui.keyframes([_ui.text("here")], Moment.SETTLES, &"slow", {easing = Motion.EMPHASIS}), _host())
	await _a_frame_passes()
	_verdict.check(once.scale == Vector2.ONE and once.modulate.a == 0.0 and _ui.motion.get_running() == 1, "and a track that runs once does not scale at all: what is left of it is the fade: %s" % once.scale)
	await _step(0.09)
	_verdict.check(once.modulate.a == 1.0, "a short one")
	# gone before reduced motion is turned off, since a loop still shown would run again then
	looping.get_parent().free()
	_ui.motion.told(Motion.REDUCES, {"on": false})
	var budget := Spent.new(_made.chimes, 16.0, 0.5, 3)
	_ui.motion.budget = budget
	var over: Control = _ui.build(_ui.keyframes([_ui.text("here")], TOGETHER, &"slow", {easing = Motion.MOVE, timed_by = Motion.TYPE, loops = Keyframes.FOREVER}), _host())
	await _a_frame_passes()
	await _step(0.09)
	_verdict.check(over.modulate.a == 1.0 and over.scale == Vector2.ONE and _ui.motion.get_running() == 0, "over budget a new track is its resting frame and nothing else - not a pass it runs through as fast as it is stepped: %s" % over.modulate.a)
	_ui.motion.budget = null
	budget.free()
	for made: Control in [once, over]:
		made.get_parent().free()
	_done()


func _hidden_or_freed_it_rests_on_its_resting_frame_and_leaves_nothing_running() -> void:
	_standing()
	var host := _host()
	var track: Control = _ui.build(_ui.keyframes([_ui.text("here")], BLINKS, &"slow", {easing = Motion.MOVE, timed_by = Motion.TYPE, loops = Keyframes.FOREVER}), host)
	await _a_frame_passes()
	await _step(0.09)
	_verdict.check(track.modulate.a < 1.0 and _ui.motion.get_running() == 1, "a track that loops is on its way: %s" % track.modulate.a)
	track.visible = false
	await _step(0.0)
	_verdict.check(track.modulate.a == 1.0 and _ui.motion.get_running() == 0, "hidden, it rests exactly on its resting frame with nothing of it left running: %s" % track.modulate.a)
	track.visible = true
	await _a_frame_passes()
	await _step(0.09)
	_verdict.check(track.modulate.a < 1.0 and _ui.motion.get_running() == 1, "shown again, the track is running again")
	host.free()
	await _step(0.0)
	_verdict.check(_ui.motion.get_running() == 0, "and freed, nothing of it is left running at all")
	_done()


func _a_countdown_beats_through_its_last_seconds_and_stops_when_the_time_runs_out() -> void:
	_standing()
	_model.set_value(&"flag", 125.0)
	var beat: Control = _ui.build(Countdown.make(_ui, _model.of(&"flag"), "now"), _host())
	await _a_frame_passes()
	await _step(0.3)
	_verdict.check(beat.modulate.a == 1.0 and _ui.motion.get_running() == 0, "two minutes out, the countdown does not beat: %s" % beat.modulate.a)
	_model.set_value(&"flag", 6.0)
	await _a_frame_passes()
	await _step(0.36)
	_verdict.check(beat.modulate.a < 1.0 and _ui.motion.get_running() > 0, "in the last seconds it beats: %s" % beat.modulate.a)
	_model.set_value(&"flag", 0.0)
	await _a_frame_passes()
	await _step(0.0)
	_verdict.check(beat.modulate.a == 1.0 and beat.scale == Vector2.ONE and _ui.motion.get_running() == 0, "the time run out, the beat stops on its resting frame: %s" % beat.modulate.a)
	var words: Array = _texts(beat)
	_verdict.check(words == ["now"], "and the words say so on their own, beat or no beat: %s" % [words])
	beat.get_parent().free()
	_done()


## Every pair of things drawn in this holder that overlap, by their words.
func _overlapping(holder: Control) -> Array:
	var seen: Array = holder.get_children(true).filter(func(child: Node) -> bool: return child is Control and (child as Control).modulate.a > 0.01)
	var pairs: Array = []
	# every pair of what can be seen, looking for two rects that meet
	for a: int in seen.size():
		for b: int in range(a + 1, seen.size()):
			var one := Rect2(seen[a].position, seen[a].size * seen[a].scale)
			var other := Rect2(seen[b].position, seen[b].size * seen[b].scale)
			if one.intersects(other):
				pairs.append([_texts(seen[a]), _texts(seen[b])])
	return pairs


func _texts(node: Node) -> Array:
	var found: Array = []
	for child: Node in node.get_children():
		if child is Text:
			found.append((child as Text).get_text())
		found.append_array(_texts(child))
	return found


## None of a track's numbers lives in a recipe: a frame names a token, and
## the look answers - the floor's placeholders until a look says its own.
func _how_deep_how_long_and_how_many_seconds_a_beat_is_are_the_look_s_to_say() -> void:
	_standing()
	_model.set_value(&"flag", 6.0)
	var beat: Control = _ui.build(Countdown.make(_ui, _model.of(&"flag"), "now"), _host())
	await _a_frame_passes()
	# a tenth of a second at a time, as frames come: one long step would land on the frame whatever the beat's length
	for tick: int in 4:
		await _step(0.1)
	_verdict.check(is_equal_approx(beat.modulate.a, 0.5) and beat.scale.is_equal_approx(Vector2.ONE * 1.08), "on the floor's own look a beat is a second long and dips to a half, swelling a little: held there at four tenths of it: %s %s" % [beat.modulate.a, beat.scale])
	beat.get_parent().free()
	var own := Theme.new()
	own.set_constant(Motion.BEAT, Motion.TYPE, 2000)
	own.set_constant(&"beat_opacity", Motion.TYPE, 800)
	own.set_constant(Motion.BEAT_FOR, Motion.TYPE, 3)
	var under := _host()
	under.theme = own
	beat = _ui.build(Countdown.make(_ui, _model.of(&"flag"), "now"), under)
	await _a_frame_passes()
	for tick: int in 8:
		await _step(0.1)
	_verdict.check(is_equal_approx(beat.modulate.a, 0.8), "under a look that says a beat is two seconds and dips to four fifths, it is there at four tenths of THAT: %s" % beat.modulate.a)
	under.free()
	root.theme.set_constant(Motion.BEAT_FOR, Motion.TYPE, 3)
	await _a_frame_passes()
	beat = _ui.build(Countdown.make(_ui, _model.of(&"flag"), "now"), _host())
	await _a_frame_passes()
	await _step(0.4)
	_verdict.check(beat.modulate.a == 1.0 and _ui.motion.get_running() == 0, "and with the look saying only the last three seconds beat, six seconds out it does not: %s" % beat.modulate.a)
	root.theme.set_constant(Motion.BEAT_FOR, Motion.TYPE, 10)
	beat.get_parent().free()
	_done()


func _the_moments_entrance_staggers_in_ends_whole_and_draws_nothing_over_anything_else() -> void:
	_standing({&"dismisses": "close", &"presents": "present"})
	var act := Act.new(_made.chimes)
	# the fact the moment is up while: set by the command that presents it and by the one that dismisses it
	for action: StringName in [&"presents", &"dismisses"]:
		_made.commands.register(Chimes.GLOBAL, action, act)
	_ui.start(_ui.app(&"app", [_ui.stack([_ui.column([_ui.text("the work"), _ui.pressable(&"presents", {}, [_ui.text("present")])]), Moment.make(_ui, act.of(&"flag", false), [_ui.text("the season ended"), _ui.text("three crates picked")], &"dismisses").named(&"moment")])]))
	await _a_frame_passes()
	_made.commands.dispatch(Chimes.GLOBAL, &"presents", {})
	await _a_frame_passes()
	var shade: Control = _ui.node_named(&"moment").get_child(0)
	var lines: Control = shade.find_children("*", "Container", true, false).filter(func(part: Node) -> bool: return part.get_children().size() == 3)[0]
	_verdict.check(shade.modulate.a == 0.0 and lines.get_children().all(func(line: Node) -> bool: return (line as Control).modulate.a == 0.0), "presented, the whole moment begins unseen: the shade, what stands on it, and every line of it")
	var crossed: Array = []
	# a hundredth of a second at a time through the whole entrance, watching the lines
	for tick: int in 60:
		await _step(0.01)
		crossed.append_array(_overlapping(lines))
	var opacities: Array = lines.get_children().map(func(line: Node) -> float: return (line as Control).modulate.a)
	_verdict.check(shade.modulate.a == 1.0 and opacities.all(func(seen: float) -> bool: return seen == 1.0) and _ui.motion.get_running() == 0, "the entrance over, every part of it is whole and nothing is left running: %s" % [opacities])
	_verdict.check(crossed.is_empty(), "and at no step on the way was any line drawn over another: %s" % [crossed.slice(0, 3)])
	var early: Array = []
	_made.commands.dispatch(Chimes.GLOBAL, &"dismisses", {})
	# the moment seen out before it is presented again - lowered at the end of the frame its fact stopped in, and still there while it goes
	await _a_frame_passes()
	await _step(1.0)
	await _a_frame_passes()
	_made.commands.dispatch(Chimes.GLOBAL, &"presents", {})
	await _a_frame_passes()
	var again: Control = _ui.node_named(&"moment").get_child(0)
	var rows: Control = again.find_children("*", "Container", true, false).filter(func(part: Node) -> bool: return part.get_children().size() == 3)[0]
	await _step(0.05)
	early = rows.get_children().map(func(line: Node) -> float: return (line as Control).modulate.a)
	_verdict.check(early[0] > early[1] and early[1] >= early[2], "shown again, its lines arrive one after another rather than together: %s" % [early])
	await _step(1.0)
	act.free()
	_done()


func _a_pulse_fades_while_its_value_holds_and_is_whole_while_it_does_not() -> void:
	_standing()
	_model.set_value(&"flag", true)
	var pulse: Pulse = _ui.build(_ui.pulse([_ui.text("look here")], _model.of(&"flag")), _host())
	await _a_frame_passes()
	await _step(0.6)
	_verdict.check(pulse.is_pulsing() and pulse.modulate.a < 0.99 and pulse.modulate.a > 0.0, "while the value holds it pulses, fading part of the way: %s" % pulse.modulate.a)
	await _step(0.6)
	_verdict.check(pulse.modulate.a == 1.0 and _ui.motion.get_running() == 1, "a period of the look's on, it is whole again and pulsing still")
	_model.set_value(&"flag", false)
	await _a_frame_passes()
	await _step(0.0)
	_verdict.check(not pulse.is_pulsing() and pulse.modulate.a == 1.0 and _ui.motion.get_running() == 0, "the value gone, it is whole and still: %s" % pulse.modulate.a)
	pulse.get_parent().free()
	_done()


## Reduced motion turned on while a pulse runs, the pulse rests whole there
## and then - not the look's quick cross-fade looping faster - and turned
## off, it pulses again, neither waiting to be shown anew.
func _a_running_pulse_follows_reduced_motion_turned_on_and_off_live() -> void:
	_standing()
	_model.set_value(&"flag", true)
	var pulse: Pulse = _ui.build(_ui.pulse([_ui.text("look here")], _model.of(&"flag")), _host())
	await _a_frame_passes()
	await _step(0.3)
	_verdict.check(pulse.modulate.a < 1.0 and _ui.motion.get_running() == 1, "a pulse is on its way: %s" % pulse.modulate.a)
	_ui.motion.told(Motion.REDUCES, {"on": true})
	var seen: Array = []
	# a second and a half, a tenth at a time, watching for any fading at all
	for tick: int in 15:
		await _step(0.1)
		seen.append(pulse.modulate.a)
	_verdict.check(seen.all(func(a: float) -> bool: return a == 1.0) and _ui.motion.get_running() == 0, "reduced motion turned on, the running pulse rests whole at once and stays so: %s" % [seen])
	_ui.motion.told(Motion.REDUCES, {"on": false})
	# the setting rings at the frame's end, and the pulse starts again there
	await _a_frame_passes()
	await _step(0.3)
	_verdict.check(pulse.modulate.a < 1.0 and _ui.motion.get_running() == 1, "turned off, it pulses again without being shown anew: %s" % pulse.modulate.a)
	pulse.get_parent().free()
	_done()
