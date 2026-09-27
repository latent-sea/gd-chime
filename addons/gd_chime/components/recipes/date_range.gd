extends RefCounted

const Themes := preload("../../theme.gd")
const Ui := preload("../primitives/ui.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const InlineChoice := preload("inline_choice.gd")
const Stretch := preload("../../stretch.gd")
const Phrase := preload("../../phrase.gd")

## A date range: the stretch a filters' date column stands in - whichever
## presets the application handed in, today and the last 7 days among them -
## as one segmented choice, and, where the one picked sets no length, the
## first and last day the reader sets by hand.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## IT HOLDS NOTHING: the stretch picked and its days are the filters'
## (filters.gd, stretch.gd), and every press is one of its actions through
## the door - PICKS {value} from the segments (inline_choice.gd),
## SETS_FIRST_DAY and SETS_LAST_DAY from the days set by hand - so a day
## refused is refused by the filters, in their words, on the control that
## asked.
##
## THE DAYS SET BY HAND ARE A DATE FIELD'S: a function (ui, action, shows)
## -> description the caller hands in - the form's date field, whose press
## carries {"value": a day, or null} - and nothing here writes one.
##
## Deliberately absent: a comparison. Whether a dashboard sets each figure
## beside the stretch before is the dashboard's, not the stretch's.

const RANGE := &"DateRange"


## The range over a filters' date column: the presets as segments, and the
## days set by hand - each field the function given makes - while the
## preset picked sets no length.
static func make(ui: Ui, stretch: Stretch, by_hand: Callable, style: StringName = RANGE) -> Desc:
	var presets := InlineChoice.segments(ui, Stretch.PICKS, ui.bound(stretch.get_presets), ui.bound(stretch.get_picked))
	var days := ui.row([ui.text(Phrase.of("From"), Themes.REASON), by_hand.call(ui, Stretch.SETS_FIRST_DAY, ui.bound(stretch.get_first_day)), ui.text(Phrase.of("To"), Themes.REASON), by_hand.call(ui, Stretch.SETS_LAST_DAY, ui.bound(stretch.get_last_day))])
	return ui.row([presets, ui.when(ui.bound(stretch.get_by_hand), days)], style)
