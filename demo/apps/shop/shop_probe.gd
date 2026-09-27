extends RefCounted

const GdChime := preload("res://addons/gd_chime/gd_chime.gd")
const Hands := preload("res://tests/hands.gd")
const Basket := preload("res://demo/apps/shop/basket.gd")

## The shop walked and reported: run by shop.gd started with --probe, and by
## checks/stalls_probe.py over every application.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## What the shop was asked to do, claim by claim: cards stand in before the
## first page lands, then a hundred pieces are there to be had a page at a
## time; the pictures near the reader are painted and those far off never
## asked for; scrolling to the foot grows the collection to every piece, and
## the pictures scrolled past are let go; every facet - room, material,
## colour, price, availability - and the search narrow it to what a query
## over the rows keeps, and an order runs it so; a card pressed opens the
## quick view over the collection, its gallery painting the large picture,
## stepping on to the next piece; adding a piece raises the basket's drawer
## holding it; a card under the pointer is drawn in its hover state, and the
## keys reach it too; the areas re-flow for a window on its end. Then the
## whole at three window shapes - the collection, the quick view, the
## basket - judged for words cut off and anything drawn over anything else.

const SHAPES: Array[Vector2i] = [Vector2i(1920, 1080), Vector2i(1280, 800), Vector2i(720, 1280)]
## How long a walk waits for what is out to land, in milliseconds of the clock.
const PATIENCE := 30000
const CLAIMS := ["cards_stand_in_first", "a_hundred_pieces_land", "near_pictures_painted_far_ones_not", "scrolling_grows_to_every_piece", "pictures_scrolled_past_let_go", "every_facet_narrows", "search_narrows", "an_order_runs_it", "quick_view_over_the_collection", "quick_view_steps_on", "adding_raises_the_basket", "hover_and_keys", "reflows_on_its_end", "no_clipped_text", "nothing_drawn_over", "words_stand_out"]

var _app: SceneTree
var _hands: Hands
var _said: Dictionary = {}


func _init(app: SceneTree) -> void:
	_app = app
	_hands = Hands.new(app)
	# every claim, false until shown
	for claim: String in CLAIMS:
		_said[claim] = false


## Frames until the view, the counts, the pages and the pictures have nothing out.
func _landed() -> void:
	var still := 0
	var until := Time.get_ticks_msec() + PATIENCE
	# a frame at a time until nothing has been out for five frames running - a picture claimed a frame late is waited for
	while Time.get_ticks_msec() < until and still < 5:
		await _app.process_frame
		var out: bool = _app.view.get_busy() or _app.filters.facets.get_busy() or _app.list.get_items().any(func(slot: Dictionary) -> bool: return slot["item"] == null) or _app.loads.get_busy()
		still = 0 if out else still + 1


func _images() -> Array:
	return _app.root.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is GdChime.LazyImage and part.is_visible_in_tree())


## The pictures shown in the place of this name, in the order they stand.
func _inside(place: StringName) -> Array:
	var holder: Node = _app.root.find_children(String(place), "Control", true, false)[0]
	return _images().filter(func(picture: GdChime.LazyImage) -> bool: return holder.is_ancestor_of(picture))


func _do(action: StringName, payload: Dictionary) -> void:
	_hands.does(_app.SHOP, action, payload)
	await _landed()


## How many rows a query of these clauses keeps.
func _kept(clauses: Array) -> int:
	return GdChime.RowQuery.run(_app.rows, clauses, {}, &"")["order"].size()


## The walk: every claim kept by name, all said, and the app quit on the answer.
func run() -> void:
	await _hands.plain_frames(1)
	_app.root.size = SHAPES[0]
	await _hands.plain_frames(2)
	_said["cards_stand_in_first"] = _app.list.get_items().size() == _app.PAGE and _app.list.get_items().all(func(slot: Dictionary) -> bool: return slot["item"] == null)
	await _landed()
	_said["a_hundred_pieces_land"] = _app.list.count() == 100 and _app.list.get_items().all(func(slot: Dictionary) -> bool: return slot["item"] != null)
	await _to_the_foot()
	await _narrows()
	await _quick_view()
	await _hover_and_keys()
	await _whole()
	var failed: Array = _said.keys().filter(func(claim: String) -> bool: return not _said[claim])
	print("PROBE %s" % [_said])
	print("PROBE " + ("OK" if failed.is_empty() else "FAILED %s" % [failed]))
	_app.quit(0 if failed.is_empty() else 1)


