extends "controller.gd"

const FrameBudget := preload("frame_budget.gd")

## The job pool: heavy work off the frame, its answers back on it.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A caller hands in WORK - a callable that computes something and returns
## it - and an ANSWER, a callable to hand the result to. The work runs on one
## of the engine's threads. The answer is called later, on the main thread,
## on a frame, with what the work returned: never inside the call that
## submitted, never from a worker, never twice. The caller keys its own
## answers - answer.bind(key) - so however the threads finish, each result
## arrives under the key it was asked for. Results are put together by key,
## never by the order they arrived.
##
## At most the ceiling run at once; the rest wait, in the order submitted.
## The ceiling is whoever composes the application's number and can be
## changed while work is out. Every job goes to the engine at its normal
## priority, so the engine's own cap on such tasks sits underneath. Behind
## the running, at most the depth wait; a submission past that bound is
## refused out loud, because the caller controls how much it submits.
##
## Before a waiting job starts, the frame budget is asked. While it says the
## frame is not being met, nothing new starts and what is running finishes.
## A task on the pool cannot be interrupted, so backing off means not
## starting the next one, and a job is kept the size of a phase for that
## reason.
##
## It holds no busy hold. Busy means the player is waiting, and work on the pool
## is waited on only sometimes: work done ahead of need, while the player is
## doing something else, is waited on by nobody, and must neither pause the
## drain nor tell the player that something is not ready. Whatever the player
## is waiting on holds the gate itself, for the whole of the wait - which is
## longer than any job it submits, since the answers still have to be applied
## and shown.
##
## There is one pool and it outlives every screen, so it belongs to the global
## region rather than to one its builder chooses, as the budget it reads does.
##
## Answers come back through this file's own sweep, once a frame while
## anything is out: each running task is asked whether it completed, waited
## exactly once, its result read from the slot the worker filled, and its
## answer called. The engine forgets a waited task, so a second wait is an
## engine error, and a completed task never waited crashes the application
## at exit. stop() therefore waits everything still on the pool, delivers
## nothing further and lets the waiting go; whoever made this calls it on
## the way out.
##
## Answers are called after the sweep's bookkeeping, so an answer that
## submits more work sees the pool as it is and loses nothing.
##
## Built with the pool disabled, a job runs on the main thread instead - one
## a frame, in submission order - and the answer still arrives later, on a
## frame. Parallelism changes speed, never results.
##
## What a job does is the caller's business: it computes from what it was
## handed and returns. It must not touch the scene tree, the belfry or
## anything shared, and nothing here can check that.
##
## Deliberately absent: an order of importance between jobs, cancelling one,
## and a bell saying a job landed - the answer is the landing.

var _budget: FrameBudget
var _ceiling: int
var _depth: int
var _inline: bool
var _waiting: Array[Dictionary] = []  # {work, answer}, in the order submitted
var _running: Array[Dictionary] = []  # {task, slot, answer}, in the order started


func _init(chimes: Chimes, budget: FrameBudget, ceiling: int, depth: int, inline: bool) -> void:
	super(chimes, [], Chimes.GLOBAL)
	set_process(false)
	_budget = budget
	_depth = depth
	_inline = inline
	set_ceiling(ceiling)


## Entering the tree switches processing back on by itself for any script that
## defines _process, so whether anything is out has to be asserted again here.
func _ready() -> void:
	set_process(_is_out())


## Queue work. Refused past the bound: the running and the waiting together
## may not exceed the ceiling plus the depth.
func submit(work: Callable, answer: Callable) -> void:
	if _waiting.size() + _running.size() >= _ceiling + _depth:
		push_error("the pool is full: %d running, %d waiting" % [_running.size(), _waiting.size()])
		return
	_waiting.append({"work": work, "answer": answer})
	set_process(true)
	_start_waiting()


## How many may run at once, from the next start. A ceiling below one would
## start nothing and leave the work out forever, which is refused rather than
## allowed to happen quietly.
func set_ceiling(ceiling: int) -> void:
	if ceiling < 1:
		push_error("a ceiling of %d would start nothing" % ceiling)
		return
	_ceiling = ceiling


func get_running() -> int:
	return _running.size()


func get_waiting() -> int:
	return _waiting.size()


## Start waiting jobs while there is room under the ceiling and the frame
## budget is within. With the pool disabled nothing starts here; the sweep
## runs one a frame instead.
func _start_waiting() -> void:
	if _inline:
		return
	# every waiting job for which there is room and budget, in order
	while _running.size() < _ceiling and not _waiting.is_empty() and not _budget.is_over():
		var job: Dictionary = _waiting.pop_front()
		var slot: Array = [null]
		# the worker fills the slot and touches nothing else; the wait is the handover
		var task := WorkerThreadPool.add_task(func() -> void: slot[0] = job["work"].call())
		_running.append({"task": task, "slot": slot, "answer": job["answer"]})


## Once a frame while anything is out: what has landed is answered, the next
## waiting jobs are started, and with nothing left the pool stops asking for
## frames.
func _process(_delta: float) -> void:
	var landed: Array[Dictionary] = []
	if _inline and not _waiting.is_empty() and not _budget.is_over():
		var job: Dictionary = _waiting.pop_front()
		landed.append({"slot": [job["work"].call()], "answer": job["answer"]})
	var still: Array[Dictionary] = []
	# every running task, in the order started: the completed waited once and set aside, the rest kept
	for job: Dictionary in _running:
		if not WorkerThreadPool.is_task_completed(job["task"]):
			still.append(job)
			continue
		WorkerThreadPool.wait_for_task_completion(job["task"])
		landed.append(job)
	_running = still
	# every landed job answered, after the bookkeeping, with what its worker put in the slot
	for job: Dictionary in landed:
		job["answer"].call(job["slot"][0])
	_start_waiting()
	set_process(_is_out())


## On the way out: wait every task still on the pool, deliver nothing
## further, and let the waiting go.
func stop() -> void:
	# every running task, waited out; the pool cannot interrupt one
	for job: Dictionary in _running:
		WorkerThreadPool.wait_for_task_completion(job["task"])
	_running.clear()
	_waiting.clear()
	set_process(false)


## Whether anything is waiting or running.
func _is_out() -> bool:
	return not _waiting.is_empty() or not _running.is_empty()
