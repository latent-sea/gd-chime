extends SceneTree

## What must be true of a screen's page: scrolling, the head and the foot
## stand pinned inside the screen with everything between them in one
## scroll down, the spill first, and a body wider than the screen widens
## nothing; held, the list scrolls itself between the head and the foot
## while the room shows the rows it must, and where it cannot, the page
## falls back to scrolling with the list drawn whole - and back again as the
## room returns - its least never the list's; in every state no scroll down
## stands inside another, and nothing in a page grows from no basis; and
## the line holding the action is found by its place's name, inside the
## screen with every scroll at its start; and the page, scrolling or drawn
## whole, wears the style given, and a nudge given to follow moves it.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_page.gd
##
## Each statement is an app of one page in the floor's look, the window
## the room the statement sets, the held page's chooser described as any
## app describes it (ui.while_fits, through Page.held). The
## list that scrolls itself needs four rows' height: it stands in a slot of
## a four-line sample (room_for.gd), as a table names its least in rows.

const Fixture := preload("res://tests/fixture.gd")
const Verdict := preload("res://tests/verdict.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Scroll := preload("res://addons/gd_chime/components/primitives/scroll.gd")
const Page := preload("res://addons/gd_chime/components/recipes/page.gd")

## How many rows the list holds, and how many it must show.
const ROWS := 30
const SHOWN := 4
## The place whose action the foot holds.
const PLACE := &"entry"

var _verdict := Verdict.new()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(600, 800)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_scrolling_the_head_and_foot_are_pinned_and_the_spill_heads_the_page)
	await _verdict.states(_scrolling_a_body_wider_than_the_screen_widens_nothing)
	await _verdict.states(_held_the_list_scrolls_itself_while_the_room_shows_its_rows)
	await _verdict.states(_held_it_falls_back_to_scrolling_with_the_list_drawn_whole_and_back_again)
	await _verdict.states(_in_every_state_no_scroll_down_stands_inside_another_and_nothing_grows_from_no_basis)
	await _verdict.states(_the_page_wears_the_style_given_and_a_nudge_moves_it)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## A builder.
func _made() -> Fixture:
	return Fixture.new(root)


## The rows of the list, each a line of words.
func _rows(ui: RefCounted) -> Array:
	return range(ROWS).map(func(at: int) -> Desc: return ui.text("row %d" % at, Themes.WORDS))


## The list scrolling itself, needing four rows' height.
func _list(ui: RefCounted) -> Desc:
	var four := "\n".join(range(SHOWN).map(func(at: int) -> String: return "row %d" % at))
	return ui.room_for(ui.scroll(ui.column(_rows(ui)), null, Scroll.DOWN), [four], Themes.WORDS).named(&"list")


## The held lines and the spill: a head, a foot holding the action, named for its place, and a spill.
func _lines(ui: RefCounted) -> Dictionary:
	return {
		"head": ui.text("the head", Themes.TITLE).named(&"head"),
		"foot": ui.row([ui.text("ENTER THESE FIVE", Themes.FACE)]).named(Page.in_hand(PLACE)),
		"spill": ui.text("what the bar could not hold", Themes.WORDS).named(&"spill"),
	}


## The held page of the list, drawn whole as a column of the same rows where the room is short.
func _held(ui: RefCounted) -> Desc:
	var options := _lines(ui)
	# the spill described again unnamed, since a held page builds it beside each list
	options.merge({"body": _list(ui), "whole": ui.column(_rows(ui)).named(&"whole"), "spill": ui.text("what the bar could not hold", Themes.WORDS)}, true)
	return Page.held(ui, options)


func _started(made: Fixture, page: Desc) -> void:
	made.ui.start(made.ui.app(&"app", [page]))
	await _a_frame_passes()


## Whether this piece stands wholly inside the window.
func _inside(piece: Control) -> bool:
	return Rect2(Vector2.ZERO, Vector2(root.size)).encloses(piece.get_global_rect())


