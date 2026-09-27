extends "res://demo/demo_theme.gd"

const Paper := preload("res://demo/gallery/looks/skeuomorphic_paper.gd")
const Pressables := preload("res://addons/gd_chime/theme_pressables.gd")
const Charts := preload("res://addons/gd_chime/theme_charts.gd")

## SKEUOMORPHISM. A digital thing should imitate a physical one, so a hand
## already knows what to do with it: leather and walnut grounds, tan panels
## with a stitched edge, and every pressable a bevelled plate lit from above
## - lighter at the top, darker at the bottom, a dark hairline around it.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Affordance through familiarity: raised means press me, sunken means write
## here, and the one thing the guide wants pressed is a brass plate glowing
## amber. Refused things go flat and grey - the only unpressable shape in the
## language. Type is classic: a serif for titles, a plain sans for the rest.
## The objects made of card and slate - a stall's and a paper form's - are
## skeuomorphic_paper.gd's, built from this look's palette and box-makers.

const PALETTE := {
	&"ground": Color("#43301f"),
	&"raised": Color("#cdb891"),
	&"lit": Color("#e3d5b5"),
	&"ink": Color("#2b1e13"),
	&"ink_soft": Color("#574733"),
	&"accent": Color("#d89a2c"),
	&"shade": Color(0.10, 0.06, 0.03, 0.62),
	# everything below is PAINTED, and a painter reads its colour from the palette as it draws, so a palette turned for another eye reaches it
	# a plate's face, top to bottom, at rest and pressed
	&"face_top": Color("#eaddbd"), &"face_bottom": Color("#c0a87c"),
	&"pressed_top": Color("#b49c71"), &"pressed_bottom": Color("#d3c095"),
	# the brass plate the prompt wears
	&"brass_top": Color("#f3c964"), &"brass_bottom": Color("#c8871a"),
	# a dead plate: no warmth left in it at all
	&"dead_top": Color("#b9b4ab"), &"dead_bottom": Color("#9a958c"),
	&"card_top": Color("#e6d8b6"), &"card_bottom": Color("#cbb488"),
	&"card_lit_top": Color("#f2e6c9"), &"card_lit_bottom": Color("#d8c296"),
	# the thread a panel is stitched with: on a board, on the counter's leather, on a ledger page
	&"stitch": Color("#9a8258"), &"stitch_deep": Color("#8a6c42"), &"stitch_pale": Color("#c2ac7c"),
	# the darker amber a printed link is underlined in
	&"amber_deep": Color("#8a5a14"),
	# the light on every bevel and the hollow under it, and the dimmer pair on the walnut sheets and the slate: warm tints, too faint in hue for any eye's palette to turn
	&"sheen": Color(1.0, 0.98, 0.90, 0.75), &"hollow": Color(0.20, 0.13, 0.06, 0.45),
	&"sheet_sheen": Color(1.0, 0.9, 0.7, 0.18), &"sheet_hollow": Color(0.0, 0.0, 0.0, 0.5), &"slate_sheen": Color(1.0, 1.0, 0.95, 0.12),
}
## The walnut the panels sit on and the hairline drawn around every plate.
const WALNUT := Color("#3a281a")
const EDGE := Color("#5d452a")
## The leather of the counter the dividers stand on and merge into.
const COUNTER := Color("#5a3d23")
const DEAD_INK := Color("#6e6a63")
const RADIUS := 7.0


