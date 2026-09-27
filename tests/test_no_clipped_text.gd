extends SceneTree

const Clipped := preload("res://addons/gd_chime/clipped_text.gd")
const Going := preload("res://addons/gd_chime/components/primitives/going.gd")
const Paragraph := preload("res://addons/gd_chime/components/primitives/paragraph.gd")
const Belfry := preload("res://addons/gd_chime/belfry.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Verdict := preload("res://tests/verdict.gd")

## What must be true of the words on every screen: none of them is cut off.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_no_clipped_text.gd
##
## TEXT CUT OFF AT AN EDGE IS A BROKEN RENDER. The rule has two halves, and
## both are needed: the rule alone could be right about nothing, and the
## arrangements alone could be green because the rule sees nothing.
##
## This is the first half: it states the rule (clipped_text.gd) over trees built here by
## hand, where every rect is known: words reaching past the window are named
## with the words and the pixels, words inside it are not; a label is never
## smaller than its words, which is the engine's fact the rule stands on; a
## parent that clips is named as what cut them - a strip too, for words
## half past its edge; words scrolled wholly out of view are not a fault and words hidden or going are not drawn at all - and a
## label told to cut its own words short is reported, because shortening the
## words is never this framework's answer to a box too small. A paragraph,
## which draws its own words with no label, is judged by the lines it laid:
## a line past the window is cut, and a line past its own box needed more
## room than it was given.
##
## The second half is not here: every arrangement - the gallery, the stall
## demos and the applications - walks every place, pop-up and the moment at
## 1920x1080, 1280x800 and 720x1280 under its own --probe (probe.gd), whose
## no_clipped_text claim fails the demo, and checks/stalls_probe.py runs
## them all. It is the slow half - a process per demo - so it runs with the
## probes, never among these quick unit tests, and once.
##
## EVERY SHAPE IS REQUIRED TO BE CLEAN - the base, the Steam Deck's, and a
## window on its end - as was ruled: a count of cut words on one of
## them would be a number nobody has to act on.

## A window big enough that nothing in these trees reaches its edge by accident.
const ROOM := Rect2(0.0, 0.0, 4000.0, 4000.0)

var _verdict := Verdict.new()


func _init() -> void:
	await process_frame
	await _verdict.states(_words_reaching_past_the_window_are_named_with_the_words_and_the_pixels)
	await _verdict.states(_a_label_is_never_smaller_than_its_words_so_its_box_is_where_they_are_drawn)
	await _verdict.states(_a_parent_that_clips_is_named_as_what_cut_them)
	await _verdict.states(_words_scrolled_out_of_view_hidden_or_going_are_not_faults)
	await _verdict.states(_words_told_to_cut_themselves_short_are_reported)
	await _verdict.states(_a_paragraph_is_judged_by_the_lines_it_laid)
	await _verdict.states(_in_a_list_words_cut_where_it_can_still_scroll_are_spared_and_where_it_cannot_are_named)
	await _verdict.states(_in_a_scroll_inside_a_scroll_words_the_outer_can_bring_in_are_spared)
	quit(_verdict.deliver(get_script()))


## A holder in the tree, since a label measures nothing until it is in one.
func _holder() -> Control:
	var holder := Control.new()
	holder.size = Vector2(4000.0, 4000.0)
	root.add_child(holder)
	return holder


## One label of these words, put at this place with this much room.
func _put(holder: Control, words: String, at: Vector2, room: Vector2) -> Label:
	var label := Label.new()
	label.text = words
	label.position = at
	label.size = room
	holder.add_child(label)
	return label


func _words_reaching_past_the_window_are_named_with_the_words_and_the_pixels() -> void:
	var holder := _holder()
	_put(holder, "there is nothing to go back to", Vector2(300.0, 10.0), Vector2(400.0, 40.0))
	_put(holder, "way back", Vector2(10.0, 10.0), Vector2(200.0, 40.0))
	var found := Clipped.clipped(holder, Rect2(0.0, 0.0, 400.0, 400.0))
	_verdict.check(found.size() == 1, "only the words that reach past the window are named, not the ones inside it: %s" % [found])
	_verdict.check(found[0].contains('"there is nothing to go back to"'), "the sentence says which words: %s" % found[0])
	_verdict.check(found[0].contains("300 pixels past the right of the window"), "and how far past which side of what: %s" % found[0])
	holder.free()


func _a_label_is_never_smaller_than_its_words_so_its_box_is_where_they_are_drawn() -> void:
	var holder := _holder()
	var label := _put(holder, "there is nothing here to go back to at all", Vector2(10.0, 10.0), Vector2(20.0, 10.0))
	_verdict.check(label.size.x > 20.0 and label.size.x >= label.get_minimum_size().x, "a label asked to be narrower than its line of words keeps the width of the line: %s" % label.size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# what a wrapping label needs is worked out again a frame on, and its lines as it is next drawn
	await process_frame
	label.size = Vector2(90.0, 10.0)
	await process_frame
	await process_frame
	_verdict.check(label.get_line_count() > 1 and label.get_visible_line_count() == label.get_line_count(), "and one that wraps, asked to be too short, is as tall as every line it wraps into: %d of %d shown in %s" % [label.get_visible_line_count(), label.get_line_count(), label.size])
	_verdict.check(Clipped.clipped(holder, ROOM).is_empty(), "so words whose box stands inside the window are never named, however little room was asked for them")
	holder.free()


func _a_parent_that_clips_is_named_as_what_cut_them() -> void:
	var holder := _holder()
	var room := Control.new()
	room.size = Vector2(200.0, 100.0)
	room.clip_contents = true
	holder.add_child(room)
	_put(room, "pick a crate", Vector2(150.0, 10.0), Vector2(200.0, 40.0))
	var found := Clipped.clipped(holder, ROOM)
	_verdict.check(found.size() == 1 and found[0].contains("150 pixels past the right of %s" % room.get_path()), "words cut by a parent that clips name that parent, not the window: %s" % [found])
	room.clip_contents = false
	_verdict.check(Clipped.clipped(holder, ROOM).is_empty(), "and the same words in a parent that does not clip are whole")
	holder.free()


func _words_scrolled_out_of_view_hidden_or_going_are_not_faults() -> void:
	var holder := _holder()
	var scroll := ScrollContainer.new()
	scroll.size = Vector2(200.0, 100.0)
	# a strip: a scroll across alone, as tab_bar.gd's is
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	holder.add_child(scroll)
	var far := _put(scroll, "ranked by takings, your own kept in view", Vector2(250.0, 0.0), Vector2(600.0, 40.0))
	var window := Rect2(0.0, 0.0, 150.0, 150.0)
	_verdict.check(Clipped.clipped(holder, window).is_empty(), "words wholly out of view inside a scroll are scrolled away, not cut off")
	var split := _put(scroll, "crate vs crate", Vector2(120.0, 50.0), Vector2(10.0, 30.0))
	var found := Clipped.clipped(holder, ROOM)
	_verdict.check(found.size() == 1 and found[0].contains('"crate vs crate"') and found[0].contains("past the right of %s" % scroll.get_path()), "but words half past the edge of a scroll across are cut by it, and named with the scroll: %s" % [found])
	split.free()
	# a lane of a board: a scroll down the strip holds, wholly past its edge
	var lane := ScrollContainer.new()
	lane.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	lane.position = Vector2(260.0, 0.0)
	lane.size = Vector2(120.0, 100.0)
	scroll.add_child(lane)
	_put(lane, "a card", Vector2.ZERO, Vector2(80.0, 30.0))
	_verdict.check(Clipped.clipped(holder, window).is_empty(), "and so are words in a scroll down that the strip holds, wholly out of view with it: %s" % [Clipped.clipped(holder, window)])
	lane.position = Vector2(170.0, 0.0)
	_verdict.check(Clipped.clipped(holder, ROOM).size() == 1, "but half past the strip's edge they are cut: %s" % [Clipped.clipped(holder, ROOM)])
	lane.free()
	scroll.remove_child(far)
	holder.add_child(far)
	_verdict.check(Clipped.clipped(holder, window).size() == 1, "and the same words in the same place outside a scroll are named, so it is the scroll that spares them")
	far.visible = false
	_verdict.check(Clipped.clipped(holder, window).is_empty(), "a label hidden is drawn by nobody and judged by nobody")
	far.visible = true
	Going.mark(far)
	_verdict.check(Clipped.clipped(holder, window).is_empty(), "and a label going is on its way out, laid out by nobody and judged by nobody")
	holder.free()


## A list running down, taller than its room: the row half past its foot
## is spared while the list can still move down to bring it in, and so is
## the one half past its head once it has moved; words cut across it, where
## it cannot move across, are named, and spared once it can.
func _in_a_list_words_cut_where_it_can_still_scroll_are_spared_and_where_it_cannot_are_named() -> void:
	var holder := _holder()
	# the list's room, which a list that cannot move across grows past rather than cutting
	var frame := Control.new()
	frame.size = Vector2(300.0, 115.0)
	frame.clip_contents = true
	holder.add_child(frame)
	var scroll := ScrollContainer.new()
	# a room whose foot falls part way through a row, with or without the rows' own separation
	scroll.size = Vector2(300.0, 115.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	frame.add_child(scroll)
	var rows := VBoxContainer.new()
	scroll.add_child(rows)
	# twelve rows of words, far taller than the room, one row about every 30 pixels
	for at: int in 12:
		var row := Label.new()
		row.text = "row number %d" % at
		row.custom_minimum_size = Vector2(0.0, 30.0)
		rows.add_child(row)
	await process_frame
	await process_frame
	var cut_at_foot: Array = rows.get_children().filter(func(row: Control) -> bool: return row.get_global_rect().position.y < 115.0 and row.get_global_rect().end.y > 115.0)
	_verdict.check(not cut_at_foot.is_empty() and Clipped.clipped(holder, ROOM).is_empty(), "a row half past the foot of a list that can still move down is spared: %s" % [cut_at_foot.map(func(row: Label) -> String: return row.text)])
	scroll.scroll_vertical = 100000
	await process_frame
	await process_frame
	_verdict.check(Clipped.clipped(holder, ROOM).is_empty(), "moved as far down as it goes, the row half past its head is spared, since it can move back up")
	var wide := Label.new()
	wide.text = "a line of words far wider than the list is, which it cannot move across to show"
	rows.add_child(wide)
	await process_frame
	await process_frame
	var found := Clipped.clipped(holder, ROOM)
	_verdict.check(found.any(func(said: String) -> bool: return said.contains('"a line of words far wider') and said.contains("past the right")), "words cut across a list that cannot move across are named: %s" % [found.slice(0, 2)])
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size = Vector2(300.0, 115.0)
	await process_frame
	await process_frame
	_verdict.check(Clipped.clipped(holder, ROOM).is_empty(), "and spared once it can move across to bring them in: %s" % [Clipped.clipped(holder, ROOM)])
	holder.free()


## A scroll inside a scroll - a tray's own, in a page shorter than the tray:
## words cut at the page's foot, while the page can move down, are spared
## though the tray's own scroll cannot move at all; words cut by a box of
## their own, whose edge no scroll can move past, are still named.
func _in_a_scroll_inside_a_scroll_words_the_outer_can_bring_in_are_spared() -> void:
	var holder := _holder()
	var page := ScrollContainer.new()
	page.size = Vector2(300.0, 85.0)
	page.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	holder.add_child(page)
	# the tray: a scroll of its own, as tall as what it holds, so it cannot move
	var tray := ScrollContainer.new()
	tray.custom_minimum_size = Vector2(0.0, 240.0)
	tray.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(tray)
	var rows := VBoxContainer.new()
	tray.add_child(rows)
	# five rows of 30 pixels and their separation, the third crossing the page's foot at 85
	for at: int in 5:
		var row := Label.new()
		row.text = "notice number %d" % at
		row.custom_minimum_size = Vector2(0.0, 30.0)
		rows.add_child(row)
	await process_frame
	await process_frame
	var cut: Array = rows.get_children().filter(func(row: Control) -> bool: return row.get_global_rect().position.y < 85.0 and row.get_global_rect().end.y > 85.0)
	_verdict.check(not cut.is_empty() and tray.get_v_scroll_bar().max_value <= tray.get_v_scroll_bar().page + 0.5 and Clipped.clipped(holder, ROOM).is_empty(), "words cut at the foot of a page that can still move down are spared, though the scroll they stand in cannot move: %s, %s" % [cut.map(func(row: Label) -> String: return row.text), Clipped.clipped(holder, ROOM)])
	# a box in the tray that clips, shorter than the words it holds, its foot nowhere near the page's
	var box := Control.new()
	box.custom_minimum_size = Vector2(0.0, 12.0)
	box.clip_contents = true
	rows.add_child(box)
	rows.move_child(box, 0)
	_put(box, "cut by its own box", Vector2.ZERO, Vector2(60.0, 30.0))
	await process_frame
	await process_frame
	var found := Clipped.clipped(holder, ROOM)
	_verdict.check(found.any(func(said: String) -> bool: return said.contains('"cut by its own box"') and said.contains("past the bottom")), "words cut by a box of their own, where no scroll can move, are still named: %s" % [found])
	holder.free()


func _words_told_to_cut_themselves_short_are_reported() -> void:
	var holder := _holder()
	var label := _put(holder, "there is nothing to go back to", Vector2(10.0, 10.0), Vector2(600.0, 40.0))
	label.clip_text = true
	var found := Clipped.clipped(holder, ROOM)
	_verdict.check(found.size() == 1 and found[0].contains("cut short rather than given room"), "a label set to cut its own words short is reported, room or no room: %s" % [found])
	label.clip_text = false
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_verdict.check(Clipped.clipped(holder, ROOM).size() == 1, "and so is one set to trim them to an ellipsis")
	label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	label.max_lines_visible = 1
	_verdict.check(Clipped.clipped(holder, ROOM).size() == 1, "and so is one set to show only so many of its lines")
	label.max_lines_visible = -1
	_verdict.check(Clipped.clipped(holder, ROOM).is_empty(), "and the same label left to show all of its words is not")
	holder.free()


## A paragraph that says it needs no room at all: the one way its lines can
## outgrow the box it is given, which is the fault the rule is there to see.
class UnderMeasured extends Paragraph:
	func _get_minimum_size() -> Vector2:
		return Vector2.ZERO


func _a_paragraph_is_judged_by_the_lines_it_laid() -> void:
	var holder := _holder()
	var chimes := Chimes.new(Belfry.new())
	var words := "crates of pears and plums, sold by the stall across the way this morning"
	var paragraph := Paragraph.new(chimes, [words], &"", Chimes.GLOBAL)
	paragraph.position = Vector2(10.0, 10.0)
	paragraph.size = Vector2(200.0, 10.0)
	holder.add_child(paragraph)
	await process_frame
	await process_frame
	var window := Rect2(0.0, 0.0, 400.0, 400.0)
	_verdict.check(paragraph.get_lines().size() > 1 and Clipped.clipped(holder, window).is_empty(), "a paragraph wrapped into %d lines within its box and the window is whole" % paragraph.get_lines().size())
	paragraph.position = Vector2(300.0, 10.0)
	var found := Clipped.clipped(holder, window)
	_verdict.check(found.size() == 1 and found[0].contains('"%s"' % words.substr(0, 60)) and found[0].contains("pixels past the right of the window"), "moved so its lines reach past the window, it is named by its words, the pixels and the side: %s" % [found])
	paragraph.free()
	var short := UnderMeasured.new(chimes, [words], &"", Chimes.GLOBAL)
	short.position = Vector2(10.0, 10.0)
	short.size = Vector2(200.0, 10.0)
	holder.add_child(short)
	await process_frame
	await process_frame
	found = Clipped.clipped(holder, window)
	_verdict.check(short.size.y < 30.0 and found.size() == 1 and found[0].contains("needs more room than its box gives"), "one whose lines need more room than its box gives is named, though the window holds them: %s" % [found])
	holder.free()

