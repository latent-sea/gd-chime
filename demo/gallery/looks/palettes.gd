extends RefCounted

const SimulatedSight := preload("res://addons/gd_chime/components/primitives/simulated_sight.gd")
const DemoTheme := preload("res://demo/demo_theme.gd")
const PaintedBox := preload("res://addons/gd_chime/painted_box.gd")

## A look's palette turned for an eye that cannot separate two of the
## primaries, and the arithmetic that says whether the turn was worth making.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A VARIANT IS DERIVED, NEVER TYPED OUT. Thirty hand-written palettes would
## be thirty things to keep true as ten looks change; this turns the one the
## look already has. The turn is chosen by measuring: every fifteenth of the
## hue circle is tried, each is passed through the matrix of the eye in
## question (simulated_sight.gd), and the one that leaves the accent furthest
## from BOTH the ground it sits on and the ink beside it wins. The turn that
## moves nothing is among those tried, so a variant is never worse than the
## palette it came from.
##
## THE LIGHTNESS STRUCTURE IS NOT TOUCHED. A hue turned at a fixed value
## would change how bright it reads - a yellow and a blue at full value are
## nothing like as bright as each other - and every contrast the look was
## built on would move with it. So a turned colour is put back to the exact
## relative luminance it had, by giving up value and then saturation until it
## reaches it. Contrast survives; only the hue moves.
##
## ONLY WHAT CARRIES HUE TURNS. A colour whose chroma is less than three
## fifths of the accent's is one of the near-greys the look's structure is
## made of - a ground, a rule, a soft ink - and stays exactly where it is.
##
## WHAT IS PAINTED TURNS TOO. A painter is given an ink - the NAME of a
## colour - and reads it from its theme on every draw (paint.gd), so a rule,
## an underline, a hatch or a bevel follows a palette turned here without
## being touched. What a layered box has to be told is WHICH theme, since one
## merged from another would read the colours it came from: every box swept
## here is pointed at the theme being swept.

const PLAIN := SimulatedSight.PLAIN
const SIGHTS := SimulatedSight.SIGHTS
## How much of the accent's chroma a colour must carry to count as carrying hue.
const CARRIES := 0.6
## How many turns of the hue circle are tried, the first of them no turn at all.
const TRIES := 24


## How much hue a colour carries, whatever its brightness: the spread of its
## three channels, which a grey has none of at any lightness.
static func chroma(colour: Color) -> float:
	return maxf(colour.r, maxf(colour.g, colour.b)) - minf(colour.r, minf(colour.g, colour.b))


## Relative luminance, as the contrast standard defines it: the linear light
## the three channels put out, weighted by how much of it the eye receives.
static func luminance(colour: Color) -> float:
	var light := colour.srgb_to_linear()
	return 0.2126 * light.r + 0.7152 * light.g + 0.0722 * light.b


## The contrast ratio between two colours, from 1 for the same to 21 for black on white.
static func contrast(one: Color, other: Color) -> float:
	var high := maxf(luminance(one), luminance(other))
	var low := minf(luminance(one), luminance(other))
	return (high + 0.05) / (low + 0.05)


## The colour as this eye receives it: its linear light through the matrix,
## and back to the screen's own scale so it can be compared with anything else.
static func seen(colour: Color, sight: StringName) -> Color:
	if sight == PLAIN:
		return colour
	var rows: Array = SimulatedSight.MATRICES[sight]
	var light := colour.srgb_to_linear()
	var through := Vector3(light.r, light.g, light.b)
	var got := Color(rows[0].dot(through), rows[1].dot(through), rows[2].dot(through), colour.a)
	return Color(clampf(got.r, 0.0, 1.0), clampf(got.g, 0.0, 1.0), clampf(got.b, 0.0, 1.0), colour.a).linear_to_srgb()


## Where a colour sits once the brightness is divided out: the share of its
## linear light each channel carries, which is what is left when two things
## differ in colour rather than in how bright they are. A black has no share
## to take, and counts as the neutral point.
static func _chromaticity(colour: Color) -> Vector2:
	var light := colour.srgb_to_linear()
	var total := light.r + light.g + light.b
	return Vector2(1.0, 1.0) / 3.0 if total <= 0.0 else Vector2(light.r, light.g) / total


## How far apart two colours are IN COLOUR to this eye. Brightness is left out
## on purpose: the variant never touches it, and a difference of brightness
## was never the thing a deficiency takes away. This is the difference that is.
static func apart(one: Color, other: Color, sight: StringName) -> float:
	return _chromaticity(seen(one, sight)).distance_to(_chromaticity(seen(other, sight)))


