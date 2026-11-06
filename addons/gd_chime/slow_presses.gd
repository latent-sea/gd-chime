extends RefCounted

## A press that takes a while answered before it is done: the screen dimmed
## first, the press then done, and the dim lifted when it is.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A PRESS IS TIMED from its landing to the frame after it, which is where
## what it built is laid out and drawn. An action whose last press took longer
## than SLOW is SLOW from then on, for the run: the next press of it dims the
## screen at once, and its work starts only once the dim has been drawn - work
## done in the frame it lands in would hold back the dim, and anything else
## drawn, until it ends. The dim then stays until the frame after the work, and
## for at least SHOWN, so it never flashes; it takes every pointer and finger
## that lands while it shows, so a press made while waiting reaches nothing
## (Ian, 2026-11-06: "the user needs to know to not press anything else"). A
## press of an action not yet slow is done at once, as it always was.
##
## Only a hand's press goes through this (interaction.gd): a press made by a
## script - a test's, a walk's - is done at once and is never timed. IT IS
## OFF UNTIL AN APPLICATION TURNS IT ON (enabled), so a suite clicking
## through its screens is never held up by a dim.
##
## Deliberately absent: a marker of progress on the dim for a long wait, and
## keeping what is slow from one run to the next.

## Longer than this, in seconds, and an action is slow from then on.
const SLOW := 0.2
## The least time a dim shows, in seconds, so it never flashes.
const SHOWN := 0.4
## How strong the dim is: the theme's shade (theme_overlays.gd, its Shade) at this share of its own strength.
const DIM_SHARE := 0.6
## The canvas layer the dim is drawn on: over everything a screen draws.
const LAYER := 120
const ThemeOverlays := preload("theme_overlays.gd")

## Whether a hand's press is timed and a slow one dimmed: off until an application turns it on.
static var enabled := false
static var _slow: Dictionary = {}  # each action found slow, by "region/action"
static var _dim: ColorRect = null


## The press of `control` done by `does`: at once and timed, or, for an action found slow, after the screen is dimmed.
static func press(control: Control, does: Callable) -> void:
	var action: Variant = control.get(&"action")
	var key := "" if not enabled or action == null or action == &"" else "%s/%s" % [control.get(&"region"), action]
	if key != "" and _slow.has(key):
		_dimmed(control, does)
		return
	var began := Time.get_ticks_usec()
	does.call()
	if key != "":
		_timed(control.get_tree(), key, began)


## How long a press took, to the frame after it, noted as slow where it was.
static func _timed(tree: SceneTree, key: String, began: int) -> void:
	await tree.process_frame
	if (Time.get_ticks_usec() - began) / 1e6 > SLOW:
		_slow[key] = true


## The dim shown and drawn, the press done, and the dim lifted after the frame that follows it and SHOWN at the least.
static func _dimmed(control: Control, does: Callable) -> void:
	var tree := control.get_tree()
	var shown_at := Time.get_ticks_usec()
	_show(control, true)
	# two frames: the dim drawn before the work begins
	await tree.process_frame
	await tree.process_frame
	if is_instance_valid(control) and control.is_inside_tree():
		does.call()
	await tree.process_frame
	# each frame until SHOWN has passed on the clock: a timer counts frames' time, and the frame the work held up counts it all at once
	while (Time.get_ticks_usec() - shown_at) / 1e6 < SHOWN:
		await tree.process_frame
	_show(control, false)


## The dim over the whole window, made the first time it is asked for, in the shade of the theme `control` is drawn
## in, shown or hidden.
static func _show(control: Control, shown: bool) -> void:
	if _dim == null or not is_instance_valid(_dim):
		if not is_instance_valid(control) or not control.is_inside_tree():
			return
		var tree := control.get_tree()
		var layer := CanvasLayer.new()
		layer.layer = LAYER
		_dim = ColorRect.new()
		var shade: StyleBox = control.get_theme_stylebox(&"panel", ThemeOverlays.SHADE)
		_dim.color = shade.bg_color if shade is StyleBoxFlat else Color.BLACK
		_dim.color.a *= DIM_SHARE
		_dim.mouse_filter = Control.MOUSE_FILTER_STOP
		_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
		layer.add_child(_dim)
		tree.root.add_child(layer)
	_dim.visible = shown
