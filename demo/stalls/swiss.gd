extends "res://demo/gallery/stall.gd"

const Shape := preload("res://addons/gd_chime/shape.gd")

## SWISS / INTERNATIONAL TYPOGRAPHIC STYLE. The same stall, arranged on an
## asymmetric grid: a wide empty left column, the places set as a thin line
## of words across the top, the instruction as one headline under them, and
## the content in a narrow measure with the right of the page left empty.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## How this differs from the placeholder: no captioned boxes anywhere - a
## block is a small grey caption over its content with a hairline under it,
## so the grid shows as rules, never as panels. The places are typographic
## tabs: grey words in a line, the one you are on black with a red rule
## broken under it, and no panel drawn at all. Hierarchy is type size
## alone: one headline per screen at the instruction's size, captions at a
## fifth of it, and nothing in between. Roughly two fifths of every screen
## is deliberately empty.
##
## ON A WINDOW ON ITS END the grid has one column where it had three: the
## empty left column goes, its one caption standing over the screens the
## way every block's caption stands over its content, the measure takes the
## width, and blocks set side by side stack or go two to a line - every
## line still starting on the one left edge. The places run along the top
## over the way back and the clock; the two actions stand over the
## instruction, each split at the same middle, so the bubble over the step
## lands in the clock's empty lower half as it does on a wide window, never
## on words. The same parts either way (by_shape.gd), and the wide
## arrangement is exactly the one this always had.

## The empty left column, and the measure the content is set to.
const MARGIN := 0.17
const MEASURE := 0.55
## A block on a turned window: under half the width, so two stand on a line with the gap between them.
const HALF := {"basis": 0.45, "grow": 1.0}


func worn() -> StringName:
	return &"swiss"


## The page: the strip of places and the headline over a measure of content,
## both starting at the same grid line, the left column left bare.
func arrange() -> Desc:
	var strip := ui.by_shape({&"margin": ui.text(""), &"tabs": pieces.tabs(), &"back": pieces.back(), &"clock": pieces.clock()}, {
		Shape.LANDSCAPE: _along({&"margin": {"basis": MARGIN}, &"tabs": {"grow": 6.0}, &"back": {"grow": 1.0}, &"clock": {"grow": 1.0}}),
		Shape.PORTRAIT: _along({&"tabs": {"basis": 1.0}, &"back": HALF, &"clock": HALF, &"margin": {}}, Themes.TILES),
	})
	var head := ui.by_shape({&"margin": ui.text(""), &"instruction": pieces.instruction(), &"start": pieces.start(), &"step": pieces.step()}, {
		Shape.LANDSCAPE: _along({&"margin": {"basis": MARGIN}, &"instruction": {"grow": 6.0}, &"start": {"grow": 1.0}, &"step": {"grow": 1.0}}),
		Shape.PORTRAIT: _along({&"start": HALF, &"step": HALF, &"margin": {}, &"instruction": {"basis": 1.0}}, Themes.TILES),
	})
	var body := ui.by_shape({&"caption": ui.text(Phrase.of("The stall"), Themes.REASON), &"screens": _screens()}, {
		Shape.LANDSCAPE: _along({&"caption": {"basis": MARGIN}, &"screens": {"grow": 1.0}}),
		Shape.PORTRAIT: _down({&"caption": {}, &"screens": {"grow": 1.0}}),
	})
	# turned, the strip and the headline are as tall as their two lines each
	var page := ui.by_shape({&"strip": strip, &"head": head, &"body": body}, {
		Shape.LANDSCAPE: _down({&"strip": {"basis": 0.08}, &"head": {"basis": 0.15}, &"body": {"grow": 1.0}}),
		Shape.PORTRAIT: _down({&"strip": {}, &"head": {}, &"body": {"grow": 1.0}}),
	})
	return ui.app(STALL, [ui.stack([page, pieces.moment(Phrase.of("Three crates picked. This is a moment: it appears once, and one word dismisses it.")), pieces.bubble()])])


func _screens() -> Desc:
	return ui.screen(&"content", [ui.stack([_about(), _readouts(), _navigation(), _sets(), _graph(), _matrix(), _detail()] + more.screens())])


