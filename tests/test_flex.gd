extends SceneTree

## What must be true of the flex layout.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_flex.gd
##
## How long a part is belongs to flex_line.gd and is proved in its own suite.
## What is proved here is everything this file decides: which parts are on a
## line, which way the line runs, where the leftover room goes, where a part
## sits across its line, that the tree is never reordered, that a part nobody
## can see takes no room, and that the engine re-places the parts when a part's
## smallest size changes without anything being connected to it; and that a
## part whose box draws past its edge - a shadow - is given that room.
##
## Every position and size below is worked by hand, so a check that disagrees
## with the code is a question about which of the two is wrong.
##
## A part is a bare Control with a smallest size, because what a part draws
## makes no difference to where it is put.

const Flex := preload("res://addons/gd_chime/components/primitives/flex.gd")
const Verdict := preload("res://tests/verdict.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Belfry := preload("res://addons/gd_chime/belfry.gd")
const Face := preload("res://addons/gd_chime/face.gd")
const Layout := preload("res://addons/gd_chime/components/primitives/layout.gd")

var _verdict := Verdict.new()


## A chip that may be chosen, as a look's picks are: a face drawn in its
## chosen box while chosen, else in its own.
class Chip extends Face:
	var chosen := false

	func get_state() -> StringName:
		return &"selected" if chosen else super.get_state()


## A chip counting how often its state is asked.
class Counted extends Chip:
	var asked := 0

	func get_state() -> StringName:
		asked += 1
		return super.get_state()


## A column, as described ones are, counting how often it is measured.
class Measured extends Layout:
	var measured := 0

	func _get_minimum_size() -> Vector2:
		measured += 1
		return super._get_minimum_size()


func _init() -> void:
	# the first frame's signal comes before any node has been processed; after it, one await is one processed frame
	await process_frame
	# the headless window is 64 by 64 and puts back a size set before the first frame, so it is sized now
	root.size = Vector2i(800, 800)
	# the pointer tests measure in the window's own pixels: the base-size stretch the project sets is off here
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_parts_take_what_they_need_and_the_gap_sits_between_them)
	await _verdict.states(_what_is_spare_goes_by_grow)
	await _verdict.states(_without_wrapping_they_share_one_line)
	await _verdict.states(_a_line_breaks_where_the_next_part_would_not_fit)
	await _verdict.states(_a_line_always_takes_one_part_however_narrow_the_room)
	await _verdict.states(_order_changes_the_line_and_not_the_tree)
	await _verdict.states(_justify_places_what_is_left_over)
	await _verdict.states(_align_places_a_part_across_its_line)
	await _verdict.states(_a_column_is_a_row_with_the_axes_swapped)
	await _verdict.states(_a_smaller_part_re_places_the_line_and_two_changes_place_it_once)
	await _verdict.states(_its_own_smallest_size_holds_its_parts)
	await _verdict.states(_wrapping_it_is_as_thick_as_its_lines_came_to_and_what_follows_sits_below_them)
	await _verdict.states(_a_layout_still_waiting_for_its_parts_holds_the_room_it_was_given)
	await _verdict.states(_a_part_nobody_can_see_takes_no_room)
	await _verdict.states(_a_fact_it_has_no_meaning_for_leaves_the_part_unplaced)
	await _verdict.states(_a_part_that_leaves_is_forgotten)
	await _verdict.states(_a_part_whose_box_draws_past_its_edge_is_given_that_room_and_a_wider_gap_moves_nothing)
	await _verdict.states(_room_is_kept_for_the_box_a_chip_stays_in_never_for_one_it_passes_through)
	await _verdict.states(_a_face_placed_again_and_again_asks_its_state_nothing_and_keeps_its_reach)
	await _verdict.states(_fifty_parts_hidden_in_one_frame_are_measured_once_and_placed_no_more_than_twice)
	await _verdict.states(_a_line_shown_again_with_nothing_moved_places_nothing)
	await _verdict.states(_a_wrapping_style_naming_a_least_column_lays_its_parts_in_equal_columns)
	quit(_verdict.deliver(get_script()))


