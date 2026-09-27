extends RefCounted

const GdChime := preload("res://addons/gd_chime/gd_chime.gd")
const Basket := preload("res://demo/apps/shop/basket.gd")

## The shop laid out: in the shell's bar, the store's name, the search, the
## order, the filters and the basket; in its work, the facets down the left
## of a wide window and the collection beside them under a tray of bento
## cells saying what the store is; in its foot, how much is showing.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Every piece is a floor recipe over the floor's models - the filters, the
## growing list, the image loads - and the shop's own basket; this names
## the pieces, says the store's words, and lays them out: a wide window the
## facets and the collection side by side, a window on its end the
## collection alone, its facets in the filters drawer (shop_overlays.gd).
##
## A CARD is the floor's tile (card.gd): the piece's picture, loading as
## the reader nears it, over its name, its price and whether it can be had,
## and a press putting it in the basket - the card itself opening the quick
## view. A row still on its way is the card's own loading form (card.gd).

## The one row's least, a sliver of the base height given a share, so the row takes whatever room the shell leaves it.
const ROOM := 0.01
## The areas: the facets beside the collection on a wide window, the collection alone on one on its end.
const LAYOUTS := {
	&"wide": {"least": &"wide_from", "columns": [0.22, 0.78], "rows": [ROOM], "areas": ["rail main"]},
	&"narrow": {"least": 0.0, "columns": [1.0], "rows": [ROOM], "areas": ["main"]},
}
## The tray of cells over the collection: one large and three small on a wide window, stacked on a narrow one.
const TRAY := {
	&"wide": {"least": 0.55, "columns": [0.5, 0.25, 0.25], "rows": [0.0, 0.0], "areas": ["feature delivery making", "feature count count"]},
	&"narrow": {"least": 0.0, "columns": [0.5, 0.5], "rows": [0.0, 0.0, 0.0], "areas": ["feature feature", "delivery making", "count count"]},
}
## The sizes a card's picture may be asked for, in pixels square.
const CARD_SIZES := [240, 480, 720]

var _ui: GdChime.Ui
var _app: Object  # the shop: its models and its places


func _init(ui: GdChime.Ui, app: Object) -> void:
	_ui = ui
	_app = app


## The shell: the bar over the rail and the collection, over the foot.
func shell(notifications: GdChime.Notifications) -> GdChime.Desc:
	var ui := _ui
	var search := ui.field(GdChime.Filters.SEARCHES, GdChime.Fields.FIELD, {"changes": GdChime.Filters.SEARCHES, "shows": ui.bound(_app.filters.get_line)})
	var basket := ui.pressable(_app.OPENS_BASKET, {}, [ui.text(ui.bound(_app.basket.get_count).map(func(count: int) -> GdChime.Phrase: return GdChime.Phrase.counted("Basket, %d piece", "Basket, %d pieces", count, "Basket")), GdChime.Themes.FACE)], GdChime.Themes.PRESSABLE).opens(_app.basket_drawer)
	var filters := ui.pressable(_app.OPENS_FILTERS, {}, [ui.text(ui.words(_app.OPENS_FILTERS), GdChime.Themes.FACE)], GdChime.Themes.PRESSABLE).opens(_app.filters_drawer)
	var bar := [ui.text(GdChime.Phrase.of("Hollin & Wren"), GdChime.Themes.WORDS), search.grow(), _app.sorting, filters, basket]
	var main := ui.scroll(ui.column([_tray(), GdChime.FacetList.chips(ui, _app.filters), GdChime.InfiniteCollection.make(ui, _app.list, card, _collection_words())]))
	var rail := ui.scroll(ui.column(_app.facet_parts()))
	return GdChime.Shell.make(ui, bar, ui.areas({&"rail": rail, &"main": main}, LAYOUTS), {status = _status(), notifications = notifications, offers = {}})


