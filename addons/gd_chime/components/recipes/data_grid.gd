extends RefCounted

const Themes := preload("../../theme.gd")
const Driver := preload("../../driver.gd")
const Actions := preload("../../actions.gd")
const Formats := preload("../../formats.gd")
const Ui := preload("../primitives/ui.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Combo := preload("combo.gd")
const Sheet := preload("sheet.gd")
const Setting := preload("setting.gd")
const FilterSet := preload("filter_set.gd")
const LongTable := preload("long_table.gd")
const TableModels := preload("../../table_models.gd")
const PackedRows := preload("../../packed_rows.gd")
const QueriedRows := preload("../../queried_rows.gd")
const RowSelection := preload("../../row_selection.gd")
const RowEdits := preload("../../row_edits.gd")
const RowFilters := preload("../../row_filters.gd")
const TableColumns := preload("../../table_columns.gd")
const EditingCell := preload("../../editing_cell.gd")
const ViewBehind := preload("../../view_behind.gd")
const Tables := preload("../../theme_tables.gd")
const Phrase := preload("../../phrase.gd")
const Pressables := preload("../../theme_pressables.gd")

## A data grid: the floor's standard way to show, narrow and act on a large
## collection - the long table (long_table.gd) under a bar of its filters,
## over a bar of what is picked and what can be done to it, and a line
## saying how the view stands - reusable by any application over its own
## rows and columns (table_models.gd).
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## ABOVE: the filters' chips and how many rows match (filter_set.gd), the
## press that raises the filter builder, the grouping - a combo over the
## words columns and none - and the press that raises the columns, each
## shown or hidden by a press. The builder and the columns stand in
## pop-ups, where they have the room, each described on the button opening
## it and lifted beside the app by the builder, as a combo's is.
##
## BELOW: the ROW ACTIONS the application declares - actions of its own
## models, each acting on what is picked or, with nothing picked, the row
## the cursor is on (row_selection.gd: get_acted_on) - as the buttons it
## describes (bell_button.gd), one raising a choice where it asks one, so the
## keys and the pad an action is declared with press them from anywhere in
## the grid, and a menu can offer the same actions later; then taking back
## the last change, bringing the view up to date and clearing the picks.
## Under them, a line of how many rows are picked, how many the view keeps
## of how many there are, and how long the view took to work out, that it
## is being worked out, or that it is out of date: an edit asks no query,
## so rows it shows can have been written since (view_behind.gd), until
## the press, the key or the pad brings it up to date.
##
## THE WORDS of every action here are the floor's, declared by the
## application with declare(): a grid's actions say the same in every
## application, and each is declared once.
##
## Deliberately absent: a context menu - the row actions are declared
## actions, which the menu will offer - and saving the columns shown.

const OPENS_FILTERS := &"opens_the_filter_builder"
const OPENS_COLUMNS := &"opens_the_columns"
const OPENS_GROUPING := &"opens_the_grouping"
## What the grid's two pop-ups are of, in their names.
const FILTERS := &"grid_filters"
const COLUMNS := &"grid_columns"
## Every action a grid draws or answers, and the words that say what it does.
const WORDS := {OPENS_FILTERS: "Add a filter", OPENS_COLUMNS: "Columns", OPENS_GROUPING: "Group by", QueriedRows.SORTS: "Sort", QueriedRows.GROUPS_BY: "Group", QueriedRows.SHUTS: "Shut or open the group", RowSelection.MOVES: "Move", RowSelection.EXTENDS: "Pick a run", RowSelection.MOVES_ACROSS: "Move across", RowSelection.PICKS: "Pick", RowSelection.TOGGLES: "Pick this row", RowSelection.PICKS_EVERY_ROW_KEPT: "Pick every row shown", RowSelection.CLEARS: "Clear the picks", RowEdits.WRITES: "Change the value", RowEdits.UNDOES: "Undo", EditingCell.EDITS: "Change this cell", EditingCell.ENDS: "Stop changing", EditingCell.RESIZES_THIS_COLUMN: "Resize this column", TableColumns.RESIZES: "Resize the column", TableColumns.TURNS: "Show or hide the column", RowFilters.NARROWS_PROPERTIES: "Find a column", RowFilters.PICKS_PROPERTY: "Column", RowFilters.PICKS_COMPARISON: "Comparison", RowFilters.NARROWS_VALUES: "Find a value", RowFilters.PICKS_VALUE: "This value", RowFilters.SETS_VALUE: "Value", RowFilters.TYPES_LINE: "Type the value", RowFilters.TOGGLES: "Turn the filter", RowFilters.REMOVES: "Remove the filter", ViewBehind.REAPPLIES: "Bring the view up to date"}
## A column shown or hidden, said with its mark: the mark is the words', never a hue alone.
const SHOWN_MARK := "✓ "
const HIDDEN_MARK := "   "


## The actions a long table shown alone performs (long_table.gd), with no
## column that edits: its headings, grips, group headings and cursor's.
const TABLE: Array[StringName] = [QueriedRows.SORTS, QueriedRows.SHUTS, RowSelection.MOVES, RowSelection.EXTENDS, RowSelection.MOVES_ACROSS, RowSelection.PICKS, RowSelection.TOGGLES, RowSelection.PICKS_EVERY_ROW_KEPT, RowSelection.CLEARS, EditingCell.EDITS, EditingCell.ENDS, EditingCell.RESIZES_THIS_COLUMN, TableColumns.RESIZES]


## The register's table for these actions: each one's words first, then the
## keys and pad buttons it is on before anyone rebinds them.
static func table(of: Array) -> Dictionary:
	var on := {RowEdits.UNDOES: [Actions.keys(KEY_U)], RowSelection.CLEARS: [Actions.keys(KEY_BACKSPACE)], ViewBehind.REAPPLIES: [Actions.keys(KEY_R), Actions.pad(JOY_BUTTON_RIGHT_STICK)]}
	var said: Dictionary = {}
	# every action asked for: its words first, the inputs it is on after them
	for action: StringName in of:
		said[action] = [WORDS[action]] + on.get(action, [])
	return said


## Every action of a grid declared, with its words and its inputs.
static func declare(register: Actions) -> void:
	register.declare_all(table(WORDS.keys()))


## Only a long table's actions declared, in the grid's words - for an
## application that shows rows in a long table alone, nothing edited:
## declaring the grid's every action would leave actions nobody performs.
static func declare_table(register: Actions) -> void:
	register.declare_all(table(TABLE))


## The grid over these models, with the row actions' buttons the application describes.
static func grid(ui: Ui, models: TableModels, row_actions: Array, style: StringName = &"DataGrid") -> Desc:
	var grouping: Array = [{"value": &"", "words": Phrase.of("No groups")}] + models.columns.get_all().filter(func(column: Dictionary) -> bool: return models.rows.kind_of(column["name"]) == PackedRows.WORDS).map(func(column: Dictionary) -> Dictionary: return {"value": column["name"], "words": column["words"]})
	var grouped := Combo.short(ui, QueriedRows.GROUPS_BY, OPENS_GROUPING, {offers = Bound.new(func() -> Array: return grouping), chosen = ui.bound(models.view.get_group), title = Phrase.of("Group the rows by")})
	# the grouping's pop-up answered by the view, said on its description as a combo's style is
	(grouped.props["overlay"] as Desc).props["handled_by"] = models.view
	var above := ui.row([FilterSet.chips(ui, models.filters, RowFilters.ACTIONS).grow(4.0), ui.button(OPENS_FILTERS, {opens = _filters(ui, models)}), grouped, ui.button(OPENS_COLUMNS, {opens = _columns(ui, models)})], Tables.BAR)
	# every button of the bar grown alike, so the reason under one has the width to be read in a line or two
	var buttons: Array = (row_actions + [ui.button(RowEdits.UNDOES), ui.button(ViewBehind.REAPPLIES), ui.button(RowSelection.CLEARS)]).map(func(button: Desc) -> Desc: return button.grow())
	var below := ui.row(buttons, Tables.BAR)
	var said := ui.text(_standing(models), Themes.REASON)
	return ui.column([above, LongTable.make(ui, models).grow(), below, said], style)


## How the view stands: picked, kept of all, and how long it took, that it
## is being worked out - from a query waiting on the typing to its landing -
## or that it is out of date, rows it shows written since.
static func _standing(models: TableModels) -> Bound:
	var sources := [Bound.new(models.picks.get_count), Bound.new(models.view.get_kept), Bound.new(models.view.get_busy), Bound.new(models.filters.get_pacing().get_waiting), Bound.new(models.behind.get_behind), Bound.new(models.view.get_took_ms)]
	var total := models.rows.count()
	return Bound.all(sources, func(picked: int, kept: int, busy: bool, waiting: bool, behind: bool, took: float) -> Phrase: return Phrase.with("%s picked   %s of %s rows shown   %s", [_number(picked), _number(kept), _number(total), _how(busy or waiting, behind, took)]))


## How the view stands, last: worked out now, out of date, or how long it took.
static func _how(working: bool, behind: bool, took: float) -> Phrase:
	if working:
		return Phrase.of("Working out the view")
	if behind:
		return Phrase.of("Out of date: rows shown have changed since")
	return Phrase.with("The view took %s ms", [_number(roundi(took))])


## A count written the language's way, as it is drawn.
static func _number(count: int) -> Phrase:
	return Phrase.written(func() -> String: return Formats.written_number(count))


## The filter builder's pop-up: the builder over the chips, and the way back.
static func _filters(ui: Ui, models: TableModels) -> Desc:
	var content := [ui.text(Phrase.of("Filter the rows"), Themes.FACE), FilterSet.builder(ui, models.filters, RowFilters.ACTIONS).grow(), FilterSet.chips(ui, models.filters, RowFilters.ACTIONS), Sheet.close(ui)]
	return ui.pop_up(FILTERS, func(_which: Bound) -> Desc: return Sheet.over(ui, content, Setting.SHEET), models.filters)


## The columns' pop-up: every column, pressed to show or hide it, its mark saying which; and the way back.
static func _columns(ui: Ui, models: TableModels) -> Desc:
	var turns: Array = []
	# every column, a press turning it
	for column: Dictionary in models.columns.get_all():
		var shown: Bound = ui.bound(models.columns.get_all).map(func(all: Array) -> bool: return all.any(func(one: Dictionary) -> bool: return one["name"] == column["name"] and one["shown"]))
		var said: Bound = shown.map(func(on: bool) -> Phrase: return Phrase.joined([SHOWN_MARK if on else HIDDEN_MARK, column["words"]]))
		turns.append(ui.pressable(TableColumns.TURNS, {"column": column["name"]}, [ui.text(said, Themes.FACE)], shown.map(func(on: bool) -> StringName: return Pressables.TOGGLE_ON if on else Pressables.TOGGLE_OFF)))
	var content := [ui.text(Phrase.of("The columns shown"), Themes.FACE), ui.grid(turns, [0.5, 0.5]), Sheet.close(ui)]
	return ui.pop_up(COLUMNS, func(_which: Bound) -> Desc: return Sheet.over(ui, content, Setting.SHEET), models.columns)