## A wrapping row of seven parts under a style naming a least column of 100
## with a gap of 10: in 350 of room, three columns of 110 - (350 - 2 gaps) / 3
## - on three lines, the last part alone as wide as the rest and at the
## start; in 470, four columns; and the same row under a wrapping style
## naming none, every part its own length.
func _a_wrapping_style_naming_a_least_column_lays_its_parts_in_equal_columns() -> void:
	var theme := Theme.new()
	# two wrapping rows with a gap of 10, one naming a least column
	for style: StringName in [&"Cards", &"Loose"]:
		theme.set_type_variation(style, &"Container")
		theme.set_constant(&"gap", style, 10)
		theme.set_constant(&"wrap", style, 1)
		theme.set_constant(&"align", style, Flex.START)
	theme.set_constant(&"least_column", &"Cards", 100)
	var holder := Control.new()
	holder.theme = theme
	root.add_child(holder)
	var laid: Array = []
	# both styles, each a row of seven parts in 350 of room
	for style: StringName in [&"Cards", &"Loose"]:
		var row := Layout.new(Flex.ROW, style)
		holder.add_child(row)
		row.set_anchors_preset(Control.PRESET_TOP_LEFT)
		row.size = Vector2(350, 200)
		# seven parts, each needing less than a column
		for at: int in 7:
			row.place(_part(Vector2(50, 20)))
		laid.append(row)
	await _a_frame_passes()
	var cards: Array = laid[0].get_children()
	var widths: Array = cards.map(func(part: Control) -> float: return snappedf(part.size.x, 0.1))
	_verdict.check(widths.all(func(wide: float) -> bool: return is_equal_approx(wide, 110.0)), "every part is as wide as one of three columns, the last line's too: %s" % [widths])
	_verdict.check(cards[3].position == Vector2(0, 30) and cards[6].position == Vector2(0, 60) and absf(cards[2].position.x - 240.0) < 0.1, "three to a line, each line starting at the line's start: %s %s %s" % [cards[2].position, cards[3].position, cards[6].position])
	_verdict.check(laid[1].get_children().all(func(part: Control) -> bool: return part.size.x == 50.0), "a wrapping style naming no least column leaves every part its own length")
	laid[0].size = Vector2(470, 200)
	await _a_frame_passes()
	_verdict.check(cards[3].position.y == 0.0 and cards[4].position == Vector2(0, 30) and absf(cards[4].size.x - 110.0) < 0.1, "in 470 of room the columns follow the width - four of 110 - rather than the parts widening: %s %s" % [cards[4].position, cards[4].size])
	holder.queue_free()
	await _a_frame_passes()


## A layout in the tree, of the room given.
func _made(direction: int, wrapping: bool, gap: float, room: Vector2) -> Flex:
	var flex := Flex.new(direction, wrapping, gap)
	flex.size = room
	root.add_child(flex)
	return flex


## A part of the smallest size given, which is all a layout asks of one.
func _part(smallest: Vector2) -> Control:
	var part := Control.new()
	part.custom_minimum_size = smallest
	return part


## process_frame is emitted BEFORE nodes are processed, so the effect of a
## frame is only visible once the next one has come round.
func _a_frame_passes() -> void:
	await process_frame
	await process_frame


func _done(flex: Flex) -> void:
	flex.queue_free()
	await _a_frame_passes()


## A wrapping row of five parts in a column of room for two across: three
## lines. Its smallest size is the thickness of the three - so the part the
## column holds after it starts below the last line, never over it - and it
## grows and shrinks with the room its lines are placed in.
func _wrapping_it_is_as_thick_as_its_lines_came_to_and_what_follows_sits_below_them() -> void:
	var wrapping := Flex.new(Flex.ROW, true, 0.0)
	# five parts, two to a line in the room the column gives
	for at: int in 5:
		wrapping.place(_part(Vector2(100, 20)))
	var after := _part(Vector2(100, 20))
	var column := _made(Flex.COLUMN, false, 0.0, Vector2(250, 400))
	column.place(wrapping)
	column.place(after)
	await _a_frame_passes()
	await _a_frame_passes()
	_verdict.check(wrapping.get_combined_minimum_size().y == 60.0, "wrapped onto three lines, it needs the three lines' thickness: %s" % wrapping.get_combined_minimum_size())
	_verdict.check(after.position.y >= 60.0, "and the part after it sits below its last line, not over it: %s" % after.position.y)
	column.size = Vector2(550, 400)
	await _a_frame_passes()
	await _a_frame_passes()
	_verdict.check(wrapping.get_combined_minimum_size().y == 20.0 and after.position.y == 20.0, "given room for all five, one line, and what follows comes up to meet it: %s %s" % [wrapping.get_combined_minimum_size().y, after.position.y])
	await _done(column)


## Whether a part sits where it was meant to, at the size it was meant to be.
func _sits(part: Control, at: Vector2, of: Vector2) -> bool:
	return part.position.is_equal_approx(at) and part.size.is_equal_approx(of)


## Nothing declared at all: each part is as long as it needs to be, in the order
## it was placed, with the gap between one and the next.
func _parts_take_what_they_need_and_the_gap_sits_between_them() -> void:
	var flex := _made(Flex.ROW, false, 10.0, Vector2(300, 50))
	var first := _part(Vector2(40, 20))
	var second := _part(Vector2(60, 30))
	var third := _part(Vector2(50, 10))
	flex.place(first)
	flex.place(second)
	flex.place(third)
	await _a_frame_passes()

	_verdict.check(_sits(first, Vector2(0, 0), Vector2(40, 50)), "the first at the start: %s %s" % [first.position, first.size])
	_verdict.check(_sits(second, Vector2(50, 0), Vector2(60, 50)), "the second past it and the gap: %s" % second.position)
	_verdict.check(_sits(third, Vector2(120, 0), Vector2(50, 50)), "and the third past both: %s" % third.position)
	await _done(flex)


