extends SceneTree

## What must be true of the recipes over sets: the collection, the
## filter-set, the matrix, the board, the disposition and the relationship
## graph.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_collections.gd

const Fixture := preload("res://tests/fixture.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Each := preload("res://addons/gd_chime/components/primitives/each.gd")
const Scroll := preload("res://addons/gd_chime/components/primitives/scroll.gd")
const PanZoom := preload("res://addons/gd_chime/components/primitives/pan_zoom.gd")
const Collection := preload("res://addons/gd_chime/components/recipes/collection.gd")
const FilterSet := preload("res://addons/gd_chime/components/recipes/filter_set.gd")
const Narrowing := preload("res://addons/gd_chime/narrowing.gd")
const Matrix := preload("res://addons/gd_chime/components/recipes/matrix.gd")
const Board := preload("res://addons/gd_chime/components/recipes/board.gd")
const Disposition := preload("res://addons/gd_chime/components/recipes/disposition.gd")
const Graph := preload("res://addons/gd_chime/components/recipes/relationship_graph.gd")
const Verdict := preload("res://tests/verdict.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")

var _verdict := Verdict.new()


## Filters, for the filter-set: properties, chips, what is being built, a
## count, and the two narrowings its pickers type against.
class Filters extends Fixture.Model:
	var properties_picked: Narrowing
	var values_picked: Narrowing

	func _init(chimes: Chimes, in_region: StringName) -> void:
		super(chimes, in_region)
		properties_picked = Narrowing.new(chimes, Bound.new(get_property_options))
		values_picked = Narrowing.new(chimes, Bound.new(get_value_options))

	func get_properties() -> Array:
		return of(&"properties", []).read()

	func get_chips() -> Array:
		return of(&"chips", []).read()

	func get_building() -> Variant:
		return of(&"building").read()

	func get_count() -> Variant:
		return of(&"count").read()

	func get_property_options() -> Array:
		return get_properties().map(func(property: Dictionary) -> Dictionary: return {"value": property["name"], "words": property["name"]})

	func get_value_options() -> Array:
		var so_far: Variant = get_building()
		if so_far == null:
			return []
		var named: Array = get_properties().filter(func(property: Dictionary) -> bool: return property["name"] == so_far["property"] and property.has("values"))
		return [] if named.is_empty() else named[0]["values"].map(func(value: String) -> Dictionary: return {"value": value, "words": value})

	func get_property_narrowing() -> Object:
		return properties_picked

	func get_value_narrowing() -> Object:
		return values_picked

## An item with a disposition.
class Item extends Fixture.Model:
	func get_chosen() -> Variant:
		return of(&"chosen").read()

	func get_satisfied() -> Variant:
		return of(&"satisfied").read()


## A graph's picture.
class Pictured extends Fixture.Model:
	func get_picture() -> Variant:
		return of(&"picture").read()

	## The node picked, or nothing: which is selected is the model's.
	func get_selected() -> Variant:
		return of(&"selected").read()

	func told(action: StringName, payload: Dictionary) -> Phrase:
		if action == &"picks":
			set_value(&"selected", of(&"picture").read()["nodes"].filter(func(node: Dictionary) -> bool: return node["id"] == payload["picked"])[0])
		return super(action, payload)


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(400, 400)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_a_collection_lays_the_model_s_members_out_as_rows_or_tiles_kept_by_key_with_its_controls_above)
	await _verdict.states(_a_filter_set_offers_what_the_property_s_type_offers_and_its_chips_toggle_and_remove)
	await _verdict.states(_a_matrix_places_a_cell_per_crossing_and_shows_one_triangle_of_a_set_against_itself)
	await _verdict.states(_a_board_keeps_the_reader_s_own_row_in_view)
	await _verdict.states(_a_disposition_is_one_picker_whose_chosen_second_half_shows_and_says_when_unfinished)
	await _verdict.states(_a_graph_paints_the_model_s_picture_and_pans_zooms_and_picks_through_it)
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


func _pressables(node: Node) -> Array:
	return node.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable)


func _each_under(node: Node) -> Each:
	return node.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Each)[0]


