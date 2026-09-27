extends Container

const Going := preload("going.gd")
const Shift := preload("shift.gd")
const Shape := preload("../../shape.gd")
const Transition := preload("transition.gd")
const Motion := preload("../../motion.gd")

## Named areas: the same parts laid into a grid of areas that each name a
## part, the grid chosen by the width THIS has - a dashboard's figures along
## the top and its charts under them on a wide screen, one over another on
## a narrow one - so the hierarchy is written once per width and kept.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## CSS Grid Layout's grid-template-areas, § 7.3: a LAYOUT is {least,
## columns, rows, areas}. AREAS is a line of words a row, each word the name
## of the part filling that cell, "." none; a part fills the rectangle of
## cells its name takes, and a name that takes no rectangle is said out
## loud. COLUMNS are shares of the width left after the gaps. ROWS are the
## least each row is: 0.0 as tall as its tallest part needs, or a share of
## the base height, the room past every row's least shared among the rows
## given a share, by their shares. LEAST is the width the layout needs, as
## by_width.gd takes it - a share of the base width or a look's constant
## under Shape - and the widest one the width meets is worn, so one is 0.0.
##
## ONE SET OF NODES, as by_shape.gd: the parts are built once, as the
## children of this, and a new layout only moves them - nothing is built,
## freed or taken out, so focus, a typed line and a scroll survive a
## re-flow. A part a layout names nowhere is hidden, never freed. A new
## layout is there at once and seen to arrive, the look's by_shape
## transition over the whole.
##
## Its gaps are the style's, "gap" and "row_gap", as a grid's. It needs, in
## height, every row's least and the gaps; in width, what its narrowest
## layout needs to make every part's columns as wide as the part needs -
## never the layout worn's, or a wide layout would hold this wide for ever. It lays out only as it is sorted - resized,
## or a part's need moving - never on a frame by itself.

const NONE := "."

var _names: Array  # the parts' names, in the order they were built
var _layouts: Dictionary
var _style: StringName
## The one clock a new layout arrives by, handed in by the builder as this is attached.
var motion: Motion = null
var _worn: StringName = &""
var _all_cells: Dictionary = {}  # every layout: part name -> Rect2i of the cells it fills there
var _cells: Dictionary = {}  # the layout worn's
var _sized: bool = false  # whether it has been given a width yet: the layout for the first is simply there


func _init(names: Array, layouts: Dictionary, style: StringName) -> void:
	_names = names
	_layouts = layouts
	_style = style
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# every layout's cells, read from its words once
	for named: StringName in layouts:
		_all_cells[named] = cells_of(layouts[named]["areas"])


## The layout worn now.
func get_worn() -> StringName:
	return _worn


## Which cells each part fills in a layout's areas - {name: Rect2i}, a
## column and row with how many across and down - a name that takes no
## rectangle said out loud.
static func cells_of(areas: Array) -> Dictionary:
	var found: Dictionary = {}
	# every row of the areas, and every word along it, widening its name's cells to hold it
	for row: int in areas.size():
		var words: PackedStringArray = areas[row].split(" ", false)
		# every word of the row, a cell of the part it names
		for column: int in words.size():
			if words[column] != NONE:
				var at := Rect2i(column, row, 1, 1)
				found[StringName(words[column])] = found[StringName(words[column])].merge(at) if found.has(StringName(words[column])) else at
	# every name, its rectangle checked cell by cell against the words
	for name: StringName in found:
		var cells: Rect2i = found[name]
		# every row of the rectangle
		for row: int in range(cells.position.y, cells.end.y):
			# every cell along it, which must name the part
			for column: int in range(cells.position.x, cells.end.x):
				if areas[row].split(" ", false)[column] != name:
					push_error("%s takes no rectangle in the areas %s" % [name, areas])
	return found


## The layout for this width: the widest least it meets, of the layouts
## whose parts it holds - a part wider than its columns would be drawn over
## its neighbour, so a layout it cannot hold is passed over for a narrower.
func layout_for(width: float) -> StringName:
	var best: StringName = &""
	var most := -1.0
	# every layout, keeping the widest least the width meets among those it holds
	for named: StringName in _layouts:
		var least: float = float(get_theme_constant(_layouts[named]["least"], Shape.TYPE)) if _layouts[named]["least"] is StringName else _layouts[named]["least"] * get_viewport().get_visible_rect().size.x
		if width >= least and least > most and width >= _needs_across(named):
			most = least
			best = named
	return best


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_RESIZED:
			_wear(layout_for(size.x), _sized)
			_sized = _sized or size.x > 0.0
		NOTIFICATION_SORT_CHILDREN: _arrange()


