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
## it holds, taking the rest of its height, over a foot kept in view below
## it: a basket's total and its way on. The foot is the caller's, or none.
## HOW WIDE it is is the look's share of the window, one for a window on
## its side and one for a window on its end, where a drawer is most of the
## width; read from the look on the window as it is described.
##
## FROM THE FOOT it is a bottom sheet: edge to edge on a PHONE'S WINDOW
## (shape.gd), and on a desktop's centred at the look's most share of the
## width ("most_wide"), the shade either side; the look's share of its
## height tall ("tall") either way.
## WHOSE WINDOW IT IS IS THE SHAPE'S, NOT A WIDTH MEASURED HERE. The canvas
## is drawn at the base size and stretched, so a phone's window is 1080
## base pixels across - past every look's compact width - and a piece
## measuring itself caps a phone's sheet as if it were a desk's, which is
## what it did: 432 of 720 pixels, centred, where a bottom sheet spans.
##
## Deliberately absent: a drawer dragged shut, and one from the top.

## The sheet, its head, and the press beside it that closes it.
const SHEET := &"Drawer"
const HEAD := &"DrawerHead"
const CLOSE := &"DrawerClose"
## Its column: the head over the body over the foot.
const COLUMN := &"DrawerColumn"
## The line a bottom sheet stands in between the shade's sides, with no gap.
const FOOT := &"DrawerFoot"
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
	var sheet := ui.surface(SHEET, [ui.column([head, content.grow()] + ([foot] if foot != null else []), COLUMN)])
	var look: Node = ui.root
	var wide: float = look.get_theme_constant(&"wide", SHEET) / 1000.0
	var narrow: float = look.get_theme_constant(&"narrow", SHEET) / 1000.0
	var down := from == FROM_BOTTOM
	var order: Array = [&"sheet", &"beside"] if from == FROM_LEFT else [&"beside", &"sheet"]
	# the sheet its share across - or up, from the foot - on a window on its side and on its end, what is beside it taking the rest
	var arranged := func(share: float) -> Dictionary: return (ui.column_of(order, {&"beside": {"grow": 1.0}, &"sheet": {"basis": share, "align": Flex.STRETCH}}, ALONGSIDE) if down else ui.row_of(order, {&"beside": {"grow": 1.0}, &"sheet": {"basis": share, "align": Flex.STRETCH}}, ALONGSIDE))
	var tall: float = look.get_theme_constant(&"tall", SHEET) / 1000.0
	var standing: Desc = sheet.arrives(from) if not down else _capped(ui, sheet.arrives(from), look.get_theme_constant(&"most_wide", SHEET) / 1000.0)
	return ui.by_shape({&"beside": Sheet.shade(ui), &"sheet": standing}, {Shape.LANDSCAPE: arranged.call(tall if down else wide), Shape.PORTRAIT: arranged.call(tall if down else narrow)})


## A bottom sheet across the whole width of a phone's window, and on a
## desktop's centred at the look's most share of it, the shade either side.
## The shade at each side is nothing at all on a phone: it holds no words
## and takes no touch target's least (pressable.gd), so it takes no width,
## and the sheet's own edges are the window's.
static func _capped(ui: Ui, sheet: Desc, most: float) -> Desc:
	var parts := {&"left": Sheet.shade(ui), &"sheet": sheet, &"right": Sheet.shade(ui)}
	var order: Array = [&"left", &"sheet", &"right"]
	var beside := (1.0 - most) / 2.0
	var centred := ui.row_of(order, {&"left": {"basis": beside}, &"sheet": {"basis": most, "align": Flex.STRETCH}, &"right": {"basis": beside}}, FOOT)
	var whole := ui.row_of(order, {&"left": {"basis": 0.0}, &"sheet": {"grow": 1.0, "align": Flex.STRETCH}, &"right": {"basis": 0.0}}, FOOT)
	return ui.by_shape(parts, {Shape.PHONE: whole, Shape.DESKTOP: centred}, ui.shape.whose_window)
