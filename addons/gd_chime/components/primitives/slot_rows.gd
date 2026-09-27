extends RefCounted

## Which row each slot of a virtual list (virtual_list.gd) shows, and which
## slots have something new to show after the list moved - so a scroll of
## three rows re-reads three slots, not every one.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A slot is known by the order it was made in, its identity, which never
## changes; the ORDER is the identities top to bottom now. A scroll by fewer
## rows than there are slots TURNS the order: the slots scrolled out of
## view at one end are taken to the other and given the rows coming into
## view there, and every other slot keeps the row it had - so the list
## moves those few slots, and the rest are where they were with nothing
## new to say. A scroll by as many or more gives every slot a new row.
##
## After any move, a page landing or a failure, each slot's item is read
## again and compared with the one it showed: CHANGED names the slots whose
## item is not the same, and those alone are told. A slot shows the item
## it was last told, read by its identity.
##
## It holds no node and rings nothing: the list does both.

var _order: Array[int] = []  # the slots' identities, top to bottom
var _rows: Array[int] = []  # by identity, the row each slot shows
var _items: Array = []  # by identity, the item each slot was last told
var _first: int = 0  # the row the top slot shows


## One more slot, at the bottom: its identity.
func add() -> int:
	var made := _rows.size()
	_order.append(made)
	_rows.append(_first + made)
	_items.append(null)
	return made


## The last slot made let go.
func remove() -> void:
	_order.erase(_rows.size() - 1)
	_rows.pop_back()
	_items.pop_back()


func count() -> int:
	return _order.size()


## The identities, top to bottom.
func get_order() -> Array[int]:
	return _order


## What the slot of this identity was last told.
func get_item(slot: int) -> Variant:
	return _items[slot]


## The list looking from this row, each row's item read by this function:
## the order turned where it can be, every slot given its row, and the
## identities whose item changed - {turned, changed}, turned the number of
## slots taken from the top to the bottom, or from the bottom to the top
## for a negative.
func follow(first: int, read: Callable) -> Dictionary:
	var count := _order.size()
	var turned := first - _first if absi(first - _first) < count else 0
	if turned > 0:
		_order.assign(_order.slice(turned) + _order.slice(0, turned))
	elif turned < 0:
		_order.assign(_order.slice(count + turned) + _order.slice(0, count + turned))
	_first = first
	# every place top to bottom, the slot standing there given its row
	for place: int in count:
		_rows[_order[place]] = first + place
	var changed: Array[int] = []
	# every slot, told again only where its item is not the one it showed
	for slot: int in count:
		var item: Variant = read.call(_rows[slot])
		if item != _items[slot] or typeof(item) != typeof(_items[slot]):
			_items[slot] = item
			changed.append(slot)
	return {"turned": turned, "changed": changed}
