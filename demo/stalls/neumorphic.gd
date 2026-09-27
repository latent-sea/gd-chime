extends "res://demo/gallery/stall.gd"

const Shape := preload("res://addons/gd_chime/shape.gd")

## NEUMORPHISM (soft UI), arranged. The stall is ONE continuous surface:
## nothing is a different colour from the window, so nothing may be fenced
## off with a box or a rule. Hierarchy comes from height alone - a plate
## pushed out towards you, or a hollow pressed into the ground - and from
## the air between them, so the spacing is generous and the plates are few
## and broad.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## How it differs from the placeholder: no captioned boxes anywhere. The
## flaps are a strip of soft chips across the top with no panel under
## them, since a flap merging into a panel needs an edge and this language
## has none: the place you are on is the chip pressed INTO the surface,
## and the screens lie on the open surface below it. Each screen is one or
## two big rounded plates rather than a grid of little ones; related
## controls sit together on a single raised plate instead of one plate
## each; the readouts are a row of soft dials; the instruction is a sunken
## tray running the width of the bottom; the detail is one soft plate
## floating in the middle with the note pressed into it.
##
## A SCREEN TALLER THAN ITS ROOM SCROLLS within it rather than running on
## under the tray: the plates keep their height and their air.
##
## ON A WINDOW ON ITS END the strip is two: the chips across the whole
## width, and back and the clock under them; the strip is only as tall as
## that; and in the tray the two moves sit under the words.

## The hollow the instruction lies in, and the wide plate a cluster sits on.
const TRAY := &"Tray"
const PLATE := Themes.RAISED
## A dial: one readout on its own small raised tile.
const DIAL := Themes.CARD


func worn() -> StringName:
	return &"neumorphic"


## The whole surface: the chips across the top, the work below them, the
## instruction sunk into the bottom.
func arrange() -> Desc:
	var screens := ui.screen(&"content", [ui.stack([_about(), _readouts(), _navigation(), _sets(), _graph(), _matrix(), _detail()] + more.screens())])
	# on a window on its end the strip is only as tall as its two lines, and the screens take the rest
	var body := ui.by_shape({&"strip": _strip(), &"screens": screens}, {
		Shape.LANDSCAPE: _arrangement(true, Themes.COLUMN, {&"strip": {"basis": 0.12}, &"screens": {"grow": 1.0}}),
		Shape.PORTRAIT: _arrangement(true, Themes.COLUMN, {&"strip": {}, &"screens": {"grow": 1.0}}),
	})
	# the words and the two moves along the tray, or the moves on a line under the words on a window on its end
	var tray := ui.surface(TRAY, [ui.by_shape({&"words": pieces.instruction(), &"start": pieces.start(), &"step": pieces.step()}, {
		Shape.LANDSCAPE: _arrangement(false, Themes.ROW, {&"words": {"grow": 4.0}, &"start": {"grow": 1.0}, &"step": {"grow": 1.0}}),
		Shape.PORTRAIT: _arrangement(false, Themes.TILES, {&"words": {"basis": 1.0}, &"start": {"grow": 1.0}, &"step": {"grow": 1.0}}),
	})])
	# air all round the window: a shadow clipped by an edge stops reading as height
	var page := ui.column([_edge(), body.grow(), tray.basis(0.15), _edge()])
	var framed := ui.row([_edge(), page.grow(), _edge()])
	var said := Phrase.of("A MOMENT: it rises once when something worth marking has happened, and one button puts it down again.")
	return ui.app(STALL, [ui.stack([framed, pieces.moment(said), pieces.bubble()])])


## The strip: the places as soft chips across the top, with back and the
## clock at its right - under them, on a window on its end. The flaps carry
## no panel - the one you are on is the chip pressed into the surface, not a
## flap joined to an edge.
func _strip() -> Desc:
	return ui.by_shape({&"chips": pieces.tabs(), &"back": pieces.back(), &"clock": _dial(Phrase.of("Closing"), pieces.clock())}, {
		Shape.LANDSCAPE: _arrangement(false, Themes.ROW, {&"chips": {"grow": 6.0}, &"back": {"grow": 1.0}, &"clock": {"grow": 1.5}}),
		Shape.PORTRAIT: _arrangement(false, Themes.TILES, {&"chips": {"basis": 1.0}, &"back": {"grow": 1.0}, &"clock": {"grow": 1.5}}),
	})


## The first place: two plates of words on the open surface, and the looks
## as a cluster of soft chips under them.
func _about() -> Desc:
	var what := _cluster(Phrase.of("A stall, softly"), [
		Phrase.of("Crates of fruit on one counter, and the kit that draws them."),
		Phrase.of("Everything you see is the same colour as the surface behind it."),
		Phrase.of("A thing you may press is pushed out towards you; the place you"),
		Phrase.within("are standing, and anything you type into, is pressed in."),
		Phrase.of("The chips along the top are the six places. Back and the clock"),
		Phrase.within("sit with them; the clock counts down to the stall closing."),
	])
	var words := _cluster(Phrase.of("Words on the stall"), [
		Phrase.of("A crate is one item on the counter. c is the coin."),
		Phrase.of("Takings is what a crate has made; recent is the last four days."),
		Phrase.of("Marks are complaints. Press start restocking in the tray below,"),
		Phrase.within("then pick a crate three times - the glow and its bubble lead."),
	])
	var picks := pieces.looks()
	var looks := ui.surface(PLATE, [ui.column([picks["worn"], ui.row(picks["picks"], Themes.TILES)])])
	return ui.screen(ABOUT, [ui.scroll(ui.column([what.grow(), words.grow(), looks.grow()]))])


