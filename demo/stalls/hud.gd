extends "res://demo/gallery/stall.gd"

const Shape := preload("res://addons/gd_chime/shape.gd")

## DARK-MODE HUD: the stall as an instrument panel. Where the placeholder
## stacks captioned boxes down one column, this pins its panels to the
## edges of the glass and keeps the middle clear: the screens are one
## centre panel with bracketed flaps along its top edge, a thin left rail
## carries the countdown, a thin right rail carries the way back, and a
## bottom strip carries the instruction with its two actions at the far
## right. Both rails are pinned outside the tab set, so they stay whatever
## flap is down. The centre is never furniture: it is whatever the screen
## is about, the board, the matrix, the graph, the cards. Captions are
## small monospaced labels at a panel's top corner, the way a readout is
## named on a HUD.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## ON A WINDOW ON ITS END the frame is still pinned to the edges of the
## glass, but a rail cannot stand beside a view barely wider than its
## words. So each rail turns into a strip across the glass, its panel at
## the head: the countdown's along the top edge, the way back's along the
## foot of the view. Under that the two actions share a line and the
## instruction runs along the very foot, so what is just above the step is
## the way back's dark glass - the bubble pointing at the step floats in
## it, as it floats in the right rail's glass on a wide window, never over
## the instruction's count or its way out. Panels that stood side by side
## stack, and a panel centred in the dark takes the width. It is the same
## parts either way (by_shape.gd), only arranged anew, so a line half typed
## and the focus survive the window turning; and the wide arrangement is
## exactly the one this always had.


## The look this demo is drawn in.
func worn() -> StringName:
	return &"hud"


## The pinned frame: the flapped centre panel between two rails, the
## instruction strip along the bottom.
func arrange() -> Desc:
	var middle := ui.by_shape({&"rail": _rail(), &"view": pieces.tabs([_screens()]), &"side": _side()}, {
		Shape.LANDSCAPE: _along({&"rail": {"basis": 0.14}, &"view": {"grow": 1.0}, &"side": {"basis": 0.12}}),
		Shape.PORTRAIT: _down({&"rail": {}, &"view": {"grow": 1.0}, &"side": {}}),
	})
	var acts := {&"instruction": pieces.instruction(), &"start": pieces.start(), &"step": pieces.step()}
	# turned, the two actions share a line and the instruction takes the next, along the very foot
	var strip := ui.by_shape(acts, {
		Shape.LANDSCAPE: _along({&"instruction": {"grow": 5.0}, &"start": {"grow": 1.0}, &"step": {"grow": 1.0}}),
		Shape.PORTRAIT: _along({&"start": {"grow": 1.0}, &"step": {"grow": 1.0}, &"instruction": {"basis": 1.0}}, Themes.TILES),
	})
	# the strip is held a hair off the bottom edge, so its brackets close; turned, it is as tall as its two lines
	var panel := ui.by_shape({&"middle": middle, &"strip": strip, &"edge": ui.text("")}, {
		Shape.LANDSCAPE: _down({&"middle": {"grow": 1.0}, &"strip": {"basis": 0.15}, &"edge": {"basis": 0.015}}),
		Shape.PORTRAIT: _down({&"middle": {"grow": 1.0}, &"strip": {}, &"edge": {"basis": 0.015}}),
	})
	return ui.app(STALL, [ui.stack([panel, pieces.moment(Phrase.of("A MOMENT: it appears once when something worth marking has happened, and one button dismisses it.")), pieces.bubble()])])


## Every screen, one taking another's place under the flaps.
func _screens() -> Desc:
	return ui.screen(&"content", [ui.stack([_about(), _readouts(), _navigation(), _sets(), _graph(), _matrix(), _detail()] + more.screens())])


## The left rail, pinned on every screen: the clock at its head, the glass
## below it left dark. Turned, the clock heads a strip across the top.
func _rail() -> Desc:
	var clock := _pinned(Phrase.of("Stall closes in"), pieces.clock())
	return ui.by_shape({&"clock": clock, &"glass": ui.text("")}, {
		Shape.LANDSCAPE: _down({&"clock": {"basis": 0.26}, &"glass": {"grow": 1.0}}),
		Shape.PORTRAIT: _along({&"clock": {"basis": 0.25}, &"glass": {"grow": 1.0}}),
	})


