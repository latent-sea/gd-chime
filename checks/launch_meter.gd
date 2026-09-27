extends "res://demo/apps/workspace/workspace.gd"

## Engine start to the workspace's first frame, headless, and the app's own build.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run by speed_meter.py, which is the half that judges. This half only
## measures and says: the workspace stands up as it is, and on its first frame
## it prints ONE line, METER, holding the engine's clock at that frame in ms -
## everything from the process starting to the first frame, the engine's own
## start and every script compiled included - and, for the reader, the app's
## own build in ms (its _init: look, models, description, the tree). Then it
## quits. It writes nothing.
##
## The workspace is the app measured because it is the one every part of the
## floor stands under: the facade, panels, documents, the palette, a table, a
## settings file. What loads before its first frame is what loads for the
## framework, so a script that starts compiling at launch shows here first.
##
## Chosen against: the app's own build alone, which is a tenth of the launch
## and misses the compile that round 2 found; a real window, which cannot run
## beside the other checks; a watchdog, since the judging half times it out.

var _built_ms: float


func _init() -> void:
	var began := Time.get_ticks_usec()
	super()
	_built_ms = (Time.get_ticks_usec() - began) / 1000.0
	_measure()


func _measure() -> void:
	await process_frame
	print("METER launch_ms=%d build_ms=%.0f" % [Time.get_ticks_msec(), _built_ms])
	quit(0)
