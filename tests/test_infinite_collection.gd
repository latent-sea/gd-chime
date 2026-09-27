extends SceneTree

## What must be true of an infinite collection over a growing list: as its
## place fills, a page of stand-ins shows until the page lands, and each
## becomes its card in place, never built again; growing is refused while a
## row is on its way and once everything shows, and grows a page of
## stand-ins that land in turn; the foot asks for the next page as the
## reader scrolls near it, and says when everything shows; the rows changing
## under it shows the first page alone again; a page that could not come
## says so beside a press asking again; and a source holding nothing says
## the caller's words for nothing.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_infinite_collection.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const LongList := preload("res://addons/gd_chime/long_list.gd")
const GrowingList := preload("res://addons/gd_chime/growing_list.gd")
const InfiniteCollection := preload("res://addons/gd_chime/components/recipes/infinite_collection.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Verdict := preload("res://tests/verdict.gd")

const REGION := &"shelf"
const PAGE := 4
const OPENS := &"opens"
const WORDS := {GrowingList.GROWS: "show more", LongList.ASK_AGAIN: "try again", OPENS: "open"}

var _verdict := Verdict.new()


## A source answering only when told: its rows, and every request waiting.
class Source extends Fixture.Model:
	var rows := value([])  # what a list reads to reset as they move
	var waiting: Array = []  # [first, count, answer]
	var failing: bool = false

	func fetch(first: int, count: int, answer: Callable) -> void:
		waiting.append([first, count, answer])

	## Every request waiting answered: the rows asked for, or none while failing.
	func answer() -> void:
		var asked := waiting.duplicate()
		waiting.clear()
		var all: Array = rows.read()
		# every request, answered in the order asked
		for request: Array in asked:
			request[2].call(null if failing else all.slice(request[0], request[0] + request[1]), all.size())


func _init() -> void:
	var theme := Themes.new(Themes.NEUTRAL)
	theme.set_constant(&"reach", &"Scroll", 250)
	# the cards one to a line in this window, each 150 tall, so a page runs past the window and its reach
	theme.set_type_variation(InfiniteCollection.CARDS, Themes.ROW)
	theme.set_constant(&"wrap", InfiniteCollection.CARDS, 1)
	theme.set_constant(&"least_column", InfiniteCollection.CARDS, 300)
	var tall := StyleBoxFlat.new()
	tall.content_margin_top = 65.0
	tall.content_margin_bottom = 65.0
	theme.set_type_variation(&"Tall", Themes.SURFACE)
	theme.set_stylebox(&"panel", &"Tall", tall)
	root.theme = theme
	await process_frame
	root.size = Vector2i(400, 400)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_a_page_of_stand_ins_shows_until_it_lands_and_each_becomes_its_card_in_place)
	await _verdict.states(_growing_is_refused_while_a_row_is_on_its_way_and_once_everything_shows)
	await _verdict.states(_growing_waits_while_a_row_showing_is_on_its_way)
	await _verdict.states(_the_foot_asks_for_the_next_page_as_the_reader_scrolls_near_it)
	await _verdict.states(_a_window_taller_than_a_page_is_filled_page_after_page)
	await _verdict.states(_the_rows_changing_under_it_shows_the_first_page_alone_again)
	await _verdict.states(_a_page_that_could_not_come_says_so_beside_a_press_asking_again)
	await _verdict.states(_a_source_holding_nothing_says_the_callers_words)
	quit(_verdict.deliver(get_script()))


