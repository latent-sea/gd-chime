extends SceneTree

## What must be true of where a scroll stands, kept with the view.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_scroll_kept.gd
##
## Scrolled, a detour and Back find the same offset, and the same screen
## entered as another view keeps its own; content that arrives later is
## waited for rather than clamped short; focus moved by the keys brings a
## row into view, and focus given back on arrival never scrolls away from
## where the reader stood; a virtual list returns to its row, not to pixels.
## In every kind of list that runs down, the row with the focus is shown
## whole: the pad onto a row part out of sight brings it wholly in, by the
## least move, and Back puts the scroll back and then moves only as far as
## shows the focused row whole; a virtual list moves a row at a time by the
## pad past its last slot.

const Fixture := preload("res://tests/fixture.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const LongList := preload("res://addons/gd_chime/long_list.gd")
const Scroll := preload("res://addons/gd_chime/components/primitives/scroll.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Verdict := preload("res://tests/verdict.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Narrowing := preload("res://addons/gd_chime/narrowing.gd")
const Collection := preload("res://addons/gd_chime/components/recipes/collection.gd")
const Board := preload("res://addons/gd_chime/components/recipes/board.gd")
const Table := preload("res://addons/gd_chime/components/recipes/table.gd")
const Sections := preload("res://addons/gd_chime/components/recipes/sections.gd")
const TypeAhead := preload("res://addons/gd_chime/components/recipes/type_ahead.gd")
const VirtualList := preload("res://addons/gd_chime/components/primitives/virtual_list.gd")
const Fields := preload("res://addons/gd_chime/theme_fields.gd")

const ROWS := 20

var _verdict := Verdict.new()
var _made: Fixture
var _model: Fixture.Model


## Two hundred rows, given at once, for a long list.
class Source extends RefCounted:
	func fetch(first: int, count: int, answer: Callable) -> void:
		var rows: Array = []
		for index: int in range(first, mini(first + count, 200)):
			rows.append({"id": index, "name": "row %d" % index})
		answer.call(rows, 200)


## The rows of every kind of list at once: the rows, a sort, and groups of them.
class Lists extends Fixture.Model:
	func get_sort() -> Variant:
		return of(&"sort").read()

	func get_sections() -> Variant:
		return of(&"sections").read()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(400, 400)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_scrolled_a_detour_and_back_find_it_where_it_was_and_another_view_keeps_its_own)
	await _verdict.states(_a_fresh_visit_stands_at_the_top_and_a_strip_round_every_screen_stays_put)
	await _verdict.states(_content_arriving_later_is_waited_for_never_clamped_short)
	await _verdict.states(_focus_moved_by_the_keys_brings_a_row_into_view)
	await _verdict.states(_focus_given_back_on_arrival_never_scrolls_away_from_where_the_reader_stood)
	await _verdict.states(_a_virtual_list_returns_to_its_row)
	await _verdict.states(_in_every_list_that_runs_down_the_focused_row_is_shown_whole)
	await _verdict.states(_a_virtual_list_moves_a_whole_row_by_the_pad_past_its_last_slot)
	await _verdict.states(_a_focused_piece_wider_than_the_room_shows_its_start_and_the_scroll_settles)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


func _go(place: StringName, parameter: Variant = null) -> void:
	_made.commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": place, "parameter": parameter})
	await _a_frame_passes()


func _back() -> void:
	_made.commands.dispatch(Chimes.GLOBAL, Driver.GOES_BACK, {})
	await _a_frame_passes()


## A screen of twenty rows in a scroll, from a model - pressable ones, or
## rows of words that take no focus - and a screen elsewhere.
func _standing(pressable: bool = true) -> ScrollContainer:
	_made = Fixture.new(root, {&"opens": "open"})
	var ui := _made.ui
	_model = Fixture.Model.new(_made.chimes, &"list")
	_made.commands.register(Chimes.GLOBAL, &"opens", _model)
	_model.set_value(&"items", range(ROWS).map(func(at: int) -> Dictionary: return {"id": at, "name": "row %d" % at}))
	var row := func(item: Bound) -> Desc: return ui.pressable(&"opens", {}, [ui.text(item.field("name"))]) if pressable else ui.text(item.field("name"))
	var listed := ui.each(_model.of(&"items"), row, func(item: Dictionary) -> int: return item["id"]).pieces_named(&"row ")
	ui.start(ui.app(&"app", [ui.stack([ui.screen(&"list", [ui.scroll(listed).named(&"scroll")]), ui.screen(&"elsewhere", [ui.pressable(&"opens", {}, [ui.text("elsewhere")])])])]))
	await _a_frame_passes()
	await _go(&"list", 1)
	return ui.node_named(&"scroll")


## The reader turning the wheel over this scroll, and then standing it here by hand.
func _scroll_by_hand(scroll: ScrollContainer, to: float) -> void:
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	wheel.position = scroll.get_global_rect().get_center()
	root.push_input(wheel)
	await _a_frame_passes()
	scroll.get_v_scroll_bar().value = to
	await _a_frame_passes()


## The focus on the first row wholly in view where the reader stands, which it gives back.
func _focus_in_view(scroll: ScrollContainer) -> Control:
	var rows: Array = scroll.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable and scroll.get_global_rect().encloses((part as Control).get_global_rect()))
	(rows[0] as Control).grab_focus()
	return rows[0]


