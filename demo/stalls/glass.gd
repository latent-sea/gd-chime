extends "res://demo/gallery/stall.gd"

const Shape := preload("res://addons/gd_chime/shape.gd")

## GLASSMORPHISM. The stall as frosted panes floating over one another: one
## vivid ground, the panel of screens over it, and every piece of the kit on
## its own translucent card hovering above that, each offset by fractions of
## the window so it visibly laps the pane beneath - frost only reads where
## there is something behind it to blur.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## How it differs from the placeholder: nothing sits in a strip or in a
## stacked column of captioned boxes. The flaps are glass and the panel they
## reveal is the widest pane of all, so the screens are held in glass rather
## than in a rectangle; the back-and-clock pill and the instruction capsule
## float at the foot over the whole of it; every screen is a ui.stack of
## panes placed by fractions, lapping each other and the panel behind them.
## The detail is not a page of its own: it is a note pane hovering over the
## collection, which stays visible behind it. Hints are inline, under each
## pane's title, rather than in boxes of their own.
##
## A pane laps only the bare foot of the pane under it, never its words, and
## no screen's words run under the pills: the second family's screens, which
## fill whatever they are given, are held clear of the foot the pills float
## over. On a window on its end the capsule's two moves hang under its words.

## The fractions the floating furniture takes: how tall the pills at the
## foot are, how far down they hang, and the margin panes are inset by.
const FOOT := 0.12
const HANGS := 0.86
const SIDE := 0.05
## The share of the panel the second family's screens leave bare at its
## foot: they fill whatever they are given, and the pills float there.
const CLEARS := 0.16


func worn() -> StringName:
	return &"glass"


## The whole stall: the flaps on the panel of screens filling the window,
## with the instruction capsule and the clock pill floating over its foot.
func arrange() -> Desc:
	# on a window on its end the words take a line of their own and the two moves share the line under them
	var act := ui.by_shape({&"words": pieces.instruction(), &"start": pieces.start(), &"step": pieces.step()}, {
		Shape.LANDSCAPE: _arrangement(false, Themes.ROW, {&"words": {"grow": 4.0}, &"start": {"grow": 1.0}, &"step": {"grow": 1.0}}),
		Shape.PORTRAIT: _arrangement(false, Themes.TILES, {&"words": {"basis": 1.0}, &"start": {"grow": 1.0}, &"step": {"grow": 1.0}}),
	})
	var capsule := _pane([act])
	var clock := _pane([ui.row([pieces.back().grow(), pieces.clock().grow(2.0)])])
	# the layers, back to front: the glass panel of screens, the two floating pills, the moment
	return ui.app(STALL, [ui.stack([
		pieces.tabs([_screens()]),
		_at(capsule, HANGS, FOOT, 0.03, 0.36),
		_at(clock, HANGS, FOOT, 0.67, 0.03),
		pieces.moment(Phrase.of("A MOMENT: the pane held closest to the eye, the thickest frost of all. One button dismisses it.")),
		pieces.bubble(),
	])])


## Every screen, one taking another's place inside the flaps' panel, the
## second family's held clear of the foot the pills float over.
func _screens() -> Desc:
	var clear := ui.column([ui.stack(more.screens()).grow(), _gap(CLEARS)])
	return ui.screen(&"content", [ui.stack([_about(), _readouts(), _navigation(), _sets(), _graph(), _matrix(), _detail(), clear])])


