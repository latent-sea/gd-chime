extends SceneTree

## What must be true of a pop-up described inside a themed subtree: opened,
## it wears that subtree's look - a colour and a constant only that look has
## - and sizes by that look's shares of the window, a drawer across and a
## long combo's sheet up; the same pop-up described outside the subtree
## wears the app's look and sizes by the app's shares; and one inside a
## themed subtree inside another wears the inner one. The look reaches it
## whether the subtree is inside the place the pop-up is described in or
## holds that place - a place shown by a when too, first or later.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_themed_pop_ups.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Surface := preload("res://addons/gd_chime/components/primitives/surface.gd")
const Drawer := preload("res://addons/gd_chime/components/recipes/drawer.gd")
const Combo := preload("res://addons/gd_chime/components/recipes/combo.gd")
const Setting := preload("res://addons/gd_chime/components/recipes/setting.gd")
const Narrowing := preload("res://addons/gd_chime/narrowing.gd")
const Fields := preload("res://addons/gd_chime/theme_fields.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Verdict := preload("res://tests/verdict.gd")

const WINDOW := Vector2i(1000, 800)
const FRUIT := ["pear", "apple", "fig", "date", "plum", "lime", "kiwi", "yuzu", "grape", "melon"]

var _verdict := Verdict.new()
## The app's look: the drawer's share across and the combo's share up that every other look here differs from.
var _app: Theme
## A look of a subtree's own: its words' colour and line spacing, and its shares, none of them the app's.
var _other: Theme
## Two more, one worn inside the other.
var _outer: Theme
var _inner: Theme


func _init() -> void:
	_app = _look(Color.WHITE, 0, 300, 600)
	_other = _look(Color(0.9, 0.1, 0.8), 13, 500, 900)
	_outer = _look(Color(0.9, 0.8, 0.1), 21, 700, 700)
	_inner = _look(Color(0.1, 0.8, 0.9), 17, 400, 800)
	root.theme = _app
	await process_frame
	root.size = WINDOW
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_a_drawer_inside_a_themed_piece_wears_its_look_and_shares_and_one_outside_the_app_s)
	await _verdict.states(_a_long_combo_inside_a_themed_piece_holding_its_screen_wears_its_look_and_share_and_one_outside_the_app_s)
	await _verdict.states(_a_drawer_inside_a_themed_piece_inside_another_wears_the_inner_look)
	await _verdict.states(_a_place_inside_a_when_inside_a_themed_piece_lifts_its_pop_ups_in_that_look)
	root.theme = null
	quit(_verdict.deliver(get_script()))


## A look whose words are this colour, this far apart, whose drawer takes this share across and whose long combo this share up, in thousandths.
func _look(words: Color, spacing: int, across: int, up: int) -> Theme:
	var look := Themes.new(Themes.NEUTRAL)
	look.set_color(&"font_color", Themes.FACE, words)
	look.set_constant(&"line_spacing", Themes.FACE, spacing)
	look.set_constant(&"wide", Drawer.SHEET, across)
	look.set_constant(&"narrow", Drawer.SHEET, across)
	look.set_constant(Fields.TALL, Fields.COMBO, up)
	return look


func _frames(count: int) -> void:
	# so many frames, for a move to be carried out and laid out
	for frame: int in count:
		await process_frame


## A drawer holding words named by this name, over the sheet they stand in.
func _drawer(ui: Object, named: StringName) -> Desc:
	return Drawer.over(ui, "basket", func(_which: Bound) -> Desc: return ui.column([ui.text("a sofa", Themes.FACE).named(named)]))


## The Label a text draws its words in, which is what reads the look.
func _words_of(text: Node) -> Label:
	return text.find_children("*", "Label", true, false)[0]


## Whether these words wear this look: its colour and its line spacing.
func _wears(words: Label, look: Theme) -> bool:
	return words.get_theme_color(&"font_color") == look.get_color(&"font_color", Themes.FACE) and words.get_theme_constant(&"line_spacing") == look.get_constant(&"line_spacing", Themes.FACE)


## The drawer's sheet: what its words stand in, the column, and the surface holding that.
func _sheet_of(words: Node) -> Control:
	return words.get_parent().get_parent().get_parent()


