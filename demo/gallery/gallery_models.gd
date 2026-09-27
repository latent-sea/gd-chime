extends RefCounted

const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Shown := preload("res://demo/gallery/shown.gd")
const Filters := preload("res://demo/gallery/filters.gd")

## The gallery's models: one small model per component shown, each holding
## the facts the component reads and answering the commands it presses,
## with a refusal where a state is a refusal.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.

## The things the collection, the board and the matrix show.
class Things extends Shown:
	const ADDS := &"adds_a_thing"
	const SORTS := &"sorts_the_things"
	const OPENS := &"opens_a_thing"
	const COMPARES := &"compares_with"
	## Every action this is told: opening a crate is the place's move, told to nobody.
	const COMMANDS: Array[StringName] = [ADDS, SORTS, COMPARES]
	const NAMES := ["pear", "apple", "fig", "date", "plum", "lime", "kiwi", "yuzu"]

	func _init(chimes: Chimes) -> void:
		super(chimes, {&"things": [], &"own": 3, &"sorted": false})
		for count: int in 6:
			facts[&"things"].append({"id": count + 1, "name": NAMES[count], "won": (count + 1) * 1700, "recent": [count, count + 2, count + 1, count + 3], "marks": count % 3})

	func get_things() -> Array:
		var shown: Array = facts[&"things"].duplicate()
		if facts[&"sorted"]:
			shown.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["name"] < b["name"])
		return shown

	func get_own() -> Variant:
		return facts[&"own"]

	func get_sorted() -> bool:
		return facts[&"sorted"]

	func would(action: StringName, _payload: Dictionary) -> Phrase:
		if action == ADDS and facts[&"things"].size() >= NAMES.size():
			return Phrase.of("Every thing there is has been added")
		return null

	func told(action: StringName, _payload: Dictionary) -> Phrase:
		match action:
			ADDS:
				var count: int = facts[&"things"].size()
				facts[&"things"].append({"id": count + 1, "name": NAMES[count], "won": (count + 1) * 1700, "recent": [1, 2, 3], "marks": 1})
			SORTS: facts[&"sorted"] = not facts[&"sorted"]
		moved()
		return null


	## Every action this model is told.
	func answers() -> Array[StringName]:
		return COMMANDS


## An act in progress, for the instruction bar and the moment.
class Act extends Shown:
	const STARTS := &"starts_the_act"
	const TAKES_A_STEP := &"takes_a_step"
	const CANCELS := &"cancels_the_act"
	const CARRIES_ON := &"carries_on"
	## Every action this is told.
	const COMMANDS: Array[StringName] = [STARTS, TAKES_A_STEP, CANCELS, CARRIES_ON]

	func _init(chimes: Chimes) -> void:
		super(chimes, {&"asking": false, &"words": null, &"progress": null, &"presented": false})

	func get_asking() -> bool:
		return facts[&"asking"]

	func get_words() -> Phrase:
		return facts[&"words"]

	func get_progress() -> Variant:
		return facts[&"progress"]

	func get_presented() -> bool:
		return facts[&"presented"]

	func would(action: StringName, _payload: Dictionary) -> Phrase:
		if action == TAKES_A_STEP and not facts[&"asking"]:
			return Phrase.of("Nothing is being asked")
		return null

	func told(action: StringName, _payload: Dictionary) -> Phrase:
		match action:
			STARTS:
				facts[&"asking"] = true
				facts[&"words"] = Phrase.of("Pick three crates to restock")
				facts[&"progress"] = {"count": 0, "ceiling": 3}
			TAKES_A_STEP:
				facts[&"progress"]["count"] += 1
				facts[&"words"] = Phrase.of(["Pick three crates to restock", "One picked, pick two more", "Two picked, pick one more"][facts[&"progress"]["count"] % 3])
				if facts[&"progress"]["count"] == 3:
					facts[&"asking"] = false
					facts[&"words"] = Phrase.of("Restocked: three crates picked")
					facts[&"progress"] = null
					facts[&"presented"] = true
			CANCELS:
				facts[&"asking"] = false
				facts[&"words"] = null
				facts[&"progress"] = null
			CARRIES_ON: facts[&"presented"] = false
		moved()
		return null


	## Every action this model is told.
	func answers() -> Array[StringName]:
		return COMMANDS


