extends SceneTree

## What must be true of the grid layout.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_grid.gd
##
## How wide a column is and which cell a part falls into belongs to
## grid_columns.gd and is proved in its own suite. What is proved here is
## everything this file decides: that the columns line up across every row,
## which is what a grid is FOR and what a wrapping line cannot do; how deep a
## row is; where a part sits down its row; that a part nobody can see takes no
## cell; that the engine re-places the parts when a part's smallest size
## changes, with nothing connected to it; and that a part placed again keeps
## the scale and turn its motion had reached.
##
## Every position and size below is worked by hand.

const Grid := preload("res://addons/gd_chime/components/primitives/grid.gd")
const Verdict := preload("res://tests/verdict.gd")

var _verdict := Verdict.new()


func _init() -> void:
	# the first frame's signal comes before any node has been processed; after it, one await is one processed frame
	await process_frame
	# the headless window is 64 by 64 and puts back a size set before the first frame, so it is sized now
	root.size = Vector2i(1400, 900)
	# the pointer tests measure in the window's own pixels: the base-size stretch the project sets is off here
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_declared_shares_place_the_parts_across_the_room)
	await _verdict.states(_the_columns_line_up_across_every_row)
	await _verdict.states(_auto_fitting_lays_a_field_out_and_wraps_it)
	await _verdict.states(_a_part_covering_two_columns_covers_the_gap_between_them)
	await _verdict.states(_a_row_is_as_deep_as_its_deepest_part)
	await _verdict.states(_align_places_a_part_down_its_row)
	await _verdict.states(_a_part_nobody_can_see_takes_no_cell)
	await _verdict.states(_its_own_smallest_size_holds_its_parts)
	await _verdict.states(_a_grid_still_waiting_for_its_parts_holds_the_room_it_was_given)
	await _verdict.states(_a_deeper_part_re_places_the_grid_and_two_changes_place_it_once)
	await _verdict.states(_a_part_covering_more_columns_than_there_are_covers_the_row)
	await _verdict.states(_a_fact_it_has_no_meaning_for_leaves_the_part_unplaced)
	await _verdict.states(_a_part_that_leaves_is_forgotten)
	await _verdict.states(_a_part_placed_again_keeps_the_scale_and_turn_its_motion_reached)
	quit(_verdict.deliver(get_script()))


## A grid in the tree, of the room given.
func _made(gap: float, row_gap: float, room: Vector2) -> Grid:
	var grid := Grid.new(gap, row_gap)
	grid.size = room
	root.add_child(grid)
	return grid


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


func _done(grid: Grid) -> void:
	grid.queue_free()
	await _a_frame_passes()


## Whether a part sits where it was meant to, at the size it was meant to be.
func _sits(part: Control, at: Vector2, of: Vector2) -> bool:
	return part.position.is_equal_approx(at) and part.size.is_equal_approx(of)


## Three columns at 2, 1 and 1 in 320 of room with two gaps of 10: 150, 75 and
## 75, each part starting past the ones before it and their gaps.
func _declared_shares_place_the_parts_across_the_room() -> void:
	var grid := _made(10.0, 10.0, Vector2(320, 200))
	grid.set_shares([2.0, 1.0, 1.0])
	var wide := _part(Vector2(0, 30))
	var middle := _part(Vector2(0, 30))
	var last := _part(Vector2(0, 30))
	grid.place(wide)
	grid.place(middle)
	grid.place(last)
	await _a_frame_passes()

	_verdict.check(_sits(wide, Vector2(0, 0), Vector2(150, 30)), "the first takes two shares: %s %s" % [wide.position, wide.size])
	_verdict.check(_sits(middle, Vector2(160, 0), Vector2(75, 30)), "the second one share, past the gap: %s %s" % [middle.position, middle.size])
	_verdict.check(_sits(last, Vector2(245, 0), Vector2(75, 30)), "and the third the same again: %s %s" % [last.position, last.size])
	await _done(grid)


