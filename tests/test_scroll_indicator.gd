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
## short to scroll or long enough to: nothing is kept aside for a bar. Where
## the reader is shows over what scrolls, in the right padding of its box -
## never beside the rows, never over the words - only while there is more
## than is shown; lit as it moves, it fades once it has rested, on the one
## clock, or stays where the look says so. A text area shows the same, over
## words the engine's own bar takes no room from. The look's ScrollIndicator
## alone says how both look, whatever the engine's bars look like, and in
## every look of the gallery it fits in the padding it stands in.

const Fixture := preload("res://tests/fixture.gd")
const Scroll := preload("res://addons/gd_chime/components/primitives/scroll.gd")
const ScrollIndicator := preload("res://addons/gd_chime/components/primitives/scroll_indicator.gd")
const Area := preload("res://addons/gd_chime/components/primitives/area.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Fields := preload("res://addons/gd_chime/theme_fields.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Looks := preload("res://demo/gallery/looks/looks.gd")
const Verdict := preload("res://tests/verdict.gd")

## A phone held upright, in pixels.
const PHONE := Vector2i(540, 1200)
const WRITES := &"writes_words"

var _verdict := Verdict.new()


## Words to write in: whatever it is told, held.
class Words extends Fixture.Model:
	func get_words() -> Variant:
		return of(&"words").read()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = PHONE
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_a_scroll_running_down_leaves_as_much_room_on_the_right_of_its_piece_as_on_the_left)
	await _verdict.states(_where_the_reader_is_stands_in_the_right_padding_never_beside_the_rows)
	await _verdict.states(_it_shows_as_the_list_moves_and_fades_once_it_has_rested)
	await _verdict.states(_a_look_that_says_it_stays_shows_it_unmoved_and_never_fades_it)
	await _verdict.states(_a_text_area_shows_where_the_reader_is_only_when_it_holds_more_than_it_shows)
	await _verdict.states(_the_look_s_scroll_indicator_alone_says_how_both_look_and_the_engine_s_bars_say_nothing)
	await _verdict.states(_in_every_look_it_fits_in_the_padding_it_stands_in)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## A list of this many lines of words in a scroll running down, the whole of the window.
func _listed(lines: int) -> Fixture:
	var made := Fixture.new(root)
	var ui := made.ui
	var rows: Array = range(lines).map(func(at: int) -> RefCounted: return ui.text("line %d" % at))
	ui.start(ui.app(&"app", [ui.scroll(ui.column(rows).named(&"piece"), null, Scroll.DOWN).named(&"scroll").grow()]))
	ui.motion.by_hand = true
	await _a_frame_passes()
	return made


## The one mark over this scroll or text box, where the reader is.
func _indicator_of(over: Node) -> ScrollIndicator:
	return over.get_children(true).filter(func(part: Node) -> bool: return part is ScrollIndicator)[0]


## A list of this many lines: the room left between the scroll's edges and its piece.
func _room_either_side(lines: int) -> Array[float]:
	var made := await _listed(lines)
	var scroll := (made.ui.node_named(&"scroll") as Control).get_global_rect()
	var piece := (made.ui.node_named(&"piece") as Control).get_global_rect()
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


## Scrolled, the mark stands between the rows' right edge and the scroll's,
## and runs down no further than the scroll does.
func _where_the_reader_is_stands_in_the_right_padding_never_beside_the_rows() -> void:
	var made := await _listed(200)
	var scroll := made.ui.node_named(&"scroll") as ScrollContainer
	var indicator := _indicator_of(scroll)
	scroll.get_v_scroll_bar().value = 400.0
	await _a_frame_passes()
	var mark := Rect2(indicator.get_global_transform() * indicator.get_mark().position, indicator.get_mark().size)
	var piece := (made.ui.node_named(&"piece") as Control).get_global_rect()
	var box := scroll.get_global_rect()
	_verdict.check(indicator.get_opacity() == 1.0 and mark.position.x >= piece.end.x and mark.end.x <= box.end.x, "it stands right of the rows, inside the scroll: mark %s, rows end %.1f, scroll ends %.1f" % [mark, piece.end.x, box.end.x])
	_verdict.check(mark.position.y > box.position.y and mark.end.y < box.end.y and mark.size.y < box.size.y / 2.0, "scrolled part way down a long list, it is short and part way down: %s in %s" % [mark, box])
	made.done()