func _scrolling_the_head_and_foot_are_pinned_and_the_spill_heads_the_page() -> void:
	var made := _made()
	var options := _lines(made.ui)
	await _started(made, Page.scrolling(made.ui, made.ui.column(_rows(made.ui)).named(&"body"), options))
	var head: Control = made.ui.node_named(&"head")
	var foot: Control = made.ui.node_named(Page.in_hand(PLACE))
	var spill: Control = made.ui.node_named(&"spill")
	var body: Control = made.ui.node_named(&"body")
	_verdict.check(body.get_combined_minimum_size().y > root.size.y, "the body is taller than the screen: %s in %s" % [body.get_combined_minimum_size().y, root.size.y])
	_verdict.check(_inside(head) and head.get_global_rect().position.y == 0.0, "the head stands at the top, inside the screen: %s" % head.get_global_rect())
	_verdict.check(_inside(foot) and is_equal_approx(foot.get_global_rect().end.y, root.size.y), "the line holding the action is found by its place's name, at the foot, inside the screen with nothing scrolled: %s" % foot.get_global_rect())
	_verdict.check(spill.get_global_rect().position.y >= head.get_global_rect().end.y and spill.get_global_rect().end.y <= body.get_global_rect().position.y, "the spill heads the page, under the head and over the body: %s, %s" % [spill.get_global_rect(), body.get_global_rect()])
	var page: ScrollContainer = body.get_parent().get_parent()
	page.scroll_vertical = 400
	await _a_frame_passes()
	_verdict.check(page.scroll_vertical > 0 and _inside(head) and _inside(foot) and is_equal_approx(foot.get_global_rect().end.y, root.size.y), "scrolled down, the page moves and the head and the foot stay where they stood: %s, %s" % [page.scroll_vertical, foot.get_global_rect()])
	made.done()


func _scrolling_a_body_wider_than_the_screen_widens_nothing() -> void:
	var made := _made()
	var wide := made.ui.text("a line of words that is far wider than the screen it stands on, and never breaks", Themes.WORDS).named(&"wide")
	await _started(made, Page.scrolling(made.ui, wide, _lines(made.ui)).named(&"page"))
	var page: Control = made.ui.node_named(&"page")
	var foot: Control = made.ui.node_named(Page.in_hand(PLACE))
	_verdict.check(made.ui.node_named(&"wide").get_combined_minimum_size().x > root.size.x, "the body needs more than the screen across: %s in %s" % [made.ui.node_named(&"wide").get_combined_minimum_size().x, root.size.x])
	_verdict.check(page.get_combined_minimum_size().x <= root.size.x and page.size.x == root.size.x and _inside(foot), "the page asks no more than its held lines across, and stands the screen's width, the foot inside it: %s, %s" % [page.get_combined_minimum_size().x, page.size.x])
	made.done()


func _held_the_list_scrolls_itself_while_the_room_shows_its_rows() -> void:
	var made := _made()
	await _started(made, _held(made.ui))
	var list: Control = made.ui.node_named(&"list")
	var whole: Control = made.ui.node_named(&"whole")
	var foot: Control = made.ui.node_named(Page.in_hand(PLACE))
	var scroller: ScrollContainer = list.find_children("*", "ScrollContainer", true, false)[0]
	_verdict.check(list.is_visible_in_tree() and not whole.is_visible_in_tree(), "with room for its rows, the list scrolling itself stands, and the list drawn whole does not")
	_verdict.check(list.size.y >= list.get_combined_minimum_size().y and list.get_global_rect().end.y <= foot.get_global_rect().position.y, "the list takes the room between the spill and the foot, at least its four rows: %s, least %s" % [list.get_global_rect(), list.get_combined_minimum_size().y])
	scroller.scroll_vertical = 300
	await _a_frame_passes()
	_verdict.check(scroller.scroll_vertical > 0 and _inside(foot) and _inside(made.ui.node_named(&"head")), "it scrolls itself while the head and the foot stay inside the screen: %s" % scroller.scroll_vertical)
	made.done()


func _held_it_falls_back_to_scrolling_with_the_list_drawn_whole_and_back_again() -> void:
	var made := _made()
	await _started(made, _held(made.ui).named(&"page"))
	var page: Control = made.ui.node_named(&"page")
	var list: Control = made.ui.node_named(&"list")
	var whole: Control = made.ui.node_named(&"whole")
	var head: Control = made.ui.node_named(&"head")
	var foot: Control = made.ui.node_named(Page.in_hand(PLACE))
	var listed: Control = list.get_parent()
	# the screen's height less the room between the head and the foot, and the least the spill and the four rows need there
	var needed: float = root.size.y - listed.get_parent().size.y + listed.get_combined_minimum_size().y
	_verdict.check(page.get_combined_minimum_size().y < needed, "its least is less than the head, the spill, four rows and the foot, so the screen may give it less: %s of %s" % [page.get_combined_minimum_size().y, needed])
	root.size.y = ceili(needed)
	await _a_frame_passes()
	_verdict.check(list.is_visible_in_tree() and not whole.is_visible_in_tree() and _inside(foot), "given just that, the list scrolling itself still stands, the foot inside the screen: %s" % foot.get_global_rect())
	root.size.y = ceili(needed) - 1
	await _a_frame_passes()
	_verdict.check(whole.is_visible_in_tree() and not list.is_visible_in_tree(), "given less than that, the list drawn whole stands in a scrolling page in its place: whole %s, list %s" % [whole.is_visible_in_tree(), list.is_visible_in_tree()])
	_verdict.check(whole.get_parent().get_parent() is ScrollContainer and _inside(head) and _inside(foot), "the whole list scrolls with the page, between the same head and foot, both inside the screen: %s, %s" % [head.get_global_rect(), foot.get_global_rect()])
	root.size.y = ceili(needed) + 100
	await _a_frame_passes()
	_verdict.check(list.is_visible_in_tree() and not whole.is_visible_in_tree() and _inside(foot), "given room for its rows again, the list scrolling itself stands once more")
	root.size.y = 800
	await _a_frame_passes()
	made.done()


