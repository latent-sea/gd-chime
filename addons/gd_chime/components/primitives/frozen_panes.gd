extends Container

const Bound := preload("bound.gd")
const Touch := preload("../../touch.gd")
const Language := preload("../../language.gd")
const ColumnLeasts := preload("column_leasts.gd")
const FrozenOffsets := preload("frozen_offsets.gd")

## A table wider or taller than its room, in four panes: a CORNER that
## never moves; the HEADS, the heading row, held at the top; the LABELS, the
## column that names each row, held at the left; and the BODY, which
## scrolls either way while the heads follow it across and the labels
## follow it down (frozen_offsets.gd). A table never squeezes a column
## under its least, never drops one and never pages: what does not fit
## scrolls.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A COLUMN IS AT LEAST ITS LEAST, and the columns share the room when they
## all fit (column_leasts.gd, shared); where they do not, each stands at its
## least and the body scrolls across. A column's least is the larger of the
## look's constant named for every column, under Columns, and the widest of
## its samples drawn in the kind of words named, with the look's pad either
## side. The columns stand in the order given, which is their rank, with the
## look's gap between them. The widths are kept where the table's drawing
## can read them: get_widths(), and a local set to them as they move.
##
## THE CORNER IS AS WIDE AS THE LABELS AND AS TALL AS THE HEADS - the wider
## and the taller of its own least and theirs. The heads are laid at the
## width of the columns, the labels and the body at the height of the
## taller of the two, so a label stands beside the row of the body whose
## height it shares; that both are drawn in rows of one height is the
## table's to keep.
##
## A FINGER, A WHEEL OR A PAD'S PAN ON ANY PANE MOVES THE BODY: on the
## heads, the labels or the corner it reaches this (touch.gd, the engine
## passing a wheel up), which hands it to the body; so does the pad walking
## the focus onto a heading or a label.
##
## ITS LEAST IS THE CORNER AND ONE COLUMN ACROSS, AND THE HEADS AND ONE ROW
## DOWN - the labels' first part - with the body's padding, whatever its
## room. Drawn whole down, the body is as tall as its rows and scrolls
## across alone, and its least is all of them: for a page drawn whole.

## A pane holding one part, which the table lays: a part inside asking for
## other room, or the pane resized, has the table lay everything again.
class Pane extends Container:
	## The least it asks for: the columns' width and the rows' height in the body, nothing elsewhere.
	var least := Vector2.ZERO
	var _moved: Callable  # the table's, laying it all again

	func _init(moved: Callable, clips: bool) -> void:
		_moved = moved
		clip_contents = clips
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _get_minimum_size() -> Vector2:
		return least

	func _notification(what: int) -> void:
		if what == NOTIFICATION_SORT_CHILDREN:
			_moved.call()

var _chimes: RefCounted
var _columns: Bound  # reads the columns shown, in rank order
var _least_column: StringName  # the look's constant under Columns every column is at least, or none
var _samples: Dictionary  # column -> the words it may hold, for a column measured by its words
var _leasts: ColumnLeasts
var _style: StringName  # the look holding the gap and the pad
var _widths_to: RefCounted  # the local the widths are set into, or none
var _whole_down: bool
var _widths: Array[float] = []
var _corner: Pane
var _heads: Pane
var _labels: Pane
var _sheet: Pane  # what the body holds: the body's part, at the columns' width and the rows' height
var _body: FrozenOffsets
var _built := 0  # how many of the four parts have been built into it


func _init(ui: RefCounted, props: Dictionary) -> void:
	_chimes = ui.chimes
	_columns = props["columns"]
	_least_column = props["least_column"]
	_samples = props["samples"]
	_leasts = ColumnLeasts.new(_samples, props["words_kind"])
	_style = props["style"]
	_widths_to = props["widths"]
	_whole_down = props["whole_down"]
	_corner = Pane.new(_part_moved, false)
	_heads = Pane.new(_part_moved, true)
	_labels = Pane.new(_part_moved, true)
	_sheet = Pane.new(_part_moved, false)
	_body = FrozenOffsets.new(ui, props["nudged"], _heads, _labels, _whole_down)
	_body.add_child(_sheet)
	# the panes standing in it, the body last so its indicator is over the rest
	for pane: Control in [_corner, _heads, _labels, _body]:
		add_child(pane)
	add_to_group(Touch.TAKES)
	_chimes.follow(self, &"columns", _columns_moved)
	_chimes.follow(self, &"language", func() -> void: Language.on().read(), _part_moved)


## A part built into it: the corner, the heads, the labels and the body, in that order.
func place(made: Control, _facts: Dictionary) -> void:
	[_corner, _heads, _labels, _sheet][_built].add_child(made)
	_built += 1


## The columns' widths as last laid, in rank order.
func get_widths() -> Array[float]:
	return _widths


## Each column's least, in rank order: the larger of the look's constant and its widest words.
func get_leasts() -> Array[float]:
	var named := float(get_theme_constant(_least_column, &"Columns")) if _least_column != &"" else 0.0
	var pad := float(get_theme_constant(&"pad", _style))
	var leasts: Array[float] = []
	# every column shown, the larger of the constant and its samples where it has any
	for column: Variant in _columns.read():
		leasts.append(maxf(named, _leasts.of(column, self, pad) if _samples.has(column) else 0.0))
	return leasts


