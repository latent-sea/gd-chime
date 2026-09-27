extends SceneTree

## What must be true of a gallery: the first picture shows large, claimed at
## a large size and the thumbnails at a small one; a thumbnail pressed by
## the pointer, by Enter or by the pad's accept shows its picture large and
## is drawn selected; the keys walk the row of thumbnails; the step presses
## go round, back from the first to the last and on from the last to the
## first; where it stands is said in words; and the keys moving to another
## thing swap every picture in place.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_gallery.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const FrameBudget := preload("res://addons/gd_chime/frame_budget.gd")
const Jobs := preload("res://addons/gd_chime/jobs.gd")
const ImageLoads := preload("res://addons/gd_chime/image_loads.gd")
const LazyImage := preload("res://addons/gd_chime/components/primitives/lazy_image.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Gallery := preload("res://addons/gd_chime/components/recipes/gallery.gd")
const Verdict := preload("res://tests/verdict.gd")

var _verdict := Verdict.new()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(600, 800)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_the_first_shows_large_at_a_large_size_and_the_thumbnails_small)
	await _verdict.states(_a_thumbnail_pressed_by_pointer_enter_or_pad_shows_large_and_is_selected)
	await _verdict.states(_the_steps_go_round_and_where_it_stands_is_said_in_words)
	await _verdict.states(_another_thing_swaps_every_picture_in_place)
	quit(_verdict.deliver(get_script()))


## A gallery of a thing's four shots: [fixture, the thing, jobs].
func _gallery() -> Array:
	var made := Fixture.new(root)
	var ui := made.ui
	var budget := FrameBudget.new(made.chimes, 1000.0, 0.9, 3)
	var jobs := Jobs.new(made.chimes, budget, 2, 64, false)
	var loads := ImageLoads.new(made.chimes, jobs, func(_key: Variant, _size: int) -> Image: return Image.create_empty(4, 4, false, Image.FORMAT_RGBA8), 4, 8)
	var thing := Fixture.Model.new(made.chimes, &"app")
	thing.set_value(&"items", [&"sofa_0", &"sofa_1", &"sofa_2", &"sofa_3"])
	for model: Node in [budget, jobs, loads, thing]:
		root.add_child(model)
	ui.start(ui.app(&"app", [ui.column([Gallery.make(ui, loads, thing.of(&"items"), {count = 4, sizes = [200, 1000], thumb_sizes = [60, 120]})])]))
	await _frames(3)
	return [made, thing, jobs]


func _frames(count: int) -> void:
	# so many frames, for a press to be carried out and drawn
	for frame: int in count:
		await process_frame


func _pictures() -> Array:
	return root.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is LazyImage)


func _thumbs() -> Array:
	return root.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part.theme_type_variation == Gallery.THUMB)


func _large() -> Array:
	return _pictures()[0].get_claimed()


func _said() -> Array:
	return root.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Text and part.get_text().contains(" of ")).map(func(part: Text) -> String: return part.get_text())


func _done(both: Array) -> void:
	(both[2] as Jobs).stop()
	(both[0] as Fixture).done()


func _the_first_shows_large_at_a_large_size_and_the_thumbnails_small() -> void:
	var both: Array = await _gallery()
	var thumbs_claimed: Array = _pictures().slice(1).map(func(picture: LazyImage) -> Array: return picture.get_claimed())
	_verdict.check(_large() == [&"sofa_0", 1000], "the first picture shows large, claimed at the least size as wide as it is drawn: %s" % [_large()])
	_verdict.check(thumbs_claimed == [[&"sofa_0", 60], [&"sofa_1", 60], [&"sofa_2", 60], [&"sofa_3", 60]] or thumbs_claimed == [[&"sofa_0", 120], [&"sofa_1", 120], [&"sofa_2", 120], [&"sofa_3", 120]], "every thumbnail its own picture, at a thumbnail's size: %s" % [thumbs_claimed])
	_verdict.check(_thumbs()[0].is_selected() and not _thumbs()[1].is_selected(), "the first thumbnail is drawn selected")
	_done(both)


func _a_thumbnail_pressed_by_pointer_enter_or_pad_shows_large_and_is_selected() -> void:
	var both: Array = await _gallery()
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = (_thumbs()[2] as Control).get_global_rect().get_center()
	root.push_input(click)
	var release := click.duplicate()
	release.pressed = false
	root.push_input(release)
	await _frames(2)
	var clicked: Array = _large()
	(_thumbs()[0] as Control).grab_focus()
	var to: Control = (_thumbs()[0] as Control).find_valid_focus_neighbor(SIDE_RIGHT)
	_verdict.check(to == _thumbs()[1], "the keys walk the row, the first thumbnail to the second")
	(_thumbs()[3] as Control).grab_focus()
	var enter := InputEventKey.new()
	enter.keycode = KEY_ENTER
	enter.physical_keycode = KEY_ENTER
	enter.pressed = true
	root.push_input(enter)
	await _frames(2)
	var entered: Array = _large()
	(_thumbs()[1] as Control).grab_focus()
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_A
	pad.pressed = true
	root.push_input(pad)
	await _frames(2)
	_verdict.check(clicked[0] == &"sofa_2" and entered[0] == &"sofa_3" and _large()[0] == &"sofa_1", "the pointer, Enter and the pad's accept each show their thumbnail's picture large: %s %s %s" % [clicked, entered, _large()])
	_verdict.check(_thumbs()[1].is_selected() and not _thumbs()[3].is_selected(), "and the one showing is drawn selected")
	_done(both)


func _the_steps_go_round_and_where_it_stands_is_said_in_words() -> void:
	var both: Array = await _gallery()
	var steps: Array = root.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part.theme_type_variation == Gallery.STEP)
	_verdict.check(_said() == ["1 of 4"], "where it stands is said in words: %s" % [_said()])
	steps[0].pressed()
	await _frames(2)
	_verdict.check(_large()[0] == &"sofa_3" and _said() == ["4 of 4"], "back from the first is the last: %s %s" % [_large(), _said()])
	steps[1].pressed()
	await _frames(2)
	_verdict.check(_large()[0] == &"sofa_0" and _said() == ["1 of 4"], "and on from the last is the first: %s %s" % [_large(), _said()])
	_done(both)


func _another_thing_swaps_every_picture_in_place() -> void:
	var both: Array = await _gallery()
	var before := _pictures()
	(both[1] as Fixture.Model).set_value(&"items", [&"lamp_0", &"lamp_1", &"lamp_2", &"lamp_3"])
	await _frames(2)
	_verdict.check(_pictures() == before and _large()[0] == &"lamp_0" and _pictures()[4].get_claimed()[0] == &"lamp_3", "another thing's shots are shown by the same pictures, in place: %s" % [_large()])
	_done(both)
