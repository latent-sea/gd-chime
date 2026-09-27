extends RefCounted

const GdChime := preload("res://addons/gd_chime/gd_chime.gd")
const KanbanBoard := preload("res://demo/apps/kanban/kanban_board.gd")

## A card of the board, described: its issue number and the person it is
## assigned to, its title - typed in place while it is being renamed - its
## labels, its priority, estimate and deadline, and what the server said.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Description only. The card is a draggable (draggable.gd) whose payload is
## the card as shown, clicked to open it in the detail pane, inside a menu's
## target offering what can be done to it, each refused as its own press
## would be. A label is a chip that turns that label's filter on. The
## priority and the deadline are badges, a mark beside their words; the
## person is an avatar. While a change of the card is on its way it says
## saving, and a change the server refused is said on the card.

## A priority's words, from 0 to 3.
const PRIORITY_WORDS: Array[String] = ["Low", "Medium", "High", "Urgent"]

var _ui: GdChime.Ui
var _board: KanbanBoard
var _always: GdChime.Bound = GdChime.Bound.new(func() -> bool: return true)


func _init(ui: GdChime.Ui, board: KanbanBoard) -> void:
	_ui = ui
	_board = board


## One card, from the handle of the card as shown.
func card(item: GdChime.Bound) -> GdChime.Desc:
	var ui: GdChime.Ui = _ui
	var number: GdChime.Bound = item.map(func(one: Variant) -> String: return "" if one == null else "#%d" % one["id"])
	var renaming: GdChime.Bound = GdChime.Bound.both(item, ui.bound(_board.get_editing), func(one: Variant, editing: Variant) -> bool: return one != null and one["id"] == editing)
	var typed: GdChime.Desc = ui.field(KanbanBoard.RETITLES, GdChime.Fields.FIELD, {"shows": item.field("title"), "carries": func(line: String) -> Dictionary: return {"id": item.read()["id"], "title": line}}).takes_focus()
	var title := ui.when(renaming, ui.row([typed.grow(), ui.button(KanbanBoard.STOPS_RENAMING)], GdChime.Collections.BOARD_CARD_LINE), ui.text(item.field("title"), GdChime.Collections.BOARD_CARD_TITLE).wraps())
	var top := ui.row([ui.text(number, GdChime.Collections.BOARD_CARD_META).grow(), GdChime.Avatar.make(ui, item.field("person"))], GdChime.Collections.BOARD_CARD_LINE)
	var marks := ui.row([priority(ui, item), ui.text(item.map(_points), GdChime.Collections.BOARD_CARD_META), deadline(ui, item)], GdChime.Collections.BOARD_CARD_LINE)
	var body := ui.column([top, title, _labels(item), marks, ui.text(item.map(said), GdChime.Themes.REASON).hides_empty().wraps()], GdChime.Collections.BOARD_CARD_COLUMN)
	var about: GdChime.Bound = item.map(func(one: Variant) -> Dictionary: return {} if one == null else {"id": one["id"]})
	var offers: Array = [KanbanBoard.OPENS, KanbanBoard.RENAMES, KanbanBoard.MOVES_ON, KanbanBoard.MOVES_BACK, KanbanBoard.RAISES, KanbanBoard.LOWERS]
	return ui.menu_target(offers, about, [ui.draggable(item, [body], GdChime.Collections.BOARD_CARD, KanbanBoard.OPENS)])


## A card's labels, each a chip turning that label's filter on.
func _labels(item: GdChime.Bound) -> GdChime.Desc:
	var ui: GdChime.Ui = _ui
	var labels: GdChime.Bound = item.map(func(one: Variant) -> Array: return [] if one == null else (one["labels"] as Array).map(func(label: String) -> Dictionary: return {"id": label}))
	var chip := func(label: GdChime.Bound) -> GdChime.Desc: return GdChime.Chip.make(ui, label.field("id"), _always, label.map(func(one: Variant) -> Dictionary: return {} if one == null else {"column": &"labels", "value": one["id"]}), {toggles = GdChime.Filters.TOGGLES})
	return ui.each_across(labels, chip, func(label: Dictionary) -> String: return label["id"], GdChime.Collections.BOARD_CARD_LINE)


## A card's priority as a badge: its words, at its level - a step above
## nothing, so even a low one has a mark.
static func priority(ui: GdChime.Ui, item: GdChime.Bound) -> GdChime.Desc:
	var words: GdChime.Bound = item.map(func(one: Variant) -> Variant: return "" if one == null else GdChime.Phrase.of(PRIORITY_WORDS[one["priority"]]))
	return GdChime.Badge.make(ui, words, item.map(func(one: Variant) -> int: return 0 if one == null else one["priority"] + 1))


## A card's deadline as a badge, while it has one: overdue at the most
## pressing level, today at the next, within three days the next, and
## later the least - nothing pressing once the card is done.
static func deadline(ui: GdChime.Ui, item: GdChime.Bound) -> GdChime.Desc:
	var due: GdChime.Bound = item.map(func(one: Variant) -> Variant: return null if one == null else one["due"])
	var words: GdChime.Bound = due.map(func(day: Variant) -> Variant: return "" if day == null else GdChime.Phrase.counted("Overdue %d day", "Overdue %d days", -day) if day < 0 else GdChime.Phrase.of("Due today") if day == 0 else GdChime.Phrase.counted("Due in %d day", "Due in %d days", day))
	var level: GdChime.Bound = item.map(func(one: Variant) -> int: return 0 if one == null or one["due"] == null or one["lane"] == KanbanBoard.DONE else 4 if one["due"] < 0 else 3 if one["due"] == 0 else 2 if one["due"] <= 3 else 1)
	return ui.when(due.map(func(day: Variant) -> bool: return day != null), GdChime.Badge.make(ui, words, level))


## A card's estimate, in points.
static func _points(one: Variant) -> Variant:
	return "" if one == null else GdChime.Phrase.counted("%d point", "%d points", one["estimate"])


## What the server said of a card's last change: saving while one is on its way, why one was not kept, or nothing.
static func said(one: Variant) -> Variant:
	if one == null or not (one["pending"] or one["refused"] != null):
		return null
	return GdChime.Phrase.of("Saving") if one["pending"] else GdChime.Phrase.with("Not kept: %s", [one["refused"]])