## A piece's card, or the shape of one while its row is on its way.
func card(row: GdChime.Bound) -> GdChime.Desc:
	var ui := _ui
	var id: GdChime.Bound = row.map(func(piece: Variant) -> Variant: return null if piece == null else piece["id"])
	var picture := ui.lazy_image(_app.loads, id.map(func(at: Variant) -> Variant: return null if at == null else Vector2i(at, 0)), CARD_SIZES)
	var price := ui.text(GdChime.Formats.money(row.map(func(piece: Variant) -> Variant: return null if piece == null else piece["price"]), "£"), GdChime.Themes.TITLE)
	var stock := ui.text(row.map(func(piece: Variant) -> String: return "" if piece == null else piece["stock"]), GdChime.Themes.REASON)
	var adds := ui.pressable(Basket.ADDS, id.map(func(at: Variant) -> Dictionary: return {} if at == null else {"id": at}), [ui.text(ui.words(Basket.ADDS), GdChime.Themes.FACE), ui.reason(GdChime.Themes.REASON)], GdChime.Pressables.BUTTON).opens(_app.basket_drawer)
	var words := [ui.text(row.map(func(piece: Variant) -> String: return "" if piece == null else piece["name"]), GdChime.Themes.FACE), ui.row([price.grow(), stock]), adds]
	var landed: GdChime.Desc = GdChime.Card.tile(ui, _app.LOOKS_CLOSER, row, [picture] + words).opens(_app.quick_view)
	var standing: GdChime.Desc = GdChime.Card.loading(ui, 3, {above = ui.lazy_image(_app.loads, id.map(func(_at: Variant) -> Variant: return null), CARD_SIZES)})
	return ui.when(row.map(func(piece: Variant) -> bool: return piece != null), landed, standing)


## The tray of bento cells over the collection: what the store is, how it delivers and makes, and how many pieces there are.
func _tray() -> GdChime.Desc:
	var ui := _ui
	var cell := func(heading: GdChime.Phrase, says: Variant) -> GdChime.Desc: return ui.surface(GdChime.Themes.CARD, [ui.column([ui.text(heading, GdChime.Themes.TITLE), ui.text(says, GdChime.Themes.REASON).wraps()])])
	var feature := ui.surface(GdChime.Themes.RAISED, [ui.column([ui.text(GdChime.Phrase.of("The autumn edit"), GdChime.Themes.WORDS), ui.text(GdChime.Phrase.of("Low sofas, warm woods and lamps for the long evenings, made to last and delivered to your room"), GdChime.Themes.FACE).wraps()])])
	var count := ui.surface(GdChime.Themes.CARD, [ui.row([ui.text(ui.bound(_app.filters.get_count).map(func(kept: Variant) -> String: return "" if kept == null else str(kept)), GdChime.Themes.NUMBER), ui.text(GdChime.Phrase.within("pieces match what you are looking for"), GdChime.Themes.REASON).wraps().grow()])])
	return ui.areas({&"feature": feature, &"delivery": cell.call(GdChime.Phrase.of("Free delivery"), GdChime.Phrase.of("To your room, on every order over £500")), &"making": cell.call(GdChime.Phrase.of("Made to order"), GdChime.Phrase.of("In our workshop, in four weeks or less")), &"count": count}, TRAY)


func _collection_words() -> Dictionary:
	return {"more": GdChime.Phrase.of("Show more pieces"), "everything": GdChime.Phrase.of("That is every piece"), "failed": GdChime.Phrase.of("These pieces could not be shown"), "again": GdChime.Phrase.of("Try again"), "empty": GdChime.Phrase.of("Nothing matches: take a filter away")}


## The foot: how many pieces show of how many match, and how many pictures are held.
func _status() -> GdChime.Bound:
	var list: GdChime.GrowingList = _app.list
	var loads: GdChime.ImageLoads = _app.loads
	return GdChime.Bound.new(list.get_items).map(func(items: Array) -> GdChime.Phrase: return GdChime.Phrase.with("Showing %d of %d pieces, %d pictures held", [items.filter(func(slot: Dictionary) -> bool: return slot["item"] != null).size(), list.count(), loads.get_held()]))
