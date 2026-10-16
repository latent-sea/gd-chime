extends SceneTree

## What must be true of the same parts in the first arrangement that fits:
## it wears the first, in the order preferred, whose least fits its width;
## it needs its narrowest across and would most like its first, so a line
## holding it narrows it into the arrangements after; given a most share of
## the safe height, it passes over one too tall for it and follows the safe
## room as it moves; it chooses again when a part's least moves with
## nothing resized; a row marked stacks is the row while it fits and a
## column of the same parts after; and by the width alone, the same parts
## need only their narrowest arrangement across.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_by_room.gd
##
## Each statement is in the floor's look, whose rows and columns keep 12
## pixels between parts, the pieces built into a host of a width the
## statement sets. Nothing moves: what is read after a change is what is
## there.

const Fixture := preload("res://tests/fixture.gd")
const Verdict := preload("res://tests/verdict.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")

## The gap the floor's look keeps between the parts of a row or a column.
const GAP := 12.0

var _verdict := Verdict.new()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(1600, 800)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_it_wears_the_first_arrangement_whose_least_fits_its_width)
	await _verdict.states(_it_needs_its_narrowest_across_and_would_most_like_its_first)
	await _verdict.states(_a_line_holding_it_narrows_it_into_the_arrangement_after)
	await _verdict.states(_given_a_most_share_of_the_safe_height_it_passes_over_one_too_tall)
	await _verdict.states(_it_chooses_again_when_a_part_s_least_moves_with_nothing_resized)
	await _verdict.states(_a_row_marked_stacks_is_the_row_while_it_fits_and_a_column_of_its_parts_after)
	await _verdict.states(_by_the_width_alone_the_parts_need_only_their_narrowest_arrangement_across)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## A plain control of this size under the root, for a piece to be built into.
func _host(of: Vector2) -> Control:
	var host := Control.new()
	host.size = of
	root.add_child(host)
	return host


## Two words side by side, one under the other second: the arrangements in the order preferred.
func _two(ui: RefCounted, first: Variant = "the first part", most_tall: float = 0.0) -> Desc:
	return ui.by_room({&"one": ui.text(first, Themes.WORDS).named(&"one"), &"two": ui.text("the second", Themes.WORDS).named(&"two")}, [ui.row_of([&"one", &"two"]), ui.column_of([&"one", &"two"])], most_tall).named(&"room")


func _it_wears_the_first_arrangement_whose_least_fits_its_width() -> void:
	var made := Fixture.new(root)
	var host := _host(Vector2(1500, 400))
	made.ui.build(_two(made.ui), host)
	await _a_frame_passes()
	var room: Control = made.ui.node_named(&"room")
	var one: Control = made.ui.node_named(&"one")
	var two: Control = made.ui.node_named(&"two")
	var along := one.get_combined_minimum_size().x + GAP + two.get_combined_minimum_size().x
	_verdict.check(room.get_worn() == &"0" and two.position.x > one.position.x and two.position.y == one.position.y, "with room for its parts side by side it wears the first, the row: %s, %s beside %s" % [room.get_worn(), two.position, one.position])
	host.size.x = along - 1.0
	await _a_frame_passes()
	_verdict.check(room.get_worn() == &"1" and two.position.y > one.position.y and two.position.x == one.position.x, "a pixel short of the row's least it wears the next, the column: %s, %s under %s" % [room.get_worn(), two.position, one.position])
	host.size.x = along
	await _a_frame_passes()
	_verdict.check(room.get_worn() == &"0", "and given the row's least again, the row: %s" % room.get_worn())
	host.free()
	made.done()


func _it_needs_its_narrowest_across_and_would_most_like_its_first() -> void:
	var made := Fixture.new(root)
	var host := _host(Vector2(1500, 400))
	made.ui.build(_two(made.ui), host)
	await _a_frame_passes()
	var room: Control = made.ui.node_named(&"room")
	var one: Control = made.ui.node_named(&"one")
	var two: Control = made.ui.node_named(&"two")
	var widest := maxf(one.get_combined_minimum_size().x, two.get_combined_minimum_size().x)
	_verdict.check(room.get_worn() == &"0" and is_equal_approx(room.get_combined_minimum_size().x, widest), "wearing the row, it needs across only what its narrowest arrangement, the column, needs: %s of %s" % [room.get_combined_minimum_size().x, widest])
	_verdict.check(is_equal_approx(room.preferred_size().x, one.preferred_size().x + GAP + two.preferred_size().x), "and would most like its first, the row, its parts at theirs: %s" % room.preferred_size().x)
	host.free()
	made.done()


func _a_line_holding_it_narrows_it_into_the_arrangement_after() -> void:
	var made := Fixture.new(root)
	var host := _host(Vector2(1500, 400))
	made.ui.build(made.ui.row([made.ui.text("beside it", Themes.WORDS).named(&"beside"), _two(made.ui)]), host)
	await _a_frame_passes()
	var room: Control = made.ui.node_named(&"room")
	var beside: Control = made.ui.node_named(&"beside")
	_verdict.check(room.get_worn() == &"0" and is_equal_approx(room.size.x, room.preferred_size().x), "in a row with room to spare it starts at what it would most like, its parts side by side: %s, %s of %s" % [room.get_worn(), room.size.x, room.preferred_size().x])
	host.size.x = beside.size.x + GAP + room.get_combined_minimum_size().x + 20.0
	await _a_frame_passes()
	_verdict.check(room.get_worn() == &"1" and room.size.x >= room.get_combined_minimum_size().x and room.get_rect().end.x <= host.size.x + 0.5, "narrowed by the row past its first, it wears the column inside the room the row gives it: %s, %s in %s" % [room.get_worn(), room.get_rect(), host.size.x])
	host.free()
	made.done()


