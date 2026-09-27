extends SceneTree

## What must be true of a table given other rows and columns (table_models.gd,
## replace): every model holds the new rows - the view shows every one of
## them, by no filter, order or grouping; nothing is picked and the cursor
## is at the first; there is no change to take back, and nothing is behind;
## the filters are the new columns', with no chip; the columns are the new
## ones, all shown, their shape moved on; and each new column's samples are
## its own words.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_table_replaced.gd

const Fixture := preload("res://tests/fixture.gd")
const FrameBudget := preload("res://addons/gd_chime/frame_budget.gd")
const Jobs := preload("res://addons/gd_chime/jobs.gd")
const PackedRows := preload("res://addons/gd_chime/packed_rows.gd")
const QueriedRows := preload("res://addons/gd_chime/queried_rows.gd")
const RowSelection := preload("res://addons/gd_chime/row_selection.gd")
const RowEdits := preload("res://addons/gd_chime/row_edits.gd")
const RowFilters := preload("res://addons/gd_chime/row_filters.gd")
const TableModels := preload("res://addons/gd_chime/table_models.gd")
const FilterSet := preload("res://addons/gd_chime/components/recipes/filter_set.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Verdict := preload("res://tests/verdict.gd")

const REGION := &"results"

var _verdict := Verdict.new()


func _init() -> void:
	await _verdict.states(_other_rows_and_columns_replace_everything_the_old_ones_held)
	quit(_verdict.deliver(get_script()))


## Pipes: a risk and a material, twelve of them.
func _pipes() -> PackedRows:
	var rows := PackedRows.new({&"risk": PackedRows.NUMBER, &"material": PackedRows.WORDS})
	# every pipe, its risk and material spread
	for row: int in 12:
		rows.add([float((row * 37) % 100), ["cast iron", "PVC", "steel"][row % 3]])
	return rows


## A query's run: a status and a carrier, five rows, all words.
func _run() -> PackedRows:
	var rows := PackedRows.new({&"status": PackedRows.WORDS, &"carrier": PackedRows.WORDS})
	# every row of the run, its words
	for row: int in 5:
		rows.add([["open", "closed"][row % 2], ["north", "south", "east"][row % 3]])
	return rows


## Frames until the view has landed.
func _landed(models: TableModels) -> void:
	# a frame at a time until no query is out
	while models.view.get_busy():
		await process_frame


func _do(made: Fixture, action: StringName, payload: Dictionary = {}) -> Phrase:
	return made.commands.dispatch(REGION, action, payload)


func _other_rows_and_columns_replace_everything_the_old_ones_held() -> void:
	var made := Fixture.new(root)
	var budget := FrameBudget.new(made.chimes, 16.0, 0.9, 3)
	var pool := Jobs.new(made.chimes, budget, 1, 4, true)
	for node: Node in [budget, pool]:
		root.add_child(node)
	var spec := [{"name": &"risk", "words": Phrase.of("risk"), "share": 0.5, "edits": true, "filters": FilterSet.A_NUMBER}, {"name": &"material", "words": Phrase.of("material"), "share": 0.5, "filters": FilterSet.A_LIST}]
	var models := TableModels.new(made.ui, _pipes(), spec, {}, pool, 6)
	# every model of the table stood up where a place would stand it, and in the tree
	for one: Node in models.all():
		made.commands.stand(REGION, one)
		root.add_child(one)
	_do(made, RowFilters.PICKS_PROPERTY, {"value": &"material"})
	_do(made, RowFilters.PICKS_COMPARISON, {"comparison": "is"})
	_do(made, RowFilters.PICKS_VALUE, {"value": "steel"})
	_do(made, QueriedRows.SORTS, {"column": &"risk"})
	await _landed(models)
	_do(made, RowSelection.MOVES, {"to": 2})
	_do(made, RowSelection.EXTENDS, {"by": 1})
	_do(made, RowEdits.WRITES, {"row": models.view.row_at(0), "column": &"risk", "line": "1"})
	# the write rings at the frame's end, and the view is behind from there
	await process_frame
	var before: bool = models.view.get_kept() == 4 and models.picks.get_count() == 2 and models.behind.get_behind() and models.filters.get_chips().size() == 1
	var shape: int = models.columns.get_shape()
	var run := _run()
	var columns := [{"name": &"status", "words": Phrase.of("status"), "share": 0.4}, {"name": &"carrier", "words": Phrase.of("carrier"), "share": 0.6}]
	models.replace(run, columns)
	await process_frame
	_verdict.check(before and models.rows == run and models.view.get_count() == 5 and models.picks.get_count() == 0 and models.picks.get_cursor() == 0 and not models.behind.get_behind(), "replaced, the view shows the five new rows, nothing picked, the cursor at the first, nothing behind (filtered, picked and written before: %s)" % before)
	var undo := _do(made, RowEdits.UNDOES)
	_verdict.check(str(undo) == "Nothing has changed to take back" and models.filters.get_chips().is_empty() and models.filters.get_properties().is_empty() and not models.filters.get_pacing().get_waiting(), "the change before is no longer there to take back (%s), and the filters are the new columns' - none - with no chip" % undo)
	var names: Array = models.columns.get_all().map(func(column: Dictionary) -> StringName: return column["name"])
	_verdict.check(names == [&"status", &"carrier"] and models.columns.get_shown().size() == 2 and models.columns.get_shape() == shape + 1 and models.samples.has(&"carrier") and models.samples[&"carrier"]["words"].slice(0, 3) == ["north", "south", "east"] and not models.samples.has(&"risk"), "the columns are the run's, all shown, their shape moved on, and each one's samples its own words: %s" % [names])
	await _landed(models)
	var page: Array = []
	models.view.fetch(0, 10, func(rows: Array, _total: int) -> void: page.assign(rows))
	_verdict.check(Array(models.view.get_order()) == [0, 1, 2, 3, 4] and models.view.get_sort().is_empty() and page.map(func(row: Dictionary) -> String: return row["carrier"]) == ["north", "south", "east", "north", "south"], "landed, every new row by no filter or order, read as the new columns: %s" % [page.map(func(row: Dictionary) -> String: return row["carrier"])])
	made.done()
