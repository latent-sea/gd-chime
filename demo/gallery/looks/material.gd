extends "res://demo/demo_theme.gd"

const Charts := preload("res://addons/gd_chime/theme_charts.gd")

## MATERIAL DESIGN. Paper, made of light: every surface is a sheet at a
## stated height above the one behind it, and the shadow it casts is the
## only thing that says how high. Colour is not picked - it is derived,
## every tone in the screen a tint of one seed - and everything sits on a
## grid of eight, so nothing is ever a little bit off.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The rules: a sheet's height is its shadow (2 for a resting card, 5 for
## the thing being asked for, 12 for a pop-up that floats over all of it);
## hover is a lighter state layer over the sheet, never a new colour;
## refused is 38% ink on a sheet laid flat with no shadow at all; the
## prompt is the container tone of the seed, lifted; focus is a two-pixel
## ring in the seed itself. Radii are small and even, 4 and 8.

## The seed, and the tonal palette derived from it.
const SEED := Color("#6750a4")
const SEED_DEEP := Color("#21005d")
const CONTAINER := Color("#eaddff")
const OUTLINE := Color("#79747e")
const WHITE := Color("#ffffff")
const PALETTE := {
	&"ground": Color("#f4eff7"),
	&"raised": Color("#fffbfe"),
	&"lit": Color("#e7e0ec"),
	&"ink": Color("#1d1b20"),
	&"ink_soft": Color("#49454f"),
	&"accent": SEED,
	&"shade": Color(0.11, 0.09, 0.15, 0.55),
	# the outline an empty slot is dashed in: named, because it is painted, and a painter reads its colour from the palette as it draws
	&"outline": OUTLINE,
}
## A shadow: the same soft dark at every height, only further and deeper.
const CAST := Color(0.11, 0.09, 0.15, 0.22)
## The grid of eight.
const STEP := 8.0
## The sans family, and its fallbacks on a machine without it.
const FAMILY: Array[String] = ["Segoe UI", "Roboto", "Helvetica", "Arial"]


func _init() -> void:
	super(PALETTE)
	_pressables()
	_surfaces()
	_type()
	_spacing()
	_phone()
	# the toggle's two looks and the inline options', from this look's own pressable: on and chosen are marked
	Look.toggle(self, &"accent")
	# paper is set moving fast and let settle slowly, taken away sharply, and a sheet scales as it fades
	moves({&"quick": 100, &"normal": 250, &"slow": 300, Motion.STAGGER: 50}, {Motion.ENTER: [Tween.TRANS_CUBIC, Tween.EASE_OUT, &"normal"], Motion.EXIT: [Tween.TRANS_CUBIC, Tween.EASE_IN, &"quick"], Motion.MOVE: [Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, &"normal"], Motion.EMPHASIS: [Tween.TRANS_QUINT, Tween.EASE_OUT, &"slow"], Motion.RESTYLE: [Tween.TRANS_CUBIC, Tween.EASE_OUT, &"quick"]}, {&"when": Transition.FADE, &"each": Transition.SCALE})



## A sheet: a fill at a radius, lifted this high, with this much air inside.
func _sheet(fill: Color, radius: float, height: float, pad: float = -1.0) -> StyleBoxFlat:
	return Look.flat(fill, {radius = radius, shadow = height, shadow_colour = CAST, shadow_offset = Vector2(0.0, height * 0.5), pad = pad})


## A box laid flat and faded, for a state that is refused.
func _refused(radius: float, pad: float) -> StyleBoxFlat:
	return Look.flat(Color(0.11, 0.11, 0.13, 0.12), {radius = radius, pad = pad})


## The four states, as sheets: resting, a lighter layer on hover, flat and
## faded when refused, the seed's container tone lifted when it is the prompt.
func _states(rest: Color, hover: Color, ink: Color, height: float, pad: float) -> Array:
	var boxes := {
		&"normal": _sheet(rest, STEP, height, pad),
		&"hover": _sheet(hover, STEP, height + 2.0, pad),
		&"inert": _refused(STEP, pad),
		&"glowing": _sheet(CONTAINER, STEP, height + 6.0, pad),
	}
	var inks := {&"normal": ink, &"hover": ink, &"inert": Color(0.11, 0.11, 0.13, 0.38), &"glowing": SEED_DEEP}
	return [boxes, inks]


