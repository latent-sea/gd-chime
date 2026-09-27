extends RefCounted

## A carry near a scroll's edge drags it that way (scroll.gd), so a reader
## can reach a target that is out of sight without letting go.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The engine tells every control when a drag begins and ends, so nothing is
## connected and nothing here knows what is being carried: while a drag is
## on, and only then, the scroll looks at where the pointer is within its
## own window each frame, and this moves it toward whichever edge the
## pointer is within the look's band of, at the look's speed. Both are the
## look's constants under Scroll, read with a plain fallback so a Theme that
## names neither still scrolls.

## The type the look holds the carry's band and speed under.
const EDGE := &"Scroll"
## How wide the band is, and how fast it drags, until a look says otherwise.
const BAND := 64.0
const SPEED := 900.0


## A point within this scroll's window, looked at for this long: the window
## moves toward whichever edge the point is within the look's band of, as
## far as the look's speed takes it. Nothing moves while nothing is being
## carried, and nothing moves for a point outside the window at all.
static func toward(scroll: ScrollContainer, carrying: bool, at: Vector2, seconds: float) -> void:
	if not carrying or not Rect2(Vector2.ZERO, scroll.size).has_point(at):
		return
	var band: float = scroll.get_theme_constant(&"drag_edge", EDGE) if scroll.has_theme_constant(&"drag_edge", EDGE) else BAND
	var speed: float = scroll.get_theme_constant(&"drag_edge_speed", EDGE) if scroll.has_theme_constant(&"drag_edge_speed", EDGE) else SPEED
	var step := roundi(speed * seconds)
	if at.y < band:
		scroll.scroll_vertical -= step
	elif at.y > scroll.size.y - band:
		scroll.scroll_vertical += step
	if at.x < band:
		scroll.scroll_horizontal -= step
	elif at.x > scroll.size.x - band:
		scroll.scroll_horizontal += step
