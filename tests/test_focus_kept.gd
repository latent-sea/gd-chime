extends SceneTree

## What must be true of where the focus is remembered and how it is given back.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_focus_kept.gd
##
## An app view's focus is kept with its history entry: Back gives it back
## exactly where it was in that entry; a fresh visit is a new entry and lands
## on the default, never where the reader was last time; the same screen
## with other parameters is another entry.
##
## A pop-up keeps the focus of its own only while it is up: moving between
## tabs inside it keeps each tab's, and lowered it forgets, so the next
## raise lands on its default; what opened it is given the focus back as it
## is lowered; and focus given back puts a scroll back where the reader
## stood and then moves it only as far as shows the focused row whole, as
## was ruled (2026-09-19) - for a row the reader had scrolled out of view,
## the least move that brings it in.

const Fixture := preload("res://tests/fixture.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Verdict := preload("res://tests/verdict.gd")

var _verdict := Verdict.new()
var _made: Fixture
var _model: Fixture.Model


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(400, 400)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_back_gives_a_view_its_focus_exactly_where_it_was_in_that_entry)
	await _verdict.states(_a_fresh_visit_lands_on_the_default_never_where_the_reader_was_last_time)
	await _verdict.states(_the_same_screen_with_other_parameters_is_another_entry)
	await _verdict.states(_two_visits_to_one_screen_each_keep_their_own_focus)
	await _verdict.states(_lowered_a_pop_up_forgets_its_own_focus_and_the_next_raise_lands_on_its_default)
	await _verdict.states(_while_it_is_up_moving_between_its_tabs_keeps_each_tab_s_focus)
	await _verdict.states(_lowered_the_focus_goes_back_to_what_opened_it)
	await _verdict.states(_focus_given_back_never_scrolls_the_scroll_it_stands_in)
	await _verdict.states(_focus_on_a_row_scrolled_out_of_view_is_given_back_whole_by_the_least_move)
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


func _button(named: StringName) -> Pressable:
	return _made.ui.node_named(named)


## An app with an opener, and a pop-up of two tabs, each with two buttons.
func _standing() -> void:
	_made = Fixture.new(root, {&"opens": "open", &"does": "do"})
	var ui := _made.ui
	_model = Fixture.Model.new(_made.chimes)
	for action: StringName in [&"opens", &"does"]:
		_made.commands.register(Chimes.GLOBAL, action, _model)
	var tab := func(named: StringName) -> Desc: return ui.screen(named, [ui.column([ui.pressable(&"does", {}, [ui.text("first")]).named(StringName(named + " first")), ui.pressable(&"does", {}, [ui.text("second")]).named(StringName(named + " second"))])])
	var asking := ui.pop_up(&"asking", func(_which: Bound) -> Desc: return ui.stack([tab.call(&"tab_a"), tab.call(&"tab_b")]))
	# something before the opener, so the app's default focus is not the opener itself
	ui.start(ui.app(&"app", [ui.column([ui.pressable(&"does", {}, [ui.text("something else")]).named(&"before"), ui.pressable(&"opens", {}, [ui.text("open")], &"Pressable").opens(asking).named(&"opener")])]))

	await _a_frame_passes()


func _done() -> void:
	_model.free()
	_made.done()


## An app of two screens side by side, each with two buttons; the reader on the first.
func _views() -> void:
	_made = Fixture.new(root, {&"does": "do"})
	var ui := _made.ui
	_model = Fixture.Model.new(_made.chimes)
	_made.commands.register(Chimes.GLOBAL, &"does", _model)
	var view := func(named: StringName) -> Desc: return ui.screen(named, [ui.column([ui.pressable(&"does", {}, [ui.text("first")]).named(StringName(named + " first")), ui.pressable(&"does", {}, [ui.text("second")]).named(StringName(named + " second"))])])
	ui.start(ui.app(&"app", [ui.stack([view.call(&"one"), view.call(&"two")])]))
	await _a_frame_passes()