## Unmoved it shows nothing; moved, it shows until rests_after has passed,
## then fades over fades_over and is gone, and stops looking at the clock. A
## list too short to scroll never shows it, however it is moved.
func _it_shows_as_the_list_moves_and_fades_once_it_has_rested() -> void:
	var made := await _listed(200)
	var scroll := made.ui.node_named(&"scroll") as ScrollContainer
	var indicator := _indicator_of(scroll)
	var rests := scroll.get_theme_constant(&"rests_after", ScrollIndicator.TYPE) / 1000.0
	var fades := scroll.get_theme_constant(&"fades_over", ScrollIndicator.TYPE) / 1000.0
	_verdict.check(indicator.get_opacity() == 0.0 and not indicator.is_processing(), "unmoved, it shows nothing and looks at nothing")
	scroll.get_v_scroll_bar().value = 300.0
	await _a_frame_passes()
	var lit := indicator.get_opacity()
	made.ui.motion.step(rests - 0.01)
	await _a_frame_passes()
	var resting := indicator.get_opacity()
	made.ui.motion.step(0.01 + fades / 2.0)
	await _a_frame_passes()
	var fading := indicator.get_opacity()
	made.ui.motion.step(fades / 2.0 + 0.01)
	await _a_frame_passes()
	_verdict.check(lit == 1.0 and resting == 1.0 and fading > 0.0 and fading < 1.0 and indicator.get_opacity() == 0.0, "lit as it moved, still lit just short of rests_after, part faded half way through fades_over, gone after: %.2f %.2f %.2f %.2f" % [lit, resting, fading, indicator.get_opacity()])
	_verdict.check(not indicator.is_processing(), "gone, it no longer looks at the clock")
	made.done()
	made = await _listed(3)
	scroll = made.ui.node_named(&"scroll") as ScrollContainer
	scroll.get_v_scroll_bar().value = 300.0
	await _a_frame_passes()
	_verdict.check(_indicator_of(scroll).get_opacity() == 0.0, "a list too short to scroll never shows it")
	made.done()


## A look setting stays: shown on arrival, unmoved, and still shown long after.
func _a_look_that_says_it_stays_shows_it_unmoved_and_never_fades_it() -> void:
	root.theme.set_constant(&"stays", ScrollIndicator.TYPE, 1)
	var made := await _listed(200)
	var indicator := _indicator_of(made.ui.node_named(&"scroll"))
	var shown := indicator.get_opacity()
	made.ui.motion.step(60.0)
	await _a_frame_passes()
	_verdict.check(shown == 1.0 and indicator.get_opacity() == 1.0, "staying, it shows unmoved and a minute on: %.2f %.2f" % [shown, indicator.get_opacity()])
	made.done()
	root.theme.set_constant(&"stays", ScrollIndicator.TYPE, 0)


## A text area of this many lines of words, the clock stepped by hand, as [made, area, edit, words].
func _written(lines: int) -> Array:
	var made := Fixture.new(root, {WRITES: "write"})
	var ui := made.ui
	var words := Words.new(made.chimes, &"app")
	words.set_value(&"words", "\n".join(range(lines).map(func(at: int) -> String: return "line %d" % at)))
	made.commands.register(&"app", WRITES, words)
	ui.start(ui.app(&"app", [ui.column([ui.area(WRITES, Bound.new(words.get_words)).named(&"it")])]))
	ui.motion.by_hand = true
	await _a_frame_passes()
	var area: Area = made.ui.node_named(&"it")
	return [made, area, area.find_children("*", "TextEdit", true, false)[0], words]


## The wheel turned down over this control.
func _wheel_over(over: Control) -> void:
	# the wheel going down and coming up, as a mouse sends it
	for pressed: bool in [true, false]:
		var wheel := InputEventMouseButton.new()
		wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
		wheel.pressed = pressed
		wheel.position = over.get_global_rect().get_center()
		root.push_input(wheel)
	await _a_frame_passes()


