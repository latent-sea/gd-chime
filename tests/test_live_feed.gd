extends SceneTree

## What must be true of a live feed on the screen: its press under the rows
## says following the newest, and is refused, while the reader follows; says
## how many are new once they step away, and pressed follows again; and
## neither the rows nor the press move a pixel through any of it. Enter on
## an entry does what the application opens entries with, on that entry.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_live_feed.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const LongList := preload("res://addons/gd_chime/long_list.gd")
const Feed := preload("res://addons/gd_chime/feed.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const LiveFeed := preload("res://addons/gd_chime/components/recipes/live_feed.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Verdict := preload("res://tests/verdict.gd")

const WATCHED := &"watched"
const OPENS := &"opens_an_entry"

var _verdict := Verdict.new()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(900, 700)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_the_press_under_the_rows_says_where_the_reader_stands_and_nothing_moves)
	quit(_verdict.deliver(get_script()))


## The words of the first label under this node.
static func _said(node: Node) -> String:
	# every child, itself a label or searched within
	for child: Node in node.get_children():
		if child is Label:
			return (child as Label).text
		var within := _said(child)
		if within != "":
			return within
	return ""


## The first pressable of this action under this node.
static func _press(node: Node, action: StringName) -> Pressable:
	# every child, itself the press or searched within
	for child: Node in node.get_children():
		if child is Pressable and (child as Pressable).action == action:
			return child
		var within := _press(child, action)
		if within != null:
			return within
	return null


func _arrive(feed: Feed, from: int, count: int) -> void:
	feed.append(range(from, from + count).map(func(at: int) -> Dictionary: return {"words": "entry %d" % at}))
	await process_frame
	await process_frame


func _the_press_under_the_rows_says_where_the_reader_stands_and_nothing_moves() -> void:
	var made := Fixture.new(root, {Feed.FOLLOWS: "show the newest", Feed.MOVES: "move", Feed.PRESSES: "pick", Feed.LETS_GO: "let go", OPENS: "open"})
	var feed := Feed.new(made.chimes, 200, 8)
	made.commands.stand(WATCHED, feed)
	root.add_child(feed)
	var opened := Fixture.Model.new(made.chimes, WATCHED)
	root.add_child(opened)
	var ui := made.ui
	var columns := _one_column()
	var line := func(entry: RefCounted) -> RefCounted: return LiveFeed.row(ui, feed, entry, [ui.text(entry.map(func(one: Variant) -> String: return "" if one == null else one["words"]), &"CellWords")], {names = [&"words"], columns = columns, samples = {&"words": {"words": ["entry 000"]}}})
	ui.start(ui.app(&"app", [ui.screen(WATCHED, [ui.column([LiveFeed.make(ui, feed, line, OPENS).named(&"feed").grow(), ui.button(OPENS)])])]))
	made.commands.register(WATCHED, OPENS, opened)
	await process_frame
	await process_frame
	var whole: Control = ui.node_named(&"feed")
	var follows := _press(whole, Feed.FOLLOWS)
	await _arrive(feed, 0, 30)
	var rows_at: Rect2 = (whole.get_child(0) as Control).get_global_rect()
	var press_at := follows.get_global_rect()
	_verdict.check(_said(follows) == "Following the newest" and not follows.is_usable(), "following, the press says so and is refused: %s" % _said(follows))
	made.commands.dispatch(WATCHED, LongList.SCROLL_ROWS, {"by": -5})
	await _arrive(feed, 30, 12)
	_verdict.check(_said(follows) == "12 new - show the newest" and follows.is_usable(), "stepped away, the press says how many are new: %s" % _said(follows))
	var still: bool = (whole.get_child(0) as Control).get_global_rect() == rows_at and follows.get_global_rect() == press_at
	follows.pressed()
	await process_frame
	await process_frame
	_verdict.check(feed.get_following() and _said(follows) == "Following the newest", "pressed, it follows the newest again: %s" % _said(follows))
	_verdict.check(still and (whole.get_child(0) as Control).get_global_rect() == rows_at and follows.get_global_rect() == press_at, "neither the rows nor the press moved through any of it")
	var list: Control = whole.get_child(0)
	list.grab_focus()
	# up onto the newest shown, then Enter
	for key: StringName in [&"ui_up", &"ui_accept"]:
		var pressed := InputEventAction.new()
		pressed.action = key
		pressed.pressed = true
		root.push_input(pressed)
		await process_frame
	_verdict.check(opened.told_actions == [OPENS] and feed.get_entry()["words"] == "entry 41", "Enter on an entry does what entries are opened with, on that entry: %s, %s" % [opened.told_actions, feed.get_entry()])
	made.done()


## The one column a row's cells stand in.
static func _one_column() -> RefCounted:
	return Bound.constant([{"name": &"words", "share": 1.0}])
