extends SceneTree

## What must be true of a line of cells: words changing place nothing,
## here or in any layout above; each column is its share but never
## narrower than the widest words it may hold, so narrowed, a column keeps
## its words whole and the line grows past its window instead; two lines
## of one table stand cell over cell; a hidden column's part is hidden and
## the rest take its room; an edge stands in each gap; the ground follows a
## bound style in place; a column is measured in the language on, and again
## when it changes.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_cells.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Tables := preload("res://addons/gd_chime/theme_tables.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Cells := preload("res://addons/gd_chime/components/primitives/cells.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Flex := preload("res://addons/gd_chime/components/primitives/flex.gd")
const Clipped := preload("res://addons/gd_chime/clipped_text.gd")
const TableColumns := preload("res://addons/gd_chime/table_columns.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Language := preload("res://addons/gd_chime/language.gd")
const Verdict := preload("res://tests/verdict.gd")

const REGION := &"table"
const NAMES: Array = [&"id", &"road", &"risk"]
## The widest a road may be, and the words a road cell starts with.
const LONG_ROAD := "the long road past the old reservoir"

var _verdict := Verdict.new()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(1200, 400)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_words_changing_place_nothing)
	await _verdict.states(_a_column_is_its_share_but_never_narrower_than_its_words)
	await _verdict.states(_two_lines_stand_cell_over_cell_and_a_hidden_column_gives_its_room)
	await _verdict.states(_an_edge_stands_in_each_gap_and_the_ground_follows_its_style)
	await _verdict.states(_columns_are_measured_in_the_language_on_and_again_when_it_changes)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## The columns, a model of three at these shares.
func _columns(made: Fixture, shares: Array) -> TableColumns:
	var columns: Array = []
	# every column name, with its share
	for at: int in NAMES.size():
		columns.append({"name": NAMES[at], "words": Phrase.of(String(NAMES[at])), "share": shares[at]})
	var model := TableColumns.new(made.chimes, columns, 0.01)
	made.commands.stand(REGION, model)
	root.add_child(model)
	return model


## A line of three texts over these columns, in a column layout of its own, under a place.
func _line(made: Fixture, columns: TableColumns, samples: Dictionary, words: Bound, ground: Variant = Tables.CELLS, edges: Array = []) -> Desc:
	var ui := made.ui
	var parts: Array = [ui.text("PIPE-000001", Tables.WORDS), ui.text(words, Tables.WORDS), ui.text("12.5", Tables.WORDS)]
	return ui.cells(parts, NAMES, Bound.new(columns.get_shown), {samples = samples, words_kind = Tables.WORDS, ground = ground, edges = edges})


func _samples() -> Dictionary:
	return {&"id": {"words": ["PIPE-000001"]}, &"road": {"words": ["mill lane", LONG_ROAD]}, &"risk": {"words": ["100.0"]}}


func _cells_in(node: Node) -> Array:
	return node.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Cells)


func _words_changing_place_nothing() -> void:
	var made := Fixture.new(root)
	var columns := _columns(made, [0.2, 0.6, 0.2])
	var words := Fixture.Model.new(made.chimes, REGION)
	words.set_value(&"words", "mill lane")
	root.add_child(words)
	made.ui.start(made.ui.app(&"app", [made.ui.column([_line(made, columns, _samples(), words.of(&"words")), made.ui.text("below")]).named(&"held")]))
	await _a_frame_passes()
	var line: Cells = _cells_in(root)[0]
	var held: Flex = made.ui.node_named(&"held")
	var placed := line.placed_count
	var arranged := held.arrange_count
	var road: Control = line.get_child(1)
	var at := road.get_rect()
	# many different words, each drawn, as a list scrolling re-points a row
	for turn: int in 20:
		words.set_value(&"words", LONG_ROAD.substr(0, 3 + turn))
		await process_frame
	_verdict.check((road as Text).get_text() == LONG_ROAD.substr(0, 22), "the words changed twenty times: %s" % (road as Text).get_text())
	_verdict.check(line.placed_count == placed and held.arrange_count == arranged and road.get_rect() == at, "and nothing was placed again - the line %d times, the layout above %d times, the cell where it was" % [line.placed_count - placed, held.arrange_count - arranged])
	made.done()


