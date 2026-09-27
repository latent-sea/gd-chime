extends "controller.gd"

const Commands := preload("commands.gd")
const Jobs := preload("jobs.gd")
const PackedRows := preload("packed_rows.gd")
const RowQuery := preload("row_query.gd")
const ViewPlaces := preload("view_places.gd")

## A collection with a query: rows held column by column (packed_rows.gd),
## the query asked of them - its clauses, its order, its grouping - and the
## VIEW that query answered, read a place at a time by whatever shows it.
## Built for a hundred thousand rows: nothing here copies a row into a node
## or runs once a row on the frame.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE QUERY RUNS OFF THE FRAME. A change of it - SORTS {column}, sorting
## by that column or turning the way it runs, or {column, ascending}, that
## way whatever ran before - a sort's choice names both; GROUPS_BY {value}, a words
## column or none, the payload a choice carries;
## the clauses a filter hands in with ask() - is set here at once, so what
## the headings say moves with the press, and the query goes to the job
## pool (jobs.gd) over a snapshot of the rows, never the rows being written.
## One query is out at a time: a change while one is out is asked once that
## one lands, with the query as it then stands, and the answer to a query
## since changed is let go. get_busy() is whether one is out; get_took_ms()
## how long the last took, asked to landed, for a reader to be told.
##
## THE SCOPE lies beneath the filters: clauses set with scope_to() by
## whoever opened the view onto part of the rows - the incidents behind one
## figure - kept under every set a filter asks, never shown as a filter's
## chip and never taken away by one. A reader narrows within it.
##
## THE VIEW is the answer set out as places (view_places.gd): in order the
## rows kept, or, grouped, each group's heading and then - while it is open
## - its rows. SHUTS {group} shuts or opens one by its code. The view, the
## query and whether one is out are values (value.gd): whoever reads them
## follows them. The places are read in pages by fetch() - a long list's
## source (long_list.gd), answered at once.
##
## THE ANSWER MOVES APART FROM THE QUERY, on a bell of its own
## (controller.gd, value on): the view and the answer it was set out from
## move when a query LANDS, where the sort, the grouping, whether one is out
## and how long the last took move when one is ASKED. A reader of the rows
## holds pages of them - a hundred thousand rows' worth - and those pages
## still stand while a query is out: woken by the asking, it would throw
## them away and build every row again on the very frame the query is
## running, which is the frame the answer has to land on.
##
## What a row holds is written by the edits (row_edits.gd), not here: a row
## written stays where the view put it until the query next changes, so a
## list never re-sorts under the reader's hand. OTHER ROWS in place of
## these - a new run of an application's own query - come by replace(): the
## reader's query let go with the rows it was asked of, and the view asked
## again over them.
##
## Deliberately absent: rows added or removed while shown.

const SORTS := &"sorts_rows"
const GROUPS_BY := &"groups_rows"
const SHUTS := &"shuts_a_group"
const COMMANDS: Array[StringName] = [SORTS, GROUPS_BY, SHUTS]

var _rows: PackedRows
var _jobs: Jobs
var _clauses: Array = []
var _scope: Array = []  # the clauses beneath every filter's
## The bell the ANSWER's values ring, apart from the query's, hung as this is built.
var _answered := OwnBell.new("answered")
var _sort := value({})
var _group := value(&"")
var _shown_group: StringName = &""  # the column the view shown now is grouped by
var _places := value(null, _answered)  # the view set out as places (view_places.gd), changed in place and set again
var _out := value(false)  # a query is on the pool
var _again: bool = false  # the query changed while one was out
var _asked_at: int = 0  # when the query out was asked, in microseconds
var _took_ms := value(0.0)
var _asked_version: int = 0  # the version of the rows the query out was asked over
var _shown := value({}, _answered)  # the answer the view shown now was set out from, or none before the first


func _init(chimes: Chimes, rows: PackedRows, jobs: Jobs) -> void:
	super(chimes)
	_answered.hang(chimes)
	_rows = rows
	_jobs = jobs
	# the rows as they were added, the first view, set out without a query
	_places.set_value(ViewPlaces.new(rows))


