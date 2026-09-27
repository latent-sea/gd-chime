extends RefCounted

const Themes := preload("theme.gd")
const Options := preload("components/primitives/options.gd")

## The painters: what a flat box cannot draw - a dashed edge, corner
## brackets, a rule along one side, a hatch, a gradient, a bevel - each a
## function of (canvas item, rect, theme) for a layered box (look.gd) to draw
## in its turn.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A PAINTER IS GIVEN AN INK, NEVER A COLOUR. An ink is a NAME the theme
## holds - `&"accent"` - read from the theme ON EVERY DRAW, the way a
## primitive asks for its stylebox. A painter that closed over a Color would
## keep it, and a palette switched for an eye that cannot separate red from
## green would re-colour everything except what is painted. Reading per draw
## is one dictionary lookup, and follows a palette turned in place as readily
## as a whole new look put on the root.
##
## WHICH THEME: a StyleBox is handed a canvas item and a rect, never the
## Control, so there is no route from here to the theme the drawing control
## inherited. The layered box is TOLD its theme as it is built into one
## (look.gd's `layered`) and re-told by whatever re-colours one in place
## (palettes.gd), and holds it weakly - see painted_box.gd.
##
## THE INK VOCABULARY is every form the ten looks need and no more: a palette
## name; `under`, a colour under another theme type; `faded`, one at an
## opacity; and `mixed`, one blended toward another, which is how a shade OF
## the accent goes on following the accent. A colour a look paints with that
## none of those reach - a bevel's warm sheen, a pure white - goes into the
## look's own palette under a name. A name the theme does not hold is reported
## once and draws in magenta: a misspelt name would be a silently wrong look.
##
## A DASHED edge and a GRADIENT take a radius and follow a rounded box's
## corners, over one shared rounded OUTLINE. The two that draw to the rect's
## own square edges - BRACKETS and HATCH - are SQUARE-ONLY: over a rounded box
## they would overhang its corners, so each is kept as one and look.gd's
## `layered` reports it over a rounded box.

## How many steps a rounded corner's arc is drawn in.
const ARC := 6

## Every square-only painter made, for layered to tell one from the rest.
static var _square_only: Array = []
## Every name already reported as one the theme does not hold, so a painter
## drawing sixty times a second says it once.
static var _absent: Dictionary = {}
## While this is on, every colour resolved is kept, so a test can read back
## what a painter drew with: nothing can be read out of a canvas item again.
static var watching: bool = false
static var watched: Array[Color] = []


## Whether this painter draws to its rect's own edges.
static func is_square_only(painter: Callable) -> bool:
	return _square_only.has(painter)


## A painter kept as square-only, for layered to report over a rounded box.
static func _square(painter: Callable) -> Callable:
	_square_only.append(painter)
	return painter


## An ink: a colour of the theme under some type other than the palette's -
## the ink a pressable's words are in for one of its states, say.
static func under(name: StringName, type: StringName) -> Dictionary:
	return {"name": name, "type": type}


## An ink at this opacity.
static func faded(ink: Variant, alpha: float) -> Dictionary:
	return {"of": ink, "alpha": alpha}


## An ink blended this far toward another, so a shade of the accent is still
## the accent's when the accent turns.
static func mixed(ink: Variant, toward: Variant, by: float) -> Dictionary:
	return {"of": ink, "toward": toward, "by": by}


## The colour an ink is in this theme, as things stand now. Every painter
## goes through here on every draw, which is what makes a palette switch
## reach what is painted.
static func of(ink: Variant, theme: Theme) -> Color:
	var got := _resolved(ink, theme)
	if watching:
		watched.append(got)
	return got


## An ink worked out: a bare name is the palette's, and the rest are built
## from other inks, so faded(mixed(...)) is as good as either alone.
static func _resolved(ink: Variant, theme: Theme) -> Color:
	if ink is StringName:
		return _named(ink, Themes.LOOK, theme)
	var spec: Dictionary = ink
	if spec.has("name"):
		return _named(spec["name"], spec["type"], theme)
	var got := _resolved(spec["of"], theme)
	if spec.has("toward"):
		return got.lerp(_resolved(spec["toward"], theme), spec["by"])
	got.a = spec["alpha"]
	return got


