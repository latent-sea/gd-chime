extends "controller.gd"

const FrameBudget := preload("frame_budget.gd")
## One value on its way, stepped here (run.gd).
const Run := preload("run.gd")
const Look := preload("look.gd")

## Motion: the one clock every animation runs on, and what the look says
## about how things move.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## MOTION BELONGS TO THE LOOK. The Theme holds the tokens under the type
## Motion: three durations - quick, normal, slow - and the stagger, in
## milliseconds, and the easings - enter, exit, move, emphasis, and
## restyle, which a change of style blends by - each a
## curve and the duration it lasts. Whatever moves asks by an easing's
## name, never in seconds, so a look changes how the whole interface moves
## and a recipe never writes a number. motion_tokens.gd writes a set into a Theme;
## a Theme that holds none moves nothing: every run lasts no time at all.
## THE TOKENS ARE READ FROM THE NODE THAT MOVES where a run is given one -
## whatever is driven is - so a part of the screen under a look of its own
## moves by its own look; a run of no node reads the window's.
##
## ONE CLOCK. A run is a value going from where it is to where it is
## wanted, handed back through a function on every step. Every run in the
## application is stepped here, in order, by one _process - so a test
## turns by_hand on and calls step(seconds) itself, and every animation is
## the same on every machine, frame by frame, with no window and no wait.
## A WAIT is timed on it too (after): a token's time passing, then done.
##
## IT IS MAIN-THREAD WORK, so it answers to the frame budget it is given:
## while the budget is over, a new run snaps to its end. What is running
## already runs on; only new work is refused.
##
## REDUCED MOTION is a setting held here, a command and a read like any
## other: while it is on, a run that MOVES a thing - slides, scales,
## bounces - snaps to its end, and a run that only FADES becomes a short
## straight cross-fade, the quick duration with no curve.
##
## ONE RUN WRITES ONE PROPERTY OF ONE NODE. drive() is a run that says
## what it writes - this node's opacity, its scale, its shift - and takes
## over from whatever was driving that already, from the value it had
## reached: an entrance turned into an exit mid-way turns round smoothly,
## and two runs never write the same thing frame about. What it takes over
## from is stopped, and never says it arrived.
##
## MANY ARRIVING OR GOING AT ONCE ARE AT REST AT ONCE, as a filter or a search
## shows or hides them: past the look's bulk of things starting an entrance or
## an exit in one frame, every one of that frame's is at its end, those begun
## before the count was passed too. One change - a drop, an add - moves as ever.
##
## A new target mid-flight RETARGETS: the run goes on from the value it has
## reached, and never jumps. A RUN IS HANDED A METHOD OF THE NODE IT MOVES,
## never a function closed over it: a method of a freed node is known to be
## gone, and the run is dropped; a closure is not, and would reach into it.

const TYPE := &"Motion"
const DURATIONS: Array[StringName] = [&"quick", &"normal", &"slow"]
const STAGGER := &"stagger"
## A second passing, in milliseconds, and how many last seconds of a countdown beat.
const BEAT := &"beat"
const BEAT_FOR := &"beat_for"
## How many things may start arriving or going in one frame and still move.
const BULK := &"bulk"
const ENTER := &"enter"
const EXIT := &"exit"
const MOVE := &"move"
const EMPHASIS := &"emphasis"
## The easing a change of style blends by: hover, glow, a bound style moving.
const RESTYLE := &"restyle"
## The command that sets reduced motion, {"on": bool}: a value, read by get_reduced().
const REDUCES := &"reduces_motion"


## Stepped by a test instead of by the engine's frames.
var by_hand: bool = false
## Nothing moves: every run is at its end at once. For a test of something
## other than motion, which reads what is there straight after a change.
var still: bool = false
## The budget this answers to, if any.
var budget: FrameBudget = null

var _reduced := value(false)
var _under: Node  # what this stands under, whose look the tokens are read from
var _runs: Array[Run] = []
var _driving: Dictionary = {}  # [a node's id, what of it] -> the one run writing that
var _frame: int = -1  # the frame the two below were counted in
var _starting: Dictionary = {}  # each thing that began arriving or going in it -> true
var _started: Array[Run] = []  # the entrances and exits begun in it that still move


func _init(chimes: Chimes, under: Node) -> void:
	super(chimes, [], Chimes.GLOBAL)
	_under = under


func get_reduced() -> bool:
	return _reduced.read()


func told(_action: StringName, payload: Dictionary) -> Phrase:
	_reduced.set_value(payload["on"])
	return null


## How long an easing lasts, in seconds, as the look says - this node's look, or the window's.
func lasts(easing: StringName, under: Control = null) -> float:
	return get_token(DURATIONS[get_token(StringName(easing + "_lasts"), under)], under) / 1000.0


## The look's stagger, in seconds: the wait between things entering together.
func stagger(under: Control = null) -> float:
	return get_token(STAGGER, under) / 1000.0