## The press opening a pop-up pressed, and the move carried out.
func _open(ui: Object, opener: StringName) -> void:
	(ui.node_named(opener) as Pressable).pressed()
	await _frames(3)


func _a_drawer_inside_a_themed_piece_wears_its_look_and_shares_and_one_outside_the_app_s() -> void:
	var made := Fixture.new(root, {&"opens_in": "open inside", &"opens_out": "open outside"})
	var ui := made.ui
	var inside: Desc = ui.pressable(&"opens_in", {}, [ui.text("inside")], Themes.PRESSABLE).opens(_drawer(ui, &"in_words")).named(&"in")
	var outside: Desc = ui.pressable(&"opens_out", {}, [ui.text("outside")], Themes.PRESSABLE).opens(_drawer(ui, &"out_words")).named(&"out")
	ui.start(ui.app(&"app", [ui.screen(&"shelf", [ui.column([ui.themed(_other, [inside]), outside])])]))
	await _frames(3)
	await _open(ui, &"in")
	var words := _words_of(ui.node_named(&"in_words"))
	var sheet := _sheet_of(ui.node_named(&"in_words"))
	_verdict.check(words.is_visible_in_tree() and _wears(words, _other), "a drawer described inside a themed piece wears its look, opened: %s %d" % [words.get_theme_color(&"font_color"), words.get_theme_constant(&"line_spacing")])
	_verdict.check(is_equal_approx(sheet.size.x, WINDOW.x * 0.5), "and takes that look's share of the window across, not the app's: %s" % [sheet.size])
	made.commands.dispatch(Chimes.GLOBAL, Driver.GOES_BACK, {})
	await _frames(3)
	await _open(ui, &"out")
	words = _words_of(ui.node_named(&"out_words"))
	sheet = _sheet_of(ui.node_named(&"out_words"))
	_verdict.check(words.is_visible_in_tree() and _wears(words, _app) and is_equal_approx(sheet.size.x, WINDOW.x * 0.3), "the same drawer described beside the themed piece wears the app's look and takes the app's share across: %s %d %s" % [words.get_theme_color(&"font_color"), words.get_theme_constant(&"line_spacing"), sheet.size])
	made.done()


## A long combo's overlay: its sheet, standing in the pop-up the combo's press opens.
func _combo_sheet(ui: Object, combo: StringName) -> Control:
	var overlay: Node = ui.node_named(combo)
	return overlay.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Surface and (part as Surface).get_style() == Setting.SHEET)[0]


func _a_long_combo_inside_a_themed_piece_holding_its_screen_wears_its_look_and_share_and_one_outside_the_app_s() -> void:
	var made := Fixture.new(root, {&"picks": "pick", &"opens_in": "open inside", &"opens_out": "open outside", &"types": "type"})
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes, &"app")
	model.set_value(&"items", FRUIT.map(func(word: String) -> Dictionary: return {"value": word.to_upper(), "words": word}))
	model.set_value(&"words", "pear")
	var narrowings: Array = []
	var combos: Array = []
	# a combo inside the themed piece and one beside it, each over a narrowing of its own and answered in its own overlay
	for side: String in ["in", "out"]:
		var narrowing := Narrowing.new(made.chimes, model.of(&"items"), 4)
		var combo := Combo.long(ui, &"picks", StringName("opens_" + side), model.of(&"words"), {narrowing = narrowing, types = &"types", title = Phrase.of("which fruit?")})
		var chooser: StringName = (combo.props["overlay"] as Desc).named(StringName(side + "_overlay")).get_place()
		made.commands.register(chooser, &"types", narrowing)
		made.commands.register(chooser, &"picks", model)
		narrowings.append(narrowing)
		combos.append(combo.named(StringName(side)))
	ui.start(ui.app(&"app", [ui.column([ui.themed(_other, [ui.screen(&"shelf", [combos[0]])]), combos[1]])]))
	await _frames(3)
	await _open(ui, &"in")
	var sheet := _combo_sheet(ui, &"in_overlay")
	var title := _words_of(sheet)
	_verdict.check(title.is_visible_in_tree() and _wears(title, _other), "a long combo whose screen stands inside a themed piece wears its look, opened: %s %d" % [title.get_theme_color(&"font_color"), title.get_theme_constant(&"line_spacing")])
	_verdict.check(is_equal_approx(sheet.size.y, WINDOW.y * 0.9), "and its sheet is that look's share of the window tall, not the app's: %s" % [sheet.size])
	made.commands.dispatch(Chimes.GLOBAL, Driver.GOES_BACK, {})
	await _frames(3)
	await _open(ui, &"out")
	sheet = _combo_sheet(ui, &"out_overlay")
	title = _words_of(sheet)
	_verdict.check(title.is_visible_in_tree() and _wears(title, _app) and is_equal_approx(sheet.size.y, WINDOW.y * 0.6), "the same combo described beside the themed piece wears the app's look and is the app's share tall: %s %d %s" % [title.get_theme_color(&"font_color"), title.get_theme_constant(&"line_spacing"), sheet.size])
	for narrowing: Node in narrowings:
		narrowing.free()
	model.free()
	made.done()