## What a grid is FOR, and the one thing a wrapping line cannot do: the part in
## the second column of the second row is exactly under the part in the second
## column of the first, however different their own sizes are.
func _the_columns_line_up_across_every_row() -> void:
	var grid := _made(10.0, 10.0, Vector2(320, 300))
	grid.set_shares([1.0, 1.0])
	var narrow := _part(Vector2(20, 30))
	var above := _part(Vector2(40, 30))
	var wider := _part(Vector2(90, 30))
	var below := _part(Vector2(10, 30))
	grid.place(narrow)
	grid.place(above)
	grid.place(wider)
	grid.place(below)
	await _a_frame_passes()

	_verdict.check(above.position.x == below.position.x, "the second column starts in one place: %s and %s" % [above.position.x, below.position.x])
	_verdict.check(above.size.x == below.size.x, "and is one width: %s and %s" % [above.size.x, below.size.x])
	_verdict.check(narrow.position.x == wider.position.x, "as does the first: %s and %s" % [narrow.position.x, wider.position.x])
	await _done(grid)


## A field of things, reflowed with nothing written per screen size: 1000 of
## room with a gap of 20 holds three columns of at least 300, at 320 each, and
## the fourth part starts the next row.
func _auto_fitting_lays_a_field_out_and_wraps_it() -> void:
	var grid := _made(20.0, 20.0, Vector2(1000, 400))
	grid.set_auto_columns(300.0)
	var one := _part(Vector2(0, 50))
	var two := _part(Vector2(0, 50))
	var three := _part(Vector2(0, 50))
	var four := _part(Vector2(0, 50))
	grid.place(one)
	grid.place(two)
	grid.place(three)
	grid.place(four)
	await _a_frame_passes()

	_verdict.check(_sits(one, Vector2(0, 0), Vector2(320, 50)), "three of 320 fit: %s %s" % [one.position, one.size])
	_verdict.check(two.position.x == 340.0 and three.position.x == 680.0, "each past the last and its gap: %s %s" % [two.position.x, three.position.x])
	_verdict.check(_sits(four, Vector2(0, 70), Vector2(320, 50)), "and the fourth starts the next row: %s" % four.position)
	await _done(grid)


## A part covering two columns is as wide as both of them AND the gap between,
## because the gap is inside it rather than beside it.
func _a_part_covering_two_columns_covers_the_gap_between_them() -> void:
	var grid := _made(10.0, 10.0, Vector2(210, 200))
	grid.set_shares([1.0, 1.0])
	var heading := _part(Vector2(0, 20))
	var under := _part(Vector2(0, 20))
	grid.place(heading, {span = 2})
	grid.place(under)
	await _a_frame_passes()

	_verdict.check(_sits(heading, Vector2(0, 0), Vector2(210, 20)), "both columns and the gap: %s %s" % [heading.position, heading.size])
	_verdict.check(_sits(under, Vector2(0, 30), Vector2(100, 20)), "and the next part starts the row below: %s %s" % [under.position, under.size])
	await _done(grid)


## A row is as deep as its deepest part, and the next row starts below it and
## the row gap - so a grid of parts of different depths has no gaps torn in it.
func _a_row_is_as_deep_as_its_deepest_part() -> void:
	var grid := _made(0.0, 10.0, Vector2(200, 300))
	grid.set_shares([1.0, 1.0])
	var shallow := _part(Vector2(0, 20))
	var deep := _part(Vector2(0, 50))
	var below := _part(Vector2(0, 20))
	grid.place(shallow)
	grid.place(deep)
	grid.place(below)
	await _a_frame_passes()

	_verdict.check(shallow.size.y == 50.0, "the shallow part fills the row its neighbour set: %s" % shallow.size)
	_verdict.check(below.position.y == 60.0, "and the next row starts past the deepest and the gap: %s" % below.position)
	await _done(grid)


## Down its row a part fills it, or sits at the top, the middle or the bottom -
## and a part that is not stretched keeps its own depth.
func _align_places_a_part_down_its_row() -> void:
	var grid := _made(0.0, 0.0, Vector2(400, 200))
	grid.set_shares([1.0, 1.0, 1.0, 1.0])
	var filling := _part(Vector2(0, 20))
	var top := _part(Vector2(0, 20))
	var middle := _part(Vector2(0, 20))
	var bottom := _part(Vector2(0, 60))
	grid.place(filling, {align = Grid.STRETCH})
	grid.place(top, {align = Grid.START})
	grid.place(middle, {align = Grid.CENTER})
	grid.place(bottom, {align = Grid.END})
	await _a_frame_passes()

	_verdict.check(filling.size.y == 60.0, "stretched, it fills the row: %s" % filling.size)
	_verdict.check(top.position.y == 0.0 and top.size.y == 20.0, "at the top it keeps its own depth: %s %s" % [top.position, top.size])
	_verdict.check(middle.position.y == 20.0, "in the middle, the rest is shared above and below: %s" % middle.position)
	_verdict.check(bottom.position.y == 0.0, "and the deepest part is the row: %s" % bottom.position)
	await _done(grid)


