extends RefCounted

const Themes := preload("../../theme.gd")
const Ui := preload("../primitives/ui.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const OpenMenu := preload("../../open_menu.gd")
const Setting := preload("setting.gd")

## A context menu: the pop-up a target opens (menu_target.gd), set down
## beside what it was opened over, one item per action it offers - its
## words, the key it is on, and why it cannot be used, if it cannot.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE APPLICATION'S ONE MENU: described once - as the pointer is one - it is
## said to the builder as it is described (describe_shell.gd: context_menu),
## so every menu target, a recipe's row among them, opens it without being
## handed it, and the builder lifts it beside the app.
##
## WHICH ITEMS AND WHAT A PICK DOES ARE THE MENU'S (open_menu.gd): the menu
## opened now is the pop-up's parameter, handed in as a bound value, and each
## item is the press it stands for, refused as that press would be. This
## describes the pop-up: the menu set down beside the rect it was opened
## over (anchored_at.gd) - a press past it the pop-up's way out, going back
## - and a pressable per item picking it, carrying the item.
##
## IT STANDS ON THE SHEET'S SURFACE, the one a choice's options stand on
## (setting.gd), with no shade: it is set down beside its target, not over
## the whole window. IT IS WALKED WITHOUT A POINTER: the first item takes the
## focus as it opens, the arrows and the pad move through the items, accept
## picks one, and the way out every pop-up has closes it. Each item wears
## MenuItem.

const ITEM := &"MenuItem"
## What the context menu's pop-up is of, in its name.
const KIND := &"context_menu"


## The application's context menu, its model answering its picks; said to the builder.
static func make(ui: Ui, menu: OpenMenu) -> Desc:
	ui.context_menu = ui.pop_up(KIND, func(up: Bound) -> Desc: return _set_down(ui, menu, up), menu)
	ui.menu_place = ui.context_menu.get_place()
	return ui.context_menu


## The menu opened as this parameter, beside where it was opened.
static func _set_down(ui: Ui, menu: OpenMenu, up: Bound) -> Desc:
	var items := ui.each(up.map(menu.items_of), func(item: Bound) -> Desc: return _item(ui, item), func(item: Dictionary) -> Variant: return item["value"])
	var at: Bound = up.map(func(opened: Variant) -> Rect2: return Rect2() if opened == null else opened["at"])
	return ui.anchored_at(at, ui.CLOSES, [ui.surface(Setting.SHEET, [items])])


## One item: the action's words and the key it is on, over why it cannot be
## picked, if it cannot - pressed, it is picked.
static func _item(ui: Ui, item: Bound) -> Desc:
	# the item itself carried, or none for one on its way out, which the menu refuses
	var carried: Bound = item.map(func(one: Variant) -> Dictionary: return {"item": one})
	# the key the action is on, read again as keys are bound and devices change
	var hint := Bound.new(func() -> Variant: var one: Variant = item.read(); return null if one == null else ui.inputs.get_hint(one["action"]))
	var said := ui.row([ui.text(item.field("words"), Themes.FACE).grow(), ui.text(hint, Themes.REASON).hides_empty()])
	return ui.pressable(OpenMenu.PICKS, carried, [ui.column([said, ui.reason(Themes.REASON)])], ITEM)
