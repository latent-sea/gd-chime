extends RefCounted

const Themes := preload("../../theme.gd")
const Navigation := preload("../../theme_navigation.gd")
const Actions := preload("../../actions.gd")
const Ui := preload("../primitives/ui.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Local := preload("../primitives/local.gd")
const Options := preload("../primitives/options.gd")
const PriorityRow := preload("../primitives/priority_row.gd")
const Sheet := preload("sheet.gd")
const Setting := preload("setting.gd")

## An application's bar: one held line across the top of every screen, the
## same parts in rank order on each, one height whatever it shows - and
## where the room runs short, the presses that do not fit behind MENU, and
## what the screen says at the head of its page.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## ITS PARTS ARE A PRIORITY ROW'S (priority_row.gd), each {name, part,
## short, folds, line}: the part, its short form where it has one, where it
## folds - KEEP, MENU, PAGE or GONE - and the line it becomes in the menu
## or at the head of the page, the part described again where none is
## given. A figure that changes - a clock, a balance, a score - is given in
## a slot of its widest samples (room_for.gd), so what folds at one room is
## decided from samples and never from what shows now: the same parts fold
## on every screen.
##
## WHAT THE SCREEN SAYS - its title, or what it asks of the reader - stands
## last in rank, in a slot of its longest sample in its kind, the Title
## kind where none is given: it stays in the bar while that sample fits
## after the parts before it, and otherwise heads the page, wrapped, through
## the spill, which each screen puts first on its page (page.gd) - or, where
## it is told to fold GONE, a hint the reader can do without, is not shown.
## What folds to the page stands along one line in rank order while it fits
## there, and wraps onto the next where it does not, so two short lines
## never take the height of two; while nothing folds there the spill is
## hidden, and takes no gap at the head of the page.
##
## ITS HEIGHT IS HELD: the tallest form of every part, shown or not, and
## the said slot's Title line - each measured from what the part can be,
## never what it shows - with the bar's own pad, and a press is never less
## than the look's touch least (pressable.gd). So nothing it shows, and
## nothing that folds, moves the screens under it.
##
## MENU is KEEP, and shows while any MENU part is folded: it opens a fitted
## sheet (sheet.gd) listing the folded parts' lines in rank order, scrolling
## where they are more than the room, over its way out, pinned.
## Its words are declared once, by whoever composes the application
## (declare). The bar is worked out again only as its room, its look or its
## language changes. Which parts are folded is a local the caller hands in,
## so the spill and the menu read the same names the row writes.

## The press opening the menu of the presses that do not fit.
const OPENS_MENU := &"opens_the_menu"
## The name of what the screen says, among the folded names.
const SAID := &"said"
## What the menu's pop-up is of, in its name.
const MENU_KIND := &"app_bar_menu"
## The bar's ground, and the line its parts stand on (theme_navigation.gd).
const BAR := Navigation.APP_BAR
const BAR_ROW := Navigation.APP_BAR_ROW

## The bar's options, the first four required: parts, in rank order; said,
## what the screen says, words or a bound value reading them; said_samples,
## the longest it may say; folded, the local the folded names are written
## to; style, the bar's ground; said_style, the kind what the screen says is
## written in, Title where none is given; and said_folds, where it goes
## where it does not fit, PAGE where none is given.
const OPTIONS: Array[String] = ["parts", "said", "said_samples", "folded", Options.STYLE, "said_style", "said_folds"]


## The menu press's words, declared once in the register.
static func declare(register: Actions) -> void:
	register.declare_all({OPENS_MENU: ["Menu"]})


## The bar, and the spill for the head of each page: {bar, spill}.
static func make(ui: Ui, options: Dictionary) -> Dictionary:
	Options.checked("an app bar", options, OPTIONS)
	var folded: Local = options["folded"]
	var kind: StringName = options.get("said_style", Themes.TITLE)
	var said := {"name": SAID, "part": ui.room_for(ui.text(options["said"], kind), options["said_samples"], kind).grow(), "folds": options.get("said_folds", PriorityRow.PAGE), "line": ui.text(options["said"], kind).wraps()}
	var parts: Array = options["parts"] + [said]
	var menu_lines: Array = []
	var page_lines: Array = []
	var paged: Array = parts.filter(func(part: Dictionary) -> bool: return part["folds"] == PriorityRow.PAGE).map(func(part: Dictionary) -> StringName: return part["name"])
	# every part in rank order: the line it becomes where it is folded, in the menu or at the head of the page
	for part: Dictionary in parts:
		var while_folded := ui.when(folded.map(func(names: Array) -> bool: return names.has(part["name"])), part.get("line", part["part"]))
		if part["folds"] == PriorityRow.MENU:
			menu_lines.append(while_folded)
		if part["folds"] == PriorityRow.PAGE:
			page_lines.append(while_folded)
	var menu := ui.pop_up(MENU_KIND, func(_which: Bound) -> Desc: return Sheet.fitted(ui, {body = ui.column(menu_lines), foot = Sheet.close(ui), style = Setting.SHEET}))
	var row := ui.priority_row(parts, folded, ui.button(OPENS_MENU, {opens = menu}), BAR_ROW)
	var any_paged: Bound = folded.map(func(names: Array) -> bool: return names.any(func(named: StringName) -> bool: return paged.has(named)))
	return {"bar": ui.surface(options.get(Options.STYLE, BAR), [row]), "spill": ui.when(any_paged, ui.row(page_lines, Themes.TILES))}
