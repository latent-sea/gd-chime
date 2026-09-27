extends "res://demo/gallery/stall.gd"

const Shape := preload("res://addons/gd_chime/shape.gd")

## MATERIAL DESIGN, arranged. The placeholder stacks captioned boxes under a
## strip; this arranges the same stall the way paper-made-of-light does. A
## top app bar carries the name of the place and, directly beneath it with
## no air between, the tabs as the indicator row on the panel of screens -
## the tab you are on is underlined, not boxed. The work is elevated cards
## on the grid of eight, grouped so that one card holds one idea. The
## instruction bar is a snackbar-like strip along the foot. The primary
## action sits bottom right of the content, a raised pair the eye falls to
## last. The detail is not a card among cards: it is a sheet with a top app
## bar of its own, back and the detour link in it.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --path <this folder> --script res://demo/stalls/material.gd
##
## Approximated: a true floating action button overlays the content, but a
## stack lays every piece across the whole of itself, so an overlaid row
## would swallow the presses of the cards beneath it. The action pair is
## therefore the last band of the content column, justified to the end.
## The detail's own app bar reuses the pieces' back and detour, which are
## the same two ways the placeholder puts in a row at the screen's foot.
##
## ON A WINDOW ON ITS END the bars are only as tall as what they hold - an
## app bar and a snackbar are a height, not a share of the window - and the
## places take the height that frees. Two panels side by side stand one over
## the other, and the grids of cards have fewer columns.

## The cards of a screen three to a row on a wide window, and the looks six.
const THIRDS: Array[float] = [0.333, 0.333, 0.334]
const SIXTHS: Array[float] = [0.166, 0.166, 0.167, 0.167, 0.167, 0.167]
## On a window on its end the cards of guidance are one to a row, the cards
## of readouts two, and the looks four.
const ONE_WIDE := {Shape.PORTRAIT: [1.0]}
const TWO_WIDE := {Shape.PORTRAIT: [0.5, 0.5]}
const FOUR_WIDE := {Shape.PORTRAIT: [0.25, 0.25, 0.25, 0.25]}


## The look this demo is drawn in.
func worn() -> StringName:
	return &"material"


## The arrangement: app bar over the indicator row on the panel of screens,
## the action pair bottom right of the content, the snackbar along the foot.
func arrange() -> Desc:
	# on a window on its end each bar is only as tall as what it holds, and the places take the height that frees
	var content := ui.by_shape({&"places": pieces.tabs([_screens()]), &"pair": _action_pair()}, {
		Shape.LANDSCAPE: _arrangement(true, Themes.COLUMN, {&"places": {"grow": 1.0}, &"pair": {"basis": 0.12}}),
		Shape.PORTRAIT: _arrangement(true, Themes.COLUMN, {&"places": {"grow": 1.0}, &"pair": {}}),
	})
	var snack := ui.surface(Themes.CARD, [pieces.instruction()])
	var page := ui.by_shape({&"bar": _app_bar(), &"content": content, &"snack": snack}, {
		Shape.LANDSCAPE: _arrangement(true, Themes.COLUMN, {&"bar": {"basis": 0.1}, &"content": {"grow": 1.0}, &"snack": {"basis": 0.1}}),
		Shape.PORTRAIT: _arrangement(true, Themes.COLUMN, {&"bar": {}, &"content": {"grow": 1.0}, &"snack": {}}),
	})
	return ui.app(STALL, [ui.stack([page, pieces.moment(Phrase.of("This is a MOMENT: it appears once when something worth marking has happened, and one button dismisses it.")), pieces.bubble()])])


## The top app bar: the leading way back, the title and the trailing clock
## on one line, on a sheet; the flaps meet its underside.
func _app_bar() -> Desc:
	var line := ui.row([pieces.back().basis(0.2), ui.text(Phrase.of("The stall"), Themes.TITLE).grow(4.0), pieces.clock().basis(0.1), ui.text("", DemoTheme.READOUT).basis(0.01)])
	return ui.surface(Themes.SURFACE, [line])


## The primary action, bottom right of the content: a row of spacing words
## and the two raised buttons, justified to the end.
func _action_pair() -> Desc:
	return ui.row([ui.text("", DemoTheme.READOUT).grow(6.0), pieces.start().basis(0.18), pieces.step().basis(0.18), ui.text("", DemoTheme.READOUT).basis(0.01)])


