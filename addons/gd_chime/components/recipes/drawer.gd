extends RefCounted

const Themes := preload("../../theme.gd")
const Driver := preload("../../driver.gd")
const Ui := preload("../primitives/ui.gd")
const Options := preload("../primitives/options.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Transition := preload("../primitives/transition.gd")
const Flex := preload("../primitives/flex.gd")
const Shape := preload("../../shape.gd")
const Capped := preload("../primitives/capped.gd")
const Sheet := preload("sheet.gd")

## A drawer: a side sheet sliding in from an edge over the shade, holding
## what belongs beside the screen rather than on it - a basket, the filters
## of a narrow window, the actions of the stop open - and closed by pressing
## the shade, by its own close press, or by Back.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## IT IS A POP-UP, described where it is used and lifted beside the app by
## the builder (ui.gd), opened by a press as one of its kind: its title and
## what it holds are functions of which one it is entered as, a bound value
## (describe_places.gd), so a stop's actions read the stop they were opened
## for. The chart says whether it is up, Back lowers it, the focus goes into
## it as it opens and back to its opener as it closes, and nothing beneath
## is reached while it stands. The pop-up fades in by the look's transition
## for an overlay; the SHEET arrives its own way each time, SLIDING FROM ITS
## EDGE (Desc.arrives), so only it moves and the shade only fades.
##
## IT STANDS ON THE SHEET'S SHADE (sheet.gd): every thing standing over the
## screen has the one shade, a press of the pop-up's way out going back,
## laid beside the sheet here rather than under it, and the one close press.
##
## THE SHEET is a head - its title and a press that closes it - over what
## it holds, which scrolls (page_scroll.gd) in the rest of its height, over
## a foot kept in view below it: a basket's total and its way on. The foot
## is the caller's, or none. HOW WIDE it is is the look's share of the
## window, one for a window on its side and one for a window on its end,
## where a drawer is most of the width; read from the look its pop-up wears
## - a themed piece's it was described inside, or the app's - as its content
## is made (describe_places.gd).
##
## FROM THE FOOT it is a bottom sheet, the look's share of the height tall
## ("tall"), against the foot, and across capped as a fitted sheet is
## (sheet.gd, capped.gd): the room less Sheet/margin either side, at most
## Sheet/most_wide, in the middle, the shade either side of it. It meets the
## window's edges only where that cap leaves less than its least - the room
## decides, never whose window it is.
##
## THE WHOLE WINDOW IS SHADED: under the drawer, a band (sheet.gd: band)
## carries the shade past the safe rect the pop-up stands in.
##
## Deliberately absent: a drawer dragged shut, and one from the top.

## The sheet, its head, and the press beside it that closes it.
const SHEET := &"Drawer"
const HEAD := &"DrawerHead"
const CLOSE := &"DrawerClose"
## Its column: the head over the body over the foot.
const COLUMN := &"DrawerColumn"
## The line the sheet and the shade stand in, with no gap between them.
const ALONGSIDE := &"DrawerLine"
## The edges it may come from: a side, or the foot - a bottom sheet.
const FROM_LEFT := Transition.FROM_LEFT
const FROM_RIGHT := Transition.FROM_RIGHT
const FROM_BOTTOM := Transition.FROM_BOTTOM
## What a drawer's pop-up is of, in its name.
const KIND := &"drawer"


## The drawer from this edge: its title - a phrase, or a function of which
## one it is entered as answering one - what it holds for that one, and the
## foot kept below it or null.
## Its options: foot, what stands along its bottom, and from, the side it
## comes in from.
const OPTIONS: Array[String] = ["foot", "from"]

static func over(ui: Ui, title: Variant, content: Callable, options: Dictionary = {}) -> Desc:
	Options.checked("a drawer", options, OPTIONS)
	var foot: Variant = options.get("foot")
	var from: StringName = options.get("from", FROM_RIGHT)
	return ui.pop_up(KIND, func(parameter: Bound) -> Desc: return _drawn(ui, title.call(parameter) if title is Callable else title, content.call(parameter), foot, from))


## The sheet and the shade beside it, arranged by the window's shape.
static func _drawn(ui: Ui, title: Variant, content: Desc, foot: Desc, from: StringName) -> Desc:
	var head := ui.row([ui.text(title, Themes.WORDS).grow(), ui.pressable(ui.CLOSES, {}, [ui.text("✕", Themes.FACE)], CLOSE).goes_to(Driver.BACK)], HEAD)
	var sheet := ui.surface(SHEET, [ui.column([head, ui.page_scroll(content).grow()] + ([foot] if foot != null else []), COLUMN)])
	var look: Node = ui.current_place()
	var wide: float = look.get_theme_constant(&"wide", SHEET) / 1000.0
	var narrow: float = look.get_theme_constant(&"narrow", SHEET) / 1000.0
	var down := from == FROM_BOTTOM
	var order: Array = [&"sheet", &"beside"] if from == FROM_LEFT else [&"beside", &"sheet"]
	# the sheet its share across - or up, from the foot - on a window on its side and on its end, what is beside it taking the rest
	var arranged := func(share: float) -> Dictionary: return (ui.column_of(order, {&"beside": {"grow": 1.0}, &"sheet": {"basis": share, "align": Flex.STRETCH}}, ALONGSIDE) if down else ui.row_of(order, {&"beside": {"grow": 1.0}, &"sheet": {"basis": share, "align": Flex.STRETCH}}, ALONGSIDE))
	var tall: float = look.get_theme_constant(&"tall", SHEET) / 1000.0
	# from the foot, the sheet capped across over the shade, which shows either side of it
	var standing: Desc = sheet.arrives(from) if not down else ui.stack([Sheet.shade(ui), Sheet.capped(ui, sheet.arrives(from), Capped.SPANS, Capped.FILLS)])
	return ui.stack([Sheet.band(ui), ui.by_shape({&"beside": Sheet.shade(ui), &"sheet": standing}, {Shape.LANDSCAPE: arranged.call(tall if down else wide), Shape.PORTRAIT: arranged.call(tall if down else narrow)})])