## Two parts of the same smallest size, one growing three times as eagerly as
## the other: the 200 that is spare arrives as 50 and 150.
func _what_is_spare_goes_by_grow() -> void:
	var flex := _made(Flex.ROW, false, 0.0, Vector2(300, 50))
	var steady := _part(Vector2(50, 10))
	var eager := _part(Vector2(50, 10))
	flex.place(steady, {grow = 1.0})
	flex.place(eager, {grow = 3.0})
	await _a_frame_passes()

	_verdict.check(_sits(steady, Vector2(0, 0), Vector2(100, 50)), "the steady one took a quarter of what was spare: %s" % steady.size)
	_verdict.check(_sits(eager, Vector2(100, 0), Vector2(200, 50)), "the eager one took the rest: %s %s" % [eager.position, eager.size])
	await _done(flex)


## Two parts each asking for the whole layout, with nowhere to wrap to: they
## share the one line and both give half of what they asked for.
func _without_wrapping_they_share_one_line() -> void:
	var flex := _made(Flex.ROW, false, 0.0, Vector2(100, 50))
	var left := _part(Vector2(0, 10))
	var right := _part(Vector2(0, 10))
	flex.place(left, {basis = 1.0})
	flex.place(right, {basis = 1.0})
	await _a_frame_passes()

	_verdict.check(_sits(left, Vector2(0, 0), Vector2(50, 50)), "the first gave half: %s" % left.size)
	_verdict.check(_sits(right, Vector2(50, 0), Vector2(50, 50)), "and the second sits beside it: %s %s" % [right.position, right.size])
	await _done(flex)


## Wrapping, a line takes what fits with its gaps counted and the rest start a
## new line below, as deep as the deepest part of the line above.
func _a_line_breaks_where_the_next_part_would_not_fit() -> void:
	var flex := _made(Flex.ROW, true, 10.0, Vector2(100, 100))
	var first := _part(Vector2(40, 20))
	var second := _part(Vector2(40, 20))
	var third := _part(Vector2(40, 20))
	flex.place(first)
	flex.place(second)
	flex.place(third)
	await _a_frame_passes()

	_verdict.check(_sits(first, Vector2(0, 0), Vector2(40, 20)), "two fit on the first line: %s" % first.position)
	_verdict.check(_sits(second, Vector2(50, 0), Vector2(40, 20)), "the second beside it: %s" % second.position)
	_verdict.check(_sits(third, Vector2(0, 30), Vector2(40, 20)), "and the third below them both: %s" % third.position)
	await _done(flex)


## A part wider than the room it is in has nowhere to go: it stays on its line
## at the size it says it needs, rather than being squeezed below it.
func _a_line_always_takes_one_part_however_narrow_the_room() -> void:
	var flex := _made(Flex.ROW, true, 10.0, Vector2(30, 50))
	var wide := _part(Vector2(40, 20))
	flex.place(wide)
	await _a_frame_passes()

	_verdict.check(_sits(wide, Vector2(0, 0), Vector2(40, 50)), "alone on its line at the size it needs: %s %s" % [wide.position, wide.size])
	await _done(flex)


## Order decides the line and nothing else. The part placed first is still the
## first child, so anything reading the tree sees what was built rather than
## what was arranged.
func _order_changes_the_line_and_not_the_tree() -> void:
	var flex := _made(Flex.ROW, false, 0.0, Vector2(300, 50))
	var placed_first := _part(Vector2(100, 10))
	var placed_second := _part(Vector2(100, 10))
	flex.place(placed_first, {order = 1.0})
	flex.place(placed_second, {order = 0.0})
	await _a_frame_passes()

	_verdict.check(placed_second.position.x == 0.0, "the later part is first on the line: %s" % placed_second.position)
	_verdict.check(placed_first.position.x == 100.0, "and the earlier one follows it: %s" % placed_first.position)
	_verdict.check(flex.get_child(0) == placed_first, "while the tree is as it was built")
	await _done(flex)


## Where the room nobody asked for goes. Two parts of 50 in 300 leave 200 over,
## and each way of spreading it is checked by where the parts land.
func _justify_places_what_is_left_over() -> void:
	var flex := _made(Flex.ROW, false, 0.0, Vector2(300, 50))
	var first := _part(Vector2(50, 10))
	var second := _part(Vector2(50, 10))
	flex.place(first)
	flex.place(second)
	await _a_frame_passes()
	_verdict.check(first.position.x == 0.0 and second.position.x == 50.0, "by default they sit at the start: %s %s" % [first.position, second.position])

	flex.justify = Flex.CENTER
	flex.queue_sort()
	await _a_frame_passes()
	_verdict.check(first.position.x == 100.0 and second.position.x == 150.0, "centred, half the room is on each side: %s" % first.position)

	flex.justify = Flex.END
	flex.queue_sort()
	await _a_frame_passes()
	_verdict.check(first.position.x == 200.0 and second.position.x == 250.0, "at the end, all of it is before them: %s" % first.position)

	flex.justify = Flex.BETWEEN
	flex.queue_sort()
	await _a_frame_passes()
	_verdict.check(first.position.x == 0.0 and second.position.x == 250.0, "between, all of it is in the middle: %s %s" % [first.position, second.position])

	flex.justify = Flex.AROUND
	flex.queue_sort()
	await _a_frame_passes()
	_verdict.check(first.position.x == 50.0 and second.position.x == 200.0, "around, each part has half a share on each side: %s %s" % [first.position, second.position])

	flex.justify = Flex.EVENLY
	flex.queue_sort()
	await _a_frame_passes()
	_verdict.check(is_equal_approx(first.position.x, 200.0 / 3.0), "evenly, the three spaces are equal: %s" % first.position)
	await _done(flex)


