extends "res://demo/gallery/stall.gd"

const Shape := preload("res://addons/gd_chime/shape.gd")

## NEO-BRUTALISM, arranged. The placeholder gallery is a polite stack of
## equal captioned boxes; this is the opposite on purpose. The tabs are
## square lemon flaps butting edge to edge with no gutter at all, so the
## strip reads as one black-ruled band welded onto the cream panel of
## screens beneath it. Under that the instruction bar is a thick banner
## across the whole width. The screens are deliberately uneven: a grid
## whose cells take one, two or three columns, so rows break where the
## content says rather than where a module would; blocks that butt with
## zero gap beside blocks separated by a chasm; and captions that are not
## tidy headers but loud lemon labels stuck on the top of a cell. The
## detail is one enormous note block with the flags as big stamps.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --path <this folder> --script res://demo/stalls/neo_brutalist.gd
##
## Deviation worth naming: the instruction bar sits ONCE, in the chrome, as
## the banner - a second copy inside the ABOUT screen would put a second
## node named "step" in the tree, and the bubble that anchors to that name
## would then point at a hidden one. So the banner is the chrome's, thick
## everywhere, rather than giant on ABOUT and thin elsewhere.
##
## ON A WINDOW ON ITS END the same blocks are stacked rather than set side
## by side, and where a line of them cannot hold them all it breaks where
## the content says, as this grid's rows always have: the banner's three
## blocks share a line with the instruction across the whole width under
## them, so the bubble over the step stands on the panel as it does when
## wide; four blocks go two to a line; the grids have two columns, a cell
## wider than that taking the row; a hint too long to stand beside its
## label drops under it. The same parts either way (by_shape.gd), and the
## wide arrangement is exactly the one this always had.

const STAMP := &"Stamp"
const BUTT := &"Butt"
const BUTT_DOWN := &"ButtDown"
const CHASM := &"Chasm"
const SLABS := &"Slabs"
## A block on a turned window: under half the width, so two stand on a line with the gap between them.
const HALF := {"basis": 0.45, "grow": 1.0}


func worn() -> StringName:
	return &"neo_brutalist"


## The whole thing: the flaps welded to the panel of screens, the banner
## across the bottom holding the way back and the clock with it.
func arrange() -> Desc:
	var acts := {&"instruction": pieces.instruction(), &"start": pieces.start(), &"step": pieces.step(), &"back": pieces.back()}
	var banner := ui.by_shape(acts, {
		Shape.LANDSCAPE: _along({&"instruction": {"grow": 4.0}, &"start": {"grow": 1.4}, &"step": {"grow": 1.2}, &"back": {"grow": 0.8}}, BUTT),
		Shape.PORTRAIT: _along({&"start": {"grow": 1.4}, &"step": {"grow": 1.2}, &"back": {"grow": 0.8}, &"instruction": {"basis": 1.0}}, Themes.TILES),
	})
	var words := Phrase.of("A MOMENT: it lands once, when something worth marking has happened, and one button knocks it away.")
	# turned, the banner is only as tall as its two lines
	var body := ui.by_shape({&"strip": pieces.tabs([_screens()]), &"banner": banner}, {
		Shape.LANDSCAPE: _down({&"strip": {"grow": 1.0}, &"banner": {"basis": 0.17}}, BUTT_DOWN),
		Shape.PORTRAIT: _down({&"strip": {"grow": 1.0}, &"banner": {}}, BUTT_DOWN),
	})
	return ui.app(STALL, [ui.stack([body, pieces.moment(words), pieces.bubble()])])


func _screens() -> Desc:
	return ui.screen(&"content", [ui.stack([_about(), _readouts(), _navigation(), _sets(), _graph(), _matrix(), _detail()] + more.screens())])


## The start: five notice blocks of uneven width, then the looks, wide.
func _about() -> Desc:
	var boxes := [
		[3, Phrase.of("WHAT THIS IS"), [Phrase.of("A market stall of crates of fruit, told one component at a time."), Phrase.of("Every screen is one of the six flaps in the strip above."), Phrase.of("Nothing here is centred, aligned or padded to be polite.")]],
		[2, Phrase.of("THE STRIP"), [Phrase.of("Six flaps, butting; the one you stand on is cream and taller, welded into the panel."), Phrase.of("They are one black-ruled band, and that is the arrangement, not a fault.")]],
		[1, Phrase.of("THE BANNER"), [Phrase.of("Its words say what to do next."), Phrase.of("The glowing block is the one meant.")]],
		[1, Phrase.of("WORDS"), [Phrase.of("A crate is one item."), Phrase.of("The coin is c. Takings is what it made."), Phrase.of("Recent is four days. Marks are complaints.")]],
		[2, Phrase.of("TRY THIS"), [Phrase.of("Press START RESTOCKING: the banner asks for crates, 0 of 3."), Phrase.of("The glow jumps to PICK A CRATE with a bubble on it. Press it three times."), Phrase.of("A moment lands. CARRY ON knocks it away.")]],
	]
	var cells: Array = []
	for box: Array in boxes:
		var lines: Array = []
		for line: Phrase in box[2]:
			lines.append(ui.text(line, DemoTheme.READOUT))
		cells.append(_cell(box[1], "", ui.column(lines, DemoTheme.TIGHT)).span(box[0]))
	var looks := pieces.looks()
	var picking := ui.column([looks["worn"], ui.grid(looks["picks"], [0.2, 0.2, 0.2, 0.2, 0.2] as Array[float], SLABS)], DemoTheme.TIGHT)
	cells.append(_cell(Phrase.of("THE LOOK"), Phrase.of("One stall, ten languages - press one"), picking).span(3))
	return ui.screen(ABOUT, [ui.scroll(ui.grid(cells, [0.34, 0.3, 0.36] as Array[float], SLABS, {Shape.PORTRAIT: [0.5, 0.5]}))])


