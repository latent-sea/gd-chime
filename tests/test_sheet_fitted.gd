extends SceneTree

## What must be true of a fitted sheet (sheet.gd: fitted, standing in
## capped.gd): at every room it stands in the middle of the safe rect, as
## wide as the room less the look's margin either side, at most the look's
## most, and as tall as it needs, at most the room less the margin; where
## that cap leaves less than its least, the margin goes and it meets the
## safe rect's edges. Its head and its foot of ways out are pinned and its
## body scrolls, so every press of the foot is inside the safe rect with the
## body at any offset, and with the keyboard up. The shade and Back each
## take its way out: CLOSES, going back, or the model's own for a pop-up a
## model presents. Its shade darkens the whole window, the band round the
## safe rect included.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_sheet_fitted.gd
##
## Every room is a window at 450 dots to the inch, a cutout of 89 pixels
## down its long edge's start, under a look whose base pixel is at least
## 120 thousandths of a millimetre, with a gutter of 12 and a floor of 360:
## the A55's numbers (test_safe_area.gd). The sweep runs windows from a
## short side of 810 pixels - under the floor, so drawn smaller - to 2400,
## at aspects from 0.45 to 2.4, both ways round.

const Fixture := preload("res://tests/fixture.gd")
const Verdict := preload("res://tests/verdict.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Easel := preload("res://addons/gd_chime/easel.gd")
const Shape := preload("res://addons/gd_chime/shape.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const PageScroll := preload("res://addons/gd_chime/components/primitives/page_scroll.gd")
const ShadeBand := preload("res://addons/gd_chime/components/primitives/shade_band.gd")
const Sheet := preload("res://addons/gd_chime/components/recipes/sheet.gd")

## The screen's dots to the inch, its cutout in pixels, and the look's least base pixel, gutter and floor.
const DPI := 450
const CUTOUT := 89
const LEAST_UM := 120
const GUTTER := 12
const FLOOR := 360
## The look's sheet margin and most across, in base pixels.
const MARGIN := 24
const MOST := 900
## The sweep: each window's short side in pixels, and its long side over its short.
const SHORT_SIDES: Array[int] = [810, 1080, 1440, 2400]
const ASPECTS: Array[float] = [1.0, 1.33, 1.78, 2.2, 2.4]
## The actions: opening each sheet, a press of the foot, typing in the body, and a model's own way out.
const OPENS_LONG := &"opens_the_long_sheet"
const OPENS_SHORT := &"opens_the_short_sheet"
const CONFIRMS := &"confirms"
const TYPES := &"types"
const CANCELS := &"cancels_the_question"
## How many lines the long body holds: more than any room shows.
const LINES := 60

var _verdict := Verdict.new()
var _easel: Easel
var _made: Fixture
var _keyboard_px: int = 0  # the keyboard's height the screen reports, in pixels
var _long: Desc  # the sheet whose body holds more than any room shows
var _short: Desc  # the sheet whose body holds three lines, and three more while the model's "more" holds
var _asked: Desc  # the sheet a model presents, its way out the model's
var _asking: Questions


## The model presenting a question: asking while it presents it, and told its way out to stop.
class Questions extends Fixture.Model:
	func told(action: StringName, payload: Dictionary) -> Phrase:
		super(action, payload)
		if action == CANCELS:
			of(&"asking").set_value(false)
		return null


func _init() -> void:
	await process_frame
	await _standing()
	await _verdict.states(_at_every_room_it_stands_in_the_middle_of_the_safe_rect_capped_by_the_look)
	await _verdict.states(_at_every_room_its_head_and_foot_are_pinned_inside_the_safe_rect_and_its_body_scrolls)
	await _verdict.states(_a_short_body_makes_a_sheet_as_tall_as_it_needs_and_no_scroll)
	await _verdict.states(_where_the_cap_leaves_less_than_its_least_the_margin_goes_and_it_meets_the_safe_edges)
	await _verdict.states(_with_the_keyboard_up_the_foot_stands_above_it)
	await _verdict.states(_its_shade_darkens_the_whole_window)
	await _verdict.states(_the_shade_and_back_each_take_its_way_out)
	_made.done()
	_easel.free()
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	# a few frames: the canvas fitted, the pop-up laid, what its page holds measured and the sheet laid again
	for frame: int in 4:
		await process_frame


## The look: the A55's base pixel, the gutter and the floor, and the sheet's cap.
func _look() -> Theme:
	var made := Themes.new(Themes.NEUTRAL)
	made.set_constant(&"least_pixel_um", Shape.TYPE, LEAST_UM)
	made.set_constant(&"edge", Shape.TYPE, GUTTER)
	made.set_constant(&"floor", Shape.TYPE, FLOOR)
	made.set_constant(&"margin", Sheet.LOOK, MARGIN)
	made.set_constant(&"most_wide", Sheet.LOOK, MOST)
	return made


## An easel answering every read of its screen as the A55 would, and an app on
## it opening the long sheet and the short one, with the question beside them.
func _standing() -> void:
	_easel = Easel.new()
	_easel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_easel.canvas.theme = _look()
	_easel.reads_dpi = func() -> int: return DPI
	_easel.reads_corner_um = func() -> int: return 0
	_easel.reads_safe_area = _cutout
	_easel.reads_keyboard = func() -> int: return _keyboard_px
	root.add_child(_easel)
	root.size = Vector2i(2340, 1080)
	await _a_frame_passes()
	_made = Fixture.new(_easel.canvas, {OPENS_LONG: "open", OPENS_SHORT: "open", CONFIRMS: "confirm", TYPES: "type", CANCELS: "cancel"})
	var ui := _made.ui
	_made.answer([CONFIRMS, TYPES])
	_asking = Questions.new(_made.chimes)
	_asking.answering = [CANCELS]
	_made.commands.stand(Chimes.GLOBAL, _asking)
	ui.root.add_child(_asking)
	var lines: Array = range(LINES).map(func(line: int) -> Desc: return ui.text("line %d" % line))
	_long = ui.pop_up(&"long", func(_which: Bound) -> Desc: return _fitted(ui, ui.column([ui.field(TYPES).named(&"field")] + lines)))
	var more := _asking.of(&"more", false)
	var three_more := ui.when(ui.bound(more.read), ui.column([ui.text("four"), ui.text("five"), ui.text("six")]))
	_short = ui.pop_up(&"short", func(_which: Bound) -> Desc: return _fitted(ui, ui.column([ui.text("one"), ui.text("two"), ui.text("three"), three_more])))
	_asked = ui.pop_up(&"asked", func(_which: Bound) -> Desc: return Sheet.fitted(ui, {body = ui.text("a question"), foot = ui.button(CANCELS), style = &"Confirm", way_out = CANCELS}), null, CANCELS)
	_asked.props["presented"] = _asking.of(&"asking", false)
	var openers := [ui.pressable(OPENS_LONG, {}, [ui.text("long")]).opens(_long).named(&"opens_long"), ui.pressable(OPENS_SHORT, {}, [ui.text("short")]).opens(_short).named(&"opens_short")]
	ui.start(ui.app(&"app", [ui.screen(&"home", [ui.column(openers + [_asked])])]))
	await _a_frame_passes()


## A fitted sheet holding this body: a head, and a foot of two ways out -
## closing it, going back (Sheet.close), and confirming.
func _fitted(ui: RefCounted, body: Desc) -> Desc:
	var foot: Desc = ui.row([Sheet.close(ui), ui.pressable(CONFIRMS, {}, [ui.text("confirm")])])
	return Sheet.fitted(ui, {head = ui.text("the head of the sheet"), body = body, foot = foot, style = &"Confirm"})


## The A55's unobscured area: the cutout down its left held sideways, at its top upright.
func _cutout() -> Rect2i:
	var cut := Vector2i(0, CUTOUT) if root.size.y > root.size.x else Vector2i(CUTOUT, 0)
	return Rect2i(root.position + cut, root.size - cut)


## Every window of the sweep: each short side at each aspect, sideways and upright.
func _rooms() -> Array[Vector2i]:
	var windows: Array[Vector2i] = []
	# each short side at each aspect, held both ways
	for short: int in SHORT_SIDES:
		for aspect: float in ASPECTS:
			windows.append(Vector2i(roundi(short * aspect), short))
			windows.append(Vector2i(short, roundi(short * aspect)))
	return windows


## The pop-up raised, by its opener.
func _open(sheet: Desc, opener: StringName) -> void:
	(_made.ui.node_named(opener) as Pressable).pressed()
	await _a_frame_passes()
	_verdict.check(_made.driver.get_top().has(sheet.get_place()), "the sheet is up: %s" % [_made.driver.get_top()])


## Back, through the door, as every road to it is (go_back.gd).
func _back() -> void:
	_made.commands.dispatch(Chimes.GLOBAL, Driver.GOES_BACK, {})
	await _a_frame_passes()


## What stands in a pop-up: its sheet - the surface its page stands in - its page, its shade and its foot's presses.
func _sheet_of(sheet: Desc) -> Control:
	return _page_of(sheet).get_parent().get_parent()


func _page_of(sheet: Desc) -> PageScroll:
	return _made.driver.index.place_named(sheet.get_place()).find_children("*", "ScrollContainer", true, false).filter(func(found: Node) -> bool: return found is PageScroll)[0]


func _shade_of(sheet: Desc) -> Pressable:
	return _made.driver.index.place_named(sheet.get_place()).find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable and part.theme_type_variation == Sheet.SHADE)[0]


func _foot_presses(sheet: Desc) -> Array:
	var column := _page_of(sheet).get_parent()
	var foot: Control = column.get_child(column.get_child_count() - 1)
	return foot.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable)


