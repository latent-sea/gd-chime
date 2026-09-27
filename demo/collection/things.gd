extends "res://addons/gd_chime/controller.gd"

## The collection demo's model: a list of things that starts empty, added
## to, sorted, filtered, flipped one at a time, and one of them picked.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Every rule is a refusal here and every change a command; the screen only
## binds. A thing is {id, name, flipped}; the things read are the ones the
## filter lets through, in the order the sort says, and each keeps its id
## whatever its place in the list.

const ADDS := &"adds_three_things"
const SORTS := &"sorts_by_name"
const SHOWS_ONLY_FLIPPED := &"shows_only_the_flipped"
const FLIPS := &"flips_a_thing"
const OPENS := &"opens_a_thing"
const RETURNS := &"returns_to_the_list"
## What each action does, said once.
const ACTIONS := {ADDS: ["Add three things"], SORTS: ["Sort by name"], SHOWS_ONLY_FLIPPED: ["Show only the flipped"], FLIPS: ["Flip"], OPENS: ["Open"], RETURNS: ["Back to the list"]}
const NAMES := ["pear", "apple", "fig", "date", "plum", "lime"]

var _things := value([])
var _sorted := value(false)
var _filtered := value(false)
var _picked := value(-1)


func _init(chimes: Chimes) -> void:
	super(chimes, [], &"things")


## The things as shown: filtered to the flipped if asked, by name if asked.
func get_things() -> Array[Dictionary]:
	var shown: Array[Dictionary] = []
	for thing: Dictionary in _things.read():
		if not _filtered.read() or thing["flipped"]:
			shown.append(thing)
	if _sorted.read():
		shown.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["name"] < b["name"])
	return shown


## The thing picked, or nothing.
func get_picked() -> Variant:
	for thing: Dictionary in _things.read():
		if thing["id"] == _picked.read():
			return thing
	return null


## Sorting and filtering nothing, and adding past the names there are, are refused.
func would(action: StringName, _payload: Dictionary) -> Phrase:
	if (action == SORTS or action == SHOWS_ONLY_FLIPPED) and _things.read().is_empty():
		return Phrase.of("Nothing to sort yet") if action == SORTS else Phrase.of("Nothing to filter yet")
	if action == ADDS and _things.read().size() >= NAMES.size():
		return Phrase.of("Every thing there is has been added")
	return null


func told(action: StringName, payload: Dictionary) -> Phrase:
	match action:
		ADDS:
			# three more, each named in turn and numbered for life
			for count: int in 3:
				_things.read().append({"id": _things.read().size() + 1, "name": NAMES[_things.read().size()], "flipped": false})
		SORTS: _sorted.set_value(not _sorted.read())
		SHOWS_ONLY_FLIPPED: _filtered.set_value(not _filtered.read())
		FLIPS:
			for thing: Dictionary in _things.read():
				if thing["id"] == payload["id"]:
					thing["flipped"] = not thing["flipped"]
		OPENS:
			_picked.set_value(payload["id"])
	# the things, changed in place, set again for whatever reads them
	_things.set_value(_things.read())
	return null