## A part nobody can see takes no cell: the parts after it close up, rather than
## a hole being left where something invisible sits.
func _a_part_nobody_can_see_takes_no_cell() -> void:
	var grid := _made(10.0, 10.0, Vector2(210, 200))
	grid.set_shares([1.0, 1.0])
	var first := _part(Vector2(0, 20))
	var hidden := _part(Vector2(0, 20))
	var last := _part(Vector2(0, 20))
	grid.place(first)
	grid.place(hidden)
	grid.place(last)
	await _a_frame_passes()
	_verdict.check(last.position.y == 30.0, "all three shown, the last is on the second row: %s" % last.position)

	hidden.visible = false
	await _a_frame_passes()

	_verdict.check(_sits(last, Vector2(110, 0), Vector2(100, 20)), "hidden, the last takes the cell it left: %s" % last.position)
	await _done(grid)


## What it tells whatever holds it: the columns its parts need with the gaps
## between them, and every row deep enough for what is in it. The first column
## holds parts of 40 and 50 so it is 50, the second holds one of 60, and with
## the gap that is 120 across; the rows are 30 and 25 deep, 65 with the gap.
## With the columns declared this needs no width to work out, so a grid inside a
## layout is given what it needs without anyone saying so.
func _its_own_smallest_size_holds_its_parts() -> void:
	var grid := _made(10.0, 10.0, Vector2(400, 400))
	grid.set_shares([1.0, 1.0])
	grid.place(_part(Vector2(40, 20)))
	grid.place(_part(Vector2(60, 30)))
	grid.place(_part(Vector2(50, 25)))
	await _a_frame_passes()

	_verdict.check(grid.get_combined_minimum_size().is_equal_approx(Vector2(120, 65)),
		"the widest part in each column across, the deepest in each row down: %s" % grid.get_combined_minimum_size())
	await _done(grid)


## Nothing is connected to a part, yet a part growing deeper moves the row below
## it. Two changes in one frame are one placing, which is the engine's own
## coalescing and the reason no part needs watching.
func _a_deeper_part_re_places_the_grid_and_two_changes_place_it_once() -> void:
	var grid := _made(10.0, 10.0, Vector2(210, 300))
	grid.set_shares([1.0, 1.0])
	var first := _part(Vector2(0, 20))
	var second := _part(Vector2(0, 20))
	var below := _part(Vector2(0, 20))
	grid.place(first)
	grid.place(second)
	grid.place(below)
	await _a_frame_passes()
	var placings := grid.arrange_count

	first.custom_minimum_size = Vector2(0, 70)
	await _a_frame_passes()

	_verdict.check(below.position.y == 80.0, "the row below the part that grew has moved: %s" % below.position)
	_verdict.check(grid.arrange_count == placings + 1, "and it was placed once for the change: %d" % (grid.arrange_count - placings))

	placings = grid.arrange_count
	first.custom_minimum_size = Vector2(0, 90)
	second.custom_minimum_size = Vector2(0, 40)
	await _a_frame_passes()

	_verdict.check(below.position.y == 100.0, "two changes in one frame both land: %s" % below.position)
	_verdict.check(grid.arrange_count == placings + 1, "in one placing: %d" % (grid.arrange_count - placings))
	await _done(grid)


## A part asking for more columns than the grid has covers the row it is on,
## rather than reaching for a column that is not there.
func _a_part_covering_more_columns_than_there_are_covers_the_row() -> void:
	var grid := _made(10.0, 10.0, Vector2(210, 200))
	grid.set_shares([1.0, 1.0])
	var greedy := _part(Vector2(0, 20))
	grid.place(greedy, {span = 3})
	await _a_frame_passes()

	_verdict.check(_sits(greedy, Vector2(0, 0), Vector2(210, 20)), "it covers the two there are: %s %s" % [greedy.position, greedy.size])
	await _done(grid)


