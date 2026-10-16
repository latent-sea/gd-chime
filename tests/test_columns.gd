extends SceneTree

## What must be true of columns (layout.gd, ui.columns): as many equal
## columns as fit stand across - clamp(floor((room + gap) / (least + gap)),
## 1, most) at every room from 200 to 3000 - the least the look's constant
## the use names, and never under the widest part's least, so no part is
## wider than its column; none named, the widest part's least; balanced,
## the fewest columns that make the same rows; every part a column wide,
## the columns filling the room; its least one column, whatever room it is
## given; and rows that share the height share what is left when every one
## fits at its least, and stand at their least when they do not.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_columns.gd
##
## Each statement is in the floor's look, whose rows keep 12 pixels between
## parts, and names a least of its own under Columns. The columns are built
## directly, as ui.columns builds them, into a host of the width the
## statement sets; the parts are plain controls of a least the statement
## sets. Nothing moves: what is read after a change is what is there.

const Verdict := preload("res://tests/verdict.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Layout := preload("res://addons/gd_chime/components/primitives/layout.gd")
const FlexLines := preload("res://addons/gd_chime/components/primitives/flex_lines.gd")

## The gap the floor's look keeps between the parts of a row.
const GAP := 12.0
## The least a card's column is, named under Columns by these statements.
const CARD := 180.0

var _verdict := Verdict.new()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	root.theme.set_constant(&"card", Layout.COLUMNS, int(CARD))
	await process_frame
	root.size = Vector2i(3200, 800)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_as_many_columns_as_fit_stand_across_at_every_room_up_to_the_most)
	await _verdict.states(_balanced_it_is_the_fewest_columns_that_make_the_same_rows)
	await _verdict.states(_every_part_is_a_column_wide_and_the_columns_fill_the_room)
	await _verdict.states(_a_column_is_never_under_the_widest_part_s_least)
	await _verdict.states(_its_least_is_one_column_whatever_room_it_is_given)
	await _verdict.states(_rows_share_the_height_left_only_when_every_one_fits)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## Columns of this many parts, each a plain control of this least width, in
## a host of this width: built as ui.columns builds them.
func _columns(parts: int, least: StringName, most: int, balanced: bool, part_least: float = 100.0) -> Layout:
	var host := Control.new()
	host.size = Vector2(1000, 600)
	var columns := Layout.new(Layout.ROW, &"Columns")
	columns.lays_columns(least, most, balanced, false)
	# every part, a plain control of the least width given and forty high
	for at: int in parts:
		var part := Control.new()
		part.custom_minimum_size = Vector2(part_least, 40)
		columns.place(part)
	host.add_child(columns)
	root.add_child(host)
	return columns


## How many parts stand on its first line: how many columns are across.
func _across(columns: Layout) -> int:
	var first: float = (columns.get_child(0) as Control).position.y
	return columns.get_children().filter(func(part: Control) -> bool: return is_equal_approx(part.position.y, first)).size()


## How many lines its parts stand on.
func _rows(columns: Layout) -> int:
	var tops: Dictionary = {}
	# every part, by the line it stands on
	for part: Control in columns.get_children():
		tops[roundi(part.position.y)] = true
	return tops.size()


## The count the rule gives: as many of at least `least` as fit the room with a gap between each two, one at least, at most `most`.
func _formula(room: float, least: float, most: int) -> int:
	var fit := maxi(floori((room + GAP) / (least + GAP)), 1)
	return mini(fit, most) if most > 0 else fit


func _as_many_columns_as_fit_stand_across_at_every_room_up_to_the_most() -> void:
	var capped := _columns(12, &"card", 5, false)
	var open := _columns(20, &"card", 0, false)
	var wrong: Array = []
	# every room from 200 to 3000 in steps of 50, for the columns standing against the rule, with a most and with none
	for room: int in range(200, 3001, 50):
		capped.get_parent().size.x = room
		open.get_parent().size.x = room
		await _a_frame_passes()
		if _across(capped) != _formula(room, CARD, 5) or _across(open) != _formula(room, CARD, 0):
			wrong.append([room, _across(capped), _formula(room, CARD, 5), _across(open), _formula(room, CARD, 0)])
	_verdict.check(wrong.is_empty(), "at every room from 200 to 3000 the columns across are clamp(floor((room + gap) / (least + gap)), 1, most), at a most of five and with none: wrong at %s" % [wrong])
	capped.get_parent().size.x = 3000
	await _a_frame_passes()
	_verdict.check(_across(capped) == 5 and _rows(capped) == 3, "with room for sixteen, twelve stand five across, at their most, in three rows: %d across, %d rows" % [_across(capped), _rows(capped)])
	capped.get_parent().size.x = 150
	await _a_frame_passes()
	_verdict.check(_across(capped) == 1, "with room for none at its least, one column still stands: %d" % _across(capped))
	capped.get_parent().free()
	open.get_parent().free()