## Every place, one taking another's place inside the flaps' panel.
func _screens() -> Desc:
	return ui.screen(&"content", [ui.stack([_about(), _readouts(), _navigation(), _sets(), _graph(), _matrix(), _detail()] + more.screens())])


## One elevated card: its heading, its supporting line, and the thing itself,
## with the air the grid of eight asks for.
func _card(heading: Variant, supporting: Variant, content: Desc) -> Desc:
	return ui.surface(Themes.RAISED, [ui.column([ui.text(heading, Themes.TITLE), ui.text(supporting, DemoTheme.READOUT).hides_empty(), content.grow()], DemoTheme.TIGHT)])


## One way of laying parts in a line, for by_shape: down or across, in this
## line style, each part with its facts, in the order the facts are given.
func _arrangement(down: bool, style: StringName, facts: Dictionary) -> Dictionary:
	return ui.column_of(facts.keys(), facts, style) if down else ui.row_of(facts.keys(), facts, style)


## Two panels side by side on a wide window, and the first over the second
## on a window on its end, each taking an even share of the line either way.
func _side_by_side(first: Desc, second: Desc) -> Desc:
	var even := {&"first": {"grow": 1.0}, &"second": {"grow": 1.0}}
	return ui.by_shape({&"first": first, &"second": second}, {
		Shape.LANDSCAPE: _arrangement(false, Themes.ROW, even),
		Shape.PORTRAIT: _arrangement(true, Themes.COLUMN, even),
	})


## A card of plain lines, for the words that only need reading.
func _lines(heading: Variant, said: Array) -> Desc:
	var lines: Array = []
	for line: Phrase in said:
		lines.append(ui.text(line, DemoTheme.READOUT))
	return _card(heading, "", ui.column(lines, DemoTheme.TIGHT))


## Start here: the guidance in cards of three columns, the look picker last.
func _about() -> Desc:
	var cards := [
		_lines(Phrase.of("What this is"), [Phrase.of("The interface kit as a market stall of crates of fruit."), Phrase.of("Every card holds one component and what to try with it."), Phrase.of("The tabs under the title move between the places.")]),
		_lines(Phrase.of("The app bar"), [Phrase.of("The title, the closing-time countdown and back, on one line."), Phrase.of("Under them the tabs, sitting on the panel they reveal."), Phrase.of("The one you are on is underlined, not boxed.")]),
		_lines(Phrase.of("The strip along the foot"), [Phrase.of("The instruction bar, in the second person: what to do next."), Phrase.of("Idle it says the guide's words; mid-act it counts the steps."), Phrase.of("The two buttons bottom right are the actions you can take.")]),
		_lines(Phrase.of("Try this"), [Phrase.of("Press start restocking: the strip asks for crates, 0 of 3."), Phrase.of("The glow moves to pick a crate, a bubble pointing at it."), Phrase.of("Press it three times; a moment says you are done.")]),
		_lines(Phrase.of("Words you will see"), [Phrase.of("A crate is one item on the stall. c is the coin."), Phrase.of("Takings is what it has made; recent is the last four days."), Phrase.of("Marks is how many complaints it has had.")]),
	]
	var looks := pieces.looks()
	var look := _card(Phrase.of("The look"), Phrase.of("The same stall in each design language; press one"), ui.column([looks["worn"], ui.grid(looks["picks"], SIXTHS, Themes.GRID, FOUR_WIDE)], DemoTheme.TIGHT))
	return ui.screen(ABOUT, [ui.scroll(ui.column([ui.grid(cards, THIRDS, Themes.GRID, ONE_WIDE).grow(2.0), look.grow()]))])


## One crate, six ways: the readouts as a grid of small cards.
func _readouts() -> Desc:
	var read := pieces.readouts()
	var cards := [
		_card(Phrase.of("Quantity"), Phrase.of("The pear crate's takings"), read["quantity"]),
		_card(Phrase.of("Bar"), Phrase.of("The same, as a fill; full is 100,000"), read["bar"]),
		_card(Phrase.of("Label"), Phrase.of("The crate's name, read live"), read["label"]),
		_card(Phrase.of("Mark"), Phrase.of("Complaints, a diamond each; pear has none"), read["mark"]),
		_card(Phrase.of("Trace"), Phrase.of("The last four days' takings"), read["trace"]),
		_card(Phrase.of("Relative"), Phrase.of("Closeness to another crate; press to compare"), read["relative"]),
	]
	var clock := _card(Phrase.of("Countdown"), Phrase.of("In the app bar, at the title's right"), ui.text(Phrase.of("Time until the stall closes"), DemoTheme.READOUT))
	return ui.screen(READOUTS, [ui.column([ui.grid(cards, THIRDS, Themes.GRID, TWO_WIDE).grow(3.0), clock.grow()])])


