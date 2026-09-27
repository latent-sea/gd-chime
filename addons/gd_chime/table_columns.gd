extends "controller.gd"

const Commands := preload("commands.gd")

## The columns a table shows: which of them, in their order, and how wide
## each is as a share of the table - moved by command, so a drag, a key
## and the pad resize alike, and a column hidden is one pressed away.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A COLUMN is {name, words, share}: the name its rows' values are read by,
## the words its heading says - a phrase - and its share of the width; and
## "edits", true for one whose cells the reader may type into. The
## shares of the columns shown are what the table lays out by, so a column
## hidden gives its width to the rest in proportion and one shown takes it
## back; get_shown() answers them made up to the whole.
##
## RESIZES {column, by} moves the edge on a column's right: that column
## gains the share and the next one shown loses it, so the rest stand where
## they are, and neither is taken below the LEAST share this was built
## with - a resize past it stops there. Asked with no "by" - the edge's grip
## at rest, asking whether it can be moved at all - it is refused only where
## neither side can give. The last column shown has no edge to
## move. TURNS {column} hides a column shown or shows one hidden; the last
## one shown is never hidden, since a table of nothing reads as broken.
##
## A share is never narrower than a column's words at the width the table
## has: that floor is a measure of the words in the look's font, so it is
## the line that lays the columns out that keeps it (cells.gd), a column
## given less than its words need getting what they need.
##
## OTHER COLUMNS come by replace() - other rows', an application's query
## run again - every one shown; get_shape() moves on with each, so a table
## knows to build its lines again.
##
## Deliberately absent: moving a column to another place, and a width in
## anything but a share.

const RESIZES := &"resizes_a_column"
const TURNS := &"turns_a_column"
## Every action this is told.
const COMMANDS: Array[StringName] = [RESIZES, TURNS]

var _columns := value([])  # {name, words, share}, in their order - changed in place and set again
var _hidden := value({})  # the names of the columns hidden, used as a set
var _least: float  # the least share a resize leaves a column
var _shape := value(0)  # moved on by every replace


func _init(chimes: Chimes, columns: Array, least: float) -> void:
	super(chimes)
	_columns.set_value(columns.duplicate(true))
	_least = least


## The columns shown, in order, their shares made up to the whole.
func get_shown() -> Array:
	var hidden: Dictionary = _hidden.read()
	var shown: Array = _columns.read().filter(func(column: Dictionary) -> bool: return not hidden.has(column["name"]))
	var whole: float = shown.reduce(func(sum: float, column: Dictionary) -> float: return sum + column["share"], 0.0)
	return shown.map(func(column: Dictionary) -> Dictionary: return {"name": column["name"], "words": column["words"], "share": column["share"] / whole, "edits": column.get("edits", false)})


## Every column, in order, each with whether it is shown - for a chooser,
## and for a table building a part for every column there is.
func get_all() -> Array:
	var hidden: Dictionary = _hidden.read()
	return _columns.read().map(func(column: Dictionary) -> Dictionary: return {"name": column["name"], "words": column["words"], "share": column["share"], "edits": column.get("edits", false), "shown": not hidden.has(column["name"])})


## How many times the columns have been replaced: a table builds its lines
## again for each new set, since every line is laid out for its columns.
func get_shape() -> int:
	return _shape.read()


## Other columns in place of these - other rows' - every one shown.
func replace(columns: Array) -> void:
	_columns.set_value(columns.duplicate(true))
	_hidden.set_value({})
	_shape.set_value(_shape.read() + 1)


## Resizing the last column shown, or one already as far as it goes that
## way, and hiding the last column shown, are refused.
func would(action: StringName, payload: Dictionary) -> Phrase:
	if action == TURNS:
		return Phrase.of("The last column shown stays") if get_shown().size() == 1 and not _hidden.read().has(payload["column"]) else null
	# a pop-up answered by this hands it the way back as well, which it refuses nothing
	if action != RESIZES:
		return null
	var at := _shown_at(payload["column"])
	var shown := get_shown()
	if at == shown.size() - 1:
		return Phrase.of("The last column has no edge to move")
	# a grip asked at rest carries no move yet: either side of its edge may give
	var by: float = payload.get("by", 0.0)
	var giving: Array = ([shown[at + 1]] if by >= 0.0 else []) + ([shown[at]] if by <= 0.0 else [])
	return Phrase.of("As narrow as a column goes") if giving.all(func(column: Dictionary) -> bool: return column["share"] <= _least + 0.0001) else null


func told(action: StringName, payload: Dictionary) -> Phrase:
	if action == TURNS:
		var hidden: Dictionary = _hidden.read()
		if hidden.has(payload["column"]):
			hidden.erase(payload["column"])
		else:
			hidden[payload["column"]] = true
		_hidden.set_value(hidden)
	elif action == RESIZES:
		resize(payload["column"], payload["by"])
	return null


## The edge right of a column moved by this share - RESIZES, and whatever
## else resizes the column the reader is on, the keys in a table.
func resize(column: StringName, by: float) -> void:
	_normalise()
	var columns: Array = _columns.read()
	var at := _index_of(column)
	var next := _index_of(get_shown()[_shown_at(column) + 1]["name"])
	# the share moved across the edge, held so neither side goes below the least
	var moved: float = clampf(by, _least - columns[at]["share"], columns[next]["share"] - _least)
	columns[at]["share"] += moved
	columns[next]["share"] -= moved
	_columns.set_value(columns)


## The shown columns' shares made up to the whole in place, so a resize moves shares of the table as it stands.
func _normalise() -> void:
	var columns: Array = _columns.read()
	# every shown column, its share as the table shows it now
	for column: Dictionary in get_shown():
		columns[_index_of(column["name"])]["share"] = column["share"]


## Where a column stands among those shown.
func _shown_at(name: StringName) -> int:
	return get_shown().map(func(column: Dictionary) -> StringName: return column["name"]).find(name)


## Where a column stands among them all.
func _index_of(name: StringName) -> int:
	return _columns.read().map(func(column: Dictionary) -> StringName: return column["name"]).find(name)


## Every action this model is told.
func answers() -> Array[StringName]:
	return COMMANDS
