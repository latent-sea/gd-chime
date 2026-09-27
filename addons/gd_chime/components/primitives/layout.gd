extends "flex.gd"

const Themes := preload("../../theme.gd")

const Going := preload("going.gd")

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
## naming none leaves every part its own length.
##
## IT TAKES NO PRESS: what it holds does. A line laid over another layer -
## a look's floating row of pills over a panel - would otherwise take every
## press between its parts, and the panel's buttons beneath would be dead.


var _style: StringName  # the style described, tried again on every look
var _reading: bool = false  # while the look is being read, so a fallback set here is not heard as another look
var _least_column: float = 0.0  # wrapping, the least a column may be; none, every part its own length


func _init(direction: int, style: StringName) -> void:
	super(direction, false, 0.0)
	_style = style
	theme_type_variation = style
	# what it holds takes the presses: the engine's own for a Container would take them between its parts
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _ready() -> void:
	_read_look()


## The look read again as the theme changes, so a look put on the root
## while this shows re-places its parts.
func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_inside_tree() and not _reading:
		_read_look()
	if what == NOTIFICATION_PRE_SORT_CHILDREN and _least_column > 0.0 and _main(size) > 0.0:
		_share_columns()


## Every part as wide as one of as many columns of at least the least as fit
## the room, the gaps between them taken first - a hair less, so the parts
## of a full line never sum past the room.
func _share_columns() -> void:
	var room := _main(size)
	var count := maxi(floori((room + _gap) / (_least_column + _gap)), 1)
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
	set_wrap(get_theme_constant(&"wrap") != 0)
	_least_column = float(get_theme_constant(&"least_column")) if _wrap else 0.0

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


## The builder's door for a row and a column alike.
static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(desc.kind).new(ROW if desc.kind == &"row" else COLUMN, desc.props["style"])
	ui.attach(made, parent, desc.facts)
	return made