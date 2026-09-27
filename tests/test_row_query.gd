extends SceneTree

## What must be true of a query over packed rows: every clause keeps what
## it says and nothing else, the order is the column's up or down with rows
## of one value in the order they were added, groups run in the order of
## their words and say where they start and how many they hold - and the
## same over a hundred thousand rows as over a handful.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_row_query.gd

const PackedRows := preload("res://addons/gd_chime/packed_rows.gd")
const RowQuery := preload("res://addons/gd_chime/row_query.gd")
const Verdict := preload("res://tests/verdict.gd")

const MATERIALS := ["cast iron", "PVC", "steel", "ductile iron"]

var _verdict := Verdict.new()


func _init() -> void:
	await _verdict.states(_every_clause_keeps_what_it_says)
	await _verdict.states(_the_order_is_the_column_s_with_ties_as_added)
	await _verdict.states(_groups_run_in_the_order_of_their_words)
	await _verdict.states(_a_hundred_thousand_rows_are_ordered_as_one_by_one_would_order_them)
	quit(_verdict.deliver(get_script()))


## Pipes: a risk, the year laid, a material.
func _pipes(count: int) -> PackedRows:
	var rows := PackedRows.new({&"risk": PackedRows.NUMBER, &"laid": PackedRows.DATE, &"material": PackedRows.WORDS})
	# every pipe, its values spread so every test has some to keep and some to leave
	for row: int in count:
		rows.add([float((row * 37) % 100), PackedRows.day_of(str(1900 + (row * 7) % 120)), MATERIALS[(row * 3) % MATERIALS.size()]])
	return rows


## The rows of an order, as ids, for reading in a sentence.
func _ids(order: PackedInt32Array) -> Array:
	return Array(order)


func _every_clause_keeps_what_it_says() -> void:
	var rows := _pipes(40)
	var iron: Dictionary = RowQuery.run(rows, [{"column": &"material", "test": RowQuery.IS, "value": ["cast iron"]}], {}, &"")
	var all_iron: bool = Array(iron["order"]).all(func(row: int) -> bool: return rows.value_at(row, &"material") == "cast iron")
	_verdict.check(iron["order"].size() == 10 and all_iron, "IS keeps the rows of that word and no other: %s" % [_ids(iron["order"])])
	var not_iron: Dictionary = RowQuery.run(rows, [{"column": &"material", "test": RowQuery.IS_NOT, "value": ["cast iron"]}], {}, &"")
	_verdict.check(not_iron["order"].size() == 30, "IS_NOT keeps the rest: %d" % not_iron["order"].size())
	var irons: Dictionary = RowQuery.run(rows, [{"column": &"material", "test": RowQuery.INCLUDES, "value": "IRON"}], {}, &"")
	_verdict.check(irons["order"].size() == 20, "INCLUDES finds the letters in either iron, whatever their case: %d" % irons["order"].size())
	var risky: Dictionary = RowQuery.run(rows, [{"column": &"risk", "test": RowQuery.OVER, "value": 70.0}], {}, &"")
	_verdict.check(Array(risky["order"]).all(func(row: int) -> bool: return rows.value_at(row, &"risk") > 70.0) and risky["order"].size() == range(40).filter(func(row: int) -> bool: return (row * 37) % 100 > 70).size(), "OVER keeps the rows above the number, not at it: %d" % risky["order"].size())
	var old: Dictionary = RowQuery.run(rows, [{"column": &"laid", "test": RowQuery.UNDER, "value": PackedRows.day_of("1970")}], {}, &"")
	var before_1970: int = range(40).filter(func(row: int) -> bool: return 1900 + (row * 7) % 120 < 1970).size()
	_verdict.check(old["order"].size() == before_1970, "UNDER a day keeps what was laid before it: %d of %d" % [old["order"].size(), before_1970])
	var three: Dictionary = RowQuery.run(rows, [{"column": &"material", "test": RowQuery.IS, "value": ["cast iron"]}, {"column": &"risk", "test": RowQuery.OVER, "value": 70.0}, {"column": &"laid", "test": RowQuery.UNDER, "value": PackedRows.day_of("1970")}], {}, &"")
	var by_hand: Array = range(40).filter(func(row: int) -> bool: return rows.value_at(row, &"material") == "cast iron" and rows.value_at(row, &"risk") > 70.0 and 1900 + (row * 7) % 120 < 1970)
	_verdict.check(_ids(three["order"]) == by_hand and not by_hand.is_empty(), "three clauses keep what all three keep, in the order added: %s against %s" % [_ids(three["order"]), by_hand])


