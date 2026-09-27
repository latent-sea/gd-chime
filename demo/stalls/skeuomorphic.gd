extends "res://demo/gallery/stall.gd"

const Shape := preload("res://addons/gd_chime/shape.gd")
const SkeuomorphicPaper := preload("res://demo/gallery/looks/skeuomorphic_paper.gd")

## SKEUOMORPHISM, arranged as the physical stall it imitates. The layout is
## a place, not a page: index-card dividers stand along the top edge of the
## leather counter, and everything of the day's trade is an object laid on
## that counter - crates in a row, a price ticket pinned beside one, an open
## ledger of two facing pages, a clipboard, a pinboard. A chalkboard strip
## along the bottom carries the instruction on a card pinned to it, with the
## two actions as brass plates screwed to its frame.
##
## WORDS TAKE THE OBJECT THEY ARE WRITTEN ON. The look inks each kind of
## words for the page it is usually read on, so a note on the cork is
## written in the ink the look keeps for cork (skeuomorphic_paper.gd's
## PINNED), and the instruction - the look's walnut, made for paper - is
## pinned up on a card rather than chalked onto the slate, where walnut is
## not read at all (faint_words.gd).
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## How this differs from the placeholder: no captioned boxes stacked down a
## screen. Every piece is given the physical object a market trader would
## keep it in, and its position is where that object would really sit -
## dividers up top, goods at hand on the counter, the ledger open flat, the
## day's instruction chalked where a customer can read it.
##
## ON A WINDOW ON ITS END the ticket is pinned across the top of the counter
## rather than beside it, so the counter has the whole width; the crates
## stand two to a row, the price ticket lies under its crate, the clipboard
## takes the counter's width, and the brass plates hang under the chalked
## words instead of beside them.

## The crates on the counter, three to a row on a wide window.
const THIRDS: Array[float] = [0.333, 0.333, 0.334]
## The crates on a window on its end, two to a row.
const TWO_WIDE := {Shape.PORTRAIT: [0.5, 0.5]}


## The look this stall is dressed in.
func worn() -> StringName:
	return &"skeuomorphic"


## The stall: index-card dividers standing on the counter that holds the
## day's trade, the back plate and the clock pinned beside it, the
## chalkboard along the bottom.
func arrange() -> Desc:
	# on a window on its end the ticket runs across the top of the counter: back at its left, the clock at its right
	var ways := ui.by_shape({&"back": pieces.back(), &"clock": pieces.clock()}, {
		Shape.LANDSCAPE: _arrangement(true, DemoTheme.TIGHT, {&"back": {}, &"clock": {}}),
		Shape.PORTRAIT: _arrangement(false, Themes.ROW, {&"back": {"grow": 1.0}, &"clock": {"grow": 1.0}}),
	})
	var beside := ui.column([ui.surface(&"Ticket", [ways]).basis(0.3), ui.text("", DemoTheme.READOUT).grow()])
	# and it is pinned above the dividers, so they and the counter they stand on have the whole width
	var counter := ui.by_shape({&"counter": pieces.tabs([_screens()]), &"ticket": beside}, {
		Shape.LANDSCAPE: _arrangement(false, Themes.ROW, {&"counter": {"grow": 9.0}, &"ticket": {"grow": 1.0}}),
		Shape.PORTRAIT: _arrangement(true, Themes.COLUMN, {&"ticket": {}, &"counter": {"grow": 1.0}}),
	})
	# the instruction on a card pinned to the board rather than chalked on it: the kind of words it is written in is the look's walnut, which is read on paper and never on slate
	var notice := ui.surface(&"Ticket", [pieces.instruction()])
	# the chalk strip: the day's instruction pinned up, the two actions as brass plates beside it - on a line under it on a window on its end
	var chalk := ui.surface(&"Chalkboard", [ui.by_shape({&"words": notice, &"start": pieces.start(), &"step": pieces.step()}, {
		Shape.LANDSCAPE: _arrangement(false, Themes.ROW, {&"words": {"grow": 5.0}, &"start": {"grow": 1.0}, &"step": {"grow": 1.0}}),
		Shape.PORTRAIT: _arrangement(false, Themes.TILES, {&"words": {"basis": 1.0}, &"start": {"grow": 1.0}, &"step": {"grow": 1.0}}),
	})])
	var stall := ui.column([counter.grow(), chalk.basis(0.14)])
	return ui.app(STALL, [ui.stack([stall, pieces.moment(Phrase.of("A MOMENT: it appears once when something worth marking has happened, and one button clears it away.")), pieces.bubble()])])


