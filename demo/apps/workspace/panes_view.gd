extends RefCounted

const GdChime := preload("res://addons/gd_chime/gd_chime.gd")
const Workbench := preload("res://demo/apps/workspace/workbench.gd")

## The workspace's four panes, described: the project explorer, the SQL
## editor under the tabs of the queries open, the rows a run answered, and
## the columns of the dataset shown - each a pane of the shell (panes.gd).
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Description only: every piece is a recipe or a primitive over the
## workbench and the documents, and every press a declared action. A
## dataset, a query and the editor are each a menu's target, so a right
## press, the menu key or the pad's view button offers their actions, each
## refused as its own press would be. Each pane says what to do while it is
## empty rather than standing blank.

var _ui: GdChime.Ui
var _bench: Workbench
var _documents: GdChime.Documents


func _init(ui: GdChime.Ui, bench: Workbench, documents: GdChime.Documents) -> void:
	_ui = ui
	_bench = bench
	_documents = documents


## The project: the datasets it uses and its queries, each group shutting,
## each row a menu's target.
func explorer() -> GdChime.Desc:
	var ui: GdChime.Ui = _ui
	var dataset := func(item: GdChime.Bound) -> GdChime.Desc: return _row(item, Workbench.SHOWS, [Workbench.PREVIEWS, Workbench.SHOWS, Workbench.PUTS_IN])
	var query := func(item: GdChime.Bound) -> GdChime.Desc: return _row(item, GdChime.Documents.OPENS, [GdChime.Documents.OPENS, GdChime.Documents.CLOSES, Workbench.COPIES])
	var named := func(item: Dictionary) -> Variant: return item["value"]
	var groups: GdChime.Desc = GdChime.Sections.static_groups(ui, [
		{"heading": GdChime.Phrase.of("Datasets in this project"), "content": [ui.each(ui.bound(_bench.get_project), dataset, named)]},
		{"heading": GdChime.Phrase.of("Queries"), "content": [ui.each(ui.bound(_bench.get_queries), query, named)]},
	])
	return GdChime.Panes.titled(ui, GdChime.Phrase.of("Explorer"), groups)


## One row of the explorer: its words, pressed as the action, and the menu of the actions it offers.
func _row(item: GdChime.Bound, action: StringName, offers: Array) -> GdChime.Desc:
	var carried: GdChime.Bound = item.map(func(one: Variant) -> Dictionary: return {"value": null if one == null else one["value"]})
	return _ui.menu_target(offers, carried, [_ui.pressable(action, carried, [_ui.text(item.field("words"), GdChime.Themes.FACE)], &"MenuItem")])


## The editor: the tabs of the queries open between previous and next, over
## the query in front in a fixed width - or, with none open, the way to one.
func editor(expands: StringName) -> GdChime.Desc:
	var ui: GdChime.Ui = _ui
	var strip: GdChime.Desc = ui.row([ui.button(GdChime.Documents.SHOWS_PREVIOUS), GdChime.Tabs.documents(ui, _documents).grow(), ui.button(GdChime.Documents.SHOWS_NEXT)], &"Controls")
	var writing: GdChime.Desc = ui.area(Workbench.WRITES, ui.bound(_bench.get_words), &"Code")
	var nothing_open: GdChime.Desc = ui.column([ui.text(GdChime.Phrase.of("No query is open. Open one from the explorer, or search for one with the palette."), GdChime.Themes.REASON).wraps(), ui.row([ui.button(Workbench.MAKES)])])
	var open: GdChime.Bound = ui.bound(_documents.get_front).map(func(front: Variant) -> bool: return front != null)
	var body: GdChime.Desc = ui.menu_target([Workbench.RUNS, GdChime.Documents.CLOSES_FRONT, Workbench.MAKES, expands], {}, [ui.when(open, writing, nothing_open).keeps()])
	return GdChime.Panes.titled(ui, GdChime.Phrase.of("Query"), ui.column([strip, body.grow()], &"PaneColumn"))


## The rows the last run answered, in the floor's long table (long_table.gd)
## - sorted by a heading, picked and moved through by the keys and the pad
## as in any grid - under what the run said, or what to do before any run;
## its menu offers these two besides running.
func results(expands: StringName, folds: StringName) -> GdChime.Desc:
	var ui: GdChime.Ui = _ui
	var answer: GdChime.Bound = ui.bound(_bench.get_results)
	var said: GdChime.Bound = answer.map(func(ran: Dictionary) -> Variant: return _said(ran))
	var table: GdChime.Desc = GdChime.LongTable.make(ui, _bench.table)
	var ran: GdChime.Bound = answer.map(func(one: Dictionary) -> bool: return one["ran"] and not one["failed"])
	var shown: GdChime.Desc = ui.column([ui.text(said, GdChime.Themes.REASON).wraps(), ui.when(ran, table, null).keeps().grow()], &"PaneColumn")
	# the results' own menu: the query run again, the results alone or folded away
	return GdChime.Panes.titled(ui, GdChime.Phrase.of("Results"), ui.menu_target([Workbench.RUNS, expands, folds], {}, [shown]))


## What a run said: how many rows of how many, and how long it took; why it failed; or what to do before any run.
static func _said(ran: Dictionary) -> Variant:
	if not ran["ran"]:
		return GdChime.Phrase.of("Run a query to see its rows here.")
	if ran["failed"]:
		return ran["said"]
	return GdChime.Phrase.with("%s of %s rows, in %s ms", [ran["rows"].size(), GdChime.Formats.written_number(ran["total"]), GdChime.Formats.written_number(ran["took"], 1)])


## The dataset shown: its name, how many columns, and each column's name and kind.
func schema() -> GdChime.Desc:
	var ui: GdChime.Ui = _ui
	var shown: GdChime.Bound = ui.bound(_bench.get_shown).map(func(named: Variant) -> Variant: return GdChime.Phrase.of("Pick a dataset to see its columns.") if named == null else named)
	var column := func(one: GdChime.Bound) -> GdChime.Desc: return ui.row([ui.text(one.field("name"), GdChime.Themes.FACE).grow(), ui.text(one.field("kind"), GdChime.Themes.REASON)])
	var columns: GdChime.Desc = ui.scroll(ui.each(ui.bound(_bench.get_columns), column, func(one: Dictionary) -> Variant: return one["name"]))
	return GdChime.Panes.titled(ui, GdChime.Phrase.of("Schema"), ui.column([ui.text(shown, GdChime.Themes.FACE).wraps(), columns.grow()], &"PaneColumn"))