func _done() -> void:
	_model.free()
	_made.done()


func _scrolled_a_detour_and_back_find_it_where_it_was_and_another_view_keeps_its_own() -> void:
	var scroll := await _standing()
	await _scroll_by_hand(scroll, 300.0)
	_focus_in_view(scroll)
	await _a_frame_passes()
	await _go(&"elsewhere")
	await _back()
	_verdict.check(scroll.scroll_vertical == 300, "scrolled, a detour and Back find it where it was: %d" % scroll.scroll_vertical)
	await _go(&"list", 2)
	await _scroll_by_hand(scroll, 100.0)
	await _back()
	_verdict.check(_made.driver.get_parameter(&"list") == 1 and scroll.scroll_vertical == 300, "the same screen entered as another view keeps its own: back on the first, it stands where the first stood: %d" % scroll.scroll_vertical)
	_done()


## A strip of flaps scrolled across in the app round the screens, and the
## list scrolled down: elsewhere, then the list again by a link - a fresh
## entry, at its top - while the strip, whose place never left, stays where
## the reader put it; Back twice finds the first visit's list where it stood.
func _a_fresh_visit_stands_at_the_top_and_a_strip_round_every_screen_stays_put() -> void:
	_made = Fixture.new(root, {&"opens": "open"})
	var ui := _made.ui
	_model = Fixture.Model.new(_made.chimes, &"list")
	_made.commands.register(Chimes.GLOBAL, &"opens", _model)
	_model.set_value(&"items", range(ROWS).map(func(at: int) -> Dictionary: return {"id": at, "name": "row %d" % at}))
	var row := func(item: Bound) -> Desc: return ui.pressable(&"opens", {}, [ui.text(item.field("name"))])
	var listed := ui.each(_model.of(&"items"), row, func(item: Dictionary) -> int: return item["id"]).pieces_named(&"row ")
	var flaps := ui.row(range(30).map(func(at: int) -> Desc: return ui.text("flap number %d" % at)))
	# a button above the list takes the default focus, so nothing but the fresh visit moves the list
	var list := ui.screen(&"list", [ui.column([ui.pressable(&"opens", {}, [ui.text("above")]), ui.scroll(listed).named(&"scroll").grow()])])
	ui.start(ui.app(&"app", [ui.column([ui.scroll(flaps, null, Scroll.ACROSS).named(&"strip"), ui.stack([list, ui.screen(&"elsewhere", [ui.pressable(&"opens", {}, [ui.text("elsewhere")])])]).grow()])]))
	await _a_frame_passes()
	await _go(&"list")
	var scroll: ScrollContainer = ui.node_named(&"scroll")
	var strip: ScrollContainer = ui.node_named(&"strip")
	scroll.scroll_vertical = 300
	strip.scroll_horizontal = 200
	await _a_frame_passes()
	# a strip rests on whole flaps (strip.gd), so where the reader put it is the flap it came to rest on
	var rested := strip.scroll_horizontal
	await _go(&"elsewhere")
	await _go(&"list")
	_verdict.check(scroll.scroll_vertical == 0, "the list again by a link is a fresh entry, at its top: %d" % scroll.scroll_vertical)
	_verdict.check(rested > 0 and strip.scroll_horizontal == rested, "and the strip round every screen, whose place never left, stays where the reader put it: %d, put at %d" % [strip.scroll_horizontal, rested])
	await _back()
	await _back()
	_verdict.check(scroll.scroll_vertical == 300, "Back twice, the first visit's list stands where the first stood: %d" % scroll.scroll_vertical)
	_done()


