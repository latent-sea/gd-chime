extends "res://demo/gallery/stall.gd"


## DATA-DENSE. Tufte's arrangement: the page is a table, not a set of
## boxes. No captioned panels at all - a heading row does the work a
## caption box would, once, for a whole column of values. The readouts are
## not seven specimens in seven frames but ONE table: a row per crate, the
## six readouts as the six cells across, under a header. The sets screen is
## two columns of one table - the rows collection beside the board - with
## the tiles demoted below the fold, small, since a tile spends a lot of
## page on one name. The matrix is set small and left to fill its width.
## The tabs are a single line of words on a hairline, the current one ruled
## under in the signal colour, with the clock at the far right; the
## instruction bar is a one-line status bar at the very bottom, its two
## actions as words at the right, the way a terminal puts its keys.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.

## The six columns of the readouts table, in English, and their shares of the width.
const HEAD_WORDS := ["Crate", "Takings", "Takings, as a bar", "Last four days", "Marks", "Closeness"]
const SHARES := [0.16, 0.13, 0.19, 0.17, 0.13, 0.22]
## The readouts by name, in the order this table sets them across.
const ACROSS := ["label", "quantity", "bar", "trace", "mark", "relative"]


func worn() -> StringName:
	return &"data_dense"


## The whole page: the flaps of words over the panel of screens, the way
## back and the clock in the corner beside them, a status line beneath.
func arrange() -> Desc:
	var corner := ui.column([pieces.back(), pieces.clock()], DemoTheme.TIGHT)
	var top := ui.row([pieces.tabs([_screens()]).grow(9.0), corner.grow()])
	var status := ui.row([pieces.instruction().grow(6.0), pieces.start().grow(), pieces.step().grow()])
	var page := ui.column([top.grow(), status.basis(0.10)])
	# one hairline gutter each side, so no column of the table is set against the window's edge
	var ruled := ui.row([ui.text("").basis(0.008), page.grow(), ui.text("").basis(0.006)])
	return ui.app(STALL, [ui.stack([ruled, pieces.moment(Phrase.of("A moment: it appears once when something worth marking has happened, and one word dismisses it.")), pieces.bubble()])])


## Every screen, one taking another's place inside the tabs' panel.
func _screens() -> Desc:
	return ui.screen(&"content", [ui.stack([_about(), _readouts(), _navigation(), _sets(), _graph(), _matrix(), _detail()] + more.screens())])


## The start: the vocabulary as a two-column glossary table, and the looks
## as one line of words - no boxes, no rules but the header's.
func _about() -> Desc:
	var terms := [
		[Phrase.of("Crate"), Phrase.of("One item on the stall; c is the coin")],
		[Phrase.of("Takings"), Phrase.of("What a crate has made, all told")],
		[Phrase.of("Last four days"), Phrase.of("The same, day by day, as a trace")],
		[Phrase.of("Marks"), Phrase.of("Complaints registered against a crate")],
		[Phrase.of("Closeness"), Phrase.of("One crate measured against another")],
		[Phrase.of("The line above"), Phrase.of("Every screen as a word on the panel it opens; the clock is time until the stall closes")],
		[Phrase.of("The line below"), Phrase.of("What to do next, and the words you may press now")],
		[Phrase.of("To try"), Phrase.of("Press start restocking, then pick a crate three times")],
	]
	var lines: Array = [_head([Phrase.of("Term"), Phrase.of("What it means")], [0.22, 0.78])]
	for term: Array in terms:
		lines.append(ui.row([ui.text(term[0], Themes.TITLE).basis(0.22), ui.text(term[1], DemoTheme.READOUT).basis(0.78)]))
	var looks := pieces.looks()
	lines.append(ui.row([looks["worn"]] + looks["picks"], Themes.TILES))
	return ui.screen(ABOUT, [ui.column(lines, DemoTheme.TIGHT)])


## The readouts as ONE table: a header, then a row per crate with the six
## readouts as its six cells. The caption a box would carry is the heading.
func _readouts() -> Desc:
	var key := func(thing: Dictionary) -> int: return thing["id"]
	var table := ui.each(ui.bound(things.get_things), _measured, key, DemoTheme.TIGHT)
	var foot := ui.text(Phrase.of("Every cell reads live; a bar is logarithmic against 100,000, closeness is a press as well as a figure"), Themes.REASON)
	# the table is not stretched: a row is a line, and the page ends where the data does
	return ui.screen(READOUTS, [ui.column([_head(HEAD_WORDS.map(func(head: String) -> Phrase: return Phrase.of(head)), SHARES), table.basis(0.45), foot], DemoTheme.TIGHT)])