func _a_collection_lays_the_model_s_members_out_as_rows_or_tiles_kept_by_key_with_its_controls_above() -> void:
	var made := Fixture.new(root, {&"sorts": "sort", &"opens": "open"})
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes, &"app")
	model.set_value(&"items", [{"id": 1, "name": "pear"}, {"id": 2, "name": "apple"}])
	var template := func(member: Bound) -> Desc: return ui.pressable(&"opens", {}, [ui.text(member.field("name"))])
	var key := func(member: Dictionary) -> int: return member["id"]
	var rows := Collection.make(ui, model.of(&"items"), template, {key = key, shape = Collection.ROWS, controls = [ui.pressable(&"sorts")]}).named(&"rows")
	var tiles := Collection.make(ui, model.of(&"items"), template, {key = key, shape = Collection.TILES}).named(&"tiles")
	model.answering = [&"sorts", &"opens"]
	ui.start(ui.app(&"app", [ui.column([rows, tiles])], model))
	await _a_frame_passes()
	var laid := _each_under(ui.node_named(&"rows"))
	var first: Node = laid.piece_for(2)
	_verdict.check(laid.get_count() == 2 and _texts(laid) == ["pear", "apple"] and _pressables(ui.node_named(&"rows")).size() == 3, "rows: one pressable member per item, the sort control above them: %s" % [_texts(laid)])
	_verdict.check(_each_under(ui.node_named(&"tiles")).theme_type_variation == Themes.TILES, "tiles: the same members along a line that wraps")
	model.set_value(&"items", [{"id": 2, "name": "apple"}, {"id": 1, "name": "pear"}])
	await _a_frame_passes()
	_verdict.check(_texts(laid) == ["apple", "pear"] and laid.piece_for(2) == first, "sorted by the model, the members reorder and keep their cells")
	model.free()
	made.done()


func _a_filter_set_offers_what_the_property_s_type_offers_and_its_chips_toggle_and_remove() -> void:
	var made := Fixture.new(root, {&"picks_property": "property", &"types_property": "find a property", &"picks_comparison": "comparison", &"picks_value": "pick a value", &"types_value": "find a value", &"sets_value": "value", &"toggles": "toggle", &"removes": "remove"})
	var ui := made.ui
	var filters := Filters.new(made.chimes, &"app")
	filters.set_value(&"properties", [{"name": "won", "type": FilterSet.A_NUMBER}, {"name": "kind", "type": FilterSet.A_LIST, "values": ["soft", "hard"]}, {"name": "retired", "type": FilterSet.A_BOOLEAN}])
	filters.set_value(&"chips", [{"id": 1, "words": "won is over 100", "on": true}])
	filters.set_value(&"building", null)
	filters.set_value(&"count", 12)
	var actions := {"picks_property": &"picks_property", "types_property": &"types_property", "picks_comparison": &"picks_comparison", "picks_value": &"picks_value", "types_value": &"types_value", "sets_value": &"sets_value", "toggles": &"toggles", "removes": &"removes"}
	for action: StringName in [&"picks_property", &"picks_comparison", &"picks_value", &"sets_value", &"toggles", &"removes"]:
		made.commands.register(&"app", action, filters)
	made.commands.register(&"app", &"types_property", filters.properties_picked)
	made.commands.register(&"app", &"types_value", filters.values_picked)
	ui.start(ui.app(&"app", [FilterSet.make(ui, filters, actions).named(&"filters")]))
	await _a_frame_passes()
	var set: Node = ui.node_named(&"filters")
	var pressed := _pressables(set)
	_verdict.check(pressed.size() == 5 and _texts(set).has("12 matches") and _texts(set).has("won is over 100"), "three properties to pick, one chip with its body and its X, and the count: %s" % [_texts(set)])
	(pressed[0] as Pressable).pressed()
	_verdict.check(filters.told_actions == [&"picks_property"] and made.commands.get_last()["payload"] == {"value": "won"}, "a property pressed picks it, by the value its option carries: %s" % [made.commands.get_last()["payload"]])
	filters.set_value(&"building", {"property": "won"})
	await _a_frame_passes()
	_verdict.check(_texts(set).has("is over") and _texts(set).has("is under") and _texts(set).has("is exactly"), "a number picked, its three comparisons are offered: %s" % [_texts(set)])
	filters.set_value(&"building", {"property": "won", "comparison": "is over"})
	await _a_frame_passes()
	_verdict.check(_lines(set) == 2, "a comparison picked, a value is typed in beside the property picker's own line")
	filters.set_value(&"building", {"property": "kind", "comparison": "is"})
	await _a_frame_passes()
	_verdict.check(_lines(set) == 2 and _texts(set).has("soft") and _texts(set).has("hard") and _texts(set).has("2 matches"), "a list picked, its values are typed against and picked, never a line to type the value into: %s" % [_texts(set)])
	filters.told_actions.clear()
	var value: Pressable = _pressables(set).filter(func(part: Node) -> bool: return (part as Pressable).action == &"picks_value")[1]
	value.pressed()
	_verdict.check(filters.told_actions == [&"picks_value"] and made.commands.get_last()["payload"] == {"value": "hard"}, "one of the values pressed builds the filter with it: %s" % [made.commands.get_last()["payload"]])
	filters.set_value(&"building", {"property": "retired", "comparison": "is true"})
	await _a_frame_passes()
	_verdict.check(_lines(set) == 1 and _texts(set).has("is true"), "a boolean takes no value at all, typed or picked")
	filters.told_actions.clear()
	var chip: Pressable = _pressables(set).filter(func(part: Node) -> bool: return (part as Pressable).action == &"removes")[0]
	chip.pressed()
	_verdict.check(filters.told_actions == [&"removes"] and made.commands.get_last()["payload"] == {"id": 1}, "the chip's X removes it: %s" % [made.commands.get_last()["payload"]])
	filters.properties_picked.free()
	filters.values_picked.free()
	filters.free()
	made.done()


