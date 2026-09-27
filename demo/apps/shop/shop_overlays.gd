extends RefCounted

const GdChime := preload("res://addons/gd_chime/gd_chime.gd")
const Basket := preload("res://demo/apps/shop/basket.gd")

## What stands over the shop: the quick view of a piece, the basket and
## the filters - each a pop-up the builder lifts over the app, each a
## floor recipe, and the shop's press opening it the way to it.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE QUICK VIEW (quick_view.gd) is a piece's gallery beside what it is,
## what it costs and a press putting it in the basket, stepping through the
## pieces in the order the collection shows them. THE BASKET is a drawer
## from the right (drawer.gd): a line a piece, one more or one fewer, and
## the total over the way to check out - raised by every press that adds a
## piece, so the drawer slides in as the piece goes in. THE FILTERS are a
## drawer from the left holding the facets, the way a window on its end
## reaches them.
##
## Deliberately absent: a basket line's quantity typed in.

## The sizes the quick view's large picture and its thumbnails may be asked for, in pixels square.
const LARGE := [480, 960, 1440]
const SMALL := [96, 192]


## The quick view: the piece's gallery beside its words, side by side on a wide window and one over the other on one on its end.
static func quick_view(ui: GdChime.Ui, app: Object) -> GdChime.Desc:
	return GdChime.QuickView.make(ui, func(item: GdChime.Bound) -> Array: return [_closer(ui, app, item)], app.SHOWS_ONE_BEFORE, {on = app.SHOWS_ONE_AFTER, neighbours = app.neighbours})


## The piece the quick view is opened as, looked at closer.
static func _closer(ui: GdChime.Ui, app: Object, item: GdChime.Bound) -> GdChime.Desc:
	var piece: GdChime.Bound = item.map(func(id: Variant) -> Variant: return null if id == null else app.rows.row_at(id))
	var shots: GdChime.Bound = item.map(func(id: Variant) -> Variant: return null if id == null else range(4).map(func(shot: int) -> Vector2i: return Vector2i(id, shot)))
	var said := func(key: StringName) -> GdChime.Bound: return piece.map(func(one: Variant) -> String: return "" if one == null else str(one[key]))
	var about := piece.map(func(one: Variant) -> Variant: return "" if one == null else GdChime.Phrase.with("In %s %s, for the %s; rated %s of 5", [one["colour"], one["material"], one["room"], one["rating"]]))
	var adds := ui.pressable(Basket.ADDS, item.map(func(id: Variant) -> Dictionary: return {} if id == null else {"id": id}), [ui.text(ui.words(Basket.ADDS), GdChime.Themes.FACE), ui.reason(GdChime.Themes.REASON)], GdChime.Pressables.BUTTON).opens(app.basket_drawer)
	var words := ui.column([ui.text(said.call(&"name"), GdChime.Themes.WORDS).wraps(), ui.text(GdChime.Formats.money(piece.map(func(one: Variant) -> Variant: return null if one == null else one["price"]), "£"), GdChime.Themes.NUMBER), ui.text(about, GdChime.Themes.FACE).wraps(), ui.text(said.call(&"stock"), GdChime.Themes.REASON), adds])
	var sides := func(down: bool) -> Dictionary: return ui.column_of([&"gallery", &"words"], {&"gallery": {"basis": 0.0}, &"words": {"grow": 1.0}}) if down else ui.row_of([&"gallery", &"words"], {&"gallery": {"basis": 0.5}, &"words": {"grow": 1.0}})
	var laid := ui.by_shape({&"gallery": GdChime.Gallery.make(ui, app.loads, shots, {count = 4, sizes = LARGE, thumb_sizes = SMALL}), &"words": words}, {GdChime.Shape.LANDSCAPE: sides.call(false), GdChime.Shape.PORTRAIT: sides.call(true)})
	return ui.scroll(laid).grow()


