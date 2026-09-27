extends "res://demo/gallery/stall.gd"

const Shape := preload("res://addons/gd_chime/shape.gd")

## BENTO GRID. The stall as a tray of compartments: every region is one
## self-contained cell in a grid of four columns, and a cell's importance
## is how many columns it takes - nothing else. The tray's main cell is the
## panel of places, and the flaps sit on its top edge as pills, so the one
## you are on is the cell you are reading. Above it a narrow row of two
## small cells: the act at the left, the ways out at the right. Every place
## is a tray too, so the arrangement never changes shape, only which
## compartments are laid in it. There is no stacked column of captioned
## boxes: a caption lives inside its own cell, under the cell's name.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Approximated twice, both the grid's: it spans across the columns only
## (grid.gd says spans down the rows are deliberately absent), so the sets
## tray's rows-collection spanning two rows is a left half holding one cell
## against a right half holding two; and a grid row is as tall as its
## content, so a tray whose cells must fill the height - the crates, the
## pairs - is laid as a line of cells instead. What is wanted in both is a
## grid whose rows share the height.
##
## ON A WINDOW ON ITS END the tray keeps its compartments and its one
## gutter. A tray of four columns is two wide there: the same cells fall two
## to a row in the order they were given, and a cell that covered two or more
## columns covers the row. The top row and the suppliers' foot are only as
## tall as their cells, rather than a share of a tall window, so no band of
## bare tray opens under either.

const COLUMNS: Array[float] = [0.25, 0.25, 0.25, 0.25]
## The columns of a tray of four on a window on its end.
const TWO_WIDE := {Shape.PORTRAIT: [0.5, 0.5]}
const TOP: Array[float] = [0.7, 0.3]
const THIRDS: Array[float] = [0.34, 0.33, 0.33]
const NOTE_AND_WAYS: Array[float] = [0.68, 0.32]


func worn() -> StringName:
	return &"bento"


## The tray: a narrow row of two small cells - the act at the left, the
## ways out at the right - over the main cell, the panel of places with
## its flaps on the top edge.
func arrange() -> Desc:
	# the words over the two moves, not beside them, so this cell stays narrow
	var moves := ui.row([pieces.start().grow(), pieces.step().grow()])
	var bar := _cell(Phrase.of("Do this next"), "", ui.column([pieces.instruction().grow(), moves.grow()]))
	var ways := _cell(Phrase.of("The stall"), "", ui.row([pieces.back().grow(), pieces.clock().grow()]))
	var top := ui.grid([bar.span(1), ways.span(1)], TOP)
	# the flaps are the top edge of the main cell: the place you are on is the cell you read
	var places := pieces.tabs([_screens()])
	var moment := pieces.moment(Phrase.of("This is a MOMENT: it appears once when something worth marking has happened, and one button dismisses it."))
	# on a window on its end the top row is only as tall as its cells, so the one gutter is all that lies under it
	var laid := ui.by_shape({&"top": top, &"places": places}, {
		Shape.LANDSCAPE: _arrangement(true, Themes.COLUMN, {&"top": {"basis": 0.16}, &"places": {"grow": 1.0}}),
		Shape.PORTRAIT: _arrangement(true, Themes.COLUMN, {&"top": {}, &"places": {"grow": 1.0}}),
	})
	# the whole tray on its own ground, so the outermost cells keep the one gutter too
	var tray := ui.surface(&"Tray", [laid])
	return ui.app(STALL, [ui.stack([tray, moment, pieces.bubble()])])


## Every place, one taking another's place inside the flaps' panel.
func _screens() -> Desc:
	return ui.screen(&"content", [ui.stack([_about(), _readouts(), _navigation(), _sets(), _graph(), _matrix(), _detail()] + more.screens())])


