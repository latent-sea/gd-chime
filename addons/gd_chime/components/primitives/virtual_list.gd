extends "../../presentation.gd"

const Bound := preload("bound.gd")
const Commands := preload("../../commands.gd")
const LongList := preload("../../long_list.gd")
const Driver := preload("../../driver.gd")
const ListCursor := preload("list_cursor.gd")
const SlotRows := preload("slot_rows.gd")
const KeptRow := preload("kept_row.gd")

## A window of slots over a long list: one piece per visible slot, built
## once, each slot told its row again only when what it shows has changed.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The list (long_list.gd) holds the rows near where it is looking and
## where it is looking; this has as many slots as the list shows, down a
## column, each reading its item through a handle - the row's item, or null
## for one not held, failed or past the end. WHICH ROW EACH SLOT SHOWS is
## slot_rows.gd's: a scroll by fewer rows than there are slots moves the
## slots scrolled out of view to the other end for the rows coming in, and
## every other slot keeps its row, its words and its ground as they were;
## as the list moves, a page lands or a failure comes or goes, each slot
## whose item is not the one it showed is told - its handle's bell, one of
## its own, rung - and no other. No slot is built on the way: a scroll
## allocates nothing, and a scroll of three rows re-reads three slots. The
## wheel is this control's own input, dispatched to the list as SCROLL_ROWS.
##
## THE ROW IT STANDS AT IS KEPT WITH THE VIEW (kept_row.gd).
##
## THE PAD OR THE KEYS MOVE IT A WHOLE ROW AT A TIME: moving on past the
## last slot, or back before the first, the list moves a row that way and
## the focus moves with the slot's row to where the next row now shows -
## every slot is whole, so the focused row always is.
##
## GIVEN A CURSOR (list_cursor.gd), the list itself takes the focus and its
## keys, its pad and the pointer's presses are the cursor's commands; the
## cursor moving, its row is brought into the rows shown, and a list whose
## focus went nowhere - a cell's field freed as its edit ended - takes it
## back. ASKED TO FIT, it shows as many rows as its height holds at the
## height a slot needs: sized again, it tells the list how many
## (LongList.SHOWS) and builds or frees slots to match - on a resize, never
## on a scroll.

const LIST_BELLS: Array[StringName] = [LongList.LOOK_MOVED, LongList.PAGE_LANDED, LongList.PAGE_FAILED, LongList.FAILURES_FORGOTTEN]

var _ui: RefCounted
var _commands: Commands
var _list: LongList
var _template: Callable
var _column := Control.new()  # the slots' holder, placed by this, never a layout that would re-place them all
var _style: StringName  # the variation of a column whose gap stands between slots
var _place: Node  # the place this was built in, or none
var _kept: KeptRow
var _slots := SlotRows.new()
var _nodes: Array[Control] = []  # by a slot's identity, its piece
var _bells: Array[StringName] = []  # by a slot's identity, the bell its handle reads on
var _made: int = 0  # slots made so far, for each one's bell a name of its own
var _cursor: ListCursor = null  # what its keys and presses mean, or none
var _fits: bool  # whether it shows as many rows as its height holds


func _init(ui: RefCounted, list: LongList, template: Callable, style: StringName, in_region: StringName, cursor: Dictionary, fits: bool) -> void:
	# the reader moving, and every bell of the list's, each a reason to see which slots have something new
	super(chimes_of(ui), LIST_BELLS.map(func(bell: StringName) -> Array: return [list.region, bell]) + [[Chimes.GLOBAL, Driver.NAVIGATED]], in_region)
	_ui = ui
	_commands = ui.commands
	_place = ui.current_place()
	_list = list
	_template = template
	_fits = fits
	_kept = KeptRow.new(ui.commands, list, ui.driver, _place)
	# given a cursor, the list is what takes the focus, and follows the cursor
	if not cursor.is_empty():
		_cursor = ListCursor.new(ui.commands, list, cursor, region)
		focus_mode = Control.FOCUS_ALL
		_chimes.follow(self, &"cursor", _cursor_moved)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_style = style
	_column.set_anchors_preset(Control.PRESET_FULL_RECT)
	_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_column)
	# one piece per slot the list shows
	for slot: int in range(list.get_showing()):
		_build_slot()


## The pieces, one per slot, top to bottom.
func get_slots() -> Array[Node]:
	return _column.get_children()


static func chimes_of(ui: RefCounted) -> Chimes:
	return ui.chimes


## One more slot at the bottom: its bell hung, and its piece, reading its item on it.
func _build_slot() -> void:
	var slot := _slots.add()
	var bell := StringName("slot_%d_%d" % [get_instance_id(), _made])
	_made += 1
	register_bell(bell)
	_bells.append(bell)
	var handle := Bound.on_bell(func() -> Variant: return _slots.get_item(slot), region, bell)
	_nodes.append(_ui.build_template(_template, handle, _column, _place))


