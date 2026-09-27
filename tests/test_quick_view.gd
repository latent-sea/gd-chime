extends SceneTree

## What must be true of a quick view: a card pressed raises it over the
## collection on the card's item, the collection staying where it was; its
## steps go to the item after and before, round the ends, without closing
## it; it stands in a tall sheet at the look's shares; and Back lowers it,
## the focus back on the very card it was opened from.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_quick_view.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const QuickView := preload("res://addons/gd_chime/components/recipes/quick_view.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Verdict := preload("res://tests/verdict.gd")

const OPENS := &"looks_closer"
const BACK := &"steps_back"
const ON := &"steps_on"

const ITEMS := [10, 11, 12]

var _verdict := Verdict.new()
var _closer: StringName  # the quick view's pop-up, named by the builder



func _init() -> void:
	var theme := Themes.new(Themes.NEUTRAL)
	theme.set_constant(&"wide", QuickView.SHEET, 800)
	theme.set_constant(&"high", QuickView.SHEET, 600)
	root.theme = theme
	await process_frame
	root.size = Vector2i(1000, 800)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_a_card_pressed_raises_it_on_the_cards_item_over_the_collection)
	await _verdict.states(_its_steps_go_round_the_items_without_closing_it)
	await _verdict.states(_back_lowers_it_the_focus_back_on_the_card)
	quit(_verdict.deliver(get_script()))


## Three cards opening a quick view that says its item: the fixture, started.
func _shop() -> Fixture:
	var made := Fixture.new(root, {OPENS: "look closer", BACK: "the one before", ON: "the one after"})
	var ui := made.ui
	var beside := func(id: int) -> Array: return [ITEMS[(ITEMS.find(id) + ITEMS.size() - 1) % ITEMS.size()], ITEMS[(ITEMS.find(id) + 1) % ITEMS.size()]]
	# what it holds says which item it was opened as, read from the parameter it is handed
	var says := func(item: Bound) -> Array: return [ui.text(item.map(func(id: Variant) -> String: return "" if id == null else "item %d" % id)).named(&"says")]
	var closer := QuickView.make(ui, says, BACK, {on = ON, neighbours = beside})
	_closer = closer.get_place()
	var cards: Array = ITEMS.map(func(id: int) -> Desc: return ui.pressable(OPENS, {"parameter": id}, [ui.text("card %d" % id)], Themes.PRESSABLE).opens(closer).named(StringName("card_%d" % id)))
	ui.start(ui.app(&"app", [ui.screen(&"shelf", [ui.column(cards)])]))
	return made


func _frames() -> void:
	# a few frames, for a move to be carried out and laid out
	for frame: int in 3:
		await process_frame


func _says(made: Fixture) -> String:
	return (made.ui.node_named(&"says") as Text).get_text()


func _step(way: StringName) -> Pressable:
	return root.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable and part.is_visible_in_tree() and part.action == way)[0]


func _a_card_pressed_raises_it_on_the_cards_item_over_the_collection() -> void:
	var made := _shop()
	await _frames()
	var card: Pressable = made.ui.node_named(&"card_11")
	card.pressed()
	await _frames()
	_verdict.check(made.driver.get_top().has(_closer) and _says(made) == "item 11" and card.is_visible_in_tree(), "pressed, the quick view stands over the collection on the card's item, the collection still there: %s" % _says(made))
	var sheet: Control = made.ui.node_named(&"says").get_parent()
	# up to the sheet itself, the surface holding what it says
	while sheet.theme_type_variation != QuickView.SHEET:
		sheet = sheet.get_parent()
	_verdict.check(is_equal_approx(sheet.size.x, 800.0) and is_equal_approx(sheet.size.y, 480.0), "in a tall sheet at the look's shares of the window: %s" % sheet.size)
	var step := _step(ON).get_global_rect()
	_verdict.check(absf(step.get_center().y - sheet.get_global_rect().get_center().y) < 2.0, "what it holds takes the sheet's height, the steps stood half way down it: %s in %s" % [step, sheet.get_global_rect()])
	made.done()


func _its_steps_go_round_the_items_without_closing_it() -> void:
	var made := _shop()
	await _frames()
	(made.ui.node_named(&"card_12") as Pressable).pressed()
	await _frames()
	_step(ON).pressed()
	await _frames()
	var after := _says(made)
	_step(BACK).pressed()
	await _frames()
	_step(BACK).pressed()
	await _frames()
	_verdict.check(after == "item 10" and _says(made) == "item 11" and made.driver.get_top().has(_closer), "on from the last is the first, and back twice from there the one before the last, never closing: %s %s" % [after, _says(made)])
	made.done()


func _back_lowers_it_the_focus_back_on_the_card() -> void:
	var made := _shop()
	await _frames()
	var card: Pressable = made.ui.node_named(&"card_10")
	card.grab_focus()
	card.pressed()
	await _frames()
	_step(ON).pressed()
	await _frames()
	made.commands.dispatch(Chimes.GLOBAL, Driver.GOES_BACK, {})
	await _frames()
	_verdict.check(not made.driver.get_top().has(_closer) and root.gui_get_focus_owner() == card, "Back lowers it, however far it stepped, the focus back on the card it was opened from")
	made.done()
