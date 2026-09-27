extends "res://addons/gd_chime/application.gd"

const Dial := preload("res://demo/clock/dial.gd")
const DemoTheme := preload("res://demo/demo_theme.gd")

## A clock, showing what it costs to watch one.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --path <this folder> --script res://demo/clock/clock.gd
##
## The time is a value read every frame (ui.every_frame), and four faces
## read it. Every face re-reads every frame; the number each shows changes
## at its own pace, and the engine draws only what changed. Drag the window
## and they resize themselves. There is no model and no bell: the standard
## wiring is application.gd's, and this file answers its questions.

const REGION := &"clock"
const UNITS := [Dial.Unit.HOUR, Dial.Unit.MINUTE, Dial.Unit.SECOND, Dial.Unit.MILLISECOND]


func look() -> Theme:
	return DemoTheme.new()


func describe() -> Desc:
	var time := ui.every_frame(Dial.now)
	var dials: Array = []
	# the same recipe four times, handed the same time and a different unit each
	for unit: Dial.Unit in UNITS:
		dials.append(Dial.make(ui, time, unit).grow())
	return ui.app(REGION, [ui.row(dials)])
