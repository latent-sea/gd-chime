extends "grid.gd"

const Going := preload("going.gd")
const Bound := preload("bound.gd")

## A grid: the column layout (grid.gd) with its gaps Theme names and its
## columns declared as shares - one set of them, or one per shape of window.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The style is a variation of Container holding the constants gap and
## row_gap, in the base pixels the engine scales, read once as this enters
## the tree. The columns are shares of what is left after the gaps, or, given
## none, as many equal columns as fit of at least the constant least_column.
## A part's facts - span - are the description's.
##
## TURNED, IT RE-FLOWS. Given columns for a shape of window - a window on its
## end, say, where four columns side by side would each be too narrow to
## read - it takes those while the window is that shape and its own the rest
## of the time, heard as the window turns (shape.gd). The cells are the SAME
## cells: only the shares change, so they fall into the columns there are in
## the order they were given, a cell covering more columns than there are
## covers the row (grid_columns.gd), and a typed line, the focus and a scroll
## inside a cell are where they were. Rebuilding the cells for each shape
## would lose exactly those, as by_shape.gd says of two descriptions.

var _columns: Array[float]  # the shares it takes on a window of any shape not named in _turned
var _turned: Dictionary  # a shape of window -> the shares it takes on one
var _reads: Bound  # the shape of the window now
var _chimes: RefCounted  # the chimes the shape is heard through


func _init(columns: Array[float], style: StringName, turned: Dictionary, reads: Bound, chimes: RefCounted) -> void:
	super(0.0, 0.0)
	_columns = columns
	_turned = turned
	_reads = reads
	_chimes = chimes
	theme_type_variation = style
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# the shape followed - by a grid given columns for a shape, which alone has cause to listen
	if not turned.is_empty():
		chimes.follow(self, &"shape", _shape_moved)


func _ready() -> void:
	set_gaps(float(get_theme_constant(&"gap")), float(get_theme_constant(&"row_gap")))
	_take_columns()


## The shape read, so it is followed; the window turned once this is
## ready, the columns for the shape it is now.
func _shape_moved() -> void:
	_reads.read()
	if is_node_ready():
		_take_columns()


## The engine tells every script in the chain, so the grid's own
## notification runs as well without a call from here.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and not _turned.is_empty():
		_chimes.stop_all(self)


## The shares for the shape the window is now, or its own; given none, as
## many equal columns as fit.
func _take_columns() -> void:
	var shares: Array[float] = []
	# a shape it was given columns for takes those; any other, its own
	shares.assign(_turned[_reads.read()] if _turned.has(_reads.read()) else _columns)
	if shares.is_empty():
		set_auto_columns(float(get_theme_constant(&"least_column")))
	else:
		set_shares(shares)


## The parts a grid takes: the grid's own, less any that is going (going.gd) -
## still drawn where it stood, but given no cell, so the rest close up.
func _shown() -> Array[Control]:
	return super._shown().filter(func(part: Control) -> bool: return not Going.is_going(part))


## The builder's door: the columns for a shape of window are the
## description's, where it gives any.
static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"grid").new(desc.props["columns"], desc.props["style"], desc.props["turned"], ui.shape.orientation, ui.chimes)
	ui.attach(made, parent, desc.facts)
	return made
