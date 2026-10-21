extends "flex.gd"

const Themes := preload("../../theme.gd")
const Shape := preload("../../shape.gd")

const Going := preload("going.gd")
const GridColumns := preload("grid_columns.gd")

## A row or a column: the line layout (flex.gd) with its gap a Theme name.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The style is a variation of Container holding the constant gap, in the
## base pixels the engine scales, the constants justify and align in the
## line layout's own words, and wrap, which is whether the line breaks
## onto more lines - tiles do; read once as this enters the tree. A part's
## facts - grow, basis - are the description's. A style the look does not
## know is laid out as its base, a row or a column: every recipe names its
## own style, and the floor's look defines the bases alone.
##
## WRAPPING IN EQUAL COLUMNS: a wrapping style naming least_column, in base
## pixels, lays its parts in as many columns of at least that as fit, every
## part as wide as a column - CSS Grid's repeat(auto-fill, minmax(least,
## 1fr)) - so a last line short of parts keeps their width and starts at
## the line's start, and a wider room makes more columns, never wider
## parts. It sets every part's basis and most to a column's share as the
## line is placed; a part's own grow and basis mean nothing here. A style
## naming none leaves every part its own length. A column is never under
## the widest part's least, so no part is wider than its column, and the
## least this needs across is one column.
##
## COLUMNS (ui.columns) are a row laid that way whatever its style says,
## the least a column is the look's constant each use names under the type
## Columns, in base pixels - none named, the widest part's least - and at
## most `most` of them: clamp(floor((room + gap) / (least + gap)), 1,
## most), the count grid_columns.gd gives. BALANCED, the fewest columns
## that make the same rows, so ten that fit six across stand five and five.
## SHARING THE HEIGHT, its rows share what is left down when every one fits
## at its least, and otherwise each is its least and the page scrolls
## (flex_lines.gd).
##
## A PART'S MOST MAY BE A LOOK'S CONSTANT, named under Shape, in base pixels
## (desc.gd, at_most): it is made a share of the line again each time the
## line is placed, since the line's length is what a share is of.
##
## WHAT IT WOULD TAKE GIVEN ALL THE ROOM IT WANTS (preferred_size): along a
## row, and along a line that wraps as if it were one line, every part at
## its own preferred width - at least a column where it lays its parts in
## columns - with its gaps; down a column, the widest of its parts. A line
## holding this starts it there (preferred.gd).
##
## IT TAKES NO PRESS: what it holds does. A line laid over another layer -
## a look's floating row of pills over a panel - would otherwise take every
## press between its parts, and the panel's buttons beneath would be dead.

## The look's type holding the least a column is, under the name each use of columns gives it, in base pixels.
const COLUMNS := &"Columns"

var _style: StringName  # the style described, tried again on every look
var _reading: bool = false  # while the look is being read, so a fallback set here is not heard as another look
var _least_column: float = 0.0  # wrapping, the least a column may be; none, every part its own length
var _named_most: Dictionary = {}  # part -> the name of the look's constant, in base pixels, that is the most it may be along the line
var _as_columns: bool = false  # laid in columns (ui.columns), wrapping whatever its style says
var _least_named: StringName = &""  # as columns, the look's constant under Columns that is the least a column is; none, the widest part's least
var _most: int = 0  # as columns, the most there may be; none, as many as fit
var _balanced: bool = false  # as columns, the fewest that make the same rows


func _init(direction: int, style: StringName) -> void:
	super(direction, false, 0.0)
	_style = style
	theme_type_variation = style
	# what it holds takes the presses: the engine's own for a Container would take them between its parts
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _ready() -> void:
	_read_look()


## Laid in columns (ui.columns): told before it enters the tree, where the look is read.
func lays_columns(least: StringName, most: int, balanced: bool, shares_height: bool) -> void:
	_as_columns = true
	_least_named = least
	_most = most
	_balanced = balanced
	_rows_share = shares_height


## How many columns stand across: as many of at least the least as fit, at
## most `most` - none, no most - and balanced, the fewest that make the same
## rows; never fewer than one, which a share of the room is divided by.
static func across(parts: int, fit: int, most: int, balanced: bool) -> int:
	var count := maxi(1, mini(fit, most) if most > 0 else fit)
	if not balanced:
		return count
	# the rows that many columns make, then the fewest columns that make no more rows
	return ceili(float(parts) / ceili(float(parts) / count))


