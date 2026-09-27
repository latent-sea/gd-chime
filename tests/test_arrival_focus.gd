extends SceneTree

## What must be true of where the focus lands as a place is arrived at
## (arrival_focus.gd): a place entered as a piece's key puts the focus on
## that piece, over the place's own default; entered as nothing, or as
## another, the default stands; entered again as another piece's key, the
## focus goes there; a pop-up raised and lowered over it is no arrival, and
## the reader keeps the focus they had; a pop-up raised while its piece's
## value holds puts the focus on it; Back to an entry is an arrival; a piece
## built on a screen already shown takes nothing; and a piece far down a
## scroll is brought into view as it takes the focus.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_arrival_focus.gd

const Fixture := preload("res://tests/fixture.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Verdict := preload("res://tests/verdict.gd")

const HOME := &"home"
const OTHER := &"other"
const LONG := &"long"
const PICKS := &"picks"
const TYPES := &"types"

var _verdict := Verdict.new()
var _zoom: StringName  # the pop-up the tests raise, named by the builder
var _made: Fixture
var _model: Fixture.Model  # handles every press, and holds whether the pop-up's piece is wanted
var _later: Fixture.Model  # holds whether a piece is built on the home screen later


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(400, 400)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_a_place_entered_as_a_pieces_key_puts_the_focus_on_it_over_its_default)
	await _verdict.states(_entered_as_nothing_the_default_stands_and_as_another_key_the_focus_goes_there)
	await _verdict.states(_a_pop_up_raised_and_lowered_over_it_is_no_arrival)
	await _verdict.states(_a_pop_up_raised_while_its_pieces_value_holds_puts_the_focus_on_it)
	await _verdict.states(_back_to_an_entry_is_an_arrival)
	await _verdict.states(_a_piece_built_on_a_screen_already_shown_takes_nothing)
	await _verdict.states(_a_piece_far_down_a_scroll_is_brought_into_view)
	quit(_verdict.deliver(get_script()))


func _frames() -> void:
	await process_frame
	await process_frame
	await process_frame


## Whether a place is entered as this key, read on every move.
func _entered_as(place: StringName, key: StringName) -> Bound:
	return _made.ui.parameter(place).map(func(on: Variant) -> bool: return on == key)


## A piece named by its key: a press, taking the focus as the place is entered as that key.
func _piece(place: StringName, key: StringName) -> RefCounted:
	var ui := _made.ui
	return ui.arrival_focus(_entered_as(place, key), [ui.pressable(PICKS, {"key": key}, [ui.text(String(key))])])


## The app: home, a press first - its default - and three pieces, the last
## built later while a value holds; another screen; a long screen whose
## last piece lies far down a scroll. Beside it, a pop-up whose piece
## takes the focus while the model says.
func _built() -> void:
	_made = Fixture.new(root, {PICKS: "pick", TYPES: "type"})
	_model = Fixture.Model.new(_made.chimes)
	_later = Fixture.Model.new(_made.chimes, &"later")
	_model.set_value(&"flag", false)
	_later.set_value(&"flag", false)
	var ui := _made.ui
	_made.commands.register(Chimes.GLOBAL, PICKS, _model)
	_made.commands.register(Chimes.GLOBAL, TYPES, _model)
	var later := ui.when(_later.of(&"flag"), _piece(HOME, &"later"))
	var home := ui.screen(HOME, [ui.column([ui.pressable(PICKS, {"key": "first"}, [ui.text("first")]), _piece(HOME, &"a"), _piece(HOME, &"b"), later])])
	var rows: Array = range(40).map(func(at: int) -> RefCounted: return ui.pressable(PICKS, {"key": "row %d" % at}, [ui.text("row %d" % at)]))
	var long := ui.screen(LONG, [ui.scroll(ui.column(rows + [_piece(LONG, &"end")])).grow()])
	ui.build(ui.app(&"app", [ui.stack([home, ui.screen(OTHER, [ui.pressable(PICKS, {}, [ui.text("other")])]), long])]), root)
	var wanted := ui.arrival_focus(_model.of(&"flag"), [ui.field(TYPES)])
	var zoom := ui.pop_up(&"zoom", func(_which: Bound) -> Desc: return ui.column([ui.pressable(PICKS, {"key": "zoom first"}, [ui.text("zoom first")]), wanted]))
	_zoom = zoom.get_place()
	ui.build(zoom, root)
	_go(HOME)
	await _frames()