## More lines than it shows: the wheel lights the mark, in the right of the
## area's padding; fewer, and the wheel shows nothing. Either way the
## engine's own bar takes no room from the words.
func _a_text_area_shows_where_the_reader_is_only_when_it_holds_more_than_it_shows() -> void:
	var long := await _written(40)
	var edit: TextEdit = long[2]
	var indicator := _indicator_of(edit)
	await _wheel_over(edit)
	var mark := indicator.get_mark()
	var padding := edit.get_theme_stylebox(&"normal").get_margin(SIDE_RIGHT)
	_verdict.check(edit.get_v_scroll_bar().value > 0.0 and indicator.get_opacity() == 1.0, "more lines than it shows, the wheel moves the words and lights the mark: %.1f, %.2f" % [edit.get_v_scroll_bar().value, indicator.get_opacity()])
	_verdict.check(mark.position.x >= edit.size.x - padding and mark.end.x <= edit.size.x, "it stands in the right of the area's padding: %s in %.1f less %.1f" % [mark, edit.size.x, padding])
	_verdict.check(edit.get_v_scroll_bar().get_combined_minimum_size().x == 0.0, "the engine's own bar takes no room: %.1f wide" % edit.get_v_scroll_bar().get_combined_minimum_size().x)
	(long[3] as Words).free()
	(long[0] as Fixture).done()
	var short := await _written(2)
	await _wheel_over(short[2])
	_verdict.check(_indicator_of(short[2]).get_opacity() == 0.0, "fewer lines than it shows, the wheel shows nothing")
	(short[3] as Words).free()
	(short[0] as Fixture).done()


## A look setting the ScrollIndicator's thickness draws both a list's and
## an area's by it; a look giving the engine's bars a wide strip moves nothing.
func _the_look_s_scroll_indicator_alone_says_how_both_look_and_the_engine_s_bars_say_nothing() -> void:
	root.theme.set_constant(&"thickness", ScrollIndicator.TYPE, 6)
	var wide := StyleBoxFlat.new()
	wide.content_margin_left = 30.0
	wide.content_margin_right = 30.0
	root.theme.set_stylebox(&"scroll", &"VScrollBar", wide)
	var room := await _room_either_side(200)
	var made := await _listed(200)
	var listed := _indicator_of(made.ui.node_named(&"scroll")).get_mark().size.x
	made.done()
	var written := await _written(40)
	var edit: TextEdit = written[2]
	var in_area := _indicator_of(edit).get_mark().size.x
	var bar := edit.get_v_scroll_bar().get_combined_minimum_size().x
	(written[3] as Words).free()
	(written[0] as Fixture).done()
	root.theme.set_constant(&"thickness", ScrollIndicator.TYPE, 4)
	root.theme.clear_stylebox(&"scroll", &"VScrollBar")
	_verdict.check(listed == 6.0 and in_area == 6.0, "the look's thickness is both marks': %.1f and %.1f" % [listed, in_area])
	_verdict.check(absf(room[0] - room[1]) < 1.0 and bar == 0.0, "the engine's bars made wide move nothing: room %s, the area's bar %.1f wide" % [room, bar])


## Every look in the gallery: the mark's thickness and inset fit inside the
## right padding of a scroll and of a text area, so it is never over words.
func _in_every_look_it_fits_in_the_padding_it_stands_in() -> void:
	var over: Array[String] = []
	# every look the gallery has, and the room its mark needs against the room each box keeps
	for named: StringName in Looks.NAMES:
		var look := Looks.make(named)
		var needs := look.get_constant(&"thickness", ScrollIndicator.TYPE) + look.get_constant(&"inset", ScrollIndicator.TYPE)
		var scroll := look.get_stylebox(&"panel", &"Scroll").get_margin(SIDE_RIGHT)
		var area := look.get_stylebox(&"normal", Fields.TEXT_AREA).get_margin(SIDE_RIGHT)
		if needs > scroll or needs > area:
			over.append("%s needs %d, a scroll keeps %.1f, a text area %.1f" % [named, needs, scroll, area])
	_verdict.check(over.is_empty(), "in every look the mark fits in the padding: %s" % [over])
