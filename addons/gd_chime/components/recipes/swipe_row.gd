extends RefCounted

const Themes := preload("../../theme.gd")
const Ui := preload("../primitives/ui.gd")
const Options := preload("../primitives/options.gd")
const Desc := preload("../primitives/desc.gd")
const Swipe := preload("../primitives/swipe.gd")
const Status := preload("status.gd")
const Collections := preload("../../theme_collections.gd")

## A row of a list with actions a finger swipes to, and the same actions in
## its menu: drawn right it does one, drawn left another, tapped it does its
## own - and the keys, the pad and the pointer reach every one of them from
## its menu, so a swipe is never the only way.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A SIDE IS {action, words, state}: what letting go on that side does, the
## words that say so and the status mark beside them (status.gd) - a state's
## shape, never a hue alone - uncovered as the row slides (swipe.gd). The
## row is a menu's target (menu_target.gd) offering its own action and
## every side's, each carrying the row's payload, opened by a right press,
## the menu key or the pad's button as any target's is: an application
## showing these rows composes the menu (context_menu.gd).
##
## Its look is SwipeRow, the ground uncovered its reveal and armed boxes by
## side, and the reveal's line SwipeReveal (theme_feedback.gd), unless another
## style is named.

const RIGHT := Swipe.RIGHT
const LEFT := Swipe.LEFT


## The row: tapped, the action - going where its place says, if anywhere -
## and swiped to a side, that side's; each with the payload, a dictionary or
## a bound value read as it lands.
## Its options: sides, {Swipe.RIGHT: action, Swipe.LEFT: action}; goes_to,
## where a tap goes; and style.
const OPTIONS: Array[String] = ["sides", Options.GOES_TO, Options.STYLE]

static func make(ui: Ui, action: StringName, payload: Variant, content: Desc, options: Dictionary = {}) -> Desc:
	Options.checked("a swiped row", options, OPTIONS)
	var sides: Dictionary = options["sides"]
	var goes_to: StringName = options.get(Options.GOES_TO, &"")
	var style: StringName = options.get(Options.STYLE, Collections.SWIPE_ROW)
	var actions: Dictionary = {}
	var reveals: Dictionary = {}
	# every side, its action and what its reveal says
	for side: StringName in sides:
		actions[side] = sides[side]["action"]
		reveals[side] = ui.row([Status.mark(ui, sides[side]["state"]), ui.text(sides[side]["words"], Themes.FACE)], Collections.SWIPE_REVEAL)
	var row := ui.swipe(action, payload, content, {sides = actions, reveals = reveals, style = style, goes_to = goes_to})
	return ui.menu_target([action] + actions.values(), payload, [row])