## What R13 says the sheet's length is on an axis: the cap, or, where that is under its least, the room.
func _expected(room: float, need: float, most: float, least: float) -> float:
	var capped := minf(minf(need, most), room - 2.0 * MARGIN)
	return capped if capped >= least else maxf(least, minf(minf(need, most), room))


func _at_every_room_it_stands_in_the_middle_of_the_safe_rect_capped_by_the_look() -> void:
	await _open(_long, &"opens_long")
	var wrong: Array = []
	# every room of the sweep, the long sheet up: its rect against what the cap says
	for window: Vector2i in _rooms():
		root.size = window
		await _a_frame_passes()
		var safe := _easel.canvas.get_safe()
		var sheet := _sheet_of(_long)
		var least := sheet.get_combined_minimum_size()
		var wants := Vector2(_expected(safe.size.x, INF, MOST, least.x), _expected(safe.size.y, INF, INF, least.y))
		var laid := sheet.get_global_rect()
		# the size R13 gives, in the middle of the safe rect, and wholly inside it
		if not (laid.size.is_equal_approx(wants) and laid.get_center().is_equal_approx(safe.get_center()) and safe.grow(0.5).encloses(laid)):
			wrong.append("%s: %s in %s, wanted %s" % [window, laid, safe, wants])
	_verdict.check(wrong.is_empty() and _rooms().size() == 40, "in all 40 rooms the sheet is as wide as the room less the margin, at most the most, as tall as the room less the margin, in the middle of the safe rect: %s" % [wrong])
	await _back()