## Rows that take no focus, so where the reader stood is all there is to put back.
func _content_arriving_later_is_waited_for_never_clamped_short() -> void:
	var scroll := await _standing(false)
	await _scroll_by_hand(scroll, 300.0)
	await _go(&"elsewhere")
	var rows: Array = _model.of(&"items").read()
	_model.set_value(&"items", rows.slice(0, 3))
	await _a_frame_passes()
	await _back()
	_verdict.check(scroll.scroll_vertical < 300, "back while the content is short, it cannot stand there yet: %d" % scroll.scroll_vertical)
	await _go(&"elsewhere")
	await _back()
	_model.set_value(&"items", rows)
	await _a_frame_passes()
	await _a_frame_passes()
	_verdict.check(scroll.scroll_vertical == 300, "away and back again while it waited, and then the content arriving, it goes to where it stood - the wait was never written down as where it stands: %d" % scroll.scroll_vertical)
	_done()


func _focus_moved_by_the_keys_brings_a_row_into_view() -> void:
	var scroll := await _standing()
	var far: Control = _made.ui.node_named(&"row 15")
	_verdict.check(far.get_global_rect().position.y > scroll.get_global_rect().end.y, "a row far down stands out of view: %s" % far.get_global_rect().position.y)
	far.grab_focus()
	await _a_frame_passes()
	_verdict.check(scroll.get_global_rect().encloses(far.get_global_rect()), "focus moved to it, it is brought into view: %d" % scroll.scroll_vertical)
	_done()


