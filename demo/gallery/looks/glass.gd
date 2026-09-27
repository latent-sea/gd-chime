extends "res://demo/demo_theme.gd"

const Charts := preload("res://addons/gd_chime/theme_charts.gd")

## GLASSMORPHISM. Frosted panes floating over a vivid ground: every surface
## is a translucent white fill with the ground blurred behind it, a hairline
## of light along its edge, and depth read only from how the panes stack.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Its rules: the ground must be saturated or the frost has nothing to
## show; a pane is white at a tenth to a sixth alpha with a generous
## radius; a border is one pixel of white at about a third alpha, never a
## line of ink; a state is a change of translucency, not of hue, except the
## glowing one, which warms. Its famous weakness is contrast - white words
## on a pane whose brightness is whatever happens to be behind it - and its
## frost is as thin as it is because of it: PANES STACK, and at the alphas
## this look began with, three deep made a lilac light enough that neither
## white nor its soft ink stood out on it (faint_words.gd). So each is
## about six tenths of what it was, and the soft ink is nearly white.

const PALETTE := {
	&"ground": Color("#2b1e6e"),
	&"raised": Color(1.0, 1.0, 1.0, 0.10),
	&"lit": Color(1.0, 1.0, 1.0, 0.16),
	&"ink": Color("#ffffff"),
	&"ink_soft": Color(1.0, 1.0, 1.0, 0.88),
	&"accent": Color("#ffb066"),
	&"shade": Color(0.10, 0.06, 0.28, 0.55),
}
const WHITE := Color("#ffffff")
## The frost: a pane's fill, the lighter one under a pointer, the clearer one refused.
const PANE := Color(1.0, 1.0, 1.0, 0.09)
const PANE_LIT := Color(1.0, 1.0, 1.0, 0.15)
const PANE_CLEAR := Color(1.0, 1.0, 1.0, 0.06)
## The sheet the flaps rest on: the panel of screens, frosted thicker than a flap.
const SHEET := Color(1.0, 1.0, 1.0, 0.11)
## The edges: a hairline of light, and the brighter one a focus draws.
const EDGE := Color(1.0, 1.0, 1.0, 0.35)
const EDGE_BRIGHT := Color(1.0, 1.0, 1.0, 0.85)
## The warm tint the one prompted thing is lit with, and its brighter rim.
const WARM := Color(1.0, 0.78, 0.50, 0.58)
const WARM_EDGE := Color(1.0, 0.90, 0.72, 1.0)
## The soft ink a refused pane's words are written in.
const INK_FAINT := Color(1.0, 1.0, 1.0, 0.45)


func _init() -> void:
	super(PALETTE)
	var sans := Look.font(["Segoe UI", "Trebuchet MS", "Verdana"])
	var light := Look.font(["Segoe UI", "Trebuchet MS", "Verdana"], {weight = 300})
	var heavy := Look.font(["Segoe UI", "Trebuchet MS", "Verdana"], {weight = 600})
	_pressables()
	_grounds()
	_words(sans, light, heavy)
	_lines()
	# the toggle's two looks and the inline options', from this look's own pressable: on and chosen are marked
	Look.toggle(self, &"accent")
	# frosted glass has no edge to snap on: everything arrives and leaves as one long soft fade
	moves({&"quick": 180, &"normal": 420, &"slow": 700, Motion.STAGGER: 70}, {Motion.ENTER: [Tween.TRANS_SINE, Tween.EASE_OUT, &"normal"], Motion.EXIT: [Tween.TRANS_SINE, Tween.EASE_IN, &"normal"], Motion.MOVE: [Tween.TRANS_SINE, Tween.EASE_IN_OUT, &"slow"], Motion.EMPHASIS: [Tween.TRANS_SINE, Tween.EASE_IN_OUT, &"slow"], Motion.RESTYLE: [Tween.TRANS_SINE, Tween.EASE_IN_OUT, &"normal"]}, {&"when": Transition.FADE, &"each": Transition.FADE})



