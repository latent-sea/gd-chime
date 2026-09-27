extends RefCounted

const GdChime := preload("res://addons/gd_chime/gd_chime.gd")
const PipesWork := preload("res://demo/apps/pipes/pipes_work.gd")
const Hands := preload("res://tests/hands.gd")

## The pipes demo walked and reported: run by pipes.gd started with --probe,
## and by checks/stalls_probe.py over every application.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The asked-for walk first: a hundred thousand pipes; filtered by three
## filters to the high-risk cast iron laid before 1970 - the rows kept
## exactly those a pass over every pipe finds; three hundred picked by the
## keys, from the first row, a run; assigned to a programme, those three
## hundred and no other; taken back, and assigned again. Then the rest of
## the grid: the arrow key moves the cursor; sorting by risk puts the least
## first; grouping by material heads each group and a group shuts;
## a column hidden and shown again; the keys resize the cursor's column; a
## diameter typed into its cell as words refused, saying why under the
## table, and as a number written, the saying gone with it; a pipe marked
## inspected with nothing picked, the cursor's alone.
##
## THE VIEW IN TIME. A query paced to the typing (query_pacing.gd): a risk
## typed a character a frame asks no query while it is typed, the grid's
## line saying the view is being worked out all the while, and one once the
## typing settles; Enter asks at once and leaves nothing waiting. A view
## behind its rows (view_behind.gd): the first pipe showing, its risk
## written under the filter, stays where it is, its row drawn with the stale
## mark and every cell dimmed, and the grid's line says the view is out of
## date; key R brings it up to date, the pipe gone and no mark left.
##
## THEN THE READER'S HANDS on the grid, each claim made by the input a hand
## gives - a right press, the menu key, a pad button - never by a command
## sent past them. A row's menu (context_menu.gd over long_table.gd's rows):
## opened by a right press on a row, a pick marks that pipe alone and not
## the picks; the programmes raised from it assign that pipe, not the picks;
## the menu key and the pad's view button open the menu of the cursor's row,
## the list holding the focus; and with no row to act on, an item says why.
## A column's edge (grip.gd in the heading): dragged by the pointer it
## widens its column, and dragged far past it never narrows the column below
## its heading's words.
##
## Then the whole of it at three window shapes, as a stall's probe judges
## (demo/gallery/probe.gd): the grid, and every pop-up raised over it,
## judged for words cut off and for anything drawn over anything else.

const SHAPES: Array[Vector2i] = [Vector2i(1920, 1080), Vector2i(1280, 800), Vector2i(720, 1280)]
const PROGRAMME := "R-2027 cast iron retirement"
## Another programme than the walk's own, chosen from a row's menu.
const OTHER := "R-2029 lead and iron sweep"
## What the grid's line says while the view is worked out, and while it is behind.
const WORKING := "Working out the view"
const BEHIND := "Out of date: rows shown have changed since"

var _app: SceneTree
var _said: Dictionary = {}
var _hands: Hands


func _init(app: SceneTree) -> void:
	_app = app
	_hands = Hands.new(app)


func _do(action: StringName, payload: Dictionary = {}) -> GdChime.Phrase:
	return _hands.does(_app.PIPES, action, payload)


## Frames until the view has landed: a frame at a time, at least one, until no query is out.
func _landed(models: RefCounted) -> void:
	# a frame each, until the view is no longer being worked out
	while true:
		await _app.process_frame
		if not models.view.get_busy():
			return