## This layout worn: its cells taken, every part it names shown and the
## rest hidden, and - once it has been given a width - the whole seen to arrive.
func _wear(named: StringName, arrives: bool) -> void:
	if named == _worn:
		return
	_worn = named
	_cells = _all_cells[named]
	# every part, shown where the layout names it
	for at: int in _names.size():
		(get_child(at) as Control).visible = _cells.has(_names[at])
	update_minimum_size()
	queue_sort()
	if arrives and is_visible_in_tree():
		Transition.enter(self, Transition.named(&"", &"by_shape", self), motion)


## Every row's height: its least, and the room past every least shared among the rows given a share.
func heights(room: float) -> Array[float]:
	var rows: Array = _layouts[_worn]["rows"]
	var least := _least_rows()
	var shared := 0.0
	var spare := room - get_theme_constant(&"row_gap", _style) * (rows.size() - 1)
	# every row, its least taken from the room and its share counted
	for row: int in rows.size():
		spare -= least[row]
		shared += rows[row]
	var made: Array[float] = []
	# every row, its least and its part of the room left
	for row: int in rows.size():
		made.append(least[row] + (maxf(spare, 0.0) * rows[row] / shared if shared > 0.0 else 0.0))
	return made


## Each row's least: its share of the base height, or what its parts need, a
## part down several rows asking the last of them for what the rest lack.
func _least_rows() -> Array[float]:
	var rows: Array = _layouts[_worn]["rows"]
	var least: Array[float] = []
	# every row, the least its share gives it
	for row: int in rows.size():
		least.append(rows[row] * get_viewport().get_visible_rect().size.y)
	# every part shown, its need laid on the rows it fills
	for at: int in _names.size():
		if _cells.has(_names[at]):
			var cells: Rect2i = _cells[_names[at]]
			var need := (get_child(at) as Control).get_combined_minimum_size().y - get_theme_constant(&"row_gap", _style) * (cells.size.y - 1)
			# every row it fills but the last, what they give it already
			for row: int in range(cells.position.y, cells.end.y - 1):
				need -= least[row]
			least[cells.end.y - 1] = maxf(least[cells.end.y - 1], need)
	return least


## Across, the least any layout needs - so whatever holds this may narrow
## it to its narrowest layout, and it wears that one there - and down, what
## the rows of the layout worn need.
func _get_minimum_size() -> Vector2:
	if _worn == &"":
		return Vector2.ZERO
	var narrowest := INF
	# every layout, for the width it needs
	for named: StringName in _layouts:
		narrowest = minf(narrowest, _needs_across(named))
	var rows := _least_rows()
	return Vector2(narrowest, rows.reduce(func(sum: float, one: float) -> float: return sum + one, 0.0) + get_theme_constant(&"row_gap", _style) * (rows.size() - 1))


## The width a layout needs: what makes every part's columns as wide as it needs.
func _needs_across(named: StringName) -> float:
	var columns: Array = _layouts[named]["columns"]
	var gap := get_theme_constant(&"gap", _style)
	var wide := 0.0
	# every part the layout names, for the width that makes its columns hold it
	for at: int in _names.size():
		if _all_cells[named].has(_names[at]):
			var cells: Rect2i = _all_cells[named][_names[at]]
			var share: float = columns.slice(cells.position.x, cells.end.x).reduce(func(sum: float, one: float) -> float: return sum + one, 0.0)
			wide = maxf(wide, ((get_child(at) as Control).get_combined_minimum_size().x - gap * (cells.size.x - 1)) / share + gap * (columns.size() - 1))
	return wide


## Every part shown fitted to the rectangle of its cells.
func _arrange() -> void:
	if _worn == &"":
		return
	var columns: Array = _layouts[_worn]["columns"]
	var gap := float(get_theme_constant(&"gap", _style))
	var row_gap := float(get_theme_constant(&"row_gap", _style))
	var across := size.x - gap * (columns.size() - 1)
	var tall := heights(size.y)
	# every part shown, its cells turned into a rect
	for at: int in _names.size():
		var part: Control = get_child(at)
		if not _cells.has(_names[at]) or Going.is_going(part):
			continue
		var cells: Rect2i = _cells[_names[at]]
		var left: float = gap * cells.position.x + across * columns.slice(0, cells.position.x).reduce(func(sum: float, one: float) -> float: return sum + one, 0.0)
		var wide: float = gap * (cells.size.x - 1) + across * columns.slice(cells.position.x, cells.end.x).reduce(func(sum: float, one: float) -> float: return sum + one, 0.0)
		var top: float = row_gap * cells.position.y + tall.slice(0, cells.position.y).reduce(func(sum: float, one: float) -> float: return sum + one, 0.0)
		var deep: float = row_gap * (cells.size.y - 1) + tall.slice(cells.position.y, cells.end.y).reduce(func(sum: float, one: float) -> float: return sum + one, 0.0)
		Shift.fit(self, part, Rect2(left, top, wide, deep))


static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"areas").new(desc.props["names"], desc.props["layouts"], desc.props["style"])
	ui.attach(made, parent, desc.facts)
	return made
