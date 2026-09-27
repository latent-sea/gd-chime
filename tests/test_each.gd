extends SceneTree

## What must be true of each: one piece per item of a bound array.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_each.gd
##
## The template is asked once per item and given a handle, never the item;
## what it binds to the handle re-reads as the array moves; unkeyed, the
## pieces are rebuilt only when the count changes; handles pass through
## three levels of nesting, an item's own list being a field of its handle,
## with no false alarm; a template that reads its handle while it runs is
## reported; and keyed, a sort keeps the focus, a typed line and a kept
## when side with their item, an item added builds one piece, and an item
## gone frees one, the rest standing; a handle finds its item by key once
## an array; only a piece whose item changed reads it again; a hundred
## pieces re-reading on one bell walk the array a few times, not once a
## piece; and an item replaced or moved inside the very array the model
## hands back is re-read as it is.

const Fixture := preload("res://tests/fixture.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Each := preload("res://addons/gd_chime/components/primitives/each.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Verdict := preload("res://tests/verdict.gd")

var _verdict := Verdict.new()
var _hearing := Hearing.new()


## Counts the errors pushed while it listens.
class Hearing extends Logger:
	var errors: int = 0
	var script_errors: int = 0

	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array) -> void:
		if error_type == ERROR_TYPE_ERROR:
			errors += 1
		if error_type == ERROR_TYPE_SCRIPT:
			script_errors += 1


func _init() -> void:
	await process_frame
	OS.add_logger(_hearing)
	await _verdict.states(_one_piece_per_item_re_read_as_the_array_moves_and_rebuilt_only_as_the_count_changes)
	await _verdict.states(_handles_pass_through_three_levels_of_nesting)
	await _verdict.states(_a_template_that_captures_the_raw_item_is_reported)
	await _verdict.states(_keyed_a_sort_keeps_the_focus_the_typed_line_and_the_kept_side_with_their_item)
	await _verdict.states(_keyed_an_item_added_builds_one_piece_and_one_gone_frees_one_and_the_rest_stand)
	await _verdict.states(_keyed_an_item_come_and_gone_within_one_frame_leaves_nothing_to_arrive)
	await _verdict.states(_keyed_a_handle_finds_its_item_by_key_once_an_array_not_once_a_read)
	await _verdict.states(_keyed_only_the_piece_whose_item_changed_reads_it_again)
	await _verdict.states(_keyed_a_hundred_pieces_re_reading_on_one_bell_walk_the_array_about_once)
	await _verdict.states(_keyed_an_item_replaced_inside_the_same_array_is_re_read_as_the_new_one)
	OS.remove_logger(_hearing)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## The words of every text under this node, in tree order.
func _words_under(node: Node) -> Array[String]:
	var found: Array[String] = []
	for child: Node in node.get_children():
		if child is Text:
			found.append((child as Text).get_text())
		found.append_array(_words_under(child))
	return found


func _one_piece_per_item_re_read_as_the_array_moves_and_rebuilt_only_as_the_count_changes() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes)
	model.set_value(&"items", ["a", "b"])
	var each: Each = ui.build(ui.each(model.of(&"items"), func(item: Bound) -> Desc: return ui.text(item.map(func(word: String) -> String: return word.to_upper()))), root)
	await _a_frame_passes()
	_verdict.check(_words_under(each) == ["A", "B"] and each.get_count() == 2, "one piece per item, each reading through its handle: %s" % [_words_under(each)])
	var pieces := each.get_children().duplicate()
	model.set_value(&"items", ["c", "d"])
	await _a_frame_passes()
	_verdict.check(_words_under(each) == ["C", "D"] and each.get_children() == pieces, "the same count with other items: the handles re-read, nothing rebuilt")
	model.set_value(&"items", ["c", "d", "e"])
	await _a_frame_passes()
	_verdict.check(_words_under(each) == ["C", "D", "E"] and each.get_count() == 3, "the count changed: rebuilt, one per item: %s" % [_words_under(each)])
	each.free()
	model.free()
	made.done()


