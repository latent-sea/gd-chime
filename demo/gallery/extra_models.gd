extends RefCounted

const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Shown := preload("res://demo/gallery/shown.gd")
const Inputs := preload("res://addons/gd_chime/input_map.gd")

## The gallery's own models, for the three screens the gallery shows and no
## other stall does (extra_pieces.gd): a shelf of crates for the motion tab,
## the keys kept on disk for the options tab, and two baskets a crate is
## carried to.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Nothing here moves or draws: a model holds the facts a motion is SEEN in
## - a crate put on, taken off, the shelf turned round, a crate ripe, how
## full it is - and the motion is the floor's, the one clock's, the look's.
## What goes to disk is the keys alone, and what comes back off it is not
## ours, so it is read with care and a failure said in words.


## A shelf of crates, for the motion tab: crates put on, taken off and the
## shelf turned round - a list entering, leaving and moving - one crate
## ripe or not - a style blending - and how full it is, a number going
## smoothly where it is sent.
class Shelf extends Shown:
	const PUTS_ON_SHELF := &"puts_a_crate_on_the_shelf"
	const TAKES := &"takes_a_crate_off_the_shelf"
	const TURNS := &"turns_the_shelf_round"
	const RIPENS := &"ripens_the_crate"
	const FILLS := &"fills_the_crate"
	## Every action this is told.
	const COMMANDS: Array[StringName] = [PUTS_ON_SHELF, TAKES, TURNS, RIPENS, FILLS]
	## The three a key or a pad button presses, as the settings rebind them.
	const KEYED: Array[StringName] = [PUTS_ON_SHELF, TAKES, TURNS]
	const NAMES := ["pear", "apple", "fig", "date", "plum", "lime"]
	## How full the crate is, the two ways a press sends it.
	const LOW := 20.0
	const HIGH := 90.0

	func _init(chimes: Chimes) -> void:
		super(chimes, {&"crates": [{"id": 1, "name": "pear"}, {"id": 2, "name": "apple"}, {"id": 3, "name": "fig"}], &"ripe": false, &"fill": LOW})

	func get_crates() -> Array:
		return facts[&"crates"]

	func get_ripe() -> bool:
		return facts[&"ripe"]

	func get_fill() -> float:
		return facts[&"fill"]

	func would(action: StringName, _payload: Dictionary) -> Phrase:
		var count: int = facts[&"crates"].size()
		if action == PUTS_ON_SHELF and count == NAMES.size():
			return Phrase.of("The shelf is full")
		if action == TAKES and count == 0:
			return Phrase.of("The shelf is empty")
		if action == TURNS and count < 2:
			return Phrase.of("It takes two crates to turn the shelf round")
		return null

	func told(action: StringName, payload: Dictionary) -> Phrase:
		var crates: Array = facts[&"crates"]
		match action:
			PUTS_ON_SHELF:
				var on: Array = crates.map(func(crate: Dictionary) -> String: return crate["name"])
				var name: String = NAMES.filter(func(one: String) -> bool: return not on.has(one))[0]
				crates.append({"id": NAMES.find(name) + 1, "name": name})
			TAKES: crates.pop_front()
			TURNS: crates.reverse()
			RIPENS: facts[&"ripe"] = payload["on"]
			FILLS: facts[&"fill"] = HIGH if facts[&"fill"] == LOW else LOW
		moved()
		return null


	## Every action this model is told.
	func answers() -> Array[StringName]:
		return COMMANDS


## The keys as the reader has bound them, kept in a file of the reader's own
## and read back from it. What is kept is the map's plain data (saved_inputs.gd).
class Keys extends Shown:
	const SAVES := &"saves_the_keys"
	const LOADS := &"loads_the_keys"
	## Every action this is told.
	const COMMANDS: Array[StringName] = [SAVES, LOADS]
	const FILE := "user://gallery_keys.json"
	var _inputs: Inputs

	func _init(chimes: Chimes, inputs: Inputs) -> void:
		super(chimes, {&"said": Phrase.of("Nothing saved or loaded yet")})
		_inputs = inputs

	func get_said() -> Phrase:
		return facts[&"said"]

	func would(action: StringName, _payload: Dictionary) -> Phrase:
		if action == LOADS and not FileAccess.file_exists(FILE):
			return Phrase.of("Nothing has been saved yet")
		return null

	func told(action: StringName, _payload: Dictionary) -> Phrase:
		if action == SAVES:
			var file := FileAccess.open(FILE, FileAccess.WRITE)
			# a disk refusing to be written is the machine's answer, said as it gave it
			if file == null:
				facts[&"said"] = Phrase.with("The keys could not be saved: %s", [error_string(FileAccess.get_open_error())])
			else:
				file.store_string(JSON.stringify(_inputs.saved()))
				facts[&"said"] = Phrase.of("The keys are saved")
		else:
			var read: Variant = JSON.parse_string(FileAccess.get_file_as_string(FILE))
			# what comes off the disk may be anything: only a dictionary is handed to the map, which checks the rest
			if read is Dictionary:
				_inputs.restore(read)
				facts[&"said"] = Phrase.of("The saved keys are loaded")
			else:
				facts[&"said"] = Phrase.of("What was saved is not a set of keys")
		moved()
		return null


	## Every action this model is told.
	func answers() -> Array[StringName]:
		return COMMANDS


## Crates on the counter, and two baskets to carry them to: one takes any
## crate, and one takes figs alone and says so of anything else.
class Baskets extends Shown:
	const PUTS_IN := &"puts_a_crate_in_the_basket"
	const PUTS_IN_FIGS := &"puts_a_crate_in_the_fig_basket"
	const EMPTIES := &"empties_the_baskets"
	## Every action this is told.
	const COMMANDS: Array[StringName] = [PUTS_IN, PUTS_IN_FIGS, EMPTIES]
	const FIG := "fig"
	## Every crate there is, on the counter to begin with.
	const CRATES := [{"id": 1, "name": "pear"}, {"id": 2, "name": "fig"}, {"id": 3, "name": "apple"}]

	func _init(chimes: Chimes) -> void:
		super(chimes, {&"counter": CRATES.duplicate(true), &"basket": [], &"figs": []})

	func get_counter() -> Array:
		return facts[&"counter"]

	func get_basket() -> Array:
		return facts[&"basket"]

	func get_figs() -> Array:
		return facts[&"figs"]

	## The fig basket refuses what is no fig - asked of whatever is carried
	## over it, which is nothing while nothing is.
	func would(action: StringName, payload: Dictionary) -> Phrase:
		# the crate carried, by its id: none while nothing is carried
		var carried: Array = facts[&"counter"].filter(func(crate: Dictionary) -> bool: return crate["id"] == payload.get("id"))
		if action == PUTS_IN_FIGS and (carried.is_empty() or carried[0]["name"] != FIG):
			return Phrase.of("Only figs go in the fig basket")
		if action == EMPTIES and facts[&"basket"].is_empty() and facts[&"figs"].is_empty():
			return Phrase.of("The baskets are empty")
		return null

	func told(action: StringName, payload: Dictionary) -> Phrase:
		if action == EMPTIES:
			facts[&"counter"] = CRATES.duplicate(true)
			facts[&"basket"] = []
			facts[&"figs"] = []
		else:
			var moved: Dictionary = facts[&"counter"].filter(func(crate: Dictionary) -> bool: return crate["id"] == payload["id"])[0]
			facts[&"counter"].erase(moved)
			facts[&"basket" if action == PUTS_IN else &"figs"].append(moved)
		moved()
		return null

	## Every action this model is told.
	func answers() -> Array[StringName]:
		return COMMANDS