func _in_every_state_no_scroll_down_stands_inside_another_and_nothing_grows_from_no_basis() -> void:
	var made := _made()
	await _started(made, _held(made.ui).named(&"page"))
	var found: Array = []
	# a room with the list held, then one too short for it, the tree walked in each
	for tall: int in [800, 160]:
		root.size.y = tall
		await _a_frame_passes()
		var scrolls: Array = made.ui.node_named(&"page").find_children("*", "ScrollContainer", true, false).filter(func(scroll: Node) -> bool: return (scroll as Control).is_visible_in_tree() and (scroll as ScrollContainer).vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED)
		# every scroll down shown, for one with another scroll down shown inside it
		for outer: ScrollContainer in scrolls:
			if scrolls.any(func(inner: ScrollContainer) -> bool: return inner != outer and outer.is_ancestor_of(inner)):
				found.append("a scroll down inside %s at %d" % [outer.name, tall])
			# everything inside it, for a part its line grows from no basis
			for part: Node in outer.find_children("*", "Control", true, false):
				var facts: Dictionary = part.get_parent().get_facts(part) if part.get_parent().has_method(&"get_facts") else {}
				if facts.get("basis", -1.0) == 0.0 and facts.get("grow", 0.0) > 0.0:
					found.append("%s grows from no basis inside %s at %d" % [part.name, outer.name, tall])
		_verdict.check(scrolls.size() == 1, "at %d high exactly one scroll down is shown: %s" % [tall, scrolls.map(func(scroll: Node) -> String: return scroll.get_class())])
	_verdict.check(found.is_empty(), "in neither state does a scroll down stand inside another, or a part grow from no basis inside one: %s" % [found])
	root.size.y = 800
	await _a_frame_passes()
	made.done()


## A look's own Scroll, padded wider, and a nudge to follow: the scrolling
## page wears it and a nudge down moves it; the held page fallen back to
## scrolling wears it too.
func _the_page_wears_the_style_given_and_a_nudge_moves_it() -> void:
	root.theme.set_type_variation(&"RoomyScroll", &"Scroll")
	var roomy := StyleBoxEmpty.new()
	roomy.content_margin_left = 30
	roomy.content_margin_right = 30
	root.theme.set_stylebox(&"panel", &"RoomyScroll", roomy)
	var made := _made()
	var model := Fixture.Model.new(made.chimes)
	model.set_value(&"nudge", {"by": 0, "count": 0})
	var options := _lines(made.ui)
	options.merge({"style": &"RoomyScroll", "nudged": model.of(&"nudge")})
	await _started(made, Page.scrolling(made.ui, made.ui.column(_rows(made.ui)).named(&"body"), options))
	var page: ScrollContainer = made.ui.node_named(&"body").get_parent().get_parent()
	_verdict.check(page.theme_type_variation == &"RoomyScroll" and is_equal_approx(made.ui.node_named(&"body").get_parent().position.x, 30.0), "the scrolling page wears the style given, its padding where what it holds starts: %s, %s" % [page.theme_type_variation, made.ui.node_named(&"body").get_parent().position])
	model.set_value(&"nudge", {"by": 1, "count": 1})
	await create_timer(0.5).timeout
	_verdict.check(page.scroll_vertical > 0, "and a nudge down moves it: %s" % page.scroll_vertical)
	made.done()
	model.free()
	made = _made()
	var held_options := _lines(made.ui)
	held_options.merge({"body": _list(made.ui), "whole": made.ui.column(_rows(made.ui)).named(&"whole"), "spill": made.ui.text("what the bar could not hold", Themes.WORDS), "style": &"RoomyScroll"}, true)
	root.size.y = 160
	await _started(made, Page.held(made.ui, held_options))
	var whole: Control = made.ui.node_named(&"whole")
	_verdict.check(whole.is_visible_in_tree() and (whole.get_parent().get_parent() as Control).theme_type_variation == &"RoomyScroll", "fallen back to scrolling, the page the list is drawn whole in wears it too: %s" % (whole.get_parent().get_parent() as Control).theme_type_variation)
	root.size.y = 800
	await _a_frame_passes()
	made.done()