## The walk: every claim kept by name, all said, and the app quit on the answer.
func run() -> void:
	await _hands.plain_frames(4)
	var models: RefCounted = _app.models
	var rows: GdChime.PackedRows = models.rows
	_said["hundred_thousand"] = rows.count() == 100000 and models.long.count() == 100000
	# the three filters, built as the filter builder builds them
	for built: Array in [[&"material", "is", "cast iron", false], [&"risk", "is over", "70", true], [&"laid", "is before", "1970", true]]:
		_do(GdChime.RowFilters.PICKS_PROPERTY, {"value": built[0]})
		_do(GdChime.RowFilters.PICKS_COMPARISON, {"comparison": built[1]})
		_do(GdChime.RowFilters.SETS_VALUE if built[3] else GdChime.RowFilters.PICKS_VALUE, {"line": built[2]} if built[3] else {"value": built[2]})
	await _landed(models)
	var by_hand: int = range(rows.count()).filter(func(row: int) -> bool: return rows.value_at(row, &"material") == "cast iron" and rows.value_at(row, &"risk") > 70.0 and rows.value_at(row, &"laid") < GdChime.PackedRows.day_of("1970")).size()
	_said["filtered"] = by_hand > 300 and models.view.get_kept() == by_hand
	_do(GdChime.RowSelection.MOVES, {"to": 0})
	_do(GdChime.RowSelection.EXTENDS, {"by": 299})
	var picked: PackedInt32Array = models.picks.get_acted_on()
	_said["picked_300"] = picked.size() == 300 and Array(picked).all(func(row: int) -> bool: return rows.value_at(row, &"material") == "cast iron")
	_do(PipesWork.ASSIGNS, {"value": PROGRAMME})
	_said["assigned"] = _in_programme(rows) == 300 and Array(picked).all(func(row: int) -> bool: return rows.value_at(row, &"programme") == PROGRAMME)
	_do(GdChime.RowEdits.UNDOES)
	var undone := _in_programme(rows) == 0
	_do(PipesWork.ASSIGNS, {"value": PROGRAMME})
	_said["undone_and_again"] = undone and _in_programme(rows) == 300
	await _the_rest(models, rows)
	await _paced(models)
	_said["behind_marked"] = await _behind(models)
	await _by_hand(models, rows)
	await _whole()
	var failed: Array = _said.keys().filter(func(claim: String) -> bool: return not _said[claim])
	print("PROBE %s" % [_said])
	print("PROBE " + ("OK" if failed.is_empty() else "FAILED %s" % [failed]))
	_app.quit(0 if failed.is_empty() else 1)


## How many pipes are in the programme.
func _in_programme(rows: GdChime.PackedRows) -> int:
	return range(rows.count()).filter(func(row: int) -> bool: return rows.value_at(row, &"programme") == PROGRAMME).size()


## Whether words saying this are drawn anywhere in the window, alone or among others.
func _shows(words: String) -> bool:
	return _hands.words().any(func(line: String) -> bool: return words in line)


## The rest of the grid: a key, a sort, a grouping, a column hidden, one resized, a cell edited, an action on the cursor's pipe.
func _the_rest(models: RefCounted, rows: GdChime.PackedRows) -> void:
	_do(GdChime.RowSelection.CLEARS)
	var at: int = models.picks.get_cursor()
	var down := InputEventAction.new()
	down.action = &"ui_down"
	down.pressed = true
	_app.ui.root.get_window().push_input(down)
	await _app.process_frame
	_said["key_moves"] = models.picks.get_cursor() == at + 1
	_do(GdChime.QueriedRows.SORTS, {"column": &"risk"})
	await _landed(models)
	_said["sorted"] = rows.value_at(models.view.row_at(0), &"risk") <= rows.value_at(models.view.row_at(50), &"risk")
	_do(GdChime.QueriedRows.GROUPS_BY, {"value": &"town"})
	await _landed(models)
	var heading: int = models.view.row_at(0)
	var places: int = models.view.get_count()
	_do(GdChime.QueriedRows.SHUTS, {"group": models.view.get_group_of(0)["code"]})
	_said["grouped"] = heading == -1 and models.view.get_count() == places - models.view.get_group_of(0)["count"]
	_do(GdChime.QueriedRows.GROUPS_BY, {"value": &""})
	await _landed(models)
	_do(GdChime.TableColumns.TURNS, {"column": &"road"})
	var hidden: bool = models.columns.get_shown().size() == 9
	_do(GdChime.TableColumns.TURNS, {"column": &"road"})
	_said["hid_a_column"] = hidden and models.columns.get_shown().size() == 10
	_do(GdChime.RowSelection.MOVES, {"to": 3})
	_do(GdChime.RowSelection.MOVES_ACROSS, {"by": 4 - models.picks.get_across()})
	var share: float = models.columns.get_shown()[4]["share"]
	_do(GdChime.EditingCell.RESIZES_THIS_COLUMN, {"by": 0.02})
	_said["resized"] = models.columns.get_shown()[4]["share"] > share
	_do(GdChime.EditingCell.EDITS)
	var row: int = models.view.row_at(3)
	await _hands.plain_frames(3)
	# typed into the cell's field as a reader types, once it has the focus
	var line := _hands.focused() as LineEdit
	line.text_submitted.emit("wide")
	await _hands.plain_frames(2)
	var why: String = str(_app.commands.refusal(_app.PIPES, GdChime.RowEdits.WRITES, {"row": row, "column": &"diameter", "line": "wide"}))
	var shown := _hands.shows_words(why)
	line.text_submitted.emit("325")
	await _hands.plain_frames(2)
	_said["edited"] = shown and rows.value_at(row, &"diameter") == 325.0 and models.editing.get_editing().is_empty() and not _hands.shows_words(why)
	_do(PipesWork.MARKS_INSPECTED)
	_said["inspected_one"] = rows.value_at(row, &"inspection") == "passed"
	await _app.process_frame


