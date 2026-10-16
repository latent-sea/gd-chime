extends SceneTree

## What must be true of an application's bar: it keeps one height whatever
## its words, its figures and its room; what folds never grows as the room
## widens, swept a pixel at a time, and is the same on two bars saying
## different things from the same samples; laid out, the row folds what it
## says it folds; what the screen says stands in the bar while its longest
## sample fits, and otherwise heads the page through the spill; and MENU,
## shown while a press is folded behind it, opens a sheet of exactly the
## folded presses.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_app_bar.gd
##
## Each statement is an app of two bars over a scrolling page holding the
## first bar's spill, in the floor's look, the window as wide as the
## statement sets, the bars' slots and line described as any app describes
## them (ui.room_for, ui.priority_row). Both bars have the same parts in
## the same ranks - back with a short form, a clock and a balance in
## slots, two presses that fold behind MENU, a chapter press that folds to
## the page - and the same samples of what they may say; they say different
## things now.

const Fixture := preload("res://tests/fixture.gd")
const Verdict := preload("res://tests/verdict.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const PriorityRow := preload("res://addons/gd_chime/components/primitives/priority_row.gd")
const AppBar := preload("res://addons/gd_chime/components/recipes/app_bar.gd")
const Page := preload("res://addons/gd_chime/components/recipes/page.gd")

const LEAVES := &"leaves_the_card"
const HOUSE := &"opens_the_house"
const SETTINGS := &"opens_the_settings"
const CHAPTER := &"opens_the_chapter"
## The rooms swept, a pixel at a time.
const NARROWEST := 300
const WIDEST := 2600
## The longest the bars may say, and the two things they say now.
const SAID_SAMPLES := ["PICK THE FIVE ENTRIES YOU WILL SEND IN ON THIS FORM", "THE CARD"]
const SHORT_SAID := "THE CARD"

var _verdict := Verdict.new()
var _made: Fixture
var _model: Fixture.Model  # the figures and the words the first bar says
var _folded: Array = []  # the locals each bar writes its folded names to, the first bar's first


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(2600, 700)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_it_keeps_one_height_whatever_its_words_its_figures_and_its_room)
	await _verdict.states(_what_folds_never_grows_as_the_room_widens_and_is_the_same_on_both_bars)
	await _verdict.states(_laid_out_the_row_folds_what_it_says_it_folds_on_both_bars_alike)
	await _verdict.states(_what_the_screen_says_stands_in_the_bar_while_its_longest_sample_fits_else_heads_the_page)
	await _verdict.states(_menu_shows_while_a_press_is_folded_and_opens_a_sheet_of_exactly_the_folded_presses)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## A bar's parts in rank order: back, short '<'; the clock and the balance in slots; house and settings behind MENU; the chapter to the page.
func _parts(ui: RefCounted, named: String) -> Array:
	return [
		{"name": &"back", "part": ui.button(LEAVES), "short": ui.pressable(LEAVES, {}, [ui.text("<", Themes.FACE)]), "folds": PriorityRow.KEEP},
		{"name": &"clock", "part": ui.room_for(ui.text(_model.of(&"clock"), Themes.FACE), ["0:00", "RUNNING NOW"], Themes.FACE), "folds": PriorityRow.KEEP},
		{"name": &"balance", "part": ui.room_for(ui.text(_model.of(&"balance"), Themes.FACE), ["9,999,999"], Themes.FACE), "folds": PriorityRow.KEEP},
		{"name": &"house", "part": ui.button(HOUSE), "folds": PriorityRow.MENU},
		{"name": &"settings", "part": ui.button(SETTINGS), "folds": PriorityRow.MENU},
		{"name": &"chapter", "part": ui.button(CHAPTER).named(StringName("%s chapter" % named)), "line": ui.button(CHAPTER), "folds": PriorityRow.PAGE},
	]