## A fact this layout has no meaning for is a mistake in whoever placed the
## part, so the part does not go in at all: laying it out on a guess would be a
## wrong screen nobody was told about.
func _a_fact_it_has_no_meaning_for_leaves_the_part_unplaced() -> void:
	var grid := _made(0.0, 0.0, Vector2(200, 200))
	grid.set_shares([1.0])
	var misspelt := _part(Vector2(20, 20))
	grid.place(misspelt, {spans = 2})
	await _a_frame_passes()

	_verdict.check(grid.get_child_count() == 0, "the part was not placed: %d" % grid.get_child_count())
	_verdict.check(misspelt.get_parent() == null, "and it is not in the tree")
	misspelt.free()
	await _done(grid)


## A grid waiting for its rows measures at nothing, which is the loading case:
## whoever builds it holds the room open, the grid above it sees that room, and
## the columns do not collapse and jump when the rows arrive.
func _a_grid_still_waiting_for_its_parts_holds_the_room_it_was_given() -> void:
	var waiting := Grid.new(0.0, 0.0)
	waiting.set_shares([1.0])
	waiting.custom_minimum_size = Vector2(300, 200)
	var outer := _made(0.0, 0.0, Vector2(800, 400))
	outer.set_shares([1.0])
	outer.place(waiting)
	await _a_frame_passes()

	_verdict.check(outer.get_combined_minimum_size().is_equal_approx(Vector2(300, 200)),
		"the room it holds open reaches the grid above: %s" % outer.get_combined_minimum_size())

	waiting.place(_part(Vector2(500, 40)))
	await _a_frame_passes()

	_verdict.check(outer.get_combined_minimum_size().is_equal_approx(Vector2(500, 200)),
		"a row wider than projected raises it, and its depth still stands: %s" % outer.get_combined_minimum_size())
	await _done(outer)


## A part's facts are held for as long as it is in the grid. Taken out, or
## moved to another parent, it is forgotten, so what is held never grows past
## the parts there are; and what is read is a copy, so reading changes nothing.
func _a_part_that_leaves_is_forgotten() -> void:
	var grid := _made(0.0, 0.0, Vector2(200, 200))
	grid.set_shares([1.0, 1.0])
	var elsewhere := Control.new()
	var taken_out := _part(Vector2(20, 20))
	var moved := _part(Vector2(20, 20))
	var staying := _part(Vector2(20, 20))
	grid.place(taken_out, {span = 2})
	grid.place(moved, {align = Grid.END})
	grid.place(staying, {align = Grid.START})
	_verdict.check(grid.get_facts(taken_out) == {span = 2}, "a part's facts are held while it is here: %s" % grid.get_facts(taken_out))
	var read := grid.get_facts(staying)
	read["align"] = Grid.CENTER
	_verdict.check(grid.get_facts(staying) == {align = Grid.START}, "and changing what was read changes nothing held: %s" % grid.get_facts(staying))

	grid.remove_child(taken_out)
	moved.reparent(elsewhere)
	await _a_frame_passes()

	_verdict.check(grid.get_facts(taken_out).is_empty(), "taken out, it is forgotten: %s" % grid.get_facts(taken_out))
	_verdict.check(grid.get_facts(moved).is_empty(), "moved to another parent, it is forgotten: %s" % grid.get_facts(moved))
	_verdict.check(grid.get_facts(staying) == {align = Grid.START}, "and the part still here keeps its own: %s" % grid.get_facts(staying))
	taken_out.free()
	elsewhere.free()
	await _done(grid)


## A part part way through a motion that scales or turns it is placed again
## at the scale and turn it has reached: a cell growing in, re-placed mid-way,
## is never drawn whole for a frame and then small again.
func _a_part_placed_again_keeps_the_scale_and_turn_its_motion_reached() -> void:
	var grid := _made(10.0, 10.0, Vector2(210, 200))
	grid.set_shares([1.0, 1.0])
	var part := _part(Vector2(0, 20))
	grid.place(part)
	await _a_frame_passes()
	part.scale = Vector2(0.5, 0.5)
	part.rotation = 0.25
	grid.queue_sort()
	await _a_frame_passes()
	_verdict.check(part.scale == Vector2(0.5, 0.5) and is_equal_approx(part.rotation, 0.25), "placed again, the part keeps the scale and turn it had reached: %s %s" % [part.scale, part.rotation])
	_verdict.check(_sits(part, Vector2(0, 0), Vector2(100, 20)), "and it is placed where its cell is: %s %s" % [part.position, part.size])
	await _done(grid)