func _pressables() -> void:
	# the base: a filled tonal button, resting a little above the ground, two steps of air inside it
	var button := _states(PALETTE[&"lit"], Color("#efe9f4"), PALETTE[&"ink"], 4.0, STEP * 2.0)
	Look.pressable(self, Themes.PRESSABLE, button[0], {inks = button[1], focus = Look.ring(SEED, {width = 2.0, radius = STEP, inset = -2.0}), base = &"Control"})
	# a tab: a flap with no fill at all, and under the one you are on the indicator - a three-pixel rule along its foot in the seed, the whole of material's answer to a tab
	var blank := Look.flat(Color.TRANSPARENT, {pad = STEP * 1.5})
	var layer := Look.flat(Color(0.40, 0.31, 0.64, 0.10), {pad = STEP * 1.5})
	Look.pressable(self, &"Tab", {
		&"normal": blank,
		&"hover": layer,
		&"inert": blank,
		&"glowing": Look.layered(self, [Look.flat(CONTAINER)], STEP * 1.5),
		&"current": Look.layered(self, [Look.nothing(), Paint.rule(&"accent", 3.0, SIDE_BOTTOM)], STEP * 1.5),
	}, {inks = {&"normal": PALETTE[&"ink_soft"], &"hover": SEED, &"inert": Color(0.11, 0.11, 0.13, 0.38), &"glowing": SEED_DEEP, &"current": SEED}, focus = Look.ring(SEED, {width = 2.0, radius = 4.0})})
	# a chip: an outline and nothing behind it, the way an assist chip is drawn
	Look.pressable(self, &"Chip", {
		&"normal": Look.flat(Color.TRANSPARENT, {radius = STEP, border = 1.0, border_colour = OUTLINE, pad = STEP * 1.5}),
		&"hover": Look.flat(Color(0.40, 0.31, 0.64, 0.10), {radius = STEP, border = 1.0, border_colour = SEED, pad = STEP * 1.5}),
		&"inert": Look.flat(Color.TRANSPARENT, {radius = STEP, border = 1.0, border_colour = Color(0.11, 0.11, 0.13, 0.20), pad = STEP * 1.5}),
		&"glowing": _sheet(CONTAINER, STEP, 6.0, STEP * 1.5),
	}, {inks = {&"normal": PALETTE[&"ink"], &"hover": SEED_DEEP, &"inert": Color(0.11, 0.11, 0.13, 0.38), &"glowing": SEED_DEEP}, focus = Look.ring(SEED, {width = 2.0, radius = STEP})})
	# an inline link: words in the seed, a state layer on hover, no sheet
	Look.pressable(self, &"NavInline", {
		&"normal": Look.nothing(),
		&"hover": Look.flat(Color(0.40, 0.31, 0.64, 0.10), {radius = 4.0, pad = STEP}),
		&"inert": Look.nothing(),
		&"glowing": Look.flat(CONTAINER, {radius = 4.0, pad = STEP}),
	}, {inks = {&"normal": SEED, &"hover": SEED_DEEP, &"inert": Color(0.11, 0.11, 0.13, 0.38), &"glowing": SEED_DEEP}, focus = Look.ring(SEED, {width = 2.0, radius = 4.0})})
	# the one filled action: the seed itself under white words, lifted highest of the pressables
	Look.pressable(self, &"NavPlay", {
		&"normal": _sheet(SEED, STEP, 6.0, STEP * 2.0),
		&"hover": _sheet(Color("#7965b5"), STEP, 10.0, STEP * 2.0),
		&"inert": _refused(STEP, STEP * 2.0),
		&"glowing": _sheet(SEED_DEEP, STEP, 14.0, STEP * 2.0),
	}, {inks = {&"normal": WHITE, &"hover": WHITE, &"inert": Color(0.11, 0.11, 0.13, 0.38), &"glowing": WHITE}, focus = Look.ring(SEED_DEEP, {width = 2.0, radius = STEP, inset = -2.0})})
	# the cards that are pressed: white sheets on the ground, less air the denser they are
	for card: Array in [[&"CardList", STEP * 2.0], [&"CardTile", STEP * 2.0], [&"CardDense", STEP]]:
		var stack := _states(PALETTE[&"raised"], Color("#f6f0fa"), PALETTE[&"ink"], 2.0, card[1])
		Look.pressable(self, card[0], stack[0], {inks = stack[1], focus = Look.ring(SEED, {width = 2.0, radius = STEP})})