## Everything laid on the counter, one thing taking another's place.
func _screens() -> Desc:
	return ui.screen(&"content", [ui.stack([_about(), _readouts(), _navigation(), _sets(), _graph(), _matrix(), _detail()] + more.screens())])


## The counter as the trader left it: a row of crates, each with its hand
## written card, and the tags of every look hung on the end.
func _about() -> Desc:
	var crates := [
		[Phrase.of("The stall"), [Phrase.of("A gallery of the kit, one part at a time,"), Phrase.within("kept as a market stall of fruit crates."), Phrase.of("The cards along the top edge are the dividers;"), Phrase.within("press one to pull that part of the stall forward.")]],
		[Phrase.of("Along the top"), [Phrase.of("A divider per part, stood on the counter."), Phrase.of("BACK returns to the one you came from."), Phrase.of("The clock is a COUNTDOWN to closing time.")]],
		[Phrase.of("The chalkboard"), [Phrase.of("The strip below says what to do next."), Phrase.of("The two brass plates are what you can do now."), Phrase.of("The glowing one is the one meant.")]],
		[Phrase.of("Try this"), [Phrase.of("Press start restocking: the board asks for 0 of 3."), Phrase.of("The glow moves to pick a crate, a bubble on it."), Phrase.of("Press it three times; a moment says you are done.")]],
		[Phrase.of("The words"), [Phrase.of("A crate is one item on the stall. c is the coin."), Phrase.of("Takings is what it has made; recent, four days."), Phrase.of("Marks are complaints against it.")]],
	]
	var shelf: Array = []
	for crate: Array in crates:
		var lines: Array = []
		for line: Phrase in crate[1]:
			lines.append(ui.text(line, DemoTheme.READOUT))
		shelf.append(_crate(crate[0], ui.column(lines, DemoTheme.TIGHT)))
	var looks := pieces.looks()
	var hung := _crate(Phrase.of("The tags"), ui.column([looks["worn"], ui.row(looks["picks"], Themes.TILES).grow()], DemoTheme.TIGHT))
	return ui.screen(ABOUT, [ui.column([ui.grid(shelf, THIRDS, Themes.GRID, TWO_WIDE).grow(3.0), hung.grow()])])


## One crate open on the counter, and its price ticket pinned beside it.
func _readouts() -> Desc:
	var read := pieces.readouts()
	var open_crate := _crate(Phrase.of("The pear crate"), ui.column([
		_line(Phrase.of("Its name, read live"), read["label"]).grow(),
		_line(Phrase.of("The last four days' takings"), read["trace"]).grow(2.0),
		_line(Phrase.of("Takings as a fill; full is 100,000"), read["bar"]).grow(),
	]))
	var ticket := ui.surface(&"Ticket", [ui.column([
		ui.text(Phrase.of("PRICE TICKET"), Themes.TITLE),
		_line(Phrase.of("Takings"), read["quantity"]).grow(),
		_line(Phrase.of("Complaints, a diamond each"), read["mark"]).grow(),
		_line(Phrase.of("Closeness to another crate; press it"), read["relative"]).grow(),
		ui.text(Phrase.of("The clock on the ticket with BACK counts down to closing"), DemoTheme.READOUT).grow(),
	], DemoTheme.TIGHT)])
	# on a window on its end the ticket lies under its crate
	return ui.screen(READOUTS, [ui.by_shape({&"crate": open_crate, &"ticket": ticket}, {
		Shape.LANDSCAPE: _arrangement(false, Themes.ROW, {&"crate": {"grow": 2.0}, &"ticket": {"grow": 1.0}}),
		Shape.PORTRAIT: _arrangement(true, Themes.COLUMN, {&"crate": {"grow": 2.0}, &"ticket": {"grow": 1.0}}),
	})])


## The goods in reach: four crates in a row on the counter, the signs that
## point off it above them, and the till below.
func _navigation() -> Desc:
	var ways := pieces.navigation()
	var cards := pieces.cards()
	var acting := pieces.acting()
	var signs := ui.surface(&"Ticket", [ui.row([
		_line(Phrase.of("To the lists"), ways["menu"]).grow(),
		_line(Phrase.of("A name; press to open"), ways["inline"]).grow(),
		_line(Phrase.of("Where you came from"), ways["back"]).grow(),
		_line(Phrase.of("Opens your own fig crate"), ways["play"]).grow(),
	])])
	var crates := ui.row([cards["list"].grow(), cards["tile"].grow(), cards["dense"].grow(), cards["empty"].grow()])
	var till := ui.surface(&"Ticket", [ui.row([
		_line(Phrase.of("Type a number, Enter sets the price"), acting["amount"]).grow(),
		_line(Phrase.of("One of three; the chosen opens its second half"), acting["disposition"]).grow(2.0),
	])])
	return ui.screen(NAVIGATION, [ui.column([signs.basis(0.17), crates.grow(), till.basis(0.3)])])


