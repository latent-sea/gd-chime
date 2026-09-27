extends "res://addons/gd_chime/controller.gd"

const Commands := preload("res://addons/gd_chime/commands.gd")
const Layer := preload("res://demo/grid/layer.gd")

## The table's data, as much of it as has arrived: pages of an array that
## lives in the layer, on another thread - and where in it the table is
## looking.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A model: it asks the layer and keeps what comes back, each fact a value
## (value.gd) - the arrivals known, how many there are, whether an add is
## out, and the first row showing - set as it moves. It never waits. What has not landed, it has not got: a
## reader asking is told so, and asks this to fetch.
##
## THE LOOK is this model's, not the screen's: the first row showing, read as
## get_first(), moved only by the commands SCROLL_TABLE_UP and
## SCROLL_TABLE_DOWN this is registered for. It never goes below zero: a
## negative index would be read by the engine's arrays as counting from the
## end. There is no bound above, because the array only grows; a slot past
## the end shows nothing, which is what a window run off the end looks like.
##
## PAGES. Arrivals are kept by index, sparsely - the ones from pages that have
## landed. A page is asked for once; asked for again while in flight, it is
## not asked for twice. Far pages are never dropped here, because the array
## only grows and a demo is short; dropping is a pure addition.
##
## AN ADD SHIFTS EVERYTHING. One more at the front moves every index up one,
## so what is known moves with it. ADD_ARRIVAL is the command that asks for
## one. Deliberately absent: a guard against a page answered after a later
## add, which would describe the old indices. This layer answers in the order
## asked, so it cannot happen; a layer that answers out of order - a server -
## needs one, and it is a number carried by the request and checked on the
## answer.
##
## BUSY. From an add going out to its landing, is_busy() is true, set at the
## two ends, so a screen can draw the waiting.

const ADD_ARRIVAL := &"add_arrival"
const SCROLL_TABLE_UP := &"scroll_table_up"
const SCROLL_TABLE_DOWN := &"scroll_table_down"
## Every action this is told.
const COMMANDS: Array[StringName] = [ADD_ARRIVAL, SCROLL_TABLE_UP, SCROLL_TABLE_DOWN]

var _layer: Layer
var _known := value({})  # index -> arrival number, for the pages that have landed
var _count := value(0)
var _in_flight: Dictionary = {}  # the pages asked for and not yet landed, used as a set
var _busy := value(false)
var _first := value(0)


func _init(chimes: Chimes, layer: Layer) -> void:
	super(chimes)
	_layer = layer
	fetch(0)


func count() -> int:
	return _count.read()


func get_busy() -> bool:
	return _busy.read()


func is_busy() -> bool:
	return _busy.read()


## The first row showing.
func get_first() -> int:
	return _first.read()


## Whether the arrival at this index has landed.
func has(index: int) -> bool:
	return _known.read().has(index)


func get_arrival(index: int) -> int:
	return _known.read()[index]


## Ask the layer for the page holding this index, unless that page is already
## on its way.
func fetch(index: int) -> void:
	@warning_ignore("integer_division")
	var page := index / Layer.PAGE
	if _in_flight.has(page):
		return
	_in_flight[page] = true
	_layer.fetch_page(page, _page_landed)


## A scroll up at the top, or an arrival while one is on its way, is refused.
func would(action: StringName, _payload: Dictionary) -> Phrase:
	if action == SCROLL_TABLE_UP and _first.read() == 0:
		return Phrase.of("Already at the top")
	if action == ADD_ARRIVAL and _busy.read():
		return Phrase.of("Already adding one")
	return null


func told(action: StringName, _payload: Dictionary) -> Phrase:
	match action:
		SCROLL_TABLE_UP: _move_to(_first.read() - 1)
		SCROLL_TABLE_DOWN: _move_to(_first.read() + 1)
		ADD_ARRIVAL:
			_busy.set_value(true)
			_layer.add(_add_landed)
	return null


## The first row set, never below zero, if it moved.
func _move_to(first: int) -> void:
	if maxi(first, 0) != _first.read():
		_first.set_value(maxi(first, 0))


## On the main thread, when a page answer lands.
func _page_landed(answer: Dictionary) -> void:
	@warning_ignore("integer_division")
	var page: int = answer["first"] / Layer.PAGE
	_in_flight.erase(page)
	_count.set_value(answer["count"])
	# every arrival in the page, kept under its own index
	for offset: int in range(answer["arrivals"].size()):
		_known.read()[answer["first"] + offset] = answer["arrivals"][offset]
	# the arrivals known, changed in place, set again for whatever reads them
	_known.set_value(_known.read())


## On the main thread, when an add lands: everything known moves up one.
func _add_landed(answer: Dictionary) -> void:
	var shifted: Dictionary = {}
	# every known arrival, one index further on than it was
	for index: int in _known.read():
		shifted[index + 1] = _known.read()[index]
	shifted[0] = answer["arrival"]
	_known.set_value(shifted)
	_count.set_value(answer["count"])
	_busy.set_value(false)


## Every action this model is told.
func answers() -> Array[StringName]:
	return COMMANDS
