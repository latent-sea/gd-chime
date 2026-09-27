extends "controller.gd"

## The frame's budget, measured: whether the game is getting the time it needs.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Two things are measured every frame, on the main thread. The STEP: how long
## the game's own per-frame work took, from the start of the process step to
## its end - which stretches when the cores are taken, because the main thread
## keeps being pushed off them. The PERIOD: how long since the frame before -
## which stretches when frames are dropped, for whatever reason, a throttled
## GPU included.
##
## It is built with the frame target - one frame at the display's rate - and
## the share of it the game's work may take. It is over budget when the step has
## exceeded that share for a run of frames, or the period has run half a frame
## long for a run of frames; it is within again when both have been fine for
## the same run. The run is what keeps one bad frame from flipping it back and
## forth. The target, the share and the run are all handed in: the target is
## read from the display at the platform's edge, the other two are set by
## measurement, and none is defaulted here.
##
## Two bells, one for each crossing: FRAME_OVERRAN when it goes over,
## FRAME_RECOVERED when it comes back; nothing sounds in between. is_over() is for whoever would
## rather ask, and the two measurements are for a readout.
##
## There is one budget and it outlives every screen, so its bells hang in the
## global region rather than in one its builder chooses: whatever listens reaches
## them at an address nobody has to be told, and closing a screen never takes
## them away.
##
## It decides nothing and slows nothing. Whether background work waits is the
## business of whoever asked. And it cannot say WHY a frame is long: a heavy
## screen and a starved thread look alike from here, and both are the player
## not getting their frame.
##
## It measures the step by running FIRST - it holds the lowest process
## priority there is and stamps the start - and reading the end twice: in a
## call deferred to the flush, and again as the rendering server is about to
## draw, after every deferred call the step queued however late - an
## arrival, a text field, the log's flush. The later reading stands, and the
## frame is judged at the next step's start. A build that draws nothing
## (headless, measured on 4.6.2) never reaches the draw, and the flush is its
## end. A node at the same lowest priority that entered the tree before it
## runs ahead of the stamp and goes unmeasured; nothing else does. The draw
## signal is the engine's own, connected here and nowhere else in the folder.

const FRAME_OVERRAN := &"frame_overran"
const FRAME_RECOVERED := &"frame_recovered"

## A period this many targets long is a frame dropped, vsync or not.
const DROPPED := 1.5

var _target_ms: float
var _allowed_ms: float
var _run: int
var _over := false
var _bad := 0  # frames in a row past the budget
var _good := 0  # frames in a row within it
var _step_ms := 0.0
var _period_ms := 0.0
var _start_us := 0


func _init(chimes: Chimes, target_ms: float, share: float, run: int) -> void:
	super(chimes, [], Chimes.GLOBAL)
	_target_ms = target_ms
	_allowed_ms = target_ms * share
	_run = run
	process_priority = -2147483648
	register_bell(FRAME_OVERRAN)
	register_bell(FRAME_RECOVERED)
	RenderingServer.frame_pre_draw.connect(_step_ended)


func is_over() -> bool:
	return _over


## The game's own work last frame, in milliseconds.
func get_step_ms() -> float:
	return _step_ms


## Time from the frame before to this one, in milliseconds.
func get_period_ms() -> float:
	return _period_ms


## First in the step: the frame before judged on its step and period, then
## the period since the last stamp, the stamp, and the end booked for the flush.
func _process(_delta: float) -> void:
	if _start_us != 0:
		_judge()
	var now := Time.get_ticks_usec()
	# the first frame has no frame before it, so it is given a period on target
	_period_ms = (now - _start_us) / 1000.0 if _start_us != 0 else _target_ms
	_start_us = now
	_step_ended.call_deferred()


## The end of the step, read at the flush and again at the draw: the later stands.
func _step_ended() -> void:
	_step_ms = (Time.get_ticks_usec() - _start_us) / 1000.0


## The frame judged: how many bad or good frames in a row, and a strike when
## the answer flips between the two.
func _judge() -> void:
	if _step_ms > _allowed_ms or _period_ms > _target_ms * DROPPED:
		_bad += 1
		_good = 0
	else:
		_good += 1
		_bad = 0
	if not _over and _bad >= _run:
		_over = true
		strike(region, FRAME_OVERRAN)
	elif _over and _good >= _run:
		_over = false
		strike(region, FRAME_RECOVERED)
