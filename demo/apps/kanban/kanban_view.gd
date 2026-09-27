extends RefCounted

const GdChime := preload("res://addons/gd_chime/gd_chime.gd")
const KanbanBoard := preload("res://demo/apps/kanban/kanban_board.gd")
const KanbanCard := preload("res://demo/apps/kanban/kanban_card.gd")
const KanbanData := preload("res://demo/apps/kanban/kanban_data.gd")

## The board's panes, described: the lanes of cards, the card open, and
## what stands over them - the project's progress, the search, the person
## and label filters.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Description only: every piece is a recipe or a primitive over the
## board's models, and every press a declared action. The lanes are the
## floor's (lanes.gd), each over its lane (lane.gd); the card open is typed
## into and chosen for in place, each change one command; a pane that has
## nothing to show says what to do.

var _ui: GdChime.Ui
var _board: KanbanBoard
var _filters: GdChime.Filters
var _lanes: Array  # the Lane of each column, in the flow's order
var _cards: KanbanCard


func _init(ui: GdChime.Ui, board: KanbanBoard, filters: GdChime.Filters, lanes: Array) -> void:
	_ui = ui
	_board = board
	_filters = filters
	_lanes = lanes
	_cards = KanbanCard.new(ui, board)


## The lanes side by side, each under its name and count.
func lanes() -> GdChime.Desc:
	var ui: GdChime.Ui = _ui
	var headings: Array = _lanes.map(func(lane: GdChime.Lane) -> GdChime.Desc: return GdChime.Lanes.heading(ui, GdChime.Phrase.of(lane.get_into()), lane))
	return GdChime.Lanes.make(ui, _lanes, headings, {template = _cards.card, key = func(card: Dictionary) -> int: return card["id"], moves = KanbanBoard.MOVES, empty = GdChime.Phrase.of("No cards here")})


## The card open: where it stands, its badges and person, its title, its
## priority, estimate and person to choose, and the words about it - or,
## with none open, how to open one.
func detail(assigning: GdChime.Desc) -> GdChime.Desc:
	var ui: GdChime.Ui = _ui
	var open: GdChime.Bound = ui.bound(_board.get_open_card)
	var where: GdChime.Bound = open.map(func(card: Variant) -> Variant: return "" if card == null else GdChime.Phrase.with("#%d, %s", [card["id"], GdChime.Phrase.of(card["lane"])]))
	var priorities := GdChime.Bound.new(func() -> Array: return range(4).map(func(level: int) -> Dictionary: return {"value": level, "words": GdChime.Phrase.of(KanbanCard.PRIORITY_WORDS[level])}))
	var said: GdChime.Bound = open.map(func(card: Variant) -> Variant: return null if card == null else KanbanCard.said(card))
	var rows: Array = [
		ui.row([ui.text(where, GdChime.Themes.FACE).grow(), GdChime.Avatar.make(ui, open.field("person"))], GdChime.Collections.BOARD_CARD_LINE),
		ui.row([KanbanCard.priority(ui, open), KanbanCard.deadline(ui, open)], GdChime.Collections.BOARD_CARD_LINE),
		ui.text(said, GdChime.Themes.REASON).hides_empty().wraps(),
		GdChime.TextField.make(ui, KanbanBoard.RETITLES, GdChime.Phrase.of("Title"), {holds = open.field("title")}),
		_labelled(GdChime.Phrase.of("Priority"), GdChime.InlineChoice.radios(ui, KanbanBoard.SETS_PRIORITY, priorities, open.field("priority"))),
		_labelled(GdChime.Phrase.of("Estimate, in points"), GdChime.Stepper.make(ui, KanbanBoard.SETS_ESTIMATE, open.field("estimate"), {minimum = 0.0, maximum = 40.0, step = 1.0})),
		_labelled(GdChime.Phrase.of("Assigned to"), assigning),
		_labelled(GdChime.Phrase.of("About it"), ui.area(KanbanBoard.WRITES_ABOUT, open.field("about"))),
	]
	var none := ui.text(GdChime.Phrase.of("Click a card, or pick open from its menu, to see it here and change it."), GdChime.Themes.REASON).wraps()
	return GdChime.Panes.titled(ui, GdChime.Phrase.of("Card"), ui.when(open.map(func(card: Variant) -> bool: return card != null), ui.scroll(ui.column(rows, &"PaneColumn")), none))


## A control under its name.
func _labelled(name: GdChime.Phrase, control: GdChime.Desc) -> GdChime.Desc:
	return _ui.column([_ui.text(name, GdChime.Themes.REASON), control], GdChime.Collections.BOARD_CARD_COLUMN)


## What stands over the board: the project's progress, the search, the
## person picked out, clearing the filters, and folding the card pane.
func bar(picking: GdChime.Desc, folds: StringName, shown: GdChime.Bound) -> Array:
	var ui: GdChime.Ui = _ui
	var progress: GdChime.Desc = GdChime.Progress.make(ui, GdChime.Phrase.of("Done"), ui.bound(_board.get_done), ui.bound(_board.get_whole)).grow(2.0)
	var search := ui.row([ui.text(GdChime.Phrase.of("Search"), GdChime.Themes.FACE), ui.field(GdChime.Filters.SEARCHES, GdChime.Fields.FIELD, {"changes": GdChime.Filters.SEARCHES}).grow()]).grow()
	return [progress, search, ui.row([ui.text(GdChime.Phrase.of("Person"), GdChime.Themes.FACE), picking]), ui.button(GdChime.Filters.CLEARS), GdChime.Panes.toggle(ui, folds, shown)]


## The labels, each a chip picking out the cards carrying it, and how many cards are shown.
func labels() -> GdChime.Desc:
	var ui: GdChime.Ui = _ui
	var chip := func(one: GdChime.Bound) -> GdChime.Desc: return GdChime.Chip.make(ui, one.field("words"), one.field("on"), one.map(func(item: Variant) -> Dictionary: return {} if item == null else {"column": &"labels", "value": item["words"]}), {toggles = GdChime.Filters.TOGGLES})
	var labels: GdChime.Bound = ui.bound(func() -> Array: return Array(KanbanData.LABELS).map(func(label: String) -> Dictionary: return {"words": label, "on": _filters.get_picked(&"labels").has(label)}))
	var chips := ui.each_across(labels, chip, func(one: Dictionary) -> String: return one["words"], GdChime.Collections.BOARD_CARD_LINE)
	var counted: GdChime.Bound = GdChime.Bound.both(ui.bound(_board.get_shown_count), ui.bound(_board.get_whole), func(shown: int, whole: int) -> GdChime.Phrase: return GdChime.Phrase.with("Showing %d of %d cards", [shown, whole]))
	return ui.row([ui.text(GdChime.Phrase.of("Labels"), GdChime.Themes.REASON), chips.grow(), ui.text(counted, GdChime.Themes.REASON)], GdChime.Collections.LANE_HEADING)
