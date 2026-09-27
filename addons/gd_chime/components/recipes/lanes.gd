extends RefCounted

const Themes := preload("../../theme.gd")
const Ui := preload("../primitives/ui.gd")
const Options := preload("../primitives/options.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Lane := preload("../../lane.gd")
const Scroll := preload("../primitives/scroll.gd")
const Collections := preload("../../theme_collections.gd")

## Lanes: a board's lists side by side - each a list target (drop_target.gd)
## standing for its lane (lane.gd), its heading over the reason it would
## refuse what is carried and its pieces - the columns of a kanban board.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A PIECE IS CARRIED ALONG A LANE AND ACROSS TO ANOTHER by the pointer, the
## keys and the pad, and let go as ONE command, the move action, carrying
## the piece's payload and {into, at}: which lane, and the place among what
## that lane shows. The lanes show it where it would land as it goes, so the
## gap opens under the hand. Whether it may land there is the door's: a lane
## that would refuse it draws refusing and says why above its pieces.
##
## The template is the caller's - a card - and describes a draggable, whose
## payload is the item itself: a lane shows the item carried where it would
## land, so it must be the whole of it. The key is an item's identity. An
## item its lane turns away (lane.gd) keeps its piece, hidden, so a search
## narrowing a board builds nothing and reads no piece's words again. Each lane scrolls its own pieces down, and one that
## shows none says so. A lane is never narrower than its widest piece: where
## the lanes cannot all fit, the board is a strip across (strip.gd), resting
## on whole lanes, and no card is cut.
##
## Deliberately absent: lanes of their own width, and a lane folded away.


## The lanes, each with the heading given for it, the pieces from the
## template kept by key, a drop the move action, and words for an empty lane.
## Its options: template, which describes one piece; key, what a piece is
## kept by; moves, the action a drop dispatches; and empty, the words for
## a lane holding nothing.
const OPTIONS: Array[String] = ["template", "key", "moves", "empty"]

static func make(ui: Ui, lanes: Array, headings: Array, options: Dictionary = {}) -> Desc:
	Options.checked("lanes", options, OPTIONS)
	var template: Callable = options["template"]
	var key: Callable = options["key"]
	var moves: StringName = options["moves"]
	var empty: Variant = options["empty"]
	var columns: Array = []
	# every lane: its heading, why it would refuse what is carried, what it holds and whether it holds nothing
	for at: int in lanes.size():
		var lane: Lane = lanes[at]
		var shows: Bound = ui.bound(lane.get_shows)
		# a piece kept while the lane turns its item away, and only hidden: built once, however often a search narrows the lane
		var kept := func(item: Bound) -> Desc: return ui.when(Bound.both(item, shows, func(one: Variant, test: Callable) -> bool: return one == null or test.call(one)), template.call(item), null).keeps()
		var none := ui.when(ui.bound(lane.get_count).map(func(count: int) -> bool: return count == 0), ui.text(empty, Themes.REASON).wraps())
		var inside := ui.column([headings[at], ui.reason(Themes.REASON), none, ui.scroll(ui.each(ui.bound(lane.get_items), kept, key), null, Scroll.DOWN).grow()], Collections.LANE_COLUMN)
		columns.append(ui.drop_target(moves, [inside], Collections.LANE, lane.get_into()).basis(0.0).grow())
	return ui.scroll(ui.row(columns, Collections.LANES), null, Scroll.ACROSS)


## A lane's heading: its title, and how many it shows, as data.
static func heading(ui: Ui, title: Variant, lane: Lane) -> Desc:
	return ui.row([ui.text(title, Themes.FACE).grow(), ui.text(ui.bound(lane.get_count).map(func(count: int) -> String: return str(count)), Themes.REASON)], Collections.LANE_HEADING)
