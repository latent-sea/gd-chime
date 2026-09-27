extends SceneTree

## What must be true of the leaf recipes: the navigation control, the
## card, the tab bar, the cell readouts, the countdown, the amount field,
## the moment, the instruction bar and attention's bubble.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_recipes.gd

const Fixture := preload("res://tests/fixture.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Layout := preload("res://addons/gd_chime/components/primitives/layout.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const When := preload("res://addons/gd_chime/components/primitives/when.gd")
const Anchored := preload("res://addons/gd_chime/components/primitives/anchored.gd")
const Going := preload("res://addons/gd_chime/components/primitives/going.gd")
const NavControl := preload("res://addons/gd_chime/components/recipes/nav_control.gd")
const Card := preload("res://addons/gd_chime/components/recipes/card.gd")
const Tabs := preload("res://addons/gd_chime/components/recipes/tab_bar.gd")
const Scroll := preload("res://addons/gd_chime/components/primitives/scroll.gd")
const Strip := preload("res://addons/gd_chime/components/primitives/strip.gd")
const Clipped := preload("res://addons/gd_chime/clipped_text.gd")
const CellReadout := preload("res://addons/gd_chime/components/recipes/cell_readout.gd")
const Countdown := preload("res://addons/gd_chime/components/recipes/countdown.gd")
const AmountField := preload("res://addons/gd_chime/components/recipes/amount_field.gd")
const Moment := preload("res://addons/gd_chime/components/recipes/moment.gd")
const InstructionBar := preload("res://addons/gd_chime/components/recipes/instruction_bar.gd")
const Attention := preload("res://addons/gd_chime/components/recipes/attention.gd")
const PressLocal := preload("res://addons/gd_chime/components/primitives/press_local.gd")
const Verdict := preload("res://tests/verdict.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")

var _verdict := Verdict.new()


## What a moment is presented while: told to present, it holds; told to dismiss, it does not.
class Presenting extends Fixture.Model:
	func told(action: StringName, payload: Dictionary) -> Phrase:
		set_value(&"flag", action == &"presents")
		return super(action, payload)


## An act in progress, for the instruction bar.
class Act extends Fixture.Model:
	func get_asking() -> Variant:
		return of(&"asking", false).read()

	func get_progress() -> Variant:
		return of(&"progress").read()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(400, 400)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_a_navigation_control_goes_where_its_place_says_an_inline_one_with_its_thing_and_a_play_is_absent_without_a_recording)
	await _verdict.states(_a_card_is_one_pressable_carrying_its_thing_and_an_empty_one_shows_its_ways_or_what_it_expects)
	await _verdict.states(_a_tab_bar_is_a_menu_item_per_tab_each_a_place)
	await _verdict.states(_a_tab_is_a_flap_on_its_panel_and_the_current_one_merges_into_it)
	await _verdict.states(_a_set_of_flaps_wider_than_its_room_scrolls_across_and_cuts_none)
	await _verdict.states(_the_current_flap_is_always_in_view_and_none_is_cut_at_either_end)
	await _verdict.states(_a_strip_rests_on_whole_flaps_moves_a_flap_at_a_time_and_covers_an_end_with_more_beyond)
	await _verdict.states(_a_strip_whose_holder_narrows_rests_again_on_whole_flaps_and_covers_the_end_with_more)
	await _verdict.states(_a_link_is_current_only_to_the_very_one_the_reader_is_on)
	await _verdict.states(_the_readouts_state_what_is_in_the_unit_s_mark_and_never_a_currency)
	await _verdict.states(_a_countdown_reads_the_time_left_and_an_amount_field_commits_a_line)
	await _verdict.states(_a_moment_is_raised_while_its_fact_holds_and_enters_no_history)
	await _verdict.states(_the_instruction_bar_says_the_ask_the_progress_and_the_way_out_and_the_prompts_when_idle)
	await _verdict.states(_a_bubble_attaches_to_the_control_the_prompts_name_and_pulses)
	await _verdict.states(_a_fading_bubble_says_its_own_actions_words)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


func _texts(node: Node) -> Array[String]:
	var found: Array[String] = []
	for child: Node in node.get_children():
		if child is Text:
			found.append((child as Text).get_text())
		found.append_array(_texts(child))
	return found


func _pressables(node: Node) -> Array:
	return node.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable)


