extends "res://addons/gd_chime/application.gd"

const GdChime := preload("res://addons/gd_chime/gd_chime.gd")
const Looks := preload("res://demo/gallery/looks/looks.gd")
const ShopData := preload("res://demo/apps/shop/shop_data.gd")
const ShopPictures := preload("res://demo/apps/shop/shop_pictures.gd")
const ShopView := preload("res://demo/apps/shop/shop_view.gd")
const ShopOverlays := preload("res://demo/apps/shop/shop_overlays.gd")
const Basket := preload("res://demo/apps/shop/basket.gd")
const ShopProbe := preload("res://demo/apps/shop/shop_probe.gd")

## Application 6, the e-commerce product browser: a furniture store of a
## hundred pieces, each with pictures painted as it loads, browsed by room,
## material, colour, price and whether it can be had, searched, ordered,
## looked at closer without leaving the collection, and put in a basket that
## slides in as a piece goes in.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --path <this folder> --script res://demo/apps/shop/shop.gd
##       [-- --look=<a gallery look; bento unless asked>] [-- --probe]
##
## EVERYTHING IS THE FLOOR'S: the pieces are rows (packed_rows.gd) queried
## off the frame (queried_rows.gd); the one filter model and the counts that
## are a view over it (filters.gd, facets.gd), the order (orders.gd) and the
## search narrow them; the collection grows a
## page at a time as the reader nears its foot (growing_list.gd,
## infinite_collection.gd), a card standing in for every piece on its way;
## every picture is painted on the job pool as it nears the reader and let go
## as it goes far (image_loads.gd, lazy_image.gd); the quick view, the basket
## and the filters are a pop-up and two drawers (quick_view.gd, drawer.gd).
## This makes the models, names the words, and hands the pictures their
## painter; the pages come a little later than asked, as from a server.

const SHOP := &"shop"
const LOOKS_CLOSER := &"looks_closer"
const SHOWS_ONE_BEFORE := &"shows_the_one_before"
const SHOWS_ONE_AFTER := &"shows_the_one_after"
const OPENS_BASKET := &"opens_the_basket"
const OPENS_FILTERS := &"opens_the_filters"
const CHOOSES_ORDER := &"chooses_the_order"
## The shop's own look, worn unless another is asked for.
const OWN_LOOK := &"bento"
## How many pieces a page, and how long a page takes to come, in seconds.
const PAGE := 12
const LATENCY := 0.35
## How many pictures are painted at once, and how many nobody shows are kept.
const PAINTED_AT_ONCE := 3
const KEPT := 24

var rows: GdChime.PackedRows
var view: GdChime.QueriedRows
var filters: GdChime.Filters
var orders: GdChime.Orders
var list: GdChime.GrowingList
var loads: GdChime.ImageLoads
var basket: Basket
## The order's choosing (combo.gd).
var sorting: Desc
## What stands over the shop (shop_overlays.gd): the basket, the filters and the quick view of a piece.
var basket_drawer: Desc
var filters_drawer: Desc
var quick_view: Desc
var _pictures: Array  # every piece's painting, by its row: what the painter reads on the pool
var _shelf: ShopView  # the shop laid out, held for its card template


## The look asked for at launch, or the shop's own - bento.
func look() -> Theme:
	return Looks.make(Looks.asked(OWN_LOOK))


func probe() -> RefCounted:
	return ShopProbe.new(self)


## The orders a shopper chooses between, by name: each a column, a way and its words.
static func named_orders() -> Dictionary:
	return {
		&"featured": {"column": &"rating", "ascending": false, "words": GdChime.Phrase.of("Most loved")},
		&"cheapest": {"column": &"price", "ascending": true, "words": GdChime.Phrase.of("Price, low to high")},
		&"dearest": {"column": &"price", "ascending": false, "words": GdChime.Phrase.of("Price, high to low")},
		&"newest": {"column": &"added", "ascending": false, "words": GdChime.Phrase.of("Newest")},
		&"name": {"column": &"name", "ascending": true, "words": GdChime.Phrase.of("Name")},
	}


