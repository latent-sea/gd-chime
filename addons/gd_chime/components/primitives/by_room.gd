extends "by_width.gd"

## The same parts in the first of their arrangements, in the order they are
## preferred, that fits the room THIS has: a row of them while the row fits,
## a column of them where it does not - read off the parts' own least
## sizes, never off a breakpoint written for them.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## AN ARRANGEMENT FITS where its least across (by_width.gd) is at most the
## width this has - and, given most_tall, a share, where its least down is
## also at most that share of the safe room's height (shape.gd's
## safe_size), a value the window publishes: never the height of anything
## holding this, which is only what that holder gave it. Where none fits
## it wears the narrowest, which its least lets any holder make room for.
## It chooses again whenever its width moves and whenever its parts are
## placed, since a part's least moving - words said again - can leave the
## one worn too wide with nothing resized.
##
## ITS LEAST IS ITS NARROWEST ARRANGEMENT'S (by_width.gd), AND WHAT IT
## WOULD TAKE GIVEN ALL THE ROOM IT WANTS IS ITS FIRST'S: the parts at their
## preferred widths as the first runs (preferred.gd), so a line holding it
## starts it as it would most like to stand and narrows it from there into
## the arrangements after.
##
## Everything else is by_shape's: one set of nodes, built once, and a new
## arrangement there at once and seen to arrive.
##
## A ROW MARKED stacks (desc.gd) IS ONE OF THESE: its parts named by where
## they stand, the row as it was described first, and a column of the same
## parts second, each part its own length down it.
##
## IT NEVER READS THE WINDOW OR THE DEVICE: only its own width, its parts'
## sizes, and the safe room's height.

var _order: Array  # the arrangements' keys, in the order they are preferred
var _most_tall: float  # the share of the safe room's height an arrangement may need down; none, no limit


func _init(ui: RefCounted, names: Array, arrangements: Array, most_tall: float, asked: StringName) -> void:
	_most_tall = most_tall
	# each arrangement's key, where it stands in the order preferred: "0" first
	_order = range(arrangements.size()).map(func(at: int) -> StringName: return StringName(str(at)))
	var keyed: Dictionary = {}
	# every arrangement, keyed by where it stands in the order preferred
	for at: int in arrangements.size():
		keyed[_order[at]] = arrangements[at]
	super(ui, names, keyed, {}, asked)


## The first arrangement, in the order preferred, that fits the width this
## has and the height it may take; the narrowest where none does; the first
## before its parts are gathered.
func key_now() -> StringName:
	# the safe room's height read first, so that it is followed from the start wherever a most is given
	var tall: float = _most_tall * _ui.shape.safe_size.read().y if _most_tall > 0.0 else INF
	if not _gathered:
		return _order[0]
	var narrowest: StringName = _order[0]
	# every arrangement in the order preferred, for the first that fits, keeping the narrowest for where none does
	for named: StringName in _order:
		var across := least_across(_arrangements[named])
		if across <= size.x + 0.01 and least_down(_arrangements[named]) <= tall:
			return named
		if across < least_across(_arrangements[narrowest]):
			narrowest = named
	return narrowest


## What it would take given all the room it wants (preferred.gd): its parts
## at their preferred widths as its first arrangement runs; never under its least.
func preferred_size() -> Vector2:
	var least := get_combined_minimum_size()
	if not _gathered:
		return least
	var first: Dictionary = _arrangements[_order[0]]
	return Vector2(maxf(least.x, Preferred.line(_shown(first), first["down"], get_theme_constant(&"gap", _style_of(first)))), least.y)


## An arrangement taken up as by_shape takes one, and what this needs asked
## again: down, it is the arrangement worn's, which the engine is not told of.
func _take_up(named: StringName) -> void:
	var worn := _worn
	super(named)
	if _worn != worn:
		update_minimum_size()


## Before its parts are placed, once it has been given a width, the
## arrangement for that width taken up again: what its parts need may have
## moved with nothing resized.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PRE_SORT_CHILDREN and _gathered and _sized:
		_take_up(key_now())


## The builder's door: the parts described are its contents, in the
## arrangements given in the order preferred - or, for a row marked
## stacks, the row as it was described and then a column of its parts.
static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control
	if desc.props.has("stacks"):
		var named: Array = range(desc.children.size()).map(func(at: int) -> StringName: return StringName("part_%d" % at))
		var along: Dictionary = {}
		# every part, with its facts along the row as it was described
		for at: int in named.size():
			along[named[at]] = desc.children[at].facts
		made = ui.primitive(&"by_room").new(ui, named, [ui.row_of(named, along, desc.props["style"]), ui.column_of(named)], 0.0, desc.props.get("transition", &""))
	else:
		made = ui.primitive(&"by_room").new(ui, desc.props["names"], desc.props["arrangements"], desc.props["most_tall"], desc.props.get("transition", &""))
	ui.attach(made, parent, desc.facts)
	return made