func _given_a_most_share_of_the_safe_height_it_passes_over_one_too_tall() -> void:
	var made := Fixture.new(root)
	var host := _host(Vector2(1500, 400))
	made.ui.build(made.ui.by_room({&"one": made.ui.text("the first part", Themes.WORDS).named(&"one"), &"two": made.ui.text("the second", Themes.WORDS).named(&"two")}, [made.ui.column_of([&"one", &"two"]), made.ui.row_of([&"one", &"two"])], 0.1).named(&"room"), host)
	await _a_frame_passes()
	var room: Control = made.ui.node_named(&"room")
	var one: Control = made.ui.node_named(&"one")
	var down := 2.0 * one.get_combined_minimum_size().y + GAP
	_verdict.check(made.ui.shape.safe_size.read().y * 0.1 < down and room.get_worn() == &"1", "a column taller than a tenth of the safe height is passed over for the row, though it fits across: %s, %s needed of %s" % [room.get_worn(), down, made.ui.shape.safe_size.read().y * 0.1])
	root.size.y = int(down * 10.0) + 10
	await _a_frame_passes()
	_verdict.check(made.ui.shape.safe_size.read().y * 0.1 >= down and room.get_worn() == &"0", "and the safe room grown so the column is within a tenth of it, the column, with nothing it stands in resized: %s" % room.get_worn())
	root.size.y = 800
	await _a_frame_passes()
	host.free()
	made.done()


func _it_chooses_again_when_a_part_s_least_moves_with_nothing_resized() -> void:
	var made := Fixture.new(root)
	var model := Fixture.Model.new(made.chimes)
	model.set_value(&"words", "short")
	var host := _host(Vector2(600, 400))
	made.ui.build(_two(made.ui, model.of(&"words")), host)
	await _a_frame_passes()
	var room: Control = made.ui.node_named(&"room")
	var worn: StringName = room.get_worn()
	model.set_value(&"words", "a part that has grown far too long for a row")
	await _a_frame_passes()
	await _a_frame_passes()
	_verdict.check(worn == &"0" and room.get_worn() == &"1" and host.size.x == 600.0, "its first part said again too long for the row beside the other, it wears the column, nothing resized: %s then %s" % [worn, room.get_worn()])
	host.free()
	model.free()
	made.done()


func _a_row_marked_stacks_is_the_row_while_it_fits_and_a_column_of_its_parts_after() -> void:
	var made := Fixture.new(root)
	var host := _host(Vector2(1500, 400))
	var said := "words that wrap beside the label and grow"
	made.ui.build(made.ui.row([made.ui.text("LABEL", Themes.WORDS).named(&"label"), made.ui.text(said, Themes.WORDS).wraps().grow().named(&"words")]).stacks().named(&"room"), host)
	await _a_frame_passes()
	var room: Control = made.ui.node_named(&"room")
	var label: Control = made.ui.node_named(&"label")
	var words: Control = made.ui.node_named(&"words")
	_verdict.check(room.get_worn() == &"0" and is_equal_approx(words.get_rect().end.x, host.size.x) and words.position.y == label.position.y, "with room it is the row it was described as, its words growing to the end of it: %s, %s" % [room.get_worn(), words.get_rect()])
	host.size.x = label.size.x + GAP + words.get_combined_minimum_size().x - 1.0
	await _a_frame_passes()
	_verdict.check(room.get_worn() == &"1" and words.position.y > label.position.y and is_equal_approx(words.size.x, room.size.x), "a pixel short of the row's least it is a column of the same parts, the words across the whole of it: %s, %s under %s" % [room.get_worn(), words.get_rect(), label.get_rect()])
	host.free()
	made.done()


func _by_the_width_alone_the_parts_need_only_their_narrowest_arrangement_across() -> void:
	var made := Fixture.new(root)
	var host := _host(Vector2(1500, 400))
	var parts := [made.ui.text("the first part", Themes.WORDS).named(&"one"), made.ui.text("the second", Themes.WORDS).named(&"two")]
	made.ui.build(Desc.new(&"by_width", {"names": [&"one", &"two"], "arrangements": {&"across": made.ui.row_of([&"one", &"two"]), &"stacked": made.ui.column_of([&"one", &"two"])}, "breakpoints": {&"stacked": 0.0, &"across": 0.5}}, parts).named(&"width"), host)
	await _a_frame_passes()
	var width: Control = made.ui.node_named(&"width")
	var one: Control = made.ui.node_named(&"one")
	var two: Control = made.ui.node_named(&"two")
	_verdict.check(width.get_worn() == &"across" and is_equal_approx(width.get_combined_minimum_size().x, maxf(one.get_combined_minimum_size().x, two.get_combined_minimum_size().x)), "worn across, it needs across only what stacked needs, so whatever holds it may narrow it into that: %s" % width.get_combined_minimum_size().x)
	host.free()
	made.done()