## A risk typed a character a frame asks no query while it is typed and one
## once the typing settles; Enter asks at once. The chip made is then
## removed, so the view is the walk's three filters' again.
func _paced(models: RefCounted) -> void:
	var pacing: GdChime.QueryPacing = models.filters.get_pacing()
	var typed := "75.0000000"
	_do(GdChime.RowFilters.PICKS_PROPERTY, {"value": &"risk"})
	_do(GdChime.RowFilters.PICKS_COMPARISON, {"comparison": "is over"})
	var sent: int = pacing.get_sent()
	# every character, a frame after the last
	for at: int in typed.length():
		_do(GdChime.RowFilters.TYPES_LINE, {"line": typed.left(at + 1)})
		await _app.process_frame
	var said_busy := _shows(WORKING)
	var while_typing: int = pacing.get_sent() - sent
	# frames until the wait has run out and its query has gone
	while pacing.get_waiting():
		await _app.process_frame
	await _landed(models)
	_said["typing_paced"] = while_typing == 0 and said_busy and pacing.get_sent() - sent == 1
	_do(GdChime.RowFilters.SETS_VALUE, {"line": typed})
	_said["enter_at_once"] = pacing.get_sent() - sent == 2 and not pacing.get_waiting()
	await _landed(models)
	_do(GdChime.RowFilters.REMOVES, {"id": models.filters.get_chips()[-1]["id"]})
	await _landed(models)


## The first pipe showing written under the filter, drawn behind, and the key bringing the view up to date.
func _behind(models: RefCounted) -> bool:
	var first: int = models.long.get_first()
	var row: int = models.view.row_at(first)
	_do(GdChime.RowEdits.WRITES, {"row": row, "column": &"risk", "line": "10"})
	await _hands.plain_frames(4)
	var marked: bool = models.behind.get_stale().has(row) and models.view.row_at(first) == row and _shows(BEHIND) and _drawn_stale() == 1
	var up_to_date := InputEventKey.new()
	up_to_date.keycode = KEY_R
	up_to_date.pressed = true
	_app.ui.root.get_window().push_input(up_to_date)
	await _landed(models)
	await _app.process_frame
	var cleared: bool = not Array(models.view.get_order()).has(row) and not models.behind.get_behind() and models.behind.get_stale().is_empty() and not _shows(BEHIND) and _drawn_stale() == 0
	_do(GdChime.RowEdits.UNDOES)
	_do(GdChime.ViewBehind.REAPPLIES)
	await _landed(models)
	return marked and cleared


## How many rows are drawn stale: the stale mark in the picks' column, and
## every cell's words beside it dimmed - a row counted only when it has both.
func _drawn_stale() -> int:
	var grounds := [GdChime.Tables.CELLS, GdChime.Tables.PICKED, GdChime.Tables.CURSOR, GdChime.Tables.PICKED_CURSOR]
	# every row's line shown, known by the ground a row wears
	var lines: Array = _app.root.find_children("*", "Control", true, false).filter(func(line: Control) -> bool: return line.theme_type_variation in grounds and _hands.shown(line))
	return lines.filter(func(line: Control) -> bool: return _stale_line(line)).size()


