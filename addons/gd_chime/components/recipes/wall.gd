extends RefCounted

const Tables := preload("../../theme_tables.gd")
const Ui := preload("../primitives/ui.gd")
const Options := preload("../primitives/options.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const KeyedItems := preload("../../keyed_items.gd")
const Status := preload("status.gd")
const Collections := preload("../../theme_collections.gd")

## A status wall: a tile for every item of a keyed set (keyed_items.gd) -
## five hundred devices, say - each its status's mark and its name, the
## tiles wrapping at the wall's width and the wall scrolling where they run
## past its height; and its legend, how many items stand in each state.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## ONE ITEM CHANGING DRAWS ONE MARK AGAIN AND LAYS NOTHING OUT: every tile
## reads its own item on that item's own bell, and a tile's room never
## moves with what it says - its mark is its look's size and its name is
## fixed - so neither the wall nor any tile beside it is placed again. The
## tiles are built once, as the wall is; a set whose members come and go is
## an each's, and pays for it.
##
## A TILE IS A PRESS, walked to by the keys and the pad by where it stands,
## brought into view by the wall's scroll as the focus moves - so the focus
## on one survives every change of every item, its own included.
##
## THE LEGEND'S COUNTS NEVER MOVE IT: each state's mark and its count in
## words stand in a column of the grid's own share, the words breaking at
## the column's width rather than widening it (status.gd), so a count going
## from nine to ten asks nothing of the layouts around it; the tallies ring
## at the look's cadence.

## The wall: the tiles, each tile(key) describing one - Wall.tile, most
## often - wrapping inside a scroll.
static func make(ui: Ui, items: KeyedItems, tile: Callable) -> Desc:
	return ui.scroll(ui.row(items.get_keys().map(tile), Collections.WALL))


## One tile: a press of this action carrying this payload, its state's mark
## - a bound value reading one of the status's states - beside its name.
## Its options: name, the words beside the mark, and goes_to, the place a
## press moves the reader to.
const TILE_OPTIONS: Array[String] = ["name", Options.GOES_TO]

static func tile(ui: Ui, action: StringName, payload: Dictionary, state: Bound, options: Dictionary = {}) -> Desc:
	Options.checked("a wall tile", options, TILE_OPTIONS)
	var name: Variant = options["name"]
	var goes_to: StringName = options.get(Options.GOES_TO, &"")
	return ui.pressable(action, payload, [Status.make(ui, state, name, {kind = Tables.WORDS})], Collections.WALL_TILE).goes_to(goes_to)


## The legend: for each state shown, {value - of the field tallied, state -
## the status's, counted - a function from how many to their words}, its
## mark and its words in a column of the same share, reading the tallies of
## the field.
static func legend(ui: Ui, items: KeyedItems, field: StringName, shown: Array) -> Desc:
	var tallied: RefCounted = items.tallied(field)
	var parts: Array = []
	var shares: Array[float] = []
	# every state shown, its column: a mark and its count in words that break rather than widen
	for one: Dictionary in shown:
		var words: Bound = tallied.map(func(counts: Dictionary) -> Variant: return one["counted"].call(counts.get(one["value"], 0)))
		parts.append(Status.make(ui, one["state"], words, {kind = Tables.WORDS, wraps = true}))
		shares.append(1.0 / shown.size())
	return ui.grid(parts, shares)
