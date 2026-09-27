extends RefCounted

const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Shown := preload("res://demo/gallery/shown.gd")
const Narrowing := preload("res://addons/gd_chime/narrowing.gd")

## The gallery's models for the second family of components: the stall's
## settings, its ledger as a sortable table and grouped sections, a picker
## over the crates, a knockout between them, and the takings as a chart.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.


## The stall's settings: a sound to turn, a pace to choose, a key to bind,
## a name to keep, and a saved day that can be thrown away.
class Prefs extends Shown:
	const TURNS_SOUND := &"turns_the_sound"
	const OPENS_PACES := &"opens_the_paces"
	const PICKS_PACE := &"picks_a_pace"
	const BINDS_CALL := &"binds_the_call_key"
	const NAMES_STALL := &"names_the_stall"
	const ASKS_TO_CLEAR := &"asks_to_clear_the_day"
	const CLEARS_DAY := &"clears_the_day"
	## Every action this is told: the two that only open a question are the places' moves.
	const COMMANDS: Array[StringName] = [TURNS_SOUND, PICKS_PACE, BINDS_CALL, NAMES_STALL, CLEARS_DAY]
	const PACE_WORDS := {&"slow": "Slow", &"steady": "Steady", &"brisk": "Brisk"}

	func _init(chimes: Chimes) -> void:
		# every pace an option: its name the value, its English beside it the words
		var options: Array = PACE_WORDS.keys().map(func(pace: StringName) -> Dictionary: return {"value": pace, "words": Phrase.of(PACE_WORDS[pace])})
		super(chimes, {&"sound": true, &"pace": &"steady", &"paces": options, &"call_key": "Space", &"title": "the corner stall", &"refusal": null, &"day": Phrase.of("A day of takings is kept")})

	func get_sound() -> bool:
		return facts[&"sound"]

	func get_pace() -> StringName:
		return facts[&"pace"]

	func get_paces() -> Array:
		return facts[&"paces"]

	func get_call_key() -> String:
		return facts[&"call_key"]

	func get_title() -> String:
		return facts[&"title"]

	func get_refusal() -> Phrase:
		return facts[&"refusal"]

	func get_day() -> Phrase:
		return facts[&"day"]

	func would(action: StringName, _payload: Dictionary) -> Phrase:
		if action == CLEARS_DAY and facts[&"day"] == null:
			return Phrase.of("There is no day kept to clear")
		return null

	func told(action: StringName, payload: Dictionary) -> Phrase:
		match action:
			TURNS_SOUND: facts[&"sound"] = payload["on"]
			PICKS_PACE: facts[&"pace"] = payload["value"]
			BINDS_CALL: facts[&"call_key"] = payload["words"]
			CLEARS_DAY: facts[&"day"] = null
			NAMES_STALL:
				# a name of nothing is refused in words, and the name held is left
				facts[&"refusal"] = Phrase.of("A stall needs a name") if String(payload["line"]).strip_edges() == "" else null
				if facts[&"refusal"] == null:
					facts[&"title"] = String(payload["line"]).strip_edges()
		moved()
		return null


	## Every action this model is told.
	func answers() -> Array[StringName]:
		return COMMANDS


## The crates as a ledger: a table sorted by a column, the same crates in
## groups by their complaints, and a picker narrowing over their names.
class Ledger extends Shown:
	const SORTS := &"sorts_the_ledger"
	const NARROWS_CRATES := &"narrows_the_crates"
	const PICKS_CRATE := &"picks_a_crate_by_name"
	## Every action this is told.
	const COMMANDS: Array[StringName] = [SORTS, NARROWS_CRATES, PICKS_CRATE]
	var narrowing: Narrowing
	var _things: Shown

	func _init(chimes: Chimes, things: Shown) -> void:
		super(chimes, {&"rows": [], &"sort": {"column": "name", "ascending": true}, &"sections": [], &"named": [], &"picked": Phrase.of("Nothing picked")})
		_things = things
		narrowing = Narrowing.new(chimes, Bound.new(get_named))

	func get_rows() -> Array:
		var rows: Array = _things.facts[&"things"].duplicate()
		var by: String = facts[&"sort"]["column"]
		var up: bool = facts[&"sort"]["ascending"]
		rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a[by] < b[by] if up else a[by] > b[by])
		return rows

	func get_sort() -> Dictionary:
		return facts[&"sort"]

	## The crates in groups by how many complaints each has had.
	func get_sections() -> Array:
		var groups: Array = []
		for marks: int in 3:
			groups.append({"id": marks, "heading": Phrase.of(["No complaints", "One complaint", "Two complaints"][marks]), "items": _things.facts[&"things"].filter(func(crate: Dictionary) -> bool: return crate["marks"] == marks)})
		return groups

	## Every crate as an option: its id the value, its name the words.
	func get_named() -> Array:
		return _things.facts[&"things"].map(func(crate: Dictionary) -> Dictionary: return {"value": crate["id"], "words": crate["name"]})

	func get_picked() -> Phrase:
		return facts[&"picked"]

	func told(action: StringName, payload: Dictionary) -> Phrase:
		match action:
			SORTS: facts[&"sort"] = {"column": payload["column"], "ascending": not facts[&"sort"]["ascending"] if facts[&"sort"]["column"] == payload["column"] else true}
			NARROWS_CRATES: return narrowing.told(action, payload)
			PICKS_CRATE: facts[&"picked"] = Phrase.with("Picked: crate %s", [payload["value"]])
		moved()
		return null


	## Every action this model is told.
	func answers() -> Array[StringName]:
		return COMMANDS


