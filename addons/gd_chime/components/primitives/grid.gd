extends Container

## Parts laid into columns and rows, where a column is as wide as the parts on
## every row need it to be.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## CSS Grid Layout Level 1: § 7 for the columns, § 8 for where a part goes. How
## many columns there are, how wide each is and which cell a part falls into is
## grid_columns.gd; this file gathers what its parts need, asks, and sets the
## rects. It is not the line layout with more options and the difference is the
## point: a wrapping line sizes each line on its own, so the second thing on one
## line has nothing to do with the second thing on the next, and columns that
## line up are the one arrangement it can never produce. Every table is that,
## and so is a matrix.
##
## Columns are declared one of two ways - as shares of what is left after the
## gaps, or as many equal columns of at least a width as fit. That least width
## is in pixels, from whoever builds this, because it is about what the content
## needs to be readable rather than about the window, which is the same
## exception the gap already is.
##
## A row is as tall as the tallest part in it. Uniform rows belong to a windowed
## list, which is its own component: baking them in here would space a grid of
## two-line and three-line parts by the worst one.
##
## Parts fill the next free cell in the order they were placed. A hole left by a
## part that did not fit the room left on its row stays a hole, because moving a
## later part into it puts the fifth thing before the fourth for no reason the
## reader can see.
##
## A part's facts are held here against the part for as long as it is here, as
## the line layout holds them. Taken out, freed or moved to another parent, it
## is forgotten, so what is held is never more than the parts there are.
##
## It extends the engine's Container for the same reason the line layout does,
## and is told the same things with nothing connected: a part's smallest size
## changing, its own resize, a part added, hidden or freed. A window resize
## therefore reaches it through its rect, as it reaches a line. It takes no
## press: what it holds does.
##
## What room the layout itself needs is what its parts need between them - and
## whoever builds it may hold open more with the engine's own custom minimum,
## which the engine takes the larger of. That is how a layout still waiting for
## its parts holds its room rather than reporting nothing and letting the
## arrangement above it be chosen on a screen that has not arrived.
##
## Deliberately absent, each a pure addition: named areas; placing a part at a
## line it names, which would be a position, and the map holds none; packing
## parts to fill holes; spans down the rows; columns sized to their content
## rather than in shares; and the sticking axes a matrix wants, which is a thing
## to draw rather than a way to place.

const GridColumns := preload("grid_columns.gd")
const Shift := preload("shift.gd")

const STRETCH := 0
const START := 1
const CENTER := 2
const END := 3

## What may be said about a part. Anything else is a mistake, not a request.
const FACTS := ["span", "align"]

var align: int = STRETCH

## How many times the parts have been placed, so that the engine coalescing two
## changes into one is something a test can read rather than something it argues.
var arrange_count: int = 0

var _shares: Array[float] = []
var _least_column: float = 0.0
var _gap: float
var _row_gap: float
var _facts: Dictionary = {}  # part -> what was given for it


func _init(gap: float, row_gap: float) -> void:
	_gap = gap
	_row_gap = row_gap
	# it takes no press, what it holds does: laid over another layer it never swallows that layer's presses
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## The gaps between columns and between rows, in pixels.
func set_gaps(gap: float, row_gap: float) -> void:
	_gap = gap
	_row_gap = row_gap
	queue_sort()


## Columns in the shares they take of what is left after the gaps - and so
## the room it needs, which whatever holds it is told.
func set_shares(of: Array[float]) -> void:
	_shares = of
	_least_column = 0.0
	update_minimum_size()
	queue_sort()


## As many equal columns of at least this width as fit, and one when none does.
func set_auto_columns(least: float) -> void:
	_shares = []
	_least_column = least
	update_minimum_size()
	queue_sort()


## Put a part in, with the facts that place it. A fact this layout has no
## meaning for leaves the part unplaced and says so: laying it out on a guess
## would be a wrong screen nobody was told about.
func place(part: Control, facts: Dictionary = {}) -> void:
	# every fact given, refusing one that means nothing here
	for given: String in facts:
		if not FACTS.has(given):
			push_error("a grid part has no %s; it has %s" % [given, FACTS])
			return
	_facts[part] = facts
	add_child(part)


