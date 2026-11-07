extends RefCounted

## A press answered before it is done: EVERY PRESS SHOWS FIRST - its face held
## down, a frame drawn, then its work - so the player sees it landed whatever
## the work costs (Ian, 2026-11-06: "pressing buttons and having no indication
## anything has happened"); and, WHERE THE PLAYER HAS TURNED IT ON (dims; off
## by default, Ian 2026-11-07: "put the dimming in settings - default it to
## off"), every press dims the screen as it lands, the dim lifted once its work
## is done and drawn (Ian: "start the dimming on press and then turn it off on
## completion" - learning which presses were slow first "is not workable").
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE FACE HELD DOWN (interaction.gd's held_down, face_give.gd) is drawn in the
## frame before the work starts, so a slow press freezes the screen on its own
## button pressed, and it stays down HELD at the least, so a quick tap is seen:
## a finger's tap otherwise lets go in the very event it lands in, and nothing
## pressed is ever drawn.
##
## THE DIM is drawn in that same frame before the work, since work blocks the
## frame and nothing can be drawn while it runs; the work done, the dim is
## lifted once what it made has been drawn - a quick press dims for a frame or
## two, a slow one for as long as it takes. While it shows it takes every
## pointer and finger that lands, so a press made while waiting reaches nothing
## (Ian, 2026-11-06: "the user needs to know to not press anything else"); and
## it lifts after LONGEST whatever happened.
##
## Only a hand's press goes through this (interaction.gd): a press made by a
## script - a test's, a walk's - is done at once. IT IS OFF UNTIL AN
## APPLICATION TURNS IT ON (enabled), so a suite clicking through its screens
## is never held up.
##
## Deliberately absent: a marker of progress on the dim for a long wait.

## The least time a dim shows, in seconds: none, it lifts on completion (Ian, 2026-11-07).
const SHOWN := 0.0
## The least time a pressed face stays down, in seconds, so a tap is seen.
const HELD := 0.15
## How strong the dim is: the theme's shade (theme_overlays.gd, its Shade) at this share of its own strength.
const DIM_SHARE := 0.6
## The canvas layer the dim is drawn on: over everything a screen draws.
const LAYER := 120
## The longest a dim may stand, in seconds: past it, it is lifted whatever happened, so no dim ever holds the screen.
const LONGEST := 3.0
const ThemeOverlays := preload("theme_overlays.gd")

## Whether a hand's press shows first: off until an application turns it on.
static var enabled := false
## Whether every press also dims the screen until it is done: the player's setting, off until they turn it on.
static var dims := false
static var _dim: ColorRect = null
static var _shown_at := 0  # when the dim was last shown, on the clock


## The press of `control` done by `does`: at once where this is off; else its face shown down first - and the screen
## dimmed, where the player dims - then the work, the dim lifted on completion.
static func press(control: Control, does: Callable) -> void:
	if not enabled:
		does.call()
		return
	if dims:
		_dimmed(control, does)
		return
	_shown_first(control, does)


## The face down, drawn, the work done, the face up again once HELD has passed.
static func _shown_first(control: Control, does: Callable) -> void:
	var tree := control.get_tree()
	var down_at := Time.get_ticks_usec()
	# deferred: a finger's lift lets the face up in the same event that pressed it, after this
	(func() -> void: _hold(control, true)).call_deferred()
	await tree.process_frame
	if is_instance_valid(control) and control.is_inside_tree():
		does.call()
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


## The dim shown and drawn, the press done, and the dim lifted once what it made is drawn and SHOWN has passed.
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
	# the face stays down HELD at the least, so a tap is seen whatever the dim did
	while (Time.get_ticks_usec() - shown_at) / 1e6 < HELD:
		await tree.process_frame
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
