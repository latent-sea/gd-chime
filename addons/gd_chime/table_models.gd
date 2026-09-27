extends RefCounted

const Chimes := preload("chimes.gd")
const Commands := preload("commands.gd")
const Jobs := preload("jobs.gd")
const LongList := preload("long_list.gd")
const PackedRows := preload("packed_rows.gd")
const QueriedRows := preload("queried_rows.gd")
const RowSelection := preload("row_selection.gd")
const RowEdits := preload("row_edits.gd")
const RowFilters := preload("row_filters.gd")
const TableColumns := preload("table_columns.gd")
const EditingCell := preload("editing_cell.gd")
const ViewBehind := preload("view_behind.gd")
const Formats := preload("formats.gd")
const Phrase := preload("phrase.gd")
const Bound := preload("components/primitives/bound.gd")

## Everything a large table stands on, made together in one region: the
## rows' view and its query, the long list of its places, the picks and the
## cursor, the columns shown, the edits and the cell being edited, the
## filters, and whether the view is behind its rows - so an application hands over rows and columns and gets a table
## whose every model already answers the table's recipe (data_grid.gd).
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A COLUMN is {name, words, share} and, at will, "edits" - its cells typed
## into - "places" - how many places a number is written to - "writes" - a
## function writing its value as data of the application's own, an asset's
## code from its number - and "filters" - the filter-set's type it is
## filtered by (filter_set.gd), where it may be. Every model is made here, put beside the app (ui.also) and answers in
## the one region given, the region of the place the table is described in.
##
## HOW A VALUE IS WRITTEN is the column's kind: a number to its places and
## a date as the language writes one (formats.gd), each a phrase said as it
## is drawn; a word as it is. And what each column MAY hold, its samples, is
## worked out once here for the lines to be measured by (cells.gd): every
## word a words column holds, a number column's least and most written, a
## date column's day in every month; the heading's words among them - the
## least and most found by the engine's own sort of a copy, never a pass of
## the rows on the frame.
##
## OTHER ROWS AND COLUMNS come by replace() - an application's own query run
## again, bringing its own columns: every model given them and the table's
## lines built again for them (long_table.gd, by the columns' shape).
##
## Deliberately absent: rows added one by one once the table stands - a
## source whose rows land later is a long list's (long_list.gd), not this.

## The column of picks every table leads with, the mark a picked row's
## holds, and its share of the width.
const PICKED := &"picked"
const PICKED_MARK := "✓"
const PICKED_SHARE := 0.03
## The mark in the same column of a row its view would now put elsewhere or leave out (view_behind.gd).
const STALE_MARK := "*"
## Undecided, and a rule's rather than a look's: the least share a column
## is resized to, and the share one step of the keys moves its edge.
const LEAST := 0.03
const STEP := 0.02
## A heading with the sort's way marked on it, the widest it says (table.gd).
const MARKED := " v"

var rows: PackedRows
var view: QueriedRows
var long: LongList
var picks: RowSelection
var columns: TableColumns
var edits: RowEdits
var editing: EditingCell
var filters: RowFilters
var behind: ViewBehind
## Every column's samples, {column: {"words"}}, shared by every line of the table.
var samples: Dictionary = {}
## The declared actions a row's context menu offers, pressed with {"id": the
## row}, given as this is built; none, and a row has no menu.
var row_actions: Array

var _kinds: Dictionary = {}  # column -> its kind
var _places: Dictionary = {}  # a number column -> how many places it is written to
var _writes: Dictionary = {}  # a column -> how its value is written, where it says so itself