func _handles_pass_through_three_levels_of_nesting() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes)
	model.set_value(&"items", [{"name": "one", "children": [{"name": "one.a", "children": [{"name": "one.a.i"}]}]}, {"name": "two", "children": []}])
	var leaf := func(item: Bound) -> Desc: return ui.text(item.field("name"))
	var middle := func(item: Bound) -> Desc: return ui.column([ui.text(item.field("name")), ui.each(item.field("children"), leaf)])
	var top := func(item: Bound) -> Desc: return ui.column([ui.text(item.field("name")), ui.each(item.field("children"), middle)])
	var before := _hearing.errors
	var each: Each = ui.build(ui.each(model.of(&"items"), top), root)
	await _a_frame_passes()
	_verdict.check(_hearing.errors == before, "a nested each reading its items as it is built is no capture: %d reported" % (_hearing.errors - before))
	_verdict.check(_words_under(each) == ["one", "one.a", "one.a.i", "two"], "three levels deep, every name read through its handle: %s" % [_words_under(each)])
	model.set_value(&"items", [{"name": "uno", "children": [{"name": "uno.a", "children": [{"name": "uno.a.i"}]}]}, {"name": "dos", "children": []}])
	await _a_frame_passes()
	_verdict.check(_words_under(each) == ["uno", "uno.a", "uno.a.i", "dos"], "the array moved with the same shape: every level re-read through its handle, nothing rebuilt: %s" % [_words_under(each)])
	each.free()
	model.free()
	made.done()


func _a_template_that_captures_the_raw_item_is_reported() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes)
	model.set_value(&"items", ["captured"])
	var before := _hearing.errors
	var each: Each = ui.build(ui.each(model.of(&"items"), func(item: Bound) -> Desc: return ui.text(item.read())), root)
	_verdict.check(_hearing.errors == before + 1, "a template reading its handle while it runs is reported: %d" % (_hearing.errors - before))
	var later: Each = ui.build(ui.each(model.of(&"items"), func(item: Bound) -> Desc: return ui.text(item.map(func(word: String) -> String: return word.to_upper()))), root)
	await _a_frame_passes()
	_verdict.check(_hearing.errors == before + 1 and _words_under(later) == ["CAPTURED"], "one reading it later, through what it described, is not: %d" % (_hearing.errors - before))
	later.free()
	each.free()
	model.free()
	made.done()


const KEYED := [{"id": 1, "name": "pear", "flipped": true}, {"id": 2, "name": "apple", "flipped": false}, {"id": 3, "name": "fig", "flipped": true}]


## A keyed list: a row per thing with its name, a line to type into, and a
## kept when; the pieces found by key.
func _keyed(made: Fixture, model: Fixture.Model) -> Each:
	var ui := made.ui
	var template := func(thing: Bound) -> Desc: return ui.row([ui.text(thing.field("name")), ui.field(&"types"), ui.when(thing.field("flipped"), ui.text("flipped"), ui.text("plain")).keeps()])
	return ui.build(ui.each(model.of(&"items"), template, func(thing: Dictionary) -> int: return thing["id"]), root)


func _keyed_a_sort_keeps_the_focus_the_typed_line_and_the_kept_side_with_their_item() -> void:
	var made := Fixture.new(root)
	var model := Fixture.Model.new(made.chimes)
	model.set_value(&"items", KEYED.duplicate(true))
	var each := _keyed(made, model)
	await _a_frame_passes()
	var apple: Node = each.piece_for(2)
	var line: LineEdit = apple.get_child(1).get_child(0)
	line.grab_focus()
	line.text = "half typed"
	var kept: Node = apple.get_child(2).get_child(0)
	var sorted: Array = KEYED.duplicate(true)
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["name"] < b["name"])
	model.set_value(&"items", sorted)
	await _a_frame_passes()
	_verdict.check(each.piece_for(2) == apple and apple.get_index() == 0 and _words_under(each)[0] == "apple", "sorted, the apple's piece is the same node, moved first: %s" % [_words_under(each)])
	_verdict.check(root.gui_get_focus_owner() == line and line.text == "half typed", "and its line keeps the focus and what was typed: '%s'" % line.text)
	_verdict.check(apple.get_child(2).get_child(0) == kept, "and its kept when side is the same node")
	var flipped_only: Array = sorted.filter(func(thing: Dictionary) -> bool: return thing["flipped"])
	model.set_value(&"items", flipped_only)
	await _a_frame_passes()
	_verdict.check(each.get_count() == 2 and each.piece_for(2) == null and root.gui_get_focus_owner() != null, "filtered to the flipped, the apple's piece is freed and the focus handed on, not lost: %s" % root.gui_get_focus_owner())
	each.free()
	model.free()
	made.done()