## A press wider than the scroll's room, with the focus: it cannot be shown
## whole, so its start is, and placing it again moves nothing - the scroll
## is placed a few times as it settles and then no more, however many frames
## pass; weighed from where it stood, the two edges pulled it back and forth
## a placing at a time until the engine died.
func _a_focused_piece_wider_than_the_room_shows_its_start_and_the_scroll_settles() -> void:
	_made = Fixture.new(root, {&"opens": "open"})
	var ui := _made.ui
	_model = Fixture.Model.new(_made.chimes)
	root.add_child(_model)
	_made.commands.register(Chimes.GLOBAL, &"opens", _model)
	var wide := ui.pressable(&"opens", {}, [ui.text("a press whose words run far wider than the narrow room it stands in")]).named(&"wide")
	ui.start(ui.app(&"app", [ui.row([ui.scroll(ui.column([wide])).named(&"narrow"), ui.text("beside")])]))
	await _a_frame_passes()
	var scroll: Scroll = ui.node_named(&"narrow")
	var placings: Array = [0]
	scroll.sort_children.connect(func() -> void: placings[0] += 1)
	(ui.node_named(&"wide") as Control).grab_focus()
	# frames enough for a settling scroll to have stopped long ago
	for frame: int in 10:
		await _a_frame_passes()
	var settled: int = placings[0]
	await _a_frame_passes()
	await _a_frame_passes()
	_verdict.check((ui.node_named(&"wide") as Control).size.x > scroll.size.x and scroll.scroll_horizontal == 0, "the press is wider than the room, and its start is what shows: %d across" % scroll.scroll_horizontal)
	_verdict.check(settled <= 4 and placings[0] == settled, "the scroll settled: placed %d times as the focus arrived, and not again since" % settled)
	_done()
	# a line typed into, grown, taking the focus, beside a button, in a wrapping row in a narrow scroll: the same, settled
	_made = Fixture.new(root, {&"renames": "rename", &"saves": "save the name"})
	ui = _made.ui
	_model = Fixture.Model.new(_made.chimes)
	root.add_child(_model)
	_made.commands.register(Chimes.GLOBAL, &"renames", _model)
	_made.commands.register(Chimes.GLOBAL, &"saves", _model)
	var line := ui.row([ui.field(&"renames", Fields.FIELD).takes_focus().grow(), ui.pressable(&"saves", {}, [ui.text("save the name")])], Themes.TILES)
	ui.start(ui.app(&"app", [ui.row([ui.scroll(ui.column([line])).basis(0.1).named(&"narrow"), ui.text("beside").grow()])]))
	await _a_frame_passes()
	scroll = ui.node_named(&"narrow")
	placings = [0]
	scroll.sort_children.connect(func() -> void: placings[0] += 1)
	# frames enough for the focus to arrive and a settling scroll to stop
	for frame: int in 10:
		await _a_frame_passes()
	settled = placings[0]
	await _a_frame_passes()
	await _a_frame_passes()
	_verdict.check(root.gui_get_focus_owner() is LineEdit and settled <= 4 and placings[0] == settled, "a line taking the focus in a wrapping row too wide for its scroll settles too: placed %d times, then not again" % settled)
	_done()


func _focus_given_back_on_arrival_never_scrolls_away_from_where_the_reader_stood() -> void:
	var scroll := await _standing()
	await _scroll_by_hand(scroll, 500.0)
	var focused := _focus_in_view(scroll)
	await _a_frame_passes()
	_verdict.check(scroll.scroll_vertical == 500, "the reader stands at 500, the focus on a row in view there")
	await _go(&"list", 2)
	await _scroll_by_hand(scroll, 0.0)
	await _back()
	_verdict.check(focused.has_focus() and scroll.scroll_vertical == 500, "back on the first view the focus is given back to that row, and the scroll stands at 500, where the reader stood - not where following the focus would put it: %d" % scroll.scroll_vertical)
	_done()


func _a_virtual_list_returns_to_its_row() -> void:
	_made = Fixture.new(root)
	var ui := _made.ui
	var source := Source.new()
	var long := LongList.new(_made.chimes, source.fetch, 10, 6, 5, Bound.new(func() -> Variant: return null))
	_made.commands.stand(&"rows", long)
	root.add_child(long)
	var slot := func(item: Bound) -> Desc: return ui.text(item.map(func(row: Variant) -> String: return "" if row == null else row["name"]))
	ui.start(ui.app(&"app", [ui.stack([ui.screen(&"rows", [ui.virtual_list(long, slot)], null, {on_fill = func(_token: Variant) -> void: long.look(null), on_empty = long.drop}), ui.screen(&"elsewhere", [ui.text("elsewhere")])])]))
	await _a_frame_passes()
	await _go(&"rows", 1)
	_made.commands.dispatch(&"rows", LongList.SCROLL_ROWS, {"by": 40})
	await _a_frame_passes()
	await _go(&"elsewhere")
	await _back()
	_verdict.check(long.get_first() == 40, "a detour and Back, the list stands at its row: %d" % long.get_first())
	await _go(&"rows", 2)
	_verdict.check(long.get_first() == 0, "the rows as 2, a fresh view, stand at their first row: %d" % long.get_first())
	_made.commands.dispatch(&"rows", LongList.SCROLL_ROWS, {"by": 5})
	await _a_frame_passes()
	await _back()
	_verdict.check(_made.driver.get_parameter(&"rows") == 1 and long.get_first() == 40, "another view moved it to its own row; back on the first, it is at the first's row again: %d" % long.get_first())
	long.free()
	_made.done()