## Every pressable: frosted glass at four depths of translucency, each with
## a hairline edge, the prompted one warmed and rimmed brighter.
func _pressables() -> void:
	# the base pressable: a pane of frost, lighter under a pointer, clearer when refused, warm when prompted
	var boxes := {
		&"normal": _pane(PANE, 14.0, EDGE, 12.0),
		&"hover": _pane(PANE_LIT, 14.0, EDGE_BRIGHT, 12.0),
		&"inert": _pane(PANE_CLEAR, 14.0, Color(1.0, 1.0, 1.0, 0.18), 12.0),
		&"glowing": _pane(WARM, 14.0, WARM_EDGE, 12.0),
	}
	var inks := {&"normal": WHITE, &"hover": WHITE, &"inert": INK_FAINT, &"glowing": WHITE}
	Look.pressable(self, Themes.PRESSABLE, boxes, {inks = inks, focus = Look.ring(EDGE_BRIGHT, {width = 2.0, radius = 14.0, inset = 3.0}), base = &"Control"})
	# a tab: a flap of glass resting on the panel it reveals - a fainter frost than the panel, a hairline of light around its top corners
	Look.pressable(self, &"Tab", {
		&"normal": Look.flap(Color(1.0, 1.0, 1.0, 0.08), {radius = 14.0, pad_top = 10.0, pad = 10.0, border = 1.0, border_colour = Color(1.0, 1.0, 1.0, 0.22)}),
		&"hover": Look.flap(Color(1.0, 1.0, 1.0, 0.15), {radius = 14.0, pad_top = 10.0, pad = 10.0, border = 1.0, border_colour = EDGE_BRIGHT}),
		&"inert": Look.flap(PANE_CLEAR, {radius = 14.0, pad_top = 10.0, pad = 10.0, border = 1.0, border_colour = Color(1.0, 1.0, 1.0, 0.16)}),
		&"glowing": Look.flap(WARM, {radius = 14.0, pad_top = 10.0, pad = 10.0, border = 1.0, border_colour = WARM_EDGE}),
		# the flap you are on: the panel's own frost, padded taller, so it stands up out of the strip and merges into the sheet with no seam
		&"current": Look.flap(SHEET, {radius = 14.0, pad_top = 22.0, pad = 10.0, border = 1.0, border_colour = EDGE}),
	}, {inks = {&"normal": PALETTE[&"ink_soft"], &"hover": WHITE, &"inert": INK_FAINT, &"glowing": WHITE, &"current": WHITE}, focus = Look.ring(EDGE_BRIGHT, {width = 2.0, radius = 14.0, inset = 2.0})})
	# a chip: the smallest pane, a pill
	Look.pressable(self, &"Chip", {
		&"normal": _pane(Color(1.0, 1.0, 1.0, 0.12), 16.0, EDGE, 8.0),
		&"hover": _pane(PANE_LIT, 16.0, EDGE_BRIGHT, 8.0),
		&"inert": _pane(PANE_CLEAR, 16.0, Color(1.0, 1.0, 1.0, 0.16), 8.0),
		&"glowing": _pane(WARM, 16.0, WARM_EDGE, 8.0),
	}, {inks = {&"normal": WHITE, &"hover": WHITE, &"inert": INK_FAINT, &"glowing": WHITE}, focus = Look.ring(EDGE_BRIGHT, {width = 2.0, radius = 16.0, inset = 2.0})})
	# an inline word: no pane at all, a rule of light under it instead
	Look.pressable(self, &"NavInline", {
		&"normal": Look.layered(self, [Paint.underline(Paint.faded(&"ink", 0.3), 1.0, 2.0)], 8.0),
		&"hover": Look.layered(self, [Paint.underline(&"ink", 2.0, 2.0)], 8.0),
		&"inert": Look.layered(self, [], 8.0),
		&"glowing": Look.layered(self, [Paint.underline(Paint.mixed(&"accent", &"ink", 0.45), 2.0, 2.0)], 8.0),
	}, {inks = {&"normal": PALETTE[&"ink_soft"], &"hover": WHITE, &"inert": INK_FAINT, &"glowing": PALETTE[&"accent"]}, focus = Look.ring(EDGE_BRIGHT, {width = 2.0, radius = 8.0, inset = 2.0})})
	# the card-shaped pressables: bigger panes, more air inside, a wider radius
	for card: StringName in [&"CardList", &"CardTile", &"CardDense"]:
		Look.pressable(self, card, {
			&"normal": _pane(PANE, 16.0, EDGE, 16.0),
			&"hover": _pane(PANE_LIT, 16.0, EDGE_BRIGHT, 16.0),
			&"inert": _pane(PANE_CLEAR, 16.0, Color(1.0, 1.0, 1.0, 0.18), 16.0),
			&"glowing": _pane(WARM, 16.0, WARM_EDGE, 16.0),
		}, {inks = {&"normal": WHITE, &"hover": WHITE, &"inert": INK_FAINT, &"glowing": WHITE}, focus = Look.ring(EDGE_BRIGHT, {width = 2.0, radius = 16.0, inset = 3.0})})