## Every action of the shop's, with its words: none of them is on a key.
func declare(register: Actions) -> void:
	register.declare_all({
		LOOKS_CLOSER: ["Look closer"], SHOWS_ONE_BEFORE: ["The one before"], SHOWS_ONE_AFTER: ["The one after"], OPENS_BASKET: ["Basket"],
		OPENS_FILTERS: ["Filters"], CHOOSES_ORDER: ["Order"], GdChime.Orders.ORDERS: ["Order by"],
		GdChime.Filters.TOGGLES: ["Pick"], GdChime.Filters.SETS_RANGE: ["Set the price"], GdChime.Filters.SEARCHES: ["Search"], GdChime.Filters.TURNS: ["Turn the filter"], GdChime.Filters.REMOVES: ["Remove the filter"], GdChime.Filters.CLEARS: ["Clear the filters"],
		Basket.ADDS: ["Add to basket"], Basket.CHANGES: ["Change how many"], Basket.REMOVES: ["Remove"], Basket.CHECKS_OUT: ["Check out"],
		GdChime.GrowingList.GROWS: ["Show more"], GdChime.LongList.ASK_AGAIN: ["Try again"], Notifications.DISMISSES: ["Dismiss"],
	})


## The models made over the pieces and the shop described.
func describe() -> Desc:
	rows = ShopData.made()
	_pictures = ShopData.pictures_of(rows)
	view = GdChime.QueriedRows.new(chimes, rows, jobs)
	var priced := func(stretch: Vector2) -> GdChime.Phrase: return GdChime.Phrase.with("%s to %s", [GdChime.Formats.written_money(stretch.x, "£"), GdChime.Formats.written_money(stretch.y, "£")])
	var prices := Array(rows.numbers(&"price"))
	var spec := {search = &"about", any_of = [&"room", &"material", &"colour", &"stock"], between = {column = &"price", bounds = Vector2(prices.min(), prices.max()), words = priced}}
	filters = model(GdChime.Filters.new(chimes, spec, {over = rows, on = jobs, asks = view.ask}))
	orders = model(GdChime.Orders.new(chimes, view, named_orders()))
	list = GdChime.GrowingList.new(chimes, _later, PAGE, GdChime.Bound.new(view.get_shown))
	loads = model(GdChime.ImageLoads.new(chimes, jobs, _painted, PAINTED_AT_ONCE, KEPT))
	basket = model(Basket.new(chimes, rows, notifications))
	sorting = GdChime.Combo.short(ui, GdChime.Orders.ORDERS, CHOOSES_ORDER, {offers = ui.bound(orders.get_options), chosen = ui.bound(orders.get_chosen), title = GdChime.Phrase.of("Order the pieces by")})
	# what stands over the shop, the basket first, which a quick view opens too
	basket_drawer = ShopOverlays.basket_drawer(ui, self)
	filters_drawer = ShopOverlays.filters_drawer(ui, self)
	quick_view = ShopOverlays.quick_view(ui, self)
	_shelf = ShopView.new(ui, self)
	# the view of the pieces and the collection that grows answer on the shop's screen, where they are described
	return ui.app(&"app", [ui.screen(SHOP, [_shelf.shell(notifications)], [view, list], {on_fill = func(token: RefCounted) -> void: list.look(token)})])


## The facets and the price, titled, as the rail and the filters drawer show them; a colour's swatch before its name.
func facet_parts() -> Array:
	var swatch := func(value: GdChime.Bound) -> Desc: return ui.lazy_image(loads, value.map(func(one: Variant) -> Variant: return null if one == null else one["value"]), [48], GdChime.FacetList.SWATCH)
	var titled := {&"room": GdChime.Phrase.of("Room"), &"material": GdChime.Phrase.of("Material"), &"colour": GdChime.Phrase.of("Colour"), &"stock": GdChime.Phrase.of("Availability")}
	return GdChime.FacetList.make(ui, filters, titled, {&"colour": swatch}) + [GdChime.FacetList.range_of(ui, filters, GdChime.Phrase.of("Price"), {step = 5.0, words = func(stretch: Vector2) -> GdChime.Phrase: return GdChime.Phrase.with("%s to %s", [GdChime.Formats.written_money(stretch.x, "£"), GdChime.Formats.written_money(stretch.y, "£")])})]


## The pieces before and after this one, in the order the collection shows them, round the ends.
func neighbours(id: int) -> Array:
	var order := Array(view.get_order())
	var at := order.find(id)
	return [order[(at + order.size() - 1) % order.size()], order[(at + 1) % order.size()]] if at >= 0 else [id, id]


## A page of the collection, a little later than asked, as from a server.
func _later(first: int, count: int, answer: Callable) -> void:
	await create_timer(LATENCY).timeout
	view.fetch(first, count, answer)


## A picture, on the pool: a colour's swatch by its name, or a piece's shot by [row, shot].
func _painted(key: Variant, size: int) -> Image:
	if key is String:
		return ShopPictures.swatch(Color.html(ShopData.COLOURS[key]), size)
	return ShopPictures.painted(_pictures[key.x], key.y, size, true)