## Across its line a part fills the line, or sits at the near edge, the middle
## or the far edge of it - and a part that is not stretched keeps its own size.
func _align_places_a_part_across_its_line() -> void:
	var flex := _made(Flex.ROW, false, 0.0, Vector2(200, 100))
	var filling := _part(Vector2(40, 20))
	var near := _part(Vector2(40, 20))
	var middle := _part(Vector2(40, 20))
	var far := _part(Vector2(40, 20))
	flex.place(filling, {align = Flex.STRETCH})
	flex.place(near, {align = Flex.START})
	flex.place(middle, {align = Flex.CENTER})
	flex.place(far, {align = Flex.END})
	await _a_frame_passes()

	_verdict.check(_sits(filling, Vector2(0, 0), Vector2(40, 100)), "stretched, it fills the line: %s" % filling.size)
	_verdict.check(_sits(near, Vector2(40, 0), Vector2(40, 20)), "at the near edge it keeps its own size: %s %s" % [near.position, near.size])
	_verdict.check(_sits(middle, Vector2(80, 40), Vector2(40, 20)), "in the middle, the rest is shared above and below: %s" % middle.position)
	_verdict.check(_sits(far, Vector2(120, 80), Vector2(40, 20)), "and at the far edge it sits against it: %s" % far.position)
	await _done(flex)


## The same three parts down a column: each as deep as it needs, the gap between
## them, and every one of them as wide as the layout. A column is the row with
## the axes swapped and nothing else, which is why one algorithm serves both.
func _a_column_is_a_row_with_the_axes_swapped() -> void:
	var flex := _made(Flex.COLUMN, false, 10.0, Vector2(300, 300))
	var first := _part(Vector2(40, 20))
	var second := _part(Vector2(60, 30))
	var third := _part(Vector2(50, 10))
	flex.place(first)
	flex.place(second)
	flex.place(third)
	await _a_frame_passes()

	_verdict.check(_sits(first, Vector2(0, 0), Vector2(300, 20)), "the first at the top, across the width: %s %s" % [first.position, first.size])
	_verdict.check(_sits(second, Vector2(0, 30), Vector2(300, 30)), "the second below it and the gap: %s" % second.position)
	_verdict.check(_sits(third, Vector2(0, 70), Vector2(300, 10)), "and the third below both: %s" % third.position)
	await _done(flex)


## Nothing is connected to a part, yet a part growing out of its old size moves
## the ones after it. Two changes in one frame are one placing, which is the
## engine's own coalescing and the reason no part needs watching.
func _a_smaller_part_re_places_the_line_and_two_changes_place_it_once() -> void:
	var flex := _made(Flex.ROW, false, 0.0, Vector2(300, 50))
	var first := _part(Vector2(40, 20))
	var second := _part(Vector2(40, 20))
	flex.place(first)
	flex.place(second)
	await _a_frame_passes()
	var placings := flex.arrange_count

	first.custom_minimum_size = Vector2(90, 20)
	await _a_frame_passes()

	_verdict.check(second.position.x == 90.0, "the part after the one that grew has moved: %s" % second.position)
	_verdict.check(flex.arrange_count == placings + 1, "and it was placed once for the change: %d" % (flex.arrange_count - placings))

	placings = flex.arrange_count
	first.custom_minimum_size = Vector2(100, 20)
	second.custom_minimum_size = Vector2(60, 20)
	await _a_frame_passes()

	_verdict.check(second.position.x == 100.0 and second.size.x == 60.0, "two changes in one frame both land: %s %s" % [second.position, second.size])
	_verdict.check(flex.arrange_count == placings + 1, "in one placing: %d" % (flex.arrange_count - placings))

	placings = flex.arrange_count
	flex.size = Vector2(400, 50)
	await _a_frame_passes()
	_verdict.check(flex.arrange_count > placings, "and its own resize places the parts again")
	await _done(flex)


## What it tells whatever holds it: the smallest room its parts can be held in,
## gaps counted. A layout inside a layout is therefore given what it needs
## without anyone saying so, which is what makes a tree of them hold together.
func _its_own_smallest_size_holds_its_parts() -> void:
	var inner := Flex.new(Flex.ROW, false, 10.0)
	inner.place(_part(Vector2(40, 20)))
	inner.place(_part(Vector2(60, 30)))
	var outer := _made(Flex.ROW, false, 0.0, Vector2(400, 400))
	outer.place(inner)
	await _a_frame_passes()

	_verdict.check(inner.get_combined_minimum_size().is_equal_approx(Vector2(110, 30)), "both parts and the gap between them: %s" % inner.get_combined_minimum_size())
	_verdict.check(outer.get_combined_minimum_size().is_equal_approx(Vector2(110, 30)), "and it reaches the layout above: %s" % outer.get_combined_minimum_size())
	await _done(outer)


