extends SceneTree

## What must be true of a grid's columns and cells.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_grid_columns.gd
##
## The arithmetic behind a grid, asserted on numbers: how many columns there
## are, which cell each part falls into, how wide each column ends up, and what
## a part covering several of them asks of the ones it covers - whether the
## columns are auto-fitted or declared as shares.
##
## Every expected number is worked by hand from CSS Grid Layout Level 1, so a
## check disagreeing with the code is a question about which of the two is
## wrong rather than a description of what the code did.

const GridColumns := preload("res://addons/gd_chime/components/primitives/grid_columns.gd")
const Verdict := preload("res://tests/verdict.gd")

var _verdict := Verdict.new()


func _init() -> void:
	await _verdict.states(_declared_shares_are_the_columns)
	await _verdict.states(_auto_fitting_takes_as_many_of_the_least_width_as_fit)
	await _verdict.states(_auto_fitting_takes_one_column_when_none_fits)
	await _verdict.states(_the_gaps_are_counted_in_how_many_columns_fit)
	await _verdict.states(_an_auto_fitted_column_is_never_narrower_than_the_widest_part)
	await _verdict.states(_an_auto_fitted_part_covering_several_columns_asks_them_together)
	await _verdict.states(_a_grid_nobody_finished_building_has_no_columns)
	await _verdict.states(_parts_fill_in_order_and_a_hole_stays_a_hole)
	await _verdict.states(_a_span_wider_than_the_grid_is_held_to_the_grid)
	await _verdict.states(_a_column_is_never_narrower_than_the_parts_in_it)
	await _verdict.states(_a_part_covering_several_columns_asks_them_together)
	await _verdict.states(_shares_are_of_what_is_left_after_the_gaps)
	quit(_verdict.deliver(get_script()))


## Whether the numbers are the ones worked by hand, to the tolerance a float sum holds.
func _same(got: Array, wanted: Array) -> bool:
	if got.size() != wanted.size():
		return false
	# every number against the one wanted
	for at: int in got.size():
		if got[at] is float and not is_equal_approx(got[at], wanted[at]):
			return false
		if got[at] is Vector2i and got[at] != wanted[at]:
			return false
	return true


## Declaring shares declares the columns: three shares are three columns.
func _declared_shares_are_the_columns() -> void:
	var shares: Array[float] = [2.0, 1.0, 1.0]

	_verdict.check(GridColumns.count(shares, 0.0, 1000.0, 10.0) == 3, "three shares, three columns")


## The whole of reflowing: 1000 of room with a gap of 20 holds three columns of
## at least 300, because a fourth would need 1280.
func _auto_fitting_takes_as_many_of_the_least_width_as_fit() -> void:
	var none: Array[float] = []

	_verdict.check(GridColumns.count(none, 300.0, 1000.0, 20.0) == 3, "three fit")
	_verdict.check(GridColumns.count(none, 300.0, 1300.0, 20.0) == 4, "a wider window holds four")
	_verdict.check(GridColumns.count(none, 300.0, 660.0, 20.0) == 2, "a handheld holds two")


## Narrower than one column, it is still one column: the parts overflow rather
## than the grid having no columns to put them in.
func _auto_fitting_takes_one_column_when_none_fits() -> void:
	var none: Array[float] = []

	_verdict.check(GridColumns.count(none, 300.0, 200.0, 0.0) == 1, "one column, not none")


## The gaps count against the columns. Two columns of 300 need 620 between
## them once the gap is counted, so 600 of room holds ONE - where counting the
## room alone would put two in and overflow the second.
func _the_gaps_are_counted_in_how_many_columns_fit() -> void:
	var none: Array[float] = []

	_verdict.check(GridColumns.count(none, 300.0, 600.0, 20.0) == 1, "600 does not hold two with a gap between them")
	_verdict.check(GridColumns.count(none, 300.0, 620.0, 20.0) == 2, "620 does, exactly")


## Auto-fitted columns are equal, and no narrower than the widest part in the
## grid: 1000 of room holds three columns of 320, but a part needing 400 makes
## every column 400 and the grid overflow - rather than that part overflowing
## into the one beside it, where it would sit on top of its neighbour.
func _an_auto_fitted_column_is_never_narrower_than_the_widest_part() -> void:
	var spans: Array[int] = [1, 1, 1]
	var needs: Array[float] = [400.0, 10.0, 10.0]
	var none: Array[float] = []
	var at := GridColumns.cells(spans, 3)

	var widths := GridColumns.widths(spans, needs, at, none, 300.0, 1000.0, 20.0)

	_verdict.check(_same(widths, [400.0, 400.0, 400.0]), "all three took the width the widest needed: %s" % [widths])