## Whether this control stands wholly inside what this scroll shows.
func _whole_in(scroll: ScrollContainer, row: Control) -> bool:
	return scroll.get_global_rect().grow(0.01).encloses(row.get_global_rect())


## A page, a collection, a board, a table, sections and a type-ahead, each of
## twenty rows in a room for a few, each on a screen of its own. Scrolled by
## hand until a row stands half past the foot, the pad down onto it from the
## row above brings it wholly in and no further; scrolled by hand until it is
## half out again, a detour and Back put the scroll back where the reader
## stood and then move only as far as shows that focused row whole; and
## while the reader scrolls by hand, the focus is not brought back under them.
func _in_every_list_that_runs_down_the_focused_row_is_shown_whole() -> void:
	_made = Fixture.new(root, {&"opens": "open", &"sorts": "sort", &"types": "type", &"picks": "pick"})
	var ui := _made.ui
	_model = Lists.new(_made.chimes, &"list")
	_made.commands.register(Chimes.GLOBAL, &"opens", _model)
	var named := func(at: int) -> Dictionary: return {"id": at, "name": "row number %d" % at, "value": at, "words": "choice %d" % at}
	_model.set_value(&"items", range(ROWS).map(named))
	_model.set_value(&"sort", {"column": "name", "ascending": true})
	_model.set_value(&"flag", null)
	_model.set_value(&"sections", [{"id": 0, "heading": "the first group", "items": range(10).map(named)}, {"id": 1, "heading": "the second group", "items": range(10, ROWS).map(named)}])
	var narrowing := Narrowing.new(_made.chimes, _model.of(&"items"), ROWS)
	var row := func(item: Bound) -> Desc: return ui.pressable(&"opens", {}, [ui.text(item.field("name"))])
	var key := func(item: Dictionary) -> int: return item["id"]
	var kinds := {
		&"page": ui.scroll(ui.column(range(ROWS).map(func(at: int) -> Desc: return ui.pressable(&"opens", {}, [ui.text("line number %d" % at)])))),
		&"collection": Collection.make(ui, _model.of(&"items"), row, {key = key}),
		&"board": Board.make(ui, _model.of(&"items"), row, {key = key, own = _model.of(&"flag")}),
		&"table": Table.make(ui, _model.of(&"items"), [{"name": "name", "words": "name", "share": 1.0, "cell": row}], {key = key, sorts = &"sorts", sort = _model.of(&"sort")}),
		&"sections": Sections.make(ui, _model.of(&"sections"), row, {key = key}),
		&"type_ahead": TypeAhead.make(ui, narrowing, &"types", &"picks"),
	}
	var screens: Array = kinds.keys().map(func(kind: StringName) -> Desc: return ui.screen(kind, [ui.column([(kinds[kind] as Desc).named(StringName("the %s" % kind)).basis(0.4637), ui.text("").grow()])]))
	ui.start(ui.app(&"app", [ui.stack(screens + [ui.screen(&"elsewhere", [ui.text("elsewhere")])])]))
	await _a_frame_passes()
	var failed: Array = []
	var down := InputEventAction.new()
	down.action = &"ui_down"
	down.pressed = true
	# every kind of list, on its own screen
	for kind: StringName in kinds:
		await _go(kind)
		var list: Node = ui.node_named(StringName("the %s" % kind))
		var scroll: ScrollContainer = list if list is ScrollContainer else list.find_children("*", "ScrollContainer", true, false)[0]
		var rows: Array = scroll.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable and (part as Control).is_visible_in_tree())
		var target: Control = rows.filter(func(one: Control) -> bool: return one.get_global_rect().position.y > scroll.get_global_rect().position.y + scroll.size.y)[1]
		var above: Control = rows[rows.find(target) - 1]
		# where a row stands in what the scroll holds, whatever it is scrolled to
		var within := func(one: Control) -> float: return one.get_global_rect().position.y - scroll.get_global_rect().position.y + scroll.get_v_scroll_bar().value
		await _scroll_by_hand(scroll, within.call(target) - scroll.size.y + target.size.y / 2.0)
		above.grab_focus()
		await _a_frame_passes()
		if _whole_in(scroll, target) or not _whole_in(scroll, above):
			failed.append("%s: scrolled by hand, the row was not left half past the foot with the one above it whole" % kind)
			continue
		root.push_input(down)
		await _a_frame_passes()
		if not target.has_focus() or not _whole_in(scroll, target) or absf(target.get_global_rect().end.y - scroll.get_global_rect().end.y) > 0.5:
			failed.append("%s: the pad down onto %s did not bring it wholly in by the least move: %s in %s" % [kind, target, target.get_global_rect(), scroll.get_global_rect()])
			continue
		var stood: float = within.call(target) - scroll.size.y + target.size.y / 2.0
		await _scroll_by_hand(scroll, stood)
		if _whole_in(scroll, target):
			failed.append("%s: scrolled by hand, the focused row was brought back into view under the reader" % kind)
			continue
		await _go(&"elsewhere")
		await _back()
		if not target.has_focus() or not _whole_in(scroll, target) or absf(scroll.get_v_scroll_bar().value - stood - target.size.y / 2.0) > 0.5:
			failed.append("%s: back, the focused row is not whole, or the scroll moved other than the least from where the reader stood: %s from %s" % [kind, scroll.get_v_scroll_bar().value, stood])
	_verdict.check(failed.is_empty(), "in every list that runs down, the pad and Back show the focused row whole by the least move, and scrolling by hand is left alone: %s" % [failed])
	narrowing.free()
	_done()


