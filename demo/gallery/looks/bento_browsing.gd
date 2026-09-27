extends RefCounted

const Look := preload("res://addons/gd_chime/look.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Motion := preload("res://addons/gd_chime/motion.gd")

## BENTO GRID, for browsing a collection: the shop's pieces - its cards'
## pictures, its facets, a gallery, a quick view and the drawers - drawn as
## more compartments of the one tray (bento.gd).
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A picture is a compartment of its card, rounded with the card's own
## family so the two never fight; a facet's value is a pill like every
## other press, the one picked the indigo block; a gallery's thumbnail is a
## small cell whose ring is the indigo seam; a quick view and a drawer are
## the largest cells, rounded as the pop-up is. The whole shop stands on
## the pale tray, one gutter in from the window's edge, and the cards keep
## that gutter between them. Every colour and number is the look's own -
## its palette, its radii, its pads and sizes - handed in from bento.gd or
## already written there; nothing new is chosen here.


## The browsing pieces put into the bento theme, from its own palette and numbers:
## {white, seam, pale, pastel, indigo, glow, ink, soft, shade, cell, pill, gutter, bold}.
static func dress(theme: Theme, bento: Dictionary) -> void:
	var white: Color = bento["white"]
	var cell: float = bento["cell"]
	var gutter: int = bento["gutter"]
	var focus := Look.ring(bento["indigo"], {width = 2.0, radius = bento["pill"], inset = 2.0})
	# the shell: the pale tray, one gutter in from the window's edge
	Look.ground(theme, &"Pane", Look.flat(bento["pale"], {pad = gutter}))
	# a picture: its own compartment, half a cell's corner inside a card, a cell's on its own
	for picture: Array in [[&"LazyImage", cell / 2.0], [&"GalleryPicture", cell], [&"GalleryThumbPicture", cell / 2.0], [&"FacetSwatch", bento["pill"]]]:
		theme.set_stylebox(&"panel", picture[0], Look.flat(bento["pale"], {radius = picture[1]}))
	# the cards: the one gutter between them
	theme.set_constant(&"gap", &"CollectionCards", gutter)
	theme.set_constant(&"gap", &"Collection", gutter)
	var pill := func(pad: float) -> Dictionary: return {&"normal": Look.flat(white, {radius = bento["pill"], border = 1.0, border_colour = bento["seam"], pad = pad}), &"hover": Look.flat(bento["pale"], {radius = bento["pill"], border = 1.0, border_colour = bento["seam"], pad = pad}), &"inert": Look.flat(bento["pale"], {radius = bento["pill"], border = 1.0, border_colour = bento["pale"], pad = pad})}
	var inks := {&"normal": bento["ink"], &"hover": bento["ink"], &"inert": bento["soft"]}
	# every small press of browsing: a pill, as every press of the tray is
	for small: StringName in [&"FacetValue", &"CollectionMore", &"DrawerClose", &"GalleryStep", &"QuickViewStep"]:
		Look.pressable(theme, small, pill.call(10.0), inks, focus)
	var picked: Dictionary = {}
	# every state of a value picked, the one indigo block
	for state: StringName in [&"normal", &"hover", &"inert"]:
		picked[state] = Look.flat(bento["indigo"], {radius = bento["pill"], shadow = 10.0, shadow_colour = bento["glow"], shadow_offset = Vector2(0.0, 4.0), pad = 10.0})
	Look.pressable(theme, &"FacetPicked", picked, {&"normal": white, &"hover": white, &"inert": white}, focus)
	Look.words(theme, &"FacetCount", 17, null, bento["soft"])
	# a facet: a white compartment with the seam, its title bold, as a heading is
	Look.ground(theme, &"FacetCell", Look.flat(white, {radius = cell, border = 1.0, border_colour = bento["seam"], pad = 18.0}))
	Look.words(theme, &"FacetTitle", 20, bento["bold"], bento["ink"])
	theme.set_constant(&"gap", &"FacetValues", 10)
	theme.set_constant(&"gap", &"Facet", 6)
	# a slider - a price's range among them: a pale pill of a track, filled with the indigo block, its handles white pills ringed in indigo
	theme.set_stylebox(&"track", &"ValueSlider", Look.flat(bento["pale"], {radius = bento["pill"]}))
	theme.set_stylebox(&"fill", &"ValueSlider", Look.flat(bento["indigo"], {radius = bento["pill"]}))
	theme.set_stylebox(&"handle", &"ValueSlider", Look.flat(white, {radius = bento["pill"], border = 2.0, border_colour = bento["indigo"]}))
	# a thumbnail: a small cell with a seam, its ring the indigo seam while it is the one showing
	var thumb := {&"normal": Look.flat(white, {radius = cell / 2.0, border = 1.0, border_colour = bento["seam"], pad = 4.0}), &"hover": Look.flat(bento["pastel"], {radius = cell / 2.0, border = 1.0, border_colour = bento["seam"], pad = 4.0}), &"inert": Look.flat(bento["pale"], {radius = cell / 2.0, pad = 4.0}), &"selected": Look.flat(white, {radius = cell / 2.0, border = 3.0, border_colour = bento["indigo"], pad = 4.0})}
	Look.pressable(theme, &"GalleryThumb", thumb, {&"normal": bento["ink"], &"hover": bento["ink"], &"inert": bento["soft"], &"selected": bento["ink"]}, Look.ring(bento["indigo"], {width = 2.0, radius = cell / 2.0, inset = 2.0}))
	# the largest cells: a quick view and a drawer, each rounded as a cell is
	Look.ground(theme, &"QuickView", Look.flat(white, {radius = 24.0, border = 1.0, border_colour = bento["seam"], pad = 26.0}))
	var drawer := Look.flat(white, {radius = 24.0, border = 1.0, border_colour = bento["seam"], pad = 26.0})
	Look.ground(theme, &"Drawer", drawer)
	# every state of the shade every sheet stands on, the look's own shade
	for shade_state: StringName in [&"normal", &"hover", &"inert", &"glowing", &"selected", &"current"]:
		theme.set_stylebox(shade_state, &"Shade", Look.flat(bento["shade"]))
	# the big cells' columns and rows, the one gutter apart
	for spaced: StringName in [&"DrawerColumn", &"QuickViewBody", &"Gallery"]:
		theme.set_constant(&"gap", spaced, gutter)