## Whether a row's line is drawn stale: its first words end in the stale mark, and every other is dimmed.
func _stale_line(line: Control) -> bool:
	var words: Array = line.find_children("*", "Label", true, false).filter(func(label: Label) -> bool: return label.is_visible_in_tree())
	return words[0].text.ends_with(GdChime.TableModels.STALE_MARK) and words.slice(1).all(func(label: Label) -> bool: return label.theme_type_variation == GdChime.Tables.STALE_WORDS)


## The grid by the reader's hands: a row's menu by the pointer, by the menu
## key and by the pad, what it offers and what a pick of it acts on; and a
## column's edge dragged.
func _by_hand(models: RefCounted, rows: GdChime.PackedRows) -> void:
	_do(GdChime.RowSelection.MOVES, {"to": 10})
	_do(GdChime.RowSelection.EXTENDS, {"by": 1})
	var picked: PackedInt32Array = models.picks.get_acted_on()
	await _app.process_frame
	# a pipe shown near the top, neither picked nor passed yet
	var place: int = range(4, 9).filter(func(at: int) -> bool: return rows.value_at(models.view.row_at(at), &"inspection") != "passed")[0]
	var row: int = models.view.row_at(place)
	var targets: Array = _app.get_nodes_in_group(GdChime.MenuTarget.TARGET).filter(_hands.shown)
	var on_row: Control = targets.filter(func(one: Control) -> bool: return one != targets[0] and one.payload()["id"] == row)[0]
	await _hands.right_click(on_row)
	var up: Variant = _app.driver.get_parameter(_app.ui.menu_place)
	var offered: bool = up != null and up["payload"]["id"] == row and _app.menu.items_of(up).map(func(item: Dictionary) -> StringName: return item["action"]) == [PipesWork.MARKS_INSPECTED, PipesWork.OPENS_PROGRAMMES]
	var inspected := func() -> Array: return Array(picked).map(func(one: int) -> Variant: return rows.value_at(one, &"inspection"))
	var before: Array = inspected.call()
	_hands.does(_app.ui.menu_place, GdChime.OpenMenu.PICKS, {"item": _app.menu.items_of(up)[0]})
	_said["menu_by_pointer_acts_on_its_row"] = offered and rows.value_at(row, &"inspection") == "passed" and inspected.call() == before and not _app.driver.is_raised()
	await _hands.right_click(on_row)
	_hands.does(_app.ui.menu_place, GdChime.OpenMenu.PICKS, {"item": _app.menu.items_of(_app.driver.get_parameter(_app.ui.menu_place))[1]})
	var assigning: StringName = _app.driver.goes_to(_app.PIPES, PipesWork.OPENS_PROGRAMMES)
	var chosen: bool = _app.driver.get_top().has(assigning)
	_hands.does(assigning, PipesWork.ASSIGNS, {"value": OTHER})
	_said["programme_from_a_menu_is_its_row_s"] = chosen and rows.value_at(row, &"programme") == OTHER and Array(picked).all(func(one: int) -> bool: return rows.value_at(one, &"programme") != OTHER)
	await _menu_by_key_and_pad(models, targets[0], on_row)
	await _refused_item_says_why(models, targets[0])
	_said["column_grip_by_pointer"] = await _grip(models)


## The list holding the focus: the menu key, then the pad's view button, open
## the menu of the cursor's row, each closed again.
func _menu_by_key_and_pad(models: RefCounted, list: Control, on_row: Control) -> void:
	list.get_child(0).grab_focus()
	var opened: Array = []
	# the two hands that open a menu without a pointer, each tried in turn
	for by_hand: Callable in [_hands.key.bind(KEY_MENU, "", []), _hands.pad.bind(JOY_BUTTON_BACK)]:
		await by_hand.call()
		var up: Variant = _app.driver.get_parameter(_app.ui.menu_place)
		opened.append(up != null and list.is_ancestor_of(on_row) and up["payload"]["id"] == models.view.row_at(models.picks.get_cursor()))
		await _hands.goes_back()
	_said["menu_by_key_and_pad"] = opened == [true, true]