func _balanced_it_is_the_fewest_columns_that_make_the_same_rows() -> void:
	var ten := _columns(10, &"card", 0, true)
	var plain := _columns(10, &"card", 0, false)
	var four := _columns(4, &"card", 0, true)
	ten.get_parent().size.x = 6 * CARD + 5 * GAP + 20.0
	plain.get_parent().size.x = 6 * CARD + 5 * GAP + 20.0
	four.get_parent().size.x = 3 * CARD + 2 * GAP + 20.0
	await _a_frame_passes()
	_verdict.check(_across(plain) == 6 and _across(ten) == 5 and _rows(ten) == 2, "ten that fit six across stand five and five, in the two rows six across would make: %d across unbalanced, %d across in %d rows balanced" % [_across(plain), _across(ten), _rows(ten)])
	_verdict.check(_across(four) == 2 and _rows(four) == 2, "four that fit three across stand two and two: %d across in %d rows" % [_across(four), _rows(four)])
	var wrong: Array = []
	# every room from 200 to 2400 in steps of 40, for balanced rows that differ from the plain ones or columns that could be fewer
	for room: int in range(200, 2401, 40):
		ten.get_parent().size.x = room
		plain.get_parent().size.x = room
		await _a_frame_passes()
		if _rows(ten) != _rows(plain) or ceili(10.0 / (_across(ten) - 1)) == _rows(ten):
			wrong.append([room, _across(plain), _rows(plain), _across(ten), _rows(ten)])
	_verdict.check(wrong.is_empty(), "at every room the balanced columns make as many rows as the plain ones, and one column fewer would make more: wrong at %s" % [wrong])
	_verdict.check(Layout.across(10, 6, 0, true) == 5 and Layout.across(10, 4, 0, true) == 4 and Layout.across(12, 7, 5, false) == 5 and Layout.across(12, 7, 5, true) == 4 and Layout.across(3, 1, 0, true) == 1, "worked by hand: ten that fit six stand five; that fit four, four; twelve that fit seven at a most of five, five, and balanced, four in three rows; three that fit one, one")
	for made: Layout in [ten, plain, four]:
		made.get_parent().free()


func _every_part_is_a_column_wide_and_the_columns_fill_the_room() -> void:
	var columns := _columns(7, &"card", 0, false)
	columns.get_parent().size.x = 1000
	await _a_frame_passes()
	var parts: Array = columns.get_children()
	var width: float = (parts[0] as Control).size.x
	var last_of_first: Control = parts[_across(columns) - 1]
	_verdict.check(parts.all(func(part: Control) -> bool: return is_equal_approx(part.size.x, width)) and width >= CARD, "every part is as wide as every other, at least the least: %s" % [parts.map(func(part: Control) -> float: return part.size.x)])
	_verdict.check(last_of_first.get_rect().end.x <= 1000.0 and last_of_first.get_rect().end.x > 1000.0 - 1.0, "and a full row of them, with its gaps, fills the room to within a pixel without passing it: ends at %s of 1000" % last_of_first.get_rect().end.x)
	_verdict.check(is_equal_approx((parts[_across(columns)] as Control).size.x, width) and is_equal_approx((parts[_across(columns)] as Control).position.x, 0.0), "a row short of parts keeps their width and starts at the line's start: %s" % (parts[_across(columns)] as Control).get_rect())
	columns.get_parent().free()


func _a_column_is_never_under_the_widest_part_s_least() -> void:
	var named := _columns(6, &"card", 0, false)
	(named.get_child(2) as Control).custom_minimum_size.x = 300.0
	var unnamed := _columns(6, &"", 0, false, 140.0)
	named.get_parent().size.x = 1000
	unnamed.get_parent().size.x = 1000
	await _a_frame_passes()
	_verdict.check(named.get_children().all(func(part: Control) -> bool: return part.size.x >= part.get_combined_minimum_size().x) and _across(named) == _formula(1000, 300.0, 0), "one part needing 300 makes every column at least 300, so none is wider than its column: %d across, %s" % [_across(named), named.get_children().map(func(part: Control) -> float: return part.size.x)])
	_verdict.check(_across(unnamed) == _formula(1000, 140.0, 0) and is_equal_approx(unnamed.get_combined_minimum_size().x, 140.0), "with no least named, the widest part's least is the least: %d across, needing %s" % [_across(unnamed), unnamed.get_combined_minimum_size().x])
	named.get_parent().free()
	unnamed.get_parent().free()


func _its_least_is_one_column_whatever_room_it_is_given() -> void:
	var columns := _columns(8, &"card", 0, true, 60.0)
	var leasts: Array = []
	# rooms of 400, 800 and 2000, for the least it needs across at each
	for room: int in [400, 800, 2000]:
		columns.get_parent().size.x = room
		await _a_frame_passes()
		leasts.append(columns.get_combined_minimum_size().x)
	_verdict.check(leasts.all(func(least: float) -> bool: return is_equal_approx(least, CARD)), "its least across is one column of the least named, under parts that need less, at every room it is given: %s" % [leasts])
	columns.get_parent().free()


func _rows_share_the_height_left_only_when_every_one_fits() -> void:
	var lines: Array = [[0, 1], [2]]
	var across: Array = [40.0, 60.0, 50.0]
	var shared: Array = FlexLines.thicknesses(lines, across, 300.0, 10.0, true)
	_verdict.check(shared == [150.0, 140.0], "two rows of 60 and 50 with 10 between, in 300, share the 180 left: %s" % [shared])
	_verdict.check(is_equal_approx(shared[0] + shared[1] + 10.0, 300.0), "so they and their gap fill the room exactly: %s" % (shared[0] + shared[1] + 10.0))
	var unshared: Array = FlexLines.thicknesses(lines, across, 300.0, 10.0, false)
	_verdict.check(unshared == [60.0, 50.0], "not sharing, each row is its thickest part: %s" % [unshared])
	var short: Array = FlexLines.thicknesses(lines, across, 100.0, 10.0, true)
	_verdict.check(short == [60.0, 50.0], "and sharing, in 100 - less than the 120 they need - each is its thickest, for what holds them to scroll: %s" % [short])
	var columns := _columns(4, &"card", 0, false)
	_verdict.check(not columns._rows_share, "columns say their rows share the height only when told to")
	columns.lays_columns(&"card", 0, false, true)
	_verdict.check(columns._rows_share, "and told to, say so to the line placing them")
	columns.get_parent().free()