## The opening: the headline, a short measure of note, and the looks.
func _about() -> Desc:
	var lines: Array = []
	for line: Phrase in [Phrase.of("Crates of fruit, one component at a time."), Phrase.of("The words along the top are the places; press one to go there."), Phrase.of("The instruction is the line that says what to do next."), Phrase.of("The two words paired with it are what you can do now; the glowing one is meant."), Phrase.of("Press start restocking, then pick a crate three times."), Phrase.of("A crate is one item on the stall. c is the coin; takings is what it has made; marks are complaints.")]:
		lines.append(ui.text(line, DemoTheme.READOUT))
	var looks := pieces.looks()
	var wearing := _headed(Phrase.of("The same stall in each design language"), ui.column([ui.row(looks["picks"], Themes.TILES), looks["worn"]], DemoTheme.TIGHT))
	return ui.screen(ABOUT, [ui.column([ui.text(Phrase.of("A stall of crates."), Themes.WORDS).basis(0.16), _measure(ui.column(lines, DemoTheme.TIGHT), MEASURE).basis(0.34), wearing.basis(0.22), ui.text("").grow()])])


## One crate, six ways: the readouts on a three-column grid, a tenth of the
## width left bare at the right, a rule under each - turned, two columns,
## the same tenth bare.
func _readouts() -> Desc:
	var read := pieces.readouts()
	var cells: Array = [
		_headed(Phrase.of("Takings"), read["quantity"]),
		_headed(Phrase.of("The same, against 100,000"), read["bar"]),
		_headed(Phrase.of("The name, read live"), read["label"]),
		_headed(Phrase.of("Complaints, a diamond each"), read["mark"]),
		_headed(Phrase.of("The last four days"), read["trace"]),
		_headed(Phrase.of("Closeness; press to compare"), read["relative"]),
	]
	return ui.screen(READOUTS, [ui.column([ui.text(Phrase.of("One crate, six ways."), Themes.WORDS).basis(0.16), ui.grid(cells, [0.3, 0.3, 0.3], Themes.GRID, {Shape.PORTRAIT: [0.45, 0.45]}).basis(0.56), ui.text(Phrase.of("The clock at the end of the strip is the seventh: time until the stall closes"), Themes.REASON).basis(0.06), ui.text("").grow()])])


## Cards and links: three bands on the same four-column grid - the ways in,
## the four cards, then the amount field and the disposition. Turned, the
## grid has two columns with the same share bare, the ways in go two to a
## line, and the amount field stands over the disposition.
func _navigation() -> Desc:
	var went := pieces.navigation()
	var cards := pieces.cards()
	var acting := pieces.acting()
	var ways := ui.by_shape({&"menu": _headed(Phrase.of("To a place"), went["menu"]), &"inline": _headed(Phrase.of("A name, opened"), went["inline"]), &"back": _headed(Phrase.of("Whence you came"), went["back"]), &"play": _headed(Phrase.of("Your own crate"), went["play"]), &"bare": ui.text("")}, {
		Shape.LANDSCAPE: _along({&"menu": {"grow": 1.0}, &"inline": {"grow": 1.0}, &"back": {"grow": 1.0}, &"play": {"grow": 1.0}, &"bare": {"grow": 0.6}}),
		Shape.PORTRAIT: _along({&"menu": HALF, &"inline": HALF, &"back": HALF, &"play": HALF, &"bare": {}}, Themes.TILES),
	})
	var laid := ui.grid([
		_headed(Phrase.of("As a row"), cards["list"]),
		_headed(Phrase.of("As a tile"), cards["tile"]),
		_headed(Phrase.of("Dense"), cards["dense"]),
		_headed(Phrase.of("Empty, and the ways to fill it"), cards["empty"]),
	], [0.23, 0.23, 0.23, 0.23], Themes.GRID, {Shape.PORTRAIT: [0.46, 0.46]})
	var acts := ui.by_shape({&"amount": _headed(Phrase.of("Type a number, Enter sets it"), acting["amount"]), &"disposition": _headed(Phrase.of("One of three; the chosen opens its second half"), acting["disposition"]), &"bare": ui.text("")}, {
		Shape.LANDSCAPE: _along({&"amount": {"grow": 1.0}, &"disposition": {"grow": 2.0}, &"bare": {"grow": 0.6}}),
		Shape.PORTRAIT: _down({&"amount": {"grow": 1.0}, &"disposition": {"grow": 2.0}, &"bare": {}}),
	})
	return ui.screen(NAVIGATION, [ui.column([ui.text(Phrase.of("Cards and links."), Themes.WORDS).basis(0.12), ways.basis(0.15), laid.basis(0.33), acts.grow()])])