## A filter keeping nothing: the menu has no row to act on, and says so.
func _refused_item_says_why(models: RefCounted, list: Control) -> void:
	_do(GdChime.RowSelection.CLEARS)
	# the three presses of the filter builder, building one that keeps nothing
	for built: Array in [[GdChime.RowFilters.PICKS_PROPERTY, {"value": &"risk"}], [GdChime.RowFilters.PICKS_COMPARISON, {"comparison": "is over"}], [GdChime.RowFilters.SETS_VALUE, {"line": "1000"}]]:
		_do(built[0], built[1])
	await _landed(models)
	list.get_child(0).grab_focus()
	await _hands.key(KEY_MENU)
	_said["refused_item_says_why"] = _app.driver.get_top().has(_app.ui.menu_place) and _hands.shows_words("Pick some pipes first")
	await _hands.goes_back()
	_do(GdChime.RowFilters.REMOVES, {"id": models.filters.get_chips()[-1]["id"]})
	await _landed(models)


## The road column's edge taken by the pointer in a desktop's window: dragged
## right it widens; dragged far past the left it stops at the least a column
## has, its heading's words still whole.
func _grip(models: RefCounted) -> bool:
	_app.root.size = Vector2i(1920, 1080)
	await _hands.plain_frames(4)
	var edge := func(column: StringName) -> Control: return _app.root.find_children("*", "Container", true, false).filter(func(one: Node) -> bool: return one.get_script() == GdChime.Grip and one.payload()["column"] == column and _hands.shown(one))[0]
	var grip: Control = edge.call(&"road")
	var share := func() -> float: return models.columns.get_shown().filter(func(column: Dictionary) -> bool: return column["name"] == &"road")[0]["share"]
	var before: float = share.call()
	var at := _hands.middle_of(grip)
	await _hands.drag(at, at + Vector2(60.0, 0.0))
	var wider: bool = share.call() > before
	at = _hands.middle_of(grip)
	await _hands.drag(at, at + Vector2(-2000.0, 0.0))
	var from: float = edge.call(&"asset").get_global_rect().end.x
	var to: float = grip.get_global_rect().position.x
	# the road column's words, heading and rows: a label is never drawn narrower than its words, so a column too narrow shows as words past its edge
	var road: Array = grip.get_parent().get_parent().find_children("*", "Label", true, false).filter(func(label: Label) -> bool: return label.is_visible_in_tree() and label.text != "" and label.get_global_rect().position.x >= from and label.get_global_rect().position.x < to)
	return wider and share.call() <= GdChime.TableModels.LEAST + 0.001 and road.size() > 10 and road.all(func(label: Label) -> bool: return label.get_global_rect().end.x <= to + 0.5)


## The grid and every pop-up at every shape, judged for words cut off and for anything drawn over.
func _whole() -> void:
	var cut: Array[String] = []
	var over: Array[String] = []
	_app.ui.motion.still = true
	_app.ui.motion.step(10.0)
	# every shape, each judged alike
	for shape: Vector2i in SHAPES:
		_app.root.size = shape
		await _hands.judged(&"the grid", shape, cut, over)
		var openers: Array = [GdChime.DataGrid.OPENS_FILTERS, GdChime.DataGrid.OPENS_COLUMNS, GdChime.DataGrid.OPENS_GROUPING, PipesWork.OPENS_PROGRAMMES]
		# every pop-up the grid can raise over itself, raised, judged, and taken down
		for overlay: StringName in openers.map(func(opener: StringName) -> StringName: return _app.driver.goes_to(_app.PIPES, opener)):
			_hands.does(GdChime.Chimes.GLOBAL, GdChime.Driver.GO, {"place": overlay})
			await _hands.judged(overlay, shape, cut, over)
			_hands.does(GdChime.Chimes.GLOBAL, GdChime.Driver.GOES_BACK, {})
	_said["no_clipped_text"] = cut.is_empty()
	_said["nothing_drawn_over"] = over.is_empty()
	_said["words_stand_out"] = _hands.get_faint().is_empty()
	_hands.say_every(cut, over)
