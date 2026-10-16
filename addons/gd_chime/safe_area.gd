extends RefCounted

## The safe room: how far in from each edge of an app's rect nothing but the
## ground may be drawn - what the system covers, the arc of a rounded corner,
## the keyboard at the foot, and a gutter - and the scale its canvas is drawn
## at, so that the room is never under the look's floor. Every answer by edge
## is indexed by the engine's Side: SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## IT NEVER READS THE WINDOW OR THE SCREEN AND KEEPS NO STATE. The easel
## (easel.gd) hands it every number, in the screen's pixels, so each answer is
## a sum a test can work out by hand.
##
## EACH EDGE IS COVERED BY THE LARGEST OF THREE, never their sum, since all
## three lie along the same edge: what of the rect is outside the system's
## unobscured area (a cutout, a notch, a home bar); 0.293 of a rounded
## corner's radius in from the window's edge, which clears the arc at its
## 45-degree point; and, at the foot alone, the keyboard, which rises from the
## window's foot. Each is measured against the app's own rect, so an app
## against the cutout loses the cutout, and one in a panel away from it
## loses nothing.
##
## THE GUTTER IS ADDED ON TOP, on all four sides, in base pixels: the margin
## the look names, so nothing stands against the edge of what is covered.
##
## THE FLOOR CAPS THE SCALE. Fitted, and held at the look's least pixel, a
## canvas could leave a safe short side under the floor - a split screen, a
## phone at its largest display size, a small desk window - so the scale is
## lowered until that side is exactly the floor: the type is drawn smaller
## before any screen is given less room than it was designed at.
##
## Deliberately absent: the keyboard, from the cap. With it, a field taking
## the focus would redraw the whole app smaller as the keyboard rose; without
## it, the safe height may fall under the floor while the keyboard is up.

## The share of a rounded corner's radius that clears its arc at the 45-degree point: 1 - 1/sqrt(2).
const CORNER_CLEARANCE := 0.293


## The pixels covered at each edge of the rect. All in the screen's pixels:
## the window the rect stands in; the rect; the system's unobscured area,
## where an empty one - the platform naming none - covers nothing; the
## keyboard's height up from the window's foot; and a rounded corner's
## radius, in thousandths of a millimetre on a screen of this many dots to
## the inch.
static func covered(window: Rect2, rect: Rect2, unobscured: Rect2, keyboard_px: float, corner_um: float, dpi: float) -> PackedFloat32Array:
	var shown: Rect2 = unobscured if unobscured.has_area() else window
	# the corner's clearance in pixels: 25,400 thousandths of a millimetre to the inch
	var corner: float = CORNER_CLEARANCE * corner_um / 25400.0 * dpi
	var left: float = maxf(shown.position.x, window.position.x + corner)
	var top: float = maxf(shown.position.y, window.position.y + corner)
	var right: float = minf(shown.end.x, window.end.x - corner)
	# the lowest of the three feet: the system's, the corner's and the keyboard's
	var bottom: float = minf(shown.end.y, window.end.y - maxf(corner, keyboard_px))
	return PackedFloat32Array([maxf(0.0, left - rect.position.x), maxf(0.0, top - rect.position.y), maxf(0.0, rect.end.x - right), maxf(0.0, rect.end.y - bottom)])


## The scale the canvas is drawn at, in the rect's pixels to a base pixel:
## the one that fits the base inside the rect, or the least a base pixel may
## measure where that is larger - and never so large that the room left by
## what is covered, less a gutter at each end, is under the floor on its
## shorter side.
static func drawn_at(rect_size: Vector2, covered_px: PackedFloat32Array, base: Vector2, least: float, floor_room: float, gutter: float) -> float:
	var fitted: float = maxf(minf(rect_size.x / base.x, rect_size.y / base.y), least)
	# the rect less what is covered, in pixels
	var clear := rect_size - Vector2(covered_px[SIDE_LEFT] + covered_px[SIDE_RIGHT], covered_px[SIDE_TOP] + covered_px[SIDE_BOTTOM])
	# the scale at which the clear short side, less a gutter at each end, is exactly the floor
	return minf(fitted, minf(clear.x, clear.y) / (floor_room + 2.0 * gutter))


## The inset at each edge of the canvas, in base pixels: what is covered, at
## this scale, with the gutter on top - each to the nearest whole base pixel.
static func insets(covered_px: PackedFloat32Array, scale: float, gutter: float) -> PackedFloat32Array:
	var inset := PackedFloat32Array()
	# every edge, in Side's order
	for side: int in 4:
		inset.append(roundf(covered_px[side] / scale + gutter))
	return inset
