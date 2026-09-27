extends "res://demo/demo_theme.gd"

const Charts := preload("res://addons/gd_chime/theme_charts.gd")

## SWISS / INTERNATIONAL TYPOGRAPHIC STYLE. The grid, the sans-serif and
## the empty space do all the work: no boxes, no gradients, no ornament
## except the type itself, set in one family at sizes far apart.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## White ground, black ink, one red. A thing is not a panel with a name in
## it - it is a name, at the size its importance deserves, with a hairline
## under it if it must be separated at all. State is a change of ink, not a
## change of shape: black is available, red is live, grey is refused. The
## grey is the lightest one a caption may be written in and still stand out
## from the white and the near-white it is set on (faint_words.gd); a
## lighter one printed well and read badly. The
## weakness is affordance - nothing announces that it can be pressed - and
## the strength is that a screen full of these still reads as one page.

const PALETTE := {
	&"ground": Color("#ffffff"),
	&"raised": Color("#ffffff"),
	&"lit": Color("#f2f2f2"),
	&"ink": Color("#000000"),
	&"ink_soft": Color("#6e6e6e"),
	&"accent": Color("#e30613"),
	&"shade": Color(1.0, 1.0, 1.0, 0.82),
}
const GAP := 24


func _init() -> void:
	super(PALETTE)
	var black: Color = PALETTE[&"ink"]
	var red: Color = PALETTE[&"accent"]
	var grey: Color = PALETTE[&"ink_soft"]
	# a pressable: words alone - black available, red live, grey refused; the glow a red bar down the left edge
	var boxes := {&"normal": _air(10.0), &"hover": _air(10.0), &"inert": _air(10.0), &"glowing": Look.layered(self, [Paint.left_bar(&"accent", 4.0)], 10.0)}
	var inks := {&"normal": black, &"hover": red, &"inert": grey, &"glowing": black}
	Look.pressable(self, Themes.PRESSABLE, boxes, {inks = inks, focus = Look.layered(self, [Paint.underline(&"ink", 1.0)], 10.0), base = &"Control"})
	# a tab: typographic - grey words in a line, no flap and no fill; the one you are on is black with a red rule broken under it
	var tab_boxes := {&"normal": _air(8.0), &"hover": _air(8.0), &"inert": _air(8.0), &"glowing": _air(8.0), &"current": Look.layered(self, [Look.nothing(), Paint.rule(&"accent", 3.0, SIDE_BOTTOM)], 8.0)}
	var tab_inks := {&"normal": grey, &"hover": red, &"inert": grey, &"glowing": black, &"current": black}
	Look.pressable(self, &"Tab", tab_boxes, {inks = tab_inks, focus = Look.layered(self, [Paint.underline(&"ink", 1.0)], 8.0)})
	# no panel at all: the strip stands alone over the page, and the rule under the current word is the only join
	Look.ground(self, &"TabPanel", Look.nothing())
	# a chip and an inline link: the same words, tighter, and no rule at all when live
	for bare: StringName in [&"Chip", &"NavInline", &"Relative"]:
		Look.pressable(self, bare, {&"normal": _air(6.0), &"hover": _air(6.0), &"inert": _air(6.0), &"glowing": _air(6.0)}, {inks = {&"normal": black, &"hover": red, &"inert": grey, &"glowing": red}, focus = Look.layered(self, [Paint.underline(&"ink", 1.0)], 6.0)})
	# a tile, a row in a list, a choice: a hairline under each, so the grid shows without a single box
	for ruled: StringName in [&"CardList", &"CardTile", &"CardDense", &"Choice", &"Picker", &"NavPlay"]:
		var ruled_boxes := {&"normal": Look.layered(self, [Paint.underline(&"ink", 1.0)], 12.0), &"hover": Look.layered(self, [Paint.underline(&"accent", 1.0)], 12.0), &"inert": Look.layered(self, [Paint.underline(&"ink_soft", 1.0)], 12.0), &"glowing": Look.layered(self, [Paint.underline(&"accent", 1.0), Paint.left_bar(&"accent", 4.0)], 12.0)}
		Look.pressable(self, ruled, ruled_boxes, {inks = {&"normal": black, &"hover": red, &"inert": grey, &"glowing": black}, focus = Look.layered(self, [Paint.underline(&"ink", 2.0)], 12.0)})
	_type(black, red, grey)
	_grounds()
	_lines()
	_dashboard(black, red, grey)
	# the toggle's two looks and the inline options', from this look's own pressable: on and chosen are marked
	Look.toggle(self, &"accent")
	# the international style moves as little as it can and never for effect: a short straight fade, and nothing slides
	moves({&"quick": 70, &"normal": 140, &"slow": 220, Motion.STAGGER: 25}, {Motion.ENTER: [Tween.TRANS_LINEAR, Tween.EASE_IN, &"quick"], Motion.EXIT: [Tween.TRANS_LINEAR, Tween.EASE_IN, &"quick"], Motion.MOVE: [Tween.TRANS_SINE, Tween.EASE_IN_OUT, &"normal"], Motion.EMPHASIS: [Tween.TRANS_SINE, Tween.EASE_OUT, &"normal"], Motion.RESTYLE: [Tween.TRANS_LINEAR, Tween.EASE_IN, &"quick"]}, {&"when": Transition.FADE, &"each": Transition.FADE})