func _init() -> void:
	super(PALETTE)
	var serif := Look.font(["Georgia", "Cambria", "Times New Roman"])
	var sans := Look.font(["Segoe UI", "Verdana", "Arial"])
	_plates()
	_panels()
	_type(serif, sans)
	# the objects made of card and slate, a stall's and a paper form's (skeuomorphic_paper.gd)
	Paper.stall(self)
	Paper.form(self)
	# lines drawn: dark walnut ink on tan, the graph in brass
	for drawn: StringName in Charts.DRAWN:
		set_color(&"line", drawn, WALNUT)
	set_color(&"line", &"Graph", Color("#a8761c"))
	set_color(&"link", &"Graph", Color(0.42, 0.32, 0.18, 0.55))
	# the spacing scale: panelled things want a little air between them
	for line: StringName in [Themes.ROW, Themes.COLUMN]:
		set_constant(&"gap", line, 14)
	Look.line(self, Pressables.PROMPT_BAR, Themes.ROW, {gap = 18, justify = Look.CENTER})
	Look.line(self, &"Chips", Themes.TILES, {gap = 10})
	Look.line(self, &"AmountField", Themes.ROW, {gap = 10, justify = Look.START, align = Look.CENTER})
	# a slow warm pulse, as a lamp behind glass rather than a blink
	set_constant(&"period", Themes.PULSE, 1600)
	set_constant(&"depth", Themes.PULSE, 40)
	# the toggle's two looks and the inline options', from this look's own pressable: on and chosen are marked
	Look.toggle(self, &"accent")
	# a real object has mass: it takes time to start, takes time to stop, and overshoots a little as it settles
	moves({&"quick": 140, &"normal": 320, &"slow": 480, Motion.STAGGER: 55}, {Motion.ENTER: [Tween.TRANS_BACK, Tween.EASE_OUT, &"normal"], Motion.EXIT: [Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, &"normal"], Motion.MOVE: [Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, &"normal"], Motion.EMPHASIS: [Tween.TRANS_BACK, Tween.EASE_OUT, &"slow"], Motion.RESTYLE: [Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, &"quick"]}, {&"when": Transition.FADE, &"each": Transition.GROW})



## Every pressable: a bevelled plate, and the few that are a different object.
func _plates() -> void:
	var boxes := {
		&"normal": plate(&"face_top", &"face_bottom", RADIUS, 12.0),
		&"hover": plate(&"pressed_top", &"pressed_bottom", RADIUS, 12.0, true),
		&"inert": dead(RADIUS, 12.0),
		&"glowing": plate(&"brass_top", &"brass_bottom", RADIUS, 12.0, false, 3.0),
	}
	var inks := {&"normal": PALETTE[&"ink"], &"hover": PALETTE[&"ink"], &"inert": DEAD_INK, &"glowing": WALNUT}
	Look.pressable(self, Themes.PRESSABLE, boxes, {inks = inks, focus = focus_ring(RADIUS), base = &"Control"})
	# every other kind of pressable wears the same plate, and is told so, or the engine has no ink for its words
	for same: StringName in [Pressables.BUTTON, &"NavPlay", &"Relative", &"Choice", &"Picker"]:
		Look.pressable(self, same, boxes, {inks = inks, focus = focus_ring(RADIUS)})
	# a tab: an index-card divider standing out of the counter, the one you are on in the counter's own leather, taller, merged into it
	var tabs := {
		&"normal": divider(Color("#c3ab7f"), 10.0),
		&"hover": divider(PALETTE[&"face_top"], 10.0),
		&"inert": divider(Color("#c3ab7f"), 10.0),
		&"glowing": divider(PALETTE[&"brass_top"], 10.0),
		&"current": Look.flap(COUNTER, {radius = 9.0, pad_top = 22.0, pad = 14.0}),
	}
	Look.pressable(self, &"Tab", tabs, {inks = {&"normal": PALETTE[&"ink"], &"hover": PALETTE[&"ink"], &"inert": PALETTE[&"ink"], &"glowing": WALNUT, &"current": PALETTE[&"lit"]}, focus = focus_ring(4.0)})
	# a chip: the same plate, small and fully rounded, as a stud
	Look.pressable(self, &"Chip", {
		&"normal": plate(&"face_top", &"face_bottom", 9.0, 9.0),
		&"hover": plate(&"pressed_top", &"pressed_bottom", 9.0, 9.0, true),
		&"inert": dead(9.0, 9.0),
		&"glowing": plate(&"brass_top", &"brass_bottom", 9.0, 9.0, false, 3.0),
	}, {inks = {&"normal": PALETTE[&"ink"], &"hover": PALETTE[&"ink"], &"inert": DEAD_INK, &"glowing": WALNUT}, focus = focus_ring(9.0)})
	# an inline word: no plate at all, an underlined line of ink, as printed text
	Look.pressable(self, &"NavInline", {
		&"normal": Look.layered(self, [Paint.underline(&"amber_deep", 2.0, 2.0)], 8.0),
		&"hover": Look.layered(self, [Paint.underline(&"accent", 3.0, 2.0)], 8.0),
		&"inert": Look.layered(self, [], 8.0),
		&"glowing": Look.layered(self, [Paint.underline(&"accent", 3.0, 2.0)], 8.0),
	}, {inks = {&"normal": Color("#7a4f10"), &"hover": Color("#8a5a14"), &"inert": DEAD_INK, &"glowing": Color("#7a4f10")}, focus = focus_ring(4.0)})
	# a listed card and a tile: a wide plate, softer cornered, roomier inside
	for card: StringName in [&"CardList", &"CardTile", &"CardDense"]:
		Look.pressable(self, card, {
			&"normal": plate(&"card_top", &"card_bottom", 6.0, 16.0),
			&"hover": plate(&"card_lit_top", &"card_lit_bottom", 6.0, 16.0),
			&"inert": dead(6.0, 16.0),
			&"glowing": plate(&"brass_top", &"brass_bottom", 6.0, 16.0, false, 3.0),
		}, {inks = {&"normal": PALETTE[&"ink"], &"hover": PALETTE[&"ink"], &"inert": DEAD_INK, &"glowing": WALNUT}, focus = focus_ring(6.0)})


