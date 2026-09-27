extends SceneTree

## What must be true of a collection with a query: the query asked is read
## at once and its view lands later, off the frame; a change while one is
## out is asked once it lands and the stale answer is never shown; the view
## is read in pages of places, grouped as headings then rows, a shut group
## its heading alone; a hundred thousand rows are set out with the frame
## kept; and other rows replacing these are shown at once, the query asked
## of the old ones let go.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_queried_rows.gd

const Fixture := preload("res://tests/fixture.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Controller := preload("res://addons/gd_chime/controller.gd")
const FrameBudget := preload("res://addons/gd_chime/frame_budget.gd")
const Jobs := preload("res://addons/gd_chime/jobs.gd")
const PackedRows := preload("res://addons/gd_chime/packed_rows.gd")
const RowQuery := preload("res://addons/gd_chime/row_query.gd")
const QueriedRows := preload("res://addons/gd_chime/queried_rows.gd")
const Verdict := preload("res://tests/verdict.gd")

const REGION := &"pipes"
const MATERIALS := ["cast iron", "PVC", "steel"]
const PATIENCE := 600

var _verdict := Verdict.new()


## Counts every time its work runs, and the work reads what it was handed:
## what a reader of the model is woken by, counted rather than argued.
class Counting extends Controller:
	var runs: int = 0

	func _init(chimes: Chimes, reading: Callable) -> void:
		super(chimes)
		follow(&"reading", func() -> void:
			runs += 1
			reading.call())


func _init() -> void:
	await _verdict.states(_the_query_is_read_at_once_and_its_view_lands_later)
	await _verdict.states(_a_sort_naming_its_way_runs_that_way_whatever_ran_before)
	await _verdict.states(_a_change_while_one_is_out_is_asked_when_it_lands)
	await _verdict.states(_a_scope_lies_beneath_every_filter_and_no_filter_takes_it_away)
	await _verdict.states(_a_grouped_view_is_headings_then_rows_and_a_shut_group_its_heading)
	await _verdict.states(_a_hundred_thousand_rows_are_queried_with_the_frame_kept)
	await _verdict.states(_asking_a_query_leaves_the_answer_standing_untouched)
	await _verdict.states(_other_rows_replace_these_and_the_query_asked_of_them_is_let_go)
	quit(_verdict.deliver(get_script()))


## Pipes: a risk and a material.
func _pipes(count: int) -> PackedRows:
	var rows := PackedRows.new({&"risk": PackedRows.NUMBER, &"material": PackedRows.WORDS})
	# every pipe, its risk and material spread
	for row: int in count:
		rows.add([float((row * 37) % 100), MATERIALS[row % MATERIALS.size()]])
	return rows


## The model over these rows, with its pool on the engine's threads, all in the tree.
func _made(made: Fixture, rows: PackedRows) -> QueriedRows:
	var budget := FrameBudget.new(made.chimes, 16.0, 0.9, 3)
	var pool := Jobs.new(made.chimes, budget, 2, 4, false)
	var queried := QueriedRows.new(made.chimes, rows, pool)
	made.commands.stand(REGION, queried)
	for node: Node in [budget, pool, queried]:
		root.add_child(node)
	return queried


## Frames until nothing is out: how many it took.
func _landed(queried: QueriedRows) -> int:
	var frames := 0
	# a frame at a time until the query lands, or patience runs out
	while queried.get_busy() and frames < PATIENCE:
		await process_frame
		frames += 1
	return frames


## The places a page from the first holds, as the long list would take them.
func _page(queried: QueriedRows, first: int, count: int) -> Array:
	var got: Array = []
	queried.fetch(first, count, func(rows: Array, _total: int) -> void: got.assign(rows))
	return got


func _the_query_is_read_at_once_and_its_view_lands_later() -> void:
	var made := Fixture.new(root)
	var queried := _made(made, _pipes(30))
	_verdict.check(queried.get_count() == 30 and _page(queried, 0, 3).map(func(place: Dictionary) -> int: return place["id"]) == [0, 1, 2], "before any query, the view is every row as added: %s" % [_page(queried, 0, 3)])
	made.commands.dispatch(REGION, QueriedRows.SORTS, {"column": &"risk"})
	_verdict.check(queried.get_sort() == {"column": &"risk", "ascending": true} and queried.get_busy() and _page(queried, 0, 1)[0]["id"] == 0, "sorted: the sort reads at once, the query is out, and the old view still stands: %s" % [queried.get_sort()])
	var frames := await _landed(queried)
	var risks: Array = _page(queried, 0, 30).map(func(place: Dictionary) -> float: return place["risk"])
	var sorted := risks.duplicate()
	sorted.sort()
	_verdict.check(frames > 0 and risks == sorted and not queried.get_busy(), "a frame or more later the view lands, least risk first: %s" % [risks.slice(0, 5)])
	_verdict.check(_page(queried, 28, 5).size() == 2 and _page(queried, 28, 5)[1]["at"] == 29, "a page past the end holds only the places there are, each saying where it is")
	made.commands.dispatch(REGION, QueriedRows.SORTS, {"column": &"risk"})
	await _landed(queried)
	_verdict.check(queried.get_sort()["ascending"] == false and _page(queried, 0, 1)[0]["risk"] == 99.0, "the same column again turns the way: %s" % [_page(queried, 0, 1)])
	made.done()


func _a_sort_naming_its_way_runs_that_way_whatever_ran_before() -> void:
	var made := Fixture.new(root)
	var queried := _made(made, _pipes(30))
	made.commands.dispatch(REGION, QueriedRows.SORTS, {"column": &"risk", "ascending": false})
	await _landed(queried)
	_verdict.check(queried.get_sort() == {"column": &"risk", "ascending": false} and _page(queried, 0, 1)[0]["risk"] == 99.0, "a sort naming its way runs that way from nothing, most risk first: %s" % [_page(queried, 0, 1)])
	made.commands.dispatch(REGION, QueriedRows.SORTS, {"column": &"risk", "ascending": false})
	await _landed(queried)
	_verdict.check(queried.get_sort()["ascending"] == false, "and asked again it stays that way rather than turning: %s" % [queried.get_sort()])
	made.done()


func _a_change_while_one_is_out_is_asked_when_it_lands() -> void:
	var made := Fixture.new(root)
	var queried := _made(made, _pipes(3000))
	var views: Array = []
	queried.ask([{"column": &"material", "test": RowQuery.IS, "value": ["PVC"]}])
	queried.ask([{"column": &"material", "test": RowQuery.IS, "value": ["steel"]}])
	# the view counted each time it could have landed, a frame at a time until nothing is out
	while queried.get_busy():
		views.append(_page(queried, 0, 1)[0]["material"] if queried.get_count() > 0 else "")
		await process_frame
	var first: String = _page(queried, 0, 1)[0]["material"]
	_verdict.check(first == "steel" and queried.get_kept() == 1000 and not views.has("PVC"), "two asked while one was out: the last is what lands, and the first's view is never shown: %s" % [first])
	made.done()


func _a_scope_lies_beneath_every_filter_and_no_filter_takes_it_away() -> void:
	var made := Fixture.new(root)
	var queried := _made(made, _pipes(300))
	queried.scope_to([{"column": &"material", "test": RowQuery.IS, "value": ["steel"]}])
	await _landed(queried)
	_verdict.check(queried.get_kept() == 100, "scoped to steel, the view keeps the hundred steel pipes alone: %d" % queried.get_kept())
	queried.ask([{"column": &"risk", "test": RowQuery.OVER, "value": 50.0}])
	await _landed(queried)
	var kept: Array = _page(queried, 0, 300)
	_verdict.check(not kept.is_empty() and kept.size() < 100 and kept.all(func(place: Dictionary) -> bool: return place["material"] == "steel" and place["risk"] > 50.0), "a filter asked narrows within the scope - steel over fifty - and never past it: %d" % kept.size())
	queried.ask([])
	await _landed(queried)
	_verdict.check(queried.get_kept() == 100, "every filter taken away, the scope still stands: %d" % queried.get_kept())
	queried.scope_to([])
	await _landed(queried)
	_verdict.check(queried.get_kept() == 300, "the scope taken away, every row again: %d" % queried.get_kept())
	made.done()


func _a_grouped_view_is_headings_then_rows_and_a_shut_group_its_heading() -> void:
	var made := Fixture.new(root)
	var queried := _made(made, _pipes(9))
	made.commands.dispatch(REGION, QueriedRows.GROUPS_BY, {"value": &"material"})
	await _landed(queried)
	var places := _page(queried, 0, 20)
	var said: Array = places.map(func(place: Dictionary) -> Variant: return place["words"] if place.has("group") else place["id"])
	_verdict.check(said == ["cast iron", 0, 3, 6, "PVC", 1, 4, 7, "steel", 2, 5, 8] and queried.get_count() == 12, "grouped: each group's heading, then its rows: %s" % [said])
	_verdict.check(queried.row_at(4) == -1 and queried.row_at(5) == 1 and places[4]["count"] == 3 and places[4]["open"], "a heading is no row, and says how many it holds and that it is open")
	made.commands.dispatch(REGION, QueriedRows.SHUTS, {"group": places[4]["group"]})
	said = _page(queried, 0, 20).map(func(place: Dictionary) -> Variant: return place["words"] if place.has("group") else place["id"])
	_verdict.check(said == ["cast iron", 0, 3, 6, "PVC", "steel", 2, 5, 8] and not _page(queried, 4, 1)[0]["open"], "PVC shut: its heading stands alone, at once, and says it is shut: %s" % [said])
	made.commands.dispatch(REGION, QueriedRows.GROUPS_BY, {"value": &""})
	await _landed(queried)
	_verdict.check(queried.get_count() == 9 and not _page(queried, 0, 1)[0].has("group"), "grouped by nothing again, every place a row: %d" % queried.get_count())
	made.commands.dispatch(REGION, QueriedRows.GROUPS_BY, {"value": &"material"})
	await _landed(queried)
	_verdict.check(queried.get_count() == 12 and _page(queried, 0, 12).filter(func(place: Dictionary) -> bool: return place.has("group")).all(func(place: Dictionary) -> bool: return place["open"]), "grouped anew, every group is open, PVC too: %d places" % queried.get_count())
	made.done()


func _a_hundred_thousand_rows_are_queried_with_the_frame_kept() -> void:
	var made := Fixture.new(root)
	var queried := _made(made, _pipes(100000))
	var longest := 0
	var last := Time.get_ticks_usec()
	queried.ask([{"column": &"material", "test": RowQuery.IS_NOT, "value": ["PVC"]}])
	made.commands.dispatch(REGION, QueriedRows.SORTS, {"column": &"risk"})
	# a frame at a time - the one the asking was in among them - until the view lands, the longest gap between frames kept
	while true:
		await process_frame
		var now := Time.get_ticks_usec()
		longest = maxi(longest, now - last)
		last = now
		if not queried.get_busy():
			break
	_verdict.check(queried.get_kept() == 66667 and queried.get_took_ms() > longest / 1000.0, "a hundred thousand rows sorted and filtered in %.0f ms, the longest frame meanwhile %.1f ms: the work was not the frame's" % [queried.get_took_ms(), longest / 1000.0])
	made.done()


func _asking_a_query_leaves_the_answer_standing_untouched() -> void:
	var made := Fixture.new(root)
	var queried := _made(made, _pipes(100000))
	await _landed(queried)
	var answer := Counting.new(made.chimes, func() -> void:
		queried.get_count()
		queried.get_shown())
	var query := Counting.new(made.chimes, func() -> void: queried.get_sort())
	for node: Node in [answer, query]:
		root.add_child(node)
	await process_frame
	var answered := answer.runs
	var asked := query.runs
	made.commands.dispatch(REGION, QueriedRows.SORTS, {"column": &"risk"})
	await process_frame
	await process_frame
	_verdict.check(queried.get_busy() and query.runs > asked and answer.runs == answered, "asked, with the query still out: a reader of the query is woken %d times, a reader of the answer %d" % [query.runs - asked, answer.runs - answered])
	await _landed(queried)
	await process_frame
	await process_frame
	_verdict.check(answer.runs > answered, "landed: the reader of the answer is woken at last, %d times" % [answer.runs - answered])
	made.done()


func _other_rows_replace_these_and_the_query_asked_of_them_is_let_go() -> void:
	var made := Fixture.new(root)
	var queried := _made(made, _pipes(9))
	queried.ask([{"column": &"material", "test": RowQuery.IS, "value": ["PVC"]}])
	made.commands.dispatch(REGION, QueriedRows.SORTS, {"column": &"risk"})
	made.commands.dispatch(REGION, QueriedRows.GROUPS_BY, {"value": &"material"})
	await _landed(queried)
	queried.ask([{"column": &"material", "test": RowQuery.IS, "value": ["steel"]}])
	var other := PackedRows.new({&"name": PackedRows.WORDS})
	# five rows of another shape, a name each
	for row: int in 5:
		other.add(["row %d" % row])
	queried.replace(other)
	var at_once: Array = _page(queried, 0, 10).map(func(place: Dictionary) -> Variant: return place["name"])
	_verdict.check(at_once == ["row 0", "row 1", "row 2", "row 3", "row 4"] and queried.get_sort().is_empty() and queried.get_group() == &"", "replaced, the new rows are shown at once as they were added, the sort and the grouping let go: %s" % [at_once])
	await _landed(queried)
	_verdict.check(queried.get_rows() == other and Array(queried.get_order()) == [0, 1, 2, 3, 4] and queried.get_count() == 5 and queried.get_shown()["clauses"].is_empty(), "landed, the view is every new row, by no filter: the answer to the query out over the old rows never shown: %s" % [queried.get_order()])
	made.done()
