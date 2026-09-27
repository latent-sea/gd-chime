extends "long_list.gd"

## A long list that grows as the reader goes: its look runs from the first
## row and takes one more page each time it is asked - the model of an
## infinite collection (infinite_collection.gd).
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A LONG LIST UNDERNEATH (long_list.gd): its source, its pages held,
## asked for, landed and failed, its reset when what its rows move with moves.
## Here the look is always from the first row, and how many it shows is
## the only thing that moves: GROWS shows a page more, refused while a row
## already showing is still on its way - so a reader racing to the foot
## asks for one page at a time - and refused once everything shows. Every
## page shown is kept; a reset - the rows changed under it, a filter or a
## sort - shows the first page alone again.
##
## THE ITEMS are what a collection draws: one per row showing, {at, item} -
## its place and the row, or null for a row still on its way, which a
## collection draws as the shape of what will land there. Before the first
## page lands there is no total, and the items are a page of nulls; once a
## page lands, never more than the list holds - and none at all where the
## source says it holds nothing, which is EMPTY, for the caller's words.
##
## Deliberately absent: letting go of pages far above the reader - a
## collection this model serves holds its rows as pieces all the same.

const GROWS := &"grows_the_list"
## The one action a growing list is told beyond a long list's own.
const GROWING: Array[StringName] = [GROWS]

var _page_rows: int
var _known: bool = false  # whether a page has landed since the rows last changed, so the total is the source's
var _items_now: Variant = null  # the items as last read, or null once anything they are read from changed


## Over this source, so many rows a page, following what its rows move with.
func _init(chimes: Chimes, fetch: Callable, page: int, rows: Bound) -> void:
	super(chimes, fetch, page, 1 << 20, page, rows)
	_page_rows = page


## The items, whether there is more, whether it is empty and whether a row
## failed move as the look does, as a page lands or fails, and as failures
## are forgotten: all four noted for whoever reads one.
func _noted() -> void:
	# every bell of the list's
	for bell: StringName in [LOOK_MOVED, PAGE_LANDED, PAGE_FAILED, FAILURES_FORGOTTEN]:
		Reads.note(region, bell)


## One per row showing: {at, item}, the item null while it is on its way -
## the very same array read after read until something here changes, so a
## hundred cards re-reading on one bell share one array.
func get_items() -> Array:
	_noted()
	if _items_now == null:
		var showing := get_showing() if not _known else mini(get_showing(), count())
		_items_now = range(showing).map(func(at: int) -> Dictionary: return {"at": at, "item": null if has_failed(at) else get_item(at)})
	return _items_now


## Whether there is more than shows: before the total is known, there may be.
func get_more() -> bool:
	_noted()
	return not _known or get_showing() < count()


## Whether the source has said there is nothing at all.
func get_empty() -> bool:
	_noted()
	return _known and count() == 0


## Whether a row showing could not be given.
func get_failed() -> bool:
	_noted()
	return range(get_showing()).any(func(at: int) -> bool: return has_failed(at))


## Growing: refused once everything shows, and while a row showing is on its way.
func would(action: StringName, payload: Dictionary) -> Phrase:
	if action != GROWS:
		return super(action, payload)
	_noted()
	if _known and get_showing() >= count():
		return Phrase.of("Everything is showing")
	if not _known or not range(get_showing()).all(func(at: int) -> bool: return has(at) or at >= count()):
		return Phrase.of("Still loading")
	return null


func told(action: StringName, payload: Dictionary) -> Phrase:
	_items_now = null
	if action == GROWS:
		return super(SHOWS, {"count": get_showing() + _page_rows})
	return super(action, payload)


## The rows changed under it: the first page alone, asked for again.
func reset() -> void:
	_showing = _page_rows
	_known = false
	_items_now = null
	super()
	strike(region, LOOK_MOVED)


## Looking again, as its place fills: nothing is known until a page lands.
func look(under: Token) -> void:
	_known = false
	_items_now = null
	super(under)


## Not looking: everything it held forgotten.
func drop() -> void:
	_items_now = null
	super()


## A page landed under a live token: the total is the source's from now on.
func _landed(rows: Variant, total: int, page: int, token: Token) -> void:
	_known = _known or (token.is_live() and rows != null)
	_items_now = null
	super(rows, total, page, token)


## Every action this model is told.
func answers() -> Array[StringName]:
	return super() + GROWING
