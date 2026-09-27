extends SceneTree

## What must be true of the frame budget.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_frame_budget.gd
##
## The frame budget measures the game's own per-frame work and the time
## between frames, and says when the frame is not being met. Proved here: an
## idle game is within and stays so; work past the share for a run of frames
## takes it over, and FRAME_OVERRAN sounds once; the work stopping brings it back, and
## FRAME_RECOVERED sounds once; one bad frame alone moves nothing; frames running
## long while the main thread is idle trip it on their own - the dropped-frame
## half, made with the engine's own frame cap; and the budget rings in the global
## region, where anything can hear it without being told. The numbers are chosen
## for a headless run, where a frame is a few milliseconds and no display sets
## the pace.

const Belfry := preload("res://addons/gd_chime/belfry.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const FrameBudget := preload("res://addons/gd_chime/frame_budget.gd")
const Verdict := preload("res://tests/verdict.gd")

const TARGET_MS := 16.0
const SHARE := 0.5  # so 8 ms of work in a frame is past the share
const RUN := 3
const BURN_MS := 12  # past the share, and short of a dropped frame

var _verdict := Verdict.new()


class Ear extends RefCounted:
	var arrivals: Array[StringName] = []

	func heard(what: StringName) -> void:
		arrivals.append(what)


## Holds the main thread for this long every frame, the way a heavy screen does.
class Burner extends Node:
	var ms := 0

	func _process(_delta: float) -> void:
		var until := Time.get_ticks_usec() + ms * 1000
		# a busy loop, not a sleep, so the step measure sees the main thread taken
		while Time.get_ticks_usec() < until:
			pass


func _init() -> void:
	await _verdict.states(_an_idle_game_is_within_and_stays_so)
	await _verdict.states(_work_past_the_share_for_a_run_takes_it_over_and_frame_overran_sounds_once)
	await _verdict.states(_the_work_stopping_brings_it_back_and_frame_recovered_sounds_once)
	await _verdict.states(_one_bad_frame_alone_moves_nothing)
	await _verdict.states(_frames_running_long_with_the_main_thread_idle_trip_it_on_their_own)
	await _verdict.states(_the_budget_rings_in_the_global_region)
	quit(_verdict.deliver(get_script()))


## A budget in the tree, an ear on both its bells, and a burner behind it in
## the tree, as [budget, ear, burner]. This test hangs the belfry and wires the
## ear by hand, standing in for whatever composes an application.
func _made() -> Array:
	var chimes := Chimes.new(Belfry.new())
	var budget := FrameBudget.new(chimes, TARGET_MS, SHARE, RUN)
	root.add_child(budget)
	var ear := Ear.new()
	chimes.listen(ear, Chimes.GLOBAL, FrameBudget.FRAME_OVERRAN)
	chimes.listen(ear, Chimes.GLOBAL, FrameBudget.FRAME_RECOVERED)
	var burner := Burner.new()
	root.add_child(burner)
	return [budget, ear, burner]


func _frames(count: int) -> void:
	# this many frames, each one processed before the next is waited for
	for i: int in range(count):
		await process_frame


## Both nodes are queued rather than freed: a deferred end-of-step call may
## still be booked for the budget on the frame this runs.
func _done(made: Array) -> void:
	(made[0] as Node).queue_free()
	(made[2] as Node).queue_free()
	await _frames(2)


func _an_idle_game_is_within_and_stays_so() -> void:
	var made := _made()
	var budget: FrameBudget = made[0]
	var ear: Ear = made[1]

	await _frames(10)

	_verdict.check(not budget.is_over(), "an idle game is within its budget")
	_verdict.check(ear.arrivals.is_empty(), "and nothing has sounded")
	_verdict.check(budget.get_step_ms() < TARGET_MS * SHARE, "its work is under the share")
	_verdict.check(budget.get_period_ms() < TARGET_MS * FrameBudget.DROPPED, "and its frames are not long")
	await _done(made)


func _work_past_the_share_for_a_run_takes_it_over_and_frame_overran_sounds_once() -> void:
	var made := _made()
	var budget: FrameBudget = made[0]
	var ear: Ear = made[1]
	var burner: Burner = made[2]
	await _frames(4)

	burner.ms = BURN_MS
	await _frames(10)

	_verdict.check(budget.is_over(), "work past the share for a run of frames takes it over")
	_verdict.check(ear.arrivals == [FrameBudget.FRAME_OVERRAN], "and FRAME_OVERRAN sounded once")
	_verdict.check(budget.get_step_ms() >= BURN_MS - 1, "and the step it measured is the work that was done")
	burner.ms = 0
	await _done(made)


func _the_work_stopping_brings_it_back_and_frame_recovered_sounds_once() -> void:
	var made := _made()
	var budget: FrameBudget = made[0]
	var ear: Ear = made[1]
	var burner: Burner = made[2]
	burner.ms = BURN_MS
	await _frames(10)
	_verdict.check(budget.is_over(), "over, to begin with")

	burner.ms = 0
	await _frames(10)

	_verdict.check(not budget.is_over(), "the work stopping brings it back within")
	_verdict.check(ear.arrivals == [FrameBudget.FRAME_OVERRAN, FrameBudget.FRAME_RECOVERED], "and FRAME_RECOVERED sounded once, after the FRAME_OVERRAN")
	await _done(made)


## The run exists so that one bad frame cannot flip the answer. process_frame
## is emitted before nodes are processed, so two waits bracket exactly one
## burned frame.
func _one_bad_frame_alone_moves_nothing() -> void:
	var made := _made()
	var budget: FrameBudget = made[0]
	var ear: Ear = made[1]
	var burner: Burner = made[2]
	await _frames(4)

	burner.ms = BURN_MS
	await _frames(2)
	burner.ms = 0
	await _frames(8)

	_verdict.check(not budget.is_over(), "one bad frame does not take it over")
	_verdict.check(ear.arrivals.is_empty(), "and nothing sounded")
	await _done(made)


## The other half of the measure: frames arriving late while the main thread
## does almost nothing, which is what a throttled GPU or a dropped frame looks
## like. The engine's own frame cap makes it happen on demand.
func _frames_running_long_with_the_main_thread_idle_trip_it_on_their_own() -> void:
	var made := _made()
	var budget: FrameBudget = made[0]
	var ear: Ear = made[1]
	await _frames(4)

	Engine.max_fps = 20
	await _frames(10)

	_verdict.check(budget.is_over(), "frames running long take it over")
	_verdict.check(budget.get_period_ms() > TARGET_MS * FrameBudget.DROPPED, "on the period")
	_verdict.check(budget.get_step_ms() < TARGET_MS * SHARE, "with the step still under the share")
	_verdict.check(ear.arrivals == [FrameBudget.FRAME_OVERRAN], "and FRAME_OVERRAN sounded once")
	Engine.max_fps = 0
	await _frames(10)
	_verdict.check(not budget.is_over() and ear.arrivals == [FrameBudget.FRAME_OVERRAN, FrameBudget.FRAME_RECOVERED], "and the cap lifting brings it back, with FRAME_RECOVERED once")
	await _done(made)


## There is one budget and it outlives every screen, so its bells hang in the
## global region: a listener that knows only a bell's name and the global region
## hears it, with nothing said about a region when the budget was made.
func _the_budget_rings_in_the_global_region() -> void:
	var made := _made()
	var budget: FrameBudget = made[0]
	var ear: Ear = made[1]
	var burner: Burner = made[2]
	await _frames(4)

	burner.ms = BURN_MS
	await _frames(10)

	_verdict.check(budget.region == Chimes.GLOBAL, "the budget is in the global region: %s" % budget.region)
	_verdict.check(ear.arrivals == [FrameBudget.FRAME_OVERRAN], "and its bell is heard there: %s" % [ear.arrivals])
	burner.ms = 0
	await _done(made)