## The one part a pane holds, or the pane itself while that is not built yet.
func _held(pane: Pane) -> Control:
	return pane.get_child(0) if pane.get_child_count() > 0 else pane


## How wide the labels and the corner stand, and how tall the heads and the corner.
func _corner_size() -> Vector2:
	return _held(_corner).get_combined_minimum_size().max(Vector2(_held(_labels).get_combined_minimum_size().x, _held(_heads).get_combined_minimum_size().y))


## The width of columns this wide, with the gaps between them.
func _across(widths: Array[float]) -> float:
	return widths.reduce(func(sum: float, width: float) -> float: return sum + width, 0.0) + float(get_theme_constant(&"gap", _style)) * maxi(widths.size() - 1, 0)


## The height of the rows: the taller of the labels and the body's part.
func _tall() -> float:
	return maxf(_held(_labels).get_combined_minimum_size().y, _held(_sheet).get_combined_minimum_size().y)


func _get_minimum_size() -> Vector2:
	var leasts := get_leasts()
	var parts: Array = _held(_labels).get_children().filter(func(part: Node) -> bool: return part is Control)
	var row: float = 0.0 if parts.is_empty() or _whole_down else (parts[0] as Control).get_combined_minimum_size().y
	return _corner_size() + _body.get_combined_minimum_size() + Vector2(0.0 if leasts.is_empty() else leasts[0], row)


## What it would take given all the room it wants: every column at its least, every row, the corner and the body's padding.
func preferred_size() -> Vector2:
	return _corner_size() + Vector2(_across(get_leasts()), _tall()) + _body.get_theme_stylebox(&"panel").get_minimum_size()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SORT_CHILDREN:
			_lay()
		NOTIFICATION_THEME_CHANGED:
			_leasts.forget()
		NOTIFICATION_PREDELETE:
			_chimes.stop_all(self)


## The columns read, so what they read is followed; moved, laid again.
func _columns_moved() -> void:
	_columns.read()
	update_minimum_size()
	queue_sort()


## A part placed or asking for other room, or the language changed: measured and laid again.
func _part_moved() -> void:
	_leasts.forget()
	update_minimum_size()
	queue_sort()


## The panes at the corner's size and the columns' widths, each pane's part
## laid in it, and the heads and the labels in step with the body.
func _lay() -> void:
	var corner := _corner_size()
	fit_child_in_rect(_body, Rect2(corner, size - corner))
	var room: float = _body.size.x - _body.get_theme_stylebox(&"panel").get_minimum_size().x
	var widths := ColumnLeasts.shared(get_leasts(), room, float(get_theme_constant(&"gap", _style)))
	# the widths moved: kept, and set into the local the table's drawing reads, given one
	if widths != _widths:
		_widths = widths
		if _widths_to != null:
			_widths_to.set_value(widths.duplicate())
	# the columns as wide as the room exactly where they share it, so a sum a hair over it never scrolls
	var sheet := Vector2(maxf(room, _across(widths)), _tall())
	if _sheet.least != sheet:
		_sheet.least = sheet
		_sheet.update_minimum_size()
	var bar: ScrollBar = _body.get_h_scroll_bar()
	fit_child_in_rect(_corner, Rect2(Vector2.ZERO, corner))
	fit_child_in_rect(_heads, Rect2(corner.x, 0.0, _body.size.x, corner.y))
	fit_child_in_rect(_labels, Rect2(0.0, corner.y, corner.x, _body.size.y - (bar.size.y if bar.visible else 0.0)))
	# each pane's one part, once built, at the size it stands at; the heads and the labels then put at the body's offsets
	for laid: Array in [[_corner, Rect2(Vector2.ZERO, corner)], [_heads, Rect2(0.0, 0.0, sheet.x, corner.y)], [_labels, Rect2(0.0, 0.0, corner.x, sheet.y)], [_sheet, Rect2(Vector2.ZERO, sheet)]]:
		for held: Node in (laid[0] as Pane).get_children():
			(laid[0] as Pane).fit_child_in_rect(held, laid[1])
	_body.keep_in_step()


## A finger on the heads, the labels or the corner: the body's (touch.gd).
func takes_finger(axis: StringName, travel: Vector2) -> bool:
	return _body.takes_finger(axis, travel)


func finger_moved(travel: Vector2, relative: Vector2) -> void:
	_body.finger_moved(travel, relative)


func finger_ended(velocity: Vector2) -> void:
	_body.finger_ended(velocity)


## A wheel or a pad's pan on the heads, the labels or the corner, passed up
## by the engine: the body's, and taken only where it moved the body.
func _gui_input(event: InputEvent) -> void:
	if _body.moved_by(event):
		accept_event()


## The pad or the keys used: once the focus has moved, a heading or a label it is on is shown whole.
func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion or event is InputEventAction:
		_focus_shown.call_deferred()


func _focus_shown() -> void:
	# gone from the tree since the press, as a place the press left is: nothing of it to show
	if not is_inside_tree():
		return
	var focus := get_viewport().gui_get_focus_owner()
	# the heads and the labels: the one the focus stands in, if either
	for pane: Pane in [_heads, _labels]:
		if focus != null and pane.is_ancestor_of(focus):
			_body.show_whole(focus, pane)


static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"frozen_panes").new(ui, desc.props)
	ui.attach(made, parent, desc.facts)
	return made
