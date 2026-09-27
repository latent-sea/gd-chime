extends "res://demo/demo_theme.gd"

const Pressables := preload("res://addons/gd_chime/theme_pressables.gd")
const Charts := preload("res://addons/gd_chime/theme_charts.gd")

## BENTO GRID. The product page as a tray of compartments: every part of a
## screen is a self-contained rounded cell, white on a soft neutral ground,
## separated by one generous gutter that never varies.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Nothing is framed by a heavy edge and nothing floats on a shadow. A cell
## is told apart from the ground by its own fill and a border so faint it
## reads as a seam. Hierarchy is carried by how much of the tray a cell
## takes and by one bold block of colour per section: a single deep indigo
## for the thing to press, a pastel fill for a cell that is merely context.
## Near-black ink, grey for the second voice, and nothing else.

const PALETTE := {
	&"ground": Color("#f3f4f6"),
	&"raised": Color("#ffffff"),
	&"lit": Color("#e5e7eb"),
	&"ink": Color("#111111"),
	&"ink_soft": Color("#5f6572"),
	&"accent": Color("#4338ca"),
	&"shade": Color(0.07, 0.07, 0.09, 0.45),
}
const WHITE := Color("#ffffff")
const SEAM := Color("#d8dae0")
const PALE := Color("#f3f4f6")
const PASTEL := Color("#eef2ff")
const INDIGO := Color("#4338ca")
const INDIGO_GLOW := Color(0.26, 0.22, 0.79, 0.35)
## The one radius family: a cell, and a pill (any number past half the height).
const CELL := 22.0
const PILL := 40.0
## The one gutter, everywhere.
const GUTTER := 16


func _init() -> void:
	super(PALETTE)
	var sans := Look.font(["Segoe UI", "Helvetica", "Arial"])
	var bold := Look.font(["Segoe UI", "Helvetica", "Arial"], 700)
	_pressables()
	_cells()
	_type(sans, bold)
	_lines()
	# the toggle's two looks and the inline options', from this look's own pressable: on and chosen are marked
	Look.toggle(self, &"accent")
	# browsing a collection - pictures, facets, a gallery, a quick view, the drawers - as more compartments of the tray
	preload("res://demo/gallery/looks/bento_browsing.gd").dress(self, {"white": WHITE, "seam": SEAM, "pale": PALE, "pastel": PASTEL, "indigo": INDIGO, "glow": INDIGO_GLOW, "ink": PALETTE[&"ink"], "soft": PALETTE[&"ink_soft"], "shade": PALETTE[&"shade"], "cell": CELL, "pill": PILL, "gutter": GUTTER, "bold": bold})
	# a tile is an object with weight: it springs into its box, and a wall of them lands one after another
	moves({&"quick": 120, &"normal": 280, &"slow": 520, Motion.STAGGER: 90}, {Motion.ENTER: [Tween.TRANS_BACK, Tween.EASE_OUT, &"normal"], Motion.EXIT: [Tween.TRANS_CUBIC, Tween.EASE_IN, &"quick"], Motion.MOVE: [Tween.TRANS_BACK, Tween.EASE_OUT, &"normal"], Motion.EMPHASIS: [Tween.TRANS_ELASTIC, Tween.EASE_OUT, &"slow"], Motion.RESTYLE: [Tween.TRANS_CUBIC, Tween.EASE_OUT, &"quick"]}, {&"when": Transition.FADE, &"each": Transition.SCALE})



