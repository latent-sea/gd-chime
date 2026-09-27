extends RefCounted

const Ui := preload("../primitives/ui.gd")
const Options := preload("../primitives/options.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Formats := preload("../../formats.gd")
const Phrase := preload("../../phrase.gd")
const CellReadout := preload("cell_readout.gd")
const LoadedOrEmpty := preload("loaded_or_empty.gd")

## A KPI card: ONE figure a reader watches - what it is, the figure large in
## its unit (formats.gd), how it stands against the stretch before it, and a
## small trend of its days - and the whole card a press opening what stands
## behind the figure.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE FIGURE is a model's bound value, {now, before, days} (measures.gd):
## null until it has landed, when the card shows loading; a now of null -
## no mean of nothing - is empty, in the caller's words. Its unit is a
## function of the written number (Formats.quantity), so "2,340 customers"
## is the language's order of number and word.
##
## UP OR DOWN IS NEVER A HUE ALONE: the change is a mark - an arrow up or
## down, or level - AND the words "Up 12% on the 7 days before", said while
## the dashboard compares (a bound value); whether up is good is the
## reader's to judge from the words, never a colour's to decide. A stretch
## before of nothing has nothing to compare with, and says so. The stretch
## before is said inside those words, so its name is the one said within a
## sentence, which is the caller's to hand in: lowercase.
##
## THE TREND is the figure's days drawn as a trace (cell_readout.gd), a
## spread's day by its middle, a day with nothing dropped.
##
## ONE PRESS: the card is a pressable of the action given, carrying its
## payload and going where it says - a figure's drill-down, the rows behind it.

const CARD := &"KpiCard"
## What the figure is, the figure itself, and its change: kinds of words.
const SAYS := &"KpiSays"
const FIGURE := &"KpiFigure"
const CHANGE := &"KpiChange"
## The trend's drawing: a trace's, with the least height its look gives it.
const TREND := &"KpiTrend"
## The marks of a change, the same in every language.
const UP := "▲"
const DOWN := "▼"
const LEVEL := "="
## A change under half a percent reads as none.
const LEVEL_WITHIN := 0.5


## The card of a figure, and the press it is. Its options: says, what the
## card says the figure is; unit, the function writing the figure in its
## unit; comparing, a bound value while which the figure is set beside the
## stretch before, and before_words, what that stretch is called within a
## sentence; says_empty, the words for a figure of nothing; places, the
## decimal places the figure is written to; and payload, goes_to and style.
const OPTIONS: Array[String] = ["says", "unit", "comparing", "before_words", Options.SAYS_EMPTY, Options.PLACES, Options.PAYLOAD, Options.GOES_TO, Options.STYLE]

static func make(ui: Ui, action: StringName, figure: Bound, options: Dictionary = {}) -> Desc:
	Options.checked("a KPI card", options, OPTIONS)
	var comparing: Bound = options["comparing"]
	var now: Bound = figure.map(func(taken: Variant) -> Variant: return null if taken == null else taken["now"])
	var change: Bound = Bound.all([figure, options["before_words"]], change_of)
	var trend: Bound = figure.map(func(taken: Variant) -> Variant: return null if taken == null else trend_of(taken["days"]))
	var written: Bound = Formats.quantity(now, options["unit"], options.get(Options.PLACES, 0))
	var shown := ui.column([ui.text(written, FIGURE), ui.when(comparing, ui.text(change, CHANGE)), CellReadout.trace(ui, trend, TREND).grow()])
	var landed: Bound = figure.map(func(taken: Variant) -> bool: return taken != null)
	var empty: Bound = now.map(func(value: Variant) -> bool: return value == null)
	var body := LoadedOrEmpty.over(ui, landed, empty, shown, {says_empty = options[Options.SAYS_EMPTY]})
	var card := ui.pressable(action, options.get(Options.PAYLOAD, {}), [ui.column([ui.text(options["says"], SAYS), body.grow()])], options.get(Options.STYLE, CARD))
	return card.goes_to(options[Options.GOES_TO]) if options.has(Options.GOES_TO) else card


## How a figure stands against the stretch before, as a mark and words:
## up or down by how much of the figure before, level, or nothing to
## compare with; nothing before the figure has landed.
static func change_of(figure: Variant, before_words: Variant) -> Variant:
	if figure == null:
		return null
	if figure["now"] == null or figure["before"] == null or figure["before"] == 0.0:
		return Phrase.with("Nothing to compare with %s", [before_words])
	var percent: float = (figure["now"] - figure["before"]) / figure["before"] * 100.0
	var written := Phrase.written(func() -> String: return Formats.written_number(absf(percent)))
	if absf(percent) < LEVEL_WITHIN:
		return Phrase.joined([LEVEL, " ", Phrase.with("Level with %s", [before_words])])
	if percent > 0.0:
		return Phrase.joined([UP, " ", Phrase.with("Up %s%% on %s", [written, before_words])])
	return Phrase.joined([DOWN, " ", Phrase.with("Down %s%% on %s", [written, before_words])])


## A figure's days as a trend's numbers: a spread's day by its middle, a day with nothing dropped.
static func trend_of(days: Array) -> Array:
	return days.filter(func(day: Variant) -> bool: return day != null).map(func(day: Variant) -> float: return day[1] if day is Array else day)