## A part nobody can see is not a gap in the line: the parts after it close up,
## because a hidden part is not a part of the line at all.
func _a_part_nobody_can_see_takes_no_room() -> void:
	var flex := _made(Flex.ROW, false, 10.0, Vector2(300, 50))
	var first := _part(Vector2(40, 20))
	var hidden := _part(Vector2(40, 20))
	var last := _part(Vector2(40, 20))
	flex.place(first)
	flex.place(hidden)
	flex.place(last)
	await _a_frame_passes()
	_verdict.check(last.position.x == 100.0, "all three shown, the last is past both: %s" % last.position)

	hidden.visible = false
	await _a_frame_passes()

	_verdict.check(last.position.x == 50.0, "hidden, the one after it closes up: %s" % last.position)
	await _done(flex)


## A fact this layout has no meaning for is a mistake in whoever placed the
## part, so the part does not go in at all: laying it out on a guess would be a
## wrong screen nobody was told about. A fraction outside the line is the same.
func _a_fact_it_has_no_meaning_for_leaves_the_part_unplaced() -> void:
	var flex := _made(Flex.ROW, false, 0.0, Vector2(300, 50))
	var misspelt := _part(Vector2(40, 20))
	var too_much := _part(Vector2(40, 20))
	flex.place(misspelt, {groww = 1.0})
	flex.place(too_much, {basis = 1.5})
	await _a_frame_passes()

	_verdict.check(flex.get_child_count() == 0, "neither part was placed: %d" % flex.get_child_count())
	_verdict.check(misspelt.get_parent() == null and too_much.get_parent() == null, "and neither is in the tree")
	misspelt.free()
	too_much.free()
	await _done(flex)


## A layout still waiting for its parts measures at nothing, so whoever builds
## it holds the room open - and the layout ABOVE it sees that room, which is
## what stops an arrangement being chosen on a screen that has not arrived. When
## the parts land, anything wider than was projected raises it.
func _a_layout_still_waiting_for_its_parts_holds_the_room_it_was_given() -> void:
	var waiting := Flex.new(Flex.COLUMN, false, 0.0)
	waiting.custom_minimum_size = Vector2(300, 200)
	var outer := _made(Flex.ROW, false, 0.0, Vector2(800, 400))
	outer.place(waiting, {grow = 1.0})
	await _a_frame_passes()

	_verdict.check(outer.get_combined_minimum_size().is_equal_approx(Vector2(300, 200)),
		"the room it holds open reaches the layout above: %s" % outer.get_combined_minimum_size())

	waiting.place(_part(Vector2(500, 40)))
	await _a_frame_passes()

	_verdict.check(outer.get_combined_minimum_size().is_equal_approx(Vector2(500, 200)),
		"a part wider than projected raises it, and its depth still stands: %s" % outer.get_combined_minimum_size())
	await _done(outer)


## A part's facts are held for as long as it is in the layout. Taken out, or
## moved to another parent, it is forgotten, so what is held never grows past
## the parts there are; and what is read is a copy, so reading changes nothing.
func _a_part_that_leaves_is_forgotten() -> void:
	var flex := _made(Flex.ROW, false, 0.0, Vector2(300, 50))
	var elsewhere := Control.new()
	var taken_out := _part(Vector2(40, 20))
	var moved := _part(Vector2(40, 20))
	var staying := _part(Vector2(40, 20))
	flex.place(taken_out, {grow = 1.0})
	flex.place(moved, {shrink = 0.5})
	flex.place(staying, {order = 2.0})
	_verdict.check(flex.get_facts(taken_out) == {grow = 1.0}, "a part's facts are held while it is here: %s" % flex.get_facts(taken_out))
	var read := flex.get_facts(staying)
	read["order"] = 9.0
	_verdict.check(flex.get_facts(staying) == {order = 2.0}, "and changing what was read changes nothing held: %s" % flex.get_facts(staying))

	flex.remove_child(taken_out)
	moved.reparent(elsewhere)
	await _a_frame_passes()

	_verdict.check(flex.get_facts(taken_out).is_empty(), "taken out, it is forgotten: %s" % flex.get_facts(taken_out))
	_verdict.check(flex.get_facts(moved).is_empty(), "moved to another parent, it is forgotten: %s" % flex.get_facts(moved))
	_verdict.check(flex.get_facts(staying) == {order = 2.0}, "and the part still here keeps its own: %s" % flex.get_facts(staying))
	taken_out.free()
	elsewhere.free()
	await _done(flex)


## A box of this size casting a shadow of this size, moved this much, as a
## look's soft box does - in a panel, which draws its box.
func _shadowed(smallest: Vector2, shadow: int, moved: Vector2) -> PanelContainer:
	var box := StyleBoxFlat.new()
	box.shadow_size = shadow
	box.shadow_offset = moved
	box.shadow_color = Color.WHITE
	var part := PanelContainer.new()
	part.add_theme_stylebox_override(&"panel", box)
	part.custom_minimum_size = smallest
	return part