## Down the collection to its foot, the list growing as the foot nears, then the pictures behind let go.
func _to_the_foot() -> void:
	var scroll: ScrollContainer = _app.root.find_children("*", "ScrollContainer", true, false).filter(func(part: Node) -> bool: return part.is_visible_in_tree() and part.get_child(0).find_children("*", "Control", true, false).any(func(inner: Node) -> bool: return inner is GdChime.Pressable and inner.action == GdChime.GrowingList.GROWS))[0]
	var first: GdChime.LazyImage = _images().filter(func(picture: GdChime.LazyImage) -> bool: return scroll.is_ancestor_of(picture))[0]
	# a screen at a time, until everything shows and the foot is reached
	for step: int in 60:
		scroll.scroll_vertical += int(scroll.size.y * 0.8)
		await _hands.plain_frames(2)
		if not _app.list.get_more() and scroll.scroll_vertical >= scroll.get_v_scroll_bar().max_value - scroll.size.y - 1.0:
			break
	await _landed()
	_said["scrolling_grows_to_every_piece"] = _app.list.get_items().size() == 100 and not _app.list.get_more()
	_said["pictures_scrolled_past_let_go"] = first.get_claimed().is_empty() and _app.loads.get_held() <= _app.loads.get_claimed() + _app.KEPT
	var claimed: Array = _images().filter(func(picture: GdChime.LazyImage) -> bool: return scroll.is_ancestor_of(picture) and not picture.get_claimed().is_empty())
	_said["near_pictures_painted_far_ones_not"] = not claimed.is_empty() and claimed.all(func(picture: GdChime.LazyImage) -> bool: return picture.get_texture() != null) and claimed.size() < 40
	scroll.scroll_vertical = 0
	await _landed()


## Every facet, the price, the search and an order, each against a query over the rows.
func _narrows() -> void:
	var narrowed: Array = []
	# a value of every facet, picked, compared, and let go
	for facet: Array in [[&"room", "bedroom"], [&"material", "oak"], [&"colour", "sage"], [&"stock", "in stock"]]:
		await _do(GdChime.Filters.TOGGLES, {"column": facet[0], "value": facet[1]})
		narrowed.append(_app.view.get_kept() == _kept([{"column": facet[0], "test": GdChime.RowQuery.IS, "value": [facet[1]]}]) and _app.view.get_kept() < 100)
		await _do(GdChime.Filters.TOGGLES, {"column": facet[0], "value": facet[1]})
	await _do(GdChime.Filters.SETS_RANGE, {"value": Vector2(200, 900)})
	narrowed.append(_app.view.get_kept() == _kept([{"column": &"price", "test": GdChime.RowQuery.OVER, "value": 199.999}, {"column": &"price", "test": GdChime.RowQuery.UNDER, "value": 900.001}]))
	_said["every_facet_narrows"] = narrowed.all(func(held: bool) -> bool: return held) and _app.list.count() == _app.view.get_kept()
	await _do(GdChime.Filters.CLEARS, {})
	await _do(GdChime.Filters.SEARCHES, {"line": "Sofa"})
	_said["search_narrows"] = _app.view.get_kept() == _kept([{"column": &"about", "test": GdChime.RowQuery.INCLUDES, "value": "sofa"}]) and _app.view.get_kept() > 0
	await _do(GdChime.Filters.CLEARS, {})
	await _do(GdChime.Orders.ORDERS, {"value": &"dearest"})
	var prices: Array = _app.list.get_items().slice(0, 12).map(func(slot: Dictionary) -> float: return slot["item"]["price"])
	var sorted := prices.duplicate()
	sorted.sort()
	sorted.reverse()
	_said["an_order_runs_it"] = prices == sorted
	await _do(GdChime.Orders.ORDERS, {"value": &"featured"})


