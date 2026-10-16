extends SceneTree

## What must be true of the guard that finds what stands past the room it
## was given: a tree standing inside the safe rect has nothing found; a
## piece past the safe rect is found, by its path and the side it is past;
## past a page across is found, and past it down is not, nor past a strip
## across, while past a holder that cuts what it holds and never moves is;
## a holder's own place is never blamed on what it holds; words that wrap set narrower than their widest word
## are found, and set at it are not; what is hidden is not judged; and in a
## debug build each piece is said out loud once, however often it is found.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_outside_safe.gd
##
## Each statement builds into a host standing at the window's corner, 400
## pixels square, which is the safe rect judged, in the floor's look. A
## piece too wide is a control 900 pixels across built by hand.

const Fixture := preload("res://tests/fixture.gd")
const Verdict := preload("res://tests/verdict.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const OutsideSafe := preload("res://addons/gd_chime/outside_safe.gd")

## The safe rect each statement judges against, which is its host's.
const SAFE := Rect2(0, 0, 400, 400)
## How wide the piece too wide for it is.
const TOO_WIDE := 900.0

var _verdict := Verdict.new()
var _hearing := Hearing.new()


## Every error said while it listens, by its words.
class Hearing extends Logger:
	var said: Array[String] = []

	func _log_error(_function: String, _file: String, _line: int, code: String, _rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type != ERROR_TYPE_WARNING:
			said.append(code)


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(1200, 800)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_a_tree_standing_inside_the_safe_rect_has_nothing_found)
	await _verdict.states(_a_piece_past_the_safe_rect_is_found_by_its_path_and_side)
	await _verdict.states(_past_a_page_across_is_found_and_past_it_down_is_not)
	await _verdict.states(_past_a_strip_across_is_not_found_and_past_a_holder_that_never_moves_is)
	await _verdict.states(_words_that_wrap_set_narrower_than_their_widest_word_are_found)
	await _verdict.states(_what_is_hidden_is_not_judged)
	await _verdict.states(_each_piece_is_said_once_however_often_it_is_found)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## The host a statement builds into: the safe rect itself, at the window's corner.
func _host() -> Control:
	var host := Control.new()
	host.position = SAFE.position
	host.size = SAFE.size
	root.add_child(host)
	return host


## A control too wide for the safe rect, as a part, named so.
func _too_wide(ui: RefCounted) -> RefCounted:
	var wide := Control.new()
	wide.custom_minimum_size = Vector2(TOO_WIDE, 20)
	return ui.embed(wide).named(&"too_wide")


func _a_tree_standing_inside_the_safe_rect_has_nothing_found() -> void:
	var made := Fixture.new(root)
	var host := _host()
	made.ui.build(made.ui.page_scroll(made.ui.column([made.ui.text("a few words", Themes.WORDS), made.ui.row([made.ui.text("a label"), made.ui.text("words that wrap within the room they have", Themes.WORDS).wraps().grow()])])), host)
	await _a_frame_passes()
	_verdict.check(OutsideSafe.found(host, SAFE).is_empty(), "a page of words inside the safe rect has nothing found: %s" % [OutsideSafe.found(host, SAFE)])
	host.free()
	made.done()


func _a_piece_past_the_safe_rect_is_found_by_its_path_and_side() -> void:
	var made := Fixture.new(root)
	var host := _host()
	made.ui.build(made.ui.column([made.ui.text("words"), _too_wide(made.ui)]).named(&"column"), host)
	await _a_frame_passes()
	var found := OutsideSafe.found(host, SAFE)
	var column: Control = made.ui.node_named(&"column")
	_verdict.check(found.size() == 1 and found[0].begins_with(String(column.get_path())) and found[0].contains("%d pixels past the right of the safe rect" % roundi(TOO_WIDE - SAFE.size.x)), "a column holding a piece 900 across, in a safe rect 400 across with nothing cutting it, is found once, past its right: %s" % [found])
	host.free()
	made.done()


func _past_a_page_across_is_found_and_past_it_down_is_not() -> void:
	var made := Fixture.new(root)
	var host := _host()
	var tall: Array = range(40).map(func(line: int) -> RefCounted: return made.ui.text("line %d of a long page" % line))
	made.ui.build(made.ui.page_scroll(made.ui.column(tall)).named(&"page"), host)
	await _a_frame_passes()
	_verdict.check(OutsideSafe.found(host, SAFE).is_empty(), "a page whose words run far below it, which it scrolls down to, has nothing found: %s" % [OutsideSafe.found(host, SAFE)])
	host.free()
	host = _host()
	made.ui.build(made.ui.page_scroll(made.ui.column([made.ui.text("words"), _too_wide(made.ui)]).named(&"held")).named(&"wide_page"), host)
	await _a_frame_passes()
	var found := OutsideSafe.found(host, SAFE)
	var page: Control = made.ui.node_named(&"wide_page")
	var held: Control = made.ui.node_named(&"held")
	_verdict.check(found.size() == 1 and found[0].begins_with(String(held.get_path())) and found[0].contains("past the right of %s" % page.get_path()), "a page holding a piece too wide for it, which it never scrolls across, has what it holds found past its right, and the page itself never: %s" % [found])
	host.free()
	made.done()


func _past_a_strip_across_is_not_found_and_past_a_holder_that_never_moves_is() -> void:
	var made := Fixture.new(root)
	var host := _host()
	made.ui.build(made.ui.column([made.ui.scroll(made.ui.row([made.ui.text("one"), _too_wide(made.ui), made.ui.text("three")]), null, &"across")]), host)
	await _a_frame_passes()
	_verdict.check(OutsideSafe.found(host, SAFE).is_empty(), "a strip whose row runs past its right, which it scrolls across to, has nothing found: %s" % [OutsideSafe.found(host, SAFE)])
	host.free()
	host = _host()
	var cut := Control.new()
	cut.clip_contents = true
	cut.size = Vector2(200, 100)
	host.add_child(cut)
	var inside := Control.new()
	inside.position = Vector2(0, 60)
	inside.size = Vector2(150, 80)
	cut.add_child(inside)
	await _a_frame_passes()
	var found := OutsideSafe.found(host, SAFE)
	_verdict.check(found.size() == 1 and found[0].begins_with(String(inside.get_path())) and found[0].contains("40 pixels past the bottom of %s" % cut.get_path()), "and a piece reaching past the foot of a holder that cuts what it holds and never moves is found, past that holder, which is never blamed itself: %s" % [found])
	host.free()
	made.done()


func _words_that_wrap_set_narrower_than_their_widest_word_are_found() -> void:
	var host := _host()
	var label := Label.new()
	label.text = "set much too narrowly"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.theme_type_variation = Themes.WORDS
	host.add_child(label)
	label.size = Vector2(40, 0)
	await _a_frame_passes()
	var squeezed := OutsideSafe.squeezed(host)
	_verdict.check(squeezed.size() == 1 and squeezed[0].contains("set much too narrowly") and OutsideSafe.found(host, SAFE).has(squeezed[0]), "words that wrap set 40 across, narrower than 'narrowly', are found, by themselves and with everything else: %s" % [squeezed])
	var font := label.get_theme_font(&"font")
	# a pixel over the widest word as the font measures it, which rounds where the label's shaping does not
	label.size = Vector2(ceilf(font.get_string_size("narrowly", HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size(&"font_size")).x) + 1.0, 0)
	await _a_frame_passes()
	_verdict.check(OutsideSafe.squeezed(host).is_empty(), "and set at their widest word they are not: %s" % [OutsideSafe.squeezed(host)])
	host.free()


func _what_is_hidden_is_not_judged() -> void:
	var made := Fixture.new(root)
	var host := _host()
	made.ui.build(made.ui.column([made.ui.text("words"), _too_wide(made.ui)]).named(&"column"), host)
	await _a_frame_passes()
	(made.ui.node_named(&"column") as Control).visible = false
	_verdict.check(OutsideSafe.found(host, SAFE).is_empty(), "a column too wide for the safe rect, hidden, has nothing found: %s" % [OutsideSafe.found(host, SAFE)])
	host.free()
	made.done()


func _each_piece_is_said_once_however_often_it_is_found() -> void:
	var made := Fixture.new(root)
	var host := _host()
	made.ui.build(made.ui.column([made.ui.text("words"), _too_wide(made.ui)]), host)
	await _a_frame_passes()
	var guard := OutsideSafe.new()
	OS.add_logger(_hearing)
	var first := guard.say(host, SAFE)
	var again := guard.say(host, SAFE)
	OS.remove_logger(_hearing)
	_verdict.check(OS.is_debug_build() and first.size() == 1 and again == first and _hearing.said == first, "found twice, the piece too wide is said out loud once, in its sentence: %s of %s" % [_hearing.said, first])
	host.free()
	made.done()