## Words of at least this size, set at the left of their box.
func _words(said: String, smallest: Vector2) -> Label:
	var words := Label.new()
	words.text = said
	words.custom_minimum_size = smallest
	return words


## Words over a box whose shadow is cast 12 up and 4 down, and words under
## it, in a column with a gap of 2: the box stands 12 below the words over
## it and the words under it 4 below the box, from the box's own numbers.
## Held inside a row inside the column it is given the same, as the row
## places it. A shadow that passes beside the words, or falls on a part
## that holds no words, is given no room; with a gap of 22 nothing moves;
## and nothing across the line.
func _a_part_whose_box_draws_past_its_edge_is_given_that_room_and_a_wider_gap_moves_nothing() -> void:
	var column := _made(Flex.COLUMN, false, 2.0, Vector2(300, 400))
	var over := _words("over the box", Vector2(100, 20))
	var boxed := _shadowed(Vector2(100, 30), 8, Vector2(0.0, -4.0))
	var under := _words("under the box", Vector2(100, 20))
	column.place(over)
	column.place(boxed)
	column.place(under)
	await _a_frame_passes()
	_verdict.check(is_equal_approx(boxed.position.y - over.get_rect().end.y, 12.0) and is_equal_approx(under.position.y - boxed.get_rect().end.y, 4.0), "the box is given the 12 its shadow is cast up over the words above and the 4 it is cast down: %s then %s" % [boxed.position.y - over.get_rect().end.y, under.position.y - boxed.get_rect().end.y])
	_verdict.check(is_equal_approx(column.get_combined_minimum_size().y, over.size.y + 12.0 + 30.0 + 4.0 + under.size.y), "and the room it needs counts it: %s" % column.get_combined_minimum_size().y)
	var held := _made(Flex.COLUMN, false, 2.0, Vector2(300, 400))
	var words := _words("over the row", Vector2(100, 20))
	var row := Flex.new(Flex.ROW, false, 0.0)
	# the row whole before it is placed, so the column learns what it needs before the row has placed a part
	row.place(_shadowed(Vector2(60, 30), 8, Vector2(0.0, -4.0)))
	row.place(_part(Vector2(60, 30)))
	held.place(words)
	held.place(row)
	await _a_frame_passes()
	await _a_frame_passes()
	_verdict.check(is_equal_approx(row.position.y - words.get_rect().end.y, 12.0), "held in a row in the column, the box is given the same room from the words over the row: %s" % (row.position.y - words.get_rect().end.y))
	var beside := _made(Flex.COLUMN, false, 2.0, Vector2(300, 400))
	var short := _words("ab", Vector2(0, 20))
	var right := Flex.new(Flex.ROW, false, 0.0)
	# a box standing at the right of the row, clear across the line of the short words over it
	right.place(_part(Vector2(200, 30)))
	right.place(_shadowed(Vector2(60, 30), 8, Vector2(0.0, -4.0)))
	beside.place(short)
	beside.place(right)
	await _a_frame_passes()
	await _a_frame_passes()
	_verdict.check(is_equal_approx(right.position.y - short.get_rect().end.y, 2.0), "a shadow cast up beside the words, not across them, is given no room: %s" % (right.position.y - short.get_rect().end.y))
	var bare := _made(Flex.COLUMN, false, 2.0, Vector2(300, 400))
	var nothing_said := _part(Vector2(100, 20))
	bare.place(nothing_said)
	bare.place(_shadowed(Vector2(100, 30), 8, Vector2(0.0, -4.0)))
	await _a_frame_passes()
	_verdict.check(is_equal_approx(bare.get_child(1).position.y - nothing_said.get_rect().end.y, 2.0), "nor one cast over a part with no words in it: %s" % (bare.get_child(1).position.y - nothing_said.get_rect().end.y))
	var deep := _made(Flex.COLUMN, false, 2.0, Vector2(300, 400))
	var padded := PanelContainer.new()
	var margin := StyleBoxEmpty.new()
	# the words set 8 in from the foot of what holds them
	margin.content_margin_bottom = 8.0
	padded.add_theme_stylebox_override(&"panel", margin)
	padded.add_child(_words("set in", Vector2(100, 20)))
	deep.place(padded)
	deep.place(_shadowed(Vector2(100, 30), 8, Vector2(0.0, -4.0)))
	await _a_frame_passes()
	await _a_frame_passes()
	_verdict.check(is_equal_approx(deep.get_child(1).position.y - padded.get_rect().end.y, 4.0), "words set 8 in from the edge are given only the 4 of the 12 that would reach them: %s" % (deep.get_child(1).position.y - padded.get_rect().end.y))
	await _done(deep)
	column.set_gap(22.0)
	await _a_frame_passes()
	_verdict.check(is_equal_approx(boxed.position.y - over.get_rect().end.y, 22.0) and is_equal_approx(under.position.y - boxed.get_rect().end.y, 22.0), "with a gap of 22 already wider than the shadow, the gap is all there is: %s then %s" % [boxed.position.y - over.get_rect().end.y, under.position.y - boxed.get_rect().end.y])
	var across := _made(Flex.ROW, false, 2.0, Vector2(300, 100))
	var side_words := _words("beside", Vector2(60, 20))
	across.place(side_words)
	across.place(_shadowed(Vector2(60, 30), 8, Vector2(0.0, -4.0)))
	await _a_frame_passes()
	_verdict.check(is_equal_approx(across.get_child(1).position.x - side_words.get_rect().end.x, 8.0) and is_equal_approx(across.get_combined_minimum_size().y, 30.0), "along a row the words beside the box are given what its shadow casts sideways, 8, and nothing across the row: %s, %s" % [across.get_child(1).position.x - side_words.get_rect().end.x, across.get_combined_minimum_size().y])
	await _done(column)
	await _done(held)
	await _done(beside)
	await _done(bare)
	await _done(across)