## A card pressed: the quick view over the collection, its large picture painted, a step on; then a piece added, the basket raised.
func _quick_view() -> void:
	var card: GdChime.Pressable = _hands.presses_of(_app.LOOKS_CLOSER)[0]
	var first_id: int = card.payload()["parameter"]
	card.pressed()
	await _landed()
	var large: GdChime.LazyImage = _inside(_app.quick_view.get_place())[0]
	_said["quick_view_over_the_collection"] = _app.driver.get_top().has(_app.quick_view.get_place()) and card.is_visible_in_tree() and _app.driver.get_parameter(_app.quick_view.get_place()) == first_id and large.get_texture() != null and large.get_claimed()[1] >= 480
	(_hands.presses_of(_app.SHOWS_ONE_AFTER)[0] as GdChime.Pressable).pressed()
	await _landed()
	_said["quick_view_steps_on"] = _app.driver.get_parameter(_app.quick_view.get_place()) == _app.neighbours(first_id)[1] and _app.driver.get_top().has(_app.quick_view.get_place())
	var adds: Array = _hands.presses_of(Basket.ADDS).filter(func(press: GdChime.Pressable) -> bool: return press.is_usable())
	(adds[-1] as GdChime.Pressable).pressed()
	await _landed()
	_said["adding_raises_the_basket"] = _app.driver.get_top().has(_app.basket_drawer.get_place()) and _app.basket.get_count() == 1 and not _inside(_app.basket_drawer.get_place()).is_empty()
	_hands.does(GdChime.Chimes.GLOBAL, GdChime.Driver.GOES_BACK, {})
	_hands.does(GdChime.Chimes.GLOBAL, GdChime.Driver.GOES_BACK, {})
	await _landed()


## A card under the pointer is drawn hovered; the keys give one the focus,
## drawn with its ring. The pointer goes to the middle of what shows of the
## card in its scroll's room: a card taller than the room shows it cut off,
## and past the cut the pointer is over what holds the scroll, not the card.
func _hover_and_keys() -> void:
	var card: GdChime.Pressable = _hands.presses_of(_app.LOOKS_CLOSER)[1]
	var up: Node = card
	# up from the card to the scroll it stands in, for the room it shows through
	while not up is ScrollContainer:
		up = up.get_parent()
	_hands.move(card.get_global_rect().intersection((up as ScrollContainer).get_global_rect()).get_center(), false)
	await _hands.plain_frames(2)
	var hovered: bool = card.get_state() == &"hover"
	card.grab_focus()
	await _hands.plain_frames(2)
	_said["hover_and_keys"] = hovered and card.has_focus() and card.get_drawn().size() == 2
	_hands.move(Vector2(-10, -10), false)


## The collection, the quick view and the basket at every shape, each judged for words cut off and for anything drawn over.
func _whole() -> void:
	var cut: Array[String] = []
	var over: Array[String] = []
	var worn: Array = []
	_app.ui.motion.still = true
	_app.ui.motion.step(10.0)
	_hands.does(_app.SHOP, Basket.ADDS, {"id": _app.list.get_items()[0]["item"]["id"]})
	_hands.does(GdChime.Chimes.GLOBAL, GdChime.Driver.GOES_BACK, {})
	# every shape, each judged alike
	for shape: Vector2i in SHAPES:
		_app.root.size = shape
		await _judged_here(&"the collection", shape, cut, over)
		worn.append((_app.root.find_children("*", "Container", true, false).filter(func(part: Node) -> bool: return part is GdChime.Areas and part.get_worn() in [&"wide", &"narrow"] and part.get_child_count() == 2)[0] as GdChime.Areas).get_worn())
		for place: StringName in [_app.quick_view.get_place(), _app.basket_drawer.get_place()]:
			_hands.does(_app.SHOP, GdChime.Driver.GO, {"place": place, "parameter": _app.list.get_items()[0]["item"]["id"] if place == _app.quick_view.get_place() else null})
			await _judged_here(place, shape, cut, over)
			_hands.does(GdChime.Chimes.GLOBAL, GdChime.Driver.GOES_BACK, {})
	_said["reflows_on_its_end"] = worn == [&"wide", &"wide", &"narrow"]
	_said["no_clipped_text"] = cut.is_empty()
	_said["nothing_drawn_over"] = over.is_empty()
	_said["words_stand_out"] = _hands.get_faint().is_empty()
	_hands.say_every(cut, over)


## Judged once everything out has landed, which a shape of its own may set going again.
func _judged_here(showing: StringName, shape: Vector2i, cut: Array[String], over: Array[String]) -> void:
	await _landed()
	await _hands.judged(showing, shape, cut, over)