## What was given for this part, as a copy - or nothing, for a part that is not
## in this layout.
func get_facts(part: Control) -> Dictionary:
	return _facts[part].duplicate() if _facts.has(part) else {}


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SORT_CHILDREN:
			_arrange()
		NOTIFICATION_CHILD_ORDER_CHANGED:
			# every part given facts, forgetting one that is no longer a child here
			for part: Control in _facts.keys():
				if part.get_parent() != self:
					_facts.erase(part)


## The smallest this can be and still hold its parts. With the columns declared
## the rows are known without a width, so it is both of them. Auto-fitting, it
## is one column wide and its deepest part deep: a truer answer needs the width
## the parts would fill at, and the engine asks without one.
func _get_minimum_size() -> Vector2:
	var parts := _shown()
	if parts.is_empty():
		return Vector2.ZERO
	var needs := _needs(parts)
	if _shares.is_empty():
		var widest := _least_column
		var deepest := 0.0
		# every part, for the widest and the deepest of them
		for part: Control in parts:
			widest = maxf(widest, part.get_combined_minimum_size().x)
			deepest = maxf(deepest, part.get_combined_minimum_size().y)
		return Vector2(widest, deepest)
	var spans := _spans(parts)
	var at := GridColumns.cells(spans, _shares.size())
	var least := GridColumns.least_of(spans, needs, at, _shares.size(), _gap)
	var across := _gap * (_shares.size() - 1)
	# every column, for the width they need between them
	for width: float in least:
		across += width
	var depths := _depths(parts, at)
	var down := _row_gap * (depths.size() - 1)
	# every row, for the depth they need between them
	for depth: float in depths:
		down += depth
	return Vector2(across, down)


func _arrange() -> void:
	arrange_count += 1
	var parts := _shown()
	if parts.is_empty():
		return
	var spans := _spans(parts)
	var count := GridColumns.count(_shares, _least_column, size.x, _gap)
	if count == 0:
		return
	var at := GridColumns.cells(spans, count)
	var widths := GridColumns.widths(spans, _needs(parts), at, _shares, _least_column, size.x, _gap)
	var depths := _depths(parts, at)
	# every part, placed in the cell it fell into at its scale and turn, its shift left to whoever slides it (shift.gd)
	for which: int in parts.size():
		var part: Control = parts[which]
		var column: int = at[which].y
		var span: int = mini(spans[which], count)
		var across := _gap * column
		# the columns before this part, for where it starts
		for before: int in column:
			across += widths[before]
		var wide := _gap * (span - 1)
		# the columns this part covers, for how wide it is
		for covered: int in range(column, column + span):
			wide += widths[covered]
		var down := _row_gap * at[which].x
		# the rows above this part, for where it starts down the grid
		for above: int in at[which].x:
			down += depths[above]
		var sits: int = _facts[part]["align"] if _facts[part].has("align") else align
		var deep: float = depths[at[which].x] if sits == STRETCH else part.get_combined_minimum_size().y
		var off := 0.0
		match sits:
			CENTER: off = (depths[at[which].x] - deep) / 2.0
			END: off = depths[at[which].x] - deep
		Shift.fit(self, part, Rect2(Vector2(across, down + off), Vector2(wide, deep)), false)


## How deep each row is: the deepest part in it.
func _depths(parts: Array[Control], at: Array[Vector2i]) -> Array[float]:
	var depths: Array[float] = []
	depths.resize(at[at.size() - 1].x + 1)
	depths.fill(0.0)
	# every part, against the row it fell into
	for which: int in parts.size():
		depths[at[which].x] = maxf(depths[at[which].x], parts[which].get_combined_minimum_size().y)
	return depths


## How wide each part needs to be, which is all the columns are worked out from.
func _needs(parts: Array[Control]) -> Array[float]:
	var needs: Array[float] = []
	# every part, for the width it says it needs
	for part: Control in parts:
		needs.append(part.get_combined_minimum_size().x)
	return needs


## How many columns each part covers, one where it did not say.
func _spans(parts: Array[Control]) -> Array[int]:
	var spans: Array[int] = []
	# every part, for the columns it covers
	for part: Control in parts:
		spans.append(int(_facts[part]["span"]) if _facts[part].has("span") else 1)
	return spans


## The parts it lays out, in the order they were placed. A part that is not
## shown takes no cell, so the parts after it close up.
func _shown() -> Array[Control]:
	var parts: Array[Control] = []
	# every child that is a shown control, since anything else is not laid out
	for child: Node in get_children():
		if child is Control and (child as Control).visible:
			parts.append(child)
	return parts
