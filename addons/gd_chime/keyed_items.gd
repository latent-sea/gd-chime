extends "controller.gd"

const Throttle := preload("throttle.gd")

## Items by key, each a value with a bell of its own: one item changing
## tells what shows that item and nothing else - the tile of one device on a
## wall of five hundred - and the tallies of the whole set move at a
## reader's pace.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A BOUND VALUE OVER A WHOLE ARRAY re-reads everything on its one bell: an
## each re-reads every item, every text over it is drawn again, for one item
## that moved. Here a key's item is a value of its own (value.gd) with a
## bell of its own (own_bell.gd), read through item(key), so a change
## reaches the few things showing that item. The keys and their order are
## fixed as this is built: a set whose members come and go is an each's,
## over an array.
##
## A CHANGE IS GATHERED, NEVER RUNG AT ONCE: set_field() writes the item
## now - a read straight after sees it - and its value's bell rings once at
## the frame's end, however many times it moved. A field set to the value it
## holds is no change and rings nothing. What an item holds is a dictionary
## of plain values, compared as such.
##
## TALLIES are counts of the items by the value of a named field - how many
## are down, how many are well - kept as each change lands, never counted
## over the set again, and read through tallied(field), which moves at the
## look's cadence (Throttle.CADENCE), since a count a reader glances at has
## nothing to say sixty times a second.
##
## Deliberately absent: adding or removing a key, and a change carrying
## what it changed - a bell carries nothing.

var _keys: Array  # the keys in the order they were given
var _items: Dictionary = {}  # key -> its item, a value of its own holding a dictionary
var _tallies: Dictionary = {}  # tallied field -> {value -> how many items hold it}
var _paced := value(0)  # moved on at the look's cadence while items move, so what reads the tallies reads them at that pace
var _pacing: Throttle


## These items, each keyed by the value of the field named, with the
## tallies of these fields kept.
func _init(chimes: Chimes, items: Array, key: StringName, tallied: Array[StringName]) -> void:
	super(chimes)
	# every field tallied, its counts begun empty
	for field: StringName in tallied:
		_tallies[field] = {}
	# every item, kept under its key as a value with a bell of its own, and its fields tallied
	for item: Dictionary in items:
		var named: Variant = item[key]
		var own := OwnBell.new("item")
		own.hang(chimes)
		_keys.append(named)
		_items[named] = Value.new(own, item.duplicate())
		_count(item, 1)
	_pacing = Throttle.new(func() -> void: _paced.set_value(_paced.read() + 1), {paced_by = Throttle.CADENCE})
	add_child(_pacing)


## The keys, in the order given.
func get_keys() -> Array:
	return _keys


## The item under this key, as it is now.
func get_item(key: Variant) -> Dictionary:
	return _items[key].read()


## This key's item, a value on its own bell alone.
func item(key: Variant) -> Value:
	return _items[key]


## How many items hold each value of this field: {value -> count}, moving at the look's cadence.
func tallied(field: StringName) -> Bound:
	return Bound.new(func() -> Dictionary:
		_paced.read()
		return _tallies[field].duplicate())


## One field of one item set: written now, and its bell rung once at the
## frame's end - nothing, where the field holds that value already.
func set_field(key: Variant, field: StringName, value: Variant) -> void:
	var held: Dictionary = _items[key].read()
	if held[field] == value:
		return
	_count(held, -1)
	held[field] = value
	_count(held, 1)
	_items[key].set_value(held)
	_pacing.ask()


## This item's tallied fields counted in, or out.
func _count(item: Dictionary, by: int) -> void:
	# every field tallied, the count of this item's value for it moved
	for field: StringName in _tallies:
		var counts: Dictionary = _tallies[field]
		var value: Variant = item[field]
		counts[value] = counts.get(value, 0) + by
		if counts[value] == 0:
			counts.erase(value)
