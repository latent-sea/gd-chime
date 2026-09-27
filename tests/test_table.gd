extends SceneTree

## What must be true of a table: headings over their own columns, sorting
## that is the model's, lines kept by key, cells a format dresses, and a
## long list's slots for a set too long to hold.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_table.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const LongList := preload("res://addons/gd_chime/long_list.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Each := preload("res://addons/gd_chime/components/primitives/each.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const VirtualList := preload("res://addons/gd_chime/components/primitives/virtual_list.gd")
const Surface := preload("res://addons/gd_chime/components/primitives/surface.gd")
const Table := preload("res://addons/gd_chime/components/recipes/table.gd")
const Outgoing := preload("res://addons/gd_chime/components/primitives/outgoing.gd")
const Verdict := preload("res://tests/verdict.gd")

var _verdict := Verdict.new()


## A set with an order: the rows as the model has sorted them, and which
## column it sorted by, which way.
class Sorted extends Fixture.Model:
	func get_sort() -> Variant:
		return of(&"sort").read()


## A source of many rows, for the long list.
class Source extends RefCounted:
	func fetch(first: int, count: int, answer: Callable) -> void:
		var rows: Array = []
		for index: int in range(first, mini(first + count, 200)):
			rows.append({"id": index, "name": "entry %d" % index, "count": index})
		answer.call(rows, 200)


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(600, 400)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_every_heading_stands_over_its_own_column)
	await _verdict.states(_a_heading_asks_the_model_to_sort_and_says_which_way_it_did)
	await _verdict.states(_the_lines_follow_the_model_s_order_and_keep_their_pieces)
	await _verdict.states(_a_format_dresses_a_cell_with_a_mark_and_a_kind)
	await _verdict.states(_a_format_that_tells_values_apart_by_colour_alone_is_said_out_loud)
	await _verdict.states(_a_long_set_is_the_list_s_slots)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


func _texts(node: Node) -> Array[String]:
	var found: Array[String] = []
	for child: Node in node.get_children():
		if child is Text:
			found.append((child as Text).get_text())
		found.append_array(_texts(child))
	return found


func _labels(node: Node) -> Array:
	return node.find_children("*", "Label", true, false)


func _parts(node: Node, of_kind: String) -> Array:
	var kinds := {"each": Each, "pressable": Pressable, "virtual_list": VirtualList, "surface": Surface}
	return node.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return is_instance_of(part, kinds[of_kind]))


func _columns(counted: Callable = Callable()) -> Array:
	var name := {"name": "name", "words": "name", "share": 0.6}
	var count := {"name": "count", "words": "count", "share": 0.4}
	if counted.is_valid():
		count["format"] = counted
	return [name, count]


## A model with two rows, sorted by name, and the table over it.
func _a_table(made: Fixture, columns: Array, long: Object = null) -> Sorted:
	var ui := made.ui
	var model := Sorted.new(made.chimes, &"app")
	model.set_value(&"items", [{"id": 1, "name": "apple", "count": 3}, {"id": 2, "name": "pear", "count": 12}])
	model.set_value(&"sort", {"column": "name", "ascending": true})
	made.commands.register(&"app", &"sorts", model)
	var key := func(row: Dictionary) -> int: return row["id"]
	var table := Table.make(ui, model.of(&"items"), columns, {key = key, sorts = &"sorts", sort = Bound.new(model.get_sort), style = &"Table", long = long})
	ui.start(ui.app(&"app", [table.named(&"table")]))
	return model


func _every_heading_stands_over_its_own_column() -> void:
	var made := Fixture.new(root, {&"sorts": "sort"})
	var model := _a_table(made, _columns())
	await _a_frame_passes()
	var table: Node = made.ui.node_named(&"table")
	var heading_x: Array = []
	for heading: Control in table.get_child(0).get_children():
		heading_x.append(heading.global_position.x)
	var line: Control = _parts(table, "each")[0].get_child(0)
	var cell_x: Array = []
	for cell: Control in line.get_children():
		cell_x.append(cell.global_position.x)
	_verdict.check(heading_x.size() == 2 and heading_x == cell_x, "two columns of unequal share: every cell starts where its heading does: %s over %s" % [heading_x, cell_x])
	_verdict.check(line.get_child(1).size.x < line.get_child(0).size.x, "and the narrower share is the narrower column: %s" % [[line.get_child(0).size.x, line.get_child(1).size.x]])
	model.free()
	made.done()