## Padding and nothing drawn: the empty space that is the whole language.
func _air(pad: float) -> StyleBox:
	return Look.layered(self, [], pad)


## The type scale: one grotesque, and sizes far enough apart that scale alone ranks the page.
func _type(black: Color, red: Color, grey: Color) -> void:
	var sans := Look.font(["Helvetica", "Arial", "Segoe UI"])
	var bold := Look.font(["Helvetica", "Arial", "Segoe UI"], {weight = 700})
	set_default_font(sans)
	default_font_size = 18
	# plain words with no kind of their own: black, or the engine's white leaves them invisible on the paper
	set_color(&"font_color", &"Label", black)
	for kind: StringName in [Themes.FACE, Themes.REASON, Themes.WORDS, READOUT, LINE, Themes.TITLE, Themes.NUMBER]:
		set_color(&"font_color", kind, black)
	# the instruction: the largest thing on the page by a long way
	Look.words(self, Themes.WORDS, 48, {font = bold, colour = black})
	Look.words(self, Themes.TITLE, 28, {font = bold, colour = black})
	Look.words(self, Themes.FACE, 24, {font = sans, colour = black})
	Look.words(self, Themes.REASON, 16, {font = sans, colour = grey})
	Look.words(self, READOUT, 18, {font = sans, colour = black})
	Look.words(self, LINE, 18, {font = sans, colour = black})
	# a dial's number: the one place the red is allowed to be enormous
	Look.words(self, Themes.NUMBER, 96, {font = bold, colour = red})


## The grounds: white, and mostly nothing - a captioned box is a rule, not a panel.
func _grounds() -> void:
	Look.ground(self, Themes.SURFACE, Look.nothing())
	Look.ground(self, Themes.RAISED, Look.layered(self, [Paint.underline(&"ink", 1.0)], 16.0))
	for bare: StringName in [&"Card", &"Bubble", &"CardEmpty", &"Collection", &"Board", &"Matrix", &"Moment", &"Graph", &"Countdown"]:
		Look.ground(self, bare, _air(12.0))
	# the text field: a line to type on, not a box - the engine's own field, given a rule and no fill
	set_type_variation(&"Field", &"LineEdit")
	set_stylebox(&"normal", &"Field", Look.layered(self, [Paint.underline(&"ink", 2.0)], 8.0))
	set_stylebox(&"focus", &"Field", Look.layered(self, [Paint.underline(&"accent", 2.0)], 8.0))
	set_color(&"font_color", &"Field", PALETTE[&"ink"])
	set_color(&"caret_color", &"Field", PALETTE[&"accent"])
	Look.ground(self, Themes.CARD, _air(12.0))
	Look.ground(self, SHADE, Look.flat(PALETTE[&"shade"]))
	# a pop-up: white on white, held apart by a full hairline frame and a lot of air
	Look.ground(self, PANEL, Look.flat(PALETTE[&"raised"], {border = 1.0, border_colour = PALETTE[&"ink"], pad = 32.0}))