## The right rail, pinned likewise: the way back at its head. Turned, it
## heads a strip across the foot of the view, wide enough that the reason
## it cannot be used reads in one line, and the glass beyond it is the dark
## the bubble over the step floats in, as the rail's own glass is when wide.
func _side() -> Desc:
	var back := _pinned(Phrase.of("Way back"), pieces.back())
	return ui.by_shape({&"back": back, &"glass": ui.text("")}, {
		Shape.LANDSCAPE: _down({&"back": {"basis": 0.2}, &"glass": {"grow": 1.0}}),
		Shape.PORTRAIT: _along({&"back": {"basis": 0.35}, &"glass": {"grow": 1.0}}),
	})


## The briefing screen: one centred panel of words, with the looks along
## its foot the way a mode is picked on a panel.
func _about() -> Desc:
	var lines: Array = []
	for line: Phrase in [Phrase.of("PANEL LAYOUT - the frame is pinned, the middle is the view."), Phrase.of("FLAPS: the top edge of the centre panel; the one you are on is lit and"), Phrase.within("merges into the panel under it."), Phrase.of("STALL CLOSES IN: the countdown - time until the stall closes."), Phrase.of("WAY BACK: back where you came from. Both sit outside the flaps."), Phrase.of("BOTTOM STRIP: the instruction, and the two actions that go with it."), Phrase.of("TRY: press start restocking. The strip asks for crates, 0 of 3, and a stop"), Phrase.within("appears. The glow moves to pick a crate, a bubble pointing at it: press"), Phrase.within("it three times, and a moment says you are done."), Phrase.of("WORDS: a crate is one item on the stall, c is the coin, takings is what it"), Phrase.within("has made, recent is the last four days, marks are complaints.")]:
		lines.append(ui.text(line, DemoTheme.READOUT))
	var looks := pieces.looks()
	var body := ui.column([ui.text(Phrase.of("THE STALL"), Themes.TITLE), ui.column(lines, DemoTheme.TIGHT).grow(), looks["worn"], ui.grid(looks["picks"], [0.2, 0.2, 0.2, 0.2, 0.2]).basis(0.2)], DemoTheme.TIGHT)
	return ui.screen(ABOUT, [_centred(_pinned(Phrase.of("Briefing"), body), 3.0)])


## The readouts: the left column of the panel, six small instruments one
## under another, the middle left clear.
func _readouts() -> Desc:
	var read := pieces.readouts()
	var captions := {"quantity": Phrase.of("Takings, c"), "bar": Phrase.of("Takings, of 100,000"), "label": Phrase.of("Crate"), "mark": Phrase.of("Complaints"), "trace": Phrase.of("Last four days"), "relative": Phrase.of("Closeness - press to compare")}
	var instruments: Array = []
	for named: String in ["quantity", "bar", "label", "mark", "trace", "relative"]:
		instruments.append(_pinned(captions[named], read[named]).grow())
	return ui.screen(READOUTS, [ui.row([ui.column(instruments).basis(0.38), ui.text("").grow()])])


## The navigation: the four cards as the middle view, every control pinned
## down the right column - turned, pinned along the foot of the cards.
func _navigation() -> Desc:
	var held := pieces.cards()
	var ways := pieces.navigation()
	var acting := pieces.acting()
	var cards := ui.column([
		ui.row([_pinned(Phrase.of("Card, list - press to open"), held["list"]).grow(), _pinned(Phrase.of("Card, tile"), held["tile"]).grow()]).grow(),
		ui.row([_pinned(Phrase.of("Card, dense"), held["dense"]).grow(), _pinned(Phrase.of("Card, empty slot"), held["empty"]).grow()]).grow(),
	])
	var links := ui.column([ways["menu"], ways["inline"], ways["back"], ways["play"]], DemoTheme.TIGHT)
	var controls := ui.column([
		_pinned(Phrase.of("Links"), links).grow(),
		_pinned(Phrase.of("Price, c - type and Enter"), acting["amount"]).grow(),
		_pinned(Phrase.of("Disposition"), acting["disposition"]).grow(2.0),
	])
	return ui.screen(NAVIGATION, [ui.by_shape({&"cards": cards, &"controls": controls}, {
		Shape.LANDSCAPE: _along({&"cards": {"grow": 2.0}, &"controls": {"basis": 0.3}}),
		Shape.PORTRAIT: _down({&"cards": {"grow": 2.0}, &"controls": {"grow": 1.0}}),
	})])


