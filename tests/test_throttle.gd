extends SceneTree

## What must be true of a throttle: asked any number of times in a frame, its
## deed is done once, at the frame's end and not before; asked in two frames,
## twice; paced, no oftener than the look's cadence, the last ask never lost;
## settled, only once the asking has rested for its token on the one clock,
## each ask putting it further off, and forgotten it is never done;
## asked nothing, nothing done and nothing processing.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_throttle.gd

const Themes := preload("res://addons/gd_chime/theme.gd")
const Fixture := preload("res://tests/fixture.gd")
const Motion := preload("res://addons/gd_chime/motion.gd")
const Throttle := preload("res://addons/gd_chime/throttle.gd")
const Verdict := preload("res://tests/verdict.gd")

const CADENCE := 250
## The token a settling throttle rests for here, in milliseconds.
const SETTLES := &"typing_settles"
const RESTS := 300

var _verdict := Verdict.new()
var _now: int = 1000  # the clock a paced throttle reads, moved by hand


func _init() -> void:
	var look := Themes.new(Themes.NEUTRAL)
	look.set_constant(Throttle.CADENCE, Motion.TYPE, CADENCE)
	look.set_constant(SETTLES, Motion.TYPE, RESTS)
	root.theme = look
	await process_frame
	await _verdict.states(_asked_a_hundred_times_in_a_frame_it_is_done_once_at_the_frame_s_end)
	await _verdict.states(_asked_in_two_frames_it_is_done_twice)
	await _verdict.states(_paced_it_is_done_no_oftener_than_the_cadence_and_the_last_ask_is_kept)
	await _verdict.states(_settled_it_waits_for_the_asking_to_rest_and_forgotten_is_never_done)
	await _verdict.states(_asked_nothing_it_does_nothing_and_does_not_process)
	quit(_verdict.deliver(get_script()))


## A throttle under the root counting its deeds into the list given.
func _made(deeds: Array, options: Dictionary = {}) -> Throttle:
	var throttle := Throttle.new(func() -> void: deeds.append(_now), options)
	throttle.clock = func() -> int: return _now
	root.add_child(throttle)
	return throttle


func _asked_a_hundred_times_in_a_frame_it_is_done_once_at_the_frame_s_end() -> void:
	var deeds: Array = []
	var throttle := _made(deeds)
	# a hundred asks in the one frame
	for ask: int in 100:
		throttle.ask()
	_verdict.check(deeds.is_empty() and throttle.is_due(), "asked, nothing is done before the frame's end: %s" % [deeds])
	await process_frame
	_verdict.check(deeds.size() == 1 and not throttle.is_due(), "a hundred asks in a frame are one deed at its end: %d" % deeds.size())
	throttle.free()


func _asked_in_two_frames_it_is_done_twice() -> void:
	var deeds: Array = []
	var throttle := _made(deeds)
	throttle.ask()
	await process_frame
	throttle.ask()
	throttle.ask()
	await process_frame
	_verdict.check(deeds.size() == 2, "asked in two frames, done twice: %d" % deeds.size())
	throttle.free()


func _paced_it_is_done_no_oftener_than_the_cadence_and_the_last_ask_is_kept() -> void:
	var deeds: Array = []
	var throttle := _made(deeds, {paced_by = Throttle.CADENCE})
	# sixty frames of asks, each frame ten milliseconds on: six hundred milliseconds of changes
	for frame: int in 60:
		throttle.ask()
		await process_frame
		_now += 10
	var apart: bool = range(1, deeds.size()).all(func(at: int) -> bool: return deeds[at] - deeds[at - 1] >= CADENCE)
	_verdict.check(deeds.size() >= 2 and deeds.size() <= 3 and apart, "paced, six hundred milliseconds of asks every frame are done at most once a cadence: %s" % [deeds])
	var before := deeds.size()
	throttle.ask()
	await process_frame
	_verdict.check(deeds.size() == before and throttle.is_due(), "an ask inside the cadence waits: %d deeds" % deeds.size())
	_now += CADENCE
	await process_frame
	await process_frame
	_verdict.check(deeds.size() == before + 1 and not throttle.is_due(), "the last ask is done as the cadence ends, never lost: %d deeds" % deeds.size())
	throttle.free()


## A settling throttle over its own clock, which only a step moves.
func _settled_it_waits_for_the_asking_to_rest_and_forgotten_is_never_done() -> void:
	var deeds: Array = []
	var made := Fixture.new(root)
	var motion: Motion = made.ui.motion
	motion.by_hand = true
	var throttle := _made(deeds, {settles_by = SETTLES, on = motion})
	# ten asks, each a fifth of the rest after the last: ten times as long as the rest, in all
	for ask: int in 10:
		throttle.ask()
		motion.step(RESTS / 5000.0)
	await process_frame
	await process_frame
	_verdict.check(deeds.is_empty() and throttle.is_due(), "asked ten times a fifth of the rest apart, nothing is done and one waits: %s" % [deeds])
	motion.step(RESTS / 1000.0 * 0.7)
	_verdict.check(deeds.is_empty(), "short of the rest since the last ask, still nothing: %s" % [deeds])
	motion.step(RESTS / 1000.0 * 0.4)
	_verdict.check(deeds.size() == 1 and not throttle.is_due(), "rested for its token, the deed is done once: %s" % [deeds])
	throttle.ask()
	throttle.forget()
	motion.step(RESTS / 1000.0 * 2.0)
	_verdict.check(deeds.size() == 1 and not throttle.is_due(), "what was forgotten is never done: %s" % [deeds])
	throttle.free()
	made.done()


func _asked_nothing_it_does_nothing_and_does_not_process() -> void:
	var deeds: Array = []
	var throttle := _made(deeds, {paced_by = Throttle.CADENCE})
	throttle.ask()
	await process_frame
	await process_frame
	_verdict.check(deeds.size() == 1 and not throttle.is_processing(), "done and asked nothing more, it does not process: %s" % throttle.is_processing())
	_now += CADENCE * 4
	await process_frame
	_verdict.check(deeds.size() == 1, "asked nothing, nothing is done: %d" % deeds.size())
	throttle.free()
