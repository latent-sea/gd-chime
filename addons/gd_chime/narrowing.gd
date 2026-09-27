extends "controller.gd"

## A narrowing: the text a reader has typed to find one option among many,
## and the options that text leaves.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A picker over sixty or six hundred options cannot be a list the reader
## walks, so the reader types and the list shrinks. What is typed is state,
## so it lives here: the recipe (type_ahead.gd) shows TYPED, OPTIONS and
## COUNT and presses the two actions, and holds none of it.
##
## The options are a SOURCE handed in - a bound value reading an array of
## {value, words} - never a list written here, so the same narrowing serves
## a set of properties, a set of names, or whatever else the caller reads;
## and because it is bound, this follows whatever the source read and
## narrows again when what there is to pick from changes. OPTIONS are the
## entries whose words contain what was typed, ignoring case, in the
## source's order, at most LIMIT of them, because a reader cannot use a
## thousand rows; COUNT is how many match in all, so the reader is told
## there is more than is shown and types further.
##
## It answers the TYPING action, which carries {"line"}: the text as it
## stands, on every keystroke. PICKING is NOT its: what picking an option
## means - a filter built, a name chosen, a place opened - belongs to
## whoever put the picker there, so that action is registered against
## their model and never reaches this.
##
## WHAT MATCHES IS WORKED OUT ONCE per keystroke and per move of the
## source, however often it is read, and kept with what it read, so whoever
## reads it follows the typing and the source - the options and the count read the
## same answer - and the source's words are lowered once per move of the
## source, not once per keystroke: a palette over a few thousand entries
## narrows as fast as the reader types.
##
## Deliberately absent: a chosen option, an order of its own, and any
## scoring of one match as better than another - the source's order is the
## order, since only whoever reads the source knows what is worth showing
## first.

const Reads := preload("reads.gd")

var _source: Bound
var _limit: int
var _types: StringName  # the action the typing into it is told, where whoever made it stands it up on its own
var _typed := value("")  # what the reader has typed so far
var _lowered: Array = []  # the source's entries each [its words lowered, the entry], worked out once and let go as the source moves (reads.gd)
var _found: Array = []  # the entries matching what is typed, worked out once and let go as either moves (reads.gd)


## Over these options, so many shown at once, told this action where it
## is stood up on its own rather than through the model that holds it.
func _init(chimes: Chimes, source: Bound, limit: int = 8, types: StringName = &"") -> void:
	super(chimes)
	_source = source
	_types = types
	_limit = limit
	follow(&"source", _source_moved)


## What the reader has typed so far.
func get_typed() -> String:
	return _typed.read()


## The matching options, in the source's order, as many as the limit allows.
func get_options() -> Array:
	return _matching().slice(0, _limit)


## How many options match in all, however few are shown.
func get_count() -> int:
	return _matching().size()


## Typed: the line as it stands now, and the options narrowed to it - which
## is worked out again as it is next read, because what is typed is among
## what that reading was kept with (reads.gd).
func told(_action: StringName, payload: Dictionary) -> Phrase:
	_typed.set_value(payload["line"])
	return null


## The source read, so it is followed - its words lowered as it is, the one
## read of it a move; moved, what there is to pick from is different, and
## both readings, each kept with its read of the source, work out afresh.
func _source_moved() -> void:
	_lower()


## The source's entries each beside its words lowered, worked out once a move of the source.
func _lower() -> Array:
	return Reads.worked(_lowered, func() -> Array:
		# every entry of the source, beside its words lowered once
		return (_source.read() as Array).map(func(option: Dictionary) -> Array: return [(option["words"] as String).to_lower(), option]))


## The source's entries whose words contain what was typed, ignoring case -
## every entry while nothing is typed - worked out once until either moves.
func _matching() -> Array:
	return Reads.worked(_found, func() -> Array:
		var lowered: Array = _lower()
		var wanted := (_typed.read() as String).to_lower()
		var found: Array = []
		# every entry, kept where its lowered words hold what was typed - all of them for nothing typed, since the engine finds no empty needle in any word
		for pair: Array in lowered:
			if wanted == "" or (pair[0] as String).contains(wanted):
				found.append(pair[1])
		return found)


## The typing this is told, where it was made with one: a model that
## holds a narrowing and forwards the typing to it says the action itself.
func answers() -> Array[StringName]:
	var told: Array[StringName] = []
	if _types != &"":
		told.append(_types)
	return told