## A colour the theme holds by name. A look naming one it does not hold is
## said out loud - once for that name - and draws in magenta: a misspelt
## name would otherwise be a silently wrong look.
static func _named(name: StringName, type: StringName, theme: Theme) -> Color:
	if theme.has_color(name, type):
		return theme.get_color(name, type)
	if not _absent.has(name):
		_absent[name] = true
		push_error("a painter asks for the colour %s under %s, which this look does not hold" % [name, type])
	return Color.MAGENTA


## The outline of a rect with its corners rounded this much, clockwise
## from the top left, each corner an arc of a few steps; square for none.
static func outline(rect: Rect2, radius: float) -> PackedVector2Array:
	var round := minf(radius, minf(rect.size.x, rect.size.y) / 2.0)
	if round <= 0.0:
		return PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	var points := PackedVector2Array()
	var centres := [rect.position + Vector2(round, round), Vector2(rect.end.x - round, rect.position.y + round), rect.end - Vector2(round, round), Vector2(rect.position.x + round, rect.end.y - round)]
	# every corner: an arc from where the last edge ends to where the next begins
	for corner: int in 4:
		for step: int in ARC + 1:
			var angle := PI + corner * PI / 2.0 + (PI / 2.0) * float(step) / float(ARC)
			points.append(centres[corner] + Vector2(cos(angle), sin(angle)) * round)
	return points


## A painter: a dashed edge walked round the rect's outline; by option its
## dash and gap in pixels, how far inside the rect it runs, and the radius
## its outline is rounded by, so it follows a rounded box's corners.
static func dashed(ink: Variant, width: float, options: Dictionary = {}) -> Callable:
	var with := Options.checked("a dashed edge", options, ["dash", "gap", "inset", "radius"])
	var dash: float = with.get("dash", 8.0)
	var gap: float = with.get("gap", 6.0)
	var inset: float = with.get("inset", 0.0)
	var radius: float = with.get("radius", 0.0)
	return func(canvas: RID, outer: Rect2, theme: Theme) -> void:
		var colour := of(ink, theme)
		var path := outline(outer.grow(-inset), radius)
		var drawing := true
		var left := dash
		# every edge of the outline, walked in dashes that carry over its corners
		for at_point: int in path.size():
			var from := path[at_point]
			var to := path[(at_point + 1) % path.size()]
			var length := from.distance_to(to)
			var along := 0.0
			while along < length:
				var reach := minf(left, length - along)
				if drawing:
					RenderingServer.canvas_item_add_line(canvas, from.lerp(to, along / length), from.lerp(to, (along + reach) / length), colour, width)
				along += reach
				left -= reach
				if left <= 0.0:
					drawing = not drawing
					left = dash if drawing else gap


## A painter: brackets on the four corners, each arm this long.
static func brackets(ink: Variant, width: float, arm: float = 14.0, inset: float = 0.0) -> Callable:
	return _square(func(canvas: RID, rect: Rect2, theme: Theme) -> void:
		var colour := of(ink, theme)
		var inner := rect.grow(-inset)
		# every corner: two arms along the edges from it
		for corner: Vector2 in [inner.position, Vector2(inner.end.x, inner.position.y), inner.end, Vector2(inner.position.x, inner.end.y)]:
			var towards_x := -1.0 if corner.x == inner.end.x else 1.0
			var towards_y := -1.0 if corner.y == inner.end.y else 1.0
			RenderingServer.canvas_item_add_line(canvas, corner, corner + Vector2(arm * towards_x, 0.0), colour, width)
			RenderingServer.canvas_item_add_line(canvas, corner, corner + Vector2(0.0, arm * towards_y), colour, width))