## The readouts as dials: two rows of soft tiles on the bare surface, the
## clock among them only by name, since it lives on the strip.
func _readouts() -> Desc:
	var read := pieces.readouts()
	var top := ui.row([
		_dial(Phrase.of("Takings"), read["quantity"]).grow(),
		_dial(Phrase.of("Against 100,000"), read["bar"]).grow(),
		_dial(Phrase.of("The name, live"), read["label"]).grow(),
	])
	var bottom := ui.row([
		_dial(Phrase.of("Four days"), read["trace"]).grow(),
		_dial(Phrase.of("Complaints"), read["mark"]).grow(),
		_dial(Phrase.of("Closeness; press to compare"), read["relative"]).grow(),
	])
	return ui.screen(READOUTS, [ui.column([top.grow(), bottom.grow()])])


## Three soft clusters: the ways through, the four cards, and the choosing.
## Each cluster is ONE plate holding several controls, never a plate each.
func _navigation() -> Desc:
	var went := pieces.navigation()
	var card := pieces.cards()
	var doing := pieces.acting()
	var ways := _plate(Phrase.of("Ways through: a menu, a name, back, and your own crate"), ui.row([
		went["menu"].grow(), went["inline"].grow(), went["back"].grow(), went["play"].grow(),
	]))
	var cards := _plate(Phrase.of("The same crate as a row, a tile, a dense card, and an empty slot"), ui.row([
		card["list"].grow(), card["tile"].grow(), card["dense"].grow(), card["empty"].grow(),
	]))
	var choosing := _plate(Phrase.of("Type a price and Enter; or choose one of three ways to let the crate go"), ui.row([
		doing["amount"].grow(), doing["disposition"].grow(2.0),
	]))
	return ui.screen(NAVIGATION, [ui.scroll(ui.column([ways.grow(), cards.grow(1.6), choosing.grow(1.4)]))])


## The lists: two broad plates and nothing else - the rows with their
## controls on the left, the tiles and the board stacked on the right.
func _sets() -> Desc:
	var kept := pieces.lists()
	var left := _plate(Phrase.of("Every crate, with add, sort and a filter; press one to open it"), kept["rows"])
	var right := ui.column([_plate(Phrase.of("The same crates as tiles"), kept["tiles"]).grow(), _plate(Phrase.of("Ranked by takings, your fig kept in view"), kept["board"]).grow()])
	return ui.screen(SETS, [ui.row([left.grow(), right.grow()])])


## The suppliers: one plate the width of the surface, the picked name under it.
func _graph() -> Desc:
	var drawn := pieces.graph()
	var inside := ui.column([drawn["graph"].grow(), drawn["picked"].basis(0.1)])
	return ui.screen(GRAPH, [_plate(Phrase.of("Who deals with whom; thicker is stronger. Drag, wheel, press a name, or the two soft buttons to zoom"), inside)])


## Crate against crate: one plate, one triangle.
func _matrix() -> Desc:
	return ui.screen(MATRIX, [_plate(Phrase.of("The gap in takings between each pair, in thousands; one triangle, since a gap has no direction"), pieces.matrix(Phrase.of("Gap, thousands")))])


## One crate: a single soft plate floating in the middle of the surface,
## with air all round it, and the note pressed into its face.
func _detail() -> Desc:
	var note := pieces.note()
	# the detour goes to a place not walked yet, and Back finds this note where it was left
	var ways := ui.row([note["back"].grow(), note["detour"].grow()])
	var face := ui.column([
		note["title"].basis(0.1),
		ui.text(Phrase.of("Type a note and Enter, tick what applies, walk to the suppliers and come back: it is still here"), DemoTheme.READOUT).basis(0.1),
		note["field"].basis(0.14),
		note["words"].basis(0.1),
		ui.row(note["flags"]).basis(0.16),
		ways.basis(0.16),
	])
	var middle := ui.row([_air(), ui.surface(PLATE, [face]).grow(4.0), _air()])
	return ui.screen(DETAIL, [ui.column([_air(), middle.grow(6.0), _air()])], null, {on_fill = drafts.begun})


## A cluster: one raised plate carrying several related controls, named by
## what to try with them, not fenced off with a caption box.
func _plate(hint: Variant, content: Desc) -> Desc:
	return ui.surface(PLATE, [ui.column([content.grow(), ui.text(hint, DemoTheme.READOUT).hides_empty().basis(0.12)])])


## A cluster of words: a title and its lines on one plate.
func _cluster(title: Variant, lines: Array) -> Desc:
	var said: Array = [ui.text(title, Themes.TITLE)]
	for line: Phrase in lines:
		said.append(ui.text(line, DemoTheme.READOUT))
	return ui.surface(PLATE, [ui.column(said, DemoTheme.TIGHT)])


## A dial: one readout on a small soft tile, its name beneath it.
func _dial(named: Variant, content: Desc) -> Desc:
	return ui.surface(DIAL, [ui.column([content.grow(), ui.text(named, DemoTheme.READOUT).basis(0.22)], DemoTheme.TIGHT)])


## One way of laying parts in a line, for by_shape: down or across, in this
## line style, each part with its facts, in the order the facts are given.
func _arrangement(down: bool, style: StringName, facts: Dictionary) -> Dictionary:
	return ui.column_of(facts.keys(), facts, style) if down else ui.row_of(facts.keys(), facts, style)


## Air: the empty surface between plates, which is half of the language.
func _air() -> Desc:
	return ui.text("").grow()


## The margin of bare surface at the window's edge.
func _edge() -> Desc:
	return ui.text("").basis(0.02)