## Words over a chip: at rest it casts its light 12 up over them and is
## given that room; chosen, it is drawn flat and casts none, and the line
## takes the room back; pointed at, it casts further, but only passing
## through, so nothing moves.
func _room_is_kept_for_the_box_a_chip_stays_in_never_for_one_it_passes_through() -> void:
	var look := Theme.new()
	var cast := func(size: int) -> StyleBoxFlat:
		var box := StyleBoxFlat.new()
		box.shadow_size = size
		box.shadow_offset = Vector2(0.0, -4.0)
		box.shadow_color = Color.WHITE
		return box
	look.set_type_variation(&"Chip", &"Control")
	look.set_stylebox(&"normal", &"Chip", cast.call(8))
	look.set_stylebox(&"hover", &"Chip", cast.call(16))
	look.set_stylebox(&"selected", &"Chip", StyleBoxFlat.new())
	var column := _made(Flex.COLUMN, false, 2.0, Vector2(300, 400))
	column.theme = look
	var over := _words("chosen or not", Vector2(100, 20))
	var chip := Chip.new(Chimes.new(Belfry.new()), Chimes.GLOBAL, &"Chip")
	chip.custom_minimum_size = Vector2(100, 30)
	column.place(over)
	column.place(chip)
	await _a_frame_passes()
	_verdict.check(is_equal_approx(chip.position.y - over.get_rect().end.y, 12.0), "a chip at rest casting its light 12 up over the words is given that room: %s" % (chip.position.y - over.get_rect().end.y))
	chip.hovered(true)
	await _a_frame_passes()
	_verdict.check(is_equal_approx(chip.position.y - over.get_rect().end.y, 12.0), "pointed at, casting 20, it is only passing through, and nothing moves: %s" % (chip.position.y - over.get_rect().end.y))
	chip.hovered(false)
	chip.chosen = true
	chip.needs_refresh()
	await _a_frame_passes()
	await _a_frame_passes()
	_verdict.check(is_equal_approx(chip.position.y - over.get_rect().end.y, 2.0), "chosen, drawn flat and casting nothing, it gives the words above no room past the gap: %s" % (chip.position.y - over.get_rect().end.y))
	await _done(column)


## A column of sixty, fifty of them hidden in one frame - a search keeping
## ten cards - and shown again: each time the column is measured once, and
## places its parts at most twice - for the parts that changed, and again
## for the size the column holding it then gives it - however many parts
## changed; never once a part.
func _fifty_parts_hidden_in_one_frame_are_measured_once_and_placed_no_more_than_twice() -> void:
	var column := Measured.new(Flex.COLUMN, &"Column")
	var holder := Layout.new(Flex.COLUMN, &"Column")
	root.add_child(holder)
	holder.place(column)
	var parts: Array = []
	# sixty parts, each a line of words
	for at: int in 60:
		parts.append(_words("card %d" % at, Vector2(100, 10)))
		column.place(parts[-1])
	await _a_frame_passes()
	await _a_frame_passes()
	var measured := column.measured
	var placed := column.arrange_count
	# fifty hidden in the one frame
	for part: Control in parts.slice(0, 50):
		part.visible = false
	await _a_frame_passes()
	await _a_frame_passes()
	_verdict.check(column.measured - measured == 1 and column.arrange_count - placed <= 2, "fifty hidden in one frame: measured %d times, placed %d times" % [column.measured - measured, column.arrange_count - placed])
	measured = column.measured
	placed = column.arrange_count
	# and shown again, in the one frame
	for part: Control in parts.slice(0, 50):
		part.visible = true
	await _a_frame_passes()
	await _a_frame_passes()
	_verdict.check(column.measured - measured == 1 and column.arrange_count - placed <= 2, "shown again in one frame: measured %d times, placed %d times" % [column.measured - measured, column.arrange_count - placed])
	await _done(holder)