## Cards and links: the four ways in one card, the four cards beside, the
## acting under them - two columns, so no band holds more than two ideas.
func _navigation() -> Desc:
	var got := pieces.navigation()
	var shown := pieces.cards()
	var acting := pieces.acting()
	var named: Array = []
	for way: Array in [[Phrase.of("Menu link"), "menu"], [Phrase.of("Inline link"), "inline"], [Phrase.of("Back"), "back"], [Phrase.of("Play"), "play"]]:
		named.append(ui.column([ui.text(way[0], DemoTheme.READOUT), got[way[1]]], DemoTheme.TIGHT))
	var cards := ui.grid([
		_card(Phrase.of("Card, list"), Phrase.of("A crate as a row; press to open"), shown["list"]),
		_card(Phrase.of("Card, tile"), Phrase.of("The same crate as a tile"), shown["tile"]),
		_card(Phrase.of("Card, dense"), Phrase.of("Live picture, takings, a button"), shown["dense"]),
		_card(Phrase.of("Card, empty"), Phrase.of("An empty slot and the ways to fill it"), shown["empty"]),
	], [0.5, 0.5])
	var left := ui.column([
		_card(Phrase.of("The four ways across"), Phrase.of("Each opens a place; back returns the one you came from"), ui.grid(named, [0.5, 0.5])).grow(),
		_card(Phrase.of("Amount field"), Phrase.of("Type a number, Enter sets the price"), acting["amount"]).grow(),
		_card(Phrase.of("Disposition"), Phrase.of("One of three; the chosen opens its second half"), acting["disposition"]).grow(),
	])
	# taller than its room on a wide window, it scrolls within it rather than pushing the bars off the window
	return ui.screen(NAVIGATION, [ui.scroll(_side_by_side(left, cards))])


## Lists of crates: the rows card wide on the left, tiles and the board stacked.
func _sets() -> Desc:
	var lists := pieces.lists()
	var others := ui.column([
		_card(Phrase.of("Collection, tiles"), Phrase.of("The same crates as tiles"), lists["tiles"]).grow(),
		_card(Phrase.of("Board"), Phrase.of("Ranked by takings; scrolled to keep your fig in view"), lists["board"]).grow(),
	])
	var rows := _card(Phrase.of("Collection, rows"), Phrase.of("Add, sort, filter; press a row to open it"), lists["rows"])
	return ui.screen(SETS, [_side_by_side(rows, others)])


## Suppliers: one card the width of the content, the graph filling it.
func _graph() -> Desc:
	var drawn := pieces.graph()
	var graph := ui.column([drawn["graph"].grow(), drawn["picked"].basis(0.08)])
	return ui.screen(GRAPH, [_card(Phrase.of("Relationship graph"), Phrase.of("Who deals with whom; thicker is stronger. Drag, wheel, press a name"), graph)])


## Crate against crate: one card, one triangle, since a gap has no direction.
func _matrix() -> Desc:
	return ui.screen(MATRIX, [_card(Phrase.of("Matrix"), Phrase.of("The gap in takings between each pair, in thousands"), pieces.matrix(Phrase.of("Gap, thousands")))])


## One crate, as a sheet: its own top app bar carrying back, the crate's
## name and the detour to the suppliers, and the note under it.
func _detail() -> Desc:
	var note := pieces.note()
	# the detour goes to a place not walked yet, and Back finds this note where it was left
	var sheet_bar := ui.surface(Themes.SURFACE, [ui.row([note["back"].basis(0.18), note["title"].grow(4.0), note["detour"].basis(0.18), ui.text("", DemoTheme.READOUT).basis(0.01)])])
	var written := _card(Phrase.of("A note kept with this crate"), Phrase.of("Type a note and Enter, tick flags, go to suppliers, come back: still here"), ui.column([note["field"], note["words"], ui.row(note["flags"])], DemoTheme.TIGHT))
	return ui.screen(DETAIL, [ui.column([sheet_bar.basis(0.14), written.grow()])], null, {on_fill = drafts.begun})