## One of the look's motion tokens by name, read where the look is: on the node, or above what this stands under.
func get_token(named: StringName, under: Control = null) -> int:
	return under.get_theme_constant(named, TYPE) if under != null else Look.wearer(_under).get_theme_constant(named, TYPE)


## A value set going from one end to the other by this easing, handed to
## apply on every step and to done, if given, as it arrives. A run that
## only fades says so, and is a cross-fade while motion is reduced.
func run(from: Variant, to: Variant, easing: StringName, apply: Callable, fades: bool = false, done: Callable = Callable(), under: Control = null) -> Run:
	var made := Run.new()
	made.under = under
	made.value = from
	made.restart(from)
	made.to = to
	made.apply = apply
	made.done = done
	made.easing = easing
	made.fades = fades
	_begin(made)
	return made


## A wait on the one clock (run.gd, waiting): done once the look's token, in
## milliseconds, has passed - stepped like every run, and never shortened.
func after(token: StringName, done: Callable, under: Control = null) -> Run:
	return wait(get_token(token, under) / 1000.0, done)


## A wait on the one clock of this many seconds, for a time a look holds
## under another type than Motion - a finger held (touch.gd).
func wait(seconds: float, done: Callable) -> Run:
	var made: Run = Run.waiting(seconds, done)
	_runs.append(made)
	return made


## The one run that writes this of this node: begun from the value whatever
## was writing it had reached, that one stopped - or from here, if nothing was.
func drive(node: Control, what: StringName, from: Variant, to: Variant, easing: StringName, apply: Callable, fades: bool = false, done: Callable = Callable()) -> Run:
	var key: Array = [node.get_instance_id(), what]
	if _driving.has(key):
		var taken_over: Run = _driving[key]
		from = taken_over.value
		taken_over.stopped = true
		_let_go(taken_over)
	var made := run(from, to, easing, apply, fades, done, node)
	# one that lasted no time has arrived already, and drives nothing
	if not made.is_over():
		made.drives = key
		_driving[key] = made
	return made


## A run sent somewhere new: on from the value it has reached, never
## jumping, the time begun again - and begun again if it had arrived.
func retarget(one: Run, to: Variant) -> void:
	one.restart(one.value)
	one.to = to
	_begin(one)


## How long and by what curve it goes, as things stand now - reduced, over
## budget - and on its way; one that lasts no time arrives here and now.
func _begin(one: Run) -> void:
	one.lasts = lasts(one.easing, one.under)
	one.curve = [get_token(StringName(one.easing + "_curve"), one.under), get_token(StringName(one.easing + "_ease"), one.under)]
	if _reduced.read() and one.fades:
		one.lasts = minf(one.lasts, get_token(DURATIONS[0], one.under) / 1000.0)
		one.curve = [Tween.TRANS_LINEAR, Tween.EASE_IN]
	# still, reduced, over budget - or an entrance or exit of many at once, reduced motion aside - it is at its end now
	if still or (_reduced.read() and not one.fades) or (budget != null and budget.is_over()) or (not _reduced.read() and (one.easing == ENTER or one.easing == EXIT) and _in_bulk(one)):
		one.lasts = 0.0
	if not _runs.has(one):
		_runs.append(one)
	if one.lasts == 0.0:
		_advance(one, 0.0)


## Whether this entrance or exit is one of more starting this frame than the
## look lets move; the one passing the count puts the frame's others at rest.
func _in_bulk(one: Run) -> bool:
	if Engine.get_process_frames() != _frame:
		_frame = Engine.get_process_frames()
		_starting.clear()
		_started.clear()
	_starting[one.under] = true
	if _starting.size() <= get_token(BULK, one.under):
		_started.append(one)
		return false
	# every entrance and exit begun this frame before the count was passed, at its end from wherever it waits
	for begun: Run in _started:
		if begun != one and not begun.is_over():
			begun.restart(begun.value)
			begun.lasts = 0.0
			_advance(begun, 0.0)
	_started.clear()
	return true


func _process(delta: float) -> void:
	if not by_hand:
		step(delta)


## Every run moved on by this long, in the order they began; the arrived and the stopped let go.
func step(seconds: float) -> void:
	for one: Run in _runs.duplicate():
		_advance(one, seconds)


func _advance(one: Run, seconds: float) -> void:
	# a run whose node was freed has nothing to hand its value to
	if one.stopped or not one.apply.is_valid():
		_let_go(one)
		return
	one.step(seconds)
	if one.is_over():
		_let_go(one)
		if one.done.is_valid():
			one.done.call()


## A run no longer stepped, and no longer the one writing what it wrote.
func _let_go(one: Run) -> void:
	_runs.erase(one)
	if _driving.get(one.drives) == one:
		_driving.erase(one.drives)


## How many runs are on their way.
func get_running() -> int:
	return _runs.size()
