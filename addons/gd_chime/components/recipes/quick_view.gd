extends RefCounted

const Themes := preload("../../theme.gd")
const Chimes := preload("../../chimes.gd")
const Driver := preload("../../driver.gd")
const Ui := preload("../primitives/ui.gd")
const Options := preload("../primitives/options.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Sheet := preload("sheet.gd")
const Flex := preload("../primitives/flex.gd")

## A quick view: one item of a collection looked at over the collection,
## never leaving it - opened on the item as its place's parameter, stepping
## to the item before and after without closing, and closed by Back to the
## very card it was opened from.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## IT IS A POP-UP over the app: the collection stays where the reader left
## it - its scroll, its pages, its filters - and Back lowers the pop-up, the
## focus going back to the card it was opened from (the chart's opener).
## WHICH ITEM is the parameter the pop-up is entered as - a card carries its
## item's id as the move's parameter, as any card does (card.gd) - so what
## it shows is a function of that parameter, handed in as a bound value
## (describe_places.gd), and a detour and Back find it on the same item.
##
## STEPPING: a press before the content and one after it open the same
## pop-up with the item before or after, as the caller's neighbours(item)
## answers [before, after] - the collection's own order, round from the last
## to the first. A move within the pop-up's layer touches nothing beneath.
## The steps carry which item, so no key is on them (shortcuts.gd): the keys
## and the pad reach them as they reach any press.
##
## THE SHEET stands tall in the middle of the window over the shade
## (sheet.gd), the look's share of the window across and down - "wide" and
## "high" under QuickView - read from the look as it is described.
##
## Deliberately absent: swiping between items.

const SHEET := &"QuickView"
## The steps' presses.
const STEP := &"QuickViewStep"
## The row of the steps and what the sheet holds between them.
const BODY := &"QuickViewBody"
## What a quick view's pop-up is of, in its name.
const KIND := &"quick_view"


## The quick view's pop-up: a step back, what it holds for the item it is
## entered as - a function of that item, a bound value - a step on, each
## step an action of the caller's, declared; in a tall sheet over the shade.
## Its options: on, the place the neighbours are walked in, and
## neighbours, which answers the one before and the one after.
const OPTIONS: Array[String] = ["on", "neighbours"]

static func make(ui: Ui, content: Callable, back: StringName, options: Dictionary = {}) -> Desc:
	Options.checked("a quick view", options, OPTIONS)
	var on: StringName = options["on"]
	var neighbours: Callable = options["neighbours"]
	var steps: Array = []
	var made := ui.pop_up(KIND, func(item: Bound) -> Desc: return _stepped(ui, item, content.call(item), back, on, neighbours, steps))
	# each step a move to this same pop-up, as the item before or after: where it goes, never a pop-up to lift, since this one is standing by then
	for step: Desc in steps:
		step.props["goes_to"] = made.get_place()
	return made


## The steps either side of what the sheet holds, kept in steps for the pop-up to be opened by.
static func _stepped(ui: Ui, item: Bound, content: Array, back: StringName, on: StringName, neighbours: Callable, steps: Array) -> Desc:
	var to := func(side: int) -> Bound: return item.map(func(id: Variant) -> Dictionary: return {} if id == null else {"parameter": neighbours.call(id)[side]})
	var before: Desc = ui.pressable(back, to.call(0), [ui.text("‹", Themes.FACE)], STEP)
	var after: Desc = ui.pressable(on, to.call(1), [ui.text("›", Themes.FACE)], STEP)
	steps.append_array([before, after])
	# the steps stood in the middle of the sheet's height, either side of what it holds
	for step: Desc in steps:
		step.facts["align"] = Flex.CENTER
	var look: Node = ui.root
	return Sheet.tall(ui, [ui.row([before, ui.column(content).grow(), after], BODY).grow()], SHEET, {wide = look.get_theme_constant(&"wide", SHEET) / 1000.0, high = look.get_theme_constant(&"high", SHEET) / 1000.0})