## Every surface: leather, walnut or tan board, stitched where it is a panel.
func _panels() -> void:
	# a captioned box: a tan board on the leather, stitched just inside its edge
	Look.ground(self, Themes.RAISED, Look.layered(self, [
		Look.flat(PALETTE[&"raised"], {radius = RADIUS, border = 1.0, border_colour = EDGE, shadow = 8.0, shadow_colour = Color(0.0, 0.0, 0.0, 0.35), shadow_offset = Vector2(0.0, 3.0)}),
		Paint.bevel(&"sheen", &"hollow", 2.0),
		stitch(&"stitch", 5.0),
	], 16.0))
	# a card inside one: the lighter tan, unstitched, so boards do not nest into noise
	Look.ground(self, Themes.CARD, Look.layered(self, [
		Look.flat(PALETTE[&"lit"], {radius = 5.0, border = 1.0, border_colour = EDGE}),
		Paint.bevel(&"sheen", &"hollow", 2.0),
	], 12.0))
	# a pop-up: the moment, a thicker board lifted well off the leather
	Look.ground(self, PANEL, Look.layered(self, [
		Look.flat(PALETTE[&"raised"], {radius = 9.0, border = 2.0, border_colour = WALNUT, shadow = 22.0, shadow_colour = Color(0.0, 0.0, 0.0, 0.55), shadow_offset = Vector2(0.0, 8.0)}),
		Paint.bevel(&"sheen", &"hollow", 3.0),
		stitch(&"stitch", 8.0),
	], 26.0))
	# the shade under it: the room going dark, not a tint
	Look.ground(self, SHADE, Look.flat(PALETTE[&"shade"]))
	# the plain surface, and the walnut sheets that things are laid out on
	Look.ground(self, Themes.SURFACE, Look.layered(self, [Look.flat(PALETTE[&"raised"], {radius = 5.0, border = 1.0, border_colour = EDGE}), Paint.bevel(&"sheen", &"hollow", 2.0)]))
	for sheet: StringName in [&"Board", &"Matrix", &"Collection", &"Graph"]:
		Look.ground(self, sheet, Look.layered(self, [
			Look.flat(WALNUT, {radius = 6.0, border = 1.0, border_colour = Color("#241708")}),
			Paint.bevel(&"sheet_sheen", &"sheet_hollow", 2.0),
		], 12.0))
	# an empty slot: the pale bed a thing would be laid in
	Look.ground(self, &"CardEmpty", bed(10.0))
	# a text field: an engine line edit, cut into the board, with an inked caret
	set_type_variation(&"Field", &"LineEdit")
	set_stylebox(&"normal", &"Field", bed(10.0))
	set_stylebox(&"focus", &"Field", focus_ring(5.0))
	set_color(&"font_color", &"Field", PALETTE[&"ink"])
	set_color(&"caret_color", &"Field", Color("#8a5a14"))
	# a spoken bubble: the lighter tan, well rounded
	Look.ground(self, &"Bubble", Look.layered(self, [Look.flat(PALETTE[&"lit"], {radius = 12.0, border = 1.0, border_colour = EDGE}), Paint.bevel(&"sheen", &"hollow", 2.0)], 12.0))


