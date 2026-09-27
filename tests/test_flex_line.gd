extends SceneTree

## What must be true of one line's lengths.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_flex_line.gd
##
## Every property here is a case from CSS Flexible Box Layout Level 1 § 9.7,
## asserted on numbers: what is spare is shared by grow, what is short is taken
## by shrink weighted by where each part started, a part held at its most hands
## the surplus back to the others, a part is never taken below what it needs,
## and factors under one between them - grow or shrink, read as the factors
## themselves and not as the shares they are weighed by - leave the rest of the
## room alone.
##
## Every expected length below is worked by hand from the specification, so a
## check disagreeing with the code is a question about which of the two is
## wrong rather than a description of what the code did.
##
## Nothing is in a tree and nothing is drawn: the subject is arithmetic, and a
## rect would only be somewhere else for the same numbers to hide in.

const FlexLine := preload("res://addons/gd_chime/components/primitives/flex_line.gd")
const Verdict := preload("res://tests/verdict.gd")

var _verdict := Verdict.new()


func _init() -> void:
	await _verdict.states(_what_is_spare_is_shared_by_grow)
	await _verdict.states(_a_part_with_no_factor_stays_where_it_starts)
	await _verdict.states(_what_is_short_is_taken_by_shrink_weighted_by_where_a_part_starts)
	await _verdict.states(_a_part_held_at_its_most_hands_the_surplus_to_the_others)
	await _verdict.states(_a_part_is_never_taken_below_what_it_needs)
	await _verdict.states(_factors_under_one_take_only_that_much_of_the_room)
	await _verdict.states(_shrink_factors_under_one_give_up_only_that_much_of_the_shortfall)
	await _verdict.states(_the_gaps_are_room_the_parts_cannot_have)
	await _verdict.states(_an_exact_fit_moves_nothing)
	await _verdict.states(_a_most_under_what_a_part_needs_still_gives_what_it_needs)
	quit(_verdict.deliver(get_script()))


## A part as the lengths are worked out from it.
func _part(base: float, grow: float, shrink: float, least: float = 0.0, most: float = INF) -> Dictionary:
	return {"base": base, "grow": grow, "shrink": shrink, "least": least, "most": most}


## Whether the lengths are the ones wanted, to the tolerance a float sum holds.
func _same(got: Array[float], wanted: Array) -> bool:
	if got.size() != wanted.size():
		return false
	# every length against the one worked by hand
	for at: int in got.size():
		if not is_equal_approx(got[at], wanted[at]):
			return false
	return true


## Room 300 over three parts starting at 50: 150 is spare, shared one part to
## two, so 50 and 100 are added to the first two.
func _what_is_spare_is_shared_by_grow() -> void:
	var line: Array = [_part(50.0, 1.0, 1.0), _part(50.0, 2.0, 1.0), _part(50.0, 0.0, 1.0)]

	var length := FlexLine.lengths(line, 300.0, 0.0)

	_verdict.check(_same(length, [100.0, 150.0, 50.0]), "one to two, and the third left alone: %s" % [length])


## The part with no grow is not merely last in line: it takes nothing at all,
## however much room there is.
func _a_part_with_no_factor_stays_where_it_starts() -> void:
	var line: Array = [_part(50.0, 0.0, 1.0), _part(50.0, 0.0, 1.0)]

	var length := FlexLine.lengths(line, 900.0, 0.0)

	_verdict.check(_same(length, [50.0, 50.0]), "900 of room and neither moved: %s" % [length])


## Shrink is weighted by where a part starts, so two parts shrinking as eagerly
## as each other each give the same FRACTION of themselves rather than the same
## number of pixels. One starts at 200 and the other at 100, in 200 of room:
## they give 66.7 and 33.3, ending a third smaller each. Weighting is the whole
## difference - without it they would give 50 apiece and end at 150 and 50.
func _what_is_short_is_taken_by_shrink_weighted_by_where_a_part_starts() -> void:
	var line: Array = [_part(200.0, 0.0, 1.0), _part(100.0, 0.0, 1.0)]

	var length := FlexLine.lengths(line, 200.0, 0.0)

	_verdict.check(_same(length, [400.0 / 3.0, 200.0 / 3.0]), "the long one gave twice what the short one did: %s" % [length])