func _a_column_is_its_share_but_never_narrower_than_its_words() -> void:
	var made := Fixture.new(root)
	var columns := _columns(made, [0.3, 0.4, 0.3])
	made.ui.start(made.ui.app(&"app", [_line(made, columns, _samples(), Bound.constant(LONG_ROAD))]))
	await _a_frame_passes()
	var line: Cells = _cells_in(root)[0]
	var wide := line.get_widths()
	_verdict.check(is_equal_approx(wide[0] / wide[2], 1.0) and wide[1] > wide[0], "with room, each column is its share: %s" % [wide])
	made.commands.dispatch(REGION, TableColumns.RESIZES, {"column": &"id", "by": 0.35})
	await _a_frame_passes()
	var narrowed := line.get_widths()
	var road: Text = line.get_child(1)
	var label: Label = road.get_child(0)
	var needs := label.get_minimum_size().x
	_verdict.check(narrowed[1] >= needs and road.size.x >= needs, "the road narrowed to a twentieth, its column still holds its longest words whole: %.0f for %.0f" % [narrowed[1], needs])
	root.size = Vector2i(400, 400)
	await _a_frame_passes()
	var cut := Clipped.clipped(root, root.get_visible_rect())
	var standing: Array = line.get_children().map(func(part: Control) -> bool: return part.visible)
	_verdict.check(cut.is_empty() and line.size.x <= 400.0 and standing == [true, false, false], "in a window too narrow for the columns, the line is no wider than it and drops the columns that do not fit, whole - no word cut: %.0f, %s, %s" % [line.size.x, standing, cut])
	root.size = Vector2i(1200, 400)
	made.done()


func _two_lines_stand_cell_over_cell_and_a_hidden_column_gives_its_room() -> void:
	var made := Fixture.new(root)
	var columns := _columns(made, [0.2, 0.5, 0.3])
	var samples := _samples()
	var head := _line(made, columns, samples, Bound.constant("road"), Tables.HEAD)
	var row := _line(made, columns, samples, Bound.constant("mill lane"))
	made.ui.start(made.ui.app(&"app", [made.ui.column([head, row])]))
	await _a_frame_passes()
	var lines := _cells_in(root)
	var xs: Array = lines.map(func(line: Cells) -> Array: return line.get_children().map(func(part: Control) -> float: return part.global_position.x))
	_verdict.check(xs[0] == xs[1] and xs[0].size() == 3, "the heading line and a row, their cells start at the same places: %s" % [xs])
	made.commands.dispatch(REGION, TableColumns.TURNS, {"column": &"road"})
	await _a_frame_passes()
	var line: Cells = lines[1]
	var shown: Array = line.get_children().map(func(part: Control) -> bool: return part.visible)
	_verdict.check(shown == [true, false, true] and line.get_widths().size() == 2 and line.get_child(2).position.x > 0.0 and line.get_child(2).position.x < line.size.x * 0.5, "road hidden: its part hidden, and risk moves up beside the id, taking a share: %s" % [shown])
	made.done()


func _an_edge_stands_in_each_gap_and_the_ground_follows_its_style() -> void:
	var made := Fixture.new(root)
	var columns := _columns(made, [0.3, 0.4, 0.3])
	var picked := Fixture.Model.new(made.chimes, REGION)
	picked.set_value(&"flag", Tables.CELLS)
	root.add_child(picked)
	var edges := [made.ui.text(""), made.ui.text(""), made.ui.text("")]
	made.ui.start(made.ui.app(&"app", [_line(made, columns, _samples(), Bound.constant("mill lane"), picked.of(&"flag"), edges)]))
	await _a_frame_passes()
	var line: Cells = _cells_in(root)[0]
	var gap := float(line.get_theme_constant(&"gap", Tables.CELLS))
	var first_end: float = line.get_widths()[0]
	var edge: Control = line.get_child(3)
	var shown_edges: Array = [line.get_child(3).visible, line.get_child(4).visible, line.get_child(5).visible]
	_verdict.check(is_equal_approx(edge.position.x, first_end) and is_equal_approx(edge.size.x, gap) and line.get_child(1).position.x >= edge.position.x + edge.size.x, "the first edge fills the gap between the first two cells and touches neither: %s" % [edge.get_rect()])
	_verdict.check(shown_edges == [true, true, false], "every column but the last has its edge: %s" % [shown_edges])
	made.commands.dispatch(REGION, TableColumns.TURNS, {"column": &"id"})
	await _a_frame_passes()
	var road_end: float = line.get_widths()[0]
	shown_edges = [line.get_child(3).visible, line.get_child(4).visible, line.get_child(5).visible]
	_verdict.check(shown_edges == [false, true, false] and is_equal_approx(line.get_child(4).position.x, road_end), "the id hidden, its edge goes with it and road's stands after road, where road now ends: %s" % [shown_edges])
	var placed := line.placed_count
	picked.set_value(&"flag", Tables.CELLS)
	await _a_frame_passes()
	_verdict.check(line.placed_count == placed, "the ground's bell ringing with the ground the same places nothing: %d times" % (line.placed_count - placed))
	picked.set_value(&"flag", Tables.PICKED)
	await _a_frame_passes()
	_verdict.check(line.theme_type_variation == Tables.PICKED and line.get_theme_stylebox(&"panel", Tables.PICKED) != line.get_theme_stylebox(&"panel", Tables.CELLS), "the bound ground moved to picked, and the line wears it: %s" % line.theme_type_variation)
	made.done()