## The basket: a line a piece, or words for none, over the total and the way to check out.
static func basket_drawer(ui: GdChime.Ui, app: Object) -> GdChime.Desc:
	var basket: Basket = app.basket
	var lines := ui.scroll(ui.each(ui.bound(basket.get_lines), func(line: GdChime.Bound) -> GdChime.Desc: return _line(ui, app, line), func(line: Dictionary) -> int: return line["id"]))
	var nothing := ui.column([ui.text(GdChime.Phrase.of("Nothing in your basket yet"), GdChime.Themes.FACE).wraps(), ui.pressable(ui.CLOSES, {}, [ui.text(GdChime.Phrase.of("Keep browsing"), GdChime.Themes.FACE)], GdChime.Themes.PRESSABLE).goes_to(GdChime.Driver.BACK)])
	var total := ui.row([ui.text(GdChime.Phrase.of("Total"), GdChime.Themes.FACE).grow(), ui.text(GdChime.Formats.money(ui.bound(basket.get_total), "£"), GdChime.Themes.TITLE)])
	var foot := ui.column([total, ui.pressable(Basket.CHECKS_OUT, {}, [ui.text(ui.words(Basket.CHECKS_OUT), GdChime.Themes.FACE), ui.reason(GdChime.Themes.REASON)], GdChime.Pressables.BUTTON)])
	return GdChime.Drawer.over(ui, GdChime.Phrase.of("Your basket"), func(_which: GdChime.Bound) -> GdChime.Desc: return ui.when(ui.bound(basket.get_empty), nothing, lines), {foot = foot})


## A basket line: the piece's picture, its name and what it comes to, one fewer and one more, and a press taking it out.
static func _line(ui: GdChime.Ui, app: Object, line: GdChime.Bound) -> GdChime.Desc:
	var id: GdChime.Bound = line.map(func(one: Variant) -> Variant: return null if one == null else one["id"])
	var by := func(step: float) -> GdChime.Bound: return id.map(func(at: Variant) -> Dictionary: return {} if at == null else {"id": at, "by": int(step)})
	var cost := line.map(func(one: Variant) -> Variant: return "" if one == null else GdChime.Phrase.with("%d at £%s", [one["count"], GdChime.Phrase.written(func() -> String: return GdChime.Formats.written_number(one["price"]))]))
	var picture := ui.lazy_image(app.loads, id.map(func(at: Variant) -> Variant: return null if at == null else Vector2i(at, 0)), SMALL, GdChime.Gallery.THUMB_PICTURE)
	var named := ui.column([ui.text(line.map(func(one: Variant) -> String: return "" if one == null else one["name"]), GdChime.Themes.FACE).wraps(), ui.text(cost, GdChime.Themes.REASON)])
	var counts: GdChime.Desc = GdChime.Stepper.steps(ui, Basket.CHANGES, {carries = by, style = GdChime.Themes.CENTRED})
	return ui.row([picture, named.grow(), counts, ui.pressable(Basket.REMOVES, id.map(func(at: Variant) -> Dictionary: return {} if at == null else {"id": at}), [ui.text(ui.words(Basket.REMOVES), GdChime.Themes.FACE)])], GdChime.Themes.CENTRED)


## The filters: the facets and the range, over clearing them and showing what they keep - the drawer's way out.
static func filters_drawer(ui: GdChime.Ui, app: Object) -> GdChime.Desc:
	var shows: GdChime.Bound = ui.bound(app.filters.get_count).map(func(kept: Variant) -> Variant: return GdChime.Phrase.of("Show the pieces") if kept == null else GdChime.Phrase.counted("Show %d piece", "Show %d pieces", kept, "Nothing matches"))
	var foot := ui.row([ui.pressable(GdChime.Filters.CLEARS, {}, [ui.text(ui.words(GdChime.Filters.CLEARS), GdChime.Themes.FACE), ui.reason(GdChime.Themes.REASON)]), ui.pressable(ui.CLOSES, {}, [ui.text(shows, GdChime.Themes.FACE)], GdChime.Pressables.BUTTON).goes_to(GdChime.Driver.BACK).grow()])
	return GdChime.Drawer.over(ui, GdChime.Phrase.of("Filters"), func(_which: GdChime.Bound) -> GdChime.Desc: return ui.scroll(ui.column(app.facet_parts())), {foot = foot, from = GdChime.Drawer.FROM_LEFT})
