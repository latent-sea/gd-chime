extends SceneTree

## What must be true of a held line whose parts fold by rank: what folds is
## a pure function of the room, the same whatever a slotted figure shows;
## it never grows as the room widens, swept a pixel at a time; the least
## needed take their short forms first, and fold only once every short form
## is taken, the least needed first; a KEEP part never folds; it needs its
## KEEP parts short, the menu press and the gaps, and would most like every
## part full; laid out, it shows exactly what it says folds, on one line,
## inside its width, the menu press while a MENU part is folded; it keeps
## one height whatever folds; and the folded names reach its local in rank
## order.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_priority_row.gd
##
## Each statement is in the floor's look, the line and its slots described
## as any app describes them (ui.priority_row, ui.room_for). Its parts are
## words: a part's kind does not matter to a line that measures every part
## by its least.

const Fixture := preload("res://tests/fixture.gd")
const Verdict := preload("res://tests/verdict.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const PriorityRow := preload("res://addons/gd_chime/components/primitives/priority_row.gd")

## The rooms swept, a pixel at a time.
const NARROWEST := 300
const WIDEST := 2600
## The parts in rank order, the most needed first, with the forms they take and where they fold.
const BACK := &"back"
const CLOCK := &"clock"
const HOUSE := &"house"
const SETTINGS := &"settings"
const CHAPTER := &"chapter"
const MARK := &"mark"

var _verdict := Verdict.new()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(2800, 400)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_what_folds_is_a_pure_function_of_the_room_whatever_a_slotted_figure_shows)
	await _verdict.states(_what_folds_never_grows_as_the_room_widens)
	await _verdict.states(_the_least_needed_take_short_forms_first_and_fold_only_after_the_least_needed_first)
	await _verdict.states(_a_keep_part_never_folds_and_it_needs_its_keep_parts_short_with_the_menu_and_gaps)
	await _verdict.states(_laid_out_it_shows_what_it_says_folds_on_one_line_inside_its_width)
	await _verdict.states(_it_keeps_one_height_whatever_folds)
	await _verdict.states(_the_folded_names_reach_its_local_in_rank_order)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## A builder.
func _made() -> Fixture:
	return Fixture.new(root)


## A plain control of this size under the root, for a piece to be built into.
func _host(of: Vector2) -> Control:
	var host := Control.new()
	host.size = of
	root.add_child(host)
	return host


## Words in the Face kind, named so they can be found.
func _words(ui: RefCounted, said: Variant, named: StringName) -> Desc:
	return ui.text(said, Themes.FACE).named(named)


## The line: six parts in rank order - back, kept, with a short form; a
## clock, kept, in a slot of its widest samples; two that fold behind the
## menu, the second with a short form; one that folds to the page; and a
## mark that goes - writing what folds to this local.
func _line(ui: RefCounted, folded: RefCounted, clock: Variant = "0:00") -> Desc:
	var parts := [
		{"name": BACK, "part": _words(ui, "BACK TO THE CARD", &"back full"), "short": _words(ui, "BACK", &"back short"), "folds": PriorityRow.KEEP},
		{"name": CLOCK, "part": ui.room_for(_words(ui, clock, &"clock words"), ["0:00", "RUNNING NOW"], Themes.FACE).named(&"clock full"), "folds": PriorityRow.KEEP},
		{"name": HOUSE, "part": _words(ui, "HOUSE RULES", &"house full"), "folds": PriorityRow.MENU},
		{"name": SETTINGS, "part": _words(ui, "SETTINGS AND SOUND", &"settings full"), "short": _words(ui, "SETTINGS", &"settings short"), "folds": PriorityRow.MENU},
		{"name": CHAPTER, "part": _words(ui, "THE LONGEST CHAPTER THERE IS", &"chapter full"), "folds": PriorityRow.PAGE},
		{"name": MARK, "part": _words(ui, "A DECORATION", &"mark full"), "folds": PriorityRow.GONE},
	]
	return ui.priority_row(parts, folded, _words(ui, "MENU", &"menu"), Themes.ROW).named(&"line")


## The line built into a host this wide, with the local it writes to.
func _built(made: Fixture, wide: float, clock: Variant = "0:00") -> Array:
	var folded: RefCounted = made.ui.local([])
	var host := _host(Vector2(wide, 200))
	made.ui.build(_line(made.ui, folded, clock), host)
	await _a_frame_passes()
	return [host, made.ui.node_named(&"line"), folded]


