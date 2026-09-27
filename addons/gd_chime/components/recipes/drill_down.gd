extends RefCounted

const Themes := preload("../../theme.gd")
const Ui := preload("../primitives/ui.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const TableModels := preload("../../table_models.gd")
const DataGrid := preload("data_grid.gd")
const Sheet := preload("sheet.gd")
const Setting := preload("setting.gd")
const Drills := preload("../../drills.gd")
const Actions := preload("../../actions.gd")
const RowEdits := preload("../../row_edits.gd")

## A drill-down: the rows behind a figure, in the floor's data grid on a
## sheet over the dashboard - what they stand behind over them, the grid's
## own filters, sort, grouping and columns, and the way back.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The drill (drills.gd) is pressed on a figure and opens this, having
## scoped the grid's view to the rows the figure counted; the grid is
## data_grid.gd's whole, over models (table_models.gd) answering from
## anywhere, their rows looked at as it fills and let go as it empties,
## as a screen of a grid does. The sheet takes the look's shares of the
## window (Sheet.tall), read from the look its pop-up wears as its content
## is made (describe_places.gd), so the rows have the room a table needs.
##
## Answered as the one pop-up: the grid's own travel on its buttons, and
## the builder lifts them all beside the app.

## The look's type holding how much of the window the sheet takes, across and down, in thousandths.
const DRILL := &"DrillDown"
## What a drill-down's pop-up is of, in its name.
const KIND := &"drill_down"


## Every action a drill-down draws or answers, with its words: the drill,
## and the grid's own but the writing of a value - its rows are read, never
## changed, so no place performs it.
static func declare(register: Actions) -> void:
	# every action of a grid but the one a grid that is only read never performs
	var read: Array = DataGrid.WORDS.keys().filter(func(action: StringName) -> bool: return action != RowEdits.WRITES)
	register.declare_all(DataGrid.table(read).merged({Drills.SHOWS_ROWS_BEHIND: ["Show the rows behind it"]}))


## The drill's pop-up over these models, the drill's title said over the
## grid; the grid's own pop-ups travel on its buttons.
static func make(ui: Ui, drills: Drills, models: TableModels, style: StringName = Setting.SHEET) -> Desc:
	var content := [ui.text(ui.bound(drills.get_title), Themes.FACE), DataGrid.grid(ui, models, []).grow(), Sheet.close(ui)]
	# the sheet the shares of the window the look on its own place says
	var up := ui.pop_up(KIND, func(_which: Bound) -> Desc: return Sheet.tall(ui, content, style, {wide = ui.current_place().get_theme_constant(&"wide", DRILL) / 1000.0, high = ui.current_place().get_theme_constant(&"high", DRILL) / 1000.0}), models.all())
	# the rows looked at as the pop-up fills and let go as it empties, said on its description as a grid's grouping names its handler
	up.props["on_fill"] = models.long.look
	up.props["on_empty"] = models.long.drop
	return up
