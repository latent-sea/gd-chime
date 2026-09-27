extends SceneTree

## What must be true of the long list.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_long_list.gd
##
## The list holds pages of a source near where it is looking, and where it is
## looking is its own. Proved here: a page lands later and only then is held;
## the look asks for its pages and one either side, each once; pages land in
## either order, each in its own place; never more than KEEP are held and the
## farthest goes first; a bell from the source resets it and a stale answer is
## dropped; PAGE_LANDED sounds on a landing and not otherwise; an index not
## held answers null; a reset asks again for the look's pages and asking again
## with nothing failed asks for nothing more and rings nothing; the look starts at the top and
## moves by command - a row, a page, any number of rows - never below zero,
## every command done; once the total is known the look stops where the rows
## still fill the screen, and a total that shrinks pulls it back on the next
## landing; and LOOK_MOVED sounds once whenever the first row changes,
## whatever moved it, and never for a move that went nowhere.
##
## And when the source could not give a page: it is known as failed, row by
## row, apart from a page still coming, and PAGE_FAILED sounds once; a look
## does not ask for it again, and asking again does; a failure a later look no
## longer covers is forgotten, so coming back asks again; and a reset forgets
## every failure, while a failure from before the reset is dropped.
##
## The source is stood in for by one that records every request and answers
## a request only when told to, in any order - so every property is about
## the list and none is about timing. A row is its own index, so what landed
## where is plain to check. The list shows four rows and its pages are four
## long, so a page is a screen.

