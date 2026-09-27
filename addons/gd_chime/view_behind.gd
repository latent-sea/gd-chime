extends "controller.gd"

const Commands := preload("commands.gd")
const PackedRows := preload("packed_rows.gd")
const RowQuery := preload("row_query.gd")
const QueriedRows := preload("queried_rows.gd")
const RowEdits := preload("row_edits.gd")

## Whether a queried view (queried_rows.gd) is behind its rows: written
## since its query was worked out, and not yet asked again.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## An edit (row_edits.gd) never asks the query again, so nothing re-sorts or
## goes from under the reader's hand while they work. The cost is a view
## that can be out of date - a filtered view showing a row the filter would
## no longer keep, a sorted one showing a row out of its place - and this
## makes that seen rather than hidden.
##
## BEHIND: as soon as a row the view shows is written, the view is behind,
## whether or not the write moved it: the reader is told the view is out of
## date. STALE: of the rows written, those the query would no longer keep,
## or that now sit out of order beside the rows around them, are named, for
## their row to be drawn dimmed and marked. Each written row is judged as
## it is written, by the query the view answered (row_query.gd), against
## the rows as they now stand; a row written back to what it was is no
## longer stale, though the view stays behind.
##
## REAPPLIES asks the view's query again, over the rows as they stand; it
## is refused while the view is not behind. When an answer lands, the rows
## written before it was asked are in it, and let go: asked after the last
## write, it clears both. A write while it was out keeps its row.
##
## Before its first answer - and from the moment other rows replace its
## own - the view shows the rows as they were added, by no query, and
## nothing is behind: what was written is let go.
##
## Deliberately absent: telling a reader of rows written that the view does
## not show but would now keep - it is behind only for what it shows.

const REAPPLIES := &"reapplies_the_query"
## The one action this is told.
const COMMANDS: Array[StringName] = [REAPPLIES]

var _view: QueriedRows
var _edits: RowEdits
var _written: Dictionary = {}  # a row written since the view's query -> the rows' version once it was
var _stale := value({})  # the written rows the query would put elsewhere or leave out, used as a set
var _behind := value(false)
var _seen: Dictionary = {}  # the answer the view was last set out from, as last followed
var _begun: bool = false  # whether both are followed: the first reads of each are only reads


func _init(chimes: Chimes, view: QueriedRows, edits: RowEdits) -> void:
	super(chimes)
	_view = view
	_edits = edits
	follow(&"written", _rows_written)
	follow(&"view", _view_moved)
	_begun = true


## Whether a row the view shows has been written since its query.
func get_behind() -> bool:
	return _behind.read()


## The rows the view shows that its query would now put elsewhere or leave out, as a set.
func get_stale() -> Dictionary:
	return _stale.read()


## Asking again is refused while the view is up to date.
func would(_action: StringName, _payload: Dictionary) -> Phrase:
	return null if _behind.read() else Phrase.of("The view is up to date")


func told(_action: StringName, _payload: Dictionary) -> Phrase:
	_view.reapply()
	return null


## The rows written read, so they are followed; written, every one of them
## kept with the version it was written at, and all judged.
func _rows_written() -> void:
	var written := _edits.get_written()
	var shown := _view.get_shown()
	if not _begun or _let_go(shown):
		return
	var version := _view.get_rows().get_version()
	# every row just written, the version it was written at kept
	for row: int in written:
		_written[row] = version
	_judge(shown)


## The view's answer read, so it is followed; a new one set out, every row
## written before it was asked let go, and the rest judged.
func _view_moved() -> void:
	var shown := _view.get_shown()
	# a group shut or opened sets the same answer out again: nothing new is shown
	if not _begun or _let_go(shown) or is_same(shown, _seen):
		return
	_seen = shown
	# every row written: let go if the answer was worked out after it
	for row: int in _written.keys():
		if _written[row] <= shown["version"]:
			_written.erase(row)
	_judge(shown)


## With no answer yet - or other rows just come - the rows as they were
## added, by no query to be behind: nothing held, and whether that was so.
func _let_go(shown: Dictionary) -> bool:
	if not shown.is_empty():
		return false
	_written.clear()
	_stale.set_value({})
	_behind.set_value(false)
	return true


## Every row written since that the view shows, judged together: the view
## behind while there is one; each stale if its query would no longer keep
## it or it now sits out of order beside the rows around it that were not
## written (row_query.gd, misplaced), else not.
func _judge(shown: Dictionary) -> void:
	var index_of: PackedInt32Array = shown["index_of"]
	var showing := PackedInt32Array(_written.keys().filter(func(row: int) -> bool: return index_of[row] >= 0))
	_behind.set_value(not showing.is_empty())
	var stale: Dictionary = {}
	# every row the query would now put elsewhere or leave out, stale
	for row: int in RowQuery.misplaced(_view.get_rows(), shown, showing):
		stale[row] = true
	_stale.set_value(stale)


## Every action this model is told.
func answers() -> Array[StringName]:
	return COMMANDS