## A collection of rows named "row N", each card its row's name or "coming"; started: [fixture, source, list].
func _collection(count: int) -> Array:
	var made := Fixture.new(root, WORDS)
	var ui := made.ui
	var source := Source.new(made.chimes, &"rows")
	source.rows.set_value(range(count).map(func(at: int) -> Dictionary: return {"name": "row %d" % at}))
	root.add_child(source)
	var list := GrowingList.new(made.chimes, source.fetch, PAGE, source.rows)
	made.commands.stand(REGION, list)
	root.add_child(list)
	# a card's opening, answered where the rows are
	var opener := Fixture.Model.new(made.chimes)
	opener.answering = [OPENS]
	made.commands.stand(REGION, opener)
	root.add_child(opener)
	var card := func(row: Bound) -> Desc: return ui.pressable(OPENS, {}, [ui.surface(&"Tall", [ui.text(row.map(func(one: Variant) -> String: return "coming" if one == null else one["name"]))])])
	var says := {"more": Phrase.of("show more"), "everything": Phrase.of("that is everything"), "failed": Phrase.of("these could not come"), "again": Phrase.of("try again"), "empty": Phrase.of("nothing here")}
	var collection := InfiniteCollection.make(ui, list, card, says)
	ui.start(ui.app(&"app", [ui.screen(REGION, [ui.scroll(collection).named(&"scroll")], null, {on_fill = func(token: RefCounted) -> void: list.look(token)})]))
	await _frames(3)
	return [made, source, list]


func _frames(count: int) -> void:
	# so many frames, for what moved to be laid out and drawn
	for frame: int in count:
		await process_frame


## Every card's words, in order.
func _cards() -> Array:
	return root.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Text and part.is_visible_in_tree() and (part.get_text() == "coming" or part.get_text().begins_with("row "))).map(func(part: Text) -> String: return part.get_text())


func _shown(words: String) -> bool:
	return root.find_children("*", "Control", true, false).any(func(part: Node) -> bool: return part is Text and part.is_visible_in_tree() and part.get_text() == words)


func _a_page_of_stand_ins_shows_until_it_lands_and_each_becomes_its_card_in_place() -> void:
	var both: Array = await _collection(10)
	var source: Source = both[1]
	_verdict.check(_cards() == ["coming", "coming", "coming", "coming"], "as its place fills, a page of stand-ins shows: %s" % [_cards()])
	var first: Node = root.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Text and part.get_text() == "coming")[0]
	source.answer()
	await _frames(2)
	_verdict.check(_cards() == ["row 0", "row 1", "row 2", "row 3"], "the page landed, each stand-in is its card: %s" % [_cards()])
	_verdict.check(is_instance_valid(first) and first.get_text() == "row 0", "and in place: the first card is the very piece that stood in")
	(both[0] as Fixture).done()


func _growing_is_refused_while_a_row_is_on_its_way_and_once_everything_shows() -> void:
	var both: Array = await _collection(10)
	var made: Fixture = both[0]
	var source: Source = both[1]
	_verdict.check(str(made.commands.dispatch(REGION, GrowingList.GROWS, {})) == "Still loading", "before the first page lands, growing is refused: still loading")
	source.answer()
	await _frames(2)
	made.commands.dispatch(REGION, GrowingList.GROWS, {})
	await _frames(2)
	_verdict.check(_cards().size() == 8 and not _cards().has("coming"), "grown, a page more shows at once, since the page after the look was asked for with it: %s" % [_cards()])
	made.commands.dispatch(REGION, GrowingList.GROWS, {})
	await _frames(2)
	_verdict.check(_cards().slice(8) == ["coming", "coming"], "grown again past what has landed, only as many as there are stand in: %s" % [_cards()])
	_verdict.check(str(made.commands.dispatch(REGION, GrowingList.GROWS, {})) == "Everything is showing", "and growing again is refused: every row the list holds already shows, landed or not")
	source.answer()
	await _frames(2)
	_verdict.check(_cards().size() == 10 and str(made.commands.dispatch(REGION, GrowingList.GROWS, {})) == "Everything is showing" and _shown("that is everything"), "landed, everything shows: growing is refused and the foot says so: %s" % [_cards()])
	made.done()


