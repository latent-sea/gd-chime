extends Node2D

const Motion := preload("../../motion.gd")
const Shape := preload("../../shape.gd")
const Touch := preload("../../touch.gd")

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
## WHILE IT SHOWS IT CAN BE TAKEN HOLD OF, by a finger or the mouse, and
## drawn: the view goes where along its track the pointer is, the top the
## start and the bottom the end, and it stays lit while held. What takes
## the pointer is a GRIP of its own, a control as tall as the track, from
## the box's right edge in as far as the mark stands - and on a phone's
## window at least the look's least touch size (Touch/least), over the
## words' edge though the mark is drawn thin. The grip holds the finger
## (touch.gd), so a finger on it pans nothing under it; faded, it takes
## nothing, and whatever is under it is pressed as ever. Taken, it makes
## the call it was handed, so whoever holds it stops anything else moving
## the view.
##
## Its look is the theme type ScrollIndicator, read where the control it
## stands over is: thickness, inset and least_length in base pixels,
## rests_after and fades_over, stays, and the colour it is drawn in.
##
## Deliberately absent: one across.

## The theme type its look is set under.
const TYPE := &"ScrollIndicator"

var _motion: Motion
var _bar: Range  # the engine's own bar: where the reader is, and how much there is
var _boxed: Control  # the control whose box it stands in the padding of, and whose child it is
var _box: StringName  # which of that control's styleboxes is the box
var _when_taken: Callable  # what holds it, told its mark was taken hold of
var _seen: float  # where the bar stood when this last looked
var _lit_at: float = -INF  # the clock's time the bar last moved, or never
var _grip := Control.new()  # what takes the pointer, over the mark's track
var _held: bool = false  # whether the grip is held


func _init(motion: Motion, bar: Range, boxed: Control, box: StringName, when_taken: Callable) -> void:
	_motion = motion
	_bar = bar
	_boxed = boxed
	_box = box
	_when_taken = when_taken
	_seen = bar.value
	_grip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grip.add_to_group(Touch.HOLDS)
	_grip.gui_input.connect(_taken)
	add_child(_grip)


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


## Where the mark runs, in its own space: from the box's top padding down to its bottom padding.
func _track() -> Rect2:
	var box := _boxed.get_theme_stylebox(_box)
	var top := box.get_margin(SIDE_TOP)
	return Rect2(0.0, top, _boxed.size.x, _boxed.size.y - top - box.get_margin(SIDE_BOTTOM))


## Where it is drawn, in its own space: its length the share shown, its
## place how far along the reader stands, never shorter than least_length.
func get_mark() -> Rect2:
	var track := _track()
	var thickness := float(_boxed.get_theme_constant(&"thickness", TYPE))
	var extent := _bar.max_value - _bar.min_value
	var length := clampf(track.size.y * _bar.page / extent, _boxed.get_theme_constant(&"least_length", TYPE), track.size.y)
	# how far along the reader stands, out of one: 0 at the top, 1 at the bottom
	var along := clampf((_bar.value - _bar.min_value) / (extent - _bar.page), 0.0, 1.0)
	return Rect2(_boxed.size.x - _boxed.get_theme_constant(&"inset", TYPE) - thickness, track.position.y + along * (track.size.y - length), thickness, length)


## Where it can be taken hold of, in its own space: down the whole track,
## from the box's right edge in as far as the mark stands, and on a phone's
## window at least the look's least touch size.
func get_grip() -> Rect2:
	var track := _track()
	var wide := float(_boxed.get_theme_constant(&"thickness", TYPE) + _boxed.get_theme_constant(&"inset", TYPE))
	if get_viewport().get_meta(Shape.PHONE, false):
		wide = maxf(wide, _boxed.get_theme_constant(&"least", Touch.TYPE))
	return Rect2(_boxed.size.x - wide, track.position.y, wide, track.size.y)


## The bar looked at: lit again if it has moved, or while it is held, and
## drawn, the grip placed over it and taking the pointer only while it
## shows; no longer looked at once it has faded, or at once where it stays.
func _process(_delta: float) -> void:
	if _bar.value != _seen or _held:
		_seen = _bar.value
		_lit_at = _motion.time
	queue_redraw()
	var grip := get_grip()
	_grip.position = grip.position
	_grip.size = grip.size
	_grip.mouse_filter = Control.MOUSE_FILTER_STOP if get_opacity() > 0.0 else Control.MOUSE_FILTER_IGNORE
	if _boxed.get_theme_constant(&"stays", TYPE) != 0 or _motion.time - _lit_at >= (_boxed.get_theme_constant(&"rests_after", TYPE) + _boxed.get_theme_constant(&"fades_over", TYPE)) / 1000.0:
		set_process(false)


## The pointer on the grip: pressed, it is held and says so; pressed or
## drawn while held, the view goes where along the track it is.
func _taken(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.button_index == MOUSE_BUTTON_LEFT:
		_held = click.pressed
		if _held:
			_when_taken.call()
	if _held and event is InputEventMouse:
		# how far down the track the pointer is, out of one: 0 at its top, 1 at its bottom
		var along := clampf((event as InputEventMouse).position.y / _grip.size.y, 0.0, 1.0)
		_bar.value = _bar.min_value + along * (_bar.max_value - _bar.page - _bar.min_value)
		moved()
	_grip.accept_event()


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