## The ledger open flat on the counter: the stock written down the left
## page, the standings ruled up the right.
func _sets() -> Desc:
	var lists := pieces.lists()
	var left := ui.surface(&"Ledger", [ui.column([ui.text(Phrase.of("Stock, as written in"), Themes.TITLE), ui.text(Phrase.of("Add, sort, filter; press a line to open it"), DemoTheme.READOUT), lists["rows"].grow()], DemoTheme.TIGHT)])
	var right := ui.surface(&"Ledger", [ui.column([
		ui.text(Phrase.of("Standings, by takings"), Themes.TITLE),
		lists["board"].grow(2.0),
		ui.text(Phrase.of("The same crates, loose in the corner"), DemoTheme.READOUT),
		lists["tiles"].grow(),
	], DemoTheme.TIGHT)])
	return ui.screen(SETS, [ui.row([left.grow(), right.grow()])])


## The pinboard behind the stall: who supplies whom, with the two zoom
## plates screwed to its frame.
func _graph() -> Desc:
	# written straight onto the cork, so in the ink the look writes on cork with, not the softer one a page is read in
	var graph := pieces.graph(SkeuomorphicPaper.PINNED)
	var pinned := ui.surface(&"Pinboard", [ui.column([ui.text(Phrase.of("Suppliers, pinned up"), Themes.TITLE), ui.text(Phrase.of("Drag the board, wheel it, press a name; the two zoom plates are pinned at its top right"), SkeuomorphicPaper.PINNED), graph["graph"].grow(), graph["picked"]], DemoTheme.TIGHT)])
	return ui.screen(GRAPH, [pinned])


## The reckoning sheet: every crate against every other, one triangle,
## since a gap between two has no direction.
func _matrix() -> Desc:
	var sheet := ui.surface(&"Ledger", [ui.column([ui.text(Phrase.of("The reckoning sheet"), Themes.TITLE), ui.text(Phrase.of("The gap in takings between each pair, in thousands"), DemoTheme.READOUT), pieces.matrix(Phrase.of("Gap, thousands")).grow()], DemoTheme.TIGHT)])
	return ui.screen(MATRIX, [sheet])


## The clipboard: one crate's note, written in and stamped, kept with this
## entry until another crate is opened.
func _detail() -> Desc:
	var note := pieces.note()
	var stamps: Array = []
	for flag: Desc in note["flags"]:
		stamps.append(flag.grow())
	var sheet := ui.surface(&"Ticket", [ui.column([
		note["title"],
		ui.text(Phrase.of("Write a line and Enter, stamp the boxes, walk to the pinboard and come back: still here"), DemoTheme.READOUT),
		note["field"],
		note["words"].grow(),
		ui.row(stamps).basis(0.22),
	], DemoTheme.TIGHT)])
	# the detour goes to a place not walked yet, and Back finds this note where it was left
	var ways := ui.row([note["back"], note["detour"]])
	var board := ui.surface(&"Clipboard", [ui.column([sheet.grow(), ways.basis(0.12)])])
	# on a window on its end the clipboard takes the counter's width, the bare counter beside it none
	var laid := ui.by_shape({&"board": board, &"bare": ui.text("", DemoTheme.READOUT)}, {
		Shape.LANDSCAPE: _arrangement(false, Themes.ROW, {&"board": {"grow": 3.0}, &"bare": {"grow": 1.0}}),
		Shape.PORTRAIT: _arrangement(false, Themes.ROW, {&"board": {"grow": 1.0}, &"bare": {"max": 0.0}}),
	})
	return ui.screen(DETAIL, [laid], null, {on_fill = drafts.begun})


## A crate on the counter: its stencilled name and what is in it.
func _crate(named: Variant, content: Desc) -> Desc:
	return ui.surface(Themes.RAISED, [ui.column([ui.text(named, Themes.TITLE), content.grow()], DemoTheme.TIGHT)])


## One way of laying parts in a line, for by_shape: down or across, in this
## line style, each part with its facts, in the order the facts are given.
func _arrangement(down: bool, style: StringName, facts: Dictionary) -> Dictionary:
	return ui.column_of(facts.keys(), facts, style) if down else ui.row_of(facts.keys(), facts, style)


## One thing with its written hint under it, as a ticket's line.
func _line(hint: Variant, content: Desc) -> Desc:
	return ui.column([content.grow(), ui.text(hint, DemoTheme.READOUT).hides_empty()], DemoTheme.TIGHT)
