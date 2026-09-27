extends SceneTree

## What must be true of a bar chart: loading until its bars land and the
## caller's words when every bar is nothing; a bar per thing, each a press
## carrying its key; the one picked drawn current, by a shape; the longest
## bar the whole track, the stretch before in the scale only while
## comparing, and its key said only then; and the bars kept by key, so the
## focus stays on the bar the reader is on as the values move.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_bar_chart.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const BarChart := preload("res://addons/gd_chime/components/recipes/bar_chart.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Verdict := preload("res://tests/verdict.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")

const PICKS := &"picks_a_region"
const THREE := [{"key": "East", "now": 30.0, "before": 60.0}, {"key": "London", "now": 15.0, "before": 10.0}, {"key": "Wales", "now": 5.0, "before": 5.0}]

var _verdict := Verdict.new()


## A dashboard's reads, for one chart.
class Board extends Fixture.Model:
	func get_bars() -> Variant:
		return of(&"bars").read()

	func get_picked() -> Variant:
		return of(&"picked").read()

	func get_comparing() -> Variant:
		return of(&"comparing").read()

	func get_before() -> Variant:
		return Phrase.of("the 7 days before")


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(600, 400)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_it_shows_loading_until_its_bars_land_and_says_so_when_every_bar_is_nothing)
	await _verdict.states(_every_bar_is_a_press_carrying_its_key_and_the_one_picked_is_current_by_a_shape)
	await _verdict.states(_the_longest_is_the_whole_track_and_the_stretch_before_counts_only_while_comparing)
	await _verdict.states(_the_bars_are_kept_by_key_so_the_focus_stays_on_its_bar_as_values_move)
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


func _bars(node: Node) -> Array:
	return node.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable and part.is_visible_in_tree())


## A chart over a board, built and started: [the fixture, the board, the chart].
func _chart(bars: Variant) -> Array:
	var made := Fixture.new(root, {PICKS: "pick the region"})
	var ui := made.ui
	var board := Board.new(made.chimes, &"app")
	board.set_value(&"bars", bars)
	board.set_value(&"picked", &"")
	board.set_value(&"comparing", false)
	var unit := func(amount: Variant) -> Phrase: return Phrase.with("%s incidents", [amount])
	var chart := ui.column([BarChart.make(ui, PICKS, Bound.new(board.get_bars), {picked = Bound.new(board.get_picked), comparing = Bound.new(board.get_comparing), before_words = Bound.new(board.get_before), unit = unit, says_empty = Phrase.of("no incidents in this stretch")})]).named(&"chart")
	made.commands.register(&"app", PICKS, board)
	ui.start(ui.app(&"app", [chart]))
	await _a_frame_passes()
	return [made, board, ui.node_named(&"chart")]


func _done(both: Array) -> void:
	(both[1] as Node).free()
	(both[0] as Fixture).done()


func _it_shows_loading_until_its_bars_land_and_says_so_when_every_bar_is_nothing() -> void:
	var both: Array = await _chart(null)
	_verdict.check(_shown(both[2]) == ["Loading"] and _bars(both[2]).is_empty(), "before its bars land it says loading, and no bar stands: %s" % [_shown(both[2])])
	(both[1] as Board).set_value(&"bars", THREE.map(func(one: Dictionary) -> Dictionary: return {"key": one["key"], "now": 0.0, "before": 1.0}))
	await _a_frame_passes()
	_verdict.check(_shown(both[2]) == ["no incidents in this stretch"], "landed with every bar nothing, it says so in the caller's words: %s" % [_shown(both[2])])
	(both[1] as Board).set_value(&"bars", THREE)
	await _a_frame_passes()
	_verdict.check(_shown(both[2]) == ["East", "30 incidents", "London", "15 incidents", "Wales", "5 incidents"], "with something to show, each bar says its name and its figure in its unit: %s" % [_shown(both[2])])
	_done(both)


func _every_bar_is_a_press_carrying_its_key_and_the_one_picked_is_current_by_a_shape() -> void:
	var both: Array = await _chart(THREE)
	var bars: Array = _bars(both[2])
	_verdict.check(bars.map(func(bar: Pressable) -> Dictionary: return bar.payload()) == [{"picked": "East"}, {"picked": "London"}, {"picked": "Wales"}], "a press a bar, each carrying its key: %s" % [bars.map(func(bar: Pressable) -> Dictionary: return bar.payload())])
	(bars[1] as Pressable).pressed()
	_verdict.check((both[1] as Board).told_actions == [PICKS] and (both[0] as Fixture).commands.get_last()["payload"] == {"picked": "London"}, "pressed, a bar asks its action with its key")
	(both[1] as Board).set_value(&"picked", "London")
	await _a_frame_passes()
	_verdict.check(bars.map(func(bar: Pressable) -> bool: return bar.is_current()) == [false, true, false], "the bar whose key is the one picked is current, the rest not")
	var current: StyleBoxFlat = (bars[1] as Control).get_theme_stylebox(&"current", BarChart.BAR)
	var normal: StyleBoxFlat = (bars[1] as Control).get_theme_stylebox(&"normal", BarChart.BAR)
	_verdict.check(current.border_width_left > 0 and normal.border_width_left == 0, "and current is a shape - a rule down its side - not a colour alone: %d against %d" % [current.border_width_left, normal.border_width_left])
	_done(both)


func _the_longest_is_the_whole_track_and_the_stretch_before_counts_only_while_comparing() -> void:
	var alone := BarChart.longest(THREE, BarChart.NOW)
	var compared := BarChart.longest(THREE, BarChart.NOW_AND_BEFORE)
	_verdict.check(alone == 30.0 and BarChart.shares(THREE[0], alone, BarChart.NOW)["now"] == 1.0 and BarChart.shares(THREE[2], alone, BarChart.NOW)["now"] == 5.0 / 30.0, "not comparing, the longest now is the whole track: %s" % alone)
	_verdict.check(compared == 60.0 and BarChart.shares(THREE[0], compared, BarChart.NOW_AND_BEFORE) == {"now": 0.5, "before": 1.0, "compares": true}, "comparing, a stretch before longer than any now is the whole track, so its tick stays on the bar: %s" % compared)
	_verdict.check(BarChart.longest([], BarChart.NOW) > 0.0, "nothing at all still has a length to be a share of")
	var both: Array = await _chart(THREE)
	_verdict.check(not _shown(both[2]).has("the 7 days before"), "not comparing, the tick's key is not said")
	(both[1] as Board).set_value(&"comparing", true)
	await _a_frame_passes()
	_verdict.check(_shown(both[2]).has("the 7 days before"), "comparing, a key says what the tick is: %s" % [_shown(both[2])])
	_done(both)


func _the_bars_are_kept_by_key_so_the_focus_stays_on_its_bar_as_values_move() -> void:
	var both: Array = await _chart(THREE)
	var before: Array = _bars(both[2])
	(before[2] as Control).grab_focus()
	var moved: Array = THREE.map(func(one: Dictionary) -> Dictionary: return {"key": one["key"], "now": one["now"] * 2.0, "before": one["before"]})
	moved.reverse()
	(both[1] as Board).set_value(&"bars", moved)
	await _a_frame_passes()
	var after: Array = _bars(both[2])
	var focused: Array = after.filter(func(bar: Control) -> bool: return bar.has_focus())
	_verdict.check(focused.size() == 1 and focused[0] == before[2] and (focused[0] as Pressable).payload() == {"picked": "Wales"} and _shown(both[2]).has("10 incidents"), "the values moved and Wales came first: its bar is the same piece, and the focus is still on it: %s" % [_shown(both[2])])
	_done(both)