## What this is: three panes lapping each other down the window, and the
## looks on a pane of their own laid over the last of them - each lapping
## only the bare foot of the pane before it, never its words, and the last
## clear of the pills.
func _about() -> Desc:
	# each pane's title, hint and lines, and where it floats: the share clear above it and how tall it is
	var said := [
		[Phrase.of("A stall of glass"), Phrase.of("Everything you see is a pane"), [Phrase.of("Crates of fruit, one interface kit, ten design languages."), Phrase.of("Here every piece floats on its own frosted pane."), Phrase.of("A pane laps the pane under it, so the frost has something to blur.")], 0.01, 0.22],
		[Phrase.of("The flaps"), Phrase.of("Along the top of the widest pane"), [Phrase.of("One flap per screen, resting on the panel it reveals; the one you are on is taller and joined to it."), Phrase.of("Press one to go there.")], 0.195, 0.19],
		[Phrase.of("The pills at the foot"), Phrase.of("Floating over everything"), [Phrase.of("The wide one holds the INSTRUCTION BAR, whose words say what to do next, and the two buttons you can press."), Phrase.of("The small one holds BACK and the COUNTDOWN - time until the stall closes."), Phrase.of("Press start restocking, then pick a crate three times: a moment says you are done."), Phrase.of("A crate is one item on the stall, c is the coin, takings is what it has made.")], 0.345, 0.25],
	]
	var panes: Array = []
	for box: Array in said:
		var lines: Array = []
		for line: Phrase in box[2]:
			lines.append(ui.text(line, DemoTheme.READOUT).wraps())
		panes.append(_at(_pane([_titled(box[0], box[1], ui.column(lines, DemoTheme.TIGHT))]), box[3], box[4], SIDE + 0.02 * panes.size(), SIDE))
	var looks := pieces.looks()
	panes.append(_at(_pane([_titled(Phrase.of("The look"), Phrase.of("Press one; the whole stall is re-dressed"), ui.column([looks["worn"], ui.row(looks["picks"], Themes.TILES)], DemoTheme.TIGHT))]), 0.575, 0.26, SIDE, SIDE))
	return ui.screen(ABOUT, [ui.stack(panes)])


## One crate read six ways: two panes of readouts, the right one hung lower
## and lapping the left, and a line about the clock under both.
func _readouts() -> Desc:
	var read := pieces.readouts()
	var left := ui.column([
		_titled(Phrase.of("Quantity"), Phrase.of("The pear crate's takings"), read["quantity"]).grow(),
		_titled(Phrase.of("Bar"), Phrase.of("The same as a fill; full is 100,000"), read["bar"]).grow(),
		_titled(Phrase.of("Label"), Phrase.of("The crate's name, read live"), read["label"]).grow(),
	], DemoTheme.TIGHT)
	var right := ui.column([
		_titled(Phrase.of("Mark"), Phrase.of("Complaints, a diamond each"), read["mark"]).grow(),
		_titled(Phrase.of("Trace"), Phrase.of("The last four days of takings"), read["trace"]).grow(),
		_titled(Phrase.of("Relative"), Phrase.of("Closeness to another crate; press to compare"), read["relative"]).grow(),
	], DemoTheme.TIGHT)
	return ui.screen(READOUTS, [ui.stack([
		_at(_pane([left]), 0.05, 0.56, SIDE, 0.47),
		_at(_pane([right]), 0.15, 0.58, 0.56, SIDE),
		_at(_pane([ui.text(Phrase.of("The countdown is the clock in the small pill at the foot"), DemoTheme.READOUT).wraps()]), 0.62, 0.10, 0.10, 0.50),
	])])


## The ways about and the four cards: a pane of controls, a pane of cards
## lapping its bare foot, and the acting pane over the bare foot of that.
func _navigation() -> Desc:
	var ways := pieces.navigation()
	var made := pieces.cards()
	var acting := pieces.acting()
	var controls := ui.row([
		_titled(Phrase.of("Menu link"), Phrase.of("A button to a screen"), ways["menu"]).grow(),
		_titled(Phrase.of("Inline link"), Phrase.of("A name; press to open it"), ways["inline"]).grow(),
		_titled(Phrase.of("Back"), Phrase.of("The screen you came from"), ways["back"]).grow(),
		_titled(Phrase.of("Play"), Phrase.of("Opens your own crate, the fig"), ways["play"]).grow(),
	])
	var cards := ui.row([made["list"].grow(), made["tile"].grow(), made["dense"].grow(), made["empty"].grow()])
	var doing := ui.row([
		_titled(Phrase.of("Amount field"), Phrase.of("Type a number, Enter sets the price"), acting["amount"]).grow(),
		_titled(Phrase.of("Disposition"), Phrase.of("One of three; the chosen opens its second half"), acting["disposition"]).grow(2.0),
	])
	return ui.screen(NAVIGATION, [ui.stack([
		_at(_pane([controls]), 0.04, 0.20, SIDE, SIDE),
		_at(_pane([_titled(Phrase.of("Cards"), Phrase.of("List, tile, dense, empty - four panes on a pane"), cards)]), 0.235, 0.32, 0.03, 0.03),
		_at(_pane([doing]), 0.555, 0.26, 0.08, 0.08),
	])])


