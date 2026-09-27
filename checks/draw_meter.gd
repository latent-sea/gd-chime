extends "res://demo/apps/pipes/pipes.gd"

const LongList := preload("res://addons/gd_chime/long_list.gd")

## What a page-a-frame scroll of the pipes costs, headless: the p50 frame, and one draw.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run by speed_meter.py, which is the half that judges. This half only measures
## and says. The pipes stand up as they are - 100,000 rows, their own look - and
## are left sixty frames to come to rest; then a page of rows is scrolled every
## frame for two hundred frames, each frame timed start to start by the wall
## clock, and every presentation's draws counted over them. It prints ONE line,
## METER, holding: the p50 frame in ms; the cost of a draw in us at that frame
## (the p50 frame over the draws a frame); the p50 IDLE frame in ms, two
## hundred frames with nothing asked of the app, timed the same way, before
## the scroll - which is where the app's own easel shows, a viewport of its
## own synced and drawn every frame whether or not anything moved (easel.gd);
## and, for the reader, the draws a frame, the rows a page, and the wires
## the chimes hold. Then it quits.
##
## It judges nothing. The baseline and the 15% are the judging half's, so a
## number is never compared where it is made, and this can be run by hand for
## the numbers alone. Vsync off and no frame cap, so a frame is the work in it
## and not the wait for a display. Headless, so it runs beside the other checks:
## the numbers are not a real window's, but they move with the same code, which
## is all a meter needs.
##
## Chosen against: a real window, which cannot run beside the others; timing
## the dispatch alone, since the draw is where the bookkeeping is paid and it
## happens in the frame, not the command; a watchdog of its own, since the
## judging half times the run out.

const REST := 60
const FRAMES := 200


func _init() -> void:
	super()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	_measure()


## Every presentation in the window's draws, added up.
func _draws() -> int:
	var total := 0
	# every control that counts its draws, its count added
	for part: Node in root.find_children("*", "Control", true, false):
		if "refresh_count" in part:
			total += part.refresh_count
	return total


## How many wires the chimes hold in all, and how many of them are follows: a
## wire under any key but the listened one (chimes.gd LISTENED) is a follow.
func _wires() -> Array[int]:
	var all := 0
	var follows := 0
	# every listener's keys, every key's addresses, counted, and those not the listened key counted apart
	for listener: Variant in chimes._wires._held:
		for key: StringName in chimes._wires._held[listener]:
			var held: int = chimes._wires._held[listener][key].size()
			all += held
			if key != chimes.LISTENED:
				follows += held
	return [all, follows]


func _measure() -> void:
	# the pipes left to come to rest, so the frames timed are the scroll's and not the start's
	for frame: int in REST:
		await process_frame
	var showing: int = models.long.get_showing()
	var idle: Array[float] = []
	var last := Time.get_ticks_usec()
	# nothing asked of the app, each frame timed start to start: the cost of the app merely standing on its easel
	for frame: int in FRAMES:
		await process_frame
		var now := Time.get_ticks_usec()
		idle.append((now - last) / 1000.0)
		last = now
	idle.sort()
	var before := _draws()
	var times: Array[float] = []
	last = Time.get_ticks_usec()
	# a page scrolled every frame, each frame timed start to start by the wall clock
	for frame: int in FRAMES:
		commands.dispatch(PIPES, LongList.SCROLL_ROWS, {"by": showing})
		await process_frame
		var now := Time.get_ticks_usec()
		times.append((now - last) / 1000.0)
		last = now
	var draws_a_frame := float(_draws() - before) / FRAMES
	times.sort()
	var p50: float = times[FRAMES / 2]
	var wires := _wires()
	print("METER page_ms_p50=%.2f draw_us=%.1f idle_ms_p50=%.3f draws_a_frame=%.0f rows_a_page=%d wires=%d follows=%d" % [p50, p50 * 1000.0 / draws_a_frame, idle[FRAMES / 2], draws_a_frame, showing, wires[0], wires[1]])
	quit(0)
