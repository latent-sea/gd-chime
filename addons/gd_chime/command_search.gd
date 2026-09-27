extends "narrowing.gd"

const Driver := preload("driver.gd")
const Actions := preload("actions.gd")
const ActionControl := preload("action_control.gd")
const Relay := preload("relay.gd")

## What the command palette searches: every command the reader could press
## on the screen now, and whatever else the application hands in - its
## datasets, its files - narrowed by what is typed, one pick sending it on.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A NARROWING (narrowing.gd), which this extends: what is typed narrows the
## entries, the options are the first of them and the count says how many
## match. Each entry is {value, words, kind, action, payload, region} - what
## it reads as, what sort of thing it is, and the press it stands for
## (relay.gd).
##
## THE COMMANDS ARE THE SCREEN'S OWN. Every action a control draws, with
## nothing to say about what it is pressing, in a place on the app's path -
## innermost first, as a shortcut finds one (shortcuts.gd) - with the words
## the register gives it, pressed in that place. So the palette lists what
## the reader could press by hand from where they are, a button hidden in a
## tab they are not on is not in it, and an action that opens the palette
## itself never is. A row's press, which says which row, is not a command.
## THE REST IS HANDED IN: each source {kind, entries, picks} - a phrase for
## what sort of thing it holds, a bound value reading {value, words}, and the
## action a pick of one dispatches, {"value"}, from anywhere.
##
## A PICK IS THE PRESS IT STANDS FOR (relay.gd): refused as that press
## would be, the reason on the entry before it is ever picked; picked, the
## palette is lowered and the press sent. RUNS_FIRST - Enter in the line -
## is a pick of the first match, so a reader types and presses Enter.
## begin() empties the line, for the palette's place to call as it opens,
## and end() is called as it closes: CLOSED, IT OFFERS NOTHING. Each entry's
## refusal follows the press it stands for and where the reader is, and
## entries standing built in a hidden palette would be drawn again as those
## move for nobody; they are built as the palette opens.
##
## Deliberately absent: an order of its own - the commands first in the
## path's order, then each source's in its own - and remembering what was
## picked before.

## The palette's three: typing, {"line"}; a pick of one entry, {"value"};
## and a pick of the first match, {"line"}. Its way out is every pop-up's
## (describe_places.gd: CLOSES).
const TYPES := &"types_in_the_palette"
const PICKS := &"picks_from_the_palette"
const RUNS_FIRST := &"runs_the_first_found"
## What a command's value begins with.
const COMMAND := "command"

var _door: Object
var _open := value(false)  # whether the palette is up, between begin() and end(): closed, it offers nothing


## The palette's search, over the door, the driver and the register, and
## the sources handed in, so many shown at once.
func _init(chimes: Chimes, door: Object, driver: Driver, actions: Actions, sources: Array, limit: int = 12) -> void:
	super(chimes, _everything(driver, actions, sources), limit)
	_door = door


## An empty line, as the palette opens.
func begin() -> void:
	_open.set_value(true)
	told(TYPES, {"line": ""})


## The palette closed: it offers nothing until it opens again.
func end() -> void:
	_open.set_value(false)


## The matching entries, as many as are shown - none while the palette is
## closed, so no entry stands built to be drawn again as the screen moves.
func get_options() -> Array:
	return super() if _open.read() else []


func would(action: StringName, payload: Dictionary) -> Phrase:
	match action:
		PICKS:
			var picked: Variant = _picked(payload["value"])
			return Phrase.of("That is no longer there to pick") if picked == null else Relay.refusal(_door, picked)
		RUNS_FIRST:
			return Phrase.of("Nothing matches") if get_count() == 0 else Relay.refusal(_door, get_options()[0])
	return null


func told(action: StringName, payload: Dictionary) -> Phrase:
	match action:
		PICKS:
			return Relay.send(_door, _picked(payload["value"]))
		RUNS_FIRST:
			return Relay.send(_door, get_options()[0])
		TYPES:
			return super(action, payload)
	return null


## The entry matching now under this value, or none.
func _picked(value: Variant) -> Variant:
	# every entry matching now, for the one of this value
	for entry: Dictionary in _matching():
		if entry["value"] == value:
			return entry
	return null


## Everything the palette searches, bound: it reads where the reader is and every source, so it moves as any of them does.
static func _everything(driver: Driver, actions: Actions, sources: Array) -> Bound:
	return Bound.new(func() -> Array: return _commands(driver, actions) + _handed_in(sources))


## Every command on the app's path, innermost place first, each once.
static func _commands(driver: Driver, actions: Actions) -> Array:
	var found: Array = []
	var seen: Dictionary = {}
	var state: Dictionary = driver.get_state()
	var path: Array = state["path"]
	# the pop-up on top - the palette, while it is up - which a press opening it goes to; none while nothing is up
	var palette: StringName = state["overlays"].back()[0] if not state["overlays"].is_empty() else &""
	# every place on the app's path, innermost first
	for step: int in range(path.size() - 1, -1, -1):
		var place: Node = driver.index.place_named(path[step])
		# every action drawn under it with nothing to say, but one that opens the palette
		for action: StringName in _drawn_bare(driver.index, place, {}):
			if not seen.has(action) and place.performs.get(action, &"") != palette:
				seen[action] = true
				found.append({"value": "%s %s" % [COMMAND, action], "words": actions.get_words(action), "kind": Phrase.of("Command"), "action": action, "payload": {}, "region": place.name})
	return found


## Every action a control under this node draws with no payload, not one in a place within, as a set.
static func _drawn_bare(index: RefCounted, node: Node, into: Dictionary) -> Dictionary:
	# every child that is not a place of its own, itself or searched within
	for child: Node in node.get_children():
		if index.is_place(child):
			continue
		if child is ActionControl and (child as ActionControl).payload().is_empty():
			into[(child as ActionControl).action] = true
		_drawn_bare(index, child, into)
	return into


## Every entry of every source handed in, as the palette's entries.
static func _handed_in(sources: Array) -> Array:
	var found: Array = []
	# every source, in the order handed in
	for at: int in sources.size():
		var source: Dictionary = sources[at]
		# every entry of it, a pick of its value
		for entry: Dictionary in (source["entries"] as Bound).read():
			found.append({"value": "%d %s" % [at, entry["value"]], "words": entry["words"], "kind": source["kind"], "action": source["picks"], "payload": {"value": entry["value"]}, "region": Chimes.GLOBAL})
	return found
