extends SceneTree

## What must be true of where a reader is in what scrolls: shown without
## taking room from what is shown.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_scroll_indicator.gd
##
## At a phone's shape, a scroll running down gives its piece the same room
## on its left as on its right, to the pixel, whether what it holds is too
## short to scroll or long enough to: nothing is kept aside for a bar.

const Fixture := preload("res://tests/fixture.gd")
const Scroll := preload("res://addons/gd_chime/components/primitives/scroll.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Verdict := preload("res://tests/verdict.gd")

## A phone held upright, in pixels.
const PHONE := Vector2i(540, 1200)

var _verdict := Verdict.new()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = PHONE
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_a_scroll_running_down_leaves_as_much_room_on_the_right_of_its_piece_as_on_the_left)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## A list of this many lines of words in a scroll running down, the whole
## of the window: the room left between the scroll's edges and its piece.
func _room_either_side(lines: int) -> Array[float]:
	var made := Fixture.new(root)
	var ui := made.ui
	var rows: Array = range(lines).map(func(at: int) -> RefCounted: return ui.text("line %d" % at))
	ui.start(ui.app(&"app", [ui.scroll(ui.column(rows).named(&"piece"), null, Scroll.DOWN).named(&"scroll").grow()]))
	await _a_frame_passes()
	var scroll := (ui.node_named(&"scroll") as Control).get_global_rect()
	var piece := (ui.node_named(&"piece") as Control).get_global_rect()
	var room: Array[float] = [piece.position.x - scroll.position.x, scroll.end.x - piece.end.x]
	made.done()
	return room


## Too short to scroll, and long enough to: the same room either side of
## the piece, to the pixel.
func _a_scroll_running_down_leaves_as_much_room_on_the_right_of_its_piece_as_on_the_left() -> void:
	var short := await _room_either_side(3)
	var long := await _room_either_side(200)
	_verdict.check(absf(short[0] - short[1]) < 1.0, "too short to scroll, as much room right of the piece as left: %s" % [short])
	_verdict.check(absf(long[0] - long[1]) < 1.0, "long enough to scroll, as much room right of the piece as left: %s" % [long])
