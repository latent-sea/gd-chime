extends RefCounted

const Driver := preload("../../driver.gd")
const Ui := preload("../primitives/ui.gd")
const Options := preload("../primitives/options.gd")
const Desc := preload("../primitives/desc.gd")
const Transition := preload("../primitives/transition.gd")
const Capped := preload("../primitives/capped.gd")

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
## shown, while the shade only fades with it. What it is put in is a
## pop-up: this is the content alone, never a place. ASKED is the line a
## sheet an application lays out itself stands in, which the look centres
## both ways (theme_overlays.gd).
##
## A moment's shade is ground and never a press (moment.gd): its way out is
## its model's, and a shade going back would lower it only for the moment's
## fact to raise it again.
##
## EVERY SHEET FITS ITSELF TO THE SAFE ROOM (fitted): a head and a foot of
## ways out, pinned, and between them a body that scrolls (page_scroll.gd),
## in the middle of the room as wide as the look's cap - the room less
## Sheet/margin either side, and at most Sheet/most_wide - and as tall as it
## needs up to the room less the margin (capped.gd); where that leaves less
## than the sheet's least, the margin is dropped and it meets the safe rect's
## edges. Its shade is a press of its way out - CLOSES, going back, or the
## model's own action for a pop-up a model presents - and a band
## (shade_band.gd) carries the shade past the safe rect, so the whole window
## is darkened. over() is a fitted sheet of a body alone; tall() is as wide
## as the same cap and as tall as the whole room, for what holds a list
## that scrolls itself and so needs no page.

const SHADE := &"Shade"
const ASKED := &"Asked"
## The look naming a sheet's cap: margin, most_wide and most_tall (capped.gd).
const LOOK := &"Sheet"


## The shade: a press of the pop-up's way out, never focused - CLOSES going
## back, or the model's own action, told to it.
static func shade(ui: Ui, way_out: StringName = Ui.CLOSES) -> Desc:
	var press := ui.pressable(way_out, {}, [], SHADE).no_focus()
	return press.goes_to(Driver.BACK) if way_out == Ui.CLOSES else press


## The shade carried past the pop-up's rect over the rest of the window
## (shade_band.gd): the first thing in a pop-up, under everything else in it.
static func band(ui: Ui) -> Desc:
	return ui.shade_band(SHADE)


## A piece laid in the middle of the room, capped by the look's sheet
## margin and most (capped.gd): across and down, each Capped.NEEDS, SPANS or FILLS.
static func capped(ui: Ui, piece: Desc, across: int, down: int) -> Desc:
	return ui.capped(piece, LOOK, across, down)


## A sheet fitted to the safe room, over the whole window's shade: its
## parts - head, pinned at the top, or none; body, which scrolls; foot, the
## ways out, pinned at the bottom, or none; style, the sheet's own; way_out,
## the pop-up's, CLOSES unless a model presents it; and ground, standing
## in the shade's place where it is not a press - a moment's.
const FITTED_PARTS: Array[String] = ["head", "body", "foot", "style", "way_out", "ground"]

static func fitted(ui: Ui, parts: Dictionary) -> Desc:
	Options.checked("a fitted sheet", parts, FITTED_PARTS)
	var head: Array = [parts["head"]] if parts.has("head") else []
	var foot: Array = [parts["foot"]] if parts.has("foot") else []
	var sheet := ui.surface(parts["style"], [ui.column(head + [ui.page_scroll(parts["body"]).grow()] + foot)])
	var under: Desc = parts["ground"] if parts.has("ground") else shade(ui, parts.get("way_out", Ui.CLOSES))
	return ui.stack([band(ui), under, capped(ui, sheet.arrives(Transition.SCALE), Capped.SPANS, Capped.NEEDS)])


## The press closing the pop-up it stands in, with the register's words for it.
static func close(ui: Ui) -> Desc:
	return ui.button(ui.CLOSES, {goes_to = Driver.BACK})


## A fitted sheet of these lines alone, scrolling where they are more than
## the room, over the shade - or over this ground in its place, a moment's.
static func over(ui: Ui, content: Array, style: StringName, ground: Desc = null) -> Desc:
	var parts := {"body": ui.column(content), "style": style}
	if ground != null:
		parts["ground"] = ground
	return fitted(ui, parts)


## A sheet as wide as a fitted one and as tall as the whole room, however
## little what it holds needs - a table of rows, whose list scrolls itself
## in the room it is given - over the whole window's shade.
static func tall(ui: Ui, content: Array, style: StringName) -> Desc:
	var sheet := ui.surface(style, [ui.column(content)]).arrives(Transition.SCALE)
	return ui.stack([band(ui), shade(ui), capped(ui, sheet, Capped.SPANS, Capped.FILLS)])
