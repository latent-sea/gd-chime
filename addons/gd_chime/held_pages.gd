extends RefCounted

## The pages a long list (long_list.gd) holds: those landed, those on the
## way, those the source could not give, and how long the whole list is -
## so the list keeps only its look and what moves it.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A page is PAGE rows. wanted() says which pages a look needs - the pages
## covering it and one either side - that are neither held, on the way,
## failed nor past the end, and marks them on the way; it forgets, as it
## goes, a failure the look no longer covers, so coming back asks again. A
## page landed is kept and the total remembered; held past KEEP pages, the
## one farthest from the page that just landed is let go, so memory stays
## flat. A page failed is remembered as failed, every row of it.
##
## It asks nothing and rings nothing: the list does both.

var _page: int
var _keep: int
var _pages: Dictionary = {}  # page -> its rows, for the pages that have landed
var _on_the_way: Dictionary = {}  # the pages asked for and not landed, used as a set
var _failed: Dictionary = {}  # the pages the source could not give, used as a set
var _total: int = 0


func _init(page: int, keep: int) -> void:
	_page = page
	_keep = keep


## How long the whole list is, as the source last said. 0 until a page lands.
func count() -> int:
	return _total


## Whether the row at this index is held. An index past the end is not, even
## when the page it would fall on is.
func has(index: int) -> bool:
	return index < _total and _pages.has(floori(float(index) / _page))


## Whether the row at this index falls on a page the source could not give.
func has_failed(index: int) -> bool:
	return _failed.has(floori(float(index) / _page))


## The row at this index, or null if it is not held.
func get_item(index: int) -> Variant:
	if not has(index):
		return null
	return _pages[floori(float(index) / _page)][index % _page]


## Everything forgotten.
func forget() -> void:
	_pages.clear()
	_on_the_way.clear()
	_failed.clear()
	_total = 0


## Every failure forgotten: whether there was any.
func forget_failures() -> bool:
	var any := not _failed.is_empty()
	_failed.clear()
	return any


## The pages a look from this row of this many rows needs asked for, each
## marked on the way; a failure it no longer covers forgotten.
func wanted(first: int, showing: int) -> Array[int]:
	var from := maxi(floori(float(first) / _page) - 1, 0)
	var to := floori(float(first + showing - 1) / _page) + 1
	# every failure this look no longer covers, forgotten so that coming back asks again
	for page: int in _failed.keys():
		if page < from or page > to:
			_failed.erase(page)
	var asked: Array[int] = []
	# every page from one before the rows shown to one after them
	for page: int in range(from, to + 1):
		if _pages.has(page) or _on_the_way.has(page) or _failed.has(page) or (_total > 0 and page * _page >= _total):
			continue
		_on_the_way[page] = true
		asked.append(page)
	return asked


## A page landed, with the total: kept, and past KEEP the farthest let go.
func landed(page: int, rows: Array, total: int) -> void:
	_on_the_way.erase(page)
	_pages[page] = rows
	_total = total
	# while more pages are held than kept: the one farthest from this landing is let go
	while _pages.size() > _keep:
		var farthest := page
		# every page held, for the one farthest from the page that just landed
		for held: int in _pages:
			if absi(held - page) > absi(farthest - page):
				farthest = held
		_pages.erase(farthest)


## A page the source could not give.
func failed(page: int) -> void:
	_on_the_way.erase(page)
	_failed[page] = true
