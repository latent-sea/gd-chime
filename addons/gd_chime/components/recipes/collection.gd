extends RefCounted

const Themes := preload("../../theme.gd")
const Ui := preload("../primitives/ui.gd")
const Options := preload("../primitives/options.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")

## A collection: many peers of one set, laid out as ROWS or as TILES, and
## acted on. The shape is not the identity - one component, since sorting,
## filtering and selecting are the same either way. An OUTCOME LIST is one
## in outcome order.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## It owns the set, the layout, the ordering and the selection; what a
## cell looks like is the template's - a card, a line of readouts. The
## members are a bound value the MODEL has already sorted and filtered, so
## every rule stays a refusal or a command on the model: the controls that
## sort and the filter-set that narrows are descriptions passed in and
## placed above the members, not logic here. The members are kept by key,
## so a sort reorders and a filter shortens without rebuilding a cell.
## Operable without a pointer: every cell is a pressable of its own.

const ROWS := &"rows"
const TILES := &"tiles"


## The collection: the controls above, the filter-set beside them, and the
## members below in the shape asked, each from the template by its key.
## Its options: key, what a member is kept by; shape, ROWS or TILES;
## controls, the row of presses above; filters, the filter-set beside
## them; and style.
const OPTIONS: Array[String] = ["key", "shape", "controls", "filters", Options.STYLE]

static func make(ui: Ui, members: Bound, template: Callable, options: Dictionary = {}) -> Desc:
	Options.checked("a collection", options, OPTIONS)
	var key: Callable = options["key"]
	var controls: Array = options.get("controls", [])
	var filters: Variant = options.get("filters")
	var above: Array = []
	if not controls.is_empty():
		above.append(ui.row(controls, &"Controls"))
	if filters != null:
		above.append(filters)
	var laid := ui.each_across(members, template, key, Themes.TILES) if options.get("shape", ROWS) == TILES else ui.each(members, template, key)
	return ui.column(above + [ui.scroll(laid).grow()], options.get(Options.STYLE, &"Collection"))


## An outcome list: one entry per possible outcome, in the model's outcome
## order, each saying what it returns - rows, with no controls above.
static func outcomes(ui: Ui, members: Bound, template: Callable, key: Callable) -> Desc:
	return make(ui, members, template, {key = key, style = &"Outcomes"})
