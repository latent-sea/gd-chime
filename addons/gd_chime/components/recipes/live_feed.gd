extends RefCounted

const Themes := preload("../../theme.gd")
const Tables := preload("../../theme_tables.gd")
const Ui := preload("../primitives/ui.gd")
const Options := preload("../primitives/options.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Feed := preload("../../feed.gd")
const Phrase := preload("../../phrase.gd")
const Pressables := preload("../../theme_pressables.gd")

## A live feed on the screen: the rows of a feed (feed.gd) as many as fit,
## the newest at the foot, and under them the one press that says where the
## reader stands - following the newest, or how many have arrived since
## they stepped away, pressed to follow again.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE LIST IS THE FLOOR'S VIRTUAL LIST WITH A CURSOR (virtual_list.gd): it
## takes the focus itself, so an entry arriving never takes it away, and a
## slot is told again only when the entry it shows is another - following,
## an arrival re-reads one row. Its keys are the cursor's: up and down move
## along the entries, a page by the rows shown, End follows the newest,
## Enter - and a second press - does what the application opens an entry
## with; Escape lets go of the entry. The wheel scrolls away from the
## newest, and back to them follows again.
##
## A ROW is a line of cells (cells.gd) at its columns' widths, so what an
## entry says never moves the line, on the ground of the row the cursor is
## on or of any other row - a shape, not a hue.
##
## THE PRESS UNDER THE ROWS NEVER MOVES: its words break at its width rather
## than widen it, and following it is refused rather than hidden, so the
## foot of the feed keeps its room and the focus on the press stays there.
##
## Its opening action must be one its place declares where it goes - a
## button of it beside the feed, say - since the keys press no button.

## The feed shown: rows of line(entry) over the press that follows the
## newest; opens is what Enter and a second press on an entry do.
static func make(ui: Ui, feed: Feed, line: Callable, opens: StringName) -> Desc:
	var rows := ui.virtual_list(feed, line, Tables.ROWS, _cursor(feed, opens)).fits()
	var said: Bound = Bound.both(ui.bound(feed.get_following), ui.bound(feed.get_unseen), func(following: bool, unseen: int) -> Phrase: return Phrase.of("Following the newest") if following else Phrase.counted("%d new - show the newest", "%d new - show the newest", unseen, "Show the newest"))
	var follows := ui.pressable(Feed.FOLLOWS, {}, [ui.text(said, Themes.FACE).wraps()], Pressables.BUTTON)
	return ui.column([rows.grow(), follows])


## One row: these cells, at the columns' widths from the samples, on the
## cursor's ground where the cursor is on this entry.
## Its options: names, one per part in order; columns, a bound value of
## the columns shown; and samples, the words each column may hold, one
## dictionary shared by every row.
const ROW_OPTIONS: Array[String] = ["names", "columns", "samples"]

static func row(ui: Ui, feed: Feed, entry: Bound, parts: Array, options: Dictionary = {}) -> Desc:
	Options.checked("a feed row", options, ROW_OPTIONS)
	var names: Array = options["names"]
	var columns: Bound = options["columns"]
	var samples: Dictionary = options["samples"]
	var ground: Bound = Bound.both(entry, ui.bound(feed.get_at), func(one: Variant, at: int) -> StringName: return Tables.CURSOR if one != null and one[Feed.SERIAL] == at else Tables.CELLS)
	return ui.cells(parts, names, columns, {samples = samples, words_kind = Tables.WORDS, ground = ground})


## The cursor: its row kept in view, its keys and presses the feed's commands.
static func _cursor(feed: Feed, opens: StringName) -> Dictionary:
	var page := feed.get_showing()
	var keys := [
		[&"ui_up", false, Feed.MOVES, {"by": -1}], [&"ui_down", false, Feed.MOVES, {"by": 1}],
		[&"ui_page_up", false, Feed.MOVES, {"by": -page}], [&"ui_page_down", false, Feed.MOVES, {"by": page}],
		[&"ui_end", false, Feed.FOLLOWS, {}], [&"ui_accept", false, opens, {}], [&"ui_text_submit", false, opens, {}],
	]
	return {"at": Bound.new(feed.get_in_view), "keys": keys, "anywhere": [[&"ui_cancel", Feed.LETS_GO]], "presses": Feed.PRESSES, "twice": opens}
