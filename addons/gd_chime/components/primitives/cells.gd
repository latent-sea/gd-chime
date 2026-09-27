extends Control

const Bound := preload("bound.gd")
const Styled := preload("styled.gd")
const FlexLine := preload("flex_line.gd")
const ColumnLeasts := preload("column_leasts.gd")
const Language := preload("../../language.gd")

## A line of cells at their columns' widths, on a ground: a table's heading
## line and every one of its rows, laid out alike so each cell stands under
## its heading - and WHAT A CELL SAYS NEVER MOVES the line.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## IT IS NO CONTAINER, AND ITS LEAST SIZE IS ITS COLUMNS'. The engine tells a
## Container whenever a part's least size changes, and a line measured by
## its words then tells every layout above it to re-place its parts; in a
## table that is every row on every scroll, since every cell's words change
## (a hundred thousand rows scrolled a page a frame spent 32 ms a frame
## there, measured). Here nothing is told, and the widths come from the
## COLUMNS alone - a bound value reading the columns shown, [{name, share}]
## (table_columns.gd) - so the line is placed again only when its size, its
## columns or its look change.
##
## A column's width is its share of the line, but never less than its
## LEAST (column_leasts.gd): the widest of the words it may ever hold - its
## SAMPLES, handed in by column name, each measured in the look's font for
## the kind of words the cells are in, in the language on - and the style's
## pad either side, which every part stands within, a heading's as a
## cell's, so words start alike. Words
## wider than a share therefore widen their column and never cut: the
## shares are resolved as a line's lengths are (flex_line.gd), each column
## held to its least and the rest shared out. A ROW TOO NARROW FOR ITS
## COLUMNS DROPS THEM WHOLE, the last first, until the rest fit - never a
## column cut at the edge, and never a line wider than where it stands: a
## word half out of sight is clipped text, however the reader might scroll
## to it (clipped_text.gd), and a reader brings a dropped column back by
## hiding another. Every line of one table is handed the same samples and
## the same columns and is as wide as the others, so all drop alike and
## agree. The language changing, every line measures again: longer words
## are never drawn over the next column.
##
## A part stands for a column by the name given for it in order; a part
## whose column is hidden is hidden. EDGES, given, are one per part, each
## standing in the gap after its column while another column follows it -
## a column's resize grip, which belongs to its column wherever the column
## now stands - as thin as the gap. Parts sit across the line's height at
## their own least height, in its middle.
##
## THE GROUND is the style's panel, or the panel of the style a bound value
## reads - a row picked, the row the cursor is on - worn in place as it
## moves, with no fade: a row re-pointed as a list scrolls is not a row that
## changed.
##
## Deliberately absent: a column wider than a share asks nobody else to
## narrow, and there is no line across two rows.

## How many times the parts have been placed, so that words changing without
## placing anything is something a test can read.
var placed_count: int = 0

var _chimes: RefCounted
var _columns: Bound
var _names: Array  # the column each part stands for, in the parts' order
var _ground: Variant  # the ground's style: a name, or a Bound reading one
var _edges: int = 0  # how many of the last children are edges
var _due: bool = false  # a placing is due at the end of the frame
var _leasts: ColumnLeasts  # each column's least in the look and language on, forgotten as either changes


func _init(chimes: RefCounted, columns: Bound, names: Array, samples: Dictionary, words_kind: StringName, ground: Variant) -> void:
	_chimes = chimes
	_columns = columns
	_names = names
	_leasts = ColumnLeasts.new(samples, words_kind)
	_ground = ground
	theme_type_variation = Styled.name_of(ground)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	chimes.follow(self, &"columns", _columns_moved)
	chimes.follow(self, &"style", _ground_moved)
	chimes.follow(self, &"language", func() -> void: Language.on().read(), _measure_again)


## The columns read, so what they read is followed; moved once ready, placed and measured again.
func _columns_moved() -> void:
	_columns.read()
	if is_node_ready():
		_place()
		update_minimum_size()


## The ground read, so what it read is followed - a row re-pointed as a list
## scrolls, the picks, the cursor - and worn, nothing placed unless it
## changed the look.
func _ground_moved() -> void:
	var worn := Styled.name_of(_ground)
	if theme_type_variation != worn:
		theme_type_variation = worn
		queue_redraw()


## How many of the children built last are edges, not cells.
func set_edges(count: int) -> void:
	_edges = count


## Resized or ready, placed; a part arriving or the look changing, measured again.
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_RESIZED, NOTIFICATION_READY: _place()
		NOTIFICATION_THEME_CHANGED, NOTIFICATION_CHILD_ORDER_CHANGED: _measure_again()
		NOTIFICATION_PREDELETE: _chimes.stop_all(self)