## Two bars, the first saying what the model says and the second a long instruction, over a page headed by the first's spill.
func _started() -> void:
	_made = Fixture.new(root, {LEAVES: "Back to the card", HOUSE: "House", SETTINGS: "Settings", CHAPTER: "The longest chapter of them all"})
	AppBar.declare(_made.actions)
	var ui := _made.ui
	_model = Fixture.Model.new(_made.chimes)
	_model.set_value(&"clock", "0:00")
	_model.set_value(&"balance", "12")
	_model.set_value(&"said", SHORT_SAID)
	_made.answer([LEAVES, HOUSE, SETTINGS, CHAPTER])
	_folded = [ui.local([]), ui.local([])]
	var first := AppBar.make(ui, {parts = _parts(ui, "first"), said = _model.of(&"said"), said_samples = SAID_SAMPLES, folded = _folded[0]})
	var second := AppBar.make(ui, {parts = _parts(ui, "second"), said = SAID_SAMPLES[0], said_samples = SAID_SAMPLES, folded = _folded[1]})
	var page := Page.scrolling(ui, ui.text("the page", Themes.WORDS), {spill = first["spill"].named(&"spill")})
	ui.start(ui.app(&"app", [ui.column([first["bar"].named(&"first bar"), second["bar"].named(&"second bar"), page.grow()])]))
	await _a_frame_passes()


func _done() -> void:
	_model.free()
	_made.done()


## The priority row of the bar of this name.
func _row(bar: StringName) -> Control:
	return _made.ui.node_named(bar).get_child(0)


## Every pressable of this action shown on the screen.
func _shown(action: StringName) -> Array:
	return root.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable and (part as Pressable).action == action and (part as Control).is_visible_in_tree())


## Whether a node stands inside the pop-up on top.
func _in_pop_up(node: Node) -> bool:
	var named := String(_made.driver.get_top()[0])
	var holder := node.get_parent()
	# up from the node, for the pop-up's place
	while holder != null and String(holder.name) != named:
		holder = holder.get_parent()
	return holder != null


## The words shown under a node.
func _texts(node: Node) -> Array:
	return node.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Text and (part as Control).is_visible_in_tree()).map(func(part: Node) -> String: return (part as Text).get_text())


func _it_keeps_one_height_whatever_its_words_its_figures_and_its_room() -> void:
	await _started()
	var bar: Control = _made.ui.node_named(&"first bar")
	var label := Label.new()
	label.theme_type_variation = Themes.TITLE
	label.text = SAID_SAMPLES[0]
	root.add_child(label)
	var title_line := label.get_minimum_size().y
	label.free()
	var held := bar.size.y
	var moved: Array = []
	# rooms from narrow to wide, each with the bar saying and showing its least and its most
	for wide: int in [NARROWEST, 420, 640, 900, 1300, 1800, WIDEST]:
		root.size.x = wide
		# its shortest and longest words and figures in turn
		for shows: Array in [[SHORT_SAID, "0:00", "1"], [SAID_SAMPLES[0], "RUNNING NOW", "9,999,999"]]:
			_model.set_value(&"said", shows[0])
			_model.set_value(&"clock", shows[1])
			_model.set_value(&"balance", shows[2])
			await _a_frame_passes()
			if bar.size.y != held or bar.get_combined_minimum_size().y != held:
				moved.append("%s at %d saying '%s'" % [bar.size.y, wide, shows[0]])
	_verdict.check(held >= title_line, "the bar is at least a Title line tall: %s, the line %s" % [held, title_line])
	_verdict.check(moved.is_empty(), "at every room, saying and showing its least and its most, the bar keeps the height it first had, %s: %s" % [held, moved])
	_verdict.check(_made.ui.node_named(&"second bar").size.y == held, "and the second bar, saying something else, is the same height: %s" % _made.ui.node_named(&"second bar").size.y)
	root.size.x = WIDEST
	_done()


func _what_folds_never_grows_as_the_room_widens_and_is_the_same_on_both_bars() -> void:
	await _started()
	var first := _row(&"first bar")
	var second := _row(&"second bar")
	var grew: Array = []
	var differ: Array = []
	var narrower: Array = first.fold_at(NARROWEST)["folded"]
	# every room from the narrowest to the widest, a pixel at a time
	for room: int in range(NARROWEST, WIDEST + 1):
		var folded: Array = first.fold_at(room)["folded"]
		if folded.any(func(named: StringName) -> bool: return not narrower.has(named)):
			grew.append(room)
		if second.fold_at(room) != first.fold_at(room):
			differ.append(room)
		narrower = folded
	_verdict.check(first.fold_at(NARROWEST)["folded"] == [&"house", &"settings", &"chapter", AppBar.SAID] and first.fold_at(WIDEST)["folded"].is_empty(), "the sweep runs from everything folded to nothing: %s, %s" % [first.fold_at(NARROWEST), first.fold_at(WIDEST)])
	_verdict.check(grew.is_empty(), "from %d to %d a pixel at a time, a wider room never folds a part a narrower one kept: %s" % [NARROWEST, WIDEST, grew.slice(0, 5)])
	_verdict.check(differ.is_empty(), "and at every one of those rooms the two bars, saying different things, fold the same parts: %s" % [differ.slice(0, 5)])
	_done()


