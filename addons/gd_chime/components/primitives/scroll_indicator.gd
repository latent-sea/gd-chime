extends Node2D

const Motion := preload("../../motion.gd")

## Where the reader is in what scrolls down: a thin mark drawn over it, in
## the right padding of the box it scrolls inside, taking no room.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## It is laid over the control whose box it stands in - a scroll
## (scroll.gd), a text area's words (area.gd) - as a child of it, and reads
## where the reader is from that one's own bar, which the engine keeps and
## never shows: its length is the share shown, its place is how far along
## the reader stands. It shows only while there is more than is shown. IT
## IS NO CONTROL: a scroll lays out every control it holds as what it
## scrolls, and lays out nothing else.
##
## IT STANDS IN THE BOX'S RIGHT PADDING, and nowhere else: never in the room
## outside the box, never adding width, never over the words. The look's
## thickness and inset place it from the box's right edge, and it runs down
## between the box's top and bottom padding; a look whose thickness and
## inset are more than that padding has it over the words.
##
## IT SHOWS WHILE THE READER SCROLLS, THEN FADES, on the one clock
## (motion.gd): lit as the bar moves, whatever moved it, and faded out
## over the look's fades_over once it has rested for its rests_after,
## both in milliseconds; a look setting stays shows it whenever there is
## more than is shown, moving or not. Whoever holds it says when the view
## may have moved (moved()); it then looks at the bar each frame until it
## has faded, and never otherwise.
##
## Its look is the theme type ScrollIndicator, read where the control it
## stands over is: thickness, inset and least_length in base pixels,
## rests_after and fades_over, stays, and the colour it is drawn in.
##
## Deliberately absent: dragging it, and one across.

## The theme type its look is set under.
const TYPE := &"ScrollIndicator"

var _motion: Motion
var _bar: Range  # the engine's own bar: where the reader is, and how much there is
var _boxed: Control  # the control whose box it stands in the padding of, and whose child it is
var _box: StringName  # which of that control's styleboxes is the box
var _seen: float  # where the bar stood when this last looked
var _lit_at: float = -INF  # the clock's time the bar last moved, or never


func _init(motion: Motion, bar: Range, boxed: Control, box: StringName) -> void:
	_motion = motion
	_bar = bar
	_boxed = boxed
	_box = box
	_seen = bar.value


## The view may have moved: the bar is looked at from the next frame on.
func moved() -> void:
	set_process(true)


## How much of it shows, out of one: lit, resting, fading, or gone.
func get_opacity() -> float:
	var extent := _bar.max_value - _bar.min_value
	if extent <= _bar.page:
		return 0.0
	if _boxed.get_theme_constant(&"stays", TYPE) != 0:
		return 1.0
	# how long past resting it is, in seconds: less than nothing while it has yet to rest, and endless if it never moved
	var fading := _motion.time - _lit_at - _boxed.get_theme_constant(&"rests_after", TYPE) / 1000.0
	var fades := _boxed.get_theme_constant(&"fades_over", TYPE) / 1000.0
	if fading < 0.0:
		return 1.0
	return clampf(1.0 - fading / fades, 0.0, 1.0) if fades > 0.0 else 0.0


## Where it is drawn, in its own space: its length the share shown, its
## place how far along the reader stands, never shorter than least_length.
func get_mark() -> Rect2:
	var box := _boxed.get_theme_stylebox(_box)
	var thickness := float(_boxed.get_theme_constant(&"thickness", TYPE))
	var top := box.get_margin(SIDE_TOP)
	var track := _boxed.size.y - top - box.get_margin(SIDE_BOTTOM)
	var extent := _bar.max_value - _bar.min_value
	var length := clampf(track * _bar.page / extent, _boxed.get_theme_constant(&"least_length", TYPE), track)
	# how far along the reader stands, out of one: 0 at the top, 1 at the bottom
	var along := clampf((_bar.value - _bar.min_value) / (extent - _bar.page), 0.0, 1.0)
	return Rect2(_boxed.size.x - _boxed.get_theme_constant(&"inset", TYPE) - thickness, top + along * (track - length), thickness, length)


## The bar looked at: lit again if it has moved, and drawn; no longer
## looked at once it has faded, or at once where it stays.
func _process(_delta: float) -> void:
	if _bar.value != _seen:
		_seen = _bar.value
		_lit_at = _motion.time
	queue_redraw()
	if _boxed.get_theme_constant(&"stays", TYPE) != 0 or _motion.time - _lit_at >= (_boxed.get_theme_constant(&"rests_after", TYPE) + _boxed.get_theme_constant(&"fades_over", TYPE)) / 1000.0:
		set_process(false)


func _notification(what: int) -> void:
	# the engine turns processing on as a script defining _process is ready: this looks at the bar only once told the view moved
	if what == NOTIFICATION_READY:
		set_process(false)


func _draw() -> void:
	var opacity := get_opacity()
	if opacity > 0.0:
		var colour := _boxed.get_theme_color(&"colour", TYPE)
		colour.a *= opacity
		draw_rect(get_mark(), colour)
