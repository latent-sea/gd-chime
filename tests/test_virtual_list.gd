extends SceneTree

## What must be true of a virtual list: slots built once, rebound on scroll.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_virtual_list.gd
##
## One piece per slot the list shows, each reading its row through a
## handle; a scroll is the list's first row moving and every handle
## re-reading, the pieces the same nodes as before; a row not held reads
## null; and the wheel over it scrolls the list by rows.

const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Fixture := preload("res://tests/fixture.gd")
const LongList := preload("res://addons/gd_chime/long_list.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const VirtualList := preload("res://addons/gd_chime/components/primitives/virtual_list.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const FrameBudget := preload("res://addons/gd_chime/frame_budget.gd")
const Jobs := preload("res://addons/gd_chime/jobs.gd")
const PackedRows := preload("res://addons/gd_chime/packed_rows.gd")
const QueriedRows := preload("res://addons/gd_chime/queried_rows.gd")
const RowSelection := preload("res://addons/gd_chime/row_selection.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Verdict := preload("res://tests/verdict.gd")

const SHOWING := 4
const REGION := Chimes.GLOBAL

var _verdict := Verdict.new()


## A source answering every page at once, a row being its number.
class Source extends RefCounted:
	var total: int = 20

	func fetch(first: int, count: int, answer: Callable) -> void:
		var rows: Array = []
		for index: int in range(first, mini(first + count, total)):
			rows.append(index)
		answer.call(rows, total)


func _init() -> void:
	await process_frame
	root.size = Vector2i(400, 400)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_slots_are_built_once_and_rebound_as_the_list_scrolls)
	await _verdict.states(_with_a_cursor_the_keys_and_presses_move_it_and_the_list_follows)
	await _verdict.states(_asked_to_fit_it_shows_as_many_rows_as_its_height_holds)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


func _words(list: VirtualList) -> Array[String]:
	var found: Array[String] = []
	for slot: Node in list.get_slots():
		found.append((slot as Text).get_text())
	return found


func _slots_are_built_once_and_rebound_as_the_list_scrolls() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var source := Source.new()
	var list := LongList.new(made.chimes, source.fetch, 5, 8, SHOWING, Bound.new(func() -> Variant: return null))
	made.commands.stand(REGION, list)
	root.add_child(list)
	var shown: VirtualList = ui.build(ui.virtual_list(list, func(row: Bound) -> Desc: return ui.text(row.map(func(item: Variant) -> String: return "..." if item == null else "row %d" % item))), root)
	await _a_frame_passes()
	_verdict.check(_words(shown) == ["...", "...", "...", "..."] and shown.get_slots().size() == SHOWING, "before the list looks, every slot reads null: %s" % [_words(shown)])
	var slots := shown.get_slots().duplicate()
	list.look(null)
	await _a_frame_passes()
	_verdict.check(_words(shown) == ["row 0", "row 1", "row 2", "row 3"], "the pages landed, every slot reads its row: %s" % [_words(shown)])
	var drawn: Array = slots.map(func(slot: Text) -> int: return slot.refresh_count)
	made.commands.dispatch(REGION, LongList.SCROLL_ROW_DOWN, {})
	await _a_frame_passes()
	var same: bool = shown.get_slots().all(func(slot: Node) -> bool: return slots.has(slot)) and shown.get_slots().size() == slots.size()
	_verdict.check(_words(shown) == ["row 1", "row 2", "row 3", "row 4"] and same, "scrolled a row, the slots read the rows below and no slot was rebuilt: %s" % [_words(shown)])
	var again: Array = range(slots.size()).filter(func(at: int) -> bool: return slots[at].refresh_count != drawn[at])
	_verdict.check(again == [0] and shown.get_slots()[-1] == slots[0], "and only the slot scrolled out of view was told, taken to the bottom for the row coming in: %s" % [again])
	var turn := InputEventMouseButton.new()
	turn.button_index = MOUSE_BUTTON_WHEEL_DOWN
	turn.pressed = true
	turn.position = Vector2(50, 50)
	root.push_input(turn)
	await _a_frame_passes()
	_verdict.check(list.get_first() == 2 and _words(shown)[0] == "row 2", "the wheel over it scrolls the list a row: %d" % list.get_first())
	shown.free()
	list.free()
	made.done()


func _asked_to_fit_it_shows_as_many_rows_as_its_height_holds() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var source := Source.new()
	source.total = 100
	var list := LongList.new(made.chimes, source.fetch, 10, 8, SHOWING, Bound.new(func() -> Variant: return null))
	made.commands.stand(REGION, list)
	root.add_child(list)
	var template := func(row: Bound) -> Desc: return ui.text(row.map(func(item: Variant) -> String: return "..." if item == null else "row %d" % item))
	var shown: VirtualList = ui.build(ui.virtual_list(list, template, &"Column", {}).fits(), root)
	list.look(null)
	await _a_frame_passes()
	var tall := (shown.get_slots()[0] as Control).get_combined_minimum_size().y
	var gap := float(shown.get_slots()[0].get_parent().get_theme_constant(&"gap"))
	var holds := floori((400.0 + gap) / (tall + gap))
	_verdict.check(list.get_showing() == holds and shown.get_slots().size() == holds and holds > SHOWING, "asked to fit 400 pixels of rows %.0f tall, it shows %d and has a slot each: %d, %d" % [tall, holds, list.get_showing(), shown.get_slots().size()])
	_verdict.check(_words(shown)[-1] == "row %d" % (holds - 1), "and the last slot reads its row: %s" % _words(shown)[-1])
	root.size = Vector2i(400, 120)
	await _a_frame_passes()
	var fewer := floori((120.0 + gap) / (tall + gap))
	_verdict.check(list.get_showing() == fewer and shown.get_slots().size() == fewer, "the window shorter, fewer rows and fewer slots: %d, %d" % [list.get_showing(), shown.get_slots().size()])
	made.commands.dispatch(REGION, LongList.SCROLL_ROWS, {"by": 1000})
	_verdict.check(list.get_first() == 100 - fewer, "and the list's end is where the rows it shows fill the screen: %d" % list.get_first())
	root.size = Vector2i(400, 400)
	shown.free()
	list.free()
	made.done()


## A key pressed on whatever has the focus.
func _key(code: Key, shift: bool = false) -> void:
	var key := InputEventKey.new()
	key.keycode = code
	key.shift_pressed = shift
	key.pressed = true
	root.push_input(key)
	await _a_frame_passes()


func _with_a_cursor_the_keys_and_presses_move_it_and_the_list_follows() -> void:
	var made := Fixture.new(root)
	var ui := made.ui
	var rows := PackedRows.new({&"size": PackedRows.NUMBER})
	# fifty rows, each its own number
	for row: int in 50:
		rows.add([float(row)])
	var budget := FrameBudget.new(made.chimes, 16.0, 0.9, 3)
	var pool := Jobs.new(made.chimes, budget, 1, 4, true)
	var view := QueriedRows.new(made.chimes, rows, pool)
	made.commands.stand(REGION, view)
	var picks := RowSelection.new(made.chimes, view, func() -> int: return 1)
	made.commands.stand(REGION, picks)
	# a first key for escape that is refused, nothing being given up, so the second is taken
	var refuser := Fixture.Model.new(made.chimes, &"refusing")
	refuser.refuse(&"gives_up", Phrase.of("nothing to give up"))
	made.commands.register(REGION, &"gives_up", refuser)
	for node: Node in [budget, pool, view, picks, refuser]:
		root.add_child(node)
	var list := LongList.new(made.chimes, view.fetch, 8, 8, SHOWING, Bound.new(view.get_shown))
	made.commands.stand(REGION, list)
	root.add_child(list)
	var keys := [[&"ui_down", false, RowSelection.MOVES, {"by": 1}], [&"ui_down", true, RowSelection.EXTENDS, {"by": 1}], [&"ui_page_down", false, RowSelection.MOVES, {"by": SHOWING}]]
	var cursor := {"at": Bound.new(picks.get_cursor), "keys": keys, "anywhere": [[&"ui_cancel", &"gives_up"], [&"ui_cancel", RowSelection.CLEARS]], "presses": RowSelection.PICKS, "twice": RowSelection.TOGGLES}
	var template := func(row: Bound) -> Desc: return ui.text(row.map(func(item: Variant) -> String: return "..." if item == null else "row %d" % item["id"]))
	var shown: VirtualList = ui.build(ui.virtual_list(list, template, &"Column", cursor), root)
	list.look(null)
	shown.grab_focus()
	await _a_frame_passes()
	_verdict.check(shown.has_focus() and shown.get_slots().all(func(slot: Control) -> bool: return slot.focus_mode == Control.FOCUS_NONE), "given a cursor, the list itself holds the focus, not a slot")
	await _key(KEY_DOWN)
	await _key(KEY_DOWN)
	_verdict.check(picks.get_cursor() == 2 and list.get_first() == 0, "down twice, the cursor is on the third row, still among those shown: %d" % picks.get_cursor())
	await _key(KEY_PAGEDOWN)
	await _key(KEY_PAGEDOWN)
	_verdict.check(picks.get_cursor() == 10 and list.get_first() == 10 - SHOWING + 1 and _words(shown)[-1] == "row 10", "a page down twice, the cursor passes the rows shown and the list follows it, its row last: %s" % [_words(shown)])
	await _key(KEY_DOWN, true)
	await _key(KEY_DOWN, true)
	_verdict.check(picks.get_count() == 3 and picks.is_picked(10) and picks.is_picked(12), "down with shift twice picks the run from where it was: %d" % picks.get_count())
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.ctrl_pressed = true
	press.position = shown.get_slots()[0].get_global_rect().get_center()
	root.push_input(press)
	await _a_frame_passes()
	_verdict.check(picks.get_cursor() == list.get_first() and picks.get_count() == 4 and picks.is_picked(list.get_first()), "a press with control on the first slot puts the cursor on its row and adds its pick: %d" % picks.get_count())
	var cancel := InputEventAction.new()
	cancel.action = &"ui_cancel"
	cancel.pressed = true
	root.push_input(cancel)
	await _a_frame_passes()
	_verdict.check(picks.get_count() == 0 and refuser.told_actions.is_empty(), "escape anywhere within the list, its first command refused, clears the picks by its second")
	shown.free()
	list.free()
	made.done()