func _surfaces() -> void:
	# the plain surface and the ones that only hold things: sheets resting on the ground
	Look.ground(self, Themes.SURFACE, _sheet(PALETTE[&"raised"], STEP, 2.0))
	Look.ground(self, Themes.RAISED, _sheet(PALETTE[&"raised"], STEP, 3.0, STEP * 2.0))
	Look.ground(self, Themes.CARD, _sheet(PALETTE[&"lit"], STEP, 2.0, STEP * 2.0))
	# the panel the flaps sit on: a sheet, so the indicator row reads as belonging to the screens under it
	Look.ground(self, &"TabPanel", _sheet(PALETTE[&"raised"], STEP, 2.0, STEP * 2.0))
	for holder: StringName in [&"Collection", &"Board", &"Matrix", &"Graph"]:
		Look.ground(self, holder, _sheet(PALETTE[&"raised"], STEP, 2.0, STEP * 2.0))
	# the pop-up: the highest sheet in the screen, and the scrim laid under it
	for over: StringName in [PANEL, &"Moment"]:
		Look.ground(self, over, _sheet(WHITE, STEP * 2.0, 14.0, STEP * 3.0))
	Look.ground(self, SHADE, Look.flat(PALETTE[&"shade"]))
	# a bubble: the seed's container tone, lifted a little
	Look.ground(self, &"Bubble", _sheet(CONTAINER, STEP, 3.0, STEP * 2.0))
	# nothing there yet: an outline in dashes rather than a sheet, because an absent sheet casts no shadow
	Look.ground(self, &"CardEmpty", Look.layered(self, [Look.flat(Color.TRANSPARENT, {radius = STEP}), Paint.dashed(&"outline", 2.0, {dash = 10.0, gap = 8.0, inset = 0.0, radius = STEP})], STEP * 2.0))
	# the text field: a fill rounded at the top alone with a line along its foot, thickening in the seed while it has the focus
	var field := Look.flat(PALETTE[&"lit"], {radius = 4.0})
	field.corner_radius_bottom_left = 0
	field.corner_radius_bottom_right = 0
	set_type_variation(&"Field", &"LineEdit")
	set_stylebox(&"normal", &"Field", Look.layered(self, [field, Paint.underline(&"ink_soft", 1.0)], STEP * 1.5))
	set_stylebox(&"focus", &"Field", Look.layered(self, [Paint.underline(&"accent", 3.0)], STEP * 1.5))
	set_color(&"font_color", &"Field", PALETTE[&"ink"])
	set_color(&"caret_color", &"Field", SEED)


func _type() -> void:
	var sans := Look.font(FAMILY)
	var medium := Look.font(FAMILY, {weight = 500})
	var bold := Look.font(FAMILY, {weight = 700})
	set_default_font(sans)
	default_font_size = 22
	# every kind reads in the darkest ink unless it is saying something quieter, and so does any words with no kind at all
	set_color(&"font_color", &"Label", PALETTE[&"ink"])
	for kind: StringName in [Themes.FACE, Themes.REASON, Themes.WORDS, READOUT, LINE, Themes.TITLE, Themes.NUMBER]:
		set_color(&"font_color", kind, PALETTE[&"ink"])
	# the clock in the strip: small, and in the seed because it is counting without being asked
	Look.words(self, &"Countdown", 20, {font = medium, colour = SEED})
	Look.words(self, Themes.TITLE, 22, {font = bold, colour = SEED_DEEP})
	Look.words(self, Themes.WORDS, 34, {font = medium, colour = PALETTE[&"ink"]})
	Look.words(self, Themes.FACE, 26, {font = medium, colour = PALETTE[&"ink"]})
	Look.words(self, Themes.REASON, 18, {font = sans, colour = PALETTE[&"ink_soft"]})
	Look.words(self, READOUT, 20, {font = sans, colour = PALETTE[&"ink_soft"]})
	Look.words(self, LINE, 22, {font = sans, colour = PALETTE[&"ink"]})
	Look.words(self, Themes.NUMBER, 80, {font = Look.font(FAMILY, {weight = 300}), colour = SEED})


