extends RefCounted

const Themes := preload("../../theme.gd")
const Tables := preload("../../theme_tables.gd")
const Ui := preload("../primitives/ui.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Transition := preload("../primitives/transition.gd")
const Table := preload("table.gd")
const Sections := preload("sections.gd")
const TableModels := preload("../../table_models.gd")
const TableColumns := preload("../../table_columns.gd")
const PackedRows := preload("../../packed_rows.gd")
const QueriedRows := preload("../../queried_rows.gd")
const RowSelection := preload("../../row_selection.gd")
const RowEdits := preload("../../row_edits.gd")
const EditingCell := preload("../../editing_cell.gd")
const Local := preload("../primitives/local.gd")
const Phrase := preload("../../phrase.gd")
const Fields := preload("../../theme_fields.gd")

## A table of more rows than will ever be nodes: the heading line over a
## window of rows (virtual_list.gd) onto a queried view (table_models.gd),
## every line a line of cells (cells.gd) at the columns' widths - the
## table's shape (table.gd) for a hundred thousand rows.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE HEADINGS STAY WHERE THEY ARE: their line stands over the rows, not among
## them, so it is there however far down the rows are. It leads with the
## picks' mark - pressed, every row the view keeps is picked - then a
## heading per column (table.gd), pressed to sort, the way marked in its
## words; and in the gap after each column its edge, where the column's
## resize grip stands. A window narrower than the columns need shows those
## that fit, whole, heading and rows alike (cells.gd): no word is cut.
##
## A ROW is a line of cells: the pick's mark, then a cell per column, the
## value written as its column writes it; its ground picked, ringed where
## the cursor is, or both - worn in place as the list scrolls. A column
## that edits shows, in the cell being edited, a field holding the value,
## whose Enter writes it (row_edits.gd) - a line refused says why under
## the rows, since a row is as tall as every other. A GROUP's heading takes a row's
## place: its mark open or shut (sections.gd), its word and how many rows
## it holds, pressed to shut or open it. Each slot holds both and shows the
## one its place is, so a scroll swaps nothing.
##
## THE KEYS are the list's, each a command of the cursor's: up and down
## move it and, with shift, pick the run; a page and the ends the same;
## left and right move across, and with shift resize that column; Enter
## opens the cell or turns a group; the accept key picks the row or its
## group; select-all picks every row kept; escape gives up an edit, or with
## none clears the picks. A press picks, with control adds, with shift
## runs; pressed twice, it opens the cell.
##
## A ROW WRITTEN OUT OF ITS PLACE - one the view's query would now leave out
## or put elsewhere (view_behind.gd) - stays where it is, its words dimmed
## and a mark beside the pick's, never a hue alone, until the query is
## asked again.
##
## Deliberately absent: a heading that follows its group down the list.


## A column standing in while a table has none yet: described, so its
## heading's and grip's actions are declared, and never shown, being no
## column the columns show.
const STAND_IN := {"name": &"", "words": "", "share": 1.0}


## The table over these models: the heading line over the rows, scrolling
## across - both built again for every set of columns a replace brings
## (table_models.gd), since every line is laid out for its columns.
static func make(ui: Ui, models: TableModels, style: StringName = &"Table") -> Desc:
	# why the cell being edited refused its line: kept here, since a row has no room under its field
	var refused := ui.local(null)
	var shape: Bound = ui.bound(models.columns.get_shape).map(func(serial: int) -> Array: return [serial])
	var lines := ui.each(shape, func(_serial: Bound) -> Desc: return _lines(ui, models, refused).grow(), func(serial: int) -> Variant: return serial, Tables.TABLE).transition(Transition.NONE)
	return ui.column([lines.grow(), ui.text(refused, Themes.REASON).hides_empty().wraps()], style)


## The heading line over the rows, for the columns as they stand - or, with
## none yet, a stand-in's, never shown, so a table empty until its first
## rows come declares its sorting and resizing all the same.
static func _lines(ui: Ui, models: TableModels, refused: Local) -> Desc:
	var all: Array = [STAND_IN] if models.columns.get_all().is_empty() else models.columns.get_all()
	var shown: Bound = ui.bound(models.columns.get_shown).map(func(columns: Variant) -> Array: return [{"name": TableModels.PICKED, "share": TableModels.PICKED_SHARE}] + columns)
	var names: Array = [TableModels.PICKED] + all.map(func(column: Dictionary) -> StringName: return column["name"])
	var sort: Bound = ui.bound(models.view.get_sort).map(func(by: Dictionary) -> Dictionary: return {"column": "", "ascending": true} if by.is_empty() else by)
	var headings: Array = [ui.pressable(RowSelection.PICKS_EVERY_ROW_KEPT, {}, [ui.text(TableModels.PICKED_MARK, Tables.WORDS)], Tables.HEADING)]
	var edges: Array = [ui.text("")]
	# every column, its heading and the edge after it
	for column: Dictionary in all:
		headings.append(Table.heading(ui, column, sort, {sorts = QueriedRows.SORTS, words_kind = Tables.WORDS}))
		edges.append(ui.grip(TableColumns.RESIZES, {"column": column["name"]}))
	var head := ui.cells(headings, names, shown, {samples = models.samples, words_kind = Tables.WORDS, ground = Tables.HEAD, edges = edges})
	var line := func(place: Bound) -> Desc: return _place(ui, models, shown, names, place, refused)
	var rows := ui.virtual_list(models.long, line, Tables.ROWS, _cursor(models)).fits()
	# the list holds the focus, not a row: the menu key and the pad open the menu of the cursor's row
	if not models.row_actions.is_empty():
		var at_cursor: Bound = ui.bound(models.picks.get_cursor).map(func(cursor: int) -> Dictionary: var row := models.view.row_at(cursor) if cursor < models.view.get_count() else -1; return {"id": row if row >= 0 else null})
		rows = ui.menu_target(models.row_actions, at_cursor, [rows])
	return ui.column([head, rows.grow()], Tables.TABLE)


## The cursor the list is moved by: its place, and every key and press.
static func _cursor(models: TableModels) -> Dictionary:
	var page := models.long.get_showing()
	var step := TableModels.STEP
	var keys := [
		[&"ui_up", false, RowSelection.MOVES, {"by": -1}], [&"ui_down", false, RowSelection.MOVES, {"by": 1}],
		[&"ui_up", true, RowSelection.EXTENDS, {"by": -1}], [&"ui_down", true, RowSelection.EXTENDS, {"by": 1}],
		[&"ui_page_up", false, RowSelection.MOVES, {"by": -page}], [&"ui_page_down", false, RowSelection.MOVES, {"by": page}],
		[&"ui_page_up", true, RowSelection.EXTENDS, {"by": -page}], [&"ui_page_down", true, RowSelection.EXTENDS, {"by": page}],
		[&"ui_home", false, RowSelection.MOVES, {"to": 0}], [&"ui_end", false, RowSelection.MOVES, {"to": -1}],
		[&"ui_home", true, RowSelection.EXTENDS, {"to": 0}], [&"ui_end", true, RowSelection.EXTENDS, {"to": -1}],
		[&"ui_left", false, RowSelection.MOVES_ACROSS, {"by": -1}], [&"ui_right", false, RowSelection.MOVES_ACROSS, {"by": 1}],
		[&"ui_left", true, EditingCell.RESIZES_THIS_COLUMN, {"by": -step}], [&"ui_right", true, EditingCell.RESIZES_THIS_COLUMN, {"by": step}],
		[&"ui_text_submit", false, EditingCell.EDITS, {}], [&"ui_accept", false, RowSelection.TOGGLES, {}],
		[&"ui_text_select_all", false, RowSelection.PICKS_EVERY_ROW_KEPT, {}],
	]
	var at: Bound = Bound.both(Bound.new(models.picks.get_cursor), Bound.new(models.editing.get_editing), func(cursor: int, _editing: Dictionary) -> int: return cursor)
	return {"at": at, "keys": keys, "anywhere": [[&"ui_cancel", EditingCell.ENDS], [&"ui_cancel", RowSelection.CLEARS]], "presses": RowSelection.PICKS, "twice": EditingCell.EDITS}


## One slot: a row or a group's heading, whichever its place is, both built once.
static func _place(ui: Ui, models: TableModels, shown: Bound, names: Array, place: Bound, refused: Local) -> Desc:
	var grouped: Bound = place.map(func(item: Variant) -> bool: return item != null and item.has("group"))
	return ui.when(grouped, _group(ui, models, place), _row(ui, models, shown, names, place, refused)).keeps().transition(Transition.NONE)


## A row: the pick's mark and a cell per column, on its ground.
static func _row(ui: Ui, models: TableModels, shown: Bound, names: Array, place: Bound, refused: Local) -> Desc:
	var picks: Bound = ui.bound(models.picks.get_count)
	var stale: Bound = ui.bound(models.behind.get_stale)
	# the pick's mark and the stale mark after it, each where it holds
	var marked: Bound = Bound.all([place, picks, stale], func(item: Variant, _count: int, written: Dictionary) -> String: return "" if item == null or not item.has("id") else (TableModels.PICKED_MARK if models.picks.is_picked(item["id"]) else "") + (TableModels.STALE_MARK if written.has(item["id"]) else ""))
	var parts: Array = [ui.text(marked, Tables.WORDS)]
	# every column, its cell
	for column: Dictionary in models.columns.get_all():
		parts.append(_cell(ui, models, column, place, refused))
	var ground: Bound = Bound.all([place, picks, ui.bound(models.picks.get_cursor)], func(item: Variant, _count: int, cursor: int) -> StringName: return _ground(models, item, cursor))
	var line := ui.cells(parts, names, shown, {samples = models.samples, words_kind = Tables.WORDS, ground = ground})
	if models.row_actions.is_empty():
		return line
	return ui.menu_target(models.row_actions, place.map(func(item: Variant) -> Dictionary: return {"id": item["id"] if item != null and item.has("id") else null}), [line])


## A row's ground: picked or not, and ringed where the cursor is.
static func _ground(models: TableModels, item: Variant, cursor: int) -> StringName:
	if item == null or not item.has("id"):
		return Tables.CELLS
	var picked := models.picks.is_picked(item["id"])
	if item["at"] == cursor:
		return Tables.PICKED_CURSOR if picked else Tables.CURSOR
	return Tables.PICKED if picked else Tables.CELLS


## One cell: its value as its column writes it - or, in the cell being
## edited, a field holding the value, whose Enter writes the line, its
## refusal kept for the table to show under its rows.
static func _cell(ui: Ui, models: TableModels, column: Dictionary, place: Bound, refused: Local) -> Desc:
	var name: StringName = column["name"]
	var dimmed: Bound = Bound.both(place, ui.bound(models.behind.get_stale), func(item: Variant, stale: Dictionary) -> StringName: return Tables.STALE_WORDS if item != null and item.has("id") and stale.has(item["id"]) else Tables.WORDS)
	var words := ui.text(place.map(func(item: Variant) -> Variant: return "" if item == null or not item.has(name) else models.written(name, item[name])), dimmed)
	if not column.get("edits", false):
		return words
	var here: Bound = Bound.both(place, ui.bound(models.editing.get_editing), func(item: Variant, editing: Dictionary) -> bool: return item != null and not editing.is_empty() and item.get("id") == editing["row"] and editing["column"] == name)
	var held: Bound = place.map(func(item: Variant) -> Variant: return null if item == null or not item.has(name) else _typed(models, name, item[name]))
	var carries := func(line: String) -> Dictionary: return {"row": place.read()["id"], "column": name, "line": line}
	return ui.when(here, ui.field(RowEdits.WRITES, Fields.FIELD, {"shows": held, "carries": carries, "refused": refused}).takes_focus(), words).transition(Transition.NONE)


## A value as it is typed back into its field: a date written year-month-day,
## a number with no places it does not have, a word as it is.
static func _typed(models: TableModels, name: StringName, value: Variant) -> String:
	match models.rows.kind_of(name):
		PackedRows.DATE: return PackedRows.date_of(value)
		PackedRows.WORDS: return value
	return String.num(value)


## A group's heading: its mark, its word and how many it holds, pressed to shut or open it.
static func _group(ui: Ui, models: TableModels, place: Bound) -> Desc:
	var said: Bound = place.map(func(item: Variant) -> Variant: return "" if item == null or not item.has("group") else Phrase.joined([Sections.OPEN if item["open"] else Sections.SHUT, " ", item["words"], "  ", Phrase.counted("%d row", "%d rows", item["count"])]))
	var carried: Bound = place.map(func(item: Variant) -> Dictionary: return {"group": item["group"] if item != null and item.has("group") else -1})
	var pressed := ui.pressable(QueriedRows.SHUTS, carried, [ui.text(said, Tables.WORDS)], Sections.HEADING).no_focus()
	var ground: Bound = Bound.both(place, ui.bound(models.picks.get_cursor), func(item: Variant, cursor: int) -> StringName: return Tables.CURSOR if item != null and item["at"] == cursor else Tables.GROUP)
	var single: Bound = Bound.constant([{"name": &"group", "share": 1.0}])
	return ui.cells([pressed], [&"group"], single, {samples = {&"group": {"words": []}}, words_kind = Tables.WORDS, ground = ground})
