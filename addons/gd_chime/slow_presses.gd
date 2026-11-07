extends RefCounted

## A press answered before it is done: EVERY PRESS SHOWS FIRST - its face held
## down, a frame drawn, then its work - so the player sees it landed whatever
## the work costs (Ian, 2026-11-06: "pressing buttons and having no indication
## anything has happened"); one that takes a while has the screen dimmed too.
##
## THE FACE HELD DOWN (interaction.gd's held_down, face_give.gd) is drawn in the
## frame before the work starts, so a slow press freezes the screen on its own
## button pressed, and it stays down HELD at the least, so a quick tap is seen:
## a finger's tap otherwise lets go in the very event it lands in, and nothing
## pressed is ever drawn.
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
## press of an action not yet slow is not dimmed: it shows by its face alone.
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
## The least time a pressed face stays down, in seconds, so a tap is seen.
const HELD := 0.15
## How strong the dim is: the theme's shade (theme_overlays.gd, its Shade) at this share of its own strength.
const DIM_SHARE := 0.6
## The canvas layer the dim is drawn on: over everything a screen draws.
const LAYER := 120
## The longest a dim may stand, in seconds: past it, it is lifted whatever happened, so no dim ever holds the screen.
const LONGEST := 3.0
const ThemeOverlays := preload("theme_overlays.gd")

## Whether a hand's press is timed and a slow one dimmed: off until an application turns it on.
static var enabled := false
static var _slow: Dictionary = {}  # each action found slow, by "region/action"
static var _dim: ColorRect = null
static var _shown_at := 0  # when the dim was last shown, on the clock


## The press of `control` done by `does`: at once where this is off; else its face shown down first, then the work, timed,
## and for an action found slow the screen dimmed first too.
static func press(control: Control, does: Callable) -> void:
	if not enabled:
		does.call()
		return
	var action: Variant = control.get(&"action")
	var key := "" if action == null or action == &"" else "%s/%s" % [control.get(&"region"), action]
	if key != "" and _slow.has(key):
		_dimmed(control, does)
		return
	_shown_first(control, does, key)


## The face down, drawn, the work done and timed, the face up again once HELD has passed.
static func _shown_first(control: Control, does: Callable, key: String) -> void:
	var tree := control.get_tree()
	var down_at := Time.get_ticks_usec()
	# deferred: a finger's lift lets the face up in the same event that pressed it, after this
	(func() -> void: _hold(control, true)).call_deferred()
	await tree.process_frame
	var began := Time.get_ticks_usec()
	if is_instance_valid(control) and control.is_inside_tree():
		does.call()
	if key != "":
		_timed(tree, key, began)
	# each frame until the face has been down HELD on the clock
	while (Time.get_ticks_usec() - down_at) / 1e6 < HELD:
		await tree.process_frame
	_hold(control, false)


## `control`'s face held down or let up, where it is still there to show it: down AT ONCE, at the look's press scale,
## so the frame drawn before the work shows it - a motion run would step only in the next frame, after the work began.
static func _hold(control: Control, down: bool) -> void:
	if not is_instance_valid(control) or not control.is_inside_tree() or not control.has_method(&"held_down"):
		return
	if not down:
		control.held_down(false)
		return
	# set at once, and held there by a run from it to itself, which takes over from any run on the face's scale - the
	# finger's lift starts one back to whole - so nothing undoes it before it is drawn
	var pressed := Vector2.ONE * control.get_theme_constant(&"press_scale", &"Motion") / 1000.0
	control.pivot_offset_ratio = Vector2(0.5, 0.5)
	control.scale = pressed
	var motion: Variant = control.get(&"motion")
	if motion != null:
		motion.drive(control, &"scale", pressed, pressed, &"restyle", control.set_scale)


## How long a press took, through the frame after it - where what it opened is laid out and drawn, the slow part of a
## press that opens a screen - to the start of the next, noted as slow where it was (Ian, 2026-11-06: no dim was ever
## seen, since timing to that frame's start missed all of it).
static func _timed(tree: SceneTree, key: String, began: int) -> void:
	await tree.process_frame
	await tree.process_frame
	if (Time.get_ticks_usec() - began) / 1e6 > SLOW:
		_slow[key] = true


## The dim shown and drawn, the press done, and the dim lifted after the frame that follows it and SHOWN at the least.
static func _dimmed(control: Control, does: Callable) -> void:
	var tree := control.get_tree()
	var shown_at := Time.get_ticks_usec()
	_show(control, true)
	(func() -> void: _hold(control, true)).call_deferred()
	# a frame: the dim drawn before the work begins - one, not two, so a press is never lost to its button made again
	# meanwhile (Ian, 2026-11-06: presses ignored on a tablet)
	await tree.process_frame
	if is_instance_valid(control) and control.is_inside_tree():
		does.call()
	await tree.process_frame
	# each frame until SHOWN has passed on the clock: a timer counts frames' time, and the frame the work held up counts it all at once
	while (Time.get_ticks_usec() - shown_at) / 1e6 < SHOWN:
		await tree.process_frame
	_show(control, false)
	_hold(control, false)


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
	if shown:
		_shown_at = Time.get_ticks_usec()
		_lift_late(_dim.get_tree(), _shown_at)


## The dim lifted LONGEST after it was shown, unless it has been lifted, or shown again, since.
static func _lift_late(tree: SceneTree, shown_at: int) -> void:
	await tree.create_timer(LONGEST, true, false, true).timeout
	if _shown_at == shown_at and _dim != null and is_instance_valid(_dim) and _dim.visible:
		_dim.visible = false
