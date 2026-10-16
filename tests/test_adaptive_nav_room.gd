extends SceneTree

## What must be true of navigation that follows its own room
## (adaptive_nav.gd): it is a bar at the foot of a frame narrower than the
## look's compact_below, and a rail beside what it opens in a frame at least
## that wide, by the frame's own width and never the window's - so a frame
## in a side panel of a wide window wears the bar - and the same
## destinations, built once, move between the two.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_adaptive_nav_room.gd
##
## In the floor's look, whose compact_below is 900 base pixels, on a wide
## window of 1920 by 1080, the frame a share of a row beside an empty part.

const Fixture := preload("res://tests/fixture.gd")
const Verdict := preload("res://tests/verdict.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Shape := preload("res://addons/gd_chime/shape.gd")
const AdaptiveNav := preload("res://addons/gd_chime/components/recipes/adaptive_nav.gd")

const GOES_HOME := &"goes_home"
const GOES_AWAY := &"goes_away"

var _verdict := Verdict.new()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(1920, 1080)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_a_frame_in_a_side_panel_of_a_wide_window_wears_the_bar_and_widened_the_rail)
	quit(_verdict.deliver(get_script()))


func _frames(count: int = 4) -> void:
	# the frames asked for, each passing
	for frame: int in count:
		await process_frame


func _a_frame_in_a_side_panel_of_a_wide_window_wears_the_bar_and_widened_the_rail() -> void:
	var made := Fixture.new(root, {GOES_HOME: "home", GOES_AWAY: "away"})
	var ui := made.ui
	var destinations := [{"action": GOES_HOME, "goes_to": &"home"}, {"action": GOES_AWAY, "goes_to": &"away"}]
	var places := ui.tabs(&"places", [ui.screen(&"home", [ui.text("at home")]), ui.screen(&"away", [ui.text("away")])])
	ui.start(ui.app(&"app", [ui.row([AdaptiveNav.make(ui, destinations, places).basis(0.3).named(&"frame"), ui.text("").grow()])]))
	await _frames(6)
	made.commands.dispatch(Chimes.GLOBAL, made.driver.GO, {"place": &"home"})
	await _frames(3)
	var frame: Control = ui.node_named(&"frame")
	var home: Control = frame.find_children("*", "Control", true, false).filter(func(one: Node) -> bool: return one.get(&"action") == GOES_HOME)[0]
	var away: Control = frame.find_children("*", "Control", true, false).filter(func(one: Node) -> bool: return one.get(&"action") == GOES_AWAY)[0]
	var content: Control = made.driver.index.place_named(&"places")
	var compact := float(frame.get_theme_constant(&"compact_below", Shape.TYPE))
	_verdict.check(made.ui.shape.size_class.read() == Shape.WIDE and frame.size.x < compact, "the window is wide, and the frame, a third of it, narrower than compact_below: %s, %s of %s" % [made.ui.shape.size_class.read(), frame.size.x, compact])
	_verdict.check(home.get_global_rect().position.y >= content.get_global_rect().end.y - 1.0 and is_equal_approx(home.get_global_rect().position.y, away.get_global_rect().position.y) and away.get_global_rect().position.x > home.get_global_rect().position.x, "so the destinations are a bar side by side at its foot, under what they open: %s %s %s" % [home.get_global_rect(), away.get_global_rect(), content.get_global_rect()])
	_verdict.check(home.get_global_rect().end.x <= frame.get_global_rect().end.x + 0.5, "and the bar stands inside the frame: %s in %s" % [home.get_global_rect(), frame.get_global_rect()])
	root.size = Vector2i(3200, 1080)
	await _frames(6)
	var still_home: Control = frame.find_children("*", "Control", true, false).filter(func(one: Node) -> bool: return one.get(&"action") == GOES_HOME)[0]
	_verdict.check(frame.size.x >= compact and still_home == home and home.get_global_rect().end.x <= content.get_global_rect().position.x + 1.0 and away.get_global_rect().position.y > home.get_global_rect().position.y, "the frame widened to at least compact_below, the same destinations are a rail down its side, beside what they open: %s %s %s %s" % [frame.size.x, home.get_global_rect(), away.get_global_rect(), content.get_global_rect()])
	_verdict.check(home.call(&"get_state") == &"current" and away.call(&"get_state") != &"current", "and the one the reader is at is drawn current")
	made.done()