## Every ground: a frosted pane over the blurred vivid ground, the deeper
## the stack the more it frosts.
func _grounds() -> void:
	# the plain surface: the faintest frost, no blur, so a pane inside a pane still separates
	Look.ground(self, Themes.SURFACE, _pane(Color(1.0, 1.0, 1.0, 0.10), 14.0, Color(1.0, 1.0, 1.0, 0.22), 14.0))
	# a captioned box: the first frosted layer off the ground
	Look.ground(self, Themes.RAISED, _pane(PANE, 16.0, EDGE, 18.0), 3)
	# a card: a second pane stacked on the first, lighter so the stack reads
	Look.ground(self, Themes.CARD, _pane(Color(1.0, 1.0, 1.0, 0.13), 14.0, Color(1.0, 1.0, 1.0, 0.28), 14.0), 2)
	# the pop-up, and a question's sheet over the screen: the thickest frost of all, the moment held closest to the eye
	for held: StringName in [PANEL, CONFIRM]:
		Look.ground(self, held, _pane(Color(1.0, 1.0, 1.0, 0.20), 16.0, EDGE_BRIGHT, 26.0), 4)
	# the shade behind a pop-up: the ground's own violet, darkened, not frosted
	Look.ground(self, SHADE, Look.flat(PALETTE[&"shade"]))
	# the quieter grounds: a clearer pane, so a stack of three does not wash out
	for clear: StringName in [&"CardEmpty", &"Collection", &"Board", &"Matrix", &"Graph", &"Countdown", &"Bubble", &"Moment"]:
		Look.ground(self, clear, _pane(Color(1.0, 1.0, 1.0, 0.10), 14.0, Color(1.0, 1.0, 1.0, 0.24), 14.0))
	# the panel the flaps rest on: the widest pane of all, blurred hardest, rounded everywhere but its top left where the first flap lands
	Look.ground(self, &"TabPanel", Look.flat(SHEET, {radius = 16.0, border = 1.0, border_colour = EDGE, pad = 18.0}), 4)
	# a pane of an application shell: the plain surface's frost, so the panes of a console float as the rest do
	Look.ground(self, &"Pane", _pane(Color(1.0, 1.0, 1.0, 0.10), 14.0, Color(1.0, 1.0, 1.0, 0.22), 14.0))
	# a tile of a status wall: the chip's pill of frost, its hairline and its fill, with no halo - five hundred halos would fog the wall
	Look.pressable(self, &"WallTile", {
		&"normal": Look.flat(Color(1.0, 1.0, 1.0, 0.12), {radius = 16.0, border = 1.0, border_colour = EDGE, pad = 8.0}),
		&"hover": Look.flat(PANE_LIT, {radius = 16.0, border = 1.0, border_colour = EDGE_BRIGHT, pad = 8.0}),
		&"inert": Look.flat(PANE_CLEAR, {radius = 16.0, border = 1.0, border_colour = Color(1.0, 1.0, 1.0, 0.16), pad = 8.0}),
		&"glowing": Look.flat(WARM, {radius = 16.0, border = 1.0, border_colour = WARM_EDGE, pad = 8.0}),
	}, {inks = {&"normal": WHITE, &"hover": WHITE, &"inert": INK_FAINT, &"glowing": WHITE}, focus = Look.ring(EDGE_BRIGHT, {width = 2.0, radius = 16.0, inset = 2.0})})
	# the text field: a sunken pane, darker than what is around it, so it reads as a hole
	Look.field(self, &"Field", {normal = _pane(Color(0.0, 0.0, 0.0, 0.18), 12.0, Color(1.0, 1.0, 1.0, 0.30), 12.0), focus = _pane(Color(0.0, 0.0, 0.0, 0.10), 12.0, Color(1.0, 1.0, 1.0, 0.85), 12.0)}, Color.WHITE)