## Every pressable is a filled pill: white with a seam normally, pale grey
## under the cursor, pale with grey ink when refused, and the one indigo
## block when it is the thing to press. The focus is a two-pixel ring.
func _pressables() -> void:
	var focus := Look.ring(INDIGO, {width = 2.0, radius = PILL, inset = 2.0})
	Look.pressable(self, Themes.PRESSABLE, _pill_boxes(14.0), _pill_inks(), focus, &"Control")
	# a bell button: the same pill with more air around its word
	Look.pressable(self, Pressables.BUTTON, _pill_boxes(18.0), _pill_inks(), focus)
	# a chip, an inline link and a small picker: a tighter pill
	for small: StringName in [&"Chip", &"NavInline", &"Picker", &"Choice", &"Relative"]:
		Look.pressable(self, small, _pill_boxes(10.0), _pill_inks(), focus)
	# a tab: a pill flap on the top edge of the tray's main cell, white with the seam; the
	# one you are on is taller and drops its bottom seam, so it is that cell's own lip
	Look.pressable(self, &"Tab", {
		&"normal": _flap(WHITE, 10.0, true),
		&"hover": _flap(PASTEL, 10.0, true),
		&"inert": _flap(PALE, 10.0, true),
		&"glowing": _flap(PASTEL, 10.0, true),
		&"current": _flap(WHITE, 20.0, false),
	}, {&"normal": PALETTE[&"ink_soft"], &"hover": PALETTE[&"ink"], &"inert": PALETTE[&"ink_soft"], &"glowing": PALETTE[&"ink"], &"current": PALETTE[&"ink"]}, focus)
	# a play button in a nav: the indigo block whatever its state, since it is the one move
	Look.pressable(self, &"NavPlay", {
		&"normal": _glow_box(14.0),
		&"hover": Look.flat(INDIGO.darkened(0.15), {radius = PILL, pad = 14.0}),
		&"inert": Look.flat(PALE, {radius = PILL, border = 1.0, border_colour = SEAM, pad = 14.0}),
		&"glowing": _glow_box(14.0),
	}, {&"normal": WHITE, &"hover": WHITE, &"inert": PALETTE[&"ink_soft"], &"glowing": WHITE}, focus)
	# the pressables that are themselves cells in the tray: the cell radius, not the pill
	for tile: StringName in [&"CardList", &"CardTile", &"CardDense"]:
		Look.pressable(self, tile, {
			&"normal": Look.flat(WHITE, {radius = CELL, border = 1.0, border_colour = SEAM, pad = 16.0}),
			&"hover": Look.flat(PASTEL, {radius = CELL, border = 1.0, border_colour = SEAM, pad = 16.0}),
			&"inert": Look.flat(PALE, {radius = CELL, border = 1.0, border_colour = SEAM, pad = 16.0}),
			&"glowing": Look.flat(INDIGO, {radius = CELL, shadow = 12.0, shadow_colour = INDIGO_GLOW, shadow_offset = Vector2(0.0, 4.0), pad = 16.0}),
		}, _pill_inks(), Look.ring(INDIGO, {width = 2.0, radius = CELL, inset = 2.0}))


## A pill's four boxes at this padding.
func _pill_boxes(pad: float) -> Dictionary:
	return {
		&"normal": Look.flat(WHITE, {radius = PILL, border = 1.0, border_colour = SEAM, pad = pad}),
		&"hover": Look.flat(PALE, {radius = PILL, border = 1.0, border_colour = SEAM, pad = pad}),
		&"inert": Look.flat(PALE, {radius = PILL, border = 1.0, border_colour = PALE, pad = pad}),
		&"glowing": _glow_box(pad),
	}


## A flap: a pill rounded at the top alone, padded this much above its word.
## Seamed all round, or with the bottom seam dropped so it joins the cell.
func _flap(fill: Color, pad_top: float, seamed: bool) -> StyleBoxFlat:
	var box := Look.flap(fill, {radius = PILL, pad_top = pad_top, pad = 14.0, border = 1.0, border_colour = SEAM})
	if not seamed:
		box.border_width_bottom = 0
	return box


## The one indigo block, on the faintest bloom of its own colour.
func _glow_box(pad: float) -> StyleBoxFlat:
	return Look.flat(INDIGO, {radius = PILL, shadow = 14.0, shadow_colour = INDIGO_GLOW, shadow_offset = Vector2(0.0, 5.0), pad = pad})


## A pill's ink in each state: near-black, and white on the indigo.
func _pill_inks() -> Dictionary:
	return {&"normal": PALETTE[&"ink"], &"hover": PALETTE[&"ink"], &"inert": PALETTE[&"ink_soft"], &"glowing": WHITE}