## The case a single pass gets wrong. Two parts start at 50 in 300 of room, both
## growing at 1, but the first may not pass 80. A single pass stops at 80 and
## 150 and leaves 70 of the room empty; going round again gives that 70 to the
## part that can still take it.
func _a_part_held_at_its_most_hands_the_surplus_to_the_others() -> void:
	var line: Array = [_part(50.0, 1.0, 1.0, 0.0, 80.0), _part(50.0, 1.0, 1.0)]

	var length := FlexLine.lengths(line, 300.0, 0.0)

	_verdict.check(_same(length, [80.0, 220.0]), "the room the held part could not take went to the other: %s" % [length])
	_verdict.check(is_equal_approx(length[0] + length[1], 300.0), "and the line is full")


## The mirror of it: a part held at what it needs stops giving, and the rest of
## the shortfall is taken from the others.
func _a_part_is_never_taken_below_what_it_needs() -> void:
	var line: Array = [_part(100.0, 0.0, 1.0, 80.0), _part(100.0, 0.0, 1.0)]

	var length := FlexLine.lengths(line, 100.0, 0.0)

	_verdict.check(_same(length, [80.0, 20.0]), "one stopped at what it needs and the other gave the rest: %s" % [length])


## Factors under one between them share only that fraction of what is free, so
## a part growing at a half of 200 spare takes 100 and leaves the rest empty.
## Without the rule it takes the lot, which is the whole difference.
func _factors_under_one_take_only_that_much_of_the_room() -> void:
	var line: Array = [_part(100.0, 0.5, 1.0)]

	var length := FlexLine.lengths(line, 300.0, 0.0)

	_verdict.check(_same(length, [200.0]), "half of what was free, not all of it: %s" % [length])


## The same rule shrinking, and it reads the shrink FACTORS, not the shares they
## are weighed by. Two parts start at 100 in 150 of room, each shrinking at a
## quarter: a half between them, so they give up half of the 50 they are short -
## 12.5 each, ending at 87.5. Weighed first, the factors would be 25 apiece, the
## rule would never apply, and they would give up the lot and end at 75. What
## they do give up is still taken by where each started.
func _shrink_factors_under_one_give_up_only_that_much_of_the_shortfall() -> void:
	var line: Array = [_part(100.0, 0.0, 0.25), _part(100.0, 0.0, 0.25)]

	var length := FlexLine.lengths(line, 150.0, 0.0)

	_verdict.check(_same(length, [87.5, 87.5]), "half of what was short, not all of it: %s" % [length])

	var uneven: Array = [_part(200.0, 0.0, 0.25), _part(100.0, 0.0, 0.25)]

	var weighed := FlexLine.lengths(uneven, 200.0, 0.0)

	_verdict.check(_same(weighed, [500.0 / 3.0, 250.0 / 3.0]),
		"and half of 100 short, taken by where each started - the long one giving twice the short one's: %s" % [weighed])


## The gaps are not the parts' to share. The same two parts in the same room
## grow by 50 each with 100 of gap in it, where without the gap they grow by 100.
func _the_gaps_are_room_the_parts_cannot_have() -> void:
	var line: Array = [_part(50.0, 1.0, 1.0), _part(50.0, 1.0, 1.0)]

	var length := FlexLine.lengths(line, 300.0, 100.0)

	_verdict.check(_same(length, [100.0, 100.0]), "the parts grew into what the gap left: %s" % [length])


## Parts that already fill the room exactly are left alone, whatever their
## factors say - there is nothing to share and nothing to take.
func _an_exact_fit_moves_nothing() -> void:
	var line: Array = [_part(100.0, 1.0, 1.0), _part(100.0, 1.0, 1.0)]

	var length := FlexLine.lengths(line, 200.0, 0.0)

	_verdict.check(_same(length, [100.0, 100.0]), "neither grew nor shrank: %s" % [length])


## A part allowed less than it needs still gets what it needs: told it may have
## 30 while its own smallest size is 100, it is 100 and the line overflows. A
## part below what it needs is one nobody can read, and on a handheld there is
## no larger window to open instead.
func _a_most_under_what_a_part_needs_still_gives_what_it_needs() -> void:
	var line: Array = [_part(50.0, 1.0, 1.0, 100.0, 30.0)]

	var length := FlexLine.lengths(line, 300.0, 0.0)

	_verdict.check(_same(length, [100.0]), "what it needs, not what it was allowed: %s" % [length])
