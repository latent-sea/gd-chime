extends SceneTree

## What must be true of a page that scrolls down: it asks for no room of its
## own, lays what fits it at exactly its width, never widens the app, never
## moves across, says the piece too wide for it and a scroll growing inside
## it, looking for them only when its width or what it holds needs has moved
## and never while hidden, and scrolls down as a scroll does; and follows the
## focus down only, settling when the focus is past its right edge.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_page_scroll.gd
##
## Each statement is on a window 400 pixels square, in the floor's look, whose
## scroll keeps 8 pixels either side of what it holds. A piece too wide is a
## control 3000 pixels across, built by hand, and set beside the same piece
## in a plain scroll running down, which passes its width up - the thing a
## page exists not to do.

const Fixture := preload("res://tests/fixture.gd")
const Verdict := preload("res://tests/verdict.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Scroll := preload("res://addons/gd_chime/components/primitives/scroll.gd")
const PageScroll := preload("res://addons/gd_chime/components/primitives/page_scroll.gd")
const ScrollIndicator := preload("res://addons/gd_chime/components/primitives/scroll_indicator.gd")

## The window's side, and how wide the piece too wide for it is.
const ROOM := 400
const TOO_WIDE := 3000.0

var _verdict := Verdict.new()
var _hearing := Hearing.new()
var _made: Fixture


## Every error said while it listens, by its words.
class Hearing extends Logger:
	var said: Array[String] = []

	func _log_error(_function: String, _file: String, _line: int, code: String, _rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type != ERROR_TYPE_WARNING:
			said.append(code)


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	OS.add_logger(_hearing)
	await process_frame
	root.size = Vector2i(ROOM, ROOM)
	await _verdict.states(_its_least_is_its_own_padding_whatever_it_holds)
	await _verdict.states(_what_fits_is_laid_at_exactly_its_width)
	await _verdict.states(_a_piece_too_wide_never_widens_the_app_and_is_cut_at_the_page_s_edge)
	await _verdict.states(_across_it_never_moves)
	await _verdict.states(_the_piece_too_wide_is_said_once_and_by_its_own_name)
	await _verdict.states(_it_scrolls_down_with_a_scroll_s_indicator)
	await _verdict.states(_a_scroll_growing_inside_it_is_said_and_one_drawn_whole_is_not)
	await _verdict.states(_it_looks_inside_itself_only_when_its_width_or_what_it_holds_needs_has_moved)
	await _verdict.states(_a_focused_piece_past_its_right_edge_leaves_it_settled_at_the_start)
	await _verdict.states(_a_focused_piece_pushed_below_the_fold_is_brought_into_view_down)
	OS.remove_logger(_hearing)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## An app on the window holding what this makes of the builder.
func _standing(content: Callable) -> void:
	_made = Fixture.new(root)
	_made.ui.start(_made.ui.app(&"app", content.call(_made.ui)))
	await _a_frame_passes()


## A control too wide for the window, as a part.
func _too_wide(ui: RefCounted) -> RefCounted:
	var wide := Control.new()
	wide.custom_minimum_size = Vector2(TOO_WIDE, 20)
	return ui.embed(wide).named(&"too_wide")


## The room a page keeps either side of what it holds, its own least: the look's panel for a scroll.
func _padding(page: Control) -> Vector2:
	return page.get_theme_stylebox(&"panel").get_minimum_size()


func _its_least_is_its_own_padding_whatever_it_holds() -> void:
	await _standing(func(ui: RefCounted) -> Array: return [ui.column([ui.page_scroll(ui.column([ui.text("a few words")])).named(&"few"), ui.page_scroll(_too_wide(ui)).named(&"wide"), ui.scroll(ui.column([ui.text("the same wide piece")]), null, Scroll.DOWN)])])
	var few: Control = _made.ui.node_named(&"few")
	var wide: Control = _made.ui.node_named(&"wide")
	_verdict.check(few is PageScroll and few.get_combined_minimum_size() == _padding(few), "a page holding a few words asks for its own padding and nothing more: %s of %s" % [few.get_combined_minimum_size(), _padding(few)])
	_verdict.check(wide.get_combined_minimum_size() == _padding(wide), "and a page holding a piece 3000 across asks for the same: %s" % [wide.get_combined_minimum_size()])
	_made.done()
	await _standing(func(ui: RefCounted) -> Array: return [ui.scroll(_too_wide(ui), null, Scroll.DOWN).named(&"plain")])
	var plain: Control = _made.ui.node_named(&"plain")
	_verdict.check(plain.get_combined_minimum_size().x >= TOO_WIDE, "while a plain scroll running down asks for the width of what it holds: %s" % [plain.get_combined_minimum_size()])
	_made.done()


func _what_fits_is_laid_at_exactly_its_width() -> void:
	await _standing(func(ui: RefCounted) -> Array: return [ui.page_scroll(ui.column([ui.text("a line")]).named(&"held")).named(&"page")])
	var page: Control = _made.ui.node_named(&"page")
	var held: Control = _made.ui.node_named(&"held")
	_verdict.check(page.size.x == ROOM and held.size.x == ROOM - _padding(page).x and held.position.x == _padding(page).x / 2.0, "what it holds is as wide as the page less its padding, from the padding's edge: %s at %s in %s" % [held.size, held.position, page.size])
	_made.done()


func _a_piece_too_wide_never_widens_the_app_and_is_cut_at_the_page_s_edge() -> void:
	await _standing(func(ui: RefCounted) -> Array: return [ui.page_scroll(ui.column([ui.text("words"), _too_wide(ui)]).named(&"held")).named(&"page")])
	var app: Control = _made.driver.index.app
	var page: Control = _made.ui.node_named(&"page")
	var held: Control = _made.ui.node_named(&"held")
	_verdict.check(app.size.x == ROOM and page.size.x == ROOM, "the app and the page stay the window's width: %s %s" % [app.size, page.size])
	_verdict.check(page.clip_contents and held.size.x >= TOO_WIDE and held.position.x == _padding(page).x / 2.0, "what it holds stands at its left and runs past its right, where the page cuts it: %s at %s" % [held.size, held.position])
	_made.done()
	await _standing(func(ui: RefCounted) -> Array: return [ui.scroll(ui.column([ui.text("words"), _too_wide(ui)]), null, Scroll.DOWN)])
	_verdict.check(_made.driver.index.app.size.x >= TOO_WIDE, "while in a plain scroll running down the same piece widens the app past the window: %s" % [_made.driver.index.app.size])
	_made.done()


## Asked to stand across by the bar's value, by a pad's pan and by a wheel tilted sideways.
func _across_it_never_moves() -> void:
	await _standing(func(ui: RefCounted) -> Array: return [ui.page_scroll(ui.column([ui.text("words"), _too_wide(ui)]).named(&"held")).named(&"page")])
	var page: ScrollContainer = _made.ui.node_named(&"page")
	var held: Control = _made.ui.node_named(&"held")
	page.scroll_horizontal = 500
	await _a_frame_passes()
	_verdict.check(page.scroll_horizontal == 0 and held.position.x == _padding(page).x / 2.0, "set across, it stands at the start again: %s %s" % [page.scroll_horizontal, held.position])
	var pan := InputEventPanGesture.new()
	pan.delta = Vector2(40, 0)
	pan.position = Vector2(ROOM / 2.0, ROOM / 2.0)
	root.push_input(pan)
	var tilt := InputEventMouseButton.new()
	tilt.button_index = MOUSE_BUTTON_WHEEL_RIGHT
	tilt.pressed = true
	tilt.factor = 10.0
	tilt.position = Vector2(ROOM / 2.0, ROOM / 2.0)
	root.push_input(tilt)
	await _a_frame_passes()
	_verdict.check(page.scroll_horizontal == 0 and held.position.x == _padding(page).x / 2.0, "panned and wheeled across, it has not moved: %s %s" % [page.scroll_horizontal, held.position])
	_made.done()


func _the_piece_too_wide_is_said_once_and_by_its_own_name() -> void:
	var said := _hearing.said.size()
	await _standing(func(ui: RefCounted) -> Array: return [ui.page_scroll(ui.column([ui.text("words"), ui.row([ui.text("beside"), _too_wide(ui)])]).named(&"held")).named(&"page")])
	var named := str((_made.ui.node_named(&"too_wide") as Node).get_path())
	var about := func(sentence: String) -> bool: return sentence.contains("cut at the page's edge")
	var sentences: Array = _hearing.said.slice(said).filter(about)
	_verdict.check(sentences.size() == 1 and (sentences[0] as String).begins_with(named + " needs"), "the piece too wide is said, by its own path, not the row or the column holding it: %s" % [sentences])
	root.size = Vector2i(ROOM + 1, ROOM)
	await _a_frame_passes()
	root.size = Vector2i(ROOM, ROOM)
	await _a_frame_passes()
	_verdict.check(_hearing.said.slice(said).filter(about).size() == 1, "and laid again and again, it is said once: %s" % [_hearing.said.slice(said)])
	_made.done()


func _it_scrolls_down_with_a_scroll_s_indicator() -> void:
	await _standing(func(ui: RefCounted) -> Array: return [ui.page_scroll(ui.column(range(60).map(func(at: int) -> RefCounted: return ui.text("row %d" % at)))).named(&"page")])
	var page: ScrollContainer = _made.ui.node_named(&"page")
	_verdict.check(page.get_v_scroll_bar().max_value > page.size.y, "sixty rows are taller than the page, and it can go down: %s against %s" % [page.get_v_scroll_bar().max_value, page.size.y])
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	wheel.position = Vector2(ROOM / 2.0, ROOM / 2.0)
	root.push_input(wheel)
	await _a_frame_passes()
	_verdict.check(page.scroll_vertical > 0, "the wheel takes it down: %s" % page.scroll_vertical)
	var marks: Array = page.get_children(true).filter(func(child: Node) -> bool: return child is ScrollIndicator)
	_verdict.check(marks.size() == 1, "and where the reader is shows over it, as over any scroll running down: %s" % [marks])
	_made.done()


func _a_scroll_growing_inside_it_is_said_and_one_drawn_whole_is_not() -> void:
	var said := _hearing.said.size()
	await _standing(func(ui: RefCounted) -> Array: return [ui.page_scroll(ui.column([ui.text("a heading"), ui.scroll(ui.column([ui.text("a list")]), null, Scroll.DOWN).grow().named(&"growing"), ui.scroll(ui.column([ui.text("a list drawn whole")]), null, Scroll.DOWN).named(&"whole"), ui.scroll(ui.row([ui.text("a strip")]), null, Scroll.ACROSS).grow().named(&"strip")])).named(&"page")])
	var about := func(sentence: String) -> bool: return sentence.contains("grows to fill its line")
	var sentences: Array = _hearing.said.slice(said).filter(about)
	var growing := str((_made.ui.node_named(&"growing") as Node).get_path())
	_verdict.check(sentences.size() == 1 and (sentences[0] as String).begins_with(growing + " scrolls down"), "the scroll running down that grows to fill its line is said, and neither the one drawn whole nor the strip across: %s" % [sentences])
	_made.done()


## Sixty rows wheeled down, the window widened, then narrowed again while
## the page is hidden, and the page shown.
func _it_looks_inside_itself_only_when_its_width_or_what_it_holds_needs_has_moved() -> void:
	await _standing(func(ui: RefCounted) -> Array: return [ui.page_scroll(ui.column(range(60).map(func(at: int) -> RefCounted: return ui.text("row %d" % at)))).named(&"page")])
	var page: PageScroll = _made.ui.node_named(&"page")
	var looked := page.look_count
	var laid: Array = [0]
	page.sort_children.connect(func() -> void: laid[0] += 1)
	# the wheel turned down five times, a frame apart
	for turn: int in 5:
		var wheel := InputEventMouseButton.new()
		wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
		wheel.pressed = true
		wheel.position = Vector2(ROOM / 2.0, ROOM / 2.0)
		root.push_input(wheel)
		await _a_frame_passes()
	_verdict.check(looked > 0 and page.scroll_vertical > 0 and laid[0] >= 5 and page.look_count == looked, "wheeled down and laid out %d times, it has not looked inside itself again: %d then %d" % [laid[0], looked, page.look_count])
	root.size = Vector2i(ROOM + 40, ROOM)
	await _a_frame_passes()
	_verdict.check(page.size.x == ROOM + 40 and page.look_count == looked + 1, "widened, it looks once more: %d" % page.look_count)
	page.visible = false
	var laid_shown: int = laid[0]
	root.size = Vector2i(ROOM, ROOM)
	await _a_frame_passes()
	_verdict.check(laid[0] > laid_shown and page.size.x == ROOM and page.look_count == looked + 1, "hidden, and laid out again at the window's narrower width, it does not look: laid %d times, %s, %d" % [laid[0] - laid_shown, page.size, page.look_count])
	page.visible = true
	await _a_frame_passes()
	_verdict.check(page.look_count == looked + 2, "shown again, at a width it has not looked inside itself at, it looks once: %d" % page.look_count)
	_made.done()


## A page holding what `beside` makes of the builder and a press, the press answered by a model the fixture stands.
func _standing_with_a_press(beside: Callable) -> void:
	_made = Fixture.new(root, {&"opens": "open"})
	_made.answer([&"opens"])
	var press: RefCounted = _made.ui.pressable(&"opens", {}, [_made.ui.text("open")]).named(&"press")
	_made.ui.start(_made.ui.app(&"app", [_made.ui.page_scroll(beside.call(_made.ui, press)).named(&"page")]))
	await _a_frame_passes()


## The press past the page's right edge, behind a piece too wide: shown whole it would be moved to across, which a page never is.
func _a_focused_piece_past_its_right_edge_leaves_it_settled_at_the_start() -> void:
	await _standing_with_a_press(func(ui: RefCounted, press: RefCounted) -> RefCounted: return ui.column([ui.text("words"), ui.row([_too_wide(ui), press])]))
	var page: ScrollContainer = _made.ui.node_named(&"page")
	var press: Control = _made.ui.node_named(&"press")
	var placings: Array = [0]
	page.sort_children.connect(func() -> void: placings[0] += 1)
	press.grab_focus()
	# frames enough for a settling page to have stopped long ago
	for frame: int in 10:
		await _a_frame_passes()
	var settled: int = placings[0]
	await _a_frame_passes()
	await _a_frame_passes()
	_verdict.check(press.has_focus() and press.get_global_rect().position.x > page.get_global_rect().end.x, "the press holds the focus, past the page's right edge: %s in %s" % [press.get_global_rect(), page.get_global_rect()])
	_verdict.check(settled <= 4 and placings[0] == settled, "the page settled: laid out %d times as the focus arrived, and not again since" % settled)
	_verdict.check(page.scroll_horizontal == 0 and page.get_child(0).position.x == _padding(page).x / 2.0, "and it stands at the start across: %s" % page.scroll_horizontal)
	_made.done()


## The press holding the focus, and then sixty rows standing above it: no focus moved, so the engine follows nothing, and the page itself takes it down until the press shows whole.
func _a_focused_piece_pushed_below_the_fold_is_brought_into_view_down() -> void:
	var rows_up: Array = []
	await _standing_with_a_press(func(ui: RefCounted, press: RefCounted) -> RefCounted:
		rows_up.append(ui.local(false))
		return ui.column([ui.when(rows_up[0], ui.column(range(60).map(func(at: int) -> RefCounted: return ui.text("row %d" % at)))), press]))
	var page: ScrollContainer = _made.ui.node_named(&"page")
	var press: Control = _made.ui.node_named(&"press")
	press.grab_focus()
	await _a_frame_passes()
	var focused_at := page.scroll_vertical
	rows_up[0].set_value(true)
	# frames enough for the rows to stand and the page to bring the press in and settle
	for frame: int in 10:
		await _a_frame_passes()
	_verdict.check(focused_at == 0 and press.has_focus() and page.scroll_vertical > 0 and page.get_global_rect().encloses(press.get_global_rect()), "the page has gone down from the top and the press shows whole: at %s, %s in %s" % [page.scroll_vertical, press.get_global_rect(), page.get_global_rect()])
	_made.done()