func _spacing() -> void:
	# the grid of eight: two steps between the big things, one inside a set
	for wide: StringName in [Themes.ROW, Themes.COLUMN, Themes.TILES, Themes.CENTRED, &"Outcomes"]:
		set_constant(&"gap", wide, int(STEP * 2.0))
	for close: StringName in [TIGHT, &"Controls", &"Chips", &"MatrixLine", &"FilterSet", &"Disposition", &"AmountField"]:
		set_constant(&"gap", close, int(STEP))
	Look.line(self, &"InstructionBar", Themes.ROW, {gap = int(STEP * 3.0), justify = Look.BETWEEN, align = Look.CENTER})
	# the indicator row: flaps abutting, sitting on the panel's top edge, and the two of them one thing
	Look.line(self, &"TabStrip", Themes.ROW, {gap = 0, justify = Look.START, align = Look.END})
	Look.line(self, &"TabSet", Themes.COLUMN, {gap = 0, justify = Look.START, align = Look.STRETCH})
	set_constant(&"gap", Themes.GRID, int(STEP * 2.0))
	set_constant(&"row_gap", Themes.GRID, int(STEP * 2.0))
	# every drawn line in the seed, and the graph's links in the softer ink
	for drawn: StringName in Charts.DRAWN:
		set_color(&"line", drawn, SEED)
	set_color(&"link", &"Graph", PALETTE[&"ink_soft"])
	# the prompt breathes slowly and shallowly: a sheet is lit, not flashed
	set_constant(&"period", Themes.PULSE, 1600)
	set_constant(&"depth", Themes.PULSE, 35)


## A phone's pieces (theme_feedback.gd): the navigation bar a raised sheet
## with the destination you are at held in the seed's container tone, a
## pill; the rail the same down the side; a swiped row a white list sheet,
## the ground it uncovers the lit tone, armed the container tone ringed in
## the seed; a snackbar's room one notification high, as Material shows one.
func _phone() -> void:
	var destination := _states(Color.TRANSPARENT, Color(0.40, 0.31, 0.64, 0.10), PALETTE[&"ink_soft"], 0.0, STEP * 1.5)
	destination[0][&"current"] = Look.flat(CONTAINER, {radius = STEP * 2.0, pad = STEP * 1.5})
	destination[1][&"current"] = SEED_DEEP
	Look.pressable(self, &"NavItem", destination[0], {inks = destination[1], focus = Look.ring(SEED, {width = 2.0, radius = STEP * 2.0})})
	Look.line(self, &"NavBar", Themes.ROW, {gap = int(STEP), justify = Look.START, align = Look.CENTER})
	Look.line(self, &"NavRail", Themes.COLUMN, {gap = int(STEP), justify = Look.START, align = Look.STRETCH})
	Look.line(self, &"NavFrame", Themes.ROW, {gap = 0, justify = Look.START, align = Look.STRETCH})
	var row := _states(PALETTE[&"raised"], Color("#f6f0fa"), PALETTE[&"ink"], 2.0, STEP * 2.0)
	Look.pressable(self, &"SwipeRow", row[0], {inks = row[1], focus = Look.ring(SEED, {width = 2.0, radius = STEP})})
	# either way a row is swiped, the ground it uncovers; armed, the container tone ringed in the seed
	for side: String in ["right", "left"]:
		set_stylebox(StringName("reveal_" + side), &"SwipeRow", Look.flat(PALETTE[&"lit"], {radius = STEP, pad = STEP * 2.0}))
		set_stylebox(StringName("armed_" + side), &"SwipeRow", Look.flat(CONTAINER, {radius = STEP, border = 3.0, border_colour = SEED, pad = STEP * 2.0}))
	Look.line(self, &"SwipeReveal", Themes.ROW, {gap = int(STEP), justify = Look.START, align = Look.CENTER})
	Look.line(self, &"PullIndicator", Themes.ROW, {gap = int(STEP), justify = Look.CENTER, align = Look.CENTER})
	# a screen: the ground itself, two steps of air from the glass's edge
	Look.ground(self, &"PhoneScreen", Look.flat(PALETTE[&"ground"], {pad = STEP * 2.0}))
	set_constant(&"holds", Themes.NOTICE, 1)
	# on a phone's window anything pressed is at least eleven steps each way: undecided, short of Material's 48dp (eighteen steps at 360dp across) to suit this look's type
	set_constant(&"least", &"Touch", int(STEP * 11.0))
