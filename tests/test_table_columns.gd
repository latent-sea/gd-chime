extends SceneTree

## What must be true of a table's columns: the shares shown always make the
## whole; a resize moves one edge, the column beyond giving what the column
## gains and neither going below the least; the last column has no edge; a
## grip asking at rest, with no move, is refused only where neither side can
## give; a
## column hidden gives its share to the rest in proportion and never the
## last shown.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_table_columns.gd

const Fixture := preload("res://tests/fixture.gd")
const TableColumns := preload("res://addons/gd_chime/table_columns.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Verdict := preload("res://tests/verdict.gd")

const REGION := &"pipes"
const LEAST := 0.05

var _verdict := Verdict.new()


func _init() -> void:
	await _verdict.states(_a_resize_moves_one_edge_and_stops_at_the_least)
	await _verdict.states(_a_column_hidden_gives_its_share_to_the_rest)
	quit(_verdict.deliver(get_script()))


func _made(made: Fixture) -> TableColumns:
	var columns := [{"name": &"id", "words": Phrase.of("asset"), "share": 0.2}, {"name": &"road", "words": Phrase.of("road"), "share": 0.4}, {"name": &"town", "words": Phrase.of("town"), "share": 0.2}, {"name": &"risk", "words": Phrase.of("risk"), "share": 0.2}]
	var model := TableColumns.new(made.chimes, columns, LEAST)
	made.commands.stand(REGION, model)
	root.add_child(model)
	return model


func _shares(model: TableColumns) -> Array:
	return model.get_shown().map(func(column: Dictionary) -> float: return snappedf(column["share"], 0.0001))


## Whether two lists of shares agree to a ten-thousandth.
func _near(shares: Array, expected: Array) -> bool:
	return shares.size() == expected.size() and range(shares.size()).all(func(at: int) -> bool: return absf(shares[at] - expected[at]) < 0.0001)


func _a_resize_moves_one_edge_and_stops_at_the_least() -> void:
	var made := Fixture.new(root)
	var model := _made(made)
	made.commands.dispatch(REGION, TableColumns.RESIZES, {"column": &"id", "by": 0.1})
	_verdict.check(_near(_shares(model), [0.3, 0.3, 0.2, 0.2]), "the edge right of asset moved: asset gains, road gives, the rest stand: %s" % [_shares(model)])
	made.commands.dispatch(REGION, TableColumns.RESIZES, {"column": &"road", "by": -0.9})
	_verdict.check(_near(_shares(model), [0.3, LEAST, 0.45, 0.2]), "narrowed far past the least, road stops at it and town takes the rest: %s" % [_shares(model)])
	var further := made.commands.dispatch(REGION, TableColumns.RESIZES, {"column": &"road", "by": -0.01})
	var last := made.commands.dispatch(REGION, TableColumns.RESIZES, {"column": &"risk", "by": 0.01})
	_verdict.check(str(further) == "As narrow as a column goes" and str(last) == "The last column has no edge to move", "at the least a further narrowing is refused, and so is the last column's edge: %s / %s" % [further, last])
	var at_rest := made.commands.refusal(REGION, TableColumns.RESIZES, {"column": &"road"})
	_verdict.check(at_rest == null and str(made.commands.refusal(REGION, TableColumns.RESIZES, {"column": &"risk"})) == "The last column has no edge to move", "asked at rest, as a grip asks, road's edge can still be moved, its neighbour able to give; the last column's cannot: %s" % [at_rest])
	var whole: float = model.get_shown().reduce(func(sum: float, column: Dictionary) -> float: return sum + column["share"], 0.0)
	_verdict.check(is_equal_approx(whole, 1.0), "the shares still make the whole: %f" % whole)
	made.done()


func _a_column_hidden_gives_its_share_to_the_rest() -> void:
	var made := Fixture.new(root)
	var model := _made(made)
	made.commands.dispatch(REGION, TableColumns.TURNS, {"column": &"road"})
	_verdict.check(_near(_shares(model), [1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0]) and not model.get_all()[1]["shown"], "road hidden, the other three share its width in proportion: %s" % [_shares(model)])
	made.commands.dispatch(REGION, TableColumns.TURNS, {"column": &"road"})
	var back: Array = _shares(model)
	_verdict.check(_near(back, [0.2, 0.4, 0.2, 0.2]), "shown again, road takes back its place and the share it had: %s" % [back])
	made.commands.dispatch(REGION, TableColumns.TURNS, {"column": &"id"})
	made.commands.dispatch(REGION, TableColumns.TURNS, {"column": &"road"})
	made.commands.dispatch(REGION, TableColumns.TURNS, {"column": &"town"})
	var kept := made.commands.dispatch(REGION, TableColumns.TURNS, {"column": &"risk"})
	_verdict.check(str(kept) == "The last column shown stays" and model.get_shown().size() == 1, "the last column shown is never hidden: %s" % kept)
	made.done()