func _back_gives_a_view_its_focus_exactly_where_it_was_in_that_entry() -> void:
	await _views()
	_button(&"one second").grab_focus()
	await _go(&"two")
	_verdict.check(_button(&"two first").has_focus(), "on the other screen, its default has the focus")
	await _back()
	_verdict.check(_button(&"one second").has_focus(), "Back, the focus is where it was in that entry - not the screen's default: %s" % root.gui_get_focus_owner())
	_done()


## Visited, left by Back - so the history lets that entry go - and visited
## again: a new entry, on the default.
func _a_fresh_visit_lands_on_the_default_never_where_the_reader_was_last_time() -> void:
	await _views()
	await _go(&"two")
	_button(&"two second").grab_focus()
	await _back()
	await _go(&"two")
	_verdict.check(_button(&"two first").has_focus() and not _button(&"two second").has_focus(), "visited afresh, the screen lands on its default - not where the reader was last time: %s" % root.gui_get_focus_owner())
	_done()


## One, two, one again by a link: two visits to one screen are two entries.
## The second lands fresh; Back through them finds each where it was.
func _two_visits_to_one_screen_each_keep_their_own_focus() -> void:
	await _views()
	_button(&"one second").grab_focus()
	await _go(&"two")
	await _go(&"one")
	_verdict.check(_button(&"one first").has_focus(), "one again by a link is a fresh entry, on its default - not the first visit's focus: %s" % root.gui_get_focus_owner())
	await _back()
	await _back()
	_verdict.check(_button(&"one second").has_focus(), "and Back to the first visit finds the first's: %s" % root.gui_get_focus_owner())
	_done()


func _the_same_screen_with_other_parameters_is_another_entry() -> void:
	await _views()
	await _go(&"two", 7)
	_button(&"two second").grab_focus()
	await _go(&"two", 8)
	_verdict.check(_button(&"two first").has_focus(), "the same screen as 8 lands on its default - the focus on 7 never carries over: %s" % root.gui_get_focus_owner())
	await _back()
	_verdict.check(_button(&"two second").has_focus(), "and Back to 7 finds it where it was on 7: %s" % root.gui_get_focus_owner())
	_done()


func _lowered_a_pop_up_forgets_its_own_focus_and_the_next_raise_lands_on_its_default() -> void:
	await _standing()
	await _go(&"tab_a")
	_verdict.check(_button(&"tab_a first").has_focus(), "raised, the pop-up's default has the focus")
	_button(&"tab_a second").grab_focus()
	await _back()
	await _go(&"tab_a")
	_verdict.check(_button(&"tab_a first").has_focus() and not _button(&"tab_a second").has_focus(), "lowered and raised again, it lands on its default - not where the focus was last time: %s" % root.gui_get_focus_owner())
	_done()


func _while_it_is_up_moving_between_its_tabs_keeps_each_tab_s_focus() -> void:
	await _standing()
	await _go(&"tab_a")
	_button(&"tab_a second").grab_focus()
	await _go(&"tab_b")
	_verdict.check(_button(&"tab_b first").has_focus(), "the other tab lands on its default")
	await _go(&"tab_a")
	_verdict.check(_button(&"tab_a second").has_focus(), "while the pop-up is up, back on the first tab the focus is where it was left: %s" % root.gui_get_focus_owner())
	_done()


func _lowered_the_focus_goes_back_to_what_opened_it() -> void:
	await _standing()
	_button(&"opener").grab_focus()
	_button(&"opener").pressed()
	await _a_frame_passes()
	_verdict.check(_made.driver.get_top().has(&"tab_a") and _button(&"tab_a first").has_focus(), "the opener pressed, the pop-up is up with its default focused")
	await _back()
	_verdict.check(_button(&"opener").has_focus(), "lowered, the focus is back on what opened it - not on the app's default: %s" % root.gui_get_focus_owner())
	_done()