func _a_navigation_control_goes_where_its_place_says_an_inline_one_with_its_thing_and_a_play_is_absent_without_a_recording() -> void:
	var made := Fixture.new(root, {&"opens_ledger": "open the ledger", &"opens_thing": "open", &"goes_back": "back", &"plays": "play"})
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes, &"app")
	model.set_value(&"items", {"id": 7, "name": "pear"})
	model.set_value(&"flag", null)
	made.commands.register(&"app", &"plays", model)
	model.refuse(&"plays", Phrase.of("no recording yet"))
	var strip := ui.row([NavControl.menu(ui, &"opens_ledger", &"ledger").named(&"menu"), NavControl.inline(ui, &"opens_thing", model.of(&"items"), {goes_to = &"thing"}).named(&"inline"), NavControl.back(ui, &"goes_back").named(&"back"), NavControl.play(ui, &"plays", model.of(&"flag"), &"recording").named(&"play")])
	ui.start(ui.app(&"app", [ui.column([strip, ui.stack([ui.screen(&"ledger", []), ui.screen(&"thing", []), ui.screen(&"recording", [])])])]))
	await _a_frame_passes()
	var app: Node = made.driver.index.app
	_verdict.check(app.performs == {&"opens_ledger": &"ledger", &"opens_thing": &"thing", &"goes_back": Driver.BACK, &"plays": &"recording"}, "each declares where it goes on its place: %s" % [app.performs])
	var inline: Pressable = ui.node_named(&"inline")
	_verdict.check(_texts(inline) == ["pear"] and inline.payload() == {"parameter": 7}, "an inline one wears its thing's name and carries its thing as the parameter: %s" % [inline.payload()])
	inline.pressed()
	_verdict.check(made.driver.get_top() == [&"app", &"thing"] and made.driver.get_parameter(&"thing") == 7, "pressed, the thing's place is entered as that thing: %s" % [made.driver.get_parameter(&"thing")])
	(ui.node_named(&"back") as Pressable).pressed()
	_verdict.check(made.driver.get_top() == [&"app", &"ledger"], "back retraces: %s" % [made.driver.get_top()])
	_verdict.check(not (ui.node_named(&"play") as Pressable).visible, "a play with no recording is absent, not inert")
	model.refuse_nothing()
	await _a_frame_passes()
	_verdict.check((ui.node_named(&"play") as Pressable).visible, "and present once there is one")
	model.free()
	made.done()


func _a_card_is_one_pressable_carrying_its_thing_and_an_empty_one_shows_its_ways_or_what_it_expects() -> void:
	var made := Fixture.new(root, {&"opens": "open", &"fills": "fill"})
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes, &"app")
	model.set_value(&"items", {"id": 3, "name": "fig", "won": 12})
	model.set_value(&"flag", null)
	var thing: Bound = model.of(&"items")
	var card := Card.list(ui, &"opens", thing, [ui.text(thing.field("name")), CellReadout.quantity(ui, thing.field("won"), "c")], {goes_to = &"detail"}).named(&"card")
	var telling := Card.tile(ui, &"opens", thing, [ui.text(thing.field("name")), Card.more(ui, ui.text("picked on tuesday"))], {goes_to = &"detail"}).named(&"telling")
	var empty := Card.empty(ui, [ui.pressable(&"fills")], model.of(&"flag")).named(&"empty")
	var waiting := Card.loading(ui, 3, {above = ui.text("its picture")}).named(&"waiting")
	made.commands.register(&"app", &"fills", model)
	ui.start(ui.app(&"app", [ui.column([card, telling, empty, waiting, ui.screen(&"detail", [])])]))
	await _a_frame_passes()
	var pressed: Pressable = ui.node_named(&"card")
	_verdict.check(_pressables(pressed).is_empty() and pressed.payload() == {"parameter": 3} and _texts(pressed) == ["fig", "c12"], "a list card is one pressable holding its readouts, carrying its thing: %s" % [_texts(pressed)])
	var tile: Pressable = ui.node_named(&"telling")
	var more: PressLocal = tile.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is PressLocal)[0]
	_verdict.check(_texts(tile) == ["fig", Card.MORE], "a card with more says so, its detail not there: %s" % [_texts(tile)])
	more.pressed()
	await _a_frame_passes()
	_verdict.check(_texts(tile) == ["fig", Card.LESS, "picked on tuesday"] and made.commands.get_last()["action"] != &"opens", "pressed, the detail is shown in place and the card was not opened: %s" % [_texts(tile)])
	more.pressed()
	await _a_frame_passes()
	_verdict.check(_texts(tile) == ["fig", Card.MORE], "pressed again, it is gone: %s" % [_texts(tile)])
	_verdict.check(_pressables(ui.node_named(&"empty")).size() == 1, "an empty position shows its ways to fill it")
	model.set_value(&"flag", "a fig")
	await _a_frame_passes()
	_verdict.check(_pressables(ui.node_named(&"empty")).is_empty() and _texts(ui.node_named(&"empty")) == ["Expecting a fig"], "reserved, it shows what it is expecting and its ways are gone: %s" % [_texts(ui.node_named(&"empty"))])
	var standing: Control = ui.node_named(&"waiting")
	var shapes: Array = standing.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return (part as Control).get(&"theme_type_variation") == Themes.PLACEHOLDER)
	_verdict.check(shapes.size() == 3 and _texts(standing) == ["its picture"] and _pressables(standing).is_empty(), "a card on its way is loading's shapes, one a line asked for, under what stands where its picture will, and nothing pressed: %d shapes, %s" % [shapes.size(), _texts(standing)])
	model.free()
	made.done()


func _a_tab_bar_is_a_menu_item_per_tab_each_a_place() -> void:
	var made := Fixture.new(root, {&"shows_a": "A", &"shows_b": "B"})
	var ui := made.ui
	ui.start(ui.app(&"app", [ui.column([Tabs.make(ui, [{"action": &"shows_a", "goes_to": &"a"}, {"action": &"shows_b", "goes_to": &"b"}]).named(&"tabs"), ui.stack([ui.screen(&"a", []), ui.screen(&"b", [])])])]))
	await _a_frame_passes()
	var tabs := _pressables(ui.node_named(&"tabs"))
	_verdict.check(tabs.size() == 2 and (tabs[1] as Pressable).get_goes_to() == &"b", "one menu item per tab, each to its place")
	(tabs[1] as Pressable).pressed()
	_verdict.check(made.driver.get_top() == [&"app", &"b"] and made.driver.get_state()["history"].size() == 2, "a tab pressed is a place entered, pushed onto the history: %s" % [made.driver.get_top()])
	made.done()


## A tab is a flap on the panel it reveals: given the content, the flaps
## sit over a panel with nothing between; the flap of the place the reader
## is on is CURRENT - selected, not unavailable - drawn taller in the
## panel's own fill with no reason under it, and the rest sit back.
func _a_tab_is_a_flap_on_its_panel_and_the_current_one_merges_into_it() -> void:
	var made := Fixture.new(root, {&"shows_a": "A", &"shows_b": "B"})
	var ui := made.ui
	ui.start(ui.app(&"app", [Tabs.make(ui, [{"action": &"shows_a", "goes_to": &"a"}, {"action": &"shows_b", "goes_to": &"b"}], [ui.stack([ui.screen(&"a", [ui.text("in a")]), ui.screen(&"b", [])])]).named(&"set")]))
	await _a_frame_passes()
	await _a_frame_passes()
	var set: Layout = ui.node_named(&"set")
	var strip: Control = set.get_child(0)
	var panel: Control = set.get_child(1)
	var tabs := _pressables(strip)
	var on: Pressable = tabs[0]
	var off: Pressable = tabs[1]
	_verdict.check(on.is_current() and not off.is_current() and on.get_state() == &"current" and off.get_state() == &"normal", "the flap of the place the reader is on is current, the other normal: %s %s" % [on.get_state(), off.get_state()])
	_verdict.check(on.reason().read() == null, "and the current flap gives no reason")
	_verdict.check(is_equal_approx(strip.get_global_rect().end.y, panel.global_position.y) and on.size.y > off.size.y and is_equal_approx(on.get_global_rect().end.y, off.get_global_rect().end.y), "the flaps sit on the panel with nothing between, the current taller on the same baseline: %s over %s" % [on.get_global_rect(), off.get_global_rect()])
	_verdict.check(on.get_theme_stylebox(&"current").bg_color == panel.get_theme_stylebox(&"panel").bg_color, "the current flap is in the panel's fill")
	off.pressed()
	await _a_frame_passes()
	_verdict.check(off.get_state() == &"current" and on.get_state() == &"normal", "pressed, the other flap is the current one")
	made.done()


## Twelve flaps in a room for three or four: the strip is exactly as tall as
## its flaps and scrolls across - every flap whole, at its own width, none
## cut off at the strip's edge by being squeezed - and a flap the focus
## moves to, far along, is brought into view.
func _a_set_of_flaps_wider_than_its_room_scrolls_across_and_cuts_none() -> void:
	var declared := {}
	var tabs: Array = []
	var screens: Array = []
	# twelve tabs, each a place of its own
	for at: int in 12:
		declared[StringName("shows_%d" % at)] = "screen number %d" % at
		tabs.append({"action": StringName("shows_%d" % at), "goes_to": StringName("screen_%d" % at)})
		screens.append(StringName("screen_%d" % at))
	var made := Fixture.new(root, declared)
	var ui := made.ui
	ui.start(ui.app(&"app", [Tabs.make(ui, tabs, [ui.stack(screens.map(func(named: StringName) -> Desc: return ui.screen(named, [])))]).named(&"set")]))
	await _a_frame_passes()
	await _a_frame_passes()
	var set: Layout = ui.node_named(&"set")
	var strip: ScrollContainer = set.get_child(0)
	var flaps := _pressables(strip)
	var tallest: float = flaps.map(func(flap: Control) -> float: return flap.size.y).max()
	_verdict.check(flaps.size() == 12 and is_equal_approx(strip.size.y, tallest), "the strip is as tall as its tallest flap: %s against %s" % [strip.size.y, tallest])
	_verdict.check(flaps.all(func(flap: Control) -> bool: return flap.size.x >= flap.get_combined_minimum_size().x), "every flap is at least as wide as its words")
	_verdict.check(strip.get_child(0).size.x > strip.size.x, "together they are wider than the room, and scroll across: %s in %s" % [strip.get_child(0).size.x, strip.size.x])
	(flaps[11] as Control).grab_focus()
	await _a_frame_passes()
	_verdict.check(strip.get_global_rect().encloses((flaps[11] as Control).get_global_rect()), "the last flap, given the focus, is brought into view: %s" % strip.scroll_horizontal)
	made.done()


## The flap of the place the reader is on is in view whenever it is current,
## however it came to be - a press that gives no focus, the driver moving,
## Back - and a strip resting at either end shows the flap at that end whole.
func _the_current_flap_is_always_in_view_and_none_is_cut_at_either_end() -> void:
	var declared := {}
	var tabs: Array = []
	var screens: Array = []
	# twelve tabs, each a place of its own, two or three to the room
	for at: int in 12:
		declared[StringName("shows_%d" % at)] = "tab %d" % at
		tabs.append({"action": StringName("shows_%d" % at), "goes_to": StringName("screen_%d" % at)})
		screens.append(StringName("screen_%d" % at))
	var made := Fixture.new(root, declared)
	var ui := made.ui
	var set :=Tabs.make(ui, tabs, [ui.stack(screens.map(func(named: StringName) -> Desc: return ui.screen(named, [])))]).named(&"set")
	# a room of a fractional width, as a share of a window is: the offset that shows its far end is not whole
	ui.start(ui.app(&"app", [ui.row([set.basis(0.6071), ui.text("").grow()])]))
	await _a_frame_passes()
	await _a_frame_passes()
	var strip: Scroll = (ui.node_named(&"set") as Layout).get_child(0)
	var flaps := _pressables(strip)
	var seen := func(flap: Control) -> bool: return strip.get_shown().grow(0.01).encloses(flap.get_global_rect())
	(flaps[9] as Pressable).pressed()
	await _a_frame_passes()
	_verdict.check((flaps[9] as Pressable).is_current() and not (flaps[9] as Control).has_focus() and seen.call(flaps[9]), "a flap pressed without the focus, current, is brought into view: %s at %s" % [(flaps[9] as Control).get_global_rect(), strip.scroll_horizontal])
	made.driver.move(&"screen_1")
	await _a_frame_passes()
	_verdict.check(seen.call(flaps[1]), "the driver moving to a place far back along brings its flap into view: %s" % strip.scroll_horizontal)
	made.driver.move(Driver.BACK)
	await _a_frame_passes()
	_verdict.check((flaps[9] as Pressable).is_current() and seen.call(flaps[9]), "Back to a place brings its flap into view again: %s %s at %s in %s" % [(flaps[9] as Pressable).is_current(), (flaps[9] as Control).get_global_rect(), strip.get_h_scroll_bar().value, strip.get_global_rect()])
	strip.scroll_horizontal = 100000
	await _a_frame_passes()
	_verdict.check(seen.call(flaps[11]), "the strip scrolled as far as it goes shows the last flap whole: %s ends at %s, the strip at %s" % [(flaps[11] as Control).get_global_rect(), (flaps[11] as Control).get_global_rect().end.x, strip.get_global_rect()])
	strip.scroll_horizontal = 0
	await _a_frame_passes()
	_verdict.check(seen.call(flaps[0]), "and scrolled back to its start, the first flap whole: %s" % (flaps[0] as Control).get_global_rect())
	made.done()


## A strip whose flaps are wider than its room shows whole flaps only -
## wherever it rests, whatever moved it - every flap wholly in what it shows
## or wholly out of it, and none of their words cut (clipped_text.gd). Moved
## by any amount it goes a whole flap that way; an end with more beyond is
## covered by the look's box, and a flap under a cover takes no press.
func _a_strip_rests_on_whole_flaps_moves_a_flap_at_a_time_and_covers_an_end_with_more_beyond() -> void:
	var declared := {}
	var tabs: Array = []
	var screens: Array = []
	# twelve tabs of words of different lengths, each a place of its own
	for at: int in 12:
		declared[StringName("shows_%d" % at)] = "tab %s" % "ab".repeat(1 + at % 4)
		tabs.append({"action": StringName("shows_%d" % at), "goes_to": StringName("screen_%d" % at)})
		screens.append(StringName("screen_%d" % at))
	var made := Fixture.new(root, declared)
	var ui := made.ui
	var set := Tabs.make(ui, tabs, [ui.stack(screens.map(func(named: StringName) -> Desc: return ui.screen(named, [])))]).named(&"set")
	ui.start(ui.app(&"app", [ui.row([set.basis(0.6071), ui.text("").grow()])]))
	await _a_frame_passes()
	await _a_frame_passes()
	var strip: Scroll = (ui.node_named(&"set") as Layout).get_child(0)
	var flaps := _pressables(strip)
	var window := Rect2(Vector2.ZERO, root.size)
	var shown_whole := func() -> bool: return flaps.all(func(flap: Control) -> bool: return strip.get_shown().grow(0.01).encloses(flap.get_global_rect()) or not strip.get_shown().intersects(flap.get_global_rect()))
	var covers: Array = strip.get_children(true).filter(func(part: Node) -> bool: return part is Strip.Cover)
	var in_view := func() -> Array: return range(flaps.size()).filter(func(at: int) -> bool: return strip.get_shown().grow(0.01).encloses((flaps[at] as Control).get_global_rect()))
	_verdict.check(shown_whole.call() and Clipped.clipped(root, window).is_empty(), "at rest at its start every flap is wholly shown or wholly not, and no words are cut: %s" % [Clipped.clipped(root, window)])
	_verdict.check(not covers[0].visible and covers[1].visible and covers[1].has_theme_stylebox(&"more_after", Strip.TYPE), "at its start only the far end is covered, with more beyond it, in the look's box")
	var cut: Array = []
	var steps: Array = []
	# a nudge of a few pixels at a time along the whole strip
	for step: int in 14:
		var was: Array = in_view.call()
		strip.get_h_scroll_bar().value += 5.0
		await _a_frame_passes()
		steps.append([was.front(), (in_view.call() as Array).front()])
		if not shown_whole.call() or not Clipped.clipped(root, window).is_empty():
			cut.append(step)
	_verdict.check(cut.is_empty(), "nudged along a few pixels at a time, it never shows part of a flap, nor cuts a word: at steps %s" % [cut])
	_verdict.check(steps.slice(0, 3).all(func(pair: Array) -> bool: return pair[1] == pair[0] + 1), "and each nudge moves it on a whole flap: %s" % [steps])
	_verdict.check(covers[0].visible and not covers[1].visible and (in_view.call() as Array).back() == 11, "at its far end the near end is covered and the last flap is shown whole: %s" % [in_view.call()])
	strip.get_h_scroll_bar().value -= 3.0
	await _a_frame_passes()
	strip.get_h_scroll_bar().value -= 3.0
	await _a_frame_passes()
	_verdict.check(covers[0].visible and covers[1].visible and shown_whole.call(), "moved back twice, it is in the middle with both ends covered and every flap whole: %s" % [in_view.call()])
	var under: Array = flaps.filter(func(flap: Control) -> bool: return covers[1].get_global_rect().intersects(flap.get_global_rect()))
	var drawn_last: Array = [strip.get_child(strip.get_child_count(true) - 2, true), strip.get_child(strip.get_child_count(true) - 1, true)]
	_verdict.check(not under.is_empty() and covers.all(func(cover: Control) -> bool: return cover.mouse_filter == Control.MOUSE_FILTER_STOP and drawn_last.has(cover)), "a flap part under a cover is drawn under it, and the cover, drawn over everything the strip holds, takes the press")
	var rest := Strip.resting([0.0, 110.0, 220.0, 330.0] as Array[float], [100.0, 210.0, 320.0, 430.0] as Array[float], 250.0, 20.0, 0.0, 0, 3)
	_verdict.check(rest["first"] == 2 and is_equal_approx(rest["offset"], 180.0) and rest["before"] and not rest["after"] and is_equal_approx(rest["shown_from"], 40.0) and is_equal_approx(rest["shown_to"], 250.0), "worked by hand: four flaps of 100 with 10 between in 250 of room, the last kept in view: the last two shown, flush with the far edge, the 40 before them covered: %s" % [rest])
	made.done()


