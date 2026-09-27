extends RefCounted

const Themes := preload("../../theme.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Motion := preload("../../motion.gd")
const Fetched := preload("../../fetched.gd")
const Keyframes := preload("../primitives/keyframes.gd")
const Flex := preload("../primitives/flex.gd")
const Status := preload("status.gd")
const Phrase := preload("../../phrase.gd")
const Feedback := preload("../../theme_feedback.gd")

## Loading: the ONE look of anything on its way from a far side - the MARK,
## turning, with the words that say so, the SHAPES standing in where the
## content will land, the FAILURE said on the thing itself with a way to ask
## again, and, once it has landed, the content.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE MARK TURNS a quarter at a time and fades a little on the way - a
## keyframe track that loops (keyframes.gd), a square in the look's LOADING
## style, turning on the look's own period. A loop is motion nobody asked
## for, so while motion is reduced it rests where it stands, and what it
## says is said beside it in words, "Loading": never by the motion alone.
## A SHAPE is a ground in the look's PLACEHOLDER style, the room a line of
## the content will take, so the screen does not jump when the content
## lands in its place. Both are grounds and words, never pressed.
##
## A FAILURE IS SAID ONE WAY, HERE AND NOWHERE ELSE: the fault's mark
## (status.gd) - never a hue alone - the reason in words, and a press that
## asks again, in a line over whatever was shown, there only while the
## fetch holds a failure and gone as the next asking begins. The other half
## of that one way is the notification the fetch itself sends (fetched.gd).
## No screen may write its own line for a failed fetch.
##
## The builder is taken untyped here because the builder's own vocabulary
## names this (ui.loading, describe_loads.gd), and a preload each way would
## be a cycle.
##
## until() is what anything filling in its own time composes: the content
## while a bound value holds - a list's count, a picture painted - and the
## mark over the shapes until it does. of() is the whole of it over a fetch.
## The actions the screen offers meanwhile are refused by its handler,
## "Still loading", and a button says so on its face as it says any refusal.

## A quarter turn, fading a little half way and whole again where it rests:
## a square a quarter turned is the square it was, so the loop has no seam.
const TURNS := [
	{&"at": 0.0, Keyframes.OPACITY: 1.0, Keyframes.TURN: 0.0},
	{&"at": 0.5, Keyframes.OPACITY: &"loading_opacity", Keyframes.TURN: 45.0},
	{&"at": 1.0, Keyframes.OPACITY: 1.0, Keyframes.TURN: 90.0},
]


## The mark turning beside the words "Loading", while a bound value holds -
## always, given none.
static func mark(ui: RefCounted, held: Bound = null) -> Desc:
	var turning: Desc = ui.keyframes([ui.surface(Themes.LOADING)], TURNS, &"period", {easing = Motion.MOVE, timed_by = Themes.LOADING, loops = Keyframes.FOREVER, held = held})
	# the square kept square: centred across the row, never stretched to the words' height
	turning.facts["align"] = Flex.CENTER
	return ui.row([turning, ui.text(Phrase.of("Loading"), Themes.REASON)])


## So many shapes, one under another, standing in for lines not landed.
static func shapes(ui: RefCounted, lines: int = 1) -> Desc:
	var standing: Array = []
	# one ground per line the content will take
	for line: int in lines:
		standing.append(ui.surface(Themes.PLACEHOLDER))
	return ui.column(standing)


## The content once the bound value holds; until then the mark over the
## shapes given - one line's, given none.
static func until(ui: RefCounted, landed: Bound, content: Desc, standing_in: Desc = null) -> Desc:
	return ui.when(landed, content, ui.column([mark(ui), shapes(ui) if standing_in == null else standing_in]))


## Why the last asking failed, with the fault's mark and a press that asks
## again - nothing at all while nothing has failed.
static func failure(ui: RefCounted, why: Bound) -> Desc:
	var said: Bound = why.map(func(reason: Variant) -> Variant: return "" if reason == null else Phrase.with("Could not be loaded: %s", [reason]))
	var again: Desc = ui.button(Fetched.ASKS_AGAIN)
	var line: Desc = ui.row([Status.mark(ui, Status.FAULT), ui.text(said, Themes.REASON).wraps().grow(), again], Feedback.STATUS_LINE)
	return ui.when(why.map(func(reason: Variant) -> bool: return reason != null), line)


## The whole of it over a fetch: the failure over the content, the content
## once it has landed, and the mark over the shapes until either happens.
static func of(ui: RefCounted, fetched: Fetched, content: Desc, standing_in: Desc) -> Desc:
	var landed: Bound = fetched.data.map(func(what: Variant) -> bool: return what != null)
	var failed: Bound = fetched.failure.map(func(why: Variant) -> bool: return why != null)
	# failed with nothing yet landed, the shapes stand alone: a mark that turns would say it is still coming
	var waiting: Desc = ui.when(failed, standing_in, ui.column([mark(ui), standing_in]))
	return ui.column([failure(ui, fetched.failure), ui.when(landed, content, waiting)])
