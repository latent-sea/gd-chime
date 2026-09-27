extends "res://demo/demo_theme.gd"

const Charts := preload("res://addons/gd_chime/theme_charts.gd")

## DATA-DENSE. Tufte's rule taken literally: every drop of ink on the page
## should be data. No fill, no border, no shadow, no rounding, no texture -
## chartjunk, all of it. Structure is whitespace and alignment; the only
## chrome is the typeface itself, set small and tight so more of what
## matters fits in one eyeful.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A state is a change of ink, never a block of colour: ordinary words are
## near-black, hovered and prompted words take the one muted signal colour,
## refused words go warm grey, and the prompt earns a single hairline under
## it. Separation, where it is needed at all, is one hairline rule; the only
## box in the language is the pop-up sheet, which must lift off the page.
## The cost is affordance - nothing announces itself as pressable until the
## pointer is over it - which is the price of a page that reads as a table.

const PALETTE := {
	&"ground": Color("#fbfaf7"),
	&"raised": Color("#fbfaf7"),
	&"lit": Color("#efece4"),
	&"ink": Color("#16150f"),
	&"ink_soft": Color("#6e6960"),
	&"accent": Color("#1a5b5e"),
	&"shade": Color(0.98, 0.98, 0.97, 0.72),
	# the hairline every row and every panel is ruled with: named, because it is painted, and a painter reads its colour from the palette as it draws
	&"rule": Color("#d8d3c8"),
}
const TEAL := Color("#1a5b5e")
const TEAL_DEEP := Color("#0f4042")
const WHITE := Color("#ffffff")


func _init() -> void:
	super(PALETTE)
	# the type: one dense sans at every size, and a hairline scale of gaps
	var sans := Look.font(["Segoe UI", "Verdana", "Tahoma", "Arial"])
	var sans_bold := Look.font(["Segoe UI", "Verdana", "Tahoma", "Arial"], 700)
	set_default_font(sans)
	default_font_size = 15
	_press(sans)
	_words(sans, sans_bold)
	_surfaces()
	_lines()
	# the toggle's two looks and the inline options', from this look's own pressable: on and chosen are marked
	Look.toggle(self, &"accent")
	# a dense table is read, not watched: motion is as near to none as it can be without the screen jumping
	moves({&"quick": 30, &"normal": 60, &"slow": 90, Motion.STAGGER: 0}, {Motion.ENTER: [Tween.TRANS_LINEAR, Tween.EASE_IN, &"quick"], Motion.EXIT: [Tween.TRANS_LINEAR, Tween.EASE_IN, &"quick"], Motion.MOVE: [Tween.TRANS_LINEAR, Tween.EASE_IN, &"quick"], Motion.EMPHASIS: [Tween.TRANS_LINEAR, Tween.EASE_IN, &"normal"], Motion.RESTYLE: [Tween.TRANS_LINEAR, Tween.EASE_IN, &"quick"]}, {&"when": Transition.FADE, &"each": Transition.FADE})



## A pressable: no block in any state; the state is the colour of the
## words, and the prompt alone is underscored.
func _press(sans: Font) -> void:
	# a dotted hairline ring, just inside the edge, for the focus
	var focus := Look.layered(self, [Paint.dashed(&"ink_soft", 1.0, 3.0, 3.0)])
	var boxes := {
		&"normal": Look.layered(self, [], 7.0),
		&"hover": Look.layered(self, [], 7.0),
		&"inert": Look.layered(self, [], 7.0),
		# the one thing to press: a thin rule under the words
		&"glowing": Look.layered(self, [Paint.underline(&"accent", 1.0, 3.0)], 7.0),
	}
	var inks := {&"normal": PALETTE[&"ink"], &"hover": TEAL, &"inert": PALETTE[&"ink_soft"], &"glowing": TEAL_DEEP}
	Look.pressable(self, Themes.PRESSABLE, boxes, inks, focus, &"Control")
	# the tabs: words on one hairline running the width, the current one on
	# a thicker teal stroke in the deep ink - the rule breaks, so the word
	# you are on reads as the heading of the panel below it, not as a button
	var tab_inks := {&"normal": PALETTE[&"ink_soft"], &"hover": TEAL, &"inert": PALETTE[&"ink_soft"], &"glowing": TEAL_DEEP, &"current": TEAL_DEEP}
	Look.pressable(self, &"Tab", {
		&"normal": Look.layered(self, [Paint.underline(&"rule", 1.0)], 6.0),
		&"hover": Look.layered(self, [Paint.underline(Paint.mixed(&"accent", &"ground", 0.5), 1.0)], 6.0),
		&"inert": Look.layered(self, [Paint.underline(&"rule", 1.0)], 6.0),
		&"glowing": Look.layered(self, [Paint.underline(&"accent", 1.0)], 6.0),
		&"current": Look.layered(self, [Paint.underline(&"accent", 2.0)], 6.0),
	}, tab_inks, focus)
	# a row of a table: the pointer marks it with a faint tint, the only fill in the language
	for listed: StringName in [&"CardList", &"CardDense", &"Relative"]:
		Look.pressable(self, listed, {
			&"normal": Look.layered(self, [], 6.0),
			&"hover": Look.layered(self, [Look.flat(PALETTE[&"lit"])], 6.0),
			&"inert": Look.layered(self, [], 6.0),
			&"glowing": Look.layered(self, [Paint.left_bar(&"accent", 2.0)], 6.0),
		}, inks, focus)
	# a chip and an inline word: smaller still, and one that is set reads ruled
	for bare: StringName in [&"Chip", &"NavInline", &"Choice", &"Picker"]:
		Look.pressable(self, bare, {
			&"normal": Look.layered(self, [], 4.0),
			&"hover": Look.layered(self, [Paint.underline(&"accent", 1.0, 1.0)], 4.0),
			&"inert": Look.layered(self, [], 4.0),
			&"glowing": Look.layered(self, [Paint.underline(&"accent", 1.0, 1.0)], 4.0),
		}, inks, focus)
		set_font_size(&"font_size", bare, 13)
		set_font(&"font", bare, sans)