func _the_order_is_the_column_s_with_ties_as_added() -> void:
	var rows := _pipes(40)
	var up: Dictionary = RowQuery.run(rows, [], {"column": &"risk", "ascending": true}, &"")
	var risks: Array = Array(up["order"]).map(func(row: int) -> float: return rows.value_at(row, &"risk"))
	var sorted := risks.duplicate()
	sorted.sort()
	_verdict.check(up["order"].size() == 40 and risks == sorted, "up by risk, every row, least first: %s" % [risks])
	var down: Dictionary = RowQuery.run(rows, [], {"column": &"material", "ascending": false}, &"")
	var words: Array = Array(down["order"]).map(func(row: int) -> String: return rows.value_at(row, &"material"))
	_verdict.check(words.front() == "steel" and words.back() == "cast iron", "down by a words column, the last word first: %s .. %s" % [words.front(), words.back()])
	var steel: Array = Array(down["order"]).filter(func(row: int) -> bool: return rows.value_at(row, &"material") == "steel")
	var in_order := steel.duplicate()
	in_order.sort()
	_verdict.check(steel == in_order, "rows of one word keep the order they were added in, down as well as up: %s" % [steel])


func _groups_run_in_the_order_of_their_words() -> void:
	var rows := _pipes(40)
	var grouped: Dictionary = RowQuery.run(rows, [{"column": &"risk", "test": RowQuery.OVER, "value": 20.0}], {"column": &"risk", "ascending": false}, &"material")
	var groups: Array = grouped["groups"]
	_verdict.check(groups.map(func(group: Dictionary) -> String: return group["words"]) == ["cast iron", "ductile iron", "PVC", "steel"], "the groups in the order of their words: %s" % [groups.map(func(group: Dictionary) -> String: return group["words"])])
	var whole := true
	# every group, its rows the ones of its word, its first where the one before ended, sorted within by risk downward
	for at: int in groups.size():
		var group: Dictionary = groups[at]
		var members: Array = _ids(grouped["order"]).slice(group["first"], group["first"] + group["count"])
		var risks: Array = members.map(func(row: int) -> float: return rows.value_at(row, &"risk"))
		var down := risks.duplicate()
		down.sort()
		down.reverse()
		whole = whole and members.all(func(row: int) -> bool: return rows.value_at(row, &"material") == group["words"]) and risks == down
		whole = whole and group["first"] == (0 if at == 0 else groups[at - 1]["first"] + groups[at - 1]["count"])
	var counted: int = groups.reduce(func(sum: int, group: Dictionary) -> int: return sum + group["count"], 0)
	_verdict.check(whole and counted == grouped["order"].size(), "each group holds its word's rows alone, starts where the last ended, sorted within: %s" % [groups])


func _a_hundred_thousand_rows_are_ordered_as_one_by_one_would_order_them() -> void:
	var rows := _pipes(100000)
	var began := Time.get_ticks_msec()
	var asked: Dictionary = RowQuery.run(rows, [{"column": &"material", "test": RowQuery.IS_NOT, "value": ["PVC"]}], {"column": &"laid", "ascending": true}, &"material")
	var took := Time.get_ticks_msec() - began
	var order: PackedInt32Array = asked["order"]
	var right := order.size() == 75000
	# every neighbouring pair in the answer, for a pair out of order: group word, then day, then id
	for at: int in range(1, order.size()):
		var a := order[at - 1]
		var b := order[at]
		var key_a := [rows.value_at(a, &"material"), rows.value_at(a, &"laid"), a]
		var key_b := [rows.value_at(b, &"material"), rows.value_at(b, &"laid"), b]
		if not (String(key_a[0]).naturalnocasecmp_to(key_b[0]) < 0 or (key_a[0] == key_b[0] and (key_a[1] < key_b[1] or (key_a[1] == key_b[1] and key_a[2] < key_b[2])))):
			right = false
			break
	_verdict.check(right, "a hundred thousand rows, three in four kept, grouped and ordered by day then as added, pair by pair (%d ms)" % took)
