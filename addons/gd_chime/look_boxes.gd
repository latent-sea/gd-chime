extends RefCounted

const PaintedBox := preload("painted_box.gd")
const Paint := preload("paint.gd")
const Options := preload("components/primitives/options.gd")

## The boxes every look is drawn with: a FLAT box in one call, a FLAP, a
## RING, NOTHING, a LAYERED box of boxes and painters, and the two made of
## layers - an ELEVATION and a SOFT box - so a look says what it believes in
## a few lines and never repeats the engine's spelling.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## This half of a look's vocabulary MAKES A BOX and never puts an entry into
## a theme. look.gd extends it with the half that does - a pressable's
## states, a kind of words, the fonts - so a look calls every one of them as
## Look's and never needs to know which half it came from.
##
## A PAINTER TAKES AN INK, A NAME THE THEME HOLDS, never a Color: it reads
## the colour as it draws, so a palette switched under it reaches what is
## painted (paint.gd). So `layered`, and the boxes made of layers, take the
## theme first: it is what the painters read.
##
## A BOX TAKES ITS FILL AND NAMED OPTIONS - `Look.flat(fill, {radius = 8,
## border = 2, border_colour = ink, pad = 12})` - never a row of numbers
## and colours whose order must be remembered: two swapped values would be
## a silently wrong look, and an option this does not know is reported out
## loud. A square-only painter (paint.gd) layered over a rounded box would
## overhang its corners, and `layered` reports that pairing.


## The options given, over these defaults, checked by the one checker every
## named option in the framework goes through (options.gd): a name this does
## not know is reported out loud, since a misspelt option would be a
## silently wrong look.
static func _options(given: Dictionary, defaults: Dictionary, what: String) -> Dictionary:
	var options := defaults.duplicate()
	options.merge(Options.checked(what, given, defaults.keys()), true)
	return options


## A flat box: a fill, and by option a radius, a border and its colour, a
## shadow with its colour and offset, and the padding inside.
static func flat(fill: Color, options: Dictionary = {}) -> StyleBoxFlat:
	var with := _options(options, {"radius": 0.0, "border": 0.0, "border_colour": Color.TRANSPARENT, "shadow": 0.0, "shadow_colour": Color.TRANSPARENT, "shadow_offset": Vector2.ZERO, "pad": -1.0}, "a flat box")
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.set_corner_radius_all(int(with["radius"]))
	box.set_border_width_all(int(with["border"]))
	box.border_color = with["border_colour"]
	box.shadow_size = int(with["shadow"])
	box.shadow_color = with["shadow_colour"]
	box.shadow_offset = with["shadow_offset"]
	if with["pad"] >= 0.0:
		box.set_content_margin_all(with["pad"])
	return box


## A flap: a box rounded at its top corners alone, padded taller above its
## words - a tab's shape; by option its radius, pad_top, pad, border.
static func flap(fill: Color, options: Dictionary = {}) -> StyleBoxFlat:
	var with := _options(options, {"radius": 0.0, "pad_top": 6.0, "pad": 6.0, "border": 0.0, "border_colour": Color.TRANSPARENT}, "a flap")
	var box := flat(fill, {"border": with["border"], "border_colour": with["border_colour"], "pad": with["pad"]})
	box.corner_radius_top_left = int(with["radius"])
	box.corner_radius_top_right = int(with["radius"])
	box.content_margin_top = with["pad_top"]
	return box


## A ring alone: the border with nothing inside, for a focus; by option its
## width, radius and how far inside the edge it sits.
static func ring(colour: Color, options: Dictionary = {}) -> StyleBoxFlat:
	var with := _options(options, {"width": 2.0, "radius": 0.0, "inset": 0.0}, "a ring")
	var box := flat(Color.TRANSPARENT, {"radius": with["radius"], "border": with["width"], "border_colour": colour})
	box.draw_center = false
	box.set_expand_margin_all(-with["inset"])
	return box


## An empty box, for a state that draws nothing.
static func nothing() -> StyleBoxEmpty:
	return StyleBoxEmpty.new()


## Boxes and painters drawn in order, INTO THIS THEME: each a StyleBox,
## [StyleBox, offset] or a painter (canvas, rect, theme). The theme is what
## the painters read their inks from as they draw. A square-only painter over
## a rounded box would overhang its corners, and is reported.
static func layered(theme: Theme, layers: Array, pad: float = -1.0) -> PaintedBox:
	var laid: Array = []
	var rounded := false
	# every layer laid with its offset, noting whether any box is rounded
	for layer: Variant in layers:
		var box: Variant = layer if layer is StyleBox else layer[0] if layer is Array else null
		if box is StyleBoxFlat and (box as StyleBoxFlat).corner_radius_top_left > 0:
			rounded = true
		laid.append([layer, Vector2.ZERO] if layer is StyleBox else layer)
	# every painter, for a square-only one over a rounded box
	for layer: Variant in layers:
		if rounded and layer is Callable and Paint.is_square_only(layer):
			push_error("a square-only painter (brackets, hatch) is layered over a rounded box and would overhang its corners; give the box no radius")
	var made := PaintedBox.new(laid, theme)
	if pad >= 0.0:
		made.set_content_margin_all(pad)
	return made


## A box at a height: an ambient shadow all round and a key shadow below,
## as Material's elevation pairs them, under the fill; by option its
## radius, height, shadow colour and padding.
static func elevation(theme: Theme, fill: Color, options: Dictionary = {}) -> PaintedBox:
	var with := _options(options, {"radius": 0.0, "height": 2.0, "shadow": Color(0.0, 0.0, 0.0, 0.3), "pad": -1.0}, "an elevation")
	var shadow: Color = with["shadow"]
	var ambient := flat(fill, {"radius": with["radius"], "shadow": with["height"] * 2.0, "shadow_colour": Color(shadow, shadow.a * 0.4)})
	var key := flat(fill, {"radius": with["radius"], "shadow": with["height"], "shadow_colour": shadow, "shadow_offset": Vector2(0.0, with["height"])})
	return layered(theme, [ambient, key, flat(fill, {"radius": with["radius"]})], with["pad"])


## A soft box: the fill with a light shadow up-left and a dark one
## down-right - extruded from the ground - or, sunken, the two swapped; by
## option its light and dark, radius, spread, sunken and padding.
static func soft(theme: Theme, fill: Color, options: Dictionary = {}) -> PaintedBox:
	var with := _options(options, {"light": Color.WHITE, "dark": Color.BLACK, "radius": 0.0, "spread": 10.0, "sunken": false, "pad": -1.0}, "a soft box")
	var offset := Vector2(with["spread"], with["spread"]) * 0.6
	var lit := flat(fill, {"radius": with["radius"], "shadow": with["spread"], "shadow_colour": with["light"], "shadow_offset": -offset})
	var shaded := flat(fill, {"radius": with["radius"], "shadow": with["spread"], "shadow_colour": with["dark"], "shadow_offset": offset})
	var body := flat(fill, {"radius": with["radius"]})
	return layered(theme, [shaded, lit, body] if with["sunken"] else [lit, shaded, body], with["pad"])