func _a_heading_asks_the_model_to_sort_and_says_which_way_it_did() -> void:
	var made := Fixture.new(root, {&"sorts": "sort"})
	var model := _a_table(made, _columns())
	await _a_frame_passes()
	var table: Node = made.ui.node_named(&"table")
	_verdict.check(_texts(table.get_child(0)) == ["name ^", "count"], "sorted by name upward, that heading alone carries the mark: %s" % [_texts(table.get_child(0))])
	(_parts(table.get_child(0), "pressable")[1] as Pressable).pressed()
	_verdict.check(model.told_actions == [&"sorts"] and made.commands.get_last()["payload"] == {"column": "count"}, "the count heading pressed asks the model to sort by count: %s" % [made.commands.get_last()["payload"]])
	model.set_value(&"sort", {"column": "count", "ascending": false})
	await _a_frame_passes()
	_verdict.check(_texts(table.get_child(0)) == ["name", "count v"], "the model having sorted by count downward, the mark moves and turns: %s" % [_texts(table.get_child(0))])
	model.free()
	made.done()


func _the_lines_follow_the_model_s_order_and_keep_their_pieces() -> void:
	var made := Fixture.new(root, {&"sorts": "sort"})
	var model := _a_table(made, _columns())
	await _a_frame_passes()
	var table: Node = made.ui.node_named(&"table")
	var laid: Each = _parts(table, "each")[0]
	var first: Node = laid.piece_for(2)
	_verdict.check(first != null and _texts(laid) == ["apple", "3", "pear", "12"], "a line per row, keyed by the row it is for, in the model's order: %s" % [_texts(laid)])
	model.set_value(&"items", [{"id": 2, "name": "pear", "count": 12}, {"id": 1, "name": "apple", "count": 3}])
	await _a_frame_passes()
	_verdict.check(_texts(laid) == ["pear", "12", "apple", "3"] and laid.piece_for(2) == first, "sorted again by the model, the lines reorder and keep their pieces: %s" % [_texts(laid)])
	model.free()
	made.done()


func _a_format_dresses_a_cell_with_a_mark_and_a_kind() -> void:
	# the floor's look colours every kind alike; a look that does not, for the words' blend to be seen
	root.theme.set_color(&"font_color", Themes.REASON, Color(0.5, 0.1, 0.1))
	root.theme.set_color(&"font_color", Themes.FACE, Color(0.1, 0.1, 0.5))
	var made := Fixture.new(root, {&"sorts": "sort"})
	var counted := func(value: Variant) -> Dictionary: return {"mark": "", "kind": Themes.REASON} if value == null or int(value) < 10 else {"mark": " !", "kind": Themes.FACE, "style": Themes.SURFACE}
	var model := _a_table(made, _columns(counted))
	await _a_frame_passes()
	var table: Node = made.ui.node_named(&"table")
	var dressed: Array[String] = _texts(_parts(table, "each")[0])
	var kinds: Array = _labels(table).map(func(label: Label) -> StringName: return label.theme_type_variation)
	_verdict.check(dressed == ["apple", "3", "pear", "12 !"], "the value over the threshold carries the format's mark, the one under it none: %s" % [dressed])
	_verdict.check(kinds.count(Themes.FACE) == 1 and kinds.count(Themes.REASON) == 1, "and the dressed cells are in the format's kinds, not a hue: %s" % [kinds])
	var grounds: Array = _parts(table, "surface").map(func(part: Control) -> StringName: return part.theme_type_variation)
	_verdict.check(grounds.count(Themes.SURFACE) == 1 and grounds.count(Table.CELL) == 1, "the marked one sits on the ground the format named, the other on the cell's own, which draws nothing: %s" % [grounds])
	var before: Array = _parts(table, "surface")
	made.ui.motion.by_hand = true
	made.ui.motion.still = false
	var panels: Array = before.map(func(part: Control) -> StyleBox: return part.get_theme_stylebox(&"panel"))
	var reason_ink: Color = root.theme.get_color(&"font_color", Themes.REASON)
	var face_ink: Color = root.theme.get_color(&"font_color", Themes.FACE)
	model.set_value(&"items", [{"id": 1, "name": "apple", "count": 30}, {"id": 2, "name": "pear", "count": 1}])
	await _a_frame_passes()
	var going: Array = before.map(func(part: Control) -> Array: return part.get_children(true).filter(func(child: Node) -> bool: return child is Outgoing))
	_verdict.check(going[0].size() == 1 and going[1].size() == 1 and (going[0][0] as Outgoing)._box == panels[0] and (going[1][0] as Outgoing)._box == panels[1], "each cell's old ground is left fading over its new one")
	made.ui.motion.step(0.045)
	await _a_frame_passes()
	var rising: Label = _labels(table).filter(func(label: Label) -> bool: return label.text == "30 !")[0]
	var between: Color = rising.get_theme_color(&"font_color")
	_verdict.check(reason_ink != face_ink and between != reason_ink and between != face_ink, "and mid-blend its words are between the two kinds' colours: %s" % [between])
	made.ui.motion.step(0.045)
	await _a_frame_passes()
	_verdict.check(not rising.has_theme_color_override(&"font_color") and rising.get_theme_color(&"font_color") == face_ink and made.ui.motion.get_running() == 0, "the blend over, the colour is the kind's own again and nothing runs")
	_verdict.check(_texts(_parts(table, "each")[0]) == ["apple", "30 !", "pear", "1"], "the values changed, the dress follows them: %s" % [_texts(_parts(table, "each")[0])])
	var after: Array = _parts(table, "surface")
	var worn: Array = after.map(func(part: Control) -> StringName: return part.theme_type_variation)
	_verdict.check(after == before and worn == [Themes.SURFACE, Table.CELL], "each value crossed the threshold and its cell changed ground in place - the same nodes before and after: %s" % [worn])
	_verdict.check(_parts(table, "each").size() == 1, "and no each stands inside a cell: the lines' own is the only one")
	for kind: StringName in [Themes.REASON, Themes.FACE]:
		root.theme.clear_color(&"font_color", kind)
	model.free()
	made.done()