## One crate as a table row: its own six readouts, at the column widths.
func _measured(thing: Bound) -> Desc:
	var read := pieces.readouts(thing)
	var cells: Array = []
	for at: int in ACROSS.size():
		cells.append(read[ACROSS[at]].basis(SHARES[at]))
	return ui.row(cells)


## The controls as a table too: a column of what it is, a column of the
## thing itself, four cards on one line beneath.
func _navigation() -> Desc:
	var went := pieces.navigation()
	var cards := pieces.cards()
	var acting := pieces.acting()
	var ways := ui.column([
		_head([Phrase.of("Control"), Phrase.of("The thing itself")], [0.22, 0.78]),
		_ruled(Phrase.of("Menu link"), went["menu"]),
		_ruled(Phrase.of("Inline link"), went["inline"]),
		_ruled(Phrase.of("Back"), went["back"]),
		_ruled(Phrase.of("Play"), went["play"]),
		_ruled(Phrase.of("Amount field"), acting["amount"]),
		_ruled(Phrase.of("Disposition"), acting["disposition"]),
	], DemoTheme.TIGHT)
	var laid := ui.row([cards["list"].grow(), cards["tile"].grow(), cards["dense"].grow(), cards["empty"].grow()])
	return ui.screen(NAVIGATION, [ui.column([ways.basis(0.34), _head([Phrase.of("As a row"), Phrase.of("As a tile"), Phrase.of("Dense"), Phrase.of("Empty")], [0.25, 0.25, 0.25, 0.25]), laid.basis(0.34)], DemoTheme.TIGHT)])


## Two columns of one table: the rows collection and the board, headed;
## the tiles kept below the eye-line, small, where a name each costs least.
func _sets() -> Desc:
	var lists := pieces.lists()
	var columns := ui.row([lists["rows"].basis(0.62), lists["board"].basis(0.38)])
	return ui.screen(SETS, [ui.column([
		_head([Phrase.of("Every crate: add, sort, filter, press to open"), Phrase.of("Ranked by takings")], [0.62, 0.38]),
		columns.basis(0.46),
		_head([Phrase.of("The same crates as tiles")], [1.0]),
		lists["tiles"].basis(0.2),
	], DemoTheme.TIGHT)])


## The matrix filling the width: the gap between each pair of crates, one
## triangle, since a gap has no direction.
func _matrix() -> Desc:
	return ui.screen(MATRIX, [ui.column([_head([Phrase.of("The gap in takings between each pair of crates")], [1.0]), pieces.matrix(Phrase.of("Gap, c thousands")).grow()], DemoTheme.TIGHT)])


## The suppliers: the canvas filling the page under one heading, with who
## is picked read back on the line beneath it.
func _graph() -> Desc:
	var graph := pieces.graph()
	return ui.screen(GRAPH, [ui.column([
		_head([Phrase.of("Who deals with whom; thicker is stronger. Drag, wheel, press a name")], [1.0]),
		graph["graph"].grow(),
		graph["picked"].basis(0.06),
	], DemoTheme.TIGHT)])


## The detail as a compact form: the title, the note line, the flags
## inline, the links inline - four lines, no box around any of them.
func _detail() -> Desc:
	var note := pieces.note()
	# the detour goes to a screen not walked yet, and Back finds this note where it was left
	var ways := ui.row([note["back"], note["detour"], ui.text(Phrase.of("Type a note and Enter, tick a flag, go to suppliers, come back: still here"), Themes.REASON).grow()])
	var form := ui.column([
		note["title"],
		ui.row([ui.text(Phrase.of("Note"), DemoTheme.READOUT).basis(0.12), note["field"].basis(0.88)]),
		note["words"],
		ui.row([ui.text(Phrase.of("Flags:"), Themes.REASON)] + note["flags"]),
		ways,
	], DemoTheme.TIGHT)
	return ui.screen(DETAIL, [form], null, {on_fill = drafts.begun})


## A header row: the column names, at the widths their column takes.
func _head(names: Array, shares: Array) -> Desc:
	var cells: Array = []
	for at: int in names.size():
		cells.append(ui.text(names[at], Themes.TITLE).basis(shares[at]))
	return ui.row(cells)


## One row of a two-column table: what it is, then the thing itself.
func _ruled(named: Variant, content: Desc) -> Desc:
	return ui.row([ui.text(named, DemoTheme.READOUT).basis(0.22), content.basis(0.78)])