## The lists of crates: the rows pane wide and low, the tiles and the board
## floating at its right-hand side, lapping only its bare edge.
func _sets() -> Desc:
	var lists := pieces.lists()
	return ui.screen(SETS, [ui.stack([
		_at(_pane([_titled(Phrase.of("Collection, rows"), Phrase.of("Add, sort, filter; press a row to open it"), lists["rows"])]), 0.04, 0.70, SIDE, 0.47),
		_at(_pane([_titled(Phrase.of("Collection, tiles"), Phrase.of("The same crates as tiles"), lists["tiles"])]), 0.07, 0.33, 0.51, SIDE),
		_at(_pane([_titled(Phrase.of("Board"), Phrase.of("Ranked by takings; scrolled to keep your fig in view"), lists["board"], true)]), 0.42, 0.34, 0.51, 0.03),
	])])


## The suppliers, one pane over the whole of the panel.
func _graph() -> Desc:
	var graph := pieces.graph()
	var drawn := ui.column([graph["graph"].grow(), graph["picked"].basis(0.08)])
	return ui.screen(GRAPH, [ui.stack([_at(_pane([_titled(Phrase.of("Relationship graph"), Phrase.of("Who deals with whom; thicker is stronger. Drag, wheel, press a name, or press the zoom buttons"), drawn)]), 0.04, 0.72, SIDE, SIDE)])])


## Crate against crate, one pane, hung a little left of centre.
func _matrix() -> Desc:
	var made := pieces.matrix(Phrase.of("Gap, thousands"))
	return ui.screen(MATRIX, [ui.stack([_at(_pane([_titled(Phrase.of("Matrix"), Phrase.of("The gap in takings between each pair, in thousands; one triangle, since a gap has no direction"), made)]), 0.04, 0.72, 0.07, 0.12)])])


## The detail: the collection kept behind, and the note pane hovering over
## its bare foot, the crates themselves in view above it.
func _detail() -> Desc:
	var note := pieces.note()
	var lists := pieces.lists()
	# the detour goes to a screen not walked yet, and Back finds this note where it was left
	var ways := ui.row([note["back"], note["detour"]])
	var writing := ui.column([note["title"], ui.text(Phrase.of("Type a note and Enter, tick flags, go to suppliers, come back: still here"), DemoTheme.READOUT).hides_empty(), note["field"], note["words"], ui.row(note["flags"]), ways], DemoTheme.TIGHT)
	return ui.screen(DETAIL, [ui.stack([
		_at(_pane([_titled(Phrase.of("The crates, still there"), Phrase.of("The note hovers over them"), lists["tiles"])]), 0.04, 0.72, SIDE, SIDE),
		_at(_pane([writing]), 0.31, 0.43, 0.16, 0.16),
	])], null, {on_fill = drafts.begun})


## A pane of frost: the raised ground, with whatever it holds down a column,
## each piece taking its share of the pane's height.
func _pane(content: Array) -> Desc:
	var filling: Array = []
	for piece: Desc in content:
		filling.append(piece.grow())
	return ui.surface(Themes.RAISED, [ui.column(filling, DemoTheme.TIGHT)])


## A piece under its name and its hint, for a pane to hold.
func _titled(title: Variant, hint: Variant, content: Desc, wraps: bool = false) -> Desc:
	var said: Desc = ui.text(hint, DemoTheme.READOUT).hides_empty()
	return ui.column([ui.text(title, Themes.TITLE), said.wraps() if wraps else said, content.grow()], DemoTheme.TIGHT)


## One way of laying parts in a line, for by_shape: down or across, in this
## line style, each part with its facts, in the order the facts are given.
func _arrangement(down: bool, style: StringName, facts: Dictionary) -> Dictionary:
	return ui.column_of(facts.keys(), facts, style) if down else ui.row_of(facts.keys(), facts, style)


## A piece floated over its layer: the share left clear above it, how tall
## it is, and the share held at each side - all fractions, so two pieces
## given overlapping shares lap one another.
func _at(content: Desc, above: float, tall: float, left: float, right: float) -> Desc:
	var line := ui.row([_gap(left), content.grow(), _gap(right)])
	return ui.column([_gap(above), line.basis(tall), _gap(maxf(0.0, 1.0 - above - tall))])


## Room held open and nothing drawn in it.
func _gap(share: float) -> Desc:
	return ui.row([]).basis(share)