## The least it needs across: its parts', and wrapping in columns, one column.
func _get_minimum_size() -> Vector2:
	return super().max(_vector(_least_column, 0.0))


## Put a part in, with the facts that size it: a most named by a look's
## constant is kept by its name, and made a share of the line as it is placed.
func place(part: Control, facts: Dictionary = {}) -> void:
	if facts.get("max") is StringName:
		_named_most[part] = facts["max"]
		facts = facts.duplicate()
		facts.erase("max")
	super(part, facts)


## What it would take given all the room it wants (preferred.gd): its parts
## at theirs along a row, the widest of them down a column; never under its least.
func preferred_size() -> Vector2:
	var least := get_combined_minimum_size()
	return Vector2(maxf(least.x, Preferred.line(_in_order(), _direction == COLUMN, _gap, _least_column)), least.y)


## The look read again as the theme changes, so a look put on the root
## while this shows re-places its parts.
func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_inside_tree() and not _reading:
		_read_look()
	if what == NOTIFICATION_PRE_SORT_CHILDREN and (_least_column > 0.0 or _as_columns) and _main(size) > 0.0:
		_share_columns()
	if what == NOTIFICATION_PRE_SORT_CHILDREN and _main(size) > 0.0:
		# every part whose most is a look's constant: that, as a share of the line it is placed on now
		for part: Control in _named_most:
			_facts[part]["max"] = minf(get_theme_constant(_named_most[part], Shape.TYPE) / _main(size), 1.0)
	if what == NOTIFICATION_CHILD_ORDER_CHANGED:
		# every part whose most is named, forgetting one that is no longer a child here, as the line forgets its facts
		for part: Control in _named_most.keys():
			if part.get_parent() != self:
				_named_most.erase(part)


## Every part as wide as one of as many columns of at least the least - and
## never under the widest part's least - as stand across (across()), the
## gaps between them taken first - a hair less, so the parts of a full line
## never sum past the room.
func _share_columns() -> void:
	var room := _main(size)
	var parts := _in_order()
	if parts.is_empty():
		return
	# the widest least of the parts placed, which no column may be under
	var widest: float = parts.reduce(func(most: float, part: Control) -> float: return maxf(most, _main(part.get_combined_minimum_size())), 0.0)
	var count := across(parts.size(), GridColumns.count([], maxf(_least_column, widest), room, _gap), _most, _balanced)
	var share := maxf((room - _gap * (count - 1)) / count - 0.01, 0.0) / room
	# every part placed here, its facts kept but for its length, which is a column's
	for part: Control in _facts:
		_facts[part].merge({"basis": share, "max": share, "grow": 0.0}, true)


func _read_look() -> void:
	_reading = true
	_wear(_style)
	if not has_theme_constant(&"align"):
		_wear(Themes.ROW if _direction == ROW else Themes.COLUMN)
	_reading = false
	justify = get_theme_constant(&"justify")
	align = get_theme_constant(&"align")
	set_gap(float(get_theme_constant(&"gap")))
	set_wrap(get_theme_constant(&"wrap") != 0 or _as_columns)
	_least_column = float(get_theme_constant(&"least_column")) if _wrap and not _as_columns else 0.0
	if _as_columns and _least_named != &"":
		_least_column = float(get_theme_constant(_least_named, COLUMNS))

## The variation set only when it changes, and never while a look is
## being read: setting it tells this the theme changed, and that is where
## this is asked from.
func _wear(variation: StringName) -> void:
	if theme_type_variation != variation:
		theme_type_variation = variation


## Whether its parts run along, as a row's do, rather than down.
func is_row() -> bool:
	return _direction == ROW


## The parts a line takes: the line layout's, less any that is going
## (going.gd) - still drawn where it stood, but neither placed nor measured,
## so what is left closes up as if it had gone.
func _in_order() -> Array[Control]:
	return super._in_order().filter(func(part: Control) -> bool: return not Going.is_going(part))


## The builder's door for a row, a column and columns alike.
static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(desc.kind).new(COLUMN if desc.kind == &"column" else ROW, desc.props["style"])
	if desc.kind == &"columns":
		made.lays_columns(desc.props["least"], desc.props["most"], desc.props.has("balanced"), desc.props.has("shares_height"))
	ui.attach(made, parent, desc.facts)
	return made