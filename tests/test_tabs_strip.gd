extends SceneTree

## What must be true of tabs as a strip (tab_bar.gd's of_presses and
## of_local): the flaps share the strip's width while every one fits at its
## least, with nothing to scroll; where they do not fit, every flap stands
## whole, at least its least, and the strip scrolls across; the current flap
## is in view in every state at every room; the flap of the current press,
## and of the local's choice, is drawn so and no other; a flap of a local,
## pressed, chooses its value; every flap of a local is in one type size;
## and a strip standing alone in its place, the app's rect narrowed until
## it scrolls and widened again, lays its flaps across its room again,
## nothing past it.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_tabs_strip.gd
##
## Each statement is in the floor's look, the strip built at the head of a
## column, as a page holds it, filling a window of the width the statement
## sets; a model answers every flap's action.

const Fixture := preload("res://tests/fixture.gd")
const Verdict := preload("res://tests/verdict.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const PressLocal := preload("res://addons/gd_chime/components/primitives/press_local.gd")
const Scroll := preload("res://addons/gd_chime/components/primitives/scroll.gd")
const Tabs := preload("res://addons/gd_chime/components/recipes/tab_bar.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")

## The rooms the current flap is looked for in, narrowest to widest.
const ROOMS := [120, 200, 320, 480, 900, 1600]

var _verdict := Verdict.new()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(1600, 400)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_flaps_that_all_fit_share_the_strip_s_width_and_nothing_scrolls)
	await _verdict.states(_flaps_that_do_not_fit_stand_whole_and_the_strip_scrolls_across)
	await _verdict.states(_the_current_press_s_flap_is_in_view_in_every_state_at_every_room)
	await _verdict.states(_a_local_s_flaps_choose_it_keep_its_choice_in_view_and_share_one_type_size)
	await _verdict.states(_a_strip_alone_in_its_place_narrowed_then_widened_spans_its_room_again)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## A fixture declaring this many actions, shows_0 and on, each said as "tab <n>" and a word longer for every third.
func _fixture(count: int) -> Fixture:
	var declared: Dictionary = {}
	# every action, its words
	for at: int in count:
		declared[StringName("shows_%d" % at)] = "tab %d%s" % [at, " more" if at % 3 == 0 else ""]
	return Fixture.new(root, declared)


## A strip of this many flaps, each a press of its own action in the one
## kind that the model answers, the one current where the model's value
## reads: at the head of a column, as a page holds it.
func _strip_of_presses(made: Fixture, count: int, current: Fixture.Model) -> Desc:
	var flaps: Array = []
	# every flap, a press of its action, its words in the look's FACE, the action the model's
	for at: int in count:
		flaps.append(made.ui.pressable(StringName("shows_%d" % at), {}, [made.ui.text("tab %d" % at, Themes.FACE)], &"Tab"))
		current.answering.append(StringName("shows_%d" % at))
		made.commands.register(Chimes.GLOBAL, StringName("shows_%d" % at), current)
	return made.ui.column([Tabs.of_presses(made.ui, flaps, current.of(&"current", 0)).named(&"strip"), made.ui.text("").grow()])


## The flaps of a strip, in order.
func _flaps(strip: Scroll) -> Array:
	return strip.get_child(0).get_children()


func _in_view(strip: Scroll, flap: Control) -> bool:
	return strip.get_shown().grow(0.01).encloses(flap.get_global_rect())


func _flaps_that_all_fit_share_the_strip_s_width_and_nothing_scrolls() -> void:
	var made := _fixture(3)
	var current := Fixture.Model.new(made.chimes)
	made.ui.start(made.ui.app(&"app", [_strip_of_presses(made, 3, current)]))
	root.size.x = 900
	await _a_frame_passes()
	var strip: Scroll = made.ui.node_named(&"strip")
	var flaps := _flaps(strip)
	var row: Control = strip.get_child(0)
	_verdict.check(is_equal_approx(row.size.x, strip.size.x) and is_equal_approx((flaps[0] as Control).position.x, 0.0) and is_equal_approx((flaps[2] as Control).get_rect().end.x, row.size.x), "three flaps in 900 run from the strip's start to its end between them, and nothing is left to scroll: %s to %s, the row %s in %s" % [(flaps[0] as Control).position.x, (flaps[2] as Control).get_rect().end.x, row.size.x, strip.size.x])
	_verdict.check(flaps.all(func(flap: Control) -> bool: return flap.size.x > flap.get_combined_minimum_size().x), "each grown past its least to share it: %s" % [flaps.map(func(flap: Control) -> Array: return [flap.size.x, flap.get_combined_minimum_size().x])])
	current.free()
	made.done()


func _flaps_that_do_not_fit_stand_whole_and_the_strip_scrolls_across() -> void:
	var made := _fixture(12)
	var current := Fixture.Model.new(made.chimes)
	made.ui.start(made.ui.app(&"app", [_strip_of_presses(made, 12, current)]))
	root.size.x = 300
	await _a_frame_passes()
	var strip: Scroll = made.ui.node_named(&"strip")
	var flaps := _flaps(strip)
	_verdict.check(strip.get_child(0).size.x > strip.size.x, "twelve flaps in 300 are wider together than the strip, which scrolls across: %s in %s" % [strip.get_child(0).size.x, strip.size.x])
	_verdict.check(flaps.all(func(flap: Control) -> bool: return flap.size.x >= flap.get_combined_minimum_size().x - 0.01), "every flap is at least its least, none squeezed: %s" % [flaps.map(func(flap: Control) -> Array: return [flap.size.x, flap.get_combined_minimum_size().x])])
	_verdict.check(flaps.all(func(flap: Control) -> bool: return _in_view(strip, flap) or not strip.get_shown().intersects(flap.get_global_rect())), "and every flap is shown whole or not at all")
	current.free()
	made.done()


