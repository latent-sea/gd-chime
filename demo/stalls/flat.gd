extends "res://demo/gallery/stall.gd"

const Shape := preload("res://addons/gd_chime/shape.gd")

## FLAT DESIGN, arranged: solid blocks on a uniform grid, every region a
## plain rectangle of colour of the same weight, no box inside a box. The
## tabs are flaps of equal blocks on the panel of screens; each screen is
## a uniform grid of equal cells, one piece per cell, its name a plain line
## above it; the instruction bar is one block across the bottom.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --path <this folder> --script res://demo/stalls/flat.gd
##
## ON A WINDOW ON ITS END the blocks stack instead of standing side by
## side, and none is built again (by_shape.gd): back and the clock are two
## equal blocks in a strip over the flaps, the instruction is a block over
## the act's two equal blocks, and SETS sets its three cells one over
## another. The grids keep their columns, each cell narrower.

## The readouts by name, each name said in words as its cell's heading.
const CELL_WORDS := {"quantity": "Quantity", "bar": "Bar", "label": "Label", "trace": "Trace", "mark": "Mark", "relative": "Relative"}

func worn() -> StringName:
	return &"flat"


func arrange() -> Desc:
	# back over the clock; on a window on its end, the two equal blocks side by side as a strip
	var side := ui.by_shape({&"back": pieces.back(), &"clock": pieces.clock()}, {Shape.LANDSCAPE: _arranged(true, [&"back", &"clock"]), Shape.PORTRAIT: _arranged(false, [&"back", &"clock"], {&"back": {"grow": 1.0}, &"clock": {"grow": 1.0}})})
	# the flaps on their panel with that beside them; on a window on its end, that strip over them
	var top := ui.by_shape({&"tabs": pieces.tabs([_screens()]), &"side": side}, {Shape.LANDSCAPE: _arranged(false, [&"tabs", &"side"], {&"tabs": {"grow": 6.0}, &"side": {"grow": 1.0}}), Shape.PORTRAIT: _arranged(true, [&"side", &"tabs"], {&"tabs": {"grow": 1.0}})})
	var acts := ui.row([pieces.start().grow(), pieces.step().grow()])
	# the instruction with the act's two blocks beside it; on a window on its end, the blocks under it
	var bar := ui.by_shape({&"words": pieces.instruction(), &"acts": acts}, {Shape.LANDSCAPE: _arranged(false, [&"words", &"acts"], {&"words": {"grow": 4.0}, &"acts": {"grow": 2.0}}), Shape.PORTRAIT: _arranged(true, [&"words", &"acts"], {&"acts": {"grow": 1.0}})})
	return ui.app(STALL, [ui.stack([ui.column([top.grow(), bar.basis(0.09)]), pieces.moment(), pieces.bubble()])])


## One arrangement of named parts, as by_shape takes it: down a column or
## along a row, in this order, each under the facts given here or none.
func _arranged(down: bool, order: Array, facts: Dictionary = {}) -> Dictionary:
	var given: Dictionary = {}
	# every part in its order, under the facts given for it or none
	for part: StringName in order:
		given[part] = facts.get(part, {})
	return ui.column_of(order, given) if down else ui.row_of(order, given)


func _screens() -> Desc:
	return ui.screen(&"content", [ui.stack([_about(), _readouts(), _navigation(), _sets(), _graph(), _matrix(), _detail()] + more.screens())])


## A cell of the grid: its name as a plain line, then the thing.
func _cell(title: Variant, content: Desc) -> Desc:
	return ui.column([ui.text(title, Themes.TITLE), content.grow()], DemoTheme.TIGHT)


func _about() -> Desc:
	var lines := [Phrase.of("A market stall with crates of fruit, laid out flat: every region an equal block."), Phrase.of("Flaps on the panel of screens, the instruction bar across the bottom, a grid of equal cells between."), Phrase.of("Press start restocking at the bottom, then pick a crate three times.")]
	var words: Array = []
	for line: Phrase in lines:
		words.append(ui.text(line, DemoTheme.READOUT))
	var looks := pieces.looks()
	return ui.screen(ABOUT, [ui.column([ui.column(words, DemoTheme.TIGHT), looks["worn"], ui.row(looks["picks"], Themes.TILES)])])


func _readouts() -> Desc:
	var read := pieces.readouts()
	var cells: Array = []
	# every readout, under its name said in words
	for named: String in CELL_WORDS:
		cells.append(_cell(Phrase.of(CELL_WORDS[named]), read[named]))
	return ui.screen(READOUTS, [ui.grid(cells, [1.0, 1.0, 1.0])])


func _navigation() -> Desc:
	var ways := pieces.navigation()
	var cards := pieces.cards()
	var acting := pieces.acting()
	var cells := [_cell(Phrase.of("Menu link"), ways["menu"]), _cell(Phrase.of("Inline link"), ways["inline"]), _cell(Phrase.of("Back"), ways["back"]), _cell(Phrase.of("Play"), ways["play"]), _cell(Phrase.of("Card, list"), cards["list"]), _cell(Phrase.of("Card, tile"), cards["tile"]), _cell(Phrase.of("Card, dense"), cards["dense"]), _cell(Phrase.of("Card, empty"), cards["empty"]), _cell(Phrase.of("Amount field"), acting["amount"]), _cell(Phrase.of("Disposition"), acting["disposition"]).span(3)]
	return ui.screen(NAVIGATION, [ui.grid(cells, [1.0, 1.0, 1.0, 1.0])])


func _sets() -> Desc:
	var lists := pieces.lists()
	var cells := {&"rows": _cell(Phrase.of("Collection, rows"), lists["rows"]), &"tiles": _cell(Phrase.of("Collection, tiles"), lists["tiles"]), &"board": _cell(Phrase.of("Board"), lists["board"])}
	var equal := {&"rows": {"grow": 1.0}, &"tiles": {"grow": 1.0}, &"board": {"grow": 1.0}}
	# three equal cells across; on a window on its end, three equal cells down
	return ui.screen(SETS, [ui.by_shape(cells, {Shape.LANDSCAPE: _arranged(false, cells.keys(), equal), Shape.PORTRAIT: _arranged(true, cells.keys(), equal)})])


func _matrix() -> Desc:
	return ui.screen(MATRIX, [_cell(Phrase.of("Gap in takings, thousands"), pieces.matrix())])


func _graph() -> Desc:
	var graph := pieces.graph()
	return ui.screen(GRAPH, [ui.column([_cell(Phrase.of("Suppliers: who deals with whom"), graph["graph"]).grow(), graph["picked"].basis(0.06)])])


func _detail() -> Desc:
	var note := pieces.note()
	var writing := ui.column([note["field"], note["words"], ui.row(note["flags"])], DemoTheme.TIGHT)
	return ui.screen(DETAIL, [ui.grid([_cell(picked_words(), writing).span(2), _cell(Phrase.of("Ways"), ui.row([note["back"], note["detour"]]))], [1.0, 1.0, 1.0])], null, {on_fill = drafts.begun})