## How many lines there are to type in, under a piece.
func _lines(node: Node) -> int:
	return node.find_children("*", "LineEdit", true, false).size()


func _a_matrix_places_a_cell_per_crossing_and_shows_one_triangle_of_a_set_against_itself() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes)
	model.set_value(&"items", [{"id": "a"}, {"id": "b"}, {"id": "c"}])
	var key := func(item: Dictionary) -> String: return item["id"]
	var cell := func(row: Bound, column: Bound) -> Desc: return ui.text(row.map(func(r: Variant) -> String: return "" if r == null or column.read() == null else r["id"] + column.read()["id"]))
	var label := func(item: Bound) -> Desc: return ui.text(item.field("id"))
	var plain := ui.build(Matrix.make(ui, model.of(&"items"), model.of(&"items"), {cell = cell, row_label = label, column_label = label, key = key}), root)
	var symmetric := ui.build(Matrix.make(ui, model.of(&"items"), model.of(&"items"), {cell = cell, row_label = label, column_label = label, key = key, corner = null, symmetric = true}), root)
	await _a_frame_passes()
	var plain_cells := _texts(plain).filter(func(words: String) -> bool: return words.length() == 2)
	_verdict.check(plain_cells == ["aa", "ab", "ac", "ba", "bb", "bc", "ca", "cb", "cc"], "two axes of three: a cell per crossing, from the row and the column: %s" % [plain_cells])
	var triangle := _texts(symmetric).filter(func(words: String) -> bool: return words.length() == 2)
	_verdict.check(triangle == ["ab", "ac", "bc"], "one set against itself: one triangle, no diagonal: %s" % [triangle])
	# a corner wider than the row labels, within its share: every column's label still starts where its cells start
	var host := Control.new()
	host.size = Vector2(900, 300)
	root.add_child(host)
	var wide := ui.build(Matrix.make(ui, model.of(&"items"), model.of(&"items"), {cell = cell, row_label = label, column_label = label, key = key, corner = ui.text("the corner words")}), host)
	await _a_frame_passes()
	var head: Control = wide.get_child(0)
	var first_line: Control = wide.get_child(1).get_child(0).get_child(0)
	var label_x: Array = []
	for piece: Control in head.get_child(1).get_children():
		label_x.append(piece.global_position.x)
	var cell_x: Array = []
	for piece: Control in first_line.get_child(1).get_children():
		cell_x.append(piece.global_position.x)
	_verdict.check(label_x.size() == 3 and label_x == cell_x, "the column labels sit over their cells, however wide the corner within its share: %s over %s" % [label_x, cell_x])
	plain.free()
	symmetric.free()
	host.free()
	model.free()
	made.done()


func _a_board_keeps_the_reader_s_own_row_in_view() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes)
	var ranked: Array = []
	for rank: int in range(40):
		ranked.append({"id": rank, "name": "entrant %d" % rank})
	model.set_value(&"items", ranked)
	model.set_value(&"flag", 33)
	var host := Control.new()
	host.size = Vector2(200, 120)
	root.add_child(host)
	var board: Scroll = ui.build(Board.make(ui, model.of(&"items"), func(row: Bound) -> Desc: return ui.text(row.field("name")), {key = func(row: Dictionary) -> int: return row["id"], own = model.of(&"flag")}), host)
	await _a_frame_passes()
	await _a_frame_passes()
	await _a_frame_passes()
	var mine: Control = ui.node_named(&"board_row_33")
	_verdict.check(mine != null and Rect2(Vector2.ZERO, board.size).encloses(Rect2(mine.global_position - board.global_position, mine.size)), "the reader's own row, far down, is in view without hunting: %d" % board.scroll_vertical)
	host.free()
	model.free()
	made.done()