func _at_every_room_its_head_and_foot_are_pinned_inside_the_safe_rect_and_its_body_scrolls() -> void:
	await _open(_long, &"opens_long")
	var wrong: Array = []
	# every room of the sweep: the foot's presses inside the safe rect, at the body's start and at its end
	for window: Vector2i in _rooms():
		root.size = window
		await _a_frame_passes()
		var safe := _easel.canvas.get_safe().grow(0.5)
		var page := _page_of(_long)
		var column := page.get_parent()
		var head: Control = column.get_child(0)
		var presses := _foot_presses(_long)
		var before: Array = [head.get_global_rect()] + presses.map(func(press: Control) -> Rect2: return press.get_global_rect())
		# the focus on the foot, so the page follows nothing, and the body taken as far down as it goes
		(presses[1] as Control).grab_focus()
		page.scroll_vertical = 100000
		await _a_frame_passes()
		var after: Array = [head.get_global_rect()] + presses.map(func(press: Control) -> Rect2: return press.get_global_rect())
		var inside := after.all(func(rect: Rect2) -> bool: return safe.encloses(rect))
		# the body moved, the head and the foot did not, and every one of them is inside the safe rect
		if not (page.scroll_vertical > 0 and before == after and inside and presses.size() == 2):
			wrong.append("%s: scrolled %d, %s then %s in %s" % [window, page.scroll_vertical, before, after, safe])
		page.scroll_vertical = 0
	_verdict.check(wrong.is_empty(), "in every room the body scrolls while the head and both presses of the foot stay where they are, inside the safe rect: %s" % [wrong])
	await _back()