## A column in a column, hidden and shown again as a search hides a card:
## nothing it holds has moved, so it places nothing - the engine sorts it as
## it shows - and every part stands where it stood; a part grown then places
## the line again, and what follows it moves down.
func _a_line_shown_again_with_nothing_moved_places_nothing() -> void:
	var holder := _made(Flex.COLUMN, false, 2.0, Vector2(300, 400))
	var inner := Flex.new(Flex.COLUMN, false, 2.0)
	var parts: Array = []
	# five parts, each a line's height
	for at: int in 5:
		parts.append(_part(Vector2(100, 20)))
		inner.place(parts[-1])
	holder.place(inner)
	await _a_frame_passes()
	var placed := inner.arrange_count
	var rects: Array = parts.map(func(part: Control) -> Rect2: return part.get_rect())
	inner.visible = false
	await _a_frame_passes()
	inner.visible = true
	await _a_frame_passes()
	_verdict.check(inner.arrange_count == placed and parts.map(func(part: Control) -> Rect2: return part.get_rect()) == rects, "shown again with nothing moved, it placed its parts %d more times, each where it stood" % (inner.arrange_count - placed))
	(parts[1] as Control).custom_minimum_size = Vector2(100, 50)
	await _a_frame_passes()
	_verdict.check(inner.arrange_count > placed and is_equal_approx((parts[2] as Control).position.y, 20.0 + 2.0 + 50.0 + 2.0), "a part grown, it places them again and the one after moves down: %s" % (parts[2] as Control).position.y)
	await _done(holder)


## A chip under words in a column resized five times, as a pane dragged
## resizes what it holds: the line places it again each time, and it is
## drawn again each time, and its state is asked not once; the room over it
## stays what its box casts.
func _a_face_placed_again_and_again_asks_its_state_nothing_and_keeps_its_reach() -> void:
	var look := Theme.new()
	var box := StyleBoxFlat.new()
	box.shadow_size = 8
	box.shadow_offset = Vector2(0.0, -4.0)
	box.shadow_color = Color.WHITE
	look.set_type_variation(&"Chip", &"Control")
	look.set_stylebox(&"normal", &"Chip", box)
	var column := _made(Flex.COLUMN, false, 2.0, Vector2(300, 400))
	column.theme = look
	var over := _words("over the chip", Vector2(100, 20))
	var chip := Counted.new(Chimes.new(Belfry.new()), Chimes.GLOBAL, &"Chip")
	chip.custom_minimum_size = Vector2(100, 30)
	column.place(over)
	column.place(chip)
	await _a_frame_passes()
	_verdict.check(is_equal_approx(column.get_combined_minimum_size().y, over.size.y + 12.0 + 30.0), "the room the column asks for counts the 12 the chip learned it casts as it placed its content: %s" % column.get_combined_minimum_size().y)
	var outer := _made(Flex.COLUMN, false, 2.0, Vector2(300, 400))
	outer.theme = look
	var words := _words("over the row", Vector2(100, 20))
	var row := Flex.new(Flex.ROW, false, 0.0)
	var held := Counted.new(Chimes.new(Belfry.new()), Chimes.GLOBAL, &"Chip")
	held.custom_minimum_size = Vector2(100, 30)
	row.place(held)
	outer.place(words)
	outer.place(row)
	await _a_frame_passes()
	await _a_frame_passes()
	_verdict.check(is_equal_approx(outer.get_combined_minimum_size().y, words.size.y + 12.0 + 30.0), "held in a row, the room the column asks for counts it too, once the row learns it: %s" % outer.get_combined_minimum_size().y)
	await _done(outer)
	var asked := chip.asked
	var placed := column.arrange_count
	# five widths, a frame each, as a drag gives them
	for width: float in [200.0, 220.0, 240.0, 260.0, 280.0]:
		column.size = Vector2(width, 400)
		await _a_frame_passes()
	_verdict.check(column.arrange_count >= placed + 5 and is_equal_approx(chip.size.x, 280.0), "the line placed the chip again at every width: %d placings, %s across" % [column.arrange_count - placed, chip.size.x])
	_verdict.check(chip.asked == asked, "and the chip, placed and drawn again five times, asked its state nothing: %d times" % (chip.asked - asked))
	_verdict.check(is_equal_approx(chip.get_reach(SIDE_TOP), 12.0) and is_equal_approx(chip.position.y - over.get_rect().end.y, 12.0), "its reach kept, the words over it still have the 12 it casts: %s" % (chip.position.y - over.get_rect().end.y))
	var sorted: Array = [0]
	chip.sort_children.connect(func() -> void: sorted[0] += 1)
	chip.hovered(true)
	await _a_frame_passes()
	chip.hovered(false)
	await _a_frame_passes()
	_verdict.check(sorted[0] == 0, "pointed at and left, drawn again in a box keeping the same room, it placed its content no more: %d times" % sorted[0])
	var roomier := box.duplicate()
	roomier.content_margin_top = 10.0
	look.set_stylebox(&"selected", &"Chip", roomier)
	chip.chosen = true
	chip.needs_refresh()
	await _a_frame_passes()
	_verdict.check(sorted[0] >= 1, "chosen, in a box keeping more room, it placed its content again: %d times" % sorted[0])
	await _done(column)
