extends SceneTree

## What must be true of a slot holding the room of its widest sample: it
## needs that sample's room in its kind of words, each way, whatever what
## it holds shows; what it holds moving never moves the line it stands in;
## what it holds is laid across the whole of its room; and dressed in
## another look, it measures its samples again.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_room_for.gd
##
## Each statement is in the floor's look, the slot described as any app
## describes it (ui.room_for), into a host of a width the statement sets.
## Nothing moves: what is read after a change is what is there.

const Fixture := preload("res://tests/fixture.gd")
const Verdict := preload("res://tests/verdict.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")

## What a clock may say at its widest, and a figure it says now.
const SAMPLES := ["0:00", "RUNNING NOW"]

var _verdict := Verdict.new()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(1200, 600)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_it_needs_its_widest_sample_s_room_in_its_kind_whatever_it_shows)
	await _verdict.states(_what_it_holds_moving_never_moves_the_line_it_stands_in)
	await _verdict.states(_what_it_holds_is_laid_across_the_whole_of_its_room)
	await _verdict.states(_dressed_in_another_look_it_measures_its_samples_again)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## A builder.
func _made() -> Fixture:
	return Fixture.new(root)


## A plain control of this size under the root, for a piece to be built into.
func _host(of: Vector2) -> Control:
	var host := Control.new()
	host.size = of
	root.add_child(host)
	return host


## A label in the Title kind saying these words, under the root, for what they need to be read off.
func _title_needs(words: String) -> Vector2:
	var label := Label.new()
	label.theme_type_variation = Themes.TITLE
	label.text = words
	root.add_child(label)
	var needs := label.get_minimum_size()
	label.free()
	return needs


## The slot of the clock's samples in the Title kind, holding words that read this value.
func _slot(ui: RefCounted, shows: Variant) -> Desc:
	return ui.room_for(ui.text(shows, Themes.TITLE).named(&"shown"), SAMPLES, Themes.TITLE).named(&"slot")


func _it_needs_its_widest_sample_s_room_in_its_kind_whatever_it_shows() -> void:
	var made := _made()
	var model := Fixture.Model.new(made.chimes)
	model.set_value(&"words", "1")
	var host := _host(Vector2(1000, 200))
	made.ui.build(_slot(made.ui, model.of(&"words")), host)
	await _a_frame_passes()
	var slot: Control = made.ui.node_named(&"slot")
	var widest := _title_needs(SAMPLES[0]).max(_title_needs(SAMPLES[1]))
	_verdict.check(widest.x > _title_needs("1").x and slot.get_combined_minimum_size().is_equal_approx(widest), "showing '1', it needs the room of its widest sample, 'RUNNING NOW', in the Title kind: %s of %s" % [slot.get_combined_minimum_size(), widest])
	model.set_value(&"words", "0:01")
	await _a_frame_passes()
	_verdict.check(slot.get_combined_minimum_size().is_equal_approx(widest), "showing '0:01', the same room: %s" % slot.get_combined_minimum_size())
	_verdict.check(slot.preferred_size().is_equal_approx(widest), "and it never wants more than that room: %s" % slot.preferred_size())
	host.free()
	model.free()
	made.done()


func _what_it_holds_moving_never_moves_the_line_it_stands_in() -> void:
	var made := _made()
	var model := Fixture.Model.new(made.chimes)
	model.set_value(&"words", "1")
	var host := _host(Vector2(1000, 200))
	made.ui.build(made.ui.row([_slot(made.ui, model.of(&"words")), made.ui.text("after it", Themes.WORDS).named(&"after")]), host)
	await _a_frame_passes()
	var after: Control = made.ui.node_named(&"after")
	var stood := after.position
	var placed: int = (made.ui.node_named(&"slot").get_parent() as Container).arrange_count
	# every figure the clock may show, from the narrowest to its widest sample
	for shows: String in ["0:00", "12:59", "RUNNING NOW", "1"]:
		model.set_value(&"words", shows)
		await _a_frame_passes()
		_verdict.check(after.position == stood, "showing '%s', what stands after it has not moved: %s, first %s" % [shows, after.position, stood])
	_verdict.check((made.ui.node_named(&"slot").get_parent() as Container).arrange_count == placed, "and the line was never placed again: %s times, first %s" % [(made.ui.node_named(&"slot").get_parent() as Container).arrange_count, placed])
	host.free()
	model.free()
	made.done()


func _what_it_holds_is_laid_across_the_whole_of_its_room() -> void:
	var made := _made()
	var host := _host(Vector2(1000, 200))
	made.ui.build(made.ui.row([_slot(made.ui, "1").grow()]), host)
	await _a_frame_passes()
	var slot: Control = made.ui.node_named(&"slot")
	var shown: Control = made.ui.node_named(&"shown")
	_verdict.check(slot.size.x > slot.get_combined_minimum_size().x and shown.get_rect() == Rect2(Vector2.ZERO, slot.size), "grown past its room, what it holds is laid across the whole of it: %s in %s" % [shown.get_rect(), slot.size])
	host.free()
	made.done()


func _dressed_in_another_look_it_measures_its_samples_again() -> void:
	var made := _made()
	var host := _host(Vector2(1000, 200))
	made.ui.build(_slot(made.ui, "1"), host)
	await _a_frame_passes()
	var slot: Control = made.ui.node_named(&"slot")
	var before := slot.get_combined_minimum_size()
	var larger := Themes.new(Themes.NEUTRAL)
	larger.set_font_size(&"font_size", Themes.TITLE, Themes.SIZES[Themes.TITLE] * 2)
	root.theme = larger
	await _a_frame_passes()
	var widest := _title_needs(SAMPLES[1])
	_verdict.check(slot.get_combined_minimum_size().x > before.x and slot.get_combined_minimum_size().is_equal_approx(widest), "in a look whose Title words are twice the size, it needs its widest sample's room in that look: %s, before %s, the sample %s" % [slot.get_combined_minimum_size(), before, widest])
	root.theme = Themes.new(Themes.NEUTRAL)
	await _a_frame_passes()
	host.free()
	made.done()