func _a_short_body_makes_a_sheet_as_tall_as_it_needs_and_no_scroll() -> void:
	root.size = Vector2i(2340, 1080)
	await _a_frame_passes()
	await _open(_short, &"opens_short")
	var safe := _easel.canvas.get_safe()
	var page := _page_of(_short)
	var held: Control = page.get_child(0)
	var sheet := _sheet_of(_short)
	var padding := page.get_theme_stylebox(&"panel").get_minimum_size().y
	_verdict.check(is_equal_approx(page.size.y, held.get_combined_minimum_size().y + padding) and page.get_v_scroll_bar().max_value <= page.size.y, "its page is exactly as tall as what it holds, with nothing to scroll: %s of %s" % [page.size.y, held.size.y])
	_verdict.check(sheet.size.y < safe.size.y - 2.0 * MARGIN and is_equal_approx(sheet.get_global_rect().get_center().y, safe.get_center().y), "so the sheet is shorter than the cap, in the middle of the safe rect: %s in %s" % [sheet.get_global_rect(), safe])
	_verdict.check(is_equal_approx(sheet.size.x, minf(safe.size.x - 2.0 * MARGIN, MOST)), "and still as wide as the cap across: %s" % sheet.size.x)
	var shorter := sheet.size.y
	_asking.of(&"more").set_value(true)
	await _a_frame_passes()
	_verdict.check(sheet.size.y > shorter and is_equal_approx(page.size.y, held.get_combined_minimum_size().y + padding), "three more lines shown while it is up, it grows to hold them all, still with nothing to scroll: %s from %s" % [sheet.size.y, shorter])
	_asking.of(&"more").set_value(false)
	await _back()


## A margin of 600 either side leaves nothing of an A55's safe room either way.
func _where_the_cap_leaves_less_than_its_least_the_margin_goes_and_it_meets_the_safe_edges() -> void:
	_easel.canvas.theme.set_constant(&"margin", Sheet.LOOK, 600)
	root.size = Vector2i(2340, 1081)
	await _a_frame_passes()
	await _open(_long, &"opens_long")
	var safe := _easel.canvas.get_safe()
	var laid := _sheet_of(_long).get_global_rect()
	_verdict.check(laid.is_equal_approx(Rect2(safe.get_center().x - MOST / 2.0, safe.position.y, MOST, safe.size.y)), "the margin gone both ways: as wide as the most, as tall as the safe rect, meeting its top and foot: %s in %s" % [laid, safe])
	_easel.canvas.theme.set_constant(&"margin", Sheet.LOOK, MARGIN)
	root.size = Vector2i(1080, 2340)
	await _a_frame_passes()
	safe = _easel.canvas.get_safe()
	laid = _sheet_of(_long).get_global_rect()
	_verdict.check(is_equal_approx(laid.size.x, safe.size.x - 2.0 * MARGIN) and is_equal_approx(laid.position.x, safe.position.x + MARGIN), "and given room for its margins again, it keeps them: %s in %s" % [laid, safe])
	await _back()


