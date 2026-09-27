extends RefCounted

## What is kept with each history entry: in-progress state under a name -
## a half-typed amount, where a list stood - so a detour and Back find it as
## it was left, and a fresh visit finds none.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## AN ENTRY IS ONE VISIT THE HISTORY HOLDS, known by the serial it was
## given as it was added (chart.gd), written as a string (entry_of): two
## visits to one view are two entries, each with its own, and a fresh visit
## finds nothing. Whatever keeps or reads here names the entry, so the entry
## being left can be written to before the state moves on, and the one
## arrived at read after. Whatever was kept with an entry the history no
## longer holds - gone Back past, dropped past the cap, forgotten - is let
## go as the state moves (let_go).
##
## A KEPT THING IS A RefCounted, freed by being let go. A Node would outlive
## its entry and leak, so it is refused out loud and not kept.
##
## It holds nothing of where the reader is, reads no tree and rings nothing:
## the driver hands it each state (driver.gd, whereabouts.gd).

var _kept: Dictionary = {}  # entry -> {name -> the thing kept with it}


## The entry the reader is on in this state: the newest's serial - nothing
## before the first arrival.
static func entry_of(state: Dictionary) -> String:
	return str(state["history_ids"].back()) if not state["history_ids"].is_empty() else ""


## A thing kept under a name with this entry: a RefCounted, and a Node
## refused out loud.
func keep(entry: String, name: StringName, thing: Object) -> void:
	if thing is Node:
		push_error("%s is a Node; a thing kept with the view is a RefCounted, freed as the entry goes" % name)
		return
	if not _kept.has(entry):
		_kept[entry] = {}
	_kept[entry][name] = thing


## What was kept under this name with this entry, or nothing.
func kept(entry: String, name: StringName) -> RefCounted:
	return (_kept.get(entry, {}) as Dictionary).get(name)


## Everything kept with an entry this state's history no longer holds, let go.
func let_go(state: Dictionary) -> void:
	# every entry the history holds, written as entry_of writes the one the reader is on
	var entries: Array = state["history_ids"].map(func(serial: int) -> String: return str(serial))
	# everything kept, let go where its entry is gone
	for entry: String in _kept.keys():
		if not entries.has(entry):
			_kept.erase(entry)