## The words: one humanist sans, white on every pane, weight and not colour
## carrying the hierarchy, because a coloured ink dies on translucent frost.
func _words(sans: Font, light: Font, heavy: Font) -> void:
	set_default_font(sans)
	default_font_size = 24
	for kind: StringName in [Themes.FACE, Themes.REASON, Themes.WORDS, READOUT, LINE, Themes.TITLE, Themes.NUMBER]:
		set_color(&"font_color", kind, WHITE)
	Look.words(self, Themes.FACE, 26, {font = sans, colour = WHITE})
	Look.words(self, Themes.REASON, 19, {font = sans, colour = PALETTE[&"ink_soft"]})
	Look.words(self, Themes.WORDS, 34, {font = light, colour = WHITE})
	Look.words(self, Themes.TITLE, 22, {font = heavy, colour = WHITE})
	Look.words(self, READOUT, 21, {font = sans, colour = PALETTE[&"ink_soft"]})
	Look.words(self, LINE, 23, {font = sans, colour = WHITE})
	# the big number: thin and luminous, the way glass wants a headline
	Look.words(self, Themes.NUMBER, 92, {font = light, colour = WHITE})
	# every drawn line: white, the graph's links fainter, both readable over frost
	for drawn: StringName in Charts.DRAWN:
		set_color(&"line", drawn, Color(1.0, 1.0, 1.0, 0.85))
	set_color(&"link", &"Graph", Color(1.0, 1.0, 1.0, 0.35))


## The lines: generous gaps, because panes need the ground to show between
## them or there is no colour left for the frost to pick up.
func _lines() -> void:
	for line: StringName in [Themes.ROW, Themes.COLUMN]:
		set_constant(&"gap", line, 16)
	Look.line(self, Themes.TILES, Themes.ROW, {gap = 16})
	Look.line(self, &"Chips", Themes.ROW, {gap = 10})
	# the flaps: a thread of ground between them, bottom-aligned so the current one grows upward off the sheet, and the two as one thing
	Look.line(self, &"TabStrip", Themes.ROW, {gap = 6, justify = Look.START, align = Look.END})
	Look.line(self, &"TabSet", Themes.COLUMN, {gap = 0})
	Look.line(self, &"Controls", Themes.ROW, {gap = 14, justify = Look.END})
	# the instruction bar: its words centred on their own pane
	Look.line(self, &"InstructionBar", Themes.ROW, {gap = 16, justify = Look.CENTER, align = Look.CENTER})


## A pane of frost: a translucent white fill at a radius, a hairline edge of
## light, and a soft dark halo standing it off whatever is behind it.
func _pane(fill: Color, radius: float, edge: Color, pad: float) -> StyleBox:
	return Look.flat(fill, {radius = radius, border = 1.0, border_colour = edge, shadow = 10.0, shadow_colour = Color(0.04, 0.02, 0.15, 0.30), shadow_offset = Vector2(0.0, 4.0), pad = pad})