func _laid_out_the_row_folds_what_it_says_it_folds_on_both_bars_alike() -> void:
	await _started()
	var wrong: Array = []
	# rooms across the sweep, each laid out
	for wide: int in [NARROWEST, 500, 700, 900, 1100, 1400, WIDEST]:
		root.size.x = wide
		await _a_frame_passes()
		var first := _row(&"first bar")
		var second := _row(&"second bar")
		var written: Array = _folded[0].read()
		if written != first.fold_at(first.size.x)["folded"] or _folded[1].read() != written:
			wrong.append("%d: %s, %s, said %s" % [wide, written, _folded[1].read(), first.fold_at(first.size.x)])
	_verdict.check(wrong.is_empty(), "at every room both bars write the same folded names, the ones their row says fold at its width: %s" % [wrong])
	root.size.x = WIDEST
	_done()


func _what_the_screen_says_stands_in_the_bar_while_its_longest_sample_fits_else_heads_the_page() -> void:
	await _started()
	var spill: Control = _made.ui.node_named(&"spill")
	var row := _row(&"first bar")
	_verdict.check(row.get_child(row.get_child_count() - 2).is_visible_in_tree() and not _texts(spill).has(SHORT_SAID), "with room, what the screen says stands in the bar, and the page's head has none of it: %s" % [_texts(spill)])
	var room := float(WIDEST)
	# narrowing a pixel at a time, for the widest room where what the screen says folds
	while not row.fold_at(room)["folded"].has(AppBar.SAID):
		room -= 1.0
	var just_wider: Dictionary = row.fold_at(room + 1.0)
	_verdict.check(just_wider["folded"].is_empty(), "it is the first to fold, a pixel short of the room for its longest sample: %s at %s" % [just_wider, room + 1.0])
	root.size.x = int(room)
	await _a_frame_passes()
	_verdict.check(row.size.x <= room and _texts(spill).has(SHORT_SAID), "given that room, though what it says now is short, it heads the page instead: %s in %s" % [_texts(spill), row.size.x])
	root.size.x = WIDEST
	await _a_frame_passes()
	_verdict.check(not _texts(spill).has(SHORT_SAID), "and given the room again, it leaves the page's head: %s" % [_texts(spill)])
	_done()


func _menu_shows_while_a_press_is_folded_and_opens_a_sheet_of_exactly_the_folded_presses() -> void:
	await _started()
	var row := _row(&"first bar")
	_verdict.check(_shown(AppBar.OPENS_MENU).is_empty(), "with room for every press, no MENU is shown: %s" % _shown(AppBar.OPENS_MENU).size())
	var room := float(WIDEST)
	# narrowing a pixel at a time, for the widest room where settings folds and house does not
	while not row.fold_at(room)["folded"].has(&"settings"):
		room -= 1.0
	_verdict.check(not row.fold_at(room)["folded"].has(&"house"), "settings, ranked below house, folds first: %s" % [row.fold_at(room)])
	root.size.x = int(room)
	await _a_frame_passes()
	var menus: Array = _shown(AppBar.OPENS_MENU).filter(func(press: Node) -> bool: return row.is_ancestor_of(press))
	_verdict.check(menus.size() == 1, "settings folded, the bar shows MENU: %s" % menus.size())
	(menus[0] as Pressable).pressed()
	await _a_frame_passes()
	var listed: Array = _shown(SETTINGS).filter(_in_pop_up)
	var house_listed: Array = _shown(HOUSE).filter(_in_pop_up)
	_verdict.check(_made.driver.is_raised() and listed.size() == 1 and house_listed.is_empty(), "MENU opens a sheet listing settings, folded, and not house, which stands in the bar: settings %s, house %s" % [listed.size(), house_listed.size()])
	var house: Array = _shown(HOUSE).filter(func(press: Node) -> bool: return row.is_ancestor_of(press))
	_verdict.check(house.size() == 1, "house is still shown in the bar: %s" % house.size())
	root.size.x = WIDEST
	_done()
