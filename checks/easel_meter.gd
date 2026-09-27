extends "res://demo/apps/dashboard/dashboard.gd"

## What the easel's own viewport costs the engine to render in a real window
## at 1080p, against what the window's costs: the engine's own render times.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run by speed_meter.py with --window, which is the half that judges, once
## a record, in a real window of 1920x1080 on a screen someone is at: headless
## there is no rendering, and the easel - a viewport of its own, synced and
## drawn every frame (easel.gd) - costs nothing that can be seen. The
## dashboard stands up as it is, in its own look, and is left REST frames to
## come to rest; then, for FRAMES frames, the engine's measured render time
## of the easel's viewport and of the window's, CPU and GPU, is read each
## frame. It prints ONE line, METER, holding the four p50s in ms, the
## window's size, and whether it rendered at all (rendered=0 headless), so
## the judging half can refuse a run that measured nothing real. Then it
## quits. It writes nothing.
##
## IT QUITS ITSELF ON EVERY PATH, since it holds someone's screen: the
## measure's end quits it; a frame cap quits it, failing, if the frames run
## on past the measure's; and a watchdog on a thread of its own ends the
## process, failing, after WATCHDOG_MS of the wall clock, even with the main
## thread stuck, where no frame would come to count.
##
## It judges nothing, as draw_meter.gd judges nothing. The display's own
## vsync stays as the project has it: the render times are the engine's work
## and not the wait for the display, and in a window at the display's pace
## the rest and the frame cap are seconds, not a blur of frames.
##
## Chosen against: the frame time by the wall clock, which in a window is
## the display's pace, not the easel's cost; the pipes, whose scrolling moves
## every frame, where the dashboard standing is the cost an app pays merely
## being on screen.

const REST := 180
const FRAMES := 120
## Frames past the measure's own after which the run is taken to have lost its way.
const FRAME_CAP := REST + FRAMES + 300
## The wall clock the whole run may take once started, in ms, before the watchdog ends it.
const WATCHDOG_MS := 90000

var _frames: int = 0
var _watchdog := Thread.new()
var _lock := Mutex.new()
var _finished: bool = false  # set once the run is ending, so the watchdog stands down


func _init() -> void:
	super()
	_watchdog.start(_watch)
	_measure()


## The watchdog: the wall clock watched in short sleeps until the run ends,
## or the process ended by its own id when the time is up.
func _watch() -> void:
	var until := Time.get_ticks_msec() + WATCHDOG_MS
	# every tenth of a second until the time is up, for the run having ended
	while Time.get_ticks_msec() < until:
		_lock.lock()
		var finished := _finished
		_lock.unlock()
		if finished:
			return
		OS.delay_msec(100)
	printerr("METER FAILED: the watchdog ended the run after %d ms" % WATCHDOG_MS)
	OS.kill(OS.get_process_id())


## Every frame counted; past the cap, the run ends failing.
func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == FRAME_CAP:
		printerr("METER FAILED: %d frames ran without the measure ending" % FRAME_CAP)
		_finish(1)
	return false


## The watchdog stood down, then the run ended with the code given.
func _finish(code: int) -> void:
	_lock.lock()
	_finished = true
	_lock.unlock()
	quit(code)


func _finalize() -> void:
	_watchdog.wait_to_finish()


func _measure() -> void:
	var easel: RID = app.viewport.get_viewport_rid()
	var window: RID = root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(easel, true)
	RenderingServer.viewport_set_measure_render_time(window, true)
	# the dashboard left to come to rest, so the frames read are it standing and not it starting
	for frame: int in REST:
		await process_frame
	var times: Array = [[], [], [], []]
	# each frame, the engine's render time of the easel's viewport and the window's, CPU and GPU
	for frame: int in FRAMES:
		await process_frame
		times[0].append(RenderingServer.viewport_get_measured_render_time_cpu(easel))
		times[1].append(RenderingServer.viewport_get_measured_render_time_gpu(easel))
		times[2].append(RenderingServer.viewport_get_measured_render_time_cpu(window))
		times[3].append(RenderingServer.viewport_get_measured_render_time_gpu(window))
	# each of the four sorted, so its middle is its p50
	for measured: Array in times:
		measured.sort()
	var rendered := int(DisplayServer.get_name() != "headless")
	print("METER easel_cpu_ms_p50=%.3f easel_gpu_ms_p50=%.3f window_cpu_ms_p50=%.3f window_gpu_ms_p50=%.3f window_width=%d window_height=%d rendered=%d" % [times[0][FRAMES / 2], times[1][FRAMES / 2], times[2][FRAMES / 2], times[3][FRAMES / 2], root.size.x, root.size.y, rendered])
	_finish(0)