## One crate read six ways: a tall butting stack against a gulfed pair.
## Turned, the three stacks are one stack.
func _readouts() -> Desc:
	var read := pieces.readouts()
	# three readouts jammed together, no gutter: one tall block of the window
	var jammed := ui.column([
		_cell(Phrase.of("QUANTITY"), Phrase.of("The takings of the pear crate"), read["quantity"]).grow(1.4),
		_cell(Phrase.of("BAR"), Phrase.of("The same, as a fill; full is 100,000"), read["bar"]).grow(),
		_cell(Phrase.of("LABEL"), Phrase.of("The name of the crate, read live"), read["label"]).grow(),
	], BUTT_DOWN)
	# and beside it, two blocks with a chasm between them
	var apart := ui.column([
		_cell(Phrase.of("TRACE"), Phrase.of("Four days of takings"), read["trace"]).grow(2.0),
		_cell(Phrase.of("MARK"), Phrase.of("Complaints, a diamond each; pear has none"), read["mark"]).grow(),
	], CHASM)
	var last := ui.column([
		_cell(Phrase.of("RELATIVE"), Phrase.of("Closeness to another crate; press to compare"), read["relative"]).grow(2.0),
		_cell(Phrase.of("COUNTDOWN"), Phrase.of("Until the stall shuts"), pieces.clock()).grow(1.3),
	], BUTT_DOWN)
	var shares := {&"jammed": {"grow": 1.3}, &"apart": {"grow": 1.0}, &"last": {"grow": 1.1}}
	return ui.screen(READOUTS, [ui.by_shape({&"jammed": jammed, &"apart": apart, &"last": last}, {Shape.LANDSCAPE: _along(shares, BUTT), Shape.PORTRAIT: _down(shares, BUTT_DOWN)})])


## Cards and links: four controls butting, four cards on an uneven grid.
## Turned, the controls go two to a line, the grid has two columns, and the
## amount field stands over the disposition, a chasm still between them.
func _navigation() -> Desc:
	var ways := pieces.navigation()
	var cards := pieces.cards()
	var acting := pieces.acting()
	var controls := ui.by_shape({
		&"menu": _cell(Phrase.of("MENU LINK"), "", ways["menu"]),
		&"inline": _cell(Phrase.of("INLINE LINK"), "", ways["inline"]),
		&"back": _cell(Phrase.of("BACK"), "", ways["back"]),
		&"play": _cell(Phrase.of("PLAY"), Phrase.of("Opens the fig, your own"), ways["play"]),
	}, {
		Shape.LANDSCAPE: _along({&"menu": {"grow": 1.3}, &"inline": {"grow": 1.0}, &"back": {"grow": 1.0}, &"play": {"grow": 1.5}}, BUTT),
		Shape.PORTRAIT: _along({&"menu": HALF, &"inline": HALF, &"back": HALF, &"play": HALF}, Themes.TILES),
	})
	var grid := ui.grid([
		_cell(Phrase.of("CARD, LIST"), Phrase.of("A crate as a row; press to open"), cards["list"]).span(2),
		_cell(Phrase.of("CARD, TILE"), Phrase.of("The same crate"), cards["tile"]).span(1),
		_cell(Phrase.of("CARD, DENSE"), Phrase.of("Picture, takings, a button"), cards["dense"]).span(1),
		_cell(Phrase.of("CARD, EMPTY"), Phrase.of("An empty slot"), cards["empty"]).span(2),
	], [0.19, 0.15, 0.15, 0.17, 0.17, 0.17] as Array[float], SLABS, {Shape.PORTRAIT: [0.5, 0.5]})
	var doing := ui.by_shape({
		&"amount": _cell(Phrase.of("AMOUNT FIELD"), Phrase.of("Type a number, Enter sets the price"), acting["amount"]),
		&"disposition": _cell(Phrase.of("DISPOSITION"), Phrase.of("One of three; the chosen opens its second half"), acting["disposition"]),
	}, {
		Shape.LANDSCAPE: _along({&"amount": {"grow": 1.0}, &"disposition": {"grow": 2.2}}, CHASM),
		Shape.PORTRAIT: _down({&"amount": {"grow": 1.0}, &"disposition": {"grow": 2.2}}, CHASM),
	})
	# turned, the controls and the cards are as tall as they need and what is left goes to the doing
	return ui.screen(NAVIGATION, [ui.by_shape({&"controls": controls, &"grid": grid, &"doing": doing}, {
		Shape.LANDSCAPE: _down({&"controls": {"basis": 0.2}, &"grid": {"grow": 1.0}, &"doing": {"basis": 0.28}}, BUTT_DOWN),
		Shape.PORTRAIT: _down({&"controls": {}, &"grid": {}, &"doing": {"grow": 1.0}}, BUTT_DOWN),
	})])