## Sideways, a keyboard of 600 pixels, which leaves the A55 under the floor's height.
func _with_the_keyboard_up_the_foot_stands_above_it() -> void:
	root.size = Vector2i(2340, 1080)
	await _a_frame_passes()
	await _open(_long, &"opens_long")
	var foot_before: Rect2 = _foot_presses(_long)[0].get_global_rect()
	_keyboard_px = 600
	var line: LineEdit = _made.ui.node_named(&"field").find_children("*", "LineEdit", true, false)[0]
	line.grab_focus()
	await _a_frame_passes()
	var safe := _easel.canvas.get_safe()
	var presses := _foot_presses(_long)
	_verdict.check(safe.end.y < _easel.canvas.size.y - 200.0 and presses.all(func(press: Control) -> bool: return safe.grow(0.5).encloses(press.get_global_rect())), "a field in the body holding the focus, the keyboard insets the foot, and both presses of the foot stand above it, inside the safe rect: %s in %s" % [presses.map(func(press: Control) -> Rect2: return press.get_global_rect()), safe])
	_verdict.check(presses[0].get_global_rect().position.y < foot_before.position.y, "moved up from where they stood: %s from %s" % [presses[0].get_global_rect(), foot_before])
	_verdict.check(safe.grow(0.5).encloses(line.get_global_rect()), "and the field typed in is in view: %s" % [line.get_global_rect()])
	_keyboard_px = 0
	await _back()


func _its_shade_darkens_the_whole_window() -> void:
	root.size = Vector2i(2340, 1080)
	await _a_frame_passes()
	await _open(_short, &"opens_short")
	var place: Control = _made.driver.index.place_named(_short.get_place())
	var band: ShadeBand = place.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is ShadeBand)[0]
	var shade: Control = _shade_of(_short)
	var canvas := Rect2(Vector2.ZERO, _easel.canvas.size)
	var safe := _easel.canvas.get_safe()
	var painted: Array = band.painted().map(func(rect: Rect2) -> Rect2: return Rect2(rect.position + band.get_global_rect().position, rect.size))
	var area: float = painted.reduce(func(sum: float, rect: Rect2) -> float: return sum + rect.get_area(), 0.0)
	_verdict.check(band.get_global_rect() == safe and shade.get_global_rect() == safe and band.get_index() < shade.get_index(), "the band and the shade's press both stand in the safe rect, the band under the press: %s %s" % [band.get_global_rect(), shade.get_global_rect()])
	_verdict.check(painted.all(func(rect: Rect2) -> bool: return canvas.encloses(rect) and not rect.intersects(safe)) and is_equal_approx(area + safe.get_area(), canvas.get_area()), "the band paints all of the window outside the safe rect, and none of it twice: %s of %s" % [painted, canvas])
	await _back()


func _the_shade_and_back_each_take_its_way_out() -> void:
	var lowered: Array = []
	# a sheet closing, by a press on its shade and by Back
	for way: StringName in [&"shade", &"back"]:
		await _open(_short, &"opens_short")
		match way:
			&"shade": _shade_of(_short).pressed()
			&"back": _made.commands.dispatch(Chimes.GLOBAL, Driver.GOES_BACK, {})
		await _a_frame_passes()
		lowered.append(not _made.driver.get_top().has(_short.get_place()))
	_verdict.check(lowered == [true, true], "a sheet whose way out is CLOSES is lowered by a press on its shade and by Back: %s" % [lowered])
	var told: Array = []
	# a sheet a model presents, by a press on its shade and by Back
	for way: StringName in [&"shade", &"back"]:
		_asking.of(&"asking").set_value(true)
		await _a_frame_passes()
		var shade := _shade_of(_asked)
		match way:
			&"shade": shade.pressed()
			&"back": _made.commands.dispatch(Chimes.GLOBAL, Driver.GOES_BACK, {})
		await _a_frame_passes()
		told.append([shade.action, _asking.told_actions.back(), _made.driver.get_top().has(_asked.get_place())])
	_verdict.check(told == [[CANCELS, CANCELS, false], [CANCELS, CANCELS, false]], "a sheet a model presents has a shade pressing the model's own way out, and a press on it and Back each tell the model that, which lowers it: %s" % [told])