## A hue at a point of the one path from black through the hue at its fullest
## to white: value first, then saturation given up - so luminance only ever
## rises along it, and the point that matches a wanted luminance can be found
## by halving in.
static func _along(hue: float, saturation: float, at: float, alpha: float) -> Color:
	return Color.from_hsv(hue, saturation if at <= 0.5 else saturation * (1.0 - (at - 0.5) * 2.0), minf(at * 2.0, 1.0), alpha)


## A colour with its hue turned this far round, put back to the relative
## luminance it had, so nothing it was in contrast with has moved.
static func turned(colour: Color, by: float) -> Color:
	var want := luminance(colour)
	var hue := fposmod(colour.h + by, 1.0)
	var low := 0.0
	var high := 1.0
	# halving in on the point of the path whose luminance is the one it had
	for _step: int in range(24):
		var middle := (low + high) * 0.5
		if luminance(_along(hue, colour.s, middle, colour.a)) < want:
			low = middle
		else:
			high = middle
	return _along(hue, colour.s, (low + high) * 0.5, colour.a)


## The turn this palette wants for this eye: of every turn tried, the one
## leaving the accent furthest from whichever of the ground and the ink it
## comes nearest - the worst of the two is what decides whether it reads.
static func turn_for(palette: Dictionary, sight: StringName) -> float:
	var accent: Color = palette[&"accent"]
	var ground: Color = palette[&"ground"]
	var ink: Color = palette[&"ink"]
	var best := 0.0
	var furthest := -1.0
	# every turn of the circle tried, the first of them none at all
	for step: int in range(TRIES):
		var by := float(step) / float(TRIES)
		var moved := turned(accent, by)
		var reads: float = minf(apart(moved, ground, sight), apart(moved, ink, sight))
		if reads > furthest:
			furthest = reads
			best = by
	return best


## The whole theme turned for this eye: the palette it was built from, every
## colour it holds under any type, and every flat box at any depth of a
## layered one. A box reached twice - a look marks its own pressable's boxes -
## is turned once.
static func rewear(theme: DemoTheme, sight: StringName) -> void:
	if sight == PLAIN:
		return
	var by := turn_for(theme.palette, sight)
	var least := chroma(theme.palette[&"accent"]) * CARRIES
	# the palette the look was built from, so whatever reads it back reads what is worn; a look's own is a constant, and constants are read-only
	var worn := theme.palette.duplicate()
	for named: StringName in worn:
		worn[named] = _maybe(worn[named], by, least)
	theme.palette = worn
	# every colour the theme holds, under every type it holds one for
	for type: StringName in theme.get_color_type_list():
		for named: StringName in theme.get_color_list(type):
			theme.set_color(named, type, _maybe(theme.get_color(named, type), by, least))
	var done: Dictionary = {}
	# every box under every type; the same box under two types is turned once
	for type: StringName in theme.get_stylebox_type_list():
		for named: StringName in theme.get_stylebox_list(type):
			_turn_box(theme.get_stylebox(named, type), by, least, done, theme)


## A colour turned if it carries enough hue to be one of the ones that mean
## something, and left alone if it is one of the near-greys.
static func _maybe(colour: Color, by: float, least: float) -> Color:
	return turned(colour, by) if chroma(colour) >= least else colour


## One box turned: a flat box's fill, border and shadow, and a layered box's
## own boxes under it - and a layered box pointed at the theme it now belongs
## to, which is where its painters read their inks.
static func _turn_box(box: StyleBox, by: float, least: float, done: Dictionary, theme: DemoTheme) -> void:
	if done.has(box.get_instance_id()):
		return
	done[box.get_instance_id()] = true
	if box is StyleBoxFlat:
		var flat := box as StyleBoxFlat
		flat.bg_color = _maybe(flat.bg_color, by, least)
		flat.border_color = _maybe(flat.border_color, by, least)
		flat.shadow_color = _maybe(flat.shadow_color, by, least)
	if box is PaintedBox:
		# its painters read their inks from the theme they are told, which is this one
		(box as PaintedBox).set_look(theme)
		# every layer that is a box of the engine's; a painter needs no turning, since it reads a name
		for layer: Variant in (box as PaintedBox)._layers:
			if layer is Array:
				_turn_box(layer[0] as StyleBox, by, least, done, theme)