## The look, the parts or the language changed: every least forgotten, and
## the line placed and measured again - once, at the end of the frame,
## however many arrive.
func _measure_again() -> void:
	_leasts.forget()
	if not _due:
		_due = true
		_settle.call_deferred()


func _settle() -> void:
	_due = false
	_place()
	update_minimum_size()


## The columns shown that fit this line: every one, or, where their leasts
## and the gaps are wider than it, as many as fit from the first, and the
## first whatever its width.
func get_fitted() -> Array:
	var shown: Array = _columns.read()
	var needs := 0.0
	# every column in order, until one would take the line past its width
	for at: int in shown.size():
		needs += _leasts.of(shown[at]["name"], self, _pad()) + (_gap() if at > 0 else 0.0)
		if needs > size.x and at > 0:
			return shown.slice(0, at)
	return shown


## The widths of the columns that fit, in order, at this width: shares,
## each held to its least.
func get_widths() -> Array[float]:
	var shown: Array = get_fitted()
	var parts: Array = shown.map(func(column: Dictionary) -> Dictionary: return {"base": 0.0, "least": _leasts.of(column["name"], self, _pad()), "most": INF, "grow": column["share"], "shrink": 0.0})
	return FlexLine.lengths(parts, size.x, _gap() * (shown.size() - 1))


## Which of the columns shown a point this far across falls in: its place
## among them, a gap counted with the column before it.
func part_at(x: float) -> int:
	var widths := get_widths()
	var end := 0.0
	# every column's width in order, until the one whose end is past the point
	for at: int in widths.size():
		end += widths[at] + _gap()
		if x < end:
			return at
	return widths.size() - 1


## Every part at its column's width in order, a hidden column's part hidden,
## an edge in each gap.
func _place() -> void:
	# attached before its parts are built into it, it has nothing to place until they are
	if get_child_count() < _names.size() + _edges:
		return
	placed_count += 1
	var shown: Array = get_fitted()
	var widths := get_widths()
	var cells := get_children().slice(0, get_child_count() - _edges)
	var edges := get_children().slice(get_child_count() - _edges)
	var named: Array = shown.map(func(column: Dictionary) -> StringName: return column["name"])
	# every part, shown only while its column is, and its edge only while another column follows it
	for index: int in cells.size():
		cells[index].visible = named.has(_names[index])
		if not edges.is_empty():
			edges[index].visible = named.has(_names[index]) and named.find(_names[index]) < named.size() - 1
	# every part and edge anchored at the top left, as a layout's are, so the place and size given here stand
	for part: Control in get_children():
		if part.anchor_right != 0.0 or part.anchor_bottom != 0.0:
			part.set_anchors_preset(Control.PRESET_TOP_LEFT)
	var x := 0.0
	# every shown column in order, its part placed and its edge put in the gap after it
	for at: int in shown.size():
		var index := _names.find(shown[at]["name"])
		var part: Control = cells[index]
		var tall := part.get_combined_minimum_size().y
		part.position = Vector2(x + _pad(), (size.y - tall) / 2.0)
		part.size = Vector2(widths[at] - 2.0 * _pad(), tall)
		x += widths[at]
		if not edges.is_empty():
			edges[index].position = Vector2(x, 0.0)
			edges[index].size = Vector2(_gap(), size.y)
		x += _gap()


## The first column's least across - the rest are dropped before they cut -
## and the tallest part down, and the ground's pad.
func _get_minimum_size() -> Vector2:
	var shown: Array = _columns.read()
	var across: float = _leasts.of(shown[0]["name"], self, _pad())
	var down := 0.0
	# every cell part, for the tallest
	for part: Node in get_children().slice(0, get_child_count() - _edges):
		down = maxf(down, (part as Control).get_combined_minimum_size().y)
	return Vector2(across, down + _box().get_minimum_size().y)


func _draw() -> void:
	draw_style_box(_box(), Rect2(Vector2.ZERO, size))


## The room either side of a cell's part, within its column.
func _pad() -> float:
	return float(get_theme_constant(&"pad", theme_type_variation))


func _gap() -> float:
	return float(get_theme_constant(&"gap", theme_type_variation))


func _box() -> StyleBox:
	return get_theme_stylebox(&"panel", theme_type_variation)


## The builder's door: the line, its parts built into it, then its edges.
static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"cells").new(ui.chimes, desc.props["columns"], desc.props["names"], desc.props["samples"], desc.props["words_kind"], desc.props["ground"])
	ui.attach(made, parent, desc.facts)
	made.set_edges(desc.props["edges"])
	return made
