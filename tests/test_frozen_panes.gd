extends SceneTree

## What must be true of a table in frozen panes: every column is at least
## its least - the look's constant named for the columns, or its widest
## sample words with the pad either side - and none is dropped; where all
## fit they share the room, in the order given, and where they do not the
## body scrolls across; after a finger, a wheel and a pad's pan on any pane,
## and the pad walking onto a heading out of sight, the heads stand at the
## body's offset across and the labels at its offset down, and the corner
## never moves; its least is the corner, one column and one row, whatever
## its room; drawn whole down, it is as tall as its rows and scrolls
## across alone; and wider and taller than its room, the guard finds
## nothing past it, the heads and the labels moving as the body does; and
## the samples it is handed are read and never written, so they may be a
## constant.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_frozen_panes.gd
##
## The table is described by hand, its props written out whole, so a
## statement may set any of them. Its heads are two presses, one at
## each end of the heading row; its labels and its body are forty rows of
## words alike, so a label and its row are one height. The look sets every
## column at least GRID across.

const Fixture := preload("res://tests/fixture.gd")
const Verdict := preload("res://tests/verdict.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const FrozenPanes := preload("res://addons/gd_chime/components/primitives/frozen_panes.gd")
const ColumnLeasts := preload("res://addons/gd_chime/components/primitives/column_leasts.gd")
const OutsideSafe := preload("res://addons/gd_chime/outside_safe.gd")

const PICKS := &"picks"
## The look's least for every column, in base pixels, and how many rows the table has.
const GRID := 72
const ROWS := 40
## The words the measured columns may hold, the first far wider than the rest.
const SAMPLES := {&"name": {"words": ["THE LONGEST NAME ANYONE EVER HAD"]}, &"score": {"words": ["9/2", "100/1"]}, &"total": {"words": ["1,000"]}}

var _verdict := Verdict.new()
var _made: Fixture
var _table: FrozenPanes


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	root.theme.set_constant(&"grid_column", &"Columns", GRID)
	root.theme.set_constant(&"pad", &"FrozenPanes", 4)
	root.theme.set_constant(&"gap", &"FrozenPanes", 2)
	await process_frame
	await _verdict.states(_too_many_to_fit_every_column_stands_at_its_least_and_the_body_scrolls_across)
	await _verdict.states(_all_fitting_the_columns_share_the_room_none_under_its_least)
	await _verdict.states(_a_column_measured_by_its_words_is_at_least_its_widest_and_the_rest_share)
	await _verdict.states(_after_a_finger_on_each_pane_the_heads_and_labels_stand_at_the_body_s_offsets)
	await _verdict.states(_after_a_wheel_and_a_pad_s_pan_on_each_pane_they_stand_in_step)
	await _verdict.states(_the_pad_walking_onto_a_heading_out_of_sight_brings_it_whole_into_view)
	await _verdict.states(_its_least_is_the_corner_one_column_and_one_row_whatever_its_room)
	await _verdict.states(_drawn_whole_down_it_is_as_tall_as_its_rows_and_scrolls_across_alone)
	await _verdict.states(_wider_and_taller_than_its_room_the_guard_finds_nothing_past_it)
	await _verdict.states(_its_samples_are_read_and_never_written)
	quit(_verdict.deliver(get_script()))


func _frames(count: int = 4) -> void:
	# each frame in turn, for the panes to be laid and the body placed at its offsets
	for frame: int in count:
		await process_frame


## A table of so many columns in a window this size, with the props this makes of the builder over the plain ones.
func _standing(columns: Array, window: Vector2i, props: Callable = func(_ui: RefCounted) -> Dictionary: return {}) -> void:
	_made = Fixture.new(root, {PICKS: "pick"})
	_made.answer([PICKS])
	var ui := _made.ui
	var given := {"columns": Bound.constant(columns), "least_column": &"grid_column", "samples": {}, "words_kind": &"Label", "widths": null, "style": &"FrozenPanes", "nudged": null, "whole_down": false}
	given.merge(props.call(ui), true)
	var heads := ui.row([ui.pressable(PICKS, {"at": 0}, [ui.text("FIRST")]).named(&"first"), ui.row([]).grow(), ui.pressable(PICKS, {"at": 1}, [ui.text("LAST")]).named(&"last")]).named(&"heads")
	var labels := ui.column(range(ROWS).map(func(at: int) -> RefCounted: return ui.text("ROW %d" % at))).named(&"labels")
	var body := ui.column(range(ROWS).map(func(at: int) -> RefCounted: return ui.text("THE CELLS OF ROW %d" % at))).named(&"body")
	var table := Desc.new(&"frozen_panes", given, [ui.text("ROWS BACK").named(&"corner"), heads, labels, body]).named(&"table")
	root.size = window
	ui.start(ui.app(&"app", [table]))
	await _frames()
	_table = ui.node_named(&"table")


## The body's scroll: what its part stands in stands in it.
func _body() -> ScrollContainer:
	return (_made.ui.node_named(&"body") as Control).get_parent().get_parent()


## The room inside the body's padding, across.
func _room() -> float:
	return _body().size.x - _body().get_theme_stylebox(&"panel").get_minimum_size().x


## Whether the heads stand at the body's offset across and the labels at its offset down, on the canvas.
func _in_step() -> bool:
	var body: Control = _made.ui.node_named(&"body")
	return is_equal_approx((_made.ui.node_named(&"heads") as Control).global_position.x, body.global_position.x) and is_equal_approx((_made.ui.node_named(&"labels") as Control).global_position.y, body.global_position.y)


## Where the parts stand, for a sentence.
func _offsets() -> String:
	return "heads %s, labels %s, body %s, body scrolled to %s" % [(_made.ui.node_named(&"heads") as Control).global_position, (_made.ui.node_named(&"labels") as Control).global_position, (_made.ui.node_named(&"body") as Control).global_position, Vector2(_body().scroll_horizontal, _body().scroll_vertical)]


## The middle of what shows of a part: the pane it stands in, for the heads and the labels, which run past it.
func _middle(named: StringName) -> Vector2:
	var part: Control = _made.ui.node_named(named)
	return (part.get_parent() as Control).get_global_rect().get_center() if named in [&"heads", &"labels"] else part.get_global_rect().get_center()


## The body put back at its start, as a reader scrolling back would leave it.
func _back_to_the_start() -> void:
	_body().get_h_scroll_bar().value = 0.0
	_body().get_v_scroll_bar().value = 0.0
	await _frames()


## A finger down at a point, drawn by these steps a frame each, and lifted: through Input, as a device's is (touch.gd).
func _drawn(at: Vector2, steps: Array) -> void:
	var touched := InputEventScreenTouch.new()
	touched.position = root.get_final_transform() * at
	touched.pressed = true
	Input.parse_input_event(touched)
	await process_frame
	var now := at
	# every step, one drag a frame
	for step: Vector2 in steps:
		now += step
		var drag := InputEventScreenDrag.new()
		drag.position = root.get_final_transform() * now
		drag.relative = root.get_final_transform().basis_xform(step)
		Input.parse_input_event(drag)
		await process_frame
	var lifted := InputEventScreenTouch.new()
	lifted.position = root.get_final_transform() * now
	lifted.pressed = false
	Input.parse_input_event(lifted)
	await _frames()


## A notch of the wheel this way at a point.
func _wheel(at: Vector2, button: MouseButton) -> void:
	var notch := InputEventMouseButton.new()
	notch.button_index = button
	notch.pressed = true
	notch.factor = 1.0
	notch.position = root.get_final_transform() * at
	root.push_input(notch)
	await _frames()


func _too_many_to_fit_every_column_stands_at_its_least_and_the_body_scrolls_across() -> void:
	await _standing(range(30), Vector2i(600, 400))
	var widths := _table.get_widths()
	_verdict.check(widths.size() == 30 and widths.all(func(width: float) -> bool: return width == GRID), "thirty columns that cannot fit in 600 each stand at the least, none dropped: %s" % [widths])
	var bar := _body().get_h_scroll_bar()
	var across := 30.0 * GRID + 29.0 * 2.0
	_verdict.check(is_equal_approx((_made.ui.node_named(&"body") as Control).size.x, across) and bar.max_value - bar.page > 0.0, "the body's part is all thirty and their gaps across, %s, and scrolls across: %s of %s" % [across, (_made.ui.node_named(&"body") as Control).size.x, bar.max_value])
	_verdict.check(is_equal_approx((_made.ui.node_named(&"heads") as Control).size.x, across), "and the heads are laid as wide as the columns: %s" % (_made.ui.node_named(&"heads") as Control).size.x)
	_made.done()


func _all_fitting_the_columns_share_the_room_none_under_its_least() -> void:
	await _standing(range(5), Vector2i(1200, 400))
	var widths := _table.get_widths()
	var shared: float = (_room() - 4.0 * 2.0) / 5.0
	_verdict.check(widths.size() == 5 and shared > GRID and widths.all(func(width: float) -> bool: return is_equal_approx(width, shared)), "five columns in 1200 share what the gaps leave of the room alike, each over the least: %s, %s" % [shared, widths])
	var bar := _body().get_h_scroll_bar()
	_verdict.check(bar.max_value - bar.page <= 0.0, "and the body has nothing to scroll across: %s of %s" % [bar.page, bar.max_value])
	_made.done()
	var local: Array = []
	await _standing(range(5), Vector2i(1200, 400), func(ui: RefCounted) -> Dictionary:
		local.append(ui.local([]))
		return {"widths": local[0]})
	_verdict.check(local[0].read() == _table.get_widths(), "a local given is set to the widths: %s against %s" % [local[0].read(), _table.get_widths()])
	root.size = Vector2i(800, 400)
	await _frames()
	_verdict.check(local[0].read() == _table.get_widths() and is_equal_approx(local[0].read()[0], (_room() - 8.0) / 5.0), "and set again as the room moves: %s" % [local[0].read()])
	_made.done()


func _a_column_measured_by_its_words_is_at_least_its_widest_and_the_rest_share() -> void:
	var columns: Array = [&"name", &"score", &"total"]
	await _standing(columns, Vector2i(1400, 400), func(_ui: RefCounted) -> Dictionary: return {"least_column": &"", "samples": SAMPLES.duplicate(true)})
	var font := _table.get_theme_font(&"font", &"Label")
	var size := _table.get_theme_font_size(&"font_size", &"Label")
	var name_least: float = font.get_string_size(SAMPLES[&"name"]["words"][0], HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + 8.0
	var widths := _table.get_widths()
	_verdict.check(widths.size() == 3 and widths[0] >= name_least - 0.01, "the column of names is at least its widest name and its pad: %s against %s" % [widths, name_least])
	_verdict.check(is_equal_approx(widths[1], widths[2]) and is_equal_approx(widths[0] + widths[1] + widths[2] + 4.0, _room()), "and where all fit the rest share the room alike, in the order given: %s in %s" % [widths, _room()])
	_made.done()
	await _standing(columns, Vector2i(300, 400), func(_ui: RefCounted) -> Dictionary: return {"least_column": &"", "samples": SAMPLES.duplicate(true)})
	var leasts := _table.get_leasts()
	_verdict.check(_table.get_widths() == leasts and leasts[0] >= name_least - 0.01 and leasts[1] < leasts[0], "too narrow for them, each stands at its own least, never squeezed: %s" % [_table.get_widths()])
	_made.done()
	_verdict.check(ColumnLeasts.shared([400.0, 50.0, 50.0], 1000.0, 0.0) == [400.0, 300.0, 300.0] and ColumnLeasts.shared([600.0, 50.0, 50.0], 1000.0, 0.0) == [600.0, 200.0, 200.0] and ColumnLeasts.shared([600.0, 300.0, 50.0], 900.0, 10.0) == [600.0, 300.0, 50.0], "a column wider than its share keeps its least and the rest share what is left; too many keep their leasts")


func _after_a_finger_on_each_pane_the_heads_and_labels_stand_at_the_body_s_offsets() -> void:
	await _standing(range(30), Vector2i(600, 400))
	var corner: Rect2 = (_made.ui.node_named(&"corner") as Control).get_global_rect()
	_verdict.check(_in_step() and _body().scroll_horizontal == 0 and _body().scroll_vertical == 0, "at the start they stand in step: %s" % _offsets())
	await _drawn(_middle(&"first") + Vector2(40, 0), [Vector2(-60, 0), Vector2(-80, 0), Vector2(-80, 0)])
	_verdict.check(_body().scroll_horizontal > 0 and _in_step(), "a finger drawn left along the heads moves the body across, the heads with it: %s" % _offsets())
	await _back_to_the_start()
	_verdict.check(_in_step(), "put back at the start, they stand in step: %s" % _offsets())
	await _drawn(_middle(&"labels"), [Vector2(0, -60), Vector2(0, -80), Vector2(0, -80)])
	_verdict.check(_body().scroll_vertical > 0 and _in_step(), "a finger drawn up the labels moves the body down, the labels with it: %s" % _offsets())
	await _back_to_the_start()
	await _drawn(_middle(&"corner"), [Vector2(-60, -60), Vector2(-80, -80), Vector2(-80, -80)])
	_verdict.check((_body().scroll_vertical > 0 or _body().scroll_horizontal > 0) and _in_step(), "a finger drawn over the corner moves the body too: %s" % _offsets())
	await _back_to_the_start()
	await _drawn(_body().get_global_rect().get_center(), [Vector2(-60, 0), Vector2(-80, 0), Vector2(-80, 0)])
	_verdict.check(_body().scroll_horizontal > 0 and _in_step(), "and a finger on the body itself moves it, the heads following: %s" % _offsets())
	_verdict.check((_made.ui.node_named(&"corner") as Control).get_global_rect() == corner, "while the corner never moved: %s" % (_made.ui.node_named(&"corner") as Control).get_global_rect())
	_made.done()


func _after_a_wheel_and_a_pad_s_pan_on_each_pane_they_stand_in_step() -> void:
	await _standing(range(30), Vector2i(600, 400))
	var corner: Rect2 = (_made.ui.node_named(&"corner") as Control).get_global_rect()
	await _wheel(_middle(&"heads"), MOUSE_BUTTON_WHEEL_DOWN)
	_verdict.check(_body().scroll_vertical > 0 and _in_step(), "a wheel turned down over the heads moves the body down: %s" % _offsets())
	await _wheel(_middle(&"labels"), MOUSE_BUTTON_WHEEL_RIGHT)
	_verdict.check(_body().scroll_horizontal > 0 and _in_step(), "a wheel tilted right over the labels moves it across: %s" % _offsets())
	var down := _body().scroll_vertical
	await _wheel(_body().get_global_rect().get_center(), MOUSE_BUTTON_WHEEL_DOWN)
	_verdict.check(_body().scroll_vertical > down and _in_step(), "a wheel over the body moves it, the labels following: %s" % _offsets())
	var across := _body().scroll_horizontal
	var pan := InputEventPanGesture.new()
	pan.delta = Vector2(3, 3)
	pan.position = root.get_final_transform() * _middle(&"corner")
	root.push_input(pan)
	await _frames()
	_verdict.check(_body().scroll_horizontal > across and _body().scroll_vertical > down and _in_step(), "a pad's pan over the corner moves it both ways: %s" % _offsets())
	_verdict.check((_made.ui.node_named(&"corner") as Control).get_global_rect() == corner, "and the corner never moved: %s" % (_made.ui.node_named(&"corner") as Control).get_global_rect())
	_made.done()


func _the_pad_walking_onto_a_heading_out_of_sight_brings_it_whole_into_view() -> void:
	await _standing(range(30), Vector2i(600, 400))
	var heads_pane: Control = (_made.ui.node_named(&"heads") as Control).get_parent()
	var last: Control = _made.ui.node_named(&"last")
	_verdict.check(not heads_pane.get_global_rect().encloses(last.get_global_rect()), "the last heading starts out of sight: %s past %s" % [last.get_global_rect(), heads_pane.get_global_rect()])
	(_made.ui.node_named(&"first") as Control).grab_focus()
	await _frames()
	# the pad's right, down and up, walking the focus from the first heading to the last
	for down: bool in [true, false]:
		var press := InputEventJoypadButton.new()
		press.button_index = JOY_BUTTON_DPAD_RIGHT
		press.pressed = down
		root.push_input(press)
	await _frames()
	var focus := root.gui_get_focus_owner()
	_verdict.check(focus == last and heads_pane.get_global_rect().grow(0.5).encloses(last.get_global_rect()) and _body().scroll_horizontal > 0 and _in_step(), "walked onto, it is brought wholly into view by the body moving, the heads in step: %s at %s in %s, %s" % [focus, last.get_global_rect(), heads_pane.get_global_rect(), _offsets()])
	_made.done()


func _its_least_is_the_corner_one_column_and_one_row_whatever_its_room() -> void:
	var leasts: Array = []
	# the same table in a narrow room and a wide one
	for window: Vector2i in [Vector2i(400, 400), Vector2i(2000, 400)]:
		await _standing(range(30), window)
		var corner: Vector2 = (_made.ui.node_named(&"corner") as Control).get_combined_minimum_size().max(Vector2((_made.ui.node_named(&"labels") as Control).get_combined_minimum_size().x, (_made.ui.node_named(&"heads") as Control).get_combined_minimum_size().y))
		var row: float = ((_made.ui.node_named(&"labels") as Control).get_child(0) as Control).get_combined_minimum_size().y
		var padding := _body().get_theme_stylebox(&"panel").get_minimum_size()
		var wanted := corner + Vector2(GRID, row) + padding
		_verdict.check(_table.get_combined_minimum_size().is_equal_approx(wanted), "in %s its least is the corner, one column and one row, with the body's padding: %s, %s" % [window, _table.get_combined_minimum_size(), wanted])
		leasts.append(_table.get_combined_minimum_size())
		_made.done()
	_verdict.check(leasts[0] == leasts[1], "and it is no greater in the wider room: %s" % [leasts])


func _drawn_whole_down_it_is_as_tall_as_its_rows_and_scrolls_across_alone() -> void:
	await _standing(range(30), Vector2i(600, 400), func(_ui: RefCounted) -> Dictionary: return {"whole_down": true})
	var labels: Control = _made.ui.node_named(&"labels")
	var heads: Control = _made.ui.node_named(&"heads")
	_verdict.check(_table.get_combined_minimum_size().y >= heads.get_combined_minimum_size().y + labels.get_combined_minimum_size().y, "its least is the heads and every row down: %s for %s rows of %s" % [_table.get_combined_minimum_size(), ROWS, labels.get_combined_minimum_size().y])
	await _wheel(_middle(&"first"), MOUSE_BUTTON_WHEEL_DOWN)
	_verdict.check(_body().scroll_vertical == 0, "a wheel turned down over it does not move it down: %s" % _body().scroll_vertical)
	await _drawn(_middle(&"first") + Vector2(40, 0), [Vector2(-60, 0), Vector2(-80, 0), Vector2(-80, 0)])
	_verdict.check(_body().scroll_horizontal > 0 and _in_step(), "while a finger along the heads still moves it across: %s" % _offsets())
	_made.done()


## Thirty columns and forty rows in 600 by 400: the heads run past their
## pane across and the labels past theirs down, as the body's part does,
## and each follows the body, so nothing stands where its room never moves,
## at the start or scrolled into the middle.
func _wider_and_taller_than_its_room_the_guard_finds_nothing_past_it() -> void:
	await _standing(range(30), Vector2i(600, 400))
	var safe := Rect2(Vector2.ZERO, Vector2(600, 400))
	var at_start := OutsideSafe.found(root, safe)
	_body().get_h_scroll_bar().value = 600.0
	_body().get_v_scroll_bar().value = 300.0
	await _frames()
	var scrolled := OutsideSafe.found(root, safe)
	_verdict.check((_made.ui.node_named(&"heads") as Control).size.x > 600.0 and (_made.ui.node_named(&"labels") as Control).size.y > 400.0, "the heads run past the room across and the labels down: %s, %s" % [(_made.ui.node_named(&"heads") as Control).size, (_made.ui.node_named(&"labels") as Control).size])
	_verdict.check(at_start.is_empty() and scrolled.is_empty(), "and nothing is found past its room, at the start or scrolled: %s, %s" % [at_start, scrolled])
	_made.done()


## The samples handed in, a constant here, measured: the table stands with
## the column at least its widest words, and the samples are as they were.
func _its_samples_are_read_and_never_written() -> void:
	var before := str(SAMPLES)
	await _standing([&"name", &"score", &"total"], Vector2i(1200, 400), func(_ui: RefCounted) -> Dictionary: return {"samples": SAMPLES})
	var leasts := _table.get_leasts()
	_verdict.check(leasts.size() == 3 and leasts[0] > float(GRID), "the name column is measured by its words, past the look's least: %s" % [leasts])
	_verdict.check(str(SAMPLES) == before, "and the samples are what they were: %s" % [SAMPLES])
	_made.done()
