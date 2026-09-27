extends RefCounted

const Ui := preload("../primitives/ui.gd")
const Options := preload("../primitives/options.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Loading := preload("loading.gd")

## What a chart or a figure shows in each of its three states: LOADING
## while its data is on its way, EMPTY once it has landed with nothing in
## it, and the content once there is something to show.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Every chart of a dashboard has all three, and each would otherwise write
## the same two whens around itself. Loading is loading.gd's mark over the
## shapes standing in for the content; empty is words of the caller's -
## "No incidents in this stretch" - never a blank plot, which reads as a
## broken one; both are read from bound values of the model's, so the
## state is its fact and never guessed from the drawing.
##
## The content is KEPT while the state is empty, only hidden, so a chart
## that empties and fills again as the reader filters is the same chart,
## never built again, and the empty words take its room.

## The empty state's words.
const EMPTY := &"Empty"


## The content once landed and not empty; the empty words once landed and
## empty; the mark over the shapes given - one line's, given none - until then.
## Its options: says_empty, the words shown once landed and empty, and
## standing_in, the shapes the loading mark stands over until it lands -
## one line's, given none.
const OPTIONS: Array[String] = [Options.SAYS_EMPTY, "standing_in"]

static func over(ui: Ui, landed: Bound, empty: Bound, content: Desc, options: Dictionary = {}) -> Desc:
	Options.checked("a loaded or empty piece", options, OPTIONS)
	var says_empty: Variant = options[Options.SAYS_EMPTY]
	var standing_in: Variant = options.get("standing_in")
	var shown := ui.when(empty.map(func(is_empty: Variant) -> bool: return is_empty != true), content, ui.text(says_empty, EMPTY).wraps()).keeps()
	return Loading.until(ui, landed, shown, standing_in)