## Counts the errors pushed while it listens.
class Hearing extends Logger:
	var errors: int = 0

	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array) -> void:
		if error_type == ERROR_TYPE_ERROR:
			errors += 1


## Meaning never rests on hue alone, as a rule that runs: two values dressed
## differently under the same mark are reported; marked differently, they are not.
func _a_format_that_tells_values_apart_by_colour_alone_is_said_out_loud() -> void:
	var hearing := Hearing.new()
	OS.add_logger(hearing)
	var marked := func(value: Variant) -> Dictionary: return {"mark": "", "kind": Themes.REASON} if value == null or int(value) < 10 else {"mark": " !", "kind": Themes.FACE}
	var made := Fixture.new(root, {&"sorts": "sort"})
	var model := _a_table(made, _columns(marked))
	await _a_frame_passes()
	_verdict.check(hearing.errors == 0, "a format that marks the value it singles out says nothing: %d" % hearing.errors)
	model.free()
	made.done()
	var by_colour := func(value: Variant) -> Dictionary: return {"mark": "", "kind": Themes.REASON} if value == null or int(value) < 10 else {"mark": "", "kind": Themes.FACE}
	made = Fixture.new(root, {&"sorts": "sort"})
	model = _a_table(made, _columns(by_colour))
	await _a_frame_passes()
	var heard := hearing.errors
	_verdict.check(heard == 1, "one that dresses a value differently and marks it with nothing is said out loud, once: %d" % heard)
	model.set_value(&"items", [{"id": 1, "name": "apple", "count": 4}, {"id": 2, "name": "pear", "count": 40}])
	await _a_frame_passes()
	_verdict.check(hearing.errors == heard, "and not again for every value it goes on dressing so: %d" % hearing.errors)
	OS.remove_logger(hearing)
	model.free()
	made.done()


func _a_long_set_is_the_list_s_slots() -> void:
	var made := Fixture.new(root, {&"sorts": "sort"})
	var source := Source.new()
	var long := LongList.new(made.chimes, source.fetch, 10, 6, 5, Bound.new(func() -> Variant: return null))
	made.commands.stand(&"long", long)
	root.add_child(long)
	var model := _a_table(made, _columns(), long)
	await _a_frame_passes()
	var table: Node = made.ui.node_named(&"table")
	var shown: Array = _parts(table, "virtual_list")
	_verdict.check(shown.size() == 1 and _parts(table, "each").is_empty(), "given a long list, the lines are its slots and the set is never held whole")
	long.look(null)
	await _a_frame_passes()
	_verdict.check((shown[0] as VirtualList).get_slots().size() == 5 and _texts(shown[0]).has("entry 0") and _texts(shown[0]).has("entry 4"), "the pages landed, a line per slot in the list's order: %s" % [_texts(shown[0])])
	made.commands.dispatch(&"long", LongList.SCROLL_ROW_DOWN, {})
	await _a_frame_passes()
	_verdict.check(_texts(shown[0]).has("entry 5") and not _texts(shown[0]).has("entry 0"), "scrolled, the same slots read the rows below: %s" % [_texts(shown[0])])
	long.free()
	model.free()
	made.done()