func _init(ui: RefCounted, held: PackedRows, spec: Array, checks: Dictionary, jobs: Jobs, showing: int, offers: Array = []) -> void:
	rows = held
	row_actions = offers
	var chimes: Chimes = ui.chimes
	view = QueriedRows.new(chimes, held, jobs)
	edits = RowEdits.new(chimes, held, checks)
	# the long list's rows move as the view's answer is set out again and as rows are written
	long = LongList.new(chimes, view.fetch, showing * 2, 6, showing, Bound.new(func() -> Array: return [view.get_count(), view.get_shown(), edits.get_written()]))
	columns = TableColumns.new(chimes, spec, LEAST)
	picks = RowSelection.new(chimes, view, func() -> int: return columns.get_shown().size())
	editing = EditingCell.new(chimes, view, picks, columns, edits)
	filters = RowFilters.new(chimes, view, _filtered(spec), ui.motion)
	behind = ViewBehind.new(chimes, view, edits)
	_learn(spec)


## Every model of the table, for the place it is described in to stand up:
## each is put in the tree there and told its actions in that place's region
## (place_builder.gd), so a table in one screen and a table in another never
## take each other's presses.
func all() -> Array:
	return [view, edits, long, columns, picks, editing, filters, behind]


## Other rows and columns in place of these - an application's own query
## run again: every model given them - the reader's filters, order, picks
## and last change let go with the rows they were of - and what each column
## may hold worked out again, for the lines built again for them.
func replace(held: PackedRows, spec: Array) -> void:
	rows = held
	_learn(spec)
	# the picks and the edits first: whatever reads a row the view shows asks them about it
	picks.replace(held)
	edits.replace(held)
	view.replace(held)
	filters.replace(_filtered(spec))
	columns.replace(spec)


## The columns a reader may filter by, {name, type}: those that say how.
static func _filtered(spec: Array) -> Array:
	return spec.filter(func(column: Dictionary) -> bool: return column.has("filters")).map(func(column: Dictionary) -> Dictionary: return {"name": column["name"], "type": column["filters"]})


## Every column's kind, places, own writing and the words it may hold, from the rows held.
func _learn(spec: Array) -> void:
	_kinds = {}
	_places = {}
	_writes = {}
	# the one dictionary every line holds, filled again in place: a line of the old columns reads the new ones' until it is built again
	samples.clear()
	samples[PICKED] = {"words": [PICKED_MARK, PICKED_MARK + STALE_MARK]}
	# every column: its kind, its places, and the words it may hold
	for column: Dictionary in spec:
		_kinds[column["name"]] = rows.kind_of(column["name"])
		_places[column["name"]] = column.get("places", 0)
		if column.has("writes"):
			_writes[column["name"]] = column["writes"]
		samples[column["name"]] = {"words": _samples_of(column) + [Phrase.joined([column["words"], MARKED])]}


## A value of a column as it is written in a cell: a phrase for a number or
## a date, the word itself for a word, nothing for nothing.
func written(column: StringName, value: Variant) -> Variant:
	if value == null:
		return ""
	if _writes.has(column):
		return _writes[column].call(value)
	return _written_as(_kinds[column], _places[column], value)


## A value written as its kind writes it - made where nothing is held, so
## the writing a sample keeps holds no hold on these models in turn.
static func _written_as(kind: StringName, places: int, value: Variant) -> Variant:
	match kind:
		PackedRows.NUMBER: return Phrase.written(func() -> String: return Formats.written_number(value, places))
		PackedRows.DATE: return Phrase.written(func() -> String: return Formats.written_date(int(value) * PackedRows.DAY_SECONDS))
	return value


## What a column may hold, as written: its words, or the least and most of
## its numbers, or its latest year's day in every month.
func _samples_of(column: Dictionary) -> Array:
	var name: StringName = column["name"]
	if rows.kind_of(name) == PackedRows.WORDS:
		return Array(rows.words(name))
	var sorted: PackedFloat64Array = rows.numbers(name).duplicate()
	sorted.sort()
	if sorted.is_empty():
		return []
	if rows.kind_of(name) == PackedRows.NUMBER:
		return [written(name, sorted[0]), written(name, sorted[-1])]
	var year: int = Time.get_date_dict_from_unix_time(int(sorted[-1]) * PackedRows.DAY_SECONDS)["year"]
	return range(1, 13).map(func(month: int) -> Variant: return written(name, PackedRows.day_of("%04d-%02d-28" % [year, month])))