## Every kind of words: a serif for the titles, a plain sans for the rest.
func _type(serif: Font, sans: Font) -> void:
	set_default_font(sans)
	default_font_size = 24
	set_color(&"font_color", &"Label", PALETTE[&"ink"])
	for kind: StringName in [Themes.FACE, Themes.REASON, Themes.WORDS, READOUT, LINE, Themes.TITLE, Themes.NUMBER]:
		set_color(&"font_color", kind, PALETTE[&"ink"])
	Look.words(self, Themes.TITLE, 24, {font = Look.font(["Georgia", "Cambria", "Times New Roman"], {weight = 700}), colour = WALNUT})
	Look.words(self, Themes.WORDS, 34, {font = serif, colour = WALNUT})
	Look.words(self, Themes.FACE, 26, {font = sans, colour = PALETTE[&"ink"]})
	Look.words(self, Themes.REASON, 19, {font = sans, colour = PALETTE[&"ink_soft"]})
	Look.words(self, READOUT, 21, {font = sans, colour = PALETTE[&"ink_soft"]})
	Look.words(self, LINE, 23, {font = sans, colour = PALETTE[&"ink"]})
	Look.words(self, Themes.NUMBER, 88, {font = Look.font(["Georgia", "Cambria", "Times New Roman"], {weight = 700}), colour = WALNUT})


## A plate: a vertical gradient, a bevel raised - or sunken, pressed - and a
## dark hairline around it, the whole thing padded like a real key.
func plate(top: StringName, bottom: StringName, radius: float, pad: float, pressed: bool = false, bevel: float = 2.0) -> StyleBox:
	return Look.layered(self, [
		Look.flat(PALETTE[bottom], {radius = radius, shadow = 5.0, shadow_colour = Color(0.0, 0.0, 0.0, 0.30), shadow_offset = Vector2(0.0, 2.0)}),
		Paint.gradient(top, bottom, radius),
		Paint.bevel(&"hollow", &"sheen", bevel) if pressed else Paint.bevel(&"sheen", &"hollow", bevel),
		Look.ring(EDGE, {width = 1.0, radius = radius}),
	], pad)


## An index-card divider: a tan flap rounded at the top, a dark hairline
## round it and the light falling across it, padded this much above its word.
func divider(fill: Color, pad_top: float) -> StyleBox:
	var box := Look.layered(self, [Look.flap(fill, {radius = 9.0, pad_top = pad_top, pad = 12.0, border = 1.0, border_colour = EDGE}), Paint.bevel(&"sheen", &"hollow", 2.0)], 12.0)
	box.content_margin_top = pad_top
	return box


## A refused plate: the same shape with the warmth and the light taken out.
func dead(radius: float, pad: float) -> StyleBox:
	return Look.layered(self, [
		Paint.gradient(&"dead_top", &"dead_bottom", radius),
		Look.ring(Color("#7f7a72"), {width = 1.0, radius = radius}),
	], pad)


## A bed cut into the board: a pale fill, the bevel sunken, a dark rim.
func bed(pad: float) -> StyleBox:
	return Look.layered(self, [
		Look.flat(Color("#f3ead2"), {radius = 5.0}),
		Paint.bevel(&"hollow", &"sheen", 3.0),
		Look.ring(EDGE, {width = 1.0, radius = 5.0}),
	], pad)


## The focus: a soft amber ring set inside the plate's edge, as a lamp on it.
func focus_ring(radius: float) -> StyleBox:
	return Look.layered(self, [
		Look.ring(Color(0.85, 0.62, 0.18, 0.45), {width = 5.0, radius = radius, inset = 1.0}),
		Look.ring(PALETTE[&"accent"], {width = 2.0, radius = radius, inset = 3.0}),
	])


## A stitched edge: the dashed painter run on the rect pulled this far in.
func stitch(thread: StringName, inset: float) -> Callable:
	var dashes := Paint.dashed(thread, 2.0, {dash = 7.0, gap = 6.0})
	return func(canvas: RID, rect: Rect2, theme: Theme) -> void:
		dashes.call(canvas, rect.grow(-inset), theme)