## The kinds of words: small, dense, and near-black, with the warm grey
## kept for what only explains.
func _words(sans: Font, sans_bold: Font) -> void:
	# plain words, of no named kind, in the ink: the page is read, not decorated
	set_color(&"font_color", &"Label", PALETTE[&"ink"])
	set_font_size(&"font_size", &"Label", 15)
	for kind: StringName in [Themes.FACE, Themes.REASON, Themes.WORDS, READOUT, LINE, Themes.TITLE, Themes.NUMBER]:
		set_color(&"font_color", kind, PALETTE[&"ink"])
	Look.words(self, Themes.FACE, 17, sans, PALETTE[&"ink"])
	Look.words(self, Themes.REASON, 13, sans, PALETTE[&"ink_soft"])
	Look.words(self, Themes.WORDS, 26, sans, PALETTE[&"ink"])
	Look.words(self, Themes.TITLE, 16, sans_bold, PALETTE[&"ink"])
	Look.words(self, READOUT, 15, sans, PALETTE[&"ink"])
	Look.words(self, LINE, 15, sans, PALETTE[&"ink"])
	# the dial's number: still the loudest thing on the page, but set as a figure, not a poster
	Look.words(self, Themes.NUMBER, 52, Look.font(["Segoe UI", "Verdana", "Tahoma", "Arial"], 300), TEAL_DEEP)


## The grounds: the page itself, with a hairline where a rule genuinely
## separates, and one white box for the pop-up that must leave the page.
func _surfaces() -> void:
	Look.ground(self, Themes.SURFACE, Look.nothing())
	# the panel the tabs sit on: no box at all, so the page under the line is bare
	Look.ground(self, &"TabPanel", Look.nothing())
	# a captioned box: nothing but a rule along its foot and the air around it
	Look.ground(self, Themes.RAISED, Look.layered(self, [Paint.underline(&"rule", 1.0)], 10.0))
	Look.ground(self, Themes.CARD, Look.layered(self, [Paint.underline(&"rule", 1.0)], 8.0))
	for bare: StringName in [&"CardEmpty", &"Collection", &"Board", &"Matrix", &"Moment", &"Graph", &"Countdown", &"Bubble"]:
		Look.ground(self, bare, Look.layered(self, [], 6.0))
	# the shade under a pop-up: the page washed out, never darkened
	Look.ground(self, SHADE, Look.flat(PALETTE[&"shade"]))
	# the sheet: a plain white box on one hairline border - the only box drawn
	Look.ground(self, PANEL, Look.flat(WHITE, {border = 1.0, border_colour = PALETTE[&"ink_soft"], pad = 18.0}))
	# a text field: a rule to write a figure on, never a box
	set_type_variation(&"Field", &"LineEdit")
	set_stylebox(&"normal", &"Field", Look.layered(self, [Paint.underline(&"ink_soft", 1.0)], 6.0))
	set_stylebox(&"focus", &"Field", Look.layered(self, [Paint.underline(&"accent", 1.0)], 6.0))
	set_color(&"font_color", &"Field", PALETTE[&"ink"])
	set_color(&"caret_color", &"Field", TEAL)
	set_font_size(&"font_size", &"Field", 15)


## The lines: tight gaps throughout, and every drawn mark a thin teal
## stroke - the data, and nothing around it.
func _lines() -> void:
	for line: StringName in [Themes.ROW, Themes.COLUMN, Themes.TILES]:
		set_constant(&"gap", line, 7)
	Look.line(self, TIGHT, Themes.COLUMN, 2)
	Look.line(self, Themes.CENTRED, Themes.ROW, 8, Look.CENTER)
	Look.line(self, &"Chips", Themes.TILES, 6)
	# the strip: words spaced along one line, sitting on its baseline
	Look.line(self, &"TabStrip", Themes.ROW, 14, Look.START, Look.END)
	Look.line(self, &"TabSet", Themes.COLUMN, 0)
	Look.line(self, &"MatrixLine", Themes.ROW, 6)
	Look.line(self, &"InstructionBar", Themes.ROW, 8, Look.BETWEEN, Look.CENTER)
	Look.line(self, &"Controls", Themes.ROW, 8, Look.END, Look.CENTER)
	Look.line(self, &"AmountField", Themes.ROW, 6, Look.START, Look.CENTER)
	Look.line(self, &"Outcomes", Themes.COLUMN, 6)
	Look.line(self, &"FilterSet", Themes.ROW, 8, Look.START, Look.CENTER)
	Look.line(self, &"Disposition", Themes.ROW, 8, Look.BETWEEN, Look.CENTER)
	set_constant(&"gap", Themes.GRID, 8)
	set_constant(&"row_gap", Themes.GRID, 8)
	for drawn: StringName in Charts.DRAWN:
		set_color(&"line", drawn, TEAL)
	# a filled bar is a lot of ink for one number, so it is drawn as a wash of the signal colour
	set_color(&"line", &"Bar", TEAL.lerp(PALETTE[&"ground"], 0.6))
	set_color(&"link", &"Graph", PALETTE[&"rule"])
	# the pulse: barely a breath, so nothing on the page moves for decoration
	set_constant(&"depth", Themes.PULSE, 25)
