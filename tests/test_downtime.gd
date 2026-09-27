extends SceneTree

## What must be true of the downtime drain.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_downtime.gd
##
## The drain runs small work in the gaps, one unit a frame, in the order of
## its categories. Proved here: one a frame, first category first, first
## added first; a category first seen through add joins at the bottom; a
## boost moves a category to the top and shifts what was above it down; a
## category first seen through boost is made at the top; an empty category
## keeps its place; nothing runs while the busy gate is held or the budget
## says over, and it carries on when they clear; it is off the engine's list
## whenever it may not run or has nothing to run; built while the gate is
## already held, it knows; and it listens from the global region, hearing the
## gate without being told where it rings. The real busy gate and the real
## frame budget are used, the budget driven over by a node burning the main
## thread. A unit does nothing but note that it ran.

const Belfry := preload("res://addons/gd_chime/belfry.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Busy := preload("res://addons/gd_chime/busy.gd")
const FrameBudget := preload("res://addons/gd_chime/frame_budget.gd")
const Downtime := preload("res://addons/gd_chime/downtime.gd")
const Verdict := preload("res://tests/verdict.gd")

const PATIENCE := 600
const TARGET_MS := 16.0
const SHARE := 0.5
const RUN := 3
const BURN_MS := 12

var _verdict := Verdict.new()


## Holds the main thread for this long every frame, to drive the budget over.
class Burner extends Node:
	var ms := 0

	func _process(_delta: float) -> void:
		var until := Time.get_ticks_usec() + ms * 1000
		# a busy loop, not a sleep, so the budget's step measure sees it
		while Time.get_ticks_usec() < until:
			pass


func _init() -> void:
	# the first frame's signal comes before any node has been processed; after it, one await is one processed frame
	await process_frame
	await _verdict.states(_idle_and_within_it_runs_one_a_frame_first_category_first_first_added_first)
	await _verdict.states(_a_category_first_seen_through_add_joins_at_the_bottom)
	await _verdict.states(_a_boost_moves_a_category_to_the_top_and_shifts_what_was_above_it_down)
	await _verdict.states(_a_category_first_seen_through_boost_is_made_at_the_top)
	await _verdict.states(_an_empty_category_keeps_its_place)
	await _verdict.states(_while_the_gate_is_held_it_runs_nothing_and_carries_on_at_idle)
	await _verdict.states(_while_the_budget_says_over_it_runs_nothing_and_carries_on_within)
	await _verdict.states(_it_is_off_the_engines_list_when_it_may_not_run_or_has_nothing_to_run)
	await _verdict.states(_built_while_the_gate_is_held_it_knows)
	await _verdict.states(_the_drain_listens_from_the_global_region)
	quit(_verdict.deliver(get_script()))


## A unit: notes its name in the record of what ran.
func _note(ran: Array, name: StringName) -> void:
	ran.append(name)


## A drain over the real busy gate and the real frame budget, in the tree, as
## a dictionary: drain, busy, budget, burner, and ran - what has run, in
## order. This test hangs the belfry, standing in for whatever composes an
## application. The gate may be held before the drain is built.
func _made(held_first: bool) -> Dictionary:
	var chimes := Chimes.new(Belfry.new())
	var busy := Busy.new(chimes)
	var budget := FrameBudget.new(chimes, TARGET_MS, SHARE, RUN)
	if held_first:
		busy.hold(&"already")
	var drain := Downtime.new(chimes, busy, budget)
	var burner := Burner.new()
	root.add_child(busy)
	root.add_child(budget)
	root.add_child(drain)
	root.add_child(burner)
	return {"drain": drain, "busy": busy, "budget": budget, "burner": burner, "ran": []}


## A unit under a category, which notes its name when it runs.
func _add(made: Dictionary, category: StringName, name: StringName) -> void:
	(made["drain"] as Downtime).add(category, _note.bind(made["ran"], name))


## Frames pass until the condition holds, or patience runs out.
func _until(condition: Callable) -> void:
	var frames := 0
	# a frame at a time, until the condition holds or patience runs out
	while not condition.call() and frames < PATIENCE:
		await process_frame
		frames += 1


func _frames(count: int) -> void:
	# this many frames, each one processed before the next is waited for
	for i: int in range(count):
		await process_frame


## Nodes queued rather than freed: a deferred end-of-step call may still be
## booked for the budget on the frame this runs.
func _done(made: Dictionary) -> void:
	(made["burner"] as Node).queue_free()
	(made["drain"] as Node).queue_free()
	(made["budget"] as Node).queue_free()
	(made["busy"] as Node).queue_free()
	await _frames(2)


func _idle_and_within_it_runs_one_a_frame_first_category_first_first_added_first() -> void:
	var made := _made(false)
	var drain: Downtime = made["drain"]
	var ran: Array = made["ran"]
	_add(made, &"thumbnails", &"a")
	_add(made, &"thumbnails", &"b")
	_add(made, &"records", &"c")
	drain.boost(&"records")

	_verdict.check(ran.is_empty(), "nothing runs within the call that added")
	await _frames(1)
	_verdict.check(ran == [&"c"], "one unit ran on the first frame, from the boosted category")
	await _frames(1)
	_verdict.check(ran == [&"c", &"a"], "then the first added of the other")
	await _frames(1)
	_verdict.check(ran == [&"c", &"a", &"b"] and drain.count() == 0, "then the next, and nothing waits")
	await _done(made)


func _a_category_first_seen_through_add_joins_at_the_bottom() -> void:
	var made := _made(false)
	var drain: Downtime = made["drain"]
	_add(made, &"thumbnails", &"a")

	_add(made, &"records", &"b")

	_verdict.check(drain.get_order() == [&"thumbnails", &"records"], "the newcomer is below what was there")
	await _until(func() -> bool: return drain.count() == 0)
	_verdict.check(made["ran"] == [&"a", &"b"], "and its unit ran after")
	await _done(made)


## The gate is held while the order is arranged, so what is proved is the
## order itself and not the timing of the running.
func _a_boost_moves_a_category_to_the_top_and_shifts_what_was_above_it_down() -> void:
	var made := _made(false)
	var drain: Downtime = made["drain"]
	var busy: Busy = made["busy"]
	busy.hold(&"not yet")
	_add(made, &"thumbnails", &"a")
	_add(made, &"records", &"b")
	_add(made, &"portraits", &"c")

	drain.boost(&"portraits")
	_verdict.check(drain.get_order() == [&"portraits", &"thumbnails", &"records"], "the boosted one is on top and the rest shifted down in their order")
	drain.boost(&"records")
	_verdict.check(drain.get_order() == [&"records", &"portraits", &"thumbnails"], "a second boost goes above the first")

	busy.release(&"not yet")
	await _until(func() -> bool: return drain.count() == 0)
	_verdict.check(made["ran"] == [&"b", &"c", &"a"], "and the units ran in that order")
	await _done(made)


func _a_category_first_seen_through_boost_is_made_at_the_top() -> void:
	var made := _made(false)
	var drain: Downtime = made["drain"]
	var busy: Busy = made["busy"]
	busy.hold(&"not yet")
	_add(made, &"thumbnails", &"a")

	drain.boost(&"portraits")
	_verdict.check(drain.get_order() == [&"portraits", &"thumbnails"], "a category boosted before anything is added to it is on top")
	_add(made, &"portraits", &"z")

	busy.release(&"not yet")
	await _until(func() -> bool: return drain.count() == 0)
	_verdict.check(made["ran"] == [&"z", &"a"], "and what is added to it afterwards runs first")
	await _done(made)


func _an_empty_category_keeps_its_place() -> void:
	var made := _made(false)
	var drain: Downtime = made["drain"]
	_add(made, &"thumbnails", &"a")
	_add(made, &"records", &"b")
	drain.boost(&"records")
	await _until(func() -> bool: return drain.count() == 0)
	_verdict.check(drain.get_order() == [&"records", &"thumbnails"], "the order stands with nothing waiting")

	_add(made, &"thumbnails", &"a2")
	_add(made, &"records", &"b2")

	await _until(func() -> bool: return drain.count() == 0)
	_verdict.check(made["ran"] == [&"b", &"a", &"b2", &"a2"], "and the boosted category still runs first")
	await _done(made)


func _while_the_gate_is_held_it_runs_nothing_and_carries_on_at_idle() -> void:
	var made := _made(false)
	var busy: Busy = made["busy"]
	_add(made, &"thumbnails", &"a")
	_add(made, &"thumbnails", &"b")
	await _frames(1)
	_verdict.check(made["ran"] == [&"a"], "one ran while idle")

	busy.hold(&"binding")
	await _frames(5)

	_verdict.check(made["ran"] == [&"a"], "nothing more ran while the gate was held")
	busy.release(&"binding")
	await _frames(2)
	_verdict.check(made["ran"] == [&"a", &"b"], "and the rest ran once it was idle again")
	await _done(made)


func _while_the_budget_says_over_it_runs_nothing_and_carries_on_within() -> void:
	var made := _made(false)
	var drain: Downtime = made["drain"]
	var budget: FrameBudget = made["budget"]
	var burner: Burner = made["burner"]
	burner.ms = BURN_MS
	await _until(func() -> bool: return budget.is_over())
	_add(made, &"thumbnails", &"a")
	_add(made, &"thumbnails", &"b")

	await _frames(5)

	_verdict.check(made["ran"].is_empty(), "nothing ran while the budget said over")
	burner.ms = 0
	await _until(func() -> bool: return drain.count() == 0)
	_verdict.check(made["ran"] == [&"a", &"b"] and not budget.is_over(), "and everything ran once it was within")
	await _done(made)


func _it_is_off_the_engines_list_when_it_may_not_run_or_has_nothing_to_run() -> void:
	var made := _made(false)
	var drain: Downtime = made["drain"]
	var busy: Busy = made["busy"]
	await _frames(1)
	_verdict.check(not drain.is_processing(), "with nothing to run it is off the list")

	_add(made, &"thumbnails", &"a")
	_verdict.check(drain.is_processing(), "with something to run it is on")
	busy.hold(&"binding")
	_verdict.check(not drain.is_processing(), "held, it is off")
	busy.release(&"binding")
	_verdict.check(drain.is_processing(), "released, on again")
	await _until(func() -> bool: return drain.count() == 0)
	await _frames(1)
	_verdict.check(not drain.is_processing(), "and drained, off again")
	await _done(made)


## The state it was born into is read, not assumed: a drain built while the
## gate is already held runs nothing until BUSY_ENDED.
func _built_while_the_gate_is_held_it_knows() -> void:
	var made := _made(true)
	var drain: Downtime = made["drain"]
	var busy: Busy = made["busy"]
	_add(made, &"thumbnails", &"a")

	await _frames(4)

	_verdict.check(made["ran"].is_empty() and not drain.is_processing(), "nothing ran and it is off the list, because the gate was held before it existed")
	busy.release(&"already")
	await _frames(2)
	_verdict.check(made["ran"] == [&"a"], "and it ran once the gate went idle")
	await _done(made)


## There is one drain and it outlives every screen, so it belongs to the global
## region and listens there, where the gate and the budget ring: it hears the
## gate with nothing said about a region when any of the three was made.
func _the_drain_listens_from_the_global_region() -> void:
	var made := _made(false)
	var drain: Downtime = made["drain"]
	var busy: Busy = made["busy"]
	_add(made, &"thumbnails", &"a")

	busy.hold(&"binding")

	_verdict.check(drain.region == Chimes.GLOBAL, "the drain is in the global region: %s" % drain.region)
	_verdict.check(not drain.is_processing(), "and heard the gate held, so it is off the list")
	busy.release(&"binding")
	_verdict.check(drain.is_processing(), "and heard it released, so it is on again")
	await _done(made)