## Every shown cell whose words are wider than the room its column gives it
## within the pad either side - words that run past it are drawn over the
## pad and the gap towards the next column: its words, what they need, and
## the room, as found.
func _words_past_their_columns(line: Cells) -> Array:
	var wrong: Array = []
	var parts: Array = line.get_children().filter(func(part: Control) -> bool: return part.visible)
	var room: Array = line.get_widths().map(func(width: float) -> float: return width - 2.0 * line.get_theme_constant(&"pad", Tables.CELLS))
	# every shown cell in its column's order, its words' width against the room inside its column
	for at: int in parts.size():
		var needs: float = (parts[at] as Text).get_child(0).get_minimum_size().x
		if needs > room[at]:
			wrong.append("%s needs %.0f in %.0f" % [(parts[at] as Text).get_text(), needs, room[at]])
	return wrong


## English to the pseudo-locale, the same phrases longer: the line measured
## in English is measured again and placed again - in the pseudo-locale,
## rather than taking the English measure kept on the samples - and back in
## English, the English measure is the one used.
func _columns_are_measured_in_the_language_on_and_again_when_it_changes() -> void:
	var made := Fixture.new(root)
	var columns := _columns(made, [0.45, 0.1, 0.45])
	var road := Phrase.of(LONG_ROAD)
	var samples := {&"id": {"words": ["PIPE-000001"]}, &"road": {"words": [road]}, &"risk": {"words": ["100.0"]}}
	var ui := made.ui
	var first := ui.cells([ui.text("PIPE-000001", Tables.WORDS), ui.text(road, Tables.WORDS), ui.text("12.5", Tables.WORDS)], NAMES, Bound.new(columns.get_shown), {samples = samples, words_kind = Tables.WORDS, ground = Tables.CELLS})
	ui.start(ui.app(&"app", [ui.column([first])]))
	await _a_frame_passes()
	var line: Cells = _cells_in(root)[0]
	var wide: float = line.get_widths()[1]
	var english: Array = _words_past_their_columns(line)
	_verdict.check(english.is_empty() and line.get_widths()[1] > 1200.0 * 0.1, "in English the road's column holds its words whole, wider than its share: %.0f, %s" % [line.get_widths()[1], english])
	made.commands.dispatch(Chimes.GLOBAL, Language.CHANGES_LANGUAGE, {"value": Language.PSEUDO})
	await _a_frame_passes()
	var pseudo := _words_past_their_columns(line)
	_verdict.check(pseudo.is_empty() and line.get_widths()[1] > wide, "in the pseudo-locale the same line measures the road again, wider, and no words run past their column towards the next: %.0f from %.0f, %s" % [line.get_widths()[1], wide, pseudo])
	made.commands.dispatch(Chimes.GLOBAL, Language.CHANGES_LANGUAGE, {"value": Language.SOURCE})
	await _a_frame_passes()
	_verdict.check(is_equal_approx(line.get_widths()[1], wide) and _words_past_their_columns(line).is_empty(), "back in English, the road's column is its English width again: %.0f" % line.get_widths()[1])
	made.done()