## Lists of crates: the rows set to the measure, the tiles and the board
## stacked beside them in the narrower column - turned, stacked under them.
func _sets() -> Desc:
	var lists := pieces.lists()
	var beside := ui.column([_headed(Phrase.of("The same crates as tiles"), lists["tiles"]).grow(), _headed(Phrase.of("Ranked by takings, your fig kept in view"), lists["board"]).grow()])
	var spread := ui.by_shape({&"rows": _headed(Phrase.of("Add, sort, filter; press a row to open it"), lists["rows"]), &"beside": beside, &"bare": ui.text("")}, {
		Shape.LANDSCAPE: _along({&"rows": {"basis": 0.46}, &"beside": {"basis": 0.36}, &"bare": {"grow": 1.0}}),
		Shape.PORTRAIT: _down({&"rows": {"grow": 1.0}, &"beside": {"grow": 1.0}, &"bare": {}}),
	})
	return ui.screen(SETS, [ui.column([ui.text(Phrase.of("Lists of crates."), Themes.WORDS).basis(0.14), spread.grow()])])


## The family of suppliers, set to the measure with the right left empty.
func _graph() -> Desc:
	var drawing := pieces.graph()
	var drawn := _headed(Phrase.of("Who deals with whom; thicker is stronger. Drag, wheel, press a name"), ui.column([drawing["graph"].grow(), drawing["picked"].basis(0.1)]))
	return ui.screen(GRAPH, [ui.column([ui.text(Phrase.of("Suppliers."), Themes.WORDS).basis(0.14), _measure(drawn, 0.72).grow()])])


## Crate against crate: one triangle, since a gap has no direction.
func _matrix() -> Desc:
	var grid := _headed(Phrase.of("The gap in takings between each pair, in thousands"), pieces.matrix(Phrase.of("Gap, thousands")))
	return ui.screen(MATRIX, [ui.column([ui.text(Phrase.of("Crate against crate."), Themes.WORDS).basis(0.14), _measure(grid, 0.7).grow()])])


## One crate: its name as the headline, a short measure of note, and the
## flags as a ragged-right row of words.
func _detail() -> Desc:
	var note := pieces.note()
	# the ragged right: the flags packed from the left, the rest of the line bare
	var ragged := ui.row(note["flags"] + [ui.text("").grow()], DemoTheme.TIGHT)
	var writing := _headed(Phrase.of("Type a note and Enter, tick flags, go to suppliers, come back: still here"), ui.column([note["field"], note["words"], ragged], DemoTheme.TIGHT))
	# the detour goes to a place not walked yet, and Back finds this note where it was left
	var ways := ui.row([note["back"], note["detour"], ui.text("").grow()])
	return ui.screen(DETAIL, [ui.column([ui.text(picked_words(), Themes.WORDS).basis(0.16), _measure(writing, MEASURE).basis(0.4), ways.basis(0.1), ui.text("").grow()])], null, {on_fill = drafts.begun})


## A block: a small caption over its content, a hairline under the whole -
## the rule that replaces the placeholder's box.
func _headed(caption: Variant, content: Desc) -> Desc:
	return ui.surface(Themes.RAISED, [ui.column([ui.text(caption, Themes.REASON), content.grow()], DemoTheme.TIGHT)])


## Set to the measure: the content on the left, this share of the width,
## the rest empty. Turned, the page is narrower than any measure, and the
## content takes all of it.
func _measure(content: Desc, share: float) -> Desc:
	return ui.by_shape({&"content": content, &"bare": ui.text("")}, {
		Shape.LANDSCAPE: _along({&"content": {"basis": share}, &"bare": {"grow": 1.0}}),
		Shape.PORTRAIT: _along({&"content": {"grow": 1.0}, &"bare": {}}),
	})


## An arrangement of a shape's parts along a line, in the look's own row or
## in the line style given, the parts standing in the order their facts are
## given.
func _along(facts: Dictionary, style: StringName = Themes.ROW) -> Dictionary:
	return ui.row_of(facts.keys(), facts, style)


## The same, down a column.
func _down(facts: Dictionary, style: StringName = Themes.COLUMN) -> Dictionary:
	return ui.column_of(facts.keys(), facts, style)