func _done() -> void:
	_model.free()
	_later.free()
	_made.done()


func _go(place: StringName, key: Variant = null) -> void:
	_made.commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": place} if key == null else {"place": place, "parameter": key})


## The key of the press holding the focus, or what holds it.
func _focused() -> Variant:
	var focused := root.gui_get_focus_owner()
	if focused is Pressable:
		return (focused as Pressable).payload().get("key")
	return focused


func _a_place_entered_as_a_pieces_key_puts_the_focus_on_it_over_its_default() -> void:
	await _built()
	_verdict.check(_focused() == "first", "entered as nothing, home's first press holds the focus: %s" % [_focused()])
	_go(OTHER)
	_go(HOME, &"b")
	await _frames()
	_verdict.check(_focused() == &"b", "entered as b, b takes the focus over the place's first press: %s" % [_focused()])
	_done()


func _entered_as_nothing_the_default_stands_and_as_another_key_the_focus_goes_there() -> void:
	await _built()
	_go(OTHER)
	_go(HOME, &"nobody")
	await _frames()
	_verdict.check(_focused() == "first", "entered as a key no piece holds, the default stands: %s" % [_focused()])
	_go(HOME, &"a")
	await _frames()
	var at_a: Variant = _focused()
	_go(HOME, &"b")
	await _frames()
	_verdict.check(at_a == &"a" and _focused() == &"b", "entered again as a, then as b, the focus goes to each: %s, %s" % [at_a, _focused()])
	_done()


func _a_pop_up_raised_and_lowered_over_it_is_no_arrival() -> void:
	await _built()
	_go(OTHER)
	_go(HOME, &"a")
	await _frames()
	var pieces := root.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable and (part as Pressable).payload().get("key") == &"b")
	(pieces[0] as Control).grab_focus()
	_go(_zoom)
	await _frames()
	_made.commands.dispatch(Chimes.GLOBAL, Driver.LOWERS, {"place": _zoom})
	await _frames()
	_verdict.check(_focused() == &"b" and _made.driver.get_parameter(HOME) == &"a", "the reader moved on to b, a pop-up raised and lowered gives b back, though home is still entered as a: %s" % [_focused()])
	_done()


func _a_pop_up_raised_while_its_pieces_value_holds_puts_the_focus_on_it() -> void:
	await _built()
	_go(_zoom)
	await _frames()
	var unwanted: Variant = _focused()
	_made.commands.dispatch(Chimes.GLOBAL, Driver.LOWERS, {"place": _zoom})
	_model.set_value(&"flag", true)
	_go(_zoom)
	await _frames()
	_verdict.check(unwanted == "zoom first" and _focused() is LineEdit, "raised while its value is false, the pop-up's first press takes the focus; raised while true, its piece's line does: %s, %s" % [unwanted, _focused()])
	_done()


func _back_to_an_entry_is_an_arrival() -> void:
	await _built()
	_go(HOME, &"a")
	await _frames()
	_go(OTHER)
	await _frames()
	_made.commands.dispatch(Chimes.GLOBAL, Driver.GOES_BACK, {})
	await _frames()
	_verdict.check(_made.driver.get_top() == [&"app", HOME] and _focused() == &"a", "Back to home entered as a, the focus is on a again: %s" % [_focused()])
	_done()


func _a_piece_built_on_a_screen_already_shown_takes_nothing() -> void:
	await _built()
	_go(OTHER)
	_go(HOME, &"later")
	await _frames()
	var before: Variant = _focused()
	_later.set_value(&"flag", true)
	await _frames()
	_go(_zoom)
	_made.commands.dispatch(Chimes.GLOBAL, Driver.LOWERS, {"place": _zoom})
	await _frames()
	_verdict.check(before == "first" and _focused() == "first", "the piece for later, built after home was entered as its key and a pop-up raised and lowered, takes nothing: %s" % [_focused()])
	_done()


func _a_piece_far_down_a_scroll_is_brought_into_view() -> void:
	await _built()
	_go(LONG, &"end")
	await _frames()
	var focused := root.gui_get_focus_owner()
	var seen := root.get_visible_rect().encloses(focused.get_global_rect())
	_verdict.check(_focused() == &"end" and seen, "entered as the last piece of forty rows down, the focus is on it and it is in view: %s at %s" % [_focused(), focused.get_global_rect()])
	_done()
