extends SceneTree

const DrawnOver := preload("res://addons/gd_chime/drawn_over.gd")
const Going := preload("res://addons/gd_chime/components/primitives/going.gd")
const Surface := preload("res://addons/gd_chime/components/primitives/surface.gd")
const Sheet := preload("res://addons/gd_chime/components/recipes/sheet.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Paragraph := preload("res://addons/gd_chime/components/primitives/paragraph.gd")
const Belfry := preload("res://addons/gd_chime/belfry.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Verdict := preload("res://tests/verdict.gd")

## What must be true of what the reader is meant to read or press: nothing
## else is ever drawn over it.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_nothing_drawn_over.gd
##
## The rule (drawn_over.gd) over trees built here by hand, where every rect
## is known: words drawn over words are named with both and the pixels, and
## words beside words are not; what holds a thing is not drawn over it; a
## ground laid over words covers them, but words standing on a ground do
## not; what lies beneath a shade is beneath it on purpose; what is switched
## off under a pop-up is not judged; a thing hidden, faded out, going or
## clipped away is not drawn; and the engine's order - by z, then as the tree
## is walked - decides which of two is over the other; and a paragraph's
## words, drawn with no label, are judged as words are. Every arrangement is
## judged by the stalls probe (probe.gd), at every shape, as its claim
## nothing_drawn_over.

## A window big enough that nothing in these trees reaches its edge by accident.
const ROOM := Rect2(0.0, 0.0, 4000.0, 4000.0)

var _verdict := Verdict.new()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	await _verdict.states(_words_drawn_over_words_are_named_with_both_and_the_pixels)
	await _verdict.states(_what_holds_a_thing_is_not_drawn_over_it)
	await _verdict.states(_a_ground_laid_over_words_covers_them_and_words_on_a_ground_do_not)
	await _verdict.states(_what_lies_beneath_a_shade_is_beneath_it_on_purpose)
	await _verdict.states(_what_is_switched_off_under_a_pop_up_is_not_judged)
	await _verdict.states(_hidden_faded_going_or_clipped_away_is_not_drawn)
	await _verdict.states(_the_engine_s_order_decides_which_is_over)
	await _verdict.states(_a_paragraph_s_words_are_judged_as_words_are)
	quit(_verdict.deliver(get_script()))


## A holder in the tree, since nothing has a rect until it is in one.
func _holder() -> Control:
	var holder := Control.new()
	holder.size = ROOM.size
	root.add_child(holder)
	return holder


## One label of these words, put here with this much room.
func _words(holder: Node, words: String, at: Vector2, room: Vector2) -> Label:
	var label := Label.new()
	label.text = words
	label.position = at
	label.size = room
	holder.add_child(label)
	return label


## A colour rect drawn here, as a ground.
func _ground(holder: Node, at: Vector2, room: Vector2) -> ColorRect:
	var ground := ColorRect.new()
	ground.color = Color.BLACK
	ground.position = at
	ground.size = room
	holder.add_child(ground)
	return ground


func _words_drawn_over_words_are_named_with_both_and_the_pixels() -> void:
	var holder := _holder()
	_words(holder, "put on the stall", Vector2(10.0, 10.0), Vector2(200.0, 40.0))
	var over := _words(holder, "lists of crates", Vector2(150.0, 30.0), Vector2(200.0, 40.0))
	var found := DrawnOver.covered(holder, ROOM)
	_verdict.check(found.size() == 1 and found[0].contains('"put on the stall"') and found[0].contains('"lists of crates"'), "words drawn over words are named, both of them: %s" % [found])
	_verdict.check(found[0].contains("60 by 20 pixels"), "with how much of them meets: %s" % found[0])
	over.position = Vector2(250.0, 10.0)
	_verdict.check(DrawnOver.covered(holder, ROOM).is_empty(), "and the same words beside them are nothing")
	holder.free()


func _what_holds_a_thing_is_not_drawn_over_it() -> void:
	var holder := _holder()
	var button := Button.new()
	button.position = Vector2(10.0, 10.0)
	button.size = Vector2(200.0, 60.0)
	holder.add_child(button)
	_words(button, "open", Vector2(10.0, 10.0), Vector2(100.0, 40.0))
	_verdict.check(DrawnOver.covered(holder, ROOM).is_empty(), "words on their button are not drawn over by it, nor it by them")
	holder.free()


func _a_ground_laid_over_words_covers_them_and_words_on_a_ground_do_not() -> void:
	var holder := _holder()
	_words(holder, "apple", Vector2(10.0, 10.0), Vector2(100.0, 40.0))
	_ground(holder, Vector2(0.0, 30.0), Vector2(300.0, 100.0))
	var found := DrawnOver.covered(holder, ROOM)
	_verdict.check(found.size() == 1 and found[0].contains('"apple"'), "a ground laid over words covers them: %s" % [found])
	holder.move_child(holder.get_child(1), 0)
	_verdict.check(DrawnOver.covered(holder, ROOM).is_empty(), "and the same words drawn after it stand on it, which is what a ground is for")
	holder.free()


## The app's words, then a sheet over everything: its shade, and the
## question standing on it right over them.
func _what_lies_beneath_a_shade_is_beneath_it_on_purpose() -> void:
	var holder := _holder()
	_words(holder, "the day's takings", Vector2(10.0, 10.0), Vector2(300.0, 40.0))
	var shade: Surface = Surface.new(Sheet.SHADE)
	holder.add_child(shade)
	_words(holder, "throw away the day?", Vector2(10.0, 10.0), Vector2(300.0, 40.0))
	await process_frame
	_verdict.check(DrawnOver.covered(holder, ROOM).is_empty(), "beneath a shade - known by what it was described as, whatever the look wears - the app's words are covered on purpose, by the shade and what stands on it")
	holder.remove_child(shade)
	shade.free()
	_verdict.check(DrawnOver.covered(holder, ROOM).size() == 1, "and with no shade the question drawn over them is a fault")
	holder.free()


func _what_is_switched_off_under_a_pop_up_is_not_judged() -> void:
	var holder := _holder()
	var app := Control.new()
	app.size = ROOM.size
	holder.add_child(app)
	_words(app, "sort by name", Vector2(10.0, 10.0), Vector2(200.0, 40.0))
	_words(holder, "pick a pace", Vector2(10.0, 10.0), Vector2(200.0, 40.0))
	_verdict.check(DrawnOver.covered(holder, ROOM).size() == 1, "while the app takes input, words over its words are a fault")
	app.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	_verdict.check(DrawnOver.covered(holder, ROOM).is_empty(), "switched off under a pop-up, it is not there to be read, and nothing over it is judged")
	holder.free()


func _hidden_faded_going_or_clipped_away_is_not_drawn() -> void:
	var holder := _holder()
	_words(holder, "apple", Vector2(10.0, 10.0), Vector2(100.0, 40.0))
	var over := _words(holder, "pear", Vector2(10.0, 10.0), Vector2(100.0, 40.0))
	over.visible = false
	_verdict.check(DrawnOver.covered(holder, ROOM).is_empty(), "words hidden are drawn over nothing")
	over.visible = true
	over.modulate.a = 0.0
	_verdict.check(DrawnOver.covered(holder, ROOM).is_empty(), "nor faded to nothing")
	over.modulate.a = 1.0
	Going.mark(over)
	_verdict.check(DrawnOver.covered(holder, ROOM).is_empty(), "nor going")
	holder.remove_child(over)
	over.free()
	var room := Control.new()
	room.position = Vector2(200.0, 0.0)
	room.size = Vector2(100.0, 100.0)
	room.clip_contents = true
	holder.add_child(room)
	_words(room, "plum", Vector2(-190.0, 10.0), Vector2(100.0, 40.0))
	_verdict.check(DrawnOver.covered(holder, ROOM).is_empty(), "nor what the parent that holds it clips away")
	room.clip_contents = false
	_verdict.check(DrawnOver.covered(holder, ROOM).size() == 1, "and the same words unclipped are drawn over the others")
	holder.free()


func _the_engine_s_order_decides_which_is_over() -> void:
	var holder := _holder()
	var first := _words(holder, "first", Vector2(10.0, 10.0), Vector2(100.0, 40.0))
	_words(holder, "second", Vector2(10.0, 10.0), Vector2(100.0, 40.0))
	_verdict.check(DrawnOver.covered(holder, ROOM)[0].begins_with('"first"'), "walked in order, the later is drawn over the earlier: %s" % [DrawnOver.covered(holder, ROOM)])
	first.z_index = 1
	_verdict.check(DrawnOver.covered(holder, ROOM)[0].begins_with('"second"'), "raised by z, the earlier is drawn over the later: %s" % [DrawnOver.covered(holder, ROOM)])
	holder.free()


## A paragraph draws its own words, with no label for them: a label laid
## over it covers them all the same.
func _a_paragraph_s_words_are_judged_as_words_are() -> void:
	var holder := _holder()
	var chimes := Chimes.new(Belfry.new())
	var paragraph := Paragraph.new(chimes, ["crates of pears and plums, sold by the stall"], Themes.PARAGRAPH, Chimes.GLOBAL)
	paragraph.position = Vector2(10.0, 10.0)
	paragraph.size = Vector2(300.0, 10.0)
	holder.add_child(paragraph)
	await process_frame
	await process_frame
	_verdict.check(DrawnOver.covered(holder, ROOM).is_empty(), "a paragraph alone covers nothing and is covered by nothing")
	var over := _words(holder, "lists of crates", Vector2(40.0, 20.0), Vector2(200.0, 30.0))
	var found := DrawnOver.covered(holder, ROOM)
	_verdict.check(found.size() == 1 and found[0].contains(String(paragraph.get_path())) and found[0].contains('"lists of crates"'), "words laid over a paragraph's words are named, the paragraph and what covers it: %s" % [found])
	over.position = Vector2(10.0, paragraph.size.y + 20.0)
	_verdict.check(DrawnOver.covered(holder, ROOM).is_empty(), "and the same words under it are nothing")
	holder.free()