const Belfry := preload("res://addons/gd_chime/belfry.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Commands := preload("res://addons/gd_chime/commands.gd")
const LongList := preload("res://addons/gd_chime/long_list.gd")
const Token := preload("res://addons/gd_chime/token.gd")
const Verdict := preload("res://tests/verdict.gd")

const REGION := &"a_screen"
const CHANGED := &"rows_changed"
const PAGE := 4
const KEEP := 4
const SHOWING := 4

var _verdict := Verdict.new()


class Ear extends RefCounted:
	var rings := 0

	func heard(_what: StringName) -> void:
		rings += 1


## Stands in for the source: records every request, and answers one only
## when told to, with the rows it asked for or with nothing.
class Source extends RefCounted:
	var length: int
	var requests: Array = []  # [first, count, answer], in the order asked

	func _init(rows: int) -> void:
		length = rows

	func fetch(first: int, count: int, answer: Callable) -> void:
		requests.append([first, count, answer])

	## Answer request number i. The rows are their own indices, up to the end.
	func deliver(i: int, could: bool) -> void:
		var request: Array = requests[i]
		var rows: Variant = null
		if could:
			rows = range(request[0], mini(request[0] + request[1], length))
		(request[2] as Callable).call(rows, length)

	## The first index of every request made, in order.
	func firsts() -> Array:
		var asked: Array = []
		# every request, taking where it started
		for request: Array in requests:
			asked.append(request[0])
		return asked


func _init() -> void:
	await _verdict.states(_a_page_asked_for_lands_later_and_only_then_is_held)
	await _verdict.states(_the_look_asks_for_its_pages_and_one_either_side_each_once)
	await _verdict.states(_two_pages_on_their_way_land_in_either_order_each_in_its_own_place)
	await _verdict.states(_never_more_than_keep_are_held_and_the_farthest_goes_first)
	await _verdict.states(_a_bell_from_the_source_resets_it_and_a_stale_answer_is_dropped)
	await _verdict.states(_page_landed_sounds_on_a_landing_and_not_otherwise)
	await _verdict.states(_an_index_not_held_answers_null_and_has_says_so)
	await _verdict.states(_a_reset_asks_again_for_the_look_and_asking_again_with_nothing_failed_asks_nothing)
	await _verdict.states(_the_look_starts_at_the_top_and_moves_by_command_never_below_zero)
	await _verdict.states(_the_look_stops_where_the_rows_still_fill_the_screen_once_the_total_is_known)
	await _verdict.states(_a_total_that_shrinks_pulls_the_look_back_on_the_next_landing)
	await _verdict.states(_look_moved_sounds_once_whenever_the_first_row_changes_whatever_moved_it)
	await _verdict.states(_a_page_the_source_could_not_give_is_known_as_failed_and_rings_once)
	await _verdict.states(_a_failed_page_is_not_asked_for_again_until_asked)
	await _verdict.states(_a_failure_a_later_look_no_longer_covers_is_forgotten)
	await _verdict.states(_a_reset_forgets_every_failure_and_a_stale_failure_is_dropped)
	await _verdict.states(_built_it_asks_nothing_until_told_to_look_and_dropped_it_forgets_and_asks_nothing)
	await _verdict.states(_an_answer_after_the_place_is_left_or_after_a_reset_lands_on_nothing)
	quit(_verdict.deliver(get_script()))


## A list over a source of this many rows, listening to the source's bell,
## with an ear on PAGE_LANDED and another on PAGE_FAILED, as a dictionary:
## list, source, ear, failures, chimes, commands. This test hangs the belfry
## and the source's bell by hand, standing in for whatever composes an
## application. Built and told to look, the list looks at the top and has
## asked for pages 0 and 1.
func _made(rows: int) -> Dictionary:
	var chimes := Chimes.new(Belfry.new())
	var commands := Commands.new(chimes)
	chimes.register(REGION, CHANGED)
	var source := Source.new(rows)
	var list := LongList.new(chimes, source.fetch, PAGE, KEEP, SHOWING, Bound.on_bell(func() -> Variant: return null, REGION, CHANGED))
	commands.stand(REGION, list)
	list.look(Token.new())
	var ear := Ear.new()
	chimes.listen(ear, list.region, LongList.PAGE_LANDED)
	var failures := Ear.new()
	chimes.listen(failures, list.region, LongList.PAGE_FAILED)
	return {"list": list, "source": source, "ear": ear, "failures": failures, "chimes": chimes, "commands": commands}


## The look moved by this many rows, as the wheel would move it.
func _scroll(made: Dictionary, by: int) -> void:
	(made["commands"] as Commands).dispatch(REGION, LongList.SCROLL_ROWS, {"by": by})


func _done(made: Dictionary) -> void:
	(made["list"] as Node).free()
	(made["commands"] as Node).free()


func _a_page_asked_for_lands_later_and_only_then_is_held() -> void:
	var made := _made(40)
	var list: LongList = made["list"]
	var source: Source = made["source"]
	_scroll(made, 4)

	_verdict.check(not list.has(4) and list.get_item(4) == null and list.count() == 0, "nothing is held within the call that looked")
	source.deliver(1, true)
	_verdict.check(list.has(4) and list.get_item(4) == 4 and list.get_item(7) == 7, "the page landed under its indices")
	_verdict.check(list.count() == 40, "and the total came with it")
	_verdict.check(not list.has(8), "and nothing beyond it is held")
	_done(made)


func _the_look_asks_for_its_pages_and_one_either_side_each_once() -> void:
	var made := _made(40)
	var source: Source = made["source"]

	_verdict.check(source.firsts() == [0, 4], "built at the top, the page shown and the one after are asked for: %s" % [source.firsts()])
	_scroll(made, 4)
	_verdict.check(source.firsts() == [0, 4, 8], "a page on, the page shown and one either side are asked for, the one before already asked: %s" % [source.firsts()])
	_scroll(made, 0)
	_verdict.check(source.firsts() == [0, 4, 8], "and a move that goes nowhere asks for nothing more")
	_scroll(made, 1)
	_verdict.check(source.firsts() == [0, 4, 8, 12], "a look that reaches one page further asks for that page only")
	_done(made)


func _two_pages_on_their_way_land_in_either_order_each_in_its_own_place() -> void:
	var made := _made(40)
	var list: LongList = made["list"]
	var source: Source = made["source"]
	_scroll(made, 4)

	source.deliver(2, true)
	source.deliver(0, true)

	_verdict.check(list.get_item(8) == 8 and list.get_item(11) == 11, "the page that landed first is where it belongs")
	_verdict.check(list.get_item(0) == 0 and list.get_item(3) == 3, "and so is the one that landed after")
	_verdict.check(not list.has(4), "and the one still on its way is not held")
	_done(made)


func _never_more_than_keep_are_held_and_the_farthest_goes_first() -> void:
	var made := _made(40)
	var list: LongList = made["list"]
	var source: Source = made["source"]
	_scroll(made, 4)
	source.deliver(0, true)
	source.deliver(1, true)
	source.deliver(2, true)
	_scroll(made, 16)
	source.deliver(3, true)
	_verdict.check(list.has(0) and list.has(16), "four pages held, the most there may be")

	source.deliver(4, true)
	_verdict.check(not list.has(0) and list.has(4) and list.has(20), "a fifth landing lets go of the farthest, page 0")
	source.deliver(5, true)
	_verdict.check(not list.has(4) and list.has(8) and list.has(24), "and the next lets go of the next farthest, page 1")
	_done(made)


## The A, B, A case: a request out across a change describes rows that no
## longer sit at those positions. The source's bell resets the list, which
## asks again for its look; the old answer is dropped and the new one is held.
func _a_bell_from_the_source_resets_it_and_a_stale_answer_is_dropped() -> void:
	var made := _made(40)
	var list: LongList = made["list"]
	var source: Source = made["source"]
	var ear: Ear = made["ear"]
	var chimes: Chimes = made["chimes"]
	_scroll(made, 4)
	source.deliver(1, true)
	_verdict.check(list.has(4) and ear.rings == 1, "a page is held, and rang once")

	chimes.strike(REGION, CHANGED)

	_verdict.check(not list.has(4) and list.count() == 0, "the bell forgot everything")
	_verdict.check(source.firsts() == [0, 4, 8, 0, 4, 8], "and the pages of the look were asked for again")
	source.deliver(0, true)
	_verdict.check(not list.has(0) and ear.rings == 1, "an answer to a request from before the bell is dropped, and rings nothing")
	source.deliver(4, true)
	_verdict.check(list.has(4) and ear.rings == 2, "and an answer to a request from after it is held, and rings")
	_done(made)


func _page_landed_sounds_on_a_landing_and_not_otherwise() -> void:
	var made := _made(40)
	var source: Source = made["source"]
	var ear: Ear = made["ear"]
	var chimes: Chimes = made["chimes"]

	_scroll(made, 4)
	_verdict.check(ear.rings == 0, "not on a look")
	source.deliver(1, true)
	_verdict.check(ear.rings == 1, "once on a landing")
	chimes.strike(REGION, CHANGED)
	_verdict.check(ear.rings == 1, "not on a reset")
	source.deliver(0, true)
	_verdict.check(ear.rings == 1, "not for an answer that was dropped")
	source.deliver(4, false)
	_verdict.check(ear.rings == 1, "not for an answer of null")
	source.deliver(3, true)
	_verdict.check(ear.rings == 2, "and once more on the next landing")
	_done(made)


## Past the end is not held even when the page it would fall on is: the last
## page of a list of ten is two rows long, and the eleventh row is nowhere.
func _an_index_not_held_answers_null_and_has_says_so() -> void:
	var made := _made(10)
	var list: LongList = made["list"]
	var source: Source = made["source"]
	_scroll(made, 8)
	source.deliver(2, true)

	_verdict.check(list.has(9) and list.get_item(9) == 9, "the last row is held")
	_verdict.check(not list.has(10) and list.get_item(10) == null, "the row past the end is not, though its page is")
	_verdict.check(not list.has(0) and list.get_item(0) == null, "and a row whose page has not landed is not")
	_done(made)


## The look is always there, so a reset always has pages to ask for again;
## asking again is for failures, and with none it asks for nothing more.
func _a_reset_asks_again_for_the_look_and_asking_again_with_nothing_failed_asks_nothing() -> void:
	var made := _made(40)
	var source: Source = made["source"]
	var chimes: Chimes = made["chimes"]
	var commands: Commands = made["commands"]

	_verdict.check(commands.dispatch(REGION, LongList.ASK_AGAIN, {}) == null and source.firsts() == [0, 4], "asking again with nothing failed is done and asks for nothing more: %s" % [source.firsts()])
	chimes.strike(REGION, CHANGED)
	_verdict.check(source.firsts() == [0, 4, 0, 4], "a bell before anything landed asks for the look's pages again: %s" % [source.firsts()])
	_done(made)


func _the_look_starts_at_the_top_and_moves_by_command_never_below_zero() -> void:
	var made := _made(40)
	var list: LongList = made["list"]
	var commands: Commands = made["commands"]

	_verdict.check(list.get_first() == 0 and list.get_showing() == SHOWING, "built, it looks at the top and shows as many rows as it was built to")
	_verdict.check(commands.dispatch(REGION, LongList.SCROLL_ROW_DOWN, {}) == null and list.get_first() == 1, "a row down, done")
	_verdict.check(commands.dispatch(REGION, LongList.SCROLL_PAGE_DOWN, {}) == null and list.get_first() == 5, "a page down moves by the rows shown, done")
	_verdict.check(commands.dispatch(REGION, LongList.SCROLL_PAGE_UP, {}) == null and list.get_first() == 1, "a page up, done")
	_verdict.check(commands.dispatch(REGION, LongList.SCROLL_ROW_UP, {}) == null and list.get_first() == 0, "a row up, done")
	_verdict.check(str(commands.dispatch(REGION, LongList.SCROLL_ROW_UP, {})) == "Already at the top" and list.get_first() == 0, "a row up at the top is refused before it runs: it would go nowhere")
	_verdict.check(commands.dispatch(REGION, LongList.SCROLL_ROWS, {"by": 3}) == null and list.get_first() == 3, "any number of rows, done")
	_verdict.check(commands.dispatch(REGION, LongList.SCROLL_ROWS, {"by": -30}) == null and list.get_first() == 0, "and never below zero")
	_done(made)


func _the_look_stops_where_the_rows_still_fill_the_screen_once_the_total_is_known() -> void:
	var made := _made(40)
	var list: LongList = made["list"]
	var source: Source = made["source"]

	_scroll(made, 100)
	_verdict.check(list.get_first() == 100, "before the total is known there is no end to stop at")
	source.deliver(0, true)
	_verdict.check(list.get_first() == 40 - SHOWING, "the first landing brings the total, and the look comes back to the last first row that fills the screen")
	_scroll(made, 1)
	_verdict.check(list.get_first() == 40 - SHOWING, "and it will not be pushed past it")
	_done(made)


## The list was 40 rows; the source's bell says it changed, and it is now 10.
func _a_total_that_shrinks_pulls_the_look_back_on_the_next_landing() -> void:
	var made := _made(40)
	var list: LongList = made["list"]
	var source: Source = made["source"]
	var chimes: Chimes = made["chimes"]
	source.deliver(0, true)
	_scroll(made, 36)
	_verdict.check(list.get_first() == 36, "scrolled to the end of forty")

	source.length = 10
	chimes.strike(REGION, CHANGED)
	# every request, those made as the look comes back included, answered against the new length
	var i := 0
	while i < source.requests.size():
		source.deliver(i, true)
		i += 1

	_verdict.check(list.get_first() == 6, "ten rows now: the look came back to the last first row that fills the screen")
	_verdict.check(list.get_item(6) == 6 and list.get_item(9) == 9, "and the end of the shorter list is held")
	_done(made)


## Whatever depends on where the list looks hears it move, whatever moved it,
## and hears nothing for a move that went nowhere.
func _look_moved_sounds_once_whenever_the_first_row_changes_whatever_moved_it() -> void:
	var made := _made(40)
	var source: Source = made["source"]
	var chimes: Chimes = made["chimes"]
	var commands: Commands = made["commands"]
	var list: LongList = made["list"]
	var moves := Ear.new()
	chimes.listen(moves, list.region, LongList.LOOK_MOVED)
	source.deliver(0, true)
	_verdict.check(moves.rings == 0, "built at the top and a page landed there: nothing moved and nothing rang")

	commands.dispatch(REGION, LongList.SCROLL_ROW_UP, {})
	_verdict.check(moves.rings == 0, "a row up at the top is refused and rings nothing")
	commands.dispatch(REGION, LongList.SCROLL_PAGE_DOWN, {})
	_verdict.check(moves.rings == 1, "a page down rings once")
	_scroll(made, 2)
	_verdict.check(moves.rings == 2, "the wheel's rows ring once too")
	_scroll(made, 100)
	source.length = 10
	chimes.strike(REGION, CHANGED)
	var rung := moves.rings
	# every request, those made as the look comes back included, answered against the new length
	var i := 0
	while i < source.requests.size():
		source.deliver(i, true)
		i += 1
	_verdict.check(moves.rings == rung + 1, "and a landing that pulls it back when the list shrinks rings once: %d" % moves.rings)
	_done(made)


## A page the source could not give is not the same as one still coming, and a
## screen must be able to tell them apart to show the failure where it happened.
## Every row of the failed page says so, a row of a page still coming does not,
## and PAGE_FAILED sounds once - while PAGE_LANDED, which is about rows arriving,
## does not.
func _a_page_the_source_could_not_give_is_known_as_failed_and_rings_once() -> void:
	var made := _made(40)
	var list: LongList = made["list"]
	var source: Source = made["source"]
	var ear: Ear = made["ear"]
	var failures: Ear = made["failures"]
	_scroll(made, 4)

	source.deliver(1, false)

	_verdict.check(list.has_failed(4) and list.has_failed(7), "every row of the page that could not come says so")
	_verdict.check(not list.has(4), "and none of it is held")
	_verdict.check(not list.has_failed(0) and not list.has(0), "while a row of a page still coming is neither held nor failed")
	_verdict.check(failures.rings == 1 and ear.rings == 0, "and PAGE_FAILED sounded once, PAGE_LANDED not at all: %d and %d" % [failures.rings, ear.rings])
	_done(made)


## A failed page is left as failed while it is looked at, so a screen shows the
## failure rather than flickering between coming and could not. Asking again
## forgets the failure and asks for the page, and then it can land.
func _a_failed_page_is_not_asked_for_again_until_asked() -> void:
	var made := _made(40)
	var list: LongList = made["list"]
	var source: Source = made["source"]
	var commands: Commands = made["commands"]
	var forgotten := Ear.new()
	(made["chimes"] as Chimes).listen(forgotten, list.region, LongList.FAILURES_FORGOTTEN)
	_scroll(made, 4)
	source.deliver(1, false)

	_scroll(made, 0)
	_scroll(made, 1)
	_verdict.check(source.firsts() == [0, 4, 8, 12], "looking again asks for the failed page no more: %s" % [source.firsts()])

	commands.dispatch(REGION, LongList.ASK_AGAIN, {})
	_verdict.check(source.firsts() == [0, 4, 8, 12, 4], "asking again asks for it, and only it: %s" % [source.firsts()])
	_verdict.check(not list.has_failed(4) and forgotten.rings == 1, "and it is no longer failed while it comes, which rang once: %d" % forgotten.rings)
	commands.dispatch(REGION, LongList.ASK_AGAIN, {})
	_verdict.check(forgotten.rings == 1, "asking again with nothing failed rings nothing")
	source.deliver(4, true)
	_verdict.check(list.has(4) and list.get_item(4) == 4, "and this time it lands")
	_done(made)


## What is remembered stays near the look. A failure a later look no longer
## covers is forgotten, and coming back to it asks for it again.
func _a_failure_a_later_look_no_longer_covers_is_forgotten() -> void:
	var made := _made(40)
	var list: LongList = made["list"]
	var source: Source = made["source"]
	_scroll(made, 4)
	source.deliver(1, false)

	_scroll(made, 20)
	_verdict.check(not list.has_failed(4), "a look far away forgets the failure")
	_scroll(made, -20)
	_verdict.check(source.firsts() == [0, 4, 8, 20, 24, 28, 4], "and coming back asks for that page again, and only it: %s" % [source.firsts()])
	_done(made)


## A reset means the rows changed, so a page that could not come before may
## come now: every failure is forgotten and asked for again. A failure answered
## to a request from before the reset describes rows that are no longer there,
## so it is dropped, and rings nothing.
func _a_reset_forgets_every_failure_and_a_stale_failure_is_dropped() -> void:
	var made := _made(40)
	var list: LongList = made["list"]
	var source: Source = made["source"]
	var failures: Ear = made["failures"]
	var chimes: Chimes = made["chimes"]
	_scroll(made, 4)
	source.deliver(1, false)

	chimes.strike(REGION, CHANGED)

	_verdict.check(not list.has_failed(4), "the reset forgot the failure")
	_verdict.check(source.firsts() == [0, 4, 8, 0, 4, 8], "and the failed page was asked for again with the rest: %s" % [source.firsts()])
	source.deliver(0, false)
	_verdict.check(not list.has_failed(0) and failures.rings == 1, "a failure answered to a request from before the reset is dropped, and rings nothing")
	_done(made)


## A list in a screen never opened costs nothing: built, it holds nothing and
## has asked for nothing; told to look, it asks; dropped, it forgets every
## page and the total and asks nothing again - not for a move, not for a
## reset - and an answer still on its way lands on nothing; told to look
## again, it asks for the same look, which it kept.
func _built_it_asks_nothing_until_told_to_look_and_dropped_it_forgets_and_asks_nothing() -> void:
	var chimes := Chimes.new(Belfry.new())
	var commands := Commands.new(chimes)
	chimes.register(REGION, CHANGED)
	var source := Source.new(50)
	var list := LongList.new(chimes, source.fetch, PAGE, KEEP, SHOWING, Bound.on_bell(func() -> Variant: return null, REGION, CHANGED))
	commands.stand(REGION, list)
	_verdict.check(source.requests.is_empty(), "built, nothing is asked for: %s" % [source.firsts()])

	list.look(Token.new())
	_verdict.check(source.firsts() == [0, PAGE], "told to look, the look's pages are asked for: %s" % [source.firsts()])
	source.deliver(0, true)
	source.deliver(1, true)
	commands.dispatch(REGION, LongList.SCROLL_ROWS, {"by": 12})
	var before := source.requests.size()
	var held := list.count()
	list.drop()
	_verdict.check(list.count() == 0 and not list.has(12), "dropped, every page and the total are forgotten: held %d" % held)
	source.deliver(before - 1, true)
	_verdict.check(not list.has(12), "and an answer still on its way lands on nothing")
	commands.dispatch(REGION, LongList.SCROLL_ROWS, {"by": 3})
	chimes.strike(REGION, CHANGED)
	_verdict.check(source.requests.size() == before, "neither a move nor a reset asks the source for anything: %d asked" % source.requests.size())
	_verdict.check(list.get_first() == 15, "though the look still moves: %d" % list.get_first())
	list.look(Token.new())
	_verdict.check(source.firsts().slice(before).has(12), "told to look again, it asks for the look it kept: %s" % [source.firsts()])
	source.deliver(before, true)
	_verdict.check(list.has(source.requests[before][0]), "and the rows land again")
	list.free()
	commands.free()


## Cancellation is the place's token: the list looks under it, and an answer
## on its way when the place is left - the token cancelled - lands on
## nothing, without the list being told; a reset cancels and reissues the
## list's own the same way, so an answer asked before it lands on nothing
## and one asked after lands.
func _an_answer_after_the_place_is_left_or_after_a_reset_lands_on_nothing() -> void:
	var chimes := Chimes.new(Belfry.new())
	var commands := Commands.new(chimes)
	chimes.register(REGION, CHANGED)
	var source := Source.new(50)
	var list := LongList.new(chimes, source.fetch, PAGE, KEEP, SHOWING, Bound.on_bell(func() -> Variant: return null, REGION, CHANGED))
	commands.stand(REGION, list)
	var stay := Token.new()
	list.look(stay)
	stay.cancel()
	source.deliver(0, true)
	_verdict.check(list.count() == 0 and not list.has(0), "the place left, a page answered after lands on nothing")

	var again := Token.new()
	list.look(again)
	var asked := source.requests.size()
	chimes.strike(REGION, CHANGED)
	source.deliver(asked - 1, true)
	_verdict.check(not list.has(0), "reset, a page asked before it lands on nothing")
	source.deliver(source.requests.size() - 1, true)
	_verdict.check(list.has(0) or list.has(PAGE), "and one asked after lands: %s" % [source.firsts()])
	list.free()
	commands.free()