## The list moved, a page landed or a failure came or went: the slots
## turned to follow it, and each with something new to show told.
func _follow_rows() -> void:
	var moved := _slots.follow(_list.get_first(), _row_at)
	var turned: int = moved["turned"]
	# every slot scrolled out at one end, taken to the other
	for step: int in absi(turned):
		_column.move_child(_column.get_child(0), -1) if turned > 0 else _column.move_child(_column.get_child(-1), 0)
	if turned != 0:
		_place_slots()
	# every slot with something new, told on its own bell
	for slot: int in moved["changed"]:
		strike(region, _bells[slot])


## Every slot at its place down the height, top to bottom, the height shared
## alike with the style's gap between - a slot's rect set, nothing laid out.
func _place_slots() -> void:
	var slots := get_slots()
	var gap := float(get_theme_constant(&"gap", _style))
	var tall := (size.y - gap * (slots.size() - 1)) / slots.size()
	# every slot in order, anchored at the top left as a layout's parts are, and placed on whole pixels, so no seam shows between two
	for at: int in slots.size():
		var slot: Control = slots[at]
		if slot.anchor_right != 0.0 or slot.anchor_bottom != 0.0:
			slot.set_anchors_preset(Control.PRESET_TOP_LEFT)
		var top := roundf(at * (tall + gap))
		slot.position = Vector2.DOWN * top
		slot.size = Vector2(size.x, roundf(at * (tall + gap) + tall) - top)


## Sized: the slots placed again; asked to fit, the rows its height holds worked out once the size has settled.
func arrange() -> void:
	_place_slots()
	if _fits:
		_fit.call_deferred()


## As many slots as the height holds at the height a slot needs, told to the
## list and built or freed to match.
func _fit() -> void:
	if size.y <= 0.0 or _nodes.is_empty():
		return
	var gap := float(get_theme_constant(&"gap", _style))
	var tall := maxf(_nodes[0].get_combined_minimum_size().y, 1.0)
	var count := maxi(floori((size.y + gap) / (tall + gap)), 1)
	if count == _list.get_showing():
		return
	_commands.dispatch(region, LongList.SHOWS, {"count": count})
	# the slots wanting, built in turn below the last
	while _nodes.size() < count:
		_build_slot()
	# the slots past the count, the last made first, freed wherever they stand
	while _nodes.size() > count:
		_slots.remove()
		_bells.pop_back()
		_nodes.pop_back().free()
	_place_slots()
	_follow_rows()


## The wheel: one row a step, downward when positive, as a command to the list.
func scrolled(steps: int) -> void:
	_commands.dispatch(region, LongList.SCROLL_ROWS, {"by": steps})


## The pad or the keys moving on past the last slot, or back before the
## first: a whole row that way - looked at before the engine moves the
## focus, since it hands them to the focus alone.
func _input(event: InputEvent) -> void:
	var focus := get_viewport().gui_get_focus_owner()
	var slots := get_slots()
	if focus == null or _cursor != null:
		return
	if event.is_action_pressed(&"ui_down") and (slots[-1] == focus or slots[-1].is_ancestor_of(focus)):
		scrolled(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_up") and (slots[0] == focus or slots[0].is_ancestor_of(focus)):
		scrolled(-1)
		get_viewport().set_input_as_handled()


## With a cursor: a key it names, its command; a press of the pointer on a
## slot, its press; anything else, a control's own.
func _gui_input(event: InputEvent) -> void:
	if _cursor != null and (_cursor.key(event) or _cursor.pointer(event, self)):
		if event is InputEventMouseButton:
			grab_focus()
		accept_event()
		return
	super(event)


## With a cursor, the keys it hears anywhere within the list - a cell's
## line being typed into - that nothing within took.
func _unhandled_input(event: InputEvent) -> void:
	var focus := get_viewport().gui_get_focus_owner()
	if _cursor == null or focus == null or not (focus == self or is_ancestor_of(focus)):
		return
	if _cursor.anywhere(event):
		get_viewport().set_input_as_handled()


## The cursor read, so it is followed; moved once this is ready, followed down the list.
func _cursor_moved() -> void:
	_cursor.get_at()
	if is_node_ready():
		_follow_cursor.call_deferred()


## The cursor moved: its row brought into the rows shown, and the focus taken back if it went nowhere.
func _follow_cursor() -> void:
	_cursor.follow()
	if is_visible_in_tree() and get_viewport().gui_get_focus_owner() == null:
		_take_focus()


## The list's bells: the slots follow it. The reader moving: the row it
## stands at kept and found again, and, shown, a list with a cursor takes
## the focus.
func heard(what: StringName) -> void:
	if LIST_BELLS.has(what):
		_follow_rows()
	# shown, a list with a cursor is where the reader is: it takes the focus, once the place's own first focus is given
	elif _kept.navigated(self) and _cursor != null:
		_follow_cursor.call_deferred()
		_take_focus.call_deferred()


## The focus taken where its layer takes any: under a pop-up it waits to be come back to.
func _take_focus() -> void:
	if get_focus_mode_with_override() != FOCUS_NONE:
		grab_focus()


func _row_at(index: int) -> Variant:
	return null if _list.has_failed(index) else _list.get_item(index)


static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"virtual_list").new(ui, desc.props["list"], desc.props["template"], desc.props["style"], ui.region(), desc.props["cursor"], desc.props["fits"])
	ui.attach(made, parent, desc.facts)
	return made
