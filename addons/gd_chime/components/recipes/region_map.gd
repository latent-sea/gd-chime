extends RefCounted

const Themes := preload("../../theme.gd")
const Ui := preload("../primitives/ui.gd")
const Options := preload("../primitives/options.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Pinned := preload("../primitives/pinned.gd")
const Loading := preload("loading.gd")

## A region map: every region drawn from data, shaded by how much of a
## figure falls in it, and each a press - its name pinned on it for the keys
## and the pad, its ground for the pointer - that picks it.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A REGION is {key, outline, pin}: its outline a polygon and its pin a
## point, both in a unit square (pinned.gd), so a map is data - any
## country, any floor plan - and never a picture. The values are a model's
## bound array, [{key, now}] (measures.gd's splits); each region is shaded
## from the look's faintest "fill" towards its "line" by its share of the
## most, so the most affected reads darkest - lightness, one ink, never a
## hue told apart.
##
## PRESSING A REGION - its pinned name or its ground - is the action given
## with {"picked": its key}, the payload a bar of a bar chart carries, so a
## map and a chart filter a collection alike (filters.gd, picks_of). The one
## picked is drawn by SHAPES: hatched across and ruled round thick in the
## line's ink, its name's press current and ringed.
##
## Loading until the values land; landed with nothing to shade, the map
## still stands - a region is still there to be pressed - and the words
## under it say so in the caller's words instead of what the shade means.

const MAP := &"RegionMap"
const PIN := &"RegionMapPin"
## A region's name on its press: a kind of words of its own, so a look can set it apart from the shade under it.
const PIN_WORDS := &"RegionMapName"


## The map of these regions over a bound [{key, now}]: shaded, each region a
## press of the action carrying its key, current while the picked value is
## its key; under it what the shade means, or, with nothing to shade, the
## caller's words for that.
## Its options: picked, a bound value reading which region is picked;
## says, what the map is called; says_empty, the words over nothing; and
## style.
const OPTIONS: Array[String] = ["picked", "says", Options.SAYS_EMPTY, Options.STYLE]

static func make(ui: Ui, action: StringName, regions: Array, values: Bound, options: Dictionary = {}) -> Desc:
	Options.checked("a region map", options, OPTIONS)
	var picked: Bound = options["picked"]
	var says: Variant = options["says"]
	var says_empty: Variant = options[Options.SAYS_EMPTY]
	var style: StringName = options.get(Options.STYLE, MAP)
	var shaded: Bound = Bound.both(values, picked, shading)
	var pins: Array = regions.map(func(one: Dictionary) -> Desc: return ui.pressable(action, {"picked": one["key"]}, [ui.text(one["key"], PIN_WORDS)], PIN).current_while(picked.map(func(chosen: Variant) -> bool: return chosen == one["key"])))
	var hit := func(at: Vector2) -> Variant: return region_at(regions, at)
	var drawn := ui.pinned(_paint.bind(regions), shaded, pins, {points = regions.map(func(one: Dictionary) -> Vector2: return one["pin"]), picks = action, hit = hit, style = style})
	var meaning: Bound = shaded.map(func(shades: Variant) -> Variant: return says_empty if shades != null and shades["empty"] else says)
	var landed: Bound = values.map(func(all: Variant) -> bool: return all != null)
	return Loading.until(ui, landed, ui.column([drawn.grow(), ui.text(meaning, Themes.REASON).wraps()]))


## Each region's share of the most any holds, the one picked, and whether
## there is nothing to shade at all: {shares, picked, empty}.
static func shading(values: Variant, picked: Variant) -> Variant:
	if values == null:
		return null
	var most := 0.0
	# every region, for the most any holds
	for one: Dictionary in values:
		most = maxf(most, one["now"])
	var shares: Dictionary = {}
	# every region, its share of that most
	for one: Dictionary in values:
		shares[one["key"]] = one["now"] / most if most > 0.0 else 0.0
	return {"shares": shares, "picked": picked, "empty": most == 0.0}


## The key of the region a point of the unit square lies in, or nothing.
static func region_at(regions: Array, at: Vector2) -> Variant:
	# every region, for the one whose outline holds the point
	for one: Dictionary in regions:
		if Geometry2D.is_point_in_polygon(at, PackedVector2Array(one["outline"])):
			return one["key"]
	return null


## The map: every region filled by its share and ruled round in the soft
## ink; the one picked hatched across and ruled round thick in the line's.
static func _paint(control: Control, shades: Variant, regions: Array) -> void:
	if shades == null:
		return
	var square := Pinned.fitted(control.size)
	var faint := control.get_theme_color(&"fill")
	var ink := control.get_theme_color(&"line")
	var deepest := control.get_theme_constant(&"deepest") / 1000.0
	# every region, filled and ruled round
	for one: Dictionary in regions:
		var placed := PackedVector2Array()
		# every corner of its outline, into the fitted square
		for corner: Vector2 in one["outline"]:
			placed.append(square.position + corner * square.size)
		control.draw_colored_polygon(placed, faint.lerp(ink, shades["shares"].get(one["key"], 0.0) * deepest))
		var picked: bool = shades["picked"] == one["key"]
		if picked:
			_hatch(control, placed, ink)
		control.draw_polyline(placed + PackedVector2Array([placed[0]]), ink if picked else control.get_theme_color(&"link"), float(control.get_theme_constant(&"picked_width" if picked else &"outline_width")))


## Lines across a region, one every gap of the look's, cut to its outline.
static func _hatch(control: Control, placed: PackedVector2Array, ink: Color) -> void:
	var bounds := Rect2(placed[0], Vector2.ZERO)
	# every corner, for the box the region stands in
	for corner: Vector2 in placed:
		bounds = bounds.expand(corner)
	var gap := float(control.get_theme_constant(&"hatch_gap"))
	var at := bounds.position.x - bounds.size.y
	# a slanting line every gap across the box, each cut to the region's outline
	while at < bounds.end.x:
		var across := PackedVector2Array([Vector2(at, bounds.end.y), Vector2(at + bounds.size.y, bounds.position.y)])
		# every piece of the line inside the region
		for inside: PackedVector2Array in Geometry2D.intersect_polyline_with_polygon(across, placed):
			control.draw_polyline(inside, ink, 1.0)
		at += gap