## Twenty rows: the first answer lands the first two pages, a grow shows the
## second, a grow past it shows the third standing in - and one more waits
## for it.
func _growing_waits_while_a_row_showing_is_on_its_way() -> void:
	var both: Array = await _collection(20)
	var made: Fixture = both[0]
	(both[1] as Source).answer()
	await _frames(2)
	made.commands.dispatch(REGION, GrowingList.GROWS, {})
	made.commands.dispatch(REGION, GrowingList.GROWS, {})
	await _frames(2)
	_verdict.check(_cards().slice(8) == ["coming", "coming", "coming", "coming"] and str(made.commands.dispatch(REGION, GrowingList.GROWS, {})) == "Still loading", "with a row showing on its way, growing is refused: still loading - %s" % [_cards()])
	made.done()


func _the_foot_asks_for_the_next_page_as_the_reader_scrolls_near_it() -> void:
	var both: Array = await _collection(40)
	var source: Source = both[1]
	var list: GrowingList = both[2]
	source.answer()
	await _frames(3)
	source.answer()
	_verdict.check(list.get_showing() == PAGE, "the foot out of reach, nothing more is asked: %d showing" % list.get_showing())
	var scroll: ScrollContainer = (both[0] as Fixture).ui.node_named(&"scroll")
	scroll.scroll_vertical = 100000
	await _frames(3)
	source.answer()
	await _frames(3)
	_verdict.check(list.get_showing() > PAGE and _cards().size() == list.get_showing(), "scrolled near the foot, the next page is asked for and shows: %d showing" % list.get_showing())
	(both[0] as Fixture).done()


## A window taller than a page: the foot is near from the start, its first
## press refused while the page is on its way; as pages land it asks again,
## page after page, until the foot is pushed out of reach - never scrolled.
func _a_window_taller_than_a_page_is_filled_page_after_page() -> void:
	root.size = Vector2i(400, 1500)
	var both: Array = await _collection(40)
	var list: GrowingList = both[2]
	# a few landings, each answering what the foot asked for
	for landing: int in 6:
		(both[1] as Source).answer()
		await _frames(3)
	_verdict.check(list.get_showing() >= 12 and _cards().size() == list.get_showing(), "the foot asked again as each page landed, filling the window: %d showing" % list.get_showing())
	(both[0] as Fixture).done()
	root.size = Vector2i(400, 400)


func _the_rows_changing_under_it_shows_the_first_page_alone_again() -> void:
	var both: Array = await _collection(12)
	var made: Fixture = both[0]
	var source: Source = both[1]
	source.answer()
	await _frames(2)
	made.commands.dispatch(REGION, GrowingList.GROWS, {})
	source.answer()
	await _frames(2)
	source.rows.set_value(range(12).map(func(at: int) -> Dictionary: return {"name": "row %d" % (100 + at)}))
	await _frames(2)
	_verdict.check(_cards() == ["coming", "coming", "coming", "coming"], "the rows changed, the first page alone stands in again: %s" % [_cards()])
	source.answer()
	await _frames(2)
	_verdict.check(_cards() == ["row 100", "row 101", "row 102", "row 103"], "and lands as the new rows: %s" % [_cards()])
	made.done()


func _a_page_that_could_not_come_says_so_beside_a_press_asking_again() -> void:
	var both: Array = await _collection(8)
	var made: Fixture = both[0]
	var source: Source = both[1]
	source.failing = true
	source.answer()
	await _frames(2)
	_verdict.check(_shown("these could not come") and _shown("try again"), "a page that could not come says so, beside a press asking again")
	source.failing = false
	made.commands.dispatch(REGION, LongList.ASK_AGAIN, {})
	source.answer()
	await _frames(2)
	_verdict.check(not _shown("these could not come") and _cards() == ["row 0", "row 1", "row 2", "row 3"], "asked again, it lands: %s" % [_cards()])
	made.done()


func _a_source_holding_nothing_says_the_callers_words() -> void:
	var both: Array = await _collection(0)
	(both[1] as Source).answer()
	await _frames(2)
	_verdict.check(_shown("nothing here") and _cards().is_empty(), "a source holding nothing says the caller's words, and no stand-in is left: %s" % [_cards()])
	(both[0] as Fixture).done()