## The lists: one wide ledger jammed against a narrow stack of two - turned,
## the ledger over the stack, the two halves of the height alike, since
## every list here scrolls and the least any of them needs says nothing.
func _sets() -> Desc:
	var lists := pieces.lists()
	var narrow := ui.column([
		_cell(Phrase.of("TILES"), Phrase.of("The same crates"), lists["tiles"]).grow(),
		_cell(Phrase.of("BOARD"), Phrase.of("Ranked; scrolled to keep the fig in view"), lists["board"]).grow(1.4),
	], BUTT_DOWN)
	var wide := _cell(Phrase.of("ROWS"), Phrase.of("Add, sort, filter; press a row to open it"), lists["rows"])
	return ui.screen(SETS, [ui.by_shape({&"wide": wide, &"narrow": narrow}, {
		Shape.LANDSCAPE: _along({&"wide": {"grow": 2.2}, &"narrow": {"grow": 1.0}}, BUTT),
		Shape.PORTRAIT: _down({&"wide": {"grow": 1.0}, &"narrow": {"grow": 1.0}}, BUTT_DOWN),
	})])


## The suppliers: one enormous block, the picked one stamped under it.
func _graph() -> Desc:
	var graph := pieces.graph()
	var picked := ui.surface(Themes.CARD, [graph["picked"]])
	var whole := _cell(Phrase.of("SUPPLIERS"), Phrase.of("Who deals with whom; thicker is stronger. Drag, wheel, press a name"), graph["graph"])
	return ui.screen(GRAPH, [ui.column([whole.grow(), picked.basis(0.1)], BUTT_DOWN)])


## Crate against crate: the whole window, one block, bled to the edges.
func _matrix() -> Desc:
	return ui.screen(MATRIX, [_cell(Phrase.of("CRATE VS CRATE"), Phrase.of("The gap in takings, in thousands; one triangle, since a gap has no direction"), pieces.matrix(Phrase.of("Gap, thousands")))])


## One crate: an enormous note block, the flags as stamps across it.
func _detail() -> Desc:
	var note := pieces.note()
	var stamps: Array = []
	for flag: Desc in note["flags"]:
		stamps.append(flag.grow())
	var written := ui.column([note["field"], note["words"].grow(), ui.row(stamps, CHASM)], DemoTheme.TIGHT)
	# the detour goes to a screen not walked yet, and Back finds this note where it was left
	var ways := ui.row([note["back"].grow(), note["detour"].grow(2.0)], BUTT)
	var block := _cell(Phrase.of("THE NOTE"), Phrase.of("Type and Enter, tick the stamps, go to suppliers, come back: still here"), written)
	return ui.screen(DETAIL, [ui.column([note["title"].basis(0.14), block.grow(), ways.basis(0.14)], BUTT_DOWN)], null, {on_fill = drafts.begun})


## A cell: the loud label stuck across its top, the hint beside it, the
## thing itself filling what is left. Turned, a hint too long to stand
## beside its label breaks onto a line of its own under it, and the thing
## stands the look's own gap below - the ring round a thing with the focus
## is drawn outside it, and must never be drawn over the hint's words.
func _cell(title: Variant, hint: Variant, content: Desc) -> Desc:
	var label := ui.surface(Themes.CARD, [ui.text(title, STAMP)])
	var shares := {&"label": {"basis": 0.34}, &"hint": {"grow": 1.0}}
	var stuck := ui.by_shape({&"label": label, &"hint": ui.text(hint, DemoTheme.READOUT).hides_empty()}, {Shape.LANDSCAPE: _along(shares), Shape.PORTRAIT: _along(shares, Themes.TILES)})
	var filled := {&"stuck": {}, &"content": {"grow": 1.0}}
	return ui.surface(Themes.RAISED, [ui.by_shape({&"stuck": stuck, &"content": content}, {Shape.LANDSCAPE: _down(filled, DemoTheme.TIGHT), Shape.PORTRAIT: _down(filled)})])


## An arrangement of a shape's parts along a line, in the look's own row or
## in the line style given, the parts standing in the order their facts are
## given.
func _along(facts: Dictionary, style: StringName = Themes.ROW) -> Dictionary:
	return ui.row_of(facts.keys(), facts, style)


## The same, down a column.
func _down(facts: Dictionary, style: StringName = Themes.COLUMN) -> Dictionary:
	return ui.column_of(facts.keys(), facts, style)
