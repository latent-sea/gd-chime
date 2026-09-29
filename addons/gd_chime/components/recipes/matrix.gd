extends RefCounted

const Themes := preload("../../theme.gd")
const Ui := preload("../primitives/ui.gd")
const Options := preload("../primitives/options.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")

## A matrix: two axes and what their crossing says. A set down the rows, a
## set across the columns, and for each pair a cell the matrix asks the
## next layer for - a function of the row and the column - and places. It
## knows nothing about what it is showing. ONE SET AGAINST ITSELF shows one
## triangle, the diagonal being meaningless.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Its cells belong to two things: a cell is the crossing, and a crossing
## may produce nothing, which is an answer. The row labels are the caller's
## - a navigation control on each - and the column labels overhead, with
## the corner above both, where a window control can sit. Both axes are
## bound values kept by key, so a row added is one line built.


## The matrix: the corner and the column labels across the top, then one
## line per row - its label, then a cell per column from the function of
## the two handles. Its options: cell, the function of a row and a column;
## row_label and column_label, the functions naming an axis; key, what a
## row or a column is kept by; corner, what stands over both sets of
## labels; symmetric, for one set against itself, which shows only the
## crossings past the diagonal; and style.
const OPTIONS: Array[String] = ["cell", "row_label", "column_label", "key", "corner", "symmetric", Options.STYLE]

static func make(ui: Ui, rows: Bound, columns: Bound, options: Dictionary = {}) -> Desc:
	Options.checked("a matrix", options, OPTIONS)
	var cell: Callable = options["cell"]
	var row_label: Callable = options["row_label"]
	var column_label: Callable = options["column_label"]
	var key: Callable = options["key"]
	var corner: Variant = options.get("corner")
	var symmetric: bool = options.get("symmetric", false)
	var style: StringName = options.get(Options.STYLE, &"Matrix")
	# the first column is one share of every line, corner and row labels alike, and never more, whatever its words need; the rest is split equally, so every column sits under its label
	var share := 1.0 / float(_count(columns) + 1)
	var labels := ui.each_across(columns, func(column: Bound) -> Desc: return (column_label.call(column) as Desc).basis(0.0).grow(), key)
	var head := ui.row([(corner if corner != null else ui.text("")).basis(share).at_most(share), labels.basis(1.0 - share)], &"MatrixLine")
	var line := func(row: Bound) -> Desc:
		var cells := ui.each_across(columns, func(column: Bound) -> Desc: return _crossing(ui, row, column, cell, key, symmetric), key)
		return ui.row([(row_label.call(row) as Desc).basis(share).at_most(share), cells.basis(1.0 - share)], &"MatrixLine")
	# the lines stand inside the scroll's padding, so the labels above them are kept in by the same
	return ui.column([ui.surface(Themes.ABOVE_SCROLL, [head]), ui.scroll(ui.each(rows, line, key)).grow()], style)


## One crossing: the cell function's description, or nothing past the
## diagonal of a symmetric matrix.
static func _crossing(ui: Ui, row: Bound, column: Bound, cell: Callable, key: Callable, symmetric: bool) -> Desc:
	if symmetric:
		var shown: Bound = row.map(func(item: Variant) -> bool: return item != null and column.read() != null and key.call(item) < key.call(column.read()))
		return ui.when(shown, cell.call(row, column), ui.text("")).basis(0.0).grow()
	return (cell.call(row, column) as Desc).basis(0.0).grow()


static func _count(columns: Bound) -> int:
	var items: Variant = columns.read()
	return maxi(1, items.size() if items != null else 1)
