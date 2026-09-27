extends "controller.gd"

const Commands := preload("commands.gd")
const QueriedRows := preload("queried_rows.gd")

## The order a collection runs in, chosen by name - "Price, low to high" -
## as a choice's options, set on the rows' view as its sort.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A shop's sort is a choice of a few named orders, each a column and a
## way, never a heading pressed twice: ORDERS {value}, the payload a choice
## (combo.gd) carries, sets the one named on the view (queried_rows.gd) at
## once - the view's own sort, {column, ascending} - and the one chosen, a
## value (value.gd), is set. The
## first named is the order it starts in.
##
## Deliberately absent: an order by more than one column, which the view
## does not have.

const ORDERS := &"orders_by"
## The one action this is told.
const COMMANDS: Array[StringName] = [ORDERS]

var _view: QueriedRows
var _named: Dictionary  # name -> {column, ascending, words}
var _chosen := value(&"")


## Over this view, these orders by name, each {column, ascending, words}.
func _init(chimes: Chimes, view: QueriedRows, named: Dictionary) -> void:
	super(chimes)
	_view = view
	_named = named
	_choose(named.keys()[0])


## The order it runs in now, by name.
func get_chosen() -> StringName:
	return _chosen.read()


## The orders to choose from, as a choice's options: {value, words}.
func get_options() -> Array:
	return _named.keys().map(func(name: StringName) -> Dictionary: return {"value": name, "words": _named[name]["words"]})


func told(_action: StringName, payload: Dictionary) -> Phrase:
	_choose(payload["value"])
	return null


func _choose(name: StringName) -> void:
	_chosen.set_value(name)
	_view.told(QueriedRows.SORTS, {"column": _named[name]["column"], "ascending": _named[name]["ascending"]})


## Every action this model is told.
func answers() -> Array[StringName]:
	return COMMANDS
