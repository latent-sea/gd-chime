extends RefCounted

const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Shown := preload("res://demo/gallery/shown.gd")

## The gallery's model for its chips (marks_pieces.gd): the labels on a
## crate, each on or off, two of them removable and one that stays.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A chip holds nothing: whether it is on, and whether it is there at all, is
## this model's, told by the chip's two presses through the door. Putting the
## labels back is refused, in words, while none is missing - so its button
## says so on its face.


## The labels on a crate.
class Labels extends Shown:
	const TOGGLES := &"toggles_a_label"
	const REMOVES := &"removes_a_label"
	const PUTS_LABELS_BACK := &"puts_the_labels_back"
	## Every action this is told.
	const COMMANDS: Array[StringName] = [TOGGLES, REMOVES, PUTS_LABELS_BACK]
	## The one label that cannot be taken off, by its id.
	const FRESH := 0

	func _init(chimes: Chimes) -> void:
		super(chimes, {&"labels": _first(), &"fresh": true})

	func get_labels() -> Array:
		return facts[&"labels"]

	func get_fresh() -> bool:
		return facts[&"fresh"]

	func would(action: StringName, _payload: Dictionary) -> Phrase:
		if action == PUTS_LABELS_BACK and facts[&"labels"].size() == _first().size():
			return Phrase.of("Every label is on the crate")
		return null

	func told(action: StringName, payload: Dictionary) -> Phrase:
		match action:
			TOGGLES when payload["id"] == FRESH: facts[&"fresh"] = not facts[&"fresh"]
			# the label pressed turned the other way, every other as it was
			TOGGLES: facts[&"labels"] = facts[&"labels"].map(func(one: Dictionary) -> Dictionary: return one.merged({"on": not one["on"]}, true) if one["id"] == payload["id"] else one)
			REMOVES: facts[&"labels"] = facts[&"labels"].filter(func(one: Dictionary) -> bool: return one["id"] != payload["id"])
			PUTS_LABELS_BACK: facts[&"labels"] = _first()
		moved()
		return null

	## The labels a crate has to begin with, one on and one off.
	static func _first() -> Array:
		return [{"id": 1, "words": Phrase.of("Ripe"), "on": true}, {"id": 2, "words": Phrase.of("Bruised"), "on": false}]

	## Every action this model is told.
	func answers() -> Array[StringName]:
		return COMMANDS