## The sets: the lists as the middle view, the board beside them, the
## filter-set carried by the rows themselves. Turned, the lists head the
## view and the tiles and the board stand side by side under them.
func _sets() -> Desc:
	var sets := pieces.lists()
	var halves := {&"tiles": {"grow": 1.0}, &"board": {"grow": 1.0}}
	var beside := ui.by_shape({&"tiles": _pinned(Phrase.of("Crates, tiled"), sets["tiles"]), &"board": _pinned(Phrase.of("Board - ranked, your fig kept in view"), sets["board"])}, {Shape.LANDSCAPE: _down(halves), Shape.PORTRAIT: _along(halves)})
	var shares := {&"rows": {"grow": 1.3}, &"beside": {"grow": 1.0}}
	return ui.screen(SETS, [ui.by_shape({&"rows": _pinned(Phrase.of("Crates, listed - add, sort, filter"), sets["rows"]), &"beside": beside}, {Shape.LANDSCAPE: _along(shares), Shape.PORTRAIT: _down(shares)})])


## The graph: the middle given over to it whole, the picked supplier read
## off a line at its foot.
func _graph() -> Desc:
	var drawn := pieces.graph()
	var picture := ui.column([drawn["graph"].grow(), drawn["picked"].basis(0.08)])
	return ui.screen(GRAPH, [_pinned(Phrase.of("Suppliers - drag, wheel, press a name"), picture)])


## The matrix: one triangle, the whole middle, since a gap has no direction.
func _matrix() -> Desc:
	return ui.screen(MATRIX, [_pinned(Phrase.of("Gap in takings, thousands - one triangle"), pieces.matrix(Phrase.of("Gap, thousands")))])


## The detail: one centred panel over the dark, the note in it, the flags
## as bracketed toggles and the ways out along its foot.
func _detail() -> Desc:
	var note := pieces.note()
	# the detour goes to a screen not walked yet, and Back finds this note where it was left
	var ways := ui.row([note["back"], note["detour"]])
	var body := ui.column([note["title"], note["field"], note["words"], ui.row(note["flags"]).basis(0.14), ui.text("").grow(), ways.basis(0.16)], DemoTheme.TIGHT)
	return ui.screen(DETAIL, [_centred(_pinned(Phrase.of("Note kept with this crate"), body), 2.0)], null, {on_fill = drafts.begun})


## A pinned panel: its caption a small monospaced label at the top corner,
## the instrument itself filling the rest.
func _pinned(caption: Variant, content: Desc) -> Desc:
	return ui.surface(Themes.RAISED, [ui.column([ui.text(caption, DemoTheme.READOUT), content.grow()], DemoTheme.TIGHT)])


## One panel held in the middle of the glass, this much wider than the dark
## either side of it - turned, across the whole width, the dark gone from
## beside it, since its lines are as long as the glass is narrow.
func _centred(content: Desc, width: float) -> Desc:
	var across := ui.by_shape({&"left": ui.text(""), &"panel": content, &"right": ui.text("")}, {
		Shape.LANDSCAPE: _along({&"left": {"grow": 1.0}, &"panel": {"grow": width}, &"right": {"grow": 1.0}}),
		Shape.PORTRAIT: _along({&"left": {}, &"panel": {"grow": 1.0}, &"right": {}}),
	})
	return ui.column([ui.text("").grow(), across.grow(6.0), ui.text("").grow()])


## An arrangement of a shape's parts along a line, in the look's own row or
## in the line style given, the parts standing in the order their facts are
## given.
func _along(facts: Dictionary, style: StringName = Themes.ROW) -> Dictionary:
	return ui.row_of(facts.keys(), facts, style)


## The same, down a column.
func _down(facts: Dictionary, style: StringName = Themes.COLUMN) -> Dictionary:
	return ui.column_of(facts.keys(), facts, style)