## Five flaps growing to share a wide strip, all shown; the window then
## narrowed - the strip's holder with it - past what the five need: the
## strip rests again on whole flaps, the far end covered with more beyond,
## and no flap is cut part-way at the edge, as was ruled: whole flaps only,
## whether or not the strip scrolls.
func _a_strip_whose_holder_narrows_rests_again_on_whole_flaps_and_covers_the_end_with_more() -> void:
	var declared := {}
	var tabs: Array = []
	var screens: Array = []
	# five tabs, each a place of its own
	for at: int in 5:
		declared[StringName("shows_%d" % at)] = "takings %d" % at
		tabs.append({"action": StringName("shows_%d" % at), "goes_to": StringName("screen_%d" % at)})
		screens.append(StringName("screen_%d" % at))
	var made := Fixture.new(root, declared)
	var ui := made.ui
	root.size = Vector2i(1400, 400)
	ui.start(ui.app(&"app", [Tabs.make(ui, tabs, [ui.stack(screens.map(func(named: StringName) -> Desc: return ui.screen(named, [])))]).named(&"set")]))
	await _a_frame_passes()
	await _a_frame_passes()
	var strip: Scroll = (ui.node_named(&"set") as Layout).get_child(0)
	var flaps := _pressables(strip)
	var covers: Array = strip.get_children(true).filter(func(part: Node) -> bool: return part is Strip.Cover)
	var shown_whole := func() -> bool: return flaps.all(func(flap: Control) -> bool: return strip.get_shown().grow(0.01).encloses(flap.get_global_rect()) or not strip.get_shown().intersects(flap.get_global_rect()))
	_verdict.check(shown_whole.call() and not covers[1].visible and strip.get_shown().grow(0.01).encloses((flaps[4] as Control).get_global_rect()), "wide, every flap is shown whole and no end is covered")
	root.size = Vector2i(460, 400)
	await _a_frame_passes()
	await _a_frame_passes()
	var window := Rect2(Vector2.ZERO, root.size)
	_verdict.check(shown_whole.call() and Clipped.clipped(root, window).is_empty(), "narrowed, every flap is wholly shown or wholly not, and no words are cut: %s" % [Clipped.clipped(root, window)])
	_verdict.check(covers[1].visible, "and the far end is covered, with more beyond it")
	root.size = Vector2i(400, 400)
	made.done()


func _the_readouts_state_what_is_in_the_unit_s_mark_and_never_a_currency() -> void:
	var made := Fixture.new(root, {&"compares": "compare"})
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes)
	model.set_value(&"items", {"won": 18400, "kind": "sprinter", "recent": [3, 5, 2, 8], "marks": 4, "strength": 0.42})
	var thing: Bound = model.of(&"items")
	made.commands.register(Chimes.GLOBAL, &"compares", model)
	ui.start(ui.app(&"app", [ui.column([CellReadout.quantity(ui, thing.field("won"), "c"), CellReadout.bar(ui, thing.field("won"), 1000000.0), CellReadout.label(ui, thing.field("kind")), CellReadout.trace(ui, thing.field("recent")), CellReadout.mark(ui, thing.field("marks"), &"diamond"), CellReadout.relative(ui, &"compares", thing.field("strength"), "closeness")]).named(&"cell")]))
	var cell: Node = ui.node_named(&"cell")
	await _a_frame_passes()
	var texts := _texts(cell)
	_verdict.check(texts[0] == "c18,400" and texts[1] == "sprinter" and texts[2] == "4" and texts[3] == "closeness 42%", "the quantity with its mark before it and grouped, the label, the count, and the relative value saying what it is the strength of: %s" % [texts])
	_verdict.check(_pressables(cell).size() == 1, "the relative value is a region of its own")
	ui.motion.by_hand = true
	ui.motion.still = false
	model.set_value(&"items", {"won": -5, "kind": "", "recent": [], "marks": 0, "strength": null})
	await _a_frame_passes()
	ui.motion.step(0.09)
	await _a_frame_passes()
	var rolling: String = _texts(cell)[0]
	_verdict.check(rolling != "c18,400" and rolling != "c-5", "moved, the quantity rolls to its new figure: on the way it is neither: %s" % rolling)
	ui.motion.step(0.09)
	await _a_frame_passes()
	_verdict.check(_texts(cell)[0] == "c-5" and _texts(cell)[2] == "" and _texts(cell)[3] == "", "moved, the readouts re-read: a minus kept, no marks no count, no strength no words: %s" % [_texts(cell)])
	model.free()
	made.done()


