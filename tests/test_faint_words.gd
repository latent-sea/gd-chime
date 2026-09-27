extends SceneTree

const Faint := preload("res://addons/gd_chime/faint_words.gd")
const PaintedBox := preload("res://addons/gd_chime/painted_box.gd")
const Paint := preload("res://addons/gd_chime/paint.gd")
const Surface := preload("res://addons/gd_chime/components/primitives/surface.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Verdict := preload("res://tests/verdict.gd")

## What must be true of every set of words: they stand out from the ground
## they are drawn on, by the ratio WCAG asks of them.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_faint_words.gd
##
## The rule (faint_words.gd) over trees built here by hand, where every ink
## and every ground is known: the ratio is WCAG's, black on white 21 to 1
## and a colour on itself 1 to 1; pale ink on a pale ground is named with
## both colours and the ratio it makes; large words owe less; the ground is
## the nearest one that fills, and a box that only paints lets the one
## behind it through; an ink part clear is judged as it is drawn; and words
## switched off are drawn faint on purpose and are not judged. Every
## application's own arrangement is judged by its probe (hands.gd), in the
## look it wears, as its claim words_stand_out.

## A control that says what it is drawn in, as a face does (face.gd): the
## boxes it draws over the whole of itself, in the order it draws them.
class Drawn extends Control:
	var boxes: Array[StyleBox] = []

	func get_drawn() -> Array[StyleBox]:
		return boxes


## A window big enough that nothing here is at its edge.
const ROOM := Vector2(2000.0, 2000.0)
## The form's own two colours: skeuomorphic's "lit" ink and its paper.
const LIT := Color("#e8dcc0")
const PAPER := Color("#f5ecd6")

var _verdict := Verdict.new()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	await _verdict.states(_the_ratio_is_wcags_own)
	await _verdict.states(_pale_ink_on_a_pale_ground_is_named_with_both_and_its_ratio)
	await _verdict.states(_large_words_owe_less_than_small_ones)
	await _verdict.states(_the_ground_is_the_nearest_that_fills_and_a_painted_box_lets_the_one_behind_through)
	await _verdict.states(_an_ink_part_clear_is_judged_as_it_is_drawn)
	await _verdict.states(_words_on_a_press_stand_on_the_box_it_is_drawn_in)
	await _verdict.states(_words_switched_off_are_faint_on_purpose)
	quit(_verdict.deliver(get_script()))


## A holder in the tree, since nothing has a rect until it is in one.
func _holder() -> Control:
	var holder := Control.new()
	holder.size = ROOM
	root.add_child(holder)
	return holder


## A ground of this colour, for words to stand on.
func _ground(holder: Node, fill: Color) -> ColorRect:
	var ground := ColorRect.new()
	ground.color = fill
	ground.size = ROOM
	holder.add_child(ground)
	return ground


## Words of this ink, at this size in base pixels.
func _words(holder: Node, said: String, ink: Color, size: int = 16) -> Label:
	var label := Label.new()
	label.text = said
	label.size = Vector2(400.0, 40.0)
	label.add_theme_color_override(&"font_color", ink)
	label.add_theme_font_size_override(&"font_size", size)
	holder.add_child(label)
	return label


## A flat box of this colour, as a look's own ground is made.
func _flat(fill: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	return box


func _the_ratio_is_wcags_own() -> void:
	var most := Faint.contrast(Color.BLACK, Color.WHITE)
	_verdict.check(most > 20.9 and most < 21.1, "black on white is 21 to 1, the most any two colours make: %s" % most)
	_verdict.check(is_equal_approx(Faint.contrast(PAPER, PAPER), 1.0), "a colour on itself is 1 to 1, whichever colour it is")
	_verdict.check(is_equal_approx(Faint.contrast(Color.WHITE, Color.BLACK), most), "and which of the two is the ink makes no difference to the ratio")
	var grey := Faint.contrast(Color("#767676"), Color.WHITE)
	_verdict.check(grey >= Faint.LEAST and grey < Faint.LEAST + 0.1, "the greyest ink that stands out on white is about the least itself: %s" % grey)
	var blue := Faint.contrast(Color.BLUE, Color.WHITE)
	var green := Faint.contrast(Color.GREEN, Color.WHITE)
	_verdict.check(blue > 8.5 and blue < 8.7 and green > 1.3 and green < 1.4, "and light is weighed as the eye weighs it, never channel for channel: pure blue on white is 8.6 to 1 and pure green 1.4, where an even weighing would make both 2.7: %s and %s" % [blue, green])


## The form's own defect, built here: skeuomorphic's light tan status ink,
## chosen for the dark leather, drawn on the pale paper of a surface's box.
func _pale_ink_on_a_pale_ground_is_named_with_both_and_its_ratio() -> void:
	var holder := _holder()
	var paper := _ground(holder, PAPER)
	_words(paper, "Every answer is in the draft", LIT)
	var found := Faint.faint(holder)
	_verdict.check(found.size() == 1 and found[0].contains('"Every answer is in the draft"') and found[0].contains(LIT.to_html(false)) and found[0].contains(PAPER.to_html(false)), "pale ink on a pale ground is named, with the ink and the ground: %s" % [found])
	_verdict.check(found[0].contains("1.2 to 1") and found[0].contains("4.5 to 1 it owes"), "with the ratio they make and the least they owed: %s" % found[0])
	paper.color = Color("#3a2a18")
	_verdict.check(Faint.faint(holder).is_empty(), "and the same words on the leather the ink was chosen for are nothing to report")
	holder.free()


func _large_words_owe_less_than_small_ones() -> void:
	var holder := _holder()
	var white := _ground(holder, Color.WHITE)
	var words := _words(white, "in the draft", Color("#949494"))
	var found := Faint.faint(holder)
	_verdict.check(found.size() == 1 and found[0].contains("4.5 to 1 it owes"), "small words owe 4.5 to 1: %s" % [found])
	words.add_theme_font_size_override(&"font_size", Faint.LARGE)
	_verdict.check(Faint.faint(holder).is_empty(), "the same ink in words read at a glance owes 3 to 1 and makes it")
	words.add_theme_color_override(&"font_color", Color("#c8c8c8"))
	var paler := Faint.faint(holder)
	_verdict.check(paler.size() == 1 and paler[0].contains("3.0 to 1 it owes"), "and large words paler still are named against the 3 to 1 they owe: %s" % [paler])
	holder.free()


## A box of layers fills with the layers that fill; one that only paints -
## a bevel, a rule - fills nothing, so what the words are read against is
## the ground behind it, which is what the eye sees through it too.
func _the_ground_is_the_nearest_that_fills_and_a_painted_box_lets_the_one_behind_through() -> void:
	var holder := _holder()
	var dark := _ground(holder, Color("#101010"))
	# a surface spreads over what holds it by its own anchors: given a size here it would be overridden, and the engine says so
	var near := Surface.new(&"Pane")
	dark.add_child(near)
	_words(near, "the day's takings", Color("#f0f0f0"))
	near.add_theme_stylebox_override(&"panel", PaintedBox.new([[_flat(PAPER), Vector2.ZERO]], root.theme))
	await process_frame
	var found := Faint.faint(holder)
	_verdict.check(found.size() == 1 and found[0].contains(PAPER.to_html(false)), "the nearest ground that fills is the one the words are read against, not the one behind it: %s" % [found])
	near.add_theme_stylebox_override(&"panel", PaintedBox.new([Paint.rule(&"ink", 2.0)], root.theme))
	await process_frame
	_verdict.check(Faint.faint(holder).is_empty(), "and a box that only paints fills nothing, so the dark ground behind it is what they stand on")
	# a link's box: a rule under its words and no ground at all, however the look coloured the fill it does not draw
	var ruled := _flat(PAPER)
	ruled.draw_center = false
	near.add_theme_stylebox_override(&"panel", ruled)
	await process_frame
	_verdict.check(Faint.faint(holder).is_empty(), "and a box told not to draw its centre fills nothing either, whatever colour it carries: %s" % [Faint.faint(holder)])
	# a look marks a press by layering a bar over the box it already made: a box of boxes, which fills by what they fill
	near.add_theme_stylebox_override(&"panel", PaintedBox.new([[PaintedBox.new([[_flat(PAPER), Vector2.ZERO]], root.theme), Vector2.ZERO], Paint.rule(&"ink", 2.0)], root.theme))
	await process_frame
	var layered := Faint.faint(holder)
	_verdict.check(layered.size() == 1 and layered[0].contains(PAPER.to_html(false)), "and a box laid inside another fills with its own, so a marked press is not read as the pane behind it: %s" % [layered])
	holder.free()


## An ink given part of an alpha is thinned by whatever it is drawn on, so
## it is laid over its ground before it is judged.
func _an_ink_part_clear_is_judged_as_it_is_drawn() -> void:
	var holder := _holder()
	var white := _ground(holder, Color.WHITE)
	var words := _words(white, "half a note", Color.BLACK)
	_verdict.check(Faint.faint(holder).is_empty(), "black on white is as clear as words get")
	words.add_theme_color_override(&"font_color", Color(0.0, 0.0, 0.0, 0.2))
	var found := Faint.faint(holder)
	_verdict.check(found.size() == 1 and not found[0].contains("000000"), "the same ink a fifth there is nearly the white it is drawn on, and is judged as the colour it becomes: %s" % [found])
	holder.free()


## A press is drawn in a box of its own for the state it is in, and its
## words stand on THAT - an index-card divider on a dark desk, its name in
## the desk's own dark ink, reads because the card is pale.
func _words_on_a_press_stand_on_the_box_it_is_drawn_in() -> void:
	var holder := _holder()
	var desk := _ground(holder, Color("#5a3d23"))
	var divider := Drawn.new()
	divider.size = ROOM
	divider.boxes = [_flat(Color("#c3ab7f"))]
	desk.add_child(divider)
	_words(divider, "1. Company details", Color("#2b1e13"))
	_verdict.check(Faint.faint(holder).is_empty(), "dark words on a pale card stand out, though the desk the card lies on is as dark as they are: %s" % [Faint.faint(holder)])
	divider.boxes = []
	var found := Faint.faint(holder)
	_verdict.check(found.size() == 1 and found[0].contains("5a3d23"), "take the card away and the same words are read against the desk, which is the fault: %s" % [found])
	holder.free()


func _words_switched_off_are_faint_on_purpose() -> void:
	var holder := _holder()
	var white := _ground(holder, Color.WHITE)
	var faded := Control.new()
	faded.size = ROOM
	white.add_child(faded)
	_words(faded, "send the form", Color("#e0e0e0"))
	_verdict.check(Faint.faint(holder).size() == 1, "words nobody switched off owe their ratio like any other")
	faded.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	_verdict.check(Faint.faint(holder).is_empty(), "switched off, they are drawn faint on purpose - that is how a reader sees they are not for them")
	holder.free()