## The grid: one generous gap everywhere, so the whitespace is a measure and not a leftover.
func _lines() -> void:
	for line: StringName in [Themes.ROW, Themes.COLUMN, Themes.TILES, Themes.GRID]:
		set_constant(&"gap", line, GAP)
	set_constant(&"row_gap", Themes.GRID, GAP)
	for tight: StringName in [TIGHT, &"MatrixLine", &"Chips"]:
		Look.line(self, tight, Themes.COLUMN if tight == TIGHT else Themes.ROW, {gap = 8})
	# the instruction bar and the tab bar: asymmetric - everything from the left edge
	Look.line(self, &"InstructionBar", Themes.ROW, {gap = GAP, justify = Look.START, align = Look.CENTER})
	Look.line(self, &"TabStrip", Themes.ROW, {gap = GAP + 8, justify = Look.START, align = Look.END})
	Look.line(self, &"TabSet", Themes.COLUMN, {gap = 0})
	Look.line(self, &"Controls", Themes.ROW, {gap = GAP, justify = Look.START, align = Look.CENTER})
	for drawn: StringName in Charts.DRAWN:
		set_color(&"line", drawn, PALETTE[&"ink"])
	set_color(&"link", &"Graph", PALETTE[&"accent"])
	set_constant(&"depth", Themes.PULSE, 40)


## A dashboard's pieces (theme_charts.gd) in the same terms: a figure is a
## big bold number under its name, a hairline under the whole; a bar is
## words alone and a region's name words on a scrap of the paper, the one
## picked marked by the red bar the glow is; the stretch before is the one
## red tick in a chart of black.
func _dashboard(black: Color, red: Color, grey: Color) -> void:
	var sans := Look.font(["Helvetica", "Arial", "Segoe UI"])
	var bold := Look.font(["Helvetica", "Arial", "Segoe UI"], {weight = 700})
	Look.words(self, &"KpiFigure", 48, {font = bold, colour = black})
	Look.words(self, &"KpiSays", 16, {font = sans, colour = grey})
	Look.words(self, &"KpiChange", 18, {font = sans, colour = black})
	Look.words(self, &"BarChartWords", 18, {font = sans, colour = black})
	Look.words(self, &"Empty", 16, {font = sans, colour = grey})
	Look.words(self, &"RegionMapName", 16, {font = sans, colour = black})
	# a figure: the ruled tile's hairline under it, red when hovered, the glow's bar when live
	var ruled := {&"normal": Look.layered(self, [Paint.underline(&"ink", 1.0)], 12.0), &"hover": Look.layered(self, [Paint.underline(&"accent", 1.0)], 12.0), &"inert": Look.layered(self, [Paint.underline(&"ink_soft", 1.0)], 12.0), &"glowing": Look.layered(self, [Paint.underline(&"accent", 1.0), Paint.left_bar(&"accent", 4.0)], 12.0)}
	Look.pressable(self, &"KpiCard", ruled, {inks = {&"normal": black, &"hover": red, &"inert": grey, &"glowing": black}, focus = Look.layered(self, [Paint.underline(&"ink", 2.0)], 12.0)})
	# a bar: words alone, the one picked marked by the red bar down its left
	var bar_boxes := {&"normal": _air(6.0), &"hover": _air(6.0), &"inert": _air(6.0), &"glowing": _air(6.0), &"current": Look.layered(self, [Paint.left_bar(&"accent", 4.0)], 6.0)}
	Look.pressable(self, &"BarChartBar", bar_boxes, {inks = {&"normal": black, &"hover": red, &"inert": grey, &"glowing": red, &"current": black}, focus = Look.layered(self, [Paint.underline(&"ink", 1.0)], 6.0)})
	# a region's name: black words on a scrap of the paper, so they read over any shade, the one picked with the red bar
	var paper := Look.flat(PALETTE[&"raised"], {pad = 6.0})
	var pin_boxes := {&"normal": paper, &"hover": paper, &"inert": paper, &"glowing": paper, &"current": Look.layered(self, [paper, Paint.left_bar(&"accent", 4.0)], 6.0)}
	Look.pressable(self, &"RegionMapPin", pin_boxes, {inks = {&"normal": black, &"hover": red, &"inert": grey, &"glowing": red, &"current": black}, focus = Look.layered(self, [Paint.underline(&"ink", 1.0)], 6.0)})
	# a bar in black, the stretch before's tick across it the one red
	set_color(&"link", &"BarChartTrack", red)
	Look.line(self, &"DateRange", Themes.ROW, {gap = GAP, justify = Look.START, align = Look.CENTER})
	set_constant(&"wrap", &"DateRange", 1)
