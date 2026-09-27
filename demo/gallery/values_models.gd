extends RefCounted

const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Shown := preload("res://demo/gallery/shown.gd")
const Narrowing := preload("res://addons/gd_chime/narrowing.gd")

## The gallery's model for the controls that set a value (values_pieces.gd):
## one order of crates - how many, how full, what size and which fruit.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Every one of them is set by an action carrying {"value"}, the payload a
## slider, a stepper, a choice and a radio group all carry, so this one
## model answers them all; and each refuses one thing, in words, so every
## control is seen refused by the door: thirteen crates, a crate filled past
## eight tenths, and a large crate. The fruit is picked from a list too long
## to walk, narrowed by typing (narrowing.gd), which answers its own typing.


## One order of crates.
class Order extends Shown:
	const SETS_CRATES := &"sets_the_crates"
	const SETS_FILL := &"sets_the_fill"
	const PICKS_SIZE := &"picks_a_size"
	const PICKS_FRUIT := &"picks_a_fruit"
	const TYPES_FRUIT := &"types_a_fruit"
	## Every action this is told: the typing is its narrowing's.
	const COMMANDS: Array[StringName] = [SETS_CRATES, SETS_FILL, PICKS_SIZE, PICKS_FRUIT]
	## The one number of crates the stall refuses, and the most a crate is filled.
	const UNLUCKY := 13.0
	const FULLEST := 0.8
	## The one size there is none of today.
	const NONE_LEFT := &"large"
	const FRUIT := ["pear", "apple", "fig", "date", "plum", "lime", "kiwi", "quince", "grape", "melon", "cherry", "lemon"]
	## The fact each action sets.
	const SET_BY := {SETS_CRATES: &"crates", SETS_FILL: &"fill", PICKS_SIZE: &"size", PICKS_FRUIT: &"fruit"}
	## The order as it is to begin with, by the action that sets each, for the probe to put it back.
	const FIRST := {SETS_CRATES: 12.0, SETS_FILL: 0.5, PICKS_SIZE: &"small", PICKS_FRUIT: "fig"}
	## The fruit's own narrowing, answering the typing.
	var narrowing: Narrowing

	func _init(chimes: Chimes) -> void:
		var sizes := [{"value": &"small", "words": Phrase.of("Small")}, {"value": &"middling", "words": Phrase.of("Middling")}, {"value": &"large", "words": Phrase.of("Large")}]
		# every fruit as an option, its name its words: data, never translated
		var fruits := FRUIT.map(func(fruit: String) -> Dictionary: return {"value": fruit, "words": fruit})
		super(chimes, {&"sizes": sizes, &"fruits": fruits})
		# every fact as it is to begin with
		for action: StringName in FIRST:
			facts[SET_BY[action]] = FIRST[action]
		narrowing = Narrowing.new(chimes, Bound.new(get_fruits), 8, TYPES_FRUIT)

	func get_crates() -> float:
		return facts[&"crates"]

	func get_fill() -> float:
		return facts[&"fill"]

	func get_size() -> StringName:
		return facts[&"size"]

	func get_fruit() -> String:
		return facts[&"fruit"]

	func get_sizes() -> Array:
		return facts[&"sizes"]

	func get_fruits() -> Array:
		return facts[&"fruits"]

	## The refused value of each: a pick with no value - an option not yet
	## laid out - refuses nothing.
	func would(action: StringName, payload: Dictionary) -> Phrase:
		var value: Variant = payload.get("value")
		if action == SETS_CRATES and value == UNLUCKY:
			return Phrase.of("The stall never stacks thirteen crates")
		if action == SETS_FILL and value > FULLEST + 0.001:
			return Phrase.of("Filled past eight tenths, a crate splits")
		if action == PICKS_SIZE and value == NONE_LEFT:
			return Phrase.of("No large crates today")
		return null

	func told(action: StringName, payload: Dictionary) -> Phrase:
		facts[SET_BY[action]] = payload["value"]
		moved()
		return null

	## Every action this model is told.
	func answers() -> Array[StringName]:
		return COMMANDS
