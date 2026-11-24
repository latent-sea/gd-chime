extends Node2D

const Motion := preload("../../motion.gd")
const Shape := preload("../../shape.gd")
const Touch := preload("../../touch.gd")
const Pressable := preload("pressable.gd")

## Where the reader is in what scrolls down: a thin mark drawn over it, in
## the right padding of the box it scrolls inside, taking no room; by the
## look's track and track_edge colours, along a track the length of the box,
## the mark drawn on it (none by default: both clear).
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
## drawn. TAKEN, THE MARK STAYS UNDER THE POINTER WHERE IT WAS TAKEN: the
## view does not move as it is taken, and drawn, the mark goes as far as the
## pointer does, so the top of its track is the start and the bottom the
## end. What takes the pointer is a GRIP of its own. Under a mouse it is the
## whole track, from the box's right edge in as far as the mark stands, and
## a press on the track off the mark brings the mark's middle to the
## pointer. On a touched window it is THE MARK ALONE, grown to the look's
## least touch size each way (Touch/least_um, as a press is: pressable.gd),
## over the words' edge though the mark is thin: a finger landing beside
## the mark pans the list or presses what is under it, as anywhere else,
## and never throws the view to where along the track it landed. The grip
## holds the finger (touch.gd), so a finger on it pans nothing under it;
## faded, it takes nothing, and whatever is under it is pressed as ever.
## Taken, it makes the call it was handed, so whoever holds it stops
## anything else moving the view.
##
## Its look is the theme type ScrollIndicator, read where the control it
## stands over is: thickness, inset and least_length in base pixels,
## rests_after and fades_over, stays, and the colour it is drawn in. With
## arrows 1, an ARROW AT EACH END of the track, a square a mark thick in the
## track's colours with a triangle in arrow_colour: pressed, it moves the
## view step base pixels that way, and the mark runs between them.
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
var _held_at: float = 0.0  # how far down the mark the pointer took it, in base pixels
var _up := Control.new()  # what takes the pointer over the arrow back up
var _down := Control.new()  # and over the arrow on down


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
	_up.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_down.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_up.gui_input.connect(_stepped.bind(-1, _up))
	_down.gui_input.connect(_stepped.bind(1, _down))
	add_child(_up)
	add_child(_down)


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
	var end := float(_boxed.get_theme_constant(&"thickness", TYPE)) if _boxed.get_theme_constant(&"arrows", TYPE) != 0 else 0.0
	var top := box.get_margin(SIDE_TOP) + end
	return Rect2(0.0, top, _boxed.size.x, _boxed.size.y - top - box.get_margin(SIDE_BOTTOM) - end)


## Each arrow's square, up then down, in its own space, a mark thick at either end of the track; none without arrows.
func get_ends() -> Array[Rect2]:
	var thick := float(_boxed.get_theme_constant(&"thickness", TYPE))
	if _boxed.get_theme_constant(&"arrows", TYPE) == 0:
		return []
	var track := _track()
	var x := _boxed.size.x - _boxed.get_theme_constant(&"inset", TYPE) - thick
	return [Rect2(x, track.position.y - thick, thick, thick), Rect2(x, track.end.y, thick, thick)]


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


## Where it can be taken hold of, in its own space: under a mouse the whole
## track, from the box's right edge in as far as the mark stands; on a
## touched window the mark alone, grown to the look's least touch size each
## way about its middle and kept inside the box.
func get_grip() -> Rect2:
	var track := _track()
	var wide := float(_boxed.get_theme_constant(&"thickness", TYPE) + _boxed.get_theme_constant(&"inset", TYPE))
	if not get_viewport().get_meta(Shape.TOUCH, false):
		return Rect2(_boxed.size.x - wide, track.position.y, wide, track.size.y)
	var least := Pressable.least_each_way(_boxed)
	var mark := get_mark()
	var long := maxf(mark.size.y, least)
	wide = maxf(wide, least)
	return Rect2(_boxed.size.x - wide, clampf(mark.get_center().y - long / 2.0, 0.0, maxf(_boxed.size.y - long, 0.0)), wide, long)


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
	var ends := get_ends()
	# each arrow's press over its square, taking the pointer only while it shows
	for at: int in ends.size():
		var end: Control = [_up, _down][at]
		end.position = ends[at].position
		end.size = ends[at].size
		end.mouse_filter = _grip.mouse_filter
	if _boxed.get_theme_constant(&"stays", TYPE) != 0 or _motion.time - _lit_at >= (_boxed.get_theme_constant(&"rests_after", TYPE) + _boxed.get_theme_constant(&"fades_over", TYPE)) / 1000.0:
		set_process(false)


## An arrow pressed: the view moved a step of the look's `way`, up (-1) or down (1).
func _stepped(event: InputEvent, way: int, end: Control) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.button_index == MOUSE_BUTTON_LEFT and click.pressed:
		_bar.value += way * _boxed.get_theme_constant(&"step", TYPE)
		_when_taken.call()
		moved()
	end.accept_event()


## The pointer on the grip: pressed, it is held and says so, where down the
## mark it was taken kept - its middle, for a press on the track off the
## mark; drawn while held, the mark goes with the pointer and the view with
## the mark.
func _taken(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	var mark := get_mark()
	if click != null and click.button_index == MOUSE_BUTTON_LEFT:
		_held = click.pressed
		if _held:
			# the pointer in this one's own space, as the mark is
			var down := _grip.position.y + click.position.y
			_held_at = down - mark.position.y if down >= mark.position.y and down <= mark.end.y else mark.size.y / 2.0
			_when_taken.call()
	var track := _track()
	if _held and event is InputEventMouse and track.size.y > mark.size.y:
		# how far down its track the mark's top is under the pointer, out of one: 0 at the start, 1 at the end
		var along := clampf((_grip.position.y + (event as InputEventMouse).position.y - _held_at - track.position.y) / (track.size.y - mark.size.y), 0.0, 1.0)
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
		var mark := get_mark()
		var track := Rect2(mark.position.x, _track().position.y, mark.size.x, _track().size.y)
		var ground := _boxed.get_theme_color(&"track", TYPE)
		var edge := _boxed.get_theme_color(&"track_edge", TYPE)
		colour.a *= opacity
		ground.a *= opacity
		edge.a *= opacity
		draw_rect(track, ground)
		draw_rect(track, edge, false, 1.0)
		draw_rect(mark, colour)
		var arrow := _boxed.get_theme_color(&"arrow_colour", TYPE)
		arrow.a *= opacity
		var ends := get_ends()
		# each arrow: its square in the track's colours, its triangle pointing away from the track
		for at: int in ends.size():
			var square: Rect2 = ends[at]
			var tip := 0.2 if at == 0 else 0.8
			draw_rect(square, ground)
			draw_rect(square, edge, false, 1.0)
			draw_colored_polygon(PackedVector2Array([Vector2(0.5, tip), Vector2(0.15, 1.0 - tip), Vector2(0.85, 1.0 - tip)].map(func(at_share: Vector2) -> Vector2: return square.position + at_share * square.size)), arrow)