## A virtual list of two hundred rows showing five: the pad on past the last
## slot moves it a whole row, the focus staying on that slot, whole.
func _a_virtual_list_moves_a_whole_row_by_the_pad_past_its_last_slot() -> void:
	_made = Fixture.new(root, {&"opens": "open"})
	var ui := _made.ui
	var source := Source.new()
	var long := LongList.new(_made.chimes, source.fetch, 10, 5, 5, Bound.new(func() -> Variant: return null))
	_made.commands.stand(&"rows", long)
	root.add_child(long)
	var slot := func(item: Bound) -> Desc: return ui.pressable(&"opens", {}, [ui.text(item.map(func(one: Variant) -> String: return "" if one == null else one["name"]))])
	ui.start(ui.app(&"app", [ui.stack([ui.screen(&"rows", [ui.virtual_list(long, slot).named(&"rows")], null, {on_fill = func(_token: Variant) -> void: long.look(null), on_empty = long.drop}), ui.screen(&"elsewhere", [ui.text("elsewhere")])])]))
	await _a_frame_passes()
	await _go(&"rows", 1)
	var rows: VirtualList = ui.node_named(&"rows")
	var last: Control = rows.get_slots()[-1]
	last.grab_focus()
	await _a_frame_passes()
	var first := long.get_first()
	var down := InputEventAction.new()
	down.action = &"ui_down"
	down.pressed = true
	root.push_input(down)
	await _a_frame_passes()
	_verdict.check(long.get_first() == first + 1 and last.has_focus() and rows.get_global_rect().grow(0.01).encloses(last.get_global_rect()), "the pad on past the last slot moves the list a whole row, and the focus stays on that slot, whole: %d -> %d" % [first, long.get_first()])
	var up := InputEventAction.new()
	up.action = &"ui_up"
	up.pressed = true
	var top: Control = rows.get_slots()[0]
	top.grab_focus()
	root.push_input(up)
	await _a_frame_passes()
	_verdict.check(long.get_first() == first and top.has_focus(), "and back past the first, a whole row back: %d" % long.get_first())
	long.free()
	_made.done()