## An item with a disposition.
class Item extends Shown:
	const ENTERS := &"enters_this_cycle"
	const LISTS := &"lists_this_cycle"
	const RELEASES := &"releases_this_cycle"
	const SETS_PRICE := &"sets_the_price"
	## Every action this is told.
	const COMMANDS: Array[StringName] = [ENTERS, LISTS, RELEASES, SETS_PRICE]

	func _init(chimes: Chimes) -> void:
		super(chimes, {&"chosen": null, &"satisfied": true, &"price": ""})
		refusals[LISTS] = Phrase.of("Not in the market phase")

	func get_chosen() -> Variant:
		return facts[&"chosen"]

	func get_satisfied() -> bool:
		return facts[&"satisfied"]

	func get_price() -> String:
		return facts[&"price"]

	func told(action: StringName, payload: Dictionary) -> Phrase:
		match action:
			SETS_PRICE:
				facts[&"price"] = payload["line"]
				facts[&"satisfied"] = true
			_:
				facts[&"chosen"] = action
				facts[&"satisfied"] = action == RELEASES
		moved()
		return null


	## Every action this model is told.
	func answers() -> Array[StringName]:
		return COMMANDS


## A picture of a family, for the graph.
class Family extends Shown:
	const PANS := &"pans_the_graph"
	const ZOOMS := &"zooms_the_graph"
	const PICKS := &"picks_an_individual"
	const ZOOMS_IN := &"zooms_in"
	const ZOOMS_OUT := &"zooms_out"
	const EXPANDS := &"expands_a_supplier"
	const OPENS := &"opens_a_supplier_s_crate"
	## Every action this is told.
	const COMMANDS: Array[StringName] = [PANS, ZOOMS, PICKS, ZOOMS_IN, ZOOMS_OUT, EXPANDS, OPENS]
	## Who each supplier deals with besides, loaded only when asked for.
	const WIDER := {1: ["ann's grower", "ann's carter"], 2: ["bo's orchard"], 3: ["cy's cousin", "cy's packer"], 4: ["dee's dairy"]}

	func _init(chimes: Chimes) -> void:
		super(chimes, {&"selected": null, &"picture": {"nodes": [{"id": 1, "name": "ann", "at": Vector2(-120, -40)}, {"id": 2, "name": "bo", "at": Vector2(40, -60)}, {"id": 3, "name": "cy", "at": Vector2(-30, 70)}, {"id": 4, "name": "dee", "at": Vector2(160, 90)}], "links": [{"a": 1, "b": 2, "strength": 0.9}, {"a": 2, "b": 3, "strength": 0.5}, {"a": 1, "b": 3, "strength": 0.3}], "view": {"centre": Vector2.ZERO, "scale": 1.0}, "radius": 14.0, "size": Vector2(400, 400)}, &"picked": null})

	func get_picture() -> Dictionary:
		return facts[&"picture"]

	func get_picked() -> Variant:
		return facts[&"picked"]

	func get_selected() -> Variant:
		return facts[&"selected"]

	func would(action: StringName, _payload: Dictionary) -> Phrase:
		var scale: float = facts[&"picture"]["view"]["scale"]
		if action == ZOOMS_IN and scale >= 4.0:
			return Phrase.of("As close as it goes")
		if action == ZOOMS_OUT and scale <= 0.25:
			return Phrase.of("As far as it goes")
		if action == EXPANDS and _payload["id"] != null and not WIDER.has(_payload["id"]):
			return Phrase.of("Nobody further is known")
		return null

	func told(action: StringName, payload: Dictionary) -> Phrase:
		var view: Dictionary = facts[&"picture"]["view"]
		match action:
			PANS: view["centre"] -= payload["by"] / view["scale"]
			ZOOMS: view["scale"] = clampf(view["scale"] * (1.25 if payload["steps"] > 0 else 0.8), 0.25, 4.0)
			ZOOMS_IN: view["scale"] = minf(view["scale"] * 1.25, 4.0)
			ZOOMS_OUT: view["scale"] = maxf(view["scale"] * 0.8, 0.25)
			PICKS:
				facts[&"selected"] = facts[&"picture"]["nodes"].filter(func(node: Dictionary) -> bool: return node["id"] == payload["picked"])[0]
				facts[&"picked"] = facts[&"selected"]["name"]
			EXPANDS: _load_wider(payload["id"])
		moved()
		return null

	## The wider family of one supplier, loaded into the picture around it, once.
	func _load_wider(id: int) -> void:
		var nodes: Array = facts[&"picture"]["nodes"]
		var around: Dictionary = nodes.filter(func(node: Dictionary) -> bool: return node["id"] == id)[0]
		# every further name of this supplier, a new node on a ring around it with a link to it
		for index: int in WIDER[id].size():
			var further: int = id * 100 + index
			if nodes.any(func(node: Dictionary) -> bool: return node["id"] == further):
				continue
			nodes.append({"id": further, "name": WIDER[id][index], "at": around["at"] + Vector2(70, 0).rotated(1.0 + index * 1.4)})
			facts[&"picture"]["links"].append({"a": id, "b": further, "strength": 0.4})

	## Every action this model is told.
	func answers() -> Array[StringName]:
		return COMMANDS
