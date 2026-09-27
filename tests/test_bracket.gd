extends SceneTree

## What must be true of the bracket: a column per round in order, a cell
## per tie, both entrants links to their place, the winner marked in
## words, an undecided slot saying so, and a result arriving updating the
## very cell that was showing the pairing.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_bracket.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Each := preload("res://addons/gd_chime/components/primitives/each.gd")
const Bracket := preload("res://addons/gd_chime/components/recipes/bracket.gd")
const Verdict := preload("res://tests/verdict.gd")

var _verdict := Verdict.new()


## A tree of rounds and their ties.
class Knockout extends Fixture.Model:
	func get_rounds() -> Variant:
		return of(&"rounds").read()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(600, 600)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_a_bracket_is_a_column_per_round_of_cells_whose_entrants_link_to_their_place)
	await _verdict.states(_a_result_arriving_marks_the_winner_and_fills_the_next_round_in_the_same_cells)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


func _texts(node: Node) -> Array[String]:
	var found: Array[String] = []
	for child: Node in node.get_children():
		if child is Text and (child as Text).get_text() != "":
			found.append((child as Text).get_text())
		found.append_array(_texts(child))
	return found


func _pressables(node: Node) -> Array:
	return node.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable)


func _eaches(node: Node) -> Array:
	return node.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Each)


## The tree as it stands before any result: the first round paired, the
## last round waiting on both of them.
func _a_knockout() -> Array:
	return [
		{"id": 10, "name": "first round", "ties": [
			{"id": 1, "a": {"id": 1, "name": "ann"}, "b": {"id": 2, "name": "bo"}, "winner": null},
			{"id": 2, "a": {"id": 3, "name": "cy"}, "b": {"id": 4, "name": "di"}, "winner": 3},
		]},
		{"id": 20, "name": "last round", "ties": [
			{"id": 3, "a": null, "b": {"id": 3, "name": "cy"}, "winner": null},
		]},
	]


func _built(made: Fixture) -> Knockout:
	var model := Knockout.new(made.chimes, &"app")
	model.set_value(&"rounds", _a_knockout())
	made.commands.register(&"app", &"opens", model)
	made.ui.start(made.ui.app(&"app", [made.ui.column([
		Bracket.make(made.ui, Bound.new(model.get_rounds), &"opens", {goes_to = &"entrant"}).named(&"bracket"),
		made.ui.stack([made.ui.screen(&"entrant", [])]),
	])]))
	return model


func _a_bracket_is_a_column_per_round_of_cells_whose_entrants_link_to_their_place() -> void:
	var made := Fixture.new(root, {&"opens": "open"})
	var ui := made.ui
	var model := _built(made)
	await _a_frame_passes()
	var bracket: Node = ui.node_named(&"bracket")
	var rounds: Each = _eaches(bracket)[0]
	var first: Node = rounds.piece_for(10)
	var last: Node = rounds.piece_for(20)
	_verdict.check(rounds.get_count() == 2 and first.get_index() < last.get_index() and _texts(first)[0] == "first round" and _texts(last)[0] == "last round", "a column per round, in the model's order, each under its name: %s" % [_texts(bracket)])
	var ties: Each = _eaches(first)[0]
	_verdict.check(ties.get_count() == 2 and _eaches(last)[0].get_count() == 1, "a cell per tie of that round: %d then %d" % [ties.get_count(), _eaches(last)[0].get_count()])
	var pairing: Node = ties.piece_for(1)
	var links := _pressables(pairing)
	_verdict.check(links.size() == 2 and _texts(pairing) == ["ann", "bo"] and (links[0] as Pressable).payload() == {"parameter": 1} and (links[1] as Pressable).payload() == {"parameter": 2}, "both entrants are links carrying their own ids: %s" % [[(links[0] as Pressable).payload(), (links[1] as Pressable).payload()]])
	(links[1] as Pressable).pressed()
	await _a_frame_passes()
	_verdict.check(made.driver.get_top() == [&"app", &"entrant"] and made.driver.get_parameter(&"entrant") == 2, "pressed, the entrant's place is entered as that entrant: %s" % [made.driver.get_parameter(&"entrant")])
	_verdict.check(_texts(ties.piece_for(2)) == ["cy", Bracket.WON, "di"], "the winner is marked in words beside the name, and the loser is not: %s" % [_texts(ties.piece_for(2))])
	var waiting: Node = _eaches(last)[0].piece_for(3)
	_verdict.check(_texts(waiting) == [Bracket.UNDECIDED, "cy"] and _pressables(waiting).size() == 1, "a slot nobody has reached yet says so and offers no link: %s" % [_texts(waiting)])
	model.free()
	made.done()


func _a_result_arriving_marks_the_winner_and_fills_the_next_round_in_the_same_cells() -> void:
	var made := Fixture.new(root, {&"opens": "open"})
	var ui := made.ui
	var model := _built(made)
	await _a_frame_passes()
	var rounds: Each = _eaches(ui.node_named(&"bracket"))[0]
	var decided: Node = _eaches(rounds.piece_for(10))[0].piece_for(1)
	var final_tie: Node = _eaches(rounds.piece_for(20))[0].piece_for(3)
	var after := _a_knockout()
	after[0]["ties"][0]["winner"] = 1
	after[1]["ties"][0]["a"] = {"id": 1, "name": "ann"}
	model.set_value(&"rounds", after)
	await _a_frame_passes()
	_verdict.check(_eaches(rounds.piece_for(10))[0].piece_for(1) == decided and _texts(decided) == ["ann", Bracket.WON, "bo"], "the result marks the winner in the very cell that was showing the pairing: %s" % [_texts(decided)])
	var filled: Node = _eaches(rounds.piece_for(20))[0].piece_for(3)
	var links := _pressables(filled)
	_verdict.check(filled == final_tie and _texts(filled) == ["ann", "cy"] and links.size() == 2 and (links[0] as Pressable).payload() == {"parameter": 1}, "and fills the next round's slot in place, a link now where the placeholder was: %s" % [_texts(filled)])
	model.free()
	made.done()
