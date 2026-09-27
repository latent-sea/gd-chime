extends "controller.gd"

const Busy := preload("busy.gd")
const FrameBudget := preload("frame_budget.gd")

## The downtime drain: small work done in the gaps, on the main thread.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A caller hands in a small piece of WORK - a callable that runs on the main
## thread and returns - under a CATEGORY, a name for what kind of work it is.
## Every frame in which the application is idle and the frame is within its
## budget, the first unit of the first category that has any is run. That is
## the slice: one unit a frame. Within a category, units run in the order
## added.
##
## The categories are kept in ORDER, and that order is the only ranking there
## is. boost() moves a category to the top; what was above it shifts down a
## place and what was below stays. A category first seen through add() joins
## at the bottom, so unknown work never jumps the queue; one first seen
## through boost() is made at the top, so whoever moves the player between
## screens can say what is needed before the screen's model adds it. An
## empty category keeps its place: the order is where the player has been,
## and it outlasts the queue running dry.
##
## Nothing is ever removed. A result stays worth having whenever it lands,
## and cancelling is how a warmed cache empties itself. The drain decides
## nothing about what matters: the order is the callers', and so are the
## units.
##
## It listens to the busy gate and the frame budget in the global region, where
## both ring - BUSY_BEGAN and BUSY_ENDED, FRAME_OVERRAN and FRAME_RECOVERED - and on any of the four reads both models
## and switches its own processing on only while idle, within, and holding
## work; off the engine's list otherwise, the way a screen with nothing due
## is. Reading both on every wake, rather than remembering which bell rang,
## also answers what the state was when this was built.
##
## There is one drain and it outlives every screen, so it belongs to the global
## region rather than to one its builder chooses, and closing a screen never
## cuts it off from the gate and the budget.
##
## It holds no busy hold: the gate says whether the player is waiting on
## something, and downtime work is what nobody is waiting for. It rings no
## bell: a result belongs to whatever model added the work, which rings its
## own.
##
## A unit should be small. One that is not shows up as a run of long frames,
## and the budget's FRAME_OVERRAN stops the drain until the frame recovers. Work that
## needs a core for long belongs on the job pool, not here.
##
## Deliberately absent: a time budget of its own per frame (the frame budget
## is the measure), and a bell saying the queue has drained (nothing wants
## it).

var _busy: Busy
var _budget: FrameBudget
var _order: Array[StringName] = []  # every category seen, top first
var _queues: Dictionary = {}  # category -> its units, in the order added


func _init(chimes: Chimes, busy: Busy, budget: FrameBudget) -> void:
	super(chimes, [[Chimes.GLOBAL, Busy.BUSY_BEGAN], [Chimes.GLOBAL, Busy.BUSY_ENDED], [Chimes.GLOBAL, FrameBudget.FRAME_OVERRAN], [Chimes.GLOBAL, FrameBudget.FRAME_RECOVERED]], Chimes.GLOBAL)
	_busy = busy
	_budget = budget
	_settle()


## Entering the tree switches processing back on by itself for any script that
## defines _process, so the answer has to be asserted again here.
func _ready() -> void:
	_settle()


## Queue work under a category. A category not seen before joins at the
## bottom.
func add(category: StringName, work: Callable) -> void:
	if not _queues.has(category):
		_queues[category] = []
		_order.append(category)
	_queues[category].append(work)
	_settle()


## Move a category to the top; what was above it shifts down a place. A
## category not seen before is made here, at the top, with nothing in it yet.
func boost(category: StringName) -> void:
	if not _queues.has(category):
		_queues[category] = []
	_order.erase(category)
	_order.push_front(category)
	_settle()


## The categories, top first. A copy, so the order cannot be edited from
## outside.
func get_order() -> Array[StringName]:
	return _order.duplicate()


## How many units wait, in every category together.
func count() -> int:
	var total := 0
	# every category's queue, added up
	for category: StringName in _order:
		total += _queues[category].size()
	return total


## Any of the four bells: read both models and settle.
func heard(_what: StringName) -> void:
	_settle()


## Processing on if and only if this may run and has something to run.
func _settle() -> void:
	set_process(not _busy.is_busy() and not _budget.is_over() and count() > 0)


## One frame it may run: the first unit of the first category that has any.
func _process(_delta: float) -> void:
	# every category in order, looking for the first with anything waiting
	for category: StringName in _order:
		if _queues[category].is_empty():
			continue
		var work: Callable = _queues[category].pop_front()
		work.call()
		break
	_settle()