## A part covering several auto-fitted columns asks them TOGETHER, as it does
## declared shares. Four columns of 100 fit 400 of room, and a heading across all
## four needing 300 fits them as they are - asking each column for the whole 300
## would make the grid 1200 wide. A heading needing more than they hold widens
## each only by its part of what it needs, with the gaps inside it counted; and a
## heading asking for more columns than there are asks the ones there are.
func _an_auto_fitted_part_covering_several_columns_asks_them_together() -> void:
	var none: Array[float] = []
	var spans: Array[int] = [4]
	var at := GridColumns.cells(spans, 4)

	var needs: Array[float] = [300.0]
	var fits := GridColumns.widths(spans, needs, at, none, 100.0, 400.0, 0.0)
	_verdict.check(_same(fits, [100.0, 100.0, 100.0, 100.0]), "a heading the columns already hold leaves them as they are: %s" % [fits])

	var wider: Array[float] = [500.0]
	var widened := GridColumns.widths(spans, wider, at, none, 100.0, 460.0, 20.0)
	_verdict.check(_same(widened, [110.0, 110.0, 110.0, 110.0]), "one needing 500 across three gaps of 20 makes each 110: %s" % [widened])

	var beyond: Array[int] = [8]
	var more: Array[float] = [480.0]
	var held := GridColumns.widths(beyond, more, GridColumns.cells(beyond, 4), none, 100.0, 400.0, 0.0)
	_verdict.check(_same(held, [120.0, 120.0, 120.0, 120.0]), "and one asking for eight columns of four asks the four: %s" % [held])


## Neither shares nor a least width is a grid nobody finished building, and it
## says so by having no columns rather than by guessing at one.
func _a_grid_nobody_finished_building_has_no_columns() -> void:
	var none: Array[float] = []

	_verdict.check(GridColumns.count(none, 0.0, 500.0, 0.0) == 0, "no columns to place anything in")


## Parts take the next free cell in the order they were placed. The part
## covering two columns does not fit beside the first two, so it starts a row -
## and the cell it left empty stays empty rather than pulling a later part back.
func _parts_fill_in_order_and_a_hole_stays_a_hole() -> void:
	var spans: Array[int] = [1, 1, 2, 1]

	var at := GridColumns.cells(spans, 2)

	_verdict.check(_same(at, [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 0), Vector2i(2, 0)]),
		"two on the first row, the wide one on the second, the last below it: %s" % [at])


## A part asking for more columns than there are gets the ones there are.
func _a_span_wider_than_the_grid_is_held_to_the_grid() -> void:
	var spans: Array[int] = [3, 1]

	var at := GridColumns.cells(spans, 2)

	_verdict.check(_same(at, [Vector2i(0, 0), Vector2i(1, 0)]), "it took the row, and the next part went below: %s" % [at])


## A column holds what the parts in it need, whatever its share says. Two equal
## shares in 300 of room, with one part needing 400: that column is 400 and the
## grid overflows, because a part squeezed under what it needs is unreadable and
## on a handheld there is no larger window to open.
func _a_column_is_never_narrower_than_the_parts_in_it() -> void:
	var spans: Array[int] = [1, 1]
	var needs: Array[float] = [400.0, 100.0]
	var shares: Array[float] = [1.0, 1.0]
	var at := GridColumns.cells(spans, 2)

	var widths := GridColumns.widths(spans, needs, at, shares, 0.0, 300.0, 0.0)

	_verdict.check(_same(widths, [400.0, 100.0]), "each column holds its own part: %s" % [widths])


## A part covering two columns asks them TOGETHER. Two columns holding 60 each,
## with a gap of 20, already hold 140 of the 300 a spanning part needs, so only
## the other 160 is shared out - 80 each, ending at 140 apiece. Asking each
## column for the whole 300 is how one wide heading widens a whole table.
func _a_part_covering_several_columns_asks_them_together() -> void:
	var spans: Array[int] = [1, 1, 2]
	var needs: Array[float] = [60.0, 60.0, 300.0]
	var at := GridColumns.cells(spans, 2)

	var least := GridColumns.least_of(spans, needs, at, 2, 20.0)

	_verdict.check(_same(least, [140.0, 140.0]), "only what they lacked, shared between them: %s" % [least])
	_verdict.check(least[0] + least[1] + 20.0 == 300.0, "and between them they hold it exactly")


## Shares are of what is left AFTER the gaps, not of the room. Three columns at
## 2, 1 and 1 in 320 with two gaps of 10 share 300, so 150, 75 and 75.
func _shares_are_of_what_is_left_after_the_gaps() -> void:
	var spans: Array[int] = [1, 1, 1]
	var needs: Array[float] = [0.0, 0.0, 0.0]
	var shares: Array[float] = [2.0, 1.0, 1.0]
	var at := GridColumns.cells(spans, 3)

	var widths := GridColumns.widths(spans, needs, at, shares, 0.0, 320.0, 10.0)

	_verdict.check(_same(widths, [150.0, 75.0, 75.0]), "twice the width, then two alike: %s" % [widths])
