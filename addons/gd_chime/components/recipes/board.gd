extends RefCounted

const Themes := preload("../../theme.gd")
const Ui := preload("../primitives/ui.gd")
const Options := preload("../primitives/options.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")

## A board: a ranked list of participants with the reader's own position
## always findable - one board per measure, several boards not one.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The ranking is the model's, authoritatively derived; this lays it out
## as rows kept by key, each row from the template, and keeps the scroll on
## the reader's own row: a bound value names which row is theirs, and the
## window is brought to it whenever the ranking moves. Every name in a row
## is the template's navigation control.


const ROW := &"board_row_"  # every row named after its key under this


## The board: a scroll over the ranked rows, revealing the reader's own.
## Its options: key, what a row is kept by; own, a bound value reading the
## reader's own row, which is revealed; and style.
const OPTIONS: Array[String] = ["key", "own", Options.STYLE]

static func make(ui: Ui, ranked: Bound, template: Callable, options: Dictionary = {}) -> Desc:
	Options.checked("a board", options, OPTIONS)
	var key: Callable = options["key"]
	var own: Bound = options["own"]
	var style: StringName = options.get(Options.STYLE, &"Board")
	var reveal: Bound = own.map(func(mine: Variant) -> Variant: return StringName(ROW + str(mine)) if mine != null else null)
	return ui.scroll(ui.each(ranked, template, key, style).pieces_named(ROW), reveal)
