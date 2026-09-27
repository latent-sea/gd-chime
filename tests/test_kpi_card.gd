extends SceneTree

## What must be true of a KPI card: it shows loading until its figure
## lands, then the figure written in its unit the language's way; its change
## on the stretch before is a mark and words - up, down, level or nothing to
## compare with - said only while the dashboard compares; a figure of
## nothing says the caller's words; its trend is its days, a spread's by the
## middle; and the whole card is one press of its action.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_kpi_card.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Formats := preload("res://addons/gd_chime/formats.gd")
const KpiCard := preload("res://addons/gd_chime/components/recipes/kpi_card.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Verdict := preload("res://tests/verdict.gd")

const DRILLS := &"drills_into"

var _verdict := Verdict.new()


## A dashboard's reads, for one card.
class Board extends Fixture.Model:
	func get_figure() -> Variant:
		return of(&"figure").read()

	func get_comparing() -> Variant:
		return of(&"comparing").read()

	func get_before() -> Variant:
		return Phrase.within("the 7 days before")


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(500, 400)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_it_shows_loading_until_its_figure_lands_then_the_figure_in_its_unit)
	await _verdict.states(_the_change_is_a_mark_and_words_up_down_level_or_nothing_to_compare_with)
	await _verdict.states(_the_change_is_said_only_while_the_dashboard_compares)
	await _verdict.states(_a_figure_of_nothing_says_the_callers_words)
	await _verdict.states(_its_trend_is_its_days_a_spreads_by_the_middle_and_a_day_of_nothing_dropped)
	await _verdict.states(_the_whole_card_is_one_press_of_its_action)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## The words showing under a node, hidden ones left out.
func _shown(node: Node) -> Array[String]:
	var found: Array[String] = []
	# every text under it that is drawn
	for text: Node in node.find_children("*", "Control", true, false):
		if text is Text and (text as Text).is_visible_in_tree() and (text as Text).get_text() != "":
			found.append((text as Text).get_text())
	return found


## A card over a board, built and started: [the fixture, the board, the card].
func _card() -> Array:
	var made := Fixture.new(root, {DRILLS: "show what is behind the figure"})
	var ui := made.ui
	var board := Board.new(made.chimes, &"app")
	board.set_value(&"figure", null)
	board.set_value(&"comparing", false)
	var unit := func(amount: Variant) -> Phrase: return Phrase.with("%s customers", [amount])
	var card := KpiCard.make(ui, DRILLS, Bound.new(board.get_figure), {payload = {"figure": "out"}, says = Phrase.of("without service"), unit = unit, comparing = Bound.new(board.get_comparing), before_words = Bound.new(board.get_before), says_empty = Phrase.of("nobody is out")}).named(&"card")
	made.commands.register(&"app", DRILLS, board)
	ui.start(ui.app(&"app", [card]))
	await _a_frame_passes()
	return [made, board, ui.node_named(&"card")]


func _done(both: Array) -> void:
	(both[1] as Node).free()
	(both[0] as Fixture).done()


func _it_shows_loading_until_its_figure_lands_then_the_figure_in_its_unit() -> void:
	var both: Array = await _card()
	var card: Node = both[2]
	_verdict.check(_shown(card) == ["without service", "Loading"], "before its figure lands it says what it is, and loading: %s" % [_shown(card)])
	(both[1] as Board).set_value(&"figure", {"now": 12345.0, "before": 10000.0, "days": [1.0, 2.0]})
	await _a_frame_passes()
	_verdict.check(_shown(card) == ["without service", "12,345 customers"], "landed, the figure is written in its unit, thousands marked the language's way: %s" % [_shown(card)])
	_done(both)


func _the_change_is_a_mark_and_words_up_down_level_or_nothing_to_compare_with() -> void:
	var before := Phrase.within("the 7 days before")
	var up := str(KpiCard.change_of({"now": 112.0, "before": 100.0}, before))
	var down := str(KpiCard.change_of({"now": 75.0, "before": 100.0}, before))
	var level := str(KpiCard.change_of({"now": 100.2, "before": 100.0}, before))
	var none := str(KpiCard.change_of({"now": 5.0, "before": 0.0}, before))
	_verdict.check(up == "▲ Up 12% on the 7 days before" and down == "▼ Down 25% on the 7 days before", "up and down each have their own mark AND say which way in words: %s / %s" % [up, down])
	_verdict.check(level == "= Level with the 7 days before" and none == "Nothing to compare with the 7 days before", "under half a percent is level, and a stretch before of nothing has nothing to compare with: %s / %s" % [level, none])
	_verdict.check(KpiCard.change_of(null, before) == null, "and nothing is said before the figure lands")


func _the_change_is_said_only_while_the_dashboard_compares() -> void:
	var both: Array = await _card()
	var card: Node = both[2]
	var board: Board = both[1]
	board.set_value(&"figure", {"now": 110.0, "before": 100.0, "days": []})
	await _a_frame_passes()
	_verdict.check(not _shown(card).any(func(words: String) -> bool: return words.contains("on the 7 days before")), "not comparing, no change is said: %s" % [_shown(card)])
	board.set_value(&"comparing", true)
	await _a_frame_passes()
	_verdict.check(_shown(card).has("▲ Up 10% on the 7 days before"), "comparing, the change is said under the figure: %s" % [_shown(card)])
	_done(both)


func _a_figure_of_nothing_says_the_callers_words() -> void:
	var both: Array = await _card()
	(both[1] as Board).set_value(&"figure", {"now": null, "before": 3.0, "days": []})
	await _a_frame_passes()
	_verdict.check(_shown(both[2]) == ["without service", "nobody is out"], "a figure that is nothing says so in the caller's words, never a blank: %s" % [_shown(both[2])])
	_done(both)


func _its_trend_is_its_days_a_spreads_by_the_middle_and_a_day_of_nothing_dropped() -> void:
	_verdict.check(KpiCard.trend_of([3.0, null, 5.0]) == [3.0, 5.0], "a day of nothing is dropped from the trend")
	_verdict.check(KpiCard.trend_of([[1.0, 2.0, 4.0], null, [2.0, 3.0, 9.0]]) == [2.0, 3.0], "a spread's day stands by its middle: %s" % [KpiCard.trend_of([[1.0, 2.0, 4.0], null, [2.0, 3.0, 9.0]])])


func _the_whole_card_is_one_press_of_its_action() -> void:
	var both: Array = await _card()
	var card: Node = both[2]
	(both[1] as Board).set_value(&"figure", {"now": 1.0, "before": 1.0, "days": []})
	await _a_frame_passes()
	var inner: Array = card.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable)
	_verdict.check(card is Pressable and inner.is_empty(), "the card is one pressable, holding no other")
	(card as Pressable).pressed()
	_verdict.check((both[1] as Board).told_actions == [DRILLS] and (both[0] as Fixture).commands.get_last()["payload"] == {"figure": "out"}, "pressed, it asks its action with its payload: %s" % [(both[1] as Board).told_actions])
	_done(both)