func _a_countdown_reads_the_time_left_and_an_amount_field_commits_a_line() -> void:
	var made := Fixture.new(root, {&"stakes": "stake"})
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes)
	model.set_value(&"flag", 125.0)
	made.commands.register(Chimes.GLOBAL, &"stakes", model)
	var pieces := ui.build(ui.column([Countdown.make(ui, model.of(&"flag"), "now"), AmountField.make(ui, &"stakes", "c").named(&"amount")]), root)
	await _a_frame_passes()
	_verdict.check(_texts(pieces)[0] == "2:05", "the countdown reads minutes and seconds: %s" % _texts(pieces)[0])
	model.set_value(&"flag", 0)
	await _a_frame_passes()
	_verdict.check(_texts(pieces)[0] == "now", "and its words once it has run out")
	var line: LineEdit = ui.node_named(&"amount").find_children("*", "LineEdit", true, false)[0]
	line.text = "250"
	line.text_submitted.emit("250")
	_verdict.check(model.told_actions == [&"stakes"] and made.commands.get_last()["payload"] == {"line": "250"}, "the amount field commits the line as its action, the mark before it: %s" % [_texts(pieces)])
	pieces.free()
	model.free()
	made.done()


func _a_moment_is_raised_while_its_fact_holds_and_enters_no_history() -> void:
	var made := Fixture.new(root, {&"presents": "present", &"dismisses": "carry on"})
	var ui := made.ui
	var act := Presenting.new(made.chimes, &"app")
	# the fact it is up while: set by the command presenting it and by the one dismissing it

	for action: StringName in [&"presents", &"dismisses"]:
		made.commands.register(Chimes.GLOBAL, action, act)
	var moment := Moment.make(ui, act.of(&"flag", false), [ui.text("the season ended")], &"dismisses")
	ui.start(ui.app(&"app", [ui.stack([ui.column([ui.text("the work"), ui.pressable(&"presents", {}, [ui.text("present")])]), moment])]))
	await _a_frame_passes()
	_verdict.check(not made.driver.is_raised(), "while its fact does not hold, nothing stands over the app: %s" % [made.driver.get_top()])
	made.commands.dispatch(&"app", &"presents", {})
	await _a_frame_passes()
	var place: Node = made.driver.index.place_named(moment.get_place())
	_verdict.check(made.driver.get_top() == [moment.get_place()] and _texts(place).has("the season ended") and _pressables(place).size() == 1, "the command that makes its fact hold raises it, showing what the boundary is about and one way on - its shade is ground, never a press")
	_verdict.check(made.driver.get_state()["history"].size() == 1, "and it enters no history entry: the history has not moved")
	(_pressables(place)[0] as Pressable).pressed()
	await _a_frame_passes()
	_verdict.check(act.told_actions == [&"presents", &"dismisses"] and not made.driver.is_raised(), "dismissed, its fact stops holding and it is lowered: %s" % [made.driver.get_top()])
	act.free()
	made.done()


func _the_instruction_bar_says_the_ask_the_progress_and_the_way_out_and_the_prompts_when_idle() -> void:
	var made := Fixture.new(root, {&"cancels": "cancel", &"saves": "save"})
	var ui := made.ui
	var act := Act.new(made.chimes, &"app")
	act.set_value(&"words", "")
	act.set_value(&"asking", false)
	act.set_value(&"progress", null)
	made.commands.register(&"app", &"cancels", act)
	made.commands.register(&"app", &"saves", act)
	ui.start(ui.app(&"app", [ui.column([InstructionBar.make(ui, act, &"cancels").named(&"bar"), ui.pressable(&"saves")])]))
	await _a_frame_passes()
	var bar: Node = ui.node_named(&"bar")
	_verdict.check(_texts(bar)[0] == "" and _pressables(bar).is_empty(), "idle with nothing to say, the bar is empty and has no way out")
	made.prompts.raise(&"guide", &"saves")
	await _a_frame_passes()
	_verdict.check(_texts(bar)[0] == "save", "idle, it says the prompts' words: %s" % _texts(bar)[0])
	act.set_value(&"words", "choose a partner")
	act.set_value(&"asking", true)
	act.set_value(&"progress", {"count": 1, "ceiling": 3})
	act.set_value(&"words", "choose a partner")
	await _a_frame_passes()
	_verdict.check(_texts(bar)[0] == "choose a partner" and _texts(bar)[1] == "1 of 3" and _pressables(bar).size() == 1, "asking, it says the ask, the progress against its ceiling, and the way out: %s" % [_texts(bar)])
	act.set_value(&"asking", false)
	act.set_value(&"words", "the round produced two")
	act.set_value(&"progress", null)
	act.set_value(&"progress", null)
	await _a_frame_passes()
	_verdict.check(_texts(bar)[0] == "the round produced two" and _pressables(bar).is_empty(), "done, it says what resolved and the way out is gone")
	act.free()
	made.done()