func _keyed_an_item_added_builds_one_piece_and_one_gone_frees_one_and_the_rest_stand() -> void:
	var made := Fixture.new(root)
	var model := Fixture.Model.new(made.chimes)
	model.set_value(&"items", KEYED.duplicate(true))
	var each := _keyed(made, model)
	await _a_frame_passes()
	var pieces := each.get_children().duplicate()
	var more: Array = KEYED.duplicate(true)
	more.append({"id": 4, "name": "date", "flipped": false})
	model.set_value(&"items", more)
	await _a_frame_passes()
	_verdict.check(each.get_count() == 4 and each.get_children().slice(0, 3) == pieces and _words_under(each.piece_for(4))[0] == "date", "one added: one piece built after the three that stand: %s" % [_words_under(each)])
	var fewer: Array = more.filter(func(thing: Dictionary) -> bool: return thing["id"] != 1)
	model.set_value(&"items", fewer)
	await _a_frame_passes()
	_verdict.check(each.get_count() == 3 and each.piece_for(1) == null and each.piece_for(2) == pieces[1] and each.piece_for(3) == pieces[2], "one gone: its piece freed, the rest the same nodes: %s" % [_words_under(each)])
	each.free()
	model.free()
	made.done()


## Fifty items, each piece reading its item three times over as it draws:
## the key is asked of each item once for the array, not once a read - and
## an item changed in the array as it stands, the bell rung, is read anew.
func _keyed_a_handle_finds_its_item_by_key_once_an_array_not_once_a_read() -> void:
	var made := Fixture.new(root)
	var model := Fixture.Model.new(made.chimes)
	var many: Array = range(50).map(func(at: int) -> Dictionary: return {"id": at, "name": "crate %d" % at})
	model.set_value(&"items", many)
	var ui := made.ui
	var asked: Array = [0]
	var key := func(thing: Dictionary) -> int:
		asked[0] += 1
		return thing["id"]
	var template := func(thing: Bound) -> Desc: return ui.column([ui.text(thing.field("name")), ui.text(thing.field("name")), ui.text(thing.field("name"))])
	var each: Each = ui.build(ui.each(model.of(&"items"), template, key), root)
	await _a_frame_passes()
	asked[0] = 0
	model.set_value(&"items", many)
	await _a_frame_passes()
	_verdict.check(asked[0] <= 2 * 50, "every piece read again, the key asked %d times for 150 reads over 50 items: once an item to settle and once to look them up" % asked[0])
	# the item replaced in the same array, as a model holding its list in place does
	many[7] = {"id": 7, "name": "renamed"}
	model.set_value(&"items", many)
	await _a_frame_passes()
	_verdict.check(_words_under(each.piece_for(7)) == ["renamed", "renamed", "renamed"], "an item changed in the array as it stands, and its bell rung, is read anew: %s" % [_words_under(each.piece_for(7))])
	each.free()
	model.free()
	made.done()


## Three items, one of them changed and the array's bell rung: that piece's
## words are drawn again and the other two pieces draw nothing - a search
## hiding some cards leaves the rest unread.
func _keyed_only_the_piece_whose_item_changed_reads_it_again() -> void:
	var made := Fixture.new(root)
	var model := Fixture.Model.new(made.chimes)
	model.set_value(&"items", KEYED.duplicate(true))
	var ui := made.ui
	var each: Each = ui.build(ui.each(model.of(&"items"), func(thing: Bound) -> Desc: return ui.text(thing.field("name")), func(thing: Dictionary) -> int: return thing["id"]), root)
	await _a_frame_passes()
	var drawn := func() -> Array: return [1, 2, 3].map(func(id: int) -> int: return (each.piece_for(id) as Text).refresh_count)
	var before: Array = drawn.call()
	var changed: Array = KEYED.duplicate(true)
	changed[1]["name"] = "a different name"
	model.set_value(&"items", changed)
	await _a_frame_passes()
	var after: Array = drawn.call()
	_verdict.check(after[1] > before[1] and after[0] == before[0] and after[2] == before[2] and (each.piece_for(2) as Text).get_text() == "a different name", "only the piece whose item changed drew again: %s to %s" % [before, after])
	each.free()
	model.free()
	made.done()


