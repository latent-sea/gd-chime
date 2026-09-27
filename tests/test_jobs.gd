extends SceneTree

## What must be true of the job pool.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_jobs.gd
##
## The pool runs work on the engine's threads and hands the answers back on
## the main thread. Proved here is the contract a caller relies on: an
## answer comes later, on main, with its own result; results arrive under
## their own keys however the threads finish; no more than the ceiling run
## at once; a submission past the bound is refused; frames keep passing while
## cores are held; the pool disabled gives the same results one a frame;
## stop() waits a running job out; nothing starts while the frame budget says
## over; an answer may submit more without losing anything; it is off the
## engine's list whenever nothing is out; and the pool belongs to the global
## region. Every pool is stopped, because a task left on the engine's pool
## crashes the process at exit - which the harness reads.
##
## Work is kept from touching anything shared: it holds a core for a while
## and returns a number. The real frame budget is used, driven over by a node
## burning the main thread.

const Belfry := preload("res://addons/gd_chime/belfry.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const FrameBudget := preload("res://addons/gd_chime/frame_budget.gd")
const Jobs := preload("res://addons/gd_chime/jobs.gd")
const Verdict := preload("res://tests/verdict.gd")

const PATIENCE := 600
const TARGET_MS := 16.0
const SHARE := 0.5
const RUN := 3
const BURN_MS := 12

var _verdict := Verdict.new()


## Takes answers, with the key each was bound with and the thread it came on.
class Catcher extends RefCounted:
	var results: Dictionary = {}  # key -> result
	var order: Array = []  # keys, in the order the answers arrived
	var on_main: Array[bool] = []

	func take(result: Variant, key: Variant) -> void:
		results[key] = result
		order.append(key)
		on_main.append(OS.get_thread_caller_id() == OS.get_main_thread_id())


## Counts how many pieces of work are running at the same moment, and the
## most there ever were. Guarded, because the workers write it together.
class Tally extends RefCounted:
	var _lock := Mutex.new()
	var _now := 0
	var most := 0

	func enter() -> void:
		_lock.lock()
		_now += 1
		most = maxi(most, _now)
		_lock.unlock()

	func leave() -> void:
		_lock.lock()
		_now -= 1
		_lock.unlock()


## Holds the main thread for this long every frame, to drive the budget over.
class Burner extends Node:
	var ms := 0

	func _process(_delta: float) -> void:
		var until := Time.get_ticks_usec() + ms * 1000
		# a busy loop, not a sleep, so the budget's step measure sees it
		while Time.get_ticks_usec() < until:
			pass


func _init() -> void:
	await _verdict.states(_an_answer_lands_later_on_the_main_thread_with_its_own_result)
	await _verdict.states(_answers_land_by_key_whatever_order_the_threads_finished)
	await _verdict.states(_at_most_the_ceiling_run_at_once_and_the_rest_wait)
	await _verdict.states(_a_submission_past_the_bound_is_refused_and_nothing_grows)
	await _verdict.states(_frames_keep_passing_on_main_while_the_pool_holds_cores)
	await _verdict.states(_with_the_pool_disabled_the_same_batch_lands_one_a_frame_in_order)
	await _verdict.states(_stop_waits_a_running_job_out_and_delivers_nothing_after)
	await _verdict.states(_while_the_budget_says_over_nothing_starts_and_what_is_running_lands)
	await _verdict.states(_an_answer_may_submit_more_and_nothing_is_lost)
	await _verdict.states(_it_is_off_the_engines_list_while_nothing_is_out)
	await _verdict.states(_the_pool_belongs_to_the_global_region)
	quit(_verdict.deliver(get_script()))


## Work: hold a core for this long, then answer with this.
func _hold_then(ms: int, value: Variant) -> Variant:
	var until := Time.get_ticks_msec() + ms
	# a busy loop on the worker, so the core is genuinely taken
	while Time.get_ticks_msec() < until:
		pass
	return value


## Work that reports itself running to a tally while it holds a core.
func _hold_counted(ms: int, value: Variant, tally: Tally) -> Variant:
	tally.enter()
	_hold_then(ms, null)
	tally.leave()
	return value


## A pool over the real frame budget, in the tree, as a dictionary: pool,
## budget and burner. This test hangs the belfry, standing in for whatever
## composes an application.
func _made(ceiling: int, depth: int, inline: bool) -> Dictionary:
	var chimes := Chimes.new(Belfry.new())
	var budget := FrameBudget.new(chimes, TARGET_MS, SHARE, RUN)
	var pool := Jobs.new(chimes, budget, ceiling, depth, inline)
	var burner := Burner.new()
	root.add_child(budget)
	root.add_child(pool)
	root.add_child(burner)
	return {"pool": pool, "budget": budget, "burner": burner}


## Frames pass until the condition holds, or patience runs out. Answers how
## many frames it took.
func _until(condition: Callable) -> int:
	var frames := 0
	# a frame at a time, until the condition holds or patience runs out
	while not condition.call() and frames < PATIENCE:
		await process_frame
		frames += 1
	return frames


func _frames(count: int) -> void:
	# this many frames, each one processed before the next is waited for
	for i: int in range(count):
		await process_frame


## The pool is stopped first, so nothing is left on the engine's pool; then
## the nodes are queued for freeing, since a deferred end-of-step call may be
## booked for the budget.
func _done(made: Dictionary) -> void:
	(made["pool"] as Jobs).stop()
	(made["burner"] as Node).queue_free()
	(made["pool"] as Node).queue_free()
	(made["budget"] as Node).queue_free()
	await _frames(2)


func _an_answer_lands_later_on_the_main_thread_with_its_own_result() -> void:
	var made := _made(2, 4, false)
	var pool: Jobs = made["pool"]
	var catcher := Catcher.new()

	pool.submit(_hold_then.bind(20, 42), catcher.take.bind(&"a"))

	_verdict.check(catcher.order.is_empty(), "nothing is answered within the call that submitted")
	await _until(func() -> bool: return catcher.order.size() >= 1)
	_verdict.check(catcher.results[&"a"] == 42, "the answer carries what the work returned")
	_verdict.check(catcher.on_main[0], "and arrives on the main thread")
	await _done(made)


## The threads finish in their own order - measured, never submission
## order - and each result still arrives under its own key. Void if they
## happened to finish in order, which the holds are shaped to prevent.
func _answers_land_by_key_whatever_order_the_threads_finished() -> void:
	var made := _made(6, 0, false)
	var pool: Jobs = made["pool"]
	var catcher := Catcher.new()
	# six jobs, the first holding longest, so the first submitted lands last
	for key: int in range(6):
		pool.submit(_hold_then.bind((6 - key) * 30, key * key), catcher.take.bind(key))
	await _until(func() -> bool: return catcher.order.size() >= 6)

	var all_own := true
	# every key, checked against the result that arrived under it
	for key: int in range(6):
		all_own = all_own and catcher.results[key] == key * key
	_verdict.check(all_own, "every result arrived under its own key")
	_verdict.check(catcher.order != [0, 1, 2, 3, 4, 5], "and the threads did not finish in submission order, or this proves nothing")
	await _done(made)


func _at_most_the_ceiling_run_at_once_and_the_rest_wait() -> void:
	var made := _made(2, 4, false)
	var pool: Jobs = made["pool"]
	var catcher := Catcher.new()
	var tally := Tally.new()
	# six jobs of equal length behind a ceiling of two
	for key: int in range(6):
		pool.submit(_hold_counted.bind(40, key, tally), catcher.take.bind(key))

	_verdict.check(pool.get_running() == 2 and pool.get_waiting() == 4, "two started and four wait")
	await _until(func() -> bool: return catcher.order.size() >= 6)
	_verdict.check(tally.most == 2, "and never more than two were running at once - the most was %d" % tally.most)
	_verdict.check(pool.get_running() == 0 and pool.get_waiting() == 0, "and afterwards nothing is out")
	await _done(made)


func _a_submission_past_the_bound_is_refused_and_nothing_grows() -> void:
	var made := _made(1, 1, false)
	var pool: Jobs = made["pool"]
	var catcher := Catcher.new()
	pool.submit(_hold_then.bind(30, 1), catcher.take.bind(1))
	pool.submit(_hold_then.bind(30, 2), catcher.take.bind(2))

	pool.submit(_hold_then.bind(30, 3), catcher.take.bind(3))

	_verdict.check(pool.get_running() == 1 and pool.get_waiting() == 1, "the third is refused and nothing grew")
	await _until(func() -> bool: return pool.get_running() == 0 and pool.get_waiting() == 0)
	_verdict.check(catcher.order == [1, 2], "and only the two accepted ever land")
	await _done(made)


## The whole reason for the pool. Four cores are held for 300 ms each; if
## the main thread were waiting on them, no frame would pass until they let go.
func _frames_keep_passing_on_main_while_the_pool_holds_cores() -> void:
	var made := _made(4, 0, false)
	var pool: Jobs = made["pool"]
	var catcher := Catcher.new()
	# four jobs each holding a core for 300 ms
	for key: int in range(4):
		pool.submit(_hold_then.bind(300, key), catcher.take.bind(key))

	var frames := await _until(func() -> bool: return catcher.order.size() >= 4)

	_verdict.check(catcher.order.size() == 4, "all four landed")
	_verdict.check(frames >= 10, "and %d frames passed on the main thread while the cores were held" % frames)
	await _done(made)


## With the pool disabled the same batch gives the same results, still later
## and on a frame - one a frame, in submission order.
func _with_the_pool_disabled_the_same_batch_lands_one_a_frame_in_order() -> void:
	var made := _made(2, 4, true)
	var pool: Jobs = made["pool"]
	var catcher := Catcher.new()
	# four keyed jobs, the batch the pool would take
	for key: int in range(4):
		pool.submit(_hold_then.bind(1, key * key), catcher.take.bind(key))

	_verdict.check(catcher.order.is_empty(), "nothing is answered within the call that submitted")
	await _frames(1)
	_verdict.check(catcher.order.size() == 1, "one lands on the first frame")
	await _frames(1)
	_verdict.check(catcher.order.size() == 2, "and one more on the next")
	await _until(func() -> bool: return catcher.order.size() >= 4)
	var all_own := true
	# every key, checked against the result that arrived under it
	for key: int in range(4):
		all_own = all_own and catcher.results[key] == key * key
	_verdict.check(catcher.order == [0, 1, 2, 3] and all_own, "all four, in submission order, with the results the pool would give")
	await _done(made)


## A window closing must not leave a task on the engine's pool - the process
## crashes at exit - and must not hand out answers after it was told to stop.
func _stop_waits_a_running_job_out_and_delivers_nothing_after() -> void:
	var made := _made(1, 1, false)
	var pool: Jobs = made["pool"]
	var catcher := Catcher.new()
	pool.submit(_hold_then.bind(300, 1), catcher.take.bind(1))
	pool.submit(_hold_then.bind(300, 2), catcher.take.bind(2))
	var began := Time.get_ticks_msec()

	pool.stop()

	_verdict.check(Time.get_ticks_msec() - began >= 250, "stopping waited the running job out")
	_verdict.check(pool.get_running() == 0 and pool.get_waiting() == 0, "and nothing is left, running or waiting")
	await _frames(3)
	_verdict.check(catcher.order.is_empty(), "and no answer was delivered after")
	await _done(made)


## While the frame budget says the frame is not being met, nothing new
## starts; what is already running still lands; and when the budget is
## within again, the waiting start. The budget is driven over by burning the
## main thread, and brought back by stopping.
func _while_the_budget_says_over_nothing_starts_and_what_is_running_lands() -> void:
	var made := _made(2, 4, false)
	var pool: Jobs = made["pool"]
	var budget: FrameBudget = made["budget"]
	var burner: Burner = made["burner"]
	var catcher := Catcher.new()
	pool.submit(_hold_then.bind(150, 1), catcher.take.bind(1))
	burner.ms = BURN_MS
	await _until(func() -> bool: return budget.is_over())

	pool.submit(_hold_then.bind(20, 2), catcher.take.bind(2))
	await _frames(4)

	_verdict.check(pool.get_waiting() == 1, "a job submitted while over waits, though there is room")
	await _until(func() -> bool: return catcher.order.size() >= 1)
	_verdict.check(catcher.order == [1] and budget.is_over(), "the job already running landed, while still over")
	_verdict.check(pool.get_waiting() == 1, "and the waiting one still has not started")
	burner.ms = 0
	await _until(func() -> bool: return catcher.order.size() >= 2)
	_verdict.check(not budget.is_over(), "within again, the waiting one started and landed")
	await _done(made)


## An answer that submits more work arrives while the pool is mid-sweep, so
## the bookkeeping has to be done before answers are called or the new job
## is lost - and a lost job is a task never waited, which crashes the
## process at exit.
func _an_answer_may_submit_more_and_nothing_is_lost() -> void:
	var made := _made(2, 4, false)
	var pool: Jobs = made["pool"]
	var catcher := Catcher.new()
	var again := func(result: Variant, key: Variant) -> void:
		catcher.take(result, key)
		if key == 1:
			pool.submit(_hold_then.bind(20, 2), catcher.take.bind(2))

	pool.submit(_hold_then.bind(20, 1), again.bind(1))
	await _until(func() -> bool: return catcher.order.size() >= 2)

	_verdict.check(catcher.order == [1, 2], "the job submitted from an answer landed too")
	_verdict.check(pool.get_running() == 0 and pool.get_waiting() == 0, "and nothing is left out")
	await _done(made)


## The pool asks the engine for a frame only while something is out: off from
## the moment it enters the tree with nothing out, before a single frame could
## turn it off again, on once work is submitted, off again when the last answer
## has landed, and off once stopped with work still out.
func _it_is_off_the_engines_list_while_nothing_is_out() -> void:
	var made := _made(1, 2, false)
	var pool: Jobs = made["pool"]
	var catcher := Catcher.new()
	_verdict.check(not pool.is_processing(), "entering the tree with nothing out, it is off the list")

	pool.submit(_hold_then.bind(20, 1), catcher.take.bind(1))
	pool.submit(_hold_then.bind(20, 2), catcher.take.bind(2))
	_verdict.check(pool.is_processing(), "with work out it is on")
	await _until(func() -> bool: return catcher.order.size() >= 2)
	await _frames(1)
	_verdict.check(catcher.order.size() == 2 and not pool.is_processing(), "and once the last answer has landed, off again")

	pool.submit(_hold_then.bind(200, 3), catcher.take.bind(3))
	pool.stop()
	_verdict.check(not pool.is_processing(), "and stopped with work out, off")
	await _done(made)


## There is one pool and it outlives every screen, so it belongs to the global
## region, as the budget it reads does, with nothing said about a region when
## either was made.
func _the_pool_belongs_to_the_global_region() -> void:
	var made := _made(1, 1, false)
	var pool: Jobs = made["pool"]

	_verdict.check(pool.region == Chimes.GLOBAL, "the pool is in the global region: %s" % pool.region)
	await _done(made)