func _what_folds_is_a_pure_function_of_the_room_whatever_a_slotted_figure_shows() -> void:
	var made := _made()
	var model := Fixture.Model.new(made.chimes)
	model.set_value(&"words", "0:00")
	var built: Array = await _built(made, 2000, model.of(&"words"))
	var line: Control = built[1]
	var before: Array = []
	# every tenth room of the sweep, what the line does there with the clock showing its narrowest
	for room: int in range(NARROWEST, WIDEST, 10):
		before.append(line.fold_at(room))
	model.set_value(&"words", "RUNNING NOW")
	await _a_frame_passes()
	var after: Array = []
	# the same rooms, the clock now showing its widest
	for room: int in range(NARROWEST, WIDEST, 10):
		after.append(line.fold_at(room))
	_verdict.check(before == after, "what folds and what is short at every room is the same whatever the clock shows")
	_verdict.check(line.fold_at(700) == line.fold_at(700), "and asked twice at one room, the same answer: %s" % line.fold_at(700))
	built[0].free()
	model.free()
	made.done()


func _what_folds_never_grows_as_the_room_widens() -> void:
	var made := _made()
	var built: Array = await _built(made, 2000)
	var line: Control = built[1]
	var grew: Array = []
	var narrower: Array = line.fold_at(NARROWEST)["folded"]
	var counts := {}
	# every room from the narrowest to the widest, a pixel at a time, for one whose folded set holds a part the narrower one did not
	for room: int in range(NARROWEST + 1, WIDEST + 1):
		var folded: Array = line.fold_at(room)["folded"]
		counts[folded.size()] = true
		if folded.any(func(named: StringName) -> bool: return not narrower.has(named)):
			grew.append(room)
		narrower = folded
	_verdict.check(grew.is_empty(), "from %d to %d a pixel at a time, a wider room never folds a part a narrower one kept: grew at %s" % [NARROWEST, WIDEST, grew.slice(0, 5)])
	_verdict.check(counts.size() == 5, "and the sweep passes through every count folded, none to all four that may fold: %s" % [counts.keys()])
	built[0].free()
	made.done()


func _the_least_needed_take_short_forms_first_and_fold_only_after_the_least_needed_first() -> void:
	var made := _made()
	var built: Array = await _built(made, 2000)
	var line: Control = built[1]
	var full: float = line.preferred_size().x
	var first_short: Dictionary = line.fold_at(full - 1.0)
	_verdict.check(first_short["short"] == [SETTINGS] and first_short["folded"].is_empty(), "a pixel short of every part full, the least needed with a short form takes it, and nothing folds: %s" % first_short)
	var all_short: float = full - (made.ui.node_named(&"back full").get_combined_minimum_size().x - made.ui.node_named(&"back short").get_combined_minimum_size().x) - (made.ui.node_named(&"settings full").get_combined_minimum_size().x - made.ui.node_named(&"settings short").get_combined_minimum_size().x)
	var both_short: Dictionary = line.fold_at(all_short)
	_verdict.check(both_short["short"] == [BACK, SETTINGS] and both_short["folded"].is_empty(), "at the length of every short form taken, both are short and still nothing folds: %s" % both_short)
	var first_fold: Dictionary = line.fold_at(all_short - 1.0)
	_verdict.check(first_fold["folded"] == [MARK], "a pixel shorter, the least needed part folds first, the mark that goes: %s" % first_fold)
	var order: Array = []
	# every room down from there, noting each part as it first folds
	for room: int in range(int(all_short) - 1, NARROWEST - 200, -1):
		for named: StringName in line.fold_at(room)["folded"]:
			if not order.has(named):
				order.append(named)
	_verdict.check(order == [MARK, CHAPTER, SETTINGS, HOUSE], "and narrowing on, they fold the least needed first: %s" % [order])
	built[0].free()
	made.done()


