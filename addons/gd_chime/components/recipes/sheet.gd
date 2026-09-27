extends RefCounted

const Driver := preload("../../driver.gd")
const Ui := preload("../primitives/ui.gd")
const Options := preload("../primitives/options.gd")
const Desc := preload("../primitives/desc.gd")
const Transition := preload("../primitives/transition.gd")
const Flex := preload("../primitives/flex.gd")

## A sheet over everything: a shade across the whole of what is beneath,
## and one sheet of content in the middle of it - the one overlay contract.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The one shape every thing that stands over the screen has - a confirm's
## question, a choice's options, a palette, a quick view, a drawer, a moment
## - so they are laid out alike, closed alike and a look dresses them once.
## THE SHADE IS A PRESS of the pop-up's way out (describe_places.gd:
## CLOSES), going back: pressed anywhere beside the sheet, the pop-up
## closes. It never takes the focus - the keys and the pad have the close
## press and Back - and it is the style Shade, the same in every state, the
## ground everything on it stands on (drawn_over.gd). The sheet is the
## caller's own style and scales in each time the place it stands in is
## shown, while the shade only fades with it; the line that holds the sheet
## is ASKED, for a look to centre and pad as it likes. What it is put in is
## a pop-up: this is the content alone, never a place.
##
## A moment's shade is ground and never a press (moment.gd): its way out is
## its model's, and a shade going back would lower it only for the moment's
## fact to raise it again.

const SHADE := &"Shade"
const ASKED := &"Asked"
## How much of the width the sheet takes.
const SHARE := 0.6


## The shade: a press going back by the pop-up's way out, never focused.
static func shade(ui: Ui) -> Desc:
	return ui.pressable(ui.CLOSES, {}, [], SHADE).goes_to(Driver.BACK).no_focus()


## The press closing the pop-up it stands in, with the register's words for it.
static func close(ui: Ui) -> Desc:
	return ui.button(ui.CLOSES, {goes_to = Driver.BACK})


## The sheet in the middle of the width, as tall as what it holds, over the
## shade - or over this ground in its place, a moment's.
static func over(ui: Ui, content: Array, style: StringName, ground: Desc = null) -> Desc:
	var sheet := ui.surface(style, [ui.column(content)])
	return ui.stack([shade(ui) if ground == null else ground, ui.row([sheet.basis(SHARE).arrives(Transition.SCALE)], ASKED)])


## A sheet as wide and as tall as these shares of the window, however
## little what it holds needs - a table of rows, whose list takes the room
## it is given - with the same room above it as below.
## Its options: wide and high, the shares of the window it takes.
const TALL_OPTIONS: Array[String] = ["wide", "high"]

static func tall(ui: Ui, content: Array, style: StringName, options: Dictionary = {}) -> Desc:
	Options.checked("a tall sheet", options, TALL_OPTIONS)
	var wide: float = options["wide"]
	var high: float = options["high"]
	var sheet: Desc = ui.surface(style, [ui.column(content)]).basis(wide).arrives(Transition.SCALE)
	# the sheet as tall as the line it stands in, rather than as tall as what it holds
	sheet.facts["align"] = Flex.STRETCH
	return ui.stack([shade(ui), ui.column([ui.column([]).grow(), ui.row([sheet], ASKED).basis(high), ui.column([]).grow()])])