## The overview tray: one cell per region, sized by how much it matters -
## a wide welcome, two half-width cells for the crates and their readings,
## three narrow ones, and the looks across the foot.
func _about() -> Desc:
	var welcome := _lines(Phrase.of("A stall of crates"), Phrase.of("What this is"), [Phrase.of("A tray of compartments: every region of this stall is one cell."), Phrase.of("A cell is as important as it is wide - that is the whole hierarchy."), Phrase.of("The pills on the top edge are the flaps of this cell; the one you are on is joined to it.")])
	var readings := _lines(Phrase.of("Readings"), Phrase.of("One crate, six ways"), [Phrase.of("A crate's takings as a number, as a fill, as four days of trace."), Phrase.of("Its name, its complaints, and how close it is to another crate."), Phrase.of("The coin is c; takings is what the crate has made.")])
	var crates := _lines(Phrase.of("Crates"), Phrase.of("Lists of crates"), [Phrase.of("Every crate as rows, with add, sort and a filter-set over them."), Phrase.of("The same crates as tiles, and ranked on a board."), Phrase.of("Press a crate anywhere and its own cell opens.")])
	var suppliers := _lines(Phrase.of("Suppliers"), Phrase.of("Who deals with whom"), [Phrase.of("Drag to pan, wheel to zoom, press a name to pick it.")])
	var pairs := _lines(Phrase.of("Crate vs crate"), Phrase.of("The gaps"), [Phrase.of("Each pair's gap in takings, one triangle.")])
	var note := _lines(Phrase.of("A note"), Phrase.of("Kept with a crate"), [Phrase.of("Open a crate, type a note, tick a flag: it is still there on your return.")])
	var instruction := _lines(Phrase.of("The cell at the top left"), Phrase.of("How the act runs"), [Phrase.of("Its words say what to do next; the two buttons under them are the moves."), Phrase.of("The glowing one is the one meant. Press start restocking, then pick a crate three times."), Phrase.of("A moment appears when the three are done; carry on dismisses it.")])
	var picked := pieces.looks()
	var looks := _cell(Phrase.of("The look"), Phrase.of("The same stall in each design language; press one"), ui.column([picked["worn"], ui.row(picked["picks"], Themes.TILES)], DemoTheme.TIGHT))
	var tray := ui.grid([welcome.span(2), instruction.span(2), readings.span(2), crates.span(2), suppliers.span(1), pairs.span(1), note.span(2), looks.span(4)], COLUMNS, Themes.GRID, TWO_WIDE)
	return ui.screen(ABOUT, [ui.scroll(tray)])


## The readings tray: the six readouts, each its own compartment, the two
## that are pictures given twice the width of the two that are a glance.
func _readouts() -> Desc:
	var read := pieces.readouts()
	var quantity := _cell(Phrase.of("Quantity"), Phrase.of("The pear crate's takings"), read["quantity"])
	var bar := _cell(Phrase.of("Bar"), Phrase.of("The same, as a fill; full is 100,000"), read["bar"])
	var trace := _cell(Phrase.of("Trace"), Phrase.of("The last four days' takings"), read["trace"])
	var label := _cell(Phrase.of("Label"), Phrase.of("The crate's name, read live"), read["label"])
	var mark := _cell(Phrase.of("Mark"), Phrase.of("Complaints, a diamond each; pear has none"), read["mark"])
	var relative := _cell(Phrase.of("Relative"), Phrase.of("Closeness to another crate; press to compare"), read["relative"])
	var clock := _cell(Phrase.of("Countdown"), Phrase.of("The clock in the ways cell"), ui.text(Phrase.of("Time until the stall closes"), DemoTheme.READOUT))
	return ui.screen(READOUTS, [ui.grid([quantity.span(2), trace.span(2), bar.span(2), relative.span(2), label.span(1), mark.span(1), clock.span(2)], COLUMNS, Themes.GRID, TWO_WIDE)])


## The ways-in tray: four narrow control cells on the first row, four card
## cells on the second, then the typed line beside the wide disposition.
func _navigation() -> Desc:
	var ways := pieces.navigation()
	var cards := pieces.cards()
	var acting := pieces.acting()
	var controls := [
		_cell(Phrase.of("Menu link"), Phrase.of("A button to a tray"), ways["menu"]),
		_cell(Phrase.of("Inline link"), Phrase.of("A name; press to open it"), ways["inline"]),
		_cell(Phrase.of("Back"), Phrase.of("The tray you came from"), ways["back"]),
		_cell(Phrase.of("Play"), Phrase.of("Opens your own crate, the fig"), ways["play"]),
	]
	var shown := [
		_cell(Phrase.of("Card, list"), Phrase.of("A crate as a row; press to open"), cards["list"]),
		_cell(Phrase.of("Card, tile"), Phrase.of("The same crate as a tile"), cards["tile"]),
		_cell(Phrase.of("Card, dense"), Phrase.of("Live picture, takings, a button"), cards["dense"]),
		_cell(Phrase.of("Card, empty"), Phrase.of("An empty slot and the ways to fill it"), cards["empty"]),
	]
	var amount := _cell(Phrase.of("Amount field"), Phrase.of("Type a number, Enter sets the price"), acting["amount"])
	var disposition := _cell(Phrase.of("Disposition"), Phrase.of("One of three; the chosen opens its second half"), acting["disposition"])
	var cells: Array = []
	# every control and card cell one column wide, so the two rows line up
	for one: Desc in controls + shown:
		cells.append(one.span(1))
	cells.append(amount.span(1))
	cells.append(disposition.span(3))
	return ui.screen(NAVIGATION, [ui.scroll(ui.grid(cells, COLUMNS, Themes.GRID, TWO_WIDE))])


