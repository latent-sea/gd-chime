extends RefCounted

const PackedRows := preload("packed_rows.gd")

## The places of a queried view (queried_rows.gd): the rows an answer kept,
## in order, set out as the places a reader scrolls through, and read a
## page at a time.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Ungrouped, a place is a row. GROUPED, each group's heading is a place of
## its own, never a row, followed - while the group is open - by its rows.
## A group is shut or opened by its code; an answer grouped anew has every
## group open. Which place is what is worked out from the groups alone,
## halving, so a view of a hundred thousand rows costs nothing to set out.
##
## A page is dictionaries, made a place at a time: a row's own (packed_rows.gd,
## row_at) with "at", its place; a heading's {"group", "words", "count",
## "open", "at"}.
##
## It rings nothing: the view that holds it says when its places moved.
##
## Deliberately absent: a heading that is a row, and any order but the answer's.

var _rows: PackedRows
var _order := PackedInt32Array()  # the rows kept, in order
var _groups: Array = []  # {code, words, first, count}, grouped
var _starts := PackedInt32Array()  # grouped: the place each group's heading takes
var _shut: Dictionary = {}  # the codes of the groups shut, used as a set
var _count: int = 0  # how many places there are


## These rows as they were added, every one a place, by no query.
func _init(rows: PackedRows) -> void:
	hold(rows)


## Other rows, set out as they were added, every one a place, nothing shut.
func hold(rows: PackedRows) -> void:
	_rows = rows
	_groups = []
	_shut.clear()
	set_out(PackedInt32Array(range(rows.count())), [], false)


## An answer's rows kept and its groups set out as places - every group open
## again when the answer is grouped anew, the codes shut being another column's.
func set_out(order: PackedInt32Array, groups: Array, regrouped: bool) -> void:
	if regrouped:
		_shut.clear()
	_order = order
	_groups = groups
	_place_groups()


## A group shut if open, open if shut, by its code, and the places set out again.
func turn(code: int) -> void:
	if _shut.has(code):
		_shut.erase(code)
	else:
		_shut[code] = true
	_place_groups()


## How many places there are, headings among them.
func get_count() -> int:
	return _count


## The rows kept, in order: every row there is a place for, a shut group's too.
func get_order() -> PackedInt32Array:
	return _order


## The row at a place, or -1 for a group's heading.
func row_at(place: int) -> int:
	if _groups.is_empty():
		return _order[place]
	var group := group_at(place)
	var within := place - _starts[group] - 1
	return -1 if within < 0 else _order[_groups[group]["first"] + within]


## The index of the group whose heading or rows take this place, by halving.
func group_at(place: int) -> int:
	return _starts.bsearch(place, false) - 1


## A group: {code, words, first - its first row's place in the order - count}.
func get_group_of(index: int) -> Dictionary:
	return _groups[index]


## The places from first, as many as asked that there are, each a dictionary.
func page(first: int, count: int) -> Array:
	var made: Array = []
	# every place asked for that there is, a row or a heading
	for place: int in range(first, mini(first + count, _count)):
		made.append(_place(place))
	return made


func _place(place: int) -> Dictionary:
	var row := row_at(place)
	if row >= 0:
		var made := _rows.row_at(row)
		made["at"] = place
		return made
	var group: Dictionary = _groups[group_at(place)]
	return {"group": group["code"], "words": group["words"], "count": group["count"], "open": not _shut.has(group["code"]), "at": place}


## Each heading's place, then its rows' places while it is open.
func _place_groups() -> void:
	_starts = PackedInt32Array()
	_count = 0 if not _groups.is_empty() else _order.size()
	# every group, its heading's place, then its rows' places if it is open
	for group: Dictionary in _groups:
		_starts.append(_count)
		_count += 1 + (0 if _shut.has(group["code"]) else group["count"])