func get_rows() -> PackedRows:
	return _rows


## How many places the view has, headings among them.
func get_count() -> int:
	return _view().get_count()


## How many rows the query kept.
func get_kept() -> int:
	return _view().get_order().size()


func get_sort() -> Dictionary:
	return _sort.read()


func get_group() -> StringName:
	return _group.read()


func get_busy() -> bool:
	return _out.read()


func get_took_ms() -> float:
	return _took_ms.read()


## The rows kept, in order: every row the view shows, a shut group's too.
func get_order() -> PackedInt32Array:
	return _view().get_order()


## The row at a place in the view, or -1 for a group's heading.
func row_at(place: int) -> int:
	return _view().row_at(place)


## The index of the group whose heading or rows take this place.
func group_at(place: int) -> int:
	return _view().group_at(place)


## A group: {code, words, first - its first row's place in the order - count}.
func get_group_of(index: int) -> Dictionary:
	return _view().get_group_of(index)


## What a long list is handed: the places from first, answered at once.
func fetch(first: int, count: int, answer: Callable) -> void:
	answer.call(_view().page(first, count), _view().get_count())


## The clauses a filter asks for, as row_query.gd reads them.
func ask(clauses: Array) -> void:
	_clauses = clauses
	_query()


## The clauses the view is scoped to, beneath whatever a filter asks.
func scope_to(clauses: Array) -> void:
	_scope = clauses
	_query()


func told(action: StringName, payload: Dictionary) -> Phrase:
	match action:
		SORTS:
			var sort: Dictionary = _sort.read()
			var turned: bool = sort.get("column") == payload["column"] and sort["ascending"]
			_sort.set_value({"column": payload["column"], "ascending": payload.get("ascending", not turned)})
			_query()
		GROUPS_BY:
			_group.set_value(payload["value"])
			_query()
		SHUTS: turn_group(payload["group"])
	return null


## A group shut if open, open if shut, by its code - SHUTS, and whatever
## else a reader opens a group by, the keys on its heading.
func turn_group(code: int) -> void:
	_view().turn(code)
	_places.set_value(_view())


## The query as it stands asked again, over the rows as they now stand -
## the view brought up to its rows after they were written (view_behind.gd).
func reapply() -> void:
	_query()


## Other rows in place of these: shown at once as they were added, the
## reader's filters, order and grouping let go - they were asked of rows
## that are gone - and the view asked again over the new ones.
func replace(rows: PackedRows) -> void:
	_rows = rows
	_clauses = []
	_sort.set_value({})
	_group.set_value(&"")
	_shown_group = &""
	_shown.set_value({})
	_view().hold(rows)
	_places.set_value(_view())
	_query()


## The answer the view shown now was set out from (row_query.gd): its order,
## groups, where each row stands in the order, the query it answered, and
## the version of the rows it was worked out over.
func get_shown() -> Dictionary:
	return _shown.read()


## The query as it now stands sent off - or, with one out, asked once it lands.
func _query() -> void:
	if _out.read():
		_again = true
		return
	_out.set_value(true)
	_asked_at = Time.get_ticks_usec()
	_asked_version = _rows.get_version()
	_jobs.submit(RowQuery.run.bind(_rows.snapshot(), (_scope + _clauses).duplicate(true), _sort.read().duplicate(), _group.read()), _landed)


## An answer: the view set out from it, unless the query has changed since,
## when the query as it stands is asked instead.
func _landed(answer: Dictionary) -> void:
	_out.set_value(false)
	if _again:
		_again = false
		_query()
		return
	_took_ms.set_value((Time.get_ticks_usec() - _asked_at) / 1000.0)
	# a view grouped anew opens every group: the codes shut were another column's
	_view().set_out(answer["order"], answer["groups"], _group.read() != _shown_group)
	_places.set_value(_view())
	_shown_group = _group.read()
	answer["version"] = _asked_version
	_shown.set_value(answer)


## The view as set out now, read: noted for whoever is reading.
func _view() -> ViewPlaces:
	return _places.read()


## Every action this model is told.
func answers() -> Array[StringName]:
	return COMMANDS