## The crates tray: a 2x2 whose left half is one tall cell - the rows, with
## their add, sort and filter-set - and whose right half is two cells.
func _sets() -> Desc:
	var lists := pieces.lists()
	var tall := _cell(Phrase.of("Collection, rows"), Phrase.of("Add, sort, filter; press a row to open it"), lists["rows"])
	# the right half: two cells stacked, since a span down the rows is not in the grid
	var stacked := ui.column([
		_cell(Phrase.of("Collection, tiles"), Phrase.of("The same crates as tiles"), lists["tiles"]).grow(),
		_cell(Phrase.of("Board"), Phrase.of("Ranked by takings; scrolled to keep your fig in view"), lists["board"]).grow(),
	])
	return ui.screen(SETS, [ui.row([tall.grow(), stacked.grow()])])


## The suppliers tray: one cell holding the whole picture, with a narrow
## cell under it saying who is picked and a narrow one saying what to try.
func _graph() -> Desc:
	var drawn := pieces.graph()
	var picture := _cell(Phrase.of("Relationship graph"), Phrase.of("Who deals with whom; thicker is stronger"), drawn["graph"])
	var who := _cell(Phrase.of("Picked"), "", drawn["picked"])
	var hint := _lines(Phrase.of("What to try"), "", [Phrase.of("Drag to pan, wheel to zoom,"), Phrase.within("press a name.")])
	var foot := ui.grid([who.span(2), hint.span(1)], THIRDS)
	# on a window on its end the foot is only as tall as its two cells, and the picture takes the rest
	return ui.screen(GRAPH, [ui.by_shape({&"picture": picture, &"foot": foot}, {
		Shape.LANDSCAPE: _arrangement(true, Themes.COLUMN, {&"picture": {"grow": 1.0}, &"foot": {"basis": 0.2}}),
		Shape.PORTRAIT: _arrangement(true, Themes.COLUMN, {&"picture": {"grow": 1.0}, &"foot": {}}),
	})])


## The pairs tray: the whole triangle in one wide cell, its reading beside
## it in a narrow one.
func _matrix() -> Desc:
	var table := _cell(Phrase.of("Matrix"), Phrase.of("The gap in takings between each pair, in thousands"), pieces.matrix(Phrase.of("Gap, thousands")))
	var hint := _lines(Phrase.of("One triangle"), "", [Phrase.of("A gap has no direction,"), Phrase.within("so the other half would"), Phrase.within("say the same twice."), Phrase.of("Press a name to open"), Phrase.within("that crate.")])
	return ui.screen(MATRIX, [ui.row([table.grow(3.0), hint.grow()])])


## The crate's own tray: two cells - the note large at the left, the ways
## out small at the right.
func _detail() -> Desc:
	var written := pieces.note()
	var note := _cell(Phrase.of("A note kept with this crate"), Phrase.of("Type a note and Enter, tick flags, go to suppliers, come back: still here"), ui.column([written["title"], written["field"], written["words"], ui.row(written["flags"])], DemoTheme.TIGHT))
	# the detour goes to a tray not walked yet, and Back finds this note where it was left
	var ways := _cell(Phrase.of("Ways out"), Phrase.of("Back, or a detour to the suppliers"), ui.column([written["back"], written["detour"]], DemoTheme.TIGHT))
	return ui.screen(DETAIL, [ui.grid([note.span(1), ways.span(1)], NOTE_AND_WAYS)], null, {on_fill = drafts.begun})


## One compartment: its name, what to try under it, and the thing itself.
func _cell(title: Variant, hint: Variant, content: Desc = null) -> Desc:
	var inside: Array = [ui.text(title, Themes.TITLE), ui.text(hint, DemoTheme.READOUT).hides_empty()]
	if content != null:
		inside.append(content.grow())
	return ui.surface(Themes.RAISED, [ui.column(inside, DemoTheme.TIGHT)])


## One way of laying parts in a line, for by_shape: down or across, in this
## line style, each part with its facts, in the order the facts are given.
func _arrangement(down: bool, style: StringName, facts: Dictionary) -> Dictionary:
	return ui.column_of(facts.keys(), facts, style) if down else ui.row_of(facts.keys(), facts, style)


## A compartment of words: its name, its caption, and the lines it holds.
func _lines(title: Variant, hint: Variant, said: Array) -> Desc:
	var written: Array = []
	for line: Phrase in said:
		written.append(ui.text(line, DemoTheme.READOUT))
	return _cell(title, hint, ui.column(written, DemoTheme.TIGHT))
