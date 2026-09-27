extends SceneTree

## What must be true of the one filter model over a collection: every value
## is counted by the rows it would keep, a column's own picks ignored; a
## value picked narrows the view and the other columns' counts with it;
## values picked in one column widen it, columns narrow each other; a value
## that would keep nothing is refused while it is not picked; the stretch
## and the search narrow it, each with a chip that says so; a chip turned
## off keeps its value and applies nothing, and one taken away lets it go;
## clearing takes every one away and is refused while there is nothing to
## take; an order chosen by name is the view's sort; a DATE column stands in
## the stretch picked out of the presets handed in, its clauses keeping
## exactly the rows a pass over every row keeps and a rollup handed those
## clauses without them, and a day set by hand that is no date, to come or
## backwards refused in words; a column picked ON A DRAWING toggles on a
## press carrying the value alone; and the SAME spec reads the same over
## ordinary items, which have no rows at all.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_filters.gd

const Fixture := preload("res://tests/fixture.gd")
const FrameBudget := preload("res://addons/gd_chime/frame_budget.gd")
const Jobs := preload("res://addons/gd_chime/jobs.gd")
const PackedRows := preload("res://addons/gd_chime/packed_rows.gd")
const QueriedRows := preload("res://addons/gd_chime/queried_rows.gd")
const Filters := preload("res://addons/gd_chime/filters.gd")
const Stretch := preload("res://addons/gd_chime/stretch.gd")
const RowQuery := preload("res://addons/gd_chime/row_query.gd")
const Orders := preload("res://addons/gd_chime/orders.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Verdict := preload("res://tests/verdict.gd")

const REGION := &"shop"
const PATIENCE := 300
## Eight pieces: a name, a room, a material and a price.
const PIECES := [
	["Aldo sofa", "living room", "oak", 900.0],
	["Brisa chair", "dining room", "oak", 150.0],
	["Calder table", "dining room", "walnut", 1200.0],
	["Dune bed", "bedroom", "oak", 1500.0],
	["Elm lamp", "living room", "brass", 120.0],
	["Fenn stool", "dining room", "walnut", 90.0],
	["Greta bed", "bedroom", "walnut", 1800.0],
	["Harlow shelf", "living room", "brass", 400.0],
]

var _verdict := Verdict.new()


func _init() -> void:
	await _verdict.states(_every_value_is_counted_by_the_rows_it_would_keep)
	await _verdict.states(_a_value_picked_narrows_the_view_and_the_other_columns_counts_its_own_ignored)
	await _verdict.states(_values_in_one_column_widen_it_and_columns_narrow_each_other)
	await _verdict.states(_a_value_that_would_keep_nothing_is_refused_while_unpicked)
	await _verdict.states(_the_stretch_and_the_search_narrow_it_each_with_a_chip)
	await _verdict.states(_a_chip_turned_off_applies_nothing_one_taken_away_lets_it_go_and_clearing_takes_all)
	await _verdict.states(_an_order_chosen_by_name_is_the_views_sort)
	await _verdict.states(_a_date_column_stands_in_the_stretch_picked_and_a_rollup_is_handed_it_apart)
	await _verdict.states(_days_set_by_hand_are_refused_where_they_are_no_date_to_come_or_backwards)
	await _verdict.states(_a_column_picked_on_a_drawing_toggles_on_the_value_alone)
	await _verdict.states(_the_same_spec_reads_the_same_over_ordinary_items)
	quit(_verdict.deliver(get_script()))


## The filters over the eight rows: [fixture, view, filters, jobs, orders].
func _made() -> Array:
	var made := Fixture.new(root)
	var budget := FrameBudget.new(made.chimes, 1000.0, 0.9, 3)
	var jobs := Jobs.new(made.chimes, budget, 2, 64, false)
	var rows := PackedRows.new({&"name": PackedRows.WORDS, &"room": PackedRows.WORDS, &"material": PackedRows.WORDS, &"price": PackedRows.NUMBER})
	# every piece, a row
	for piece: Array in PIECES:
		rows.add(piece)
	var view := QueriedRows.new(made.chimes, rows, jobs)
	made.commands.stand(REGION, view)
	var worded := func(stretch: Vector2) -> Phrase: return Phrase.with("%d to %d", [stretch.x, stretch.y])
	var spec := {search = &"name", any_of = [&"room", &"material"], between = {column = &"price", bounds = Vector2(90.0, 1800.0), words = worded}}
	var filters := Filters.new(made.chimes, spec, {over = rows, on = jobs, asks = view.ask})
	made.commands.stand(REGION, filters)
	var orders := Orders.new(made.chimes, view, {&"featured": {"column": &"name", "ascending": true, "words": Phrase.of("featured")}, &"dearest": {"column": &"price", "ascending": false, "words": Phrase.of("dearest first")}})
	made.commands.stand(REGION, orders)
	for model: Node in [budget, jobs, view, filters, orders]:
		root.add_child(model)
	await _settled(filters, view)
	return [made, view, filters, jobs, orders]


## Frames until neither the view nor the counts have anything out.
func _settled(filters: Filters, view: QueriedRows) -> void:
	var frames := 0
	# a frame at a time, at least two, until nothing is out
	while frames < PATIENCE and (frames < 2 or filters.facets.get_busy() or view.get_busy()):
		await process_frame
		frames += 1


func _do(both: Array, action: StringName, payload: Dictionary) -> Phrase:
	var said := (both[0] as Fixture).commands.dispatch(REGION, action, payload)
	await _settled(both[2], both[1])
	return said


func _counts(filters: Filters, column: StringName) -> Dictionary:
	var found: Dictionary = {}
	# every value of the column, its count
	for value: Dictionary in filters.get_values(column):
		found[value["value"]] = value["count"]
	return found


func _names(view: QueriedRows) -> Array:
	return Array(view.get_order()).map(func(row: int) -> String: return PIECES[row][0])


func _done(both: Array) -> void:
	(both[3] as Jobs).stop()
	(both[0] as Fixture).done()


func _every_value_is_counted_by_the_rows_it_would_keep() -> void:
	var both: Array = await _made()
	var filters: Filters = both[2]
	_verdict.check(_counts(filters, &"material") == {"brass": 2, "oak": 3, "walnut": 3} and filters.get_count() == 8, "every value counted by the rows it would keep, in the reader's order: %s" % [_counts(filters, &"material")])
	_verdict.check(filters.get_values(&"room").map(func(value: Dictionary) -> String: return value["value"]) == ["bedroom", "dining room", "living room"], "a column's values in the reader's order")
	_done(both)


func _a_value_picked_narrows_the_view_and_the_other_columns_counts_its_own_ignored() -> void:
	var both: Array = await _made()
	var filters: Filters = both[2]
	await _do(both, Filters.TOGGLES, {"column": &"material", "value": "oak"})
	_verdict.check(_names(both[1]) == ["Aldo sofa", "Brisa chair", "Dune bed"] and filters.get_count() == 3, "oak picked, the view is the oak pieces: %s" % [_names(both[1])])
	_verdict.check(_counts(filters, &"room") == {"bedroom": 1, "dining room": 1, "living room": 1}, "the rooms counted among the oak pieces: %s" % [_counts(filters, &"room")])
	_verdict.check(_counts(filters, &"material") == {"brass": 2, "oak": 3, "walnut": 3}, "the materials counted as if nothing were picked in them - their own pick ignored: %s" % [_counts(filters, &"material")])
	_done(both)


func _values_in_one_column_widen_it_and_columns_narrow_each_other() -> void:
	var both: Array = await _made()
	await _do(both, Filters.TOGGLES, {"column": &"material", "value": "oak"})
	await _do(both, Filters.TOGGLES, {"column": &"material", "value": "walnut"})
	var widened := _names(both[1]).size()
	await _do(both, Filters.TOGGLES, {"column": &"room", "value": "bedroom"})
	_verdict.check(widened == 6 and _names(both[1]) == ["Dune bed", "Greta bed"], "oak or walnut widens to six; and in the bedroom narrows to two: %d, %s" % [widened, _names(both[1])])
	_done(both)


func _a_value_that_would_keep_nothing_is_refused_while_unpicked() -> void:
	var both: Array = await _made()
	await _do(both, Filters.TOGGLES, {"column": &"room", "value": "bedroom"})
	var refused: Phrase = await _do(both, Filters.TOGGLES, {"column": &"material", "value": "brass"})
	_verdict.check(str(refused) == "Nothing would match" and _names(both[1]) == ["Dune bed", "Greta bed"], "in the bedroom, brass would keep nothing and is refused: %s" % [refused])
	_done(both)


func _the_stretch_and_the_search_narrow_it_each_with_a_chip() -> void:
	var both: Array = await _made()
	var filters: Filters = both[2]
	_verdict.check(filters.get_bounds() == Vector2(90, 1800) and filters.get_range() == Vector2(90, 1800) and filters.get_chips().is_empty(), "the stretch starts as the column's own least and most, with no chip")
	await _do(both, Filters.SETS_RANGE, {"value": Vector2(150, 1200)})
	_verdict.check(_names(both[1]) == ["Aldo sofa", "Brisa chair", "Calder table", "Harlow shelf"] and str(filters.get_chips()[0]["words"]) == "150 to 1200", "a stretch keeps the pieces within it, its ends among them, and its chip says so in the caller's words: %s" % [_names(both[1])])
	await _do(both, Filters.SEARCHES, {"line": "  BED "})
	_verdict.check(_names(both[1]).is_empty() and filters.get_chips().size() == 2 and str(filters.get_chips()[1]["words"]) == "\"BED\"", "a search narrows by the letters, whatever their case: %s" % [_names(both[1])])
	await _do(both, Filters.SETS_RANGE, {"value": Vector2(0, 5000)})
	_verdict.check(_names(both[1]) == ["Dune bed", "Greta bed"] and filters.get_range() == Vector2(90, 1800) and filters.get_chips().size() == 1, "a stretch past the column's ends is held within them, and narrows nothing: %s" % [_names(both[1])])
	_done(both)


func _a_chip_turned_off_applies_nothing_one_taken_away_lets_it_go_and_clearing_takes_all() -> void:
	var both: Array = await _made()
	var filters: Filters = both[2]
	var nothing_to_clear: Phrase = filters.would(Filters.CLEARS, {})
	await _do(both, Filters.TOGGLES, {"column": &"material", "value": "brass"})
	await _do(both, Filters.TURNS, {"id": "material:brass"})
	_verdict.check(_names(both[1]).size() == 8 and filters.get_chips() == [{"id": "material:brass", "words": "brass", "on": false}], "turned off, the chip stays and the view is every piece: %s" % [filters.get_chips()])
	await _do(both, Filters.TURNS, {"id": "material:brass"})
	_verdict.check(_names(both[1]).size() == 2, "turned on again, brass narrows it again")
	await _do(both, Filters.REMOVES, {"id": "material:brass"})
	_verdict.check(filters.get_chips().is_empty() and not filters.get_values(&"material")[0]["picked"] and _names(both[1]).size() == 8, "taken away, brass is let go")
	await _do(both, Filters.TOGGLES, {"column": &"room", "value": "bedroom"})
	await _do(both, Filters.SEARCHES, {"line": "bed"})
	await _do(both, Filters.CLEARS, {})
	_verdict.check(filters.get_chips().is_empty() and _names(both[1]).size() == 8, "clearing takes every one away")
	_verdict.check(str(nothing_to_clear) == "No filters are on" and str(filters.would(Filters.CLEARS, {})) == "No filters are on", "and clearing is refused while there is nothing to take: %s" % [nothing_to_clear])
	_done(both)


func _an_order_chosen_by_name_is_the_views_sort() -> void:
	var both: Array = await _made()
	var orders: Orders = both[4]
	_verdict.check(orders.get_chosen() == &"featured" and (both[1] as QueriedRows).get_sort() == {"column": &"name", "ascending": true}, "the first order named is the one it starts in, the view sorted by it")
	await _do(both, Orders.ORDERS, {"value": &"dearest"})
	_verdict.check(orders.get_chosen() == &"dearest" and _names(both[1]).slice(0, 2) == ["Greta bed", "Dune bed"], "dearest first chosen, the view runs by price, down: %s" % [_names(both[1])])
	_verdict.check(orders.get_options().map(func(option: Dictionary) -> StringName: return option["value"]) == [&"featured", &"dearest"], "the orders are a choice's options")
	_done(both)


## Noon on day 20,000, in hours, and the stretches an application hands in:
## today, the last 7 days, and the days the reader sets by hand.
const NOW := 20000.0 * 24.0 + 12.0
const INCIDENTS := &"incidents"


func _dated() -> Array:
	var made := Fixture.new(root)
	var rows := PackedRows.new({&"region": PackedRows.WORDS, &"reported": PackedRows.NUMBER})
	# an incident every six hours over forty days back from now, in turn in two regions: so a Welsh one falls on each stretch's first hour
	for at: int in 160:
		rows.add([["Wales", "London"][at % 2], NOW - at * 6.0])
	var presets: Array = [{"value": &"today", "words": Phrase.of("Today"), "days": 1}, {"value": &"week", "words": Phrase.of("7 days"), "days": 7}, {"value": &"by_hand", "words": Phrase.of("Custom")}]
	var filters := Filters.new(made.chimes, {one_of = &"region", on_a_drawing = &"region", dates = {column = &"reported", now = NOW, presets = presets, starts = &"week"}})
	made.commands.stand(INCIDENTS, filters)
	root.add_child(filters)
	return [made, filters, rows]


func _told(both: Array, action: StringName, payload: Dictionary) -> Phrase:
	return (both[0] as Fixture).commands.dispatch(INCIDENTS, action, payload)


## The rows the filters' clauses keep, and the rows a pass over every row keeps.
func _kept(both: Array, clauses: Array) -> Array:
	return Array(RowQuery.run(both[2], clauses, {}, &"")["order"])


func _a_date_column_stands_in_the_stretch_picked_and_a_rollup_is_handed_it_apart() -> void:
	var both: Array = await _dated()
	var filters: Filters = both[1]
	var rows: PackedRows = both[2]
	var week: Dictionary = filters.stretch.get_stretches()
	_verdict.check(week["now"]["first_day"] == 19994 and week["now"]["days"] == 7 and week["now"]["from"] == 19994.0 * 24.0 and week["now"]["to"] == NOW, "the preset picked runs back from the day that holds the data's now, never past it: %s" % [week["now"]])
	_verdict.check(week["before"]["to"] == week["now"]["from"] and week["before"]["days"] == 7 and week["before"]["first_day"] == 19987, "the stretch before is as long and ends where this one starts: %s" % [week["before"]])
	_told(both, Filters.picks_of(&"region"), {"picked": "Wales"})
	var by_hand: Array = range(rows.count()).filter(func(row: int) -> bool: return rows.value_at(row, &"region") == "Wales" and rows.value_at(row, &"reported") >= week["now"]["from"] and rows.value_at(row, &"reported") < week["now"]["to"])
	var kept: Array = _kept(both, filters.get_clauses())
	var on_the_hour: Array = kept.filter(func(row: int) -> bool: return rows.value_at(row, &"reported") == week["now"]["from"])
	_verdict.check(on_the_hour.size() == 1 and not by_hand.is_empty() and kept == by_hand, "the dates keep the Welsh incidents from the stretch's first hour to before its last, as a pass over every row finds them: %d of %d" % [kept.size(), by_hand.size()])
	var rollup: Dictionary = filters.get_rollup()
	_verdict.check(rollup["stretches"] == week and _kept(both, rollup["clauses"]).size() == 80, "a rollup is handed the stretch beside the clauses, and those clauses hold no date: every Welsh incident of the forty days, not the week's")
	_told(both, Stretch.PICKS, {"value": &"today"})
	_verdict.check(filters.stretch.get_stretches()["now"]["days"] == 1 and _kept(both, filters.get_clauses()).size() == 1, "another preset picked moves the stretch, and the rows kept with it - today holds one Welsh incident: %s" % [_kept(both, filters.get_clauses())])
	_told(both, Stretch.PICKS, {"value": &"by_hand"})
	_told(both, Stretch.SETS_FIRST_DAY, {"value": 19990})
	_told(both, Stretch.SETS_LAST_DAY, {"value": 19992})
	var set_by_hand: Dictionary = filters.stretch.get_stretches()
	_verdict.check(filters.stretch.get_by_hand() and set_by_hand["now"]["days"] == 3 and set_by_hand["now"]["from"] == 19990.0 * 24.0 and set_by_hand["now"]["to"] == 19993.0 * 24.0 and set_by_hand["before"]["first_day"] == 19987, "a preset of no days is the stretch set by hand, from the first day's midnight to the end of the last: %s" % [set_by_hand])
	_verdict.check(filters.keeps({"region": "Wales", "reported": 19991.0 * 24.0}) and not filters.keeps({"region": "Wales", "reported": 19989.0 * 24.0}), "and an ordinary item is kept by the same days, which have no rows at all")
	(both[0] as Fixture).done()


func _days_set_by_hand_are_refused_where_they_are_no_date_to_come_or_backwards() -> void:
	var both: Array = await _dated()
	var filters: Filters = both[1]
	_told(both, Stretch.PICKS, {"value": &"by_hand"})
	_told(both, Stretch.SETS_FIRST_DAY, {"value": 19990})
	var none: Phrase = _told(both, Stretch.SETS_FIRST_DAY, {"value": null})
	var coming: Phrase = _told(both, Stretch.SETS_LAST_DAY, {"value": 20003})
	var backwards: Phrase = _told(both, Stretch.SETS_LAST_DAY, {"value": 19989})
	_verdict.check(str(none) == "That is not a date" and str(coming) == "That day has not come yet" and str(backwards) == "The first day is after the last", "a line that is no date, a day to come and a last day before the first are each refused in their own words: %s, %s, %s" % [none, coming, backwards])
	_verdict.check(filters.stretch.get_first_day() == 19990 and filters.stretch.get_last_day() == 20000, "and nothing refused was set: %d to %d" % [filters.stretch.get_first_day(), filters.stretch.get_last_day()])
	(both[0] as Fixture).done()


## A map's region and a chart's bar carry the value they hit and nothing
## else, so the column picked on a drawing answers an action of its own.
func _a_column_picked_on_a_drawing_toggles_on_the_value_alone() -> void:
	var both: Array = await _dated()
	var filters: Filters = both[1]
	_verdict.check(filters.answers().has(Filters.picks_of(&"region")) and Filters.picks_of(&"region") == &"picks_a_region", "the column answers an action named after it: %s" % [filters.answers()])
	_told(both, Filters.picks_of(&"region"), {"picked": "Wales"})
	_verdict.check(filters.get_chosen(&"region") == "Wales" and str(filters.get_chips()[0]["words"]) == "Wales", "a value pressed on a drawing is picked, and shows as a chip")
	_told(both, Filters.picks_of(&"region"), {"picked": "London"})
	_verdict.check(filters.get_picked(&"region") == ["London"], "another takes its place, since at most one is picked in the column: %s" % [filters.get_picked(&"region")])
	_told(both, Filters.picks_of(&"region"), {"picked": "London"})
	_verdict.check(filters.get_chosen(&"region") == "" and filters.get_chips().is_empty(), "and the one picked pressed again is let go")
	(both[0] as Fixture).done()


## The same declared spec over ordinary dictionaries - no rows, no counts:
## one person picked, any of the labels turned on, and a line looked for in
## several fields at once, which packed rows cannot do.
func _the_same_spec_reads_the_same_over_ordinary_items() -> void:
	var made := Fixture.new(root)
	var filters := Filters.new(made.chimes, {search = [&"title", &"person"], one_of = &"person", any_of = &"labels"})
	made.commands.stand(&"board", filters)
	root.add_child(filters)
	var cards: Array = [
		{"title": "Paginate the ledger", "person": "Ana", "labels": ["bug", "ui"]},
		{"title": "Ana's crate count", "person": "Bo", "labels": ["ui"]},
		{"title": "Slow query", "person": "Ana", "labels": ["chore"]},
	]
	var kept := func() -> Array: return cards.filter(filters.keeps).map(func(card: Dictionary) -> String: return card["title"])
	made.commands.dispatch(&"board", Filters.SEARCHES, {"line": "ledger"})
	var by_title: Array = kept.call()
	made.commands.dispatch(&"board", Filters.SEARCHES, {"line": "  BO "})
	_verdict.check(by_title == ["Paginate the ledger"] and kept.call() == ["Ana's crate count"], "a line is looked for in every column searched, whatever their case: %s, %s" % [by_title, kept.call()])
	made.commands.dispatch(&"board", Filters.SEARCHES, {"line": ""})
	made.commands.dispatch(&"board", Filters.PICKS, {"column": &"person", "value": "Ana"})
	_verdict.check(kept.call() == ["Paginate the ledger", "Slow query"], "one person picked keeps that person's: %s" % [kept.call()])
	made.commands.dispatch(&"board", Filters.TOGGLES, {"column": &"labels", "value": "ui"})
	_verdict.check(kept.call() == ["Paginate the ledger"], "a label turned on keeps what shares one with it, and the two narrow each other: %s" % [kept.call()])
	made.commands.dispatch(&"board", Filters.PICKS, {"column": &"person", "value": ""})
	_verdict.check(kept.call() == ["Paginate the ledger", "Ana's crate count"], "nobody picked lets the person go, the label still on: %s" % [kept.call()])
	made.commands.dispatch(&"board", Filters.CLEARS, {})
	_verdict.check(kept.call().size() == 3 and filters.get_chips().is_empty(), "cleared, every card is kept again")
	filters.free()
	made.done()