func _a_keep_part_never_folds_and_it_needs_its_keep_parts_short_with_the_menu_and_gaps() -> void:
	var made := _made()
	var built: Array = await _built(made, 2000)
	var line: Control = built[1]
	var nothing: Dictionary = line.fold_at(0.0)
	_verdict.check(nothing["folded"] == [HOUSE, SETTINGS, CHAPTER, MARK] and nothing["short"] == [BACK], "given no room at all, every part that may fold is folded, and back, kept, stands short: %s" % nothing)
	var gap := float(line.get_theme_constant(&"gap", Themes.ROW))
	var least: float = made.ui.node_named(&"back short").get_combined_minimum_size().x + made.ui.node_named(&"clock full").get_combined_minimum_size().x + made.ui.node_named(&"menu").get_combined_minimum_size().x + 2.0 * gap
	_verdict.check(is_equal_approx(line.get_combined_minimum_size().x, least), "it needs across back short, the clock's slot and the menu press, with a gap between each two: %s of %s" % [line.get_combined_minimum_size().x, least])
	var preferred := 0.0
	# every full form, end to end
	for named: StringName in [&"back full", &"clock full", &"house full", &"settings full", &"chapter full", &"mark full"]:
		preferred += made.ui.node_named(named).get_combined_minimum_size().x
	_verdict.check(is_equal_approx(line.preferred_size().x, preferred + 5.0 * gap), "and would most like every part full, with no menu: %s of %s" % [line.preferred_size().x, preferred + 5.0 * gap])
	built[0].free()
	made.done()


func _laid_out_it_shows_what_it_says_folds_on_one_line_inside_its_width() -> void:
	var made := _made()
	var built: Array = await _built(made, 2000)
	var host: Control = built[0]
	var line: Control = built[1]
	var wrong: Array = []
	# rooms from its least to past every part full, a line laid out in each
	for room: float in [line.get_combined_minimum_size().x, 420.0, 560.0, 700.0, 840.0, 980.0, 1120.0, line.preferred_size().x - 1.0, line.preferred_size().x]:
		host.size.x = room
		await _a_frame_passes()
		var says: Dictionary = line.fold_at(room)
		var menu_says: bool = says["folded"].has(HOUSE) or says["folded"].has(SETTINGS)
		# every part's forms, against what the line says of it at this room
		for named: StringName in [BACK, CLOCK, HOUSE, SETTINGS, CHAPTER, MARK]:
			var full: Control = made.ui.node_named(StringName("%s full" % named))
			var short: Control = made.ui.node_named(StringName("%s short" % named))
			var should_full: bool = not says["folded"].has(named) and not says["short"].has(named)
			if full.visible != should_full or (short != null and short.visible != says["short"].has(named)):
				wrong.append("%s at %s" % [named, room])
		if made.ui.node_named(&"menu").visible != menu_says:
			wrong.append("the menu at %s" % room)
		var shown: Array = line.get_children().filter(func(part: Node) -> bool: return (part as Control).visible)
		# every part shown, for one off the line or past its right edge
		for part: Control in shown:
			if part.position.y != 0.0 or part.get_rect().end.x > room + 0.5:
				wrong.append("%s placed at %s in %s" % [part.name, part.get_rect(), room])
	_verdict.check(wrong.is_empty(), "at every room it shows each part's form exactly as it says, the menu press while a MENU part is folded, all on one line inside its width: %s" % [wrong])
	host.free()
	made.done()


func _it_keeps_one_height_whatever_folds() -> void:
	var made := _made()
	var built: Array = await _built(made, 2000)
	var host: Control = built[0]
	var line: Control = built[1]
	var tallest := 0.0
	# every form of every part, for the tallest of them
	for part: Node in line.get_children():
		tallest = maxf(tallest, (part as Control).get_combined_minimum_size().y)
	var heights := {}
	# rooms where nothing, some and everything that may fold is folded
	for room: float in [line.get_combined_minimum_size().x, 600.0, line.preferred_size().x]:
		host.size.x = room
		await _a_frame_passes()
		heights[line.get_combined_minimum_size().y] = room
	_verdict.check(heights.size() == 1 and heights.has(tallest), "it needs the height of its tallest form at every room, whatever folds: %s, the tallest %s" % [heights, tallest])
	host.free()
	made.done()


func _the_folded_names_reach_its_local_in_rank_order() -> void:
	var made := _made()
	var built: Array = await _built(made, 2000)
	var host: Control = built[0]
	var line: Control = built[1]
	var folded: RefCounted = built[2]
	_verdict.check(folded.read() == [], "with room for every part, nothing is written folded: %s" % [folded.read()])
	host.size.x = line.get_combined_minimum_size().x
	await _a_frame_passes()
	_verdict.check(folded.read() == [HOUSE, SETTINGS, CHAPTER, MARK], "at its least, every part that may fold, in rank order: %s" % [folded.read()])
	host.size.x = 2000
	await _a_frame_passes()
	_verdict.check(folded.read() == [], "and given the room again, none: %s" % [folded.read()])
	host.free()
	made.done()
