extends SceneTree

## What must be true of a date range: the stretches handed in are one
## choice, the one picked worn chosen, and a press of another picks it
## through the filters; and the days set by hand stand only while the
## preset picked sets no length, each made by the field the caller hands in
## with the filters' action and day, so a day set there is the filters'.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_date_range.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Filters := preload("res://addons/gd_chime/filters.gd")
const Stretch := preload("res://addons/gd_chime/stretch.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const DateRange := preload("res://addons/gd_chime/components/recipes/date_range.gd")
const Verdict := preload("res://tests/verdict.gd")
const Pressables := preload("res://addons/gd_chime/theme_pressables.gd")

const NOW := 20000.0 * 24.0 + 12.0
## The stretches an application hands in: today, the last 7 days, the last 30, and the days set by hand.
const TODAY := &"today"
const WEEK := &"week"
const MONTH := &"month"
const BY_HAND := &"by_hand"

var _verdict := Verdict.new()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(1400, 400)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_the_stretches_are_one_choice_and_a_press_picks_one_through_the_filters)
	await _verdict.states(_the_days_set_by_hand_stand_only_while_the_preset_sets_no_length)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## A day's stand-in field: a press setting the day before the one it shows, saying the day.
func _earlier(ui: RefCounted, action: StringName, shows: Bound) -> Desc:
	return ui.pressable(action, shows.map(func(day: Variant) -> Dictionary: return {"value": day - 1}), [ui.text(shows.map(func(day: Variant) -> String: return "day %d" % day))]).named(StringName("field_" + action))


## The range over a filters' date column, built and started: [the fixture, the filters].
func _range() -> Array:
	var made := Fixture.new(root, {Stretch.PICKS: "stretch", Stretch.SETS_FIRST_DAY: "first day", Stretch.SETS_LAST_DAY: "last day"})
	var ui := made.ui
	var presets: Array = [{"value": TODAY, "words": Phrase.of("Today"), "days": 1}, {"value": WEEK, "words": Phrase.of("7 days"), "days": 7}, {"value": MONTH, "words": Phrase.of("30 days"), "days": 30}, {"value": BY_HAND, "words": Phrase.of("Custom")}]
	var filters := Filters.new(made.chimes, {one_of = &"region", dates = {column = &"reported", now = NOW, presets = presets, starts = WEEK}})
	made.commands.stand(&"app", filters)
	root.add_child(filters)
	ui.start(ui.app(&"app", [DateRange.make(ui, filters.stretch, _earlier).named(&"range")]))
	await _a_frame_passes()
	return [made, filters]


func _presses(both: Array) -> Array:
	return ((both[0] as Fixture).ui.node_named(&"range") as Node).find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable and part.is_visible_in_tree())


func _the_stretches_are_one_choice_and_a_press_picks_one_through_the_filters() -> void:
	var both: Array = await _range()
	var segments: Array = _presses(both).filter(func(press: Pressable) -> bool: return press.action == Stretch.PICKS)
	_verdict.check(segments.map(func(press: Pressable) -> Dictionary: return press.payload()) == [{"value": TODAY}, {"value": WEEK}, {"value": MONTH}, {"value": BY_HAND}], "one segment a stretch handed in, each carrying which")
	_verdict.check(segments[1].theme_type_variation == Pressables.SEGMENT_CHOSEN and segments[2].theme_type_variation == Pressables.SEGMENT, "the stretch on now wears the chosen look, the rest the plain")
	(segments[2] as Pressable).pressed()
	await _a_frame_passes()
	_verdict.check((both[1] as Filters).stretch.get_picked() == MONTH and segments[2].theme_type_variation == Pressables.SEGMENT_CHOSEN, "pressed, 30 days is the filters' stretch, and worn chosen")
	(both[0] as Fixture).done()


func _the_days_set_by_hand_stand_only_while_the_preset_sets_no_length() -> void:
	var both: Array = await _range()
	var ui: RefCounted = (both[0] as Fixture).ui
	_verdict.check(ui.node_named(&"field_sets_the_first_day") == null, "a preset of so many days picked, no day set by hand stands")
	(both[0] as Fixture).commands.dispatch(&"app", Stretch.PICKS, {"value": BY_HAND})
	await _a_frame_passes()
	var first: Pressable = ui.node_named(&"field_sets_the_first_day")
	var last: Pressable = ui.node_named(&"field_sets_the_last_day")
	_verdict.check(first != null and last != null, "the preset that sets no length picked, a field for the first day and one for the last stand")
	first.pressed()
	await _a_frame_passes()
	_verdict.check((both[1] as Filters).stretch.get_first_day() == 19999, "a day set in the first's field is the filters' first day: %d" % (both[1] as Filters).stretch.get_first_day())
	(both[0] as Fixture).done()