## A knockout between four crates: two ties feed a last one, decided in turn.
class Knockout extends Shown:
	const DECIDES := &"decides_the_next_tie"
	## The one action this is told.
	const COMMANDS: Array[StringName] = [DECIDES]

	func _init(chimes: Chimes) -> void:
		var pear := {"id": 1, "name": "pear"}
		var apple := {"id": 2, "name": "apple"}
		var fig := {"id": 3, "name": "fig"}
		var date := {"id": 4, "name": "date"}
		super(chimes, {&"rounds": [{"id": 1, "name": Phrase.of("First ties"), "ties": [{"id": 1, "a": pear, "b": apple, "winner": null}, {"id": 2, "a": fig, "b": date, "winner": null}]}, {"id": 2, "name": Phrase.of("Last tie"), "ties": [{"id": 3, "a": null, "b": null, "winner": null}]}]})

	func get_rounds() -> Array:
		return facts[&"rounds"]

	func would(action: StringName, _payload: Dictionary) -> Phrase:
		return Phrase.of("Every tie is decided") if action == DECIDES and _next() == null else null

	## The next tie with both its entrants and no winner, or none.
	func _next() -> Variant:
		for round: Dictionary in facts[&"rounds"]:
			for tie: Dictionary in round["ties"]:
				if tie["winner"] == null and tie["a"] != null and tie["b"] != null:
					return tie
		return null

	func told(_action: StringName, _payload: Dictionary) -> Phrase:
		var tie: Dictionary = _next()
		tie["winner"] = tie["a"]["id"]
		# a winner of a first tie takes its slot in the last
		var last: Dictionary = facts[&"rounds"][1]["ties"][0]
		if tie["id"] != last["id"]:
			last["a" if tie["id"] == 1 else "b"] = tie["a"]
		moved()
		return null


	## Every action this model is told.
	func answers() -> Array[StringName]:
		return COMMANDS


## The takings over the days, as two series a day can be added to.
class Takings extends Shown:
	const ADDS_DAY := &"adds_a_day"
	## The one action this is told.
	const COMMANDS: Array[StringName] = [ADDS_DAY]

	func _init(chimes: Chimes) -> void:
		super(chimes, {&"chart": {"series": [{"name": "pear", "points": [Vector2(1, 12), Vector2(2, 18), Vector2(3, 15), Vector2(4, 22)]}, {"name": "fig", "points": [Vector2(1, 30), Vector2(2, 24), Vector2(3, 28), Vector2(4, 26)]}], "x_words": Phrase.of("Day"), "y_words": Phrase.of("Takings, c")}})

	func get_chart() -> Dictionary:
		return facts[&"chart"]

	func told(_action: StringName, _payload: Dictionary) -> Phrase:
		for series: Dictionary in facts[&"chart"]["series"]:
			var last: Vector2 = series["points"].back()
			series["points"].append(Vector2(last.x + 1.0, last.y + (7.0 if int(last.x) % 2 == 0 else -4.0)))
		moved()
		return null


	## Every action this model is told.
	func answers() -> Array[StringName]:
		return COMMANDS


## The days kept: a list of them, each one thrown away by its id - through
## the one question every row shares.
class Kept extends Shown:
	const ASKS_TO_DROP := &"asks_to_drop_a_day"
	const DROPS := &"drops_a_kept_day"
	## The one action this is told: asking is the question's own move.
	const COMMANDS: Array[StringName] = [DROPS]

	func _init(chimes: Chimes) -> void:
		super(chimes, {&"days": [{"id": 1, "name": "market monday"}, {"id": 2, "name": "quiet tuesday"}, {"id": 3, "name": "fair day"}]})

	func get_days() -> Array:
		return facts[&"days"]

	## The name of the day of this id, for the question to say.
	func name_of(id: Variant) -> String:
		var found: Array = facts[&"days"].filter(func(day: Dictionary) -> bool: return day["id"] == id)
		return "" if found.is_empty() else found[0]["name"]

	func told(_action: StringName, payload: Dictionary) -> Phrase:
		facts[&"days"] = facts[&"days"].filter(func(day: Dictionary) -> bool: return day["id"] != payload["id"])
		moved()
		return null

	## Every action this model is told.
	func answers() -> Array[StringName]:
		return COMMANDS