func _a_disposition_is_one_picker_whose_chosen_second_half_shows_and_says_when_unfinished() -> void:
	var made := Fixture.new(root, {&"enters": "enter", &"lists": "list", &"releases": "release"})
	var ui := made.ui
	var item := Item.new(made.chimes, &"app")
	item.set_value(&"chosen", null)
	item.set_value(&"satisfied", true)
	item.refuse(&"lists", Phrase.of("not in the market phase"))
	for action: StringName in [&"enters", &"lists", &"releases"]:
		made.commands.register(&"app", action, item)
	ui.start(ui.app(&"app", [Disposition.make(ui, item, {&"enters": ui.text("which round"), &"lists": ui.text("at what price"), &"releases": null}).named(&"it")]))
	await _a_frame_passes()
	var it: Node = ui.node_named(&"it")
	var picker := _pressables(it)
	_verdict.check(picker.size() == 3 and not (picker[1] as Pressable).is_usable() and str((picker[1] as Pressable).get_reason()) == "not in the market phase", "one picker of three choices, the one the phase does not allow inert and saying why")
	_verdict.check(not _texts(it).has("which round") and not _texts(it).has("at what price"), "nothing chosen, no second half shows")
	item.set_value(&"satisfied", false)
	item.set_value(&"chosen", &"enters")
	await _a_frame_passes()
	_verdict.check(_texts(it).has("which round") and not _texts(it).has("at what price") and _texts(it).has("The choice is not finished"), "entering chosen, its second half shows and the control says it is not finished: %s" % [_texts(it)])
	item.set_value(&"satisfied", true)
	await _a_frame_passes()
	_verdict.check(not _texts(it).has("The choice is not finished"), "answered, it is satisfied")
	item.free()
	made.done()


func _a_graph_paints_the_model_s_picture_and_pans_zooms_and_picks_through_it() -> void:
	var made := Fixture.new(root, {&"pans": "pan", &"zooms": "zoom", &"picks": "pick", &"zooms_in": "zoom in", &"zooms_out": "zoom out", &"expands": "wider family", &"opens": "open"})
	var ui := made.ui
	var graph := Pictured.new(made.chimes, &"app")
	graph.set_value(&"picture", {"nodes": [{"id": 1, "name": "ann", "at": Vector2(-60, 0)}, {"id": 2, "name": "bo", "at": Vector2(60, 0)}, {"id": 3, "name": "cy", "at": Vector2(0, 100)}], "links": [{"a": 1, "b": 2, "strength": 0.8}], "view": {"centre": Vector2.ZERO, "scale": 1.0}, "radius": 12.0, "size": Vector2(400, 400)})
	var actions := {"pans": &"pans", "zooms": &"zooms", "picks": &"picks", "zooms_in": &"zooms_in", "zooms_out": &"zooms_out", "expands": &"expands", "opens": &"opens"}
	for action: StringName in actions.values():
		made.commands.register(&"app", action, graph)
	ui.start(ui.app(&"app", [ui.column([Graph.make(ui, graph, actions, &"individual").named(&"graph").grow(), ui.screen(&"individual", [])])]))
	await _a_frame_passes()
	var canvas: PanZoom = ui.node_named(&"graph").find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is PanZoom)[0]
	var centre := canvas.global_position + canvas.size / 2.0
	var ann := centre + Vector2(-60, 0)
	_click(ann)
	await _a_frame_passes()
	_verdict.check(graph.told_actions == [&"picks"] and made.commands.get_last()["payload"] == {"picked": 1}, "a press on a node picks that individual: %s" % [graph.told_actions])
	_click(centre + Vector2(0, -150))
	await _a_frame_passes()
	_verdict.check(graph.told_actions == [&"picks"], "a press on empty space picks nothing")
	var ways := _pressables(ui.node_named(&"graph"))
	_verdict.check(ways.size() == 4 and graph.of(&"picture").read()["selected"] == 1 and _texts(ui.node_named(&"graph")).has("ann"), "selected, the node is noted for the painter's ring and its panel stands by the zoom buttons, named: %s" % [_texts(ui.node_named(&"graph"))])
	(ways[3] as Pressable).pressed()
	_verdict.check(graph.told_actions == [&"picks", &"expands"] and made.commands.get_last()["payload"] == {"id": 1}, "expand is a command to the model, carrying the node: %s" % [made.commands.get_last()["payload"]])
	(ways[2] as Pressable).pressed()
	await _a_frame_passes()
	_verdict.check(made.driver.get_top().has(&"individual") and made.driver.get_parameter(&"individual") == 1, "open is a link to that individual, carrying its id: %s" % [made.driver.get_parameter(&"individual")])
	graph.free()
	made.done()


func _click(at: Vector2) -> void:
	for pressed: bool in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		click.position = at
		root.push_input(click)