## The compartments: white cells with a seam, a pastel cell for context,
## and the pop-up a cell with a little more air and a heavier indigo seam.
func _cells() -> void:
	var white_cell := Look.flat(WHITE, {radius = CELL, border = 1.0, border_colour = SEAM, pad = 18.0})
	Look.ground(self, Themes.SURFACE, Look.flat(WHITE, {radius = CELL, border = 1.0, border_colour = SEAM}))
	Look.ground(self, Themes.RAISED, white_cell)
	# the cells that hold a reading rather than a choice: pastel, no seam
	for pastel: StringName in [Themes.CARD, &"Bubble"]:
		Look.ground(self, pastel, Look.flat(PASTEL, {radius = CELL, pad = 16.0}))
	Look.ground(self, &"Moment", white_cell)
	# the tray's main cell: the panel the flaps sit on, the same white cell as any other
	Look.ground(self, &"TabPanel", white_cell)
	# the typed line: its own compartment, pastel, with the indigo seam while it is being typed in
	set_type_variation(&"Field", &"LineEdit")
	set_stylebox(&"normal", &"Field", Look.flat(PASTEL, {radius = CELL, border = 1.0, border_colour = SEAM, pad = 12.0}))
	set_stylebox(&"focus", &"Field", Look.ring(INDIGO, {width = 2.0, radius = CELL}))
	set_color(&"font_color", &"Field", PALETTE[&"ink"])
	set_color(&"caret_color", &"Field", INDIGO)
	# the tray itself: the ground, holding one gutter of air around the outermost cells
	Look.ground(self, &"Tray", Look.flat(PALE, {pad = GUTTER}))
	# an empty compartment: the seam alone, so the tray still reads as a grid
	Look.ground(self, &"CardEmpty", Look.flat(PALE, {radius = CELL, border = 1.0, border_colour = SEAM, pad = 18.0}))
	# the pop-up: the biggest cell, the indigo seam saying which one is the moment
	Look.ground(self, PANEL, Look.flat(WHITE, {radius = 24.0, border = 2.0, border_colour = INDIGO, shadow = 18.0, shadow_colour = INDIGO_GLOW, shadow_offset = Vector2(0.0, 8.0), pad = 26.0}))
	Look.ground(self, SHADE, Look.flat(PALETTE[&"shade"]))


## One sans family throughout: bold for the two headings, regular for the
## rest, grey only for the second voice.
func _type(sans: Font, bold: Font) -> void:
	set_default_font(sans)
	default_font_size = 22
	for kind: StringName in [Themes.FACE, Themes.REASON, Themes.WORDS, READOUT, LINE, Themes.TITLE, Themes.NUMBER]:
		set_color(&"font_color", kind, PALETTE[&"ink"])
	Look.words(self, Themes.WORDS, 36, bold, PALETTE[&"ink"])
	Look.words(self, Themes.FACE, 22, sans, PALETTE[&"ink"])
	Look.words(self, Themes.REASON, 17, sans, PALETTE[&"ink_soft"])
	Look.words(self, Themes.TITLE, 24, bold, PALETTE[&"ink"])
	Look.words(self, READOUT, 18, sans, PALETTE[&"ink_soft"])
	Look.words(self, LINE, 20, sans, PALETTE[&"ink"])
	Look.words(self, Themes.NUMBER, 76, bold, INDIGO)
	# the clock in the strip: the second voice, never a heading
	Look.words(self, &"Countdown", 20, sans, PALETTE[&"ink_soft"])
	# the drawn readouts: indigo, the one accent, with the graph's links grey
	for drawn: StringName in Charts.DRAWN:
		set_color(&"line", drawn, INDIGO)
	set_color(&"link", &"Graph", PALETTE[&"ink_soft"])
	# the pulse: barely a breath, since a bento cell is meant to sit still
	set_constant(&"depth", Themes.PULSE, 25)
	set_constant(&"period", Themes.PULSE, 2000)


## One gutter between compartments, everywhere, and the tight lines inside
## a cell kept tight so the grid's rhythm is the only spacing the eye reads.
func _lines() -> void:
	for line: StringName in [Themes.ROW, Themes.COLUMN, Themes.TILES]:
		set_constant(&"gap", line, GUTTER)
	for grid: StringName in [&"gap", &"row_gap"]:
		set_constant(grid, Themes.GRID, GUTTER)
	Look.line(self, TIGHT, Themes.COLUMN, 6)
	Look.line(self, Themes.CENTRED, Themes.ROW, GUTTER, Look.CENTER)
	Look.line(self, &"Chips", Themes.ROW, 10)
	# the flaps' strip: bottom-aligned on the panel's top edge, a hair of air between pills
	Look.line(self, &"TabStrip", Themes.ROW, 6, Look.START, Look.END)
	# the strip and its panel with nothing between them
	Look.line(self, &"TabSet", Themes.COLUMN, 0)
	Look.line(self, &"Controls", Themes.ROW, GUTTER, Look.END)
	Look.line(self, &"InstructionBar", Themes.ROW, GUTTER, Look.BETWEEN, Look.CENTER)
	Look.line(self, &"Outcomes", Themes.COLUMN, 10)
	Look.line(self, &"FilterSet", Themes.ROW, 10)
	Look.line(self, &"MatrixLine", Themes.ROW, 8)
	Look.line(self, &"Disposition", Themes.ROW, GUTTER)
	Look.line(self, &"AmountField", Themes.ROW, 10, Look.START, Look.CENTER)
	# the compartments that are stacks of lines, not surfaces: the gutter between their rows
	for stacked: StringName in [&"Board", &"Collection", &"Matrix"]:
		Look.line(self, stacked, Themes.COLUMN, 10)