## An item added and taken away again before the layout places anything -
## two keystrokes in one frame, in a palette - arrives as nothing, and the
## layout places what stands without a word.
func _keyed_an_item_come_and_gone_within_one_frame_leaves_nothing_to_arrive() -> void:
	var made := Fixture.new(root)
	var model := Fixture.Model.new(made.chimes)
	model.set_value(&"items", KEYED.duplicate(true))
	var each := _keyed(made, model)
	made.ui.motion.still = false
	await _a_frame_passes()
	var before := _hearing.script_errors
	var more: Array = KEYED.duplicate(true)
	more.append({"id": 4, "name": "date", "flipped": false})
	model.set_value(&"items", more)
	model.set_value(&"items", KEYED.duplicate(true))
	await _a_frame_passes()
	_verdict.check(_hearing.script_errors == before and each.get_count() == 3 and each.piece_for(4) == null, "come and gone in one frame, nothing is left to arrive and nothing is said: %d errors, %d pieces" % [_hearing.script_errors - before, each.get_count()])
	each.free()
	model.free()
	made.done()


## A hundred pieces, every item replaced by a new one with the same key: each
## piece re-reads its item, and finding them asks the key of each item a few
## times over, never once per piece per item - a page landing under a
## collection of cards costs a walk of the array, not a hundred.
func _keyed_a_hundred_pieces_re_reading_on_one_bell_walk_the_array_about_once() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes)
	model.set_value(&"items", range(100).map(func(at: int) -> Dictionary: return {"id": at, "name": "old %d" % at}))
	var asked := [0]
	var key := func(thing: Dictionary) -> int:
		asked[0] += 1
		return thing["id"]
	var each: Each = ui.build(ui.each(model.of(&"items"), func(thing: Bound) -> Desc: return ui.text(thing.field("name")), key), root)
	await _a_frame_passes()
	asked[0] = 0
	model.set_value(&"items", range(100).map(func(at: int) -> Dictionary: return {"id": at, "name": "new %d" % at}))
	await _a_frame_passes()
	_verdict.check(_words_under(each)[99] == "new 99" and _words_under(each)[0] == "new 0", "every piece re-read its new item: %s" % _words_under(each)[99])
	_verdict.check(asked[0] <= 600, "and a key was asked %d times for a hundred pieces over a hundred items - a few walks, not one per piece" % asked[0])
	each.free()
	model.free()
	made.done()


## The model writing into the array it hands back rather than handing back
## another: an item replaced there is the one its piece reads next.
func _keyed_an_item_replaced_inside_the_same_array_is_re_read_as_the_new_one() -> void:
	var made := Fixture.new(root)
	var model := Fixture.Model.new(made.chimes)
	model.set_value(&"items", KEYED.duplicate(true))
	var each := _keyed(made, model)
	await _a_frame_passes()
	var items: Array = model.of(&"items").read()
	items[1] = {"id": 2, "name": "quince", "flipped": false}
	model.set_value(&"items", items)
	await _a_frame_passes()
	_verdict.check(_words_under(each.piece_for(2))[0] == "quince", "replaced in the same array, its piece reads the new item: %s" % [_words_under(each)])
	items[0] = items[2]
	items[2] = {"id": 1, "name": "pear", "flipped": true}
	model.set_value(&"items", items)
	await _a_frame_passes()
	_verdict.check(_words_under(each.piece_for(3))[0] == "fig" and each.piece_for(3).get_index() == 0, "moved within the same array, each piece still reads its own item: %s" % [_words_under(each)])
	each.free()
	model.free()
	made.done()