func _a_bubble_attaches_to_the_control_the_prompts_name_and_pulses() -> void:
	var made := Fixture.new(root, {&"saves": "save the day", &"waves": "wave"})
	var ui := made.ui
	made.answer([&"saves", &"waves"])
	ui.start(ui.app(&"app", [ui.stack([ui.row([ui.pressable(&"saves").named(&"save"), ui.pressable(&"waves")]), Attention.bubble(ui, &"save", &"saves").named(&"bubble")])]))
	await _a_frame_passes()
	var bubble: When = ui.node_named(&"bubble")
	_verdict.check(bubble.get_child_count() == 0, "with nothing prompted, no bubble")
	made.prompts.raise(&"guide", &"saves")
	await _a_frame_passes()
	await _a_frame_passes()
	var save: Control = ui.node_named(&"save")
	var attached: Anchored = bubble.get_child(0)
	_verdict.check(is_equal_approx(attached.get_global_rect().end.y, save.global_position.y) and _texts(attached) == ["save the day"], "the prompts naming its action, a bubble sits just above the control with the prompts' words: %s" % [_texts(attached)])
	_verdict.check(attached.find_children("*", "Control", true, false).any(func(part: Node) -> bool: return part.get_script() == ui.primitive(&"pulse")), "and it pulses")
	made.prompts.raise(&"guide", &"waves")
	await _a_frame_passes()
	_verdict.check(bubble.get_child_count() == 0, "the prompts naming another, the bubble is gone: one glow at a time")
	made.done()


## The prompts moving on while motion runs: the bubble fades out over the
## look's transition, and says its own action's words the whole way, never
## the words of the action the prompts name now.
func _a_fading_bubble_says_its_own_actions_words() -> void:
	var made := Fixture.new(root, {&"saves": "save the day", &"waves": "wave"})
	var ui := made.ui
	made.answer([&"saves", &"waves"])
	ui.start(ui.app(&"app", [ui.stack([ui.row([ui.pressable(&"saves").named(&"save"), ui.pressable(&"waves")]), Attention.bubble(ui, &"save", &"saves").named(&"bubble")])]))
	made.prompts.raise(&"guide", &"saves")
	await _a_frame_passes()
	await _a_frame_passes()
	var bubble: When = ui.node_named(&"bubble")
	var attached: Anchored = bubble.get_child(0)
	ui.motion.still = false
	ui.motion.by_hand = true
	made.prompts.raise(&"guide", &"waves")
	await _a_frame_passes()
	ui.motion.step(0.05)
	await _a_frame_passes()
	_verdict.check(Going.is_going(attached) and attached.is_visible_in_tree() and _texts(attached) == ["save the day"], "the prompts naming another, the bubble on its way out still says its own action's words: going %s, %s" % [Going.is_going(attached), [_texts(attached)]])
	ui.motion.step(10.0)
	await _a_frame_passes()
	_verdict.check(bubble.get_child_count() == 0, "and once its exit has run, it is gone")
	made.done()


## On the screen of item 7, a link to item 7 is current and a link to item
## 8 is not - pressing it would move - while a tab on its own place, which
## carries no parameter against a place entered with none, is current.
func _a_link_is_current_only_to_the_very_one_the_reader_is_on() -> void:
	var made := Fixture.new(root, {&"opens": "open", &"shows_list": "list"})
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes, &"app")
	model.set_value(&"items", [{"id": 7, "name": "seven"}, {"id": 8, "name": "eight"}])
	var items: Bound = model.of(&"items")
	var links := ui.row([NavControl.inline(ui, &"opens", items.field(0), {goes_to = &"item"}).named(&"to_seven"), NavControl.inline(ui, &"opens", items.field(1), {goes_to = &"item"}).named(&"to_eight"), NavControl.menu(ui, &"shows_list", &"list").named(&"tab")])
	ui.start(ui.app(&"app", [ui.column([links, ui.stack([ui.screen(&"list", []), ui.screen(&"item", [])])])]))
	await _a_frame_passes()
	var to_seven: Pressable = ui.node_named(&"to_seven")
	var to_eight: Pressable = ui.node_named(&"to_eight")
	var tab: Pressable = ui.node_named(&"tab")
	_verdict.check(tab.is_current() and not to_seven.is_current() and not to_eight.is_current(), "on the list, the tab to the list is current and neither item link is")
	to_seven.pressed()
	await _a_frame_passes()
	_verdict.check(made.driver.get_parameter(&"item") == 7 and to_seven.is_current() and not to_eight.is_current() and not tab.is_current(), "on item 7, the link to 7 is current and the link to 8 is not: %s %s" % [to_seven.get_state(), to_eight.get_state()])
	_verdict.check(to_eight.reason().read() == null and to_eight.is_usable(), "and the link to 8 is an ordinary usable link")
	to_eight.pressed()
	await _a_frame_passes()
	_verdict.check(made.driver.get_parameter(&"item") == 8 and to_eight.is_current() and not to_seven.is_current(), "pressed, it moves to 8, and now that link is the current one")
	model.free()
	made.done()
