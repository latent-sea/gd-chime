extends SceneTree

## What must be true of a feed in a virtual list: following, the newest are
## shown and an entry taken re-reads one row and no other; scrolled away,
## the rows the reader looks at stay exactly as they were however many
## arrive, and those arrivals are counted as unseen; following again, the
## newest show and the count is gone; the cursor on an entry holds the feed
## still; past the capacity the look is never before the oldest held; the
## focus stays on the list through every arrival.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_feed.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const LongList := preload("res://addons/gd_chime/long_list.gd")
const Feed := preload("res://addons/gd_chime/feed.gd")
const Verdict := preload("res://tests/verdict.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")

const SHOWING := 5
const CAPACITY := 40

var _verdict := Verdict.new()
var _feed: Feed
var _list: Control
var _made: Fixture


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(800, 600)
	await _verdict.states(_following_the_newest_show_and_one_arrival_re_reads_one_row)
	await _verdict.states(_scrolled_away_the_rows_stay_as_they_were_and_arrivals_are_counted)
	await _verdict.states(_the_cursor_on_an_entry_holds_the_feed_still)
	await _verdict.states(_past_the_capacity_the_look_is_never_before_the_oldest_held)
	quit(_verdict.deliver(get_script()))


## A feed of five rows shown in a virtual list with a cursor, begun; the list focused.
func _begin() -> void:
	_made = Fixture.new(root, {Feed.FOLLOWS: "show the newest", Feed.MOVES: "move", Feed.PRESSES: "pick", Feed.LETS_GO: "let go"})
	_feed = Feed.new(_made.chimes, CAPACITY, SHOWING)
	_made.commands.stand(Chimes.GLOBAL, _feed)
	root.add_child(_feed)
	var ui := _made.ui
	var cursor := {"at": Bound.new(_feed.get_in_view), "region": Chimes.GLOBAL, "keys": [[&"ui_up", false, Feed.MOVES, {"by": -1}], [&"ui_down", false, Feed.MOVES, {"by": 1}]], "anywhere": [[&"ui_cancel", Feed.LETS_GO]], "presses": Feed.PRESSES, "twice": Feed.FOLLOWS}
	var line := func(entry: RefCounted) -> RefCounted: return ui.text(entry.map(func(one: Variant) -> String: return "" if one == null else one["words"]))
	ui.start(ui.app(&"app", [ui.screen(&"watched", [ui.virtual_list(_feed, line, Themes.COLUMN, cursor).named(&"list")])]))
	await process_frame
	await process_frame
	_list = ui.node_named(&"list")
	_list.grab_focus()


func _arrive(from: int, count: int) -> void:
	_feed.append(range(from, from + count).map(func(at: int) -> Dictionary: return {"words": "entry %d" % at}))
	await process_frame
	await process_frame


## What the slots say, top to bottom.
func _shown() -> Array:
	return _list.get_slots().map(func(slot: Control) -> String: return slot.get_text())


func _following_the_newest_show_and_one_arrival_re_reads_one_row() -> void:
	await _begin()
	await _arrive(0, 12)
	_verdict.check(_shown() == ["entry 7", "entry 8", "entry 9", "entry 10", "entry 11"] and _feed.get_following(), "following, the newest five show, the last at the foot: %s" % [_shown()])
	var drawn: Array = _list.get_slots().map(func(slot: Control) -> int: return slot.refresh_count)
	await _arrive(12, 1)
	var slots: Array = _list.get_slots()
	var again: int = range(slots.size()).filter(func(at: int) -> bool: return slots[at].refresh_count != drawn[_slot_before(at)]).size()
	_verdict.check(_shown() == ["entry 8", "entry 9", "entry 10", "entry 11", "entry 12"] and again == 1, "one entry taken moves the rows on and re-reads one row alone: %s, %d re-read" % [_shown(), again])
	_made.done()


## The slot now at this place stood one place lower before a move of one row on: the slots turn.
func _slot_before(at: int) -> int:
	return (at + 1) % SHOWING


func _scrolled_away_the_rows_stay_as_they_were_and_arrivals_are_counted() -> void:
	await _begin()
	await _arrive(0, 20)
	_made.commands.dispatch(Chimes.GLOBAL, LongList.SCROLL_ROWS, {"by": -4})
	await process_frame
	var held := _shown()
	var slots: Array = _list.get_slots()
	# thirty entries in three frames while the reader is away
	for batch: int in 3:
		await _arrive(20 + batch * 10, 10)
	_verdict.check(_shown() == held and _list.get_slots() == slots and not _feed.get_following() and _feed.get_unseen() == 30, "scrolled away, the rows shown stay as they were and the thirty arrivals are counted unseen: %s, %d unseen" % [_shown(), _feed.get_unseen()])
	_verdict.check(root.gui_get_focus_owner() == _list, "the focus stays on the list through every arrival: %s" % root.gui_get_focus_owner())
	_made.commands.dispatch(Chimes.GLOBAL, Feed.FOLLOWS, {})
	await process_frame
	await process_frame
	_verdict.check(_shown()[-1] == "entry 49" and _feed.get_following() and _feed.get_unseen() == 0, "following again, the newest show and nothing is unseen: %s" % [_shown()])
	_made.commands.dispatch(Chimes.GLOBAL, LongList.SCROLL_ROWS, {"by": -2})
	_made.commands.dispatch(Chimes.GLOBAL, LongList.SCROLL_ROWS, {"by": 2})
	await process_frame
	_verdict.check(_feed.get_following(), "scrolled back to the end, it follows again")
	_made.done()


func _the_cursor_on_an_entry_holds_the_feed_still() -> void:
	await _begin()
	await _arrive(0, 10)
	var up := InputEventAction.new()
	up.action = &"ui_up"
	up.pressed = true
	root.push_input(up)
	await process_frame
	var on: Variant = _feed.get_entry()
	var held := _shown()
	await _arrive(10, 6)
	_verdict.check(on != null and on["words"] == "entry 9" and _feed.get_entry() == on and _shown() == held and not _feed.get_following(), "the cursor on an entry holds it where it is as more arrive: %s, %s" % [_feed.get_entry(), _shown()])
	_made.commands.dispatch(Chimes.GLOBAL, Feed.LETS_GO, {})
	await process_frame
	_verdict.check(_feed.get_at() == -1 and _shown() == held and _feed.get_unseen() == 6, "let go of, the feed stays where the reader was, the arrivals counted: %d unseen" % _feed.get_unseen())
	_made.done()


func _past_the_capacity_the_look_is_never_before_the_oldest_held() -> void:
	await _begin()
	await _arrive(0, 20)
	_made.commands.dispatch(Chimes.GLOBAL, LongList.SCROLL_ROWS, {"by": -15})
	await process_frame
	await _arrive(20, CAPACITY)
	_verdict.check(_feed.get_first() >= _feed.count() - CAPACITY and _shown()[0] == "entry %d" % (_feed.count() - CAPACITY), "past the capacity, the reader is carried to the oldest held: first %d, %s" % [_feed.get_first(), _shown()])
	_made.done()