func _the_current_press_s_flap_is_in_view_in_every_state_at_every_room() -> void:
	var made := _fixture(12)
	var current := Fixture.Model.new(made.chimes)
	made.ui.start(made.ui.app(&"app", [_strip_of_presses(made, 12, current)]))
	await _a_frame_passes()
	var strip: Scroll = made.ui.node_named(&"strip")
	var flaps := _flaps(strip)
	var out: Array = []
	var drawn_wrong: Array = []
	# every room, and every flap current in turn at it, for a current flap out of view or a flap drawn current that is not
	for room: int in ROOMS:
		root.size.x = room
		# every flap made current in turn, the far ones first so each move is a long one
		for at: int in [11, 0, 6, 9, 2, 10, 1, 5, 3, 8, 4, 7]:
			current.set_value(&"current", at)
			await _a_frame_passes()
			if not _in_view(strip, flaps[at]):
				out.append([room, at])
			if range(12).any(func(other: int) -> bool: return (flaps[other] as Pressable).is_current() != (other == at)):
				drawn_wrong.append([room, at])
	_verdict.check(out.is_empty(), "at every room from 120 to 1600, whichever flap is current is wholly in the strip's view: out of view at %s" % [out])
	_verdict.check(drawn_wrong.is_empty() and (flaps[7] as Pressable).get_state() == &"current", "and that flap alone is drawn current: wrong at %s" % [drawn_wrong])
	current.free()
	made.done()


func _a_local_s_flaps_choose_it_keep_its_choice_in_view_and_share_one_type_size() -> void:
	var made := Fixture.new(root)
	var chosen := made.ui.local(&"game")
	var choices: Array = [{"value": &"game", "words": "GAME"}, {"value": &"display", "words": "DISPLAY"}, {"value": &"sound", "words": "SOUND"}, {"value": &"controls", "words": "CONTROLS"}, {"value": &"language", "words": "LANGUAGE AND REGION"}]
	made.ui.start(made.ui.app(&"app", [made.ui.column([Tabs.of_local(made.ui, chosen, choices).named(&"strip"), made.ui.text("").grow()])]))
	root.size.x = 160
	await _a_frame_passes()
	var strip: Scroll = made.ui.node_named(&"strip")
	var flaps := _flaps(strip)
	(flaps[3] as PressLocal).pressed()
	await _a_frame_passes()
	_verdict.check(chosen.read() == &"controls" and (flaps[3] as PressLocal).is_selected() and not (flaps[0] as PressLocal).is_selected(), "a flap pressed chooses its value, and it alone is selected: %s" % chosen.read())
	_verdict.check(_in_view(strip, flaps[3]), "and in 160, too narrow for them all, it is in view: %s in %s" % [(flaps[3] as Control).get_global_rect(), strip.get_shown()])
	chosen.set_value(&"language")
	await _a_frame_passes()
	_verdict.check(_in_view(strip, flaps[4]) and (flaps[4] as PressLocal).is_selected(), "the local set elsewhere, its flap is selected and brought into view: %s in %s" % [(flaps[4] as Control).get_global_rect(), strip.get_shown()])
	chosen.set_value(&"game")
	await _a_frame_passes()
	_verdict.check(_in_view(strip, flaps[0]), "and set back to the first, the first: %s in %s" % [(flaps[0] as Control).get_global_rect(), strip.get_shown()])
	var sizes: Array = strip.find_children("*", "Label", true, false).map(func(label: Label) -> int: return label.get_theme_font_size(&"font_size"))
	_verdict.check(sizes.size() == 5 and sizes.all(func(one: int) -> bool: return one == sizes[0]), "every flap's words are in one type size: %s" % [sizes])
	made.done()


## The app standing in a host's rect, as an app hosted beside a game's own
## scenes does, the host narrowed and widened: narrowed, the row is wider
## than the strip and scrolls; widened again, the row is as wide as the
## strip once more - never the new width and the old overflow besides - and
## every flap ends inside it.
func _a_strip_alone_in_its_place_narrowed_then_widened_spans_its_room_again() -> void:
	var made := _fixture(12)
	var current := Fixture.Model.new(made.chimes)
	var flaps: Array = []
	# every flap, a press of its action that the model answers
	for at: int in 12:
		flaps.append(made.ui.pressable(StringName("shows_%d" % at), {}, [made.ui.text("tab %d" % at, Themes.FACE)], &"Tab"))
		current.answering.append(StringName("shows_%d" % at))
		made.commands.register(Chimes.GLOBAL, StringName("shows_%d" % at), current)
	var host := Control.new()
	host.size = Vector2(1600, 200)
	root.add_child(host)
	made.ui.build(made.ui.app(&"app", [Tabs.of_presses(made.ui, flaps, current.of(&"current", 0)).named(&"strip")]), host)
	await _a_frame_passes()
	var strip: Scroll = host.find_children("*", "ScrollContainer", true, false)[0]
	var row: Control = strip.get_child(0)
	var wide := row.size.x
	host.size.x = 300
	await _a_frame_passes()
	var narrow := row.size.x
	host.size.x = 1600
	await _a_frame_passes()
	_verdict.check(is_equal_approx(wide, strip.size.x) and narrow > 300.0, "at 1600 the row spans the strip, and at 300 it is wider and scrolls: %s, %s" % [wide, narrow])
	_verdict.check(is_equal_approx(row.size.x, strip.size.x) and (_flaps(strip)[11] as Control).get_global_rect().end.x <= strip.get_global_rect().end.x + 0.01, "widened again, the row spans the strip once more and the last flap ends inside it: the row %s in %s" % [row.size.x, strip.size.x])
	current.free()
	made.done()