## Rows in a scroll, stood far down with the focus on one there; a detour,
## and while the reader is away the scroll moved to the top; Back: the
## focus is on that row and the scroll stands where the reader stood.
func _focus_given_back_never_scrolls_the_scroll_it_stands_in() -> void:
	_made = Fixture.new(root, {&"opens": "open"})
	var ui := _made.ui
	_model = Fixture.Model.new(_made.chimes)
	_made.commands.register(Chimes.GLOBAL, &"opens", _model)
	_model.set_value(&"items", range(20).map(func(at: int) -> Dictionary: return {"id": at}))
	var row := func(item: Bound) -> Desc: return ui.pressable(&"opens", {}, [ui.text(item.field("id"))])
	var listed := ui.each(_model.of(&"items"), row, func(item: Dictionary) -> int: return item["id"]).pieces_named(&"row ")
	ui.start(ui.app(&"app", [ui.stack([ui.screen(&"list", [ui.scroll(listed).named(&"scroll")]), ui.screen(&"elsewhere", [ui.pressable(&"opens", {}, [ui.text("elsewhere")])])])]))
	await _a_frame_passes()
	await _go(&"list", 1)
	var scroll: ScrollContainer = ui.node_named(&"scroll")
	scroll.scroll_vertical = 500
	await _a_frame_passes()
	var far: Control = ui.node_named(&"row 13")
	far.grab_focus()
	await _a_frame_passes()
	var stood: int = scroll.scroll_vertical
	await _go(&"elsewhere")
	scroll.scroll_vertical = 0
	await _a_frame_passes()
	await _back()
	_verdict.check(far.has_focus() and scroll.scroll_vertical == stood, "back, the focus is on that row and the scroll stands where the reader stood on that view: %d" % scroll.scroll_vertical)
	_done()


## The focus on a row, and then the reader scrolls on with the wheel, the
## row out of view but still focused - left so while they scroll by hand; a
## detour and Back: the row has the focus again, and the scroll, put back
## where the reader left it, has moved only as far as shows the row whole.
func _focus_on_a_row_scrolled_out_of_view_is_given_back_whole_by_the_least_move() -> void:
	_made = Fixture.new(root, {&"opens": "open"})
	var ui := _made.ui
	_model = Fixture.Model.new(_made.chimes)
	_made.commands.register(Chimes.GLOBAL, &"opens", _model)
	_model.set_value(&"items", range(30).map(func(at: int) -> Dictionary: return {"id": at}))
	var row := func(item: Bound) -> Desc: return ui.pressable(&"opens", {}, [ui.text(item.field("id"))])
	var listed := ui.each(_model.of(&"items"), row, func(item: Dictionary) -> int: return item["id"]).pieces_named(&"row ")
	ui.start(ui.app(&"app", [ui.stack([ui.screen(&"list", [ui.scroll(listed).named(&"scroll")]), ui.screen(&"elsewhere", [ui.pressable(&"opens", {}, [ui.text("elsewhere")])])])]))
	await _a_frame_passes()
	await _go(&"list")
	var scroll: ScrollContainer = ui.node_named(&"scroll")
	var first: Control = ui.node_named(&"row 1")
	first.grab_focus()
	await _a_frame_passes()
	# where the row stands in what the scroll holds
	var at: float = first.get_global_rect().position.y - scroll.get_global_rect().position.y + scroll.get_v_scroll_bar().value
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	wheel.position = scroll.get_global_rect().get_center()
	root.push_input(wheel)
	await _a_frame_passes()
	scroll.scroll_vertical = 900
	await _a_frame_passes()
	_verdict.check(first.has_focus() and not scroll.get_global_rect().intersects(first.get_global_rect()), "scrolled on by hand, the row keeps the focus out of view")
	await _go(&"elsewhere")
	await _back()
	_verdict.check(first.has_focus() and is_equal_approx(scroll.get_v_scroll_bar().value, at), "back, the row has the focus and the scroll has moved from where the reader left it only as far as shows the row whole, its top at the top: %s against %s" % [scroll.get_v_scroll_bar().value, at])
	_done()