## A painter: a rule along one side - SIDE_TOP, SIDE_BOTTOM, SIDE_LEFT or
## SIDE_RIGHT - this thick, this far in from the edge.
static func rule(ink: Variant, width: float, side: int = SIDE_BOTTOM, inset: float = 0.0) -> Callable:
	return func(canvas: RID, rect: Rect2, theme: Theme) -> void:
		var inner := rect.grow(-inset)
		var along := Rect2(inner.position, Vector2(inner.size.x, width)) if side == SIDE_TOP else Rect2(Vector2(inner.position.x, inner.end.y - width), Vector2(inner.size.x, width)) if side == SIDE_BOTTOM else Rect2(inner.position, Vector2(width, inner.size.y)) if side == SIDE_LEFT else Rect2(Vector2(inner.end.x - width, inner.position.y), Vector2(width, inner.size.y))
		RenderingServer.canvas_item_add_rect(canvas, along, of(ink, theme))


## A painter: a line along the bottom edge.
static func underline(ink: Variant, width: float, inset: float = 0.0) -> Callable:
	return rule(ink, width, SIDE_BOTTOM, inset)


## A painter: a bar along the left edge.
static func left_bar(ink: Variant, width: float) -> Callable:
	return rule(ink, width, SIDE_LEFT)


## A painter: parallel hairlines across the rect; by option how far apart
## and how wide, and `diagonal` - at 45 degrees for a hatch, flat without
## it for scanlines.
static func hatch(ink: Variant, options: Dictionary = {}) -> Callable:
	var with := Options.checked("a hatch", options, ["spacing", "width", "diagonal"])
	var spacing: float = with.get("spacing", 4.0)
	var width: float = with.get("width", 1.0)
	var diagonal: bool = with.get("diagonal", false)
	return _square(func(canvas: RID, rect: Rect2, theme: Theme) -> void:
		var colour := of(ink, theme)
		var reach := rect.size.x + rect.size.y if diagonal else rect.size.y
		var along := 0.0
		while along < reach:
			if diagonal:
				var from := Vector2(rect.position.x + maxf(0.0, along - rect.size.y), rect.position.y + minf(along, rect.size.y))
				var to := Vector2(rect.position.x + minf(along, rect.size.x), rect.position.y + maxf(0.0, along - rect.size.x))
				RenderingServer.canvas_item_add_line(canvas, from, to, colour, width)
			else:
				RenderingServer.canvas_item_add_line(canvas, Vector2(rect.position.x, rect.position.y + along), Vector2(rect.end.x, rect.position.y + along), colour, width)
			along += spacing)


## A painter: a vertical gradient fill, top to bottom, reaching the corners
## of a box rounded by this radius: the rounded outline drawn as one
## polygon, each point in the colour of its height.
static func gradient(top: Variant, bottom: Variant, radius: float = 0.0) -> Callable:
	return func(canvas: RID, rect: Rect2, theme: Theme) -> void:
		var high := of(top, theme)
		var low := of(bottom, theme)
		var points := outline(rect, radius)
		var colours := PackedColorArray()
		# every point of the outline, in the colour of the height it sits at
		for point: Vector2 in points:
			colours.append(high.lerp(low, (point.y - rect.position.y) / rect.size.y))
		RenderingServer.canvas_item_add_polygon(canvas, points, colours)


## A painter: a bevel - a light line along the top and left, a dark one
## along the bottom and right, as a raised edge; swapped, a sunken one.
static func bevel(lit: Variant, dark: Variant, width: float = 2.0) -> Callable:
	return func(canvas: RID, rect: Rect2, theme: Theme) -> void:
		var above := of(lit, theme)
		var below := of(dark, theme)
		var half := width / 2.0
		RenderingServer.canvas_item_add_line(canvas, rect.position + Vector2(0.0, half), Vector2(rect.end.x, rect.position.y + half), above, width)
		RenderingServer.canvas_item_add_line(canvas, rect.position + Vector2(half, 0.0), Vector2(rect.position.x + half, rect.end.y), above, width)
		RenderingServer.canvas_item_add_line(canvas, Vector2(rect.position.x, rect.end.y - half), rect.end - Vector2(0.0, half), below, width)
		RenderingServer.canvas_item_add_line(canvas, Vector2(rect.end.x - half, rect.position.y), rect.end - Vector2(half, 0.0), below, width)