func _a_drawer_inside_a_themed_piece_inside_another_wears_the_inner_look() -> void:
	var made := Fixture.new(root, {&"opens_in": "open inside"})
	var ui := made.ui
	var opener: Desc = ui.pressable(&"opens_in", {}, [ui.text("inside")], Themes.PRESSABLE).opens(_drawer(ui, &"in_words")).named(&"in")
	ui.start(ui.app(&"app", [ui.screen(&"shelf", [ui.themed(_outer, [ui.themed(_inner, [opener])])])]))
	await _frames(3)
	await _open(ui, &"in")
	var words := _words_of(ui.node_named(&"in_words"))
	var sheet := _sheet_of(ui.node_named(&"in_words"))
	_verdict.check(words.is_visible_in_tree() and _wears(words, _inner) and is_equal_approx(sheet.size.x, WINDOW.x * 0.4), "a drawer inside a themed piece inside another wears the inner look and takes its share across: %s %d %s" % [words.get_theme_color(&"font_color"), words.get_theme_constant(&"line_spacing"), sheet.size])
	made.done()


## A when builds the side it first shows as it is made, before it stands in
## anything, and the other side later, standing: a place on either side,
## built inside a themed piece, lifts its pop-ups in that piece's look.
func _a_place_inside_a_when_inside_a_themed_piece_lifts_its_pop_ups_in_that_look() -> void:
	var made := Fixture.new(root, {&"opens_in": "open inside"})
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes, &"app")
	model.set_value(&"flag", false)
	var first: Desc = ui.pressable(&"opens_in", {}, [ui.text("inside")], Themes.PRESSABLE).opens(_drawer(ui, &"in_words")).named(&"in")
	var later: Desc = ui.pressable(&"opens_in", {}, [ui.text("later")], Themes.PRESSABLE).opens(_drawer(ui, &"later_words")).named(&"later")
	var stall := ui.when(Bound.constant(true), ui.screen(&"stall", [first]))
	var cart := ui.when(model.of(&"flag"), ui.screen(&"cart", [later]))
	ui.start(ui.app(&"app", [ui.screen(&"shelf", [ui.themed(_other, [ui.column([stall, cart])])])]))
	await _frames(3)
	await _open(ui, &"in")
	var words := _words_of(ui.node_named(&"in_words"))
	var sheet := _sheet_of(ui.node_named(&"in_words"))
	_verdict.check(words.is_visible_in_tree() and _wears(words, _other) and is_equal_approx(sheet.size.x, WINDOW.x * 0.5), "a place a when shows first, inside a themed piece, lifts its drawer in that look and share: %s %d %s" % [words.get_theme_color(&"font_color"), words.get_theme_constant(&"line_spacing"), sheet.size])
	made.commands.dispatch(Chimes.GLOBAL, Driver.GOES_BACK, {})
	model.set_value(&"flag", true)
	await _frames(3)
	made.commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": &"cart"})
	await _frames(3)
	await _open(ui, &"later")
	words = _words_of(ui.node_named(&"later_words"))
	sheet = _sheet_of(ui.node_named(&"later_words"))
	_verdict.check(words.is_visible_in_tree() and _wears(words, _other) and is_equal_approx(sheet.size.x, WINDOW.x * 0.5), "and a place it shows later lifts its drawer in that look and share too: %s %d %s" % [words.get_theme_color(&"font_color"), words.get_theme_constant(&"line_spacing"), sheet.size])
	model.free()
	made.done()
