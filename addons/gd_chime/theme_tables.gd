extends RefCounted

const Themes := preload("theme.gd")

## TABLES, as the floor's look draws them until a look says otherwise: the
## heading line, a row, a row picked, the row the cursor is on, a group's
## heading, the words in the cells, and the lines a table, a data grid and a
## matrix stand in.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## theme.gd builds the look and calls dress() once, with the palette it was
## given; this puts its types into that theme and holds nothing. Its numbers
## are placeholders, and theme_placeholders.gd holds them under CELLS: the
## gap between columns - as wide as a column's resize grip, which stands in
## it - the pad either side of a cell's words, how big those words are, and
## how thick a rule is. Read here, never written.
##
## Every line is a cells line (cells.gd) whose ground is its panel. A row
## is ruled along its foot; picked, it is filled; the cursor's is ringed in
## ink, so the row the reader is on is a shape and not a hue; picked and the
## cursor's, both. A row its view is behind on is dimmed in its words, the
## soft ink, beside the mark its row carries. A heading is a pressable
## padded down only: the line pads every part across alike, so a heading's
## words start where its cells' do.
##
## A RECIPE OWNS ITS STRUCTURAL VARIANTS: every line a table's recipe names
## is registered here as a variation of its base, so a look that sets
## nothing lays it out. A table, its rows and a matrix's line stand their
## parts edge to edge, since a table's own rule is what separates them.
##
## It must never name a colour: every colour is the palette's, by name.

## The lines, by what they are.
const CELLS := &"Cells"
const PICKED := &"CellsPicked"
const CURSOR := &"CellsCursor"
const PICKED_CURSOR := &"CellsPickedCursor"
const HEAD := &"CellsHead"
const GROUP := &"CellsGroup"
## The words in a cell, a kind of Label's.
const WORDS := &"CellWords"
## The words of a row its view would now put elsewhere or leave out: the same words, dimmed.
const STALE_WORDS := &"CellWordsStale"
## The rows' column, which stands them edge to edge: each row rules its own foot.
const ROWS := &"CellsRows"
## A table: its heading line and its rows, one over the other with no gap.
const TABLE := &"Table"
## A table's own head and row, and the column a data grid stands in.
const TABLE_HEAD := &"TableHead"
const TABLE_ROW := &"TableRow"
const DATA_GRID := &"DataGrid"
## A matrix of one figure per pair, and one of its lines.
const MATRIX := &"Matrix"
const MATRIX_LINE := &"MatrixLine"
## What a cell reads out: an amount, and how far it has moved since before.
const QUANTITY := &"Quantity"
const RELATIVE := &"Relative"
## A table's cell with nothing to say about its ground: it draws none.
const TABLE_CELL := &"TableCell"
## A grid's bar of controls, above its rows and below them.
const BAR := &"GridBar"
## A column's heading: a pressable.
const HEADING := &"TableHeading"
## Each line's fill, and whether the cursor's ring is on it, as palette names; no fill draws none.
const LINES := {CELLS: [&"", false], PICKED: [&"lit", false], CURSOR: [&"", true], PICKED_CURSOR: [&"lit", true], HEAD: [&"raised", false], GROUP: [&"raised", false]}
## A heading's ground in each state, as palette names.
const HEADING_GROUNDS := {&"normal": &"raised", &"hover": &"lit", &"inert": &"raised", &"glowing": &"accent"}
## And its words in each state: THE INK GOES WITH THE GROUND. A ground set
## here without one leaves the words the look's pressable ink, which is the
## ink for the look's OWN box - white, in a look whose presses are white on
## blue - and a heading then stands white on the pale ground set here, as
## it did in flat and neo-brutalist (faint_words.gd).
const HEADING_INKS := {&"normal": &"ink", &"hover": &"ink", &"inert": &"ink_soft", &"glowing": &"ground"}
## The lines that stand their parts edge to edge: a table's own rule is what separates them.
const EDGE_TO_EDGE: Array[StringName] = [ROWS, TABLE]
## Every other line a table's recipe names, with the base it varies.
const LINES_OF := {TABLE_ROW: Themes.ROW, TABLE_HEAD: Themes.ROW, MATRIX_LINE: Themes.ROW, MATRIX: Themes.COLUMN, DATA_GRID: Themes.COLUMN}


## Every line's type, the cells' words and the heading put into this theme, from this palette.
static func dress(theme: Theme, palette: Dictionary) -> void:
	var pad := float(theme.get_constant(&"pad", CELLS))
	var rule := theme.get_constant(&"rule", CELLS)
	theme.set_type_variation(WORDS, &"Label")
	theme.set_font_size(&"font_size", WORDS, theme.get_constant(&"words_size", CELLS))
	theme.set_color(&"font_color", WORDS, palette[&"ink"])
	theme.set_type_variation(STALE_WORDS, WORDS)
	theme.set_color(&"font_color", STALE_WORDS, palette[&"ink_soft"])
	theme.set_type_variation(CELLS, &"Control")
	# the rows' column and the table's own, standing lines edge to edge: each line rules its own foot
	for edge_to_edge: StringName in EDGE_TO_EDGE:
		theme.set_type_variation(edge_to_edge, Themes.COLUMN)
		theme.set_constant(&"gap", edge_to_edge, 0)
	# every other line a table's recipe names: its base, so a look that sets nothing lays it out
	for line: StringName in LINES_OF:
		theme.set_type_variation(line, LINES_OF[line])
	# what a cell reads out: an amount in words, and how far it has moved since before, a press of its own
	theme.set_type_variation(RELATIVE, Themes.PRESSABLE)
	theme.set_type_variation(QUANTITY, &"Label")
	# a grid's bars: rows that wrap, so a narrow window takes their parts onto more lines rather than past its edge
	theme.set_type_variation(BAR, Themes.ROW)
	theme.set_constant(&"wrap", BAR, 1)
	# a cell with nothing to say about its ground
	theme.set_type_variation(TABLE_CELL, Themes.SURFACE)
	theme.set_stylebox(&"panel", TABLE_CELL, StyleBoxEmpty.new())
	# every line: its fill or none, a rule along its foot, and the cursor's ring where it has one
	for line: StringName in LINES:
		var box := StyleBoxFlat.new()
		box.draw_center = LINES[line][0] != &""
		box.bg_color = palette[LINES[line][0]] if LINES[line][0] != &"" else palette[&"ground"]
		box.border_color = palette[&"ink"] if LINES[line][1] else palette[&"lit"]
		box.set_border_width_all(rule if LINES[line][1] else 0)
		box.border_width_bottom = rule
		box.set_content_margin_all(0.0)
		# air over and under the words, which is what a line needs beyond them, so rows do not stand crowded
		box.content_margin_top = pad / 2.0
		box.content_margin_bottom = pad / 2.0
		if line != CELLS:
			theme.set_type_variation(line, CELLS)
		theme.set_stylebox(&"panel", line, box)
	theme.set_type_variation(HEADING, Themes.PRESSABLE)
	# each state of a heading: its ground, its words padded down only - its line pads it across, as it does a cell
	for state: StringName in HEADING_GROUNDS:
		var box := StyleBoxFlat.new()
		box.bg_color = palette[HEADING_GROUNDS[state]]
		box.content_margin_left = 0.0
		box.content_margin_right = 0.0
		box.content_margin_top = pad / 2.0
		box.content_margin_bottom = pad / 2.0
		theme.set_stylebox(state, HEADING, box)
		theme.set_color(StringName("font_color_" + state), HEADING, palette[HEADING_INKS[state]])
