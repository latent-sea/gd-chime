extends "res://addons/gd_chime/application.gd"

const GdChime := preload("res://addons/gd_chime/gd_chime.gd")
const Looks := preload("res://demo/gallery/looks/looks.gd")
const KanbanData := preload("res://demo/apps/kanban/kanban_data.gd")
const KanbanBoard := preload("res://demo/apps/kanban/kanban_board.gd")
const KanbanServer := preload("res://demo/apps/kanban/kanban_server.gd")
const KanbanView := preload("res://demo/apps/kanban/kanban_view.gd")
const KanbanProbe := preload("res://demo/apps/kanban/kanban_probe.gd")

## Application 4, the kanban project workspace: a software team's board of
## three hundred issues in six lanes - Backlog, Ready, In progress, Review,
## Testing, Done - with the project's progress over it, built on the floor's
## application shell, lanes and provisional changes.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --path <this folder> --script res://demo/apps/kanban/kanban.gd
##       [-- --look=<a gallery look>] [-- --probe]
## It opens in the neo-brutalist look, the board's own; --look=placeholder
## wears the floor's neutral one.
##
## Drag a card along its lane or across to another and the gap opens where
## it would land; let go, and it is there - the progress counting a card
## let go in Done at once - while the server is asked; a card it refuses (one
## labelled blocked, past In progress) goes back, saying why on itself and in
## a notification. By the keys or the pad: accept lifts the card, the arrows
## carry it, accept sets it down, cancel puts it back. A click opens a card
## in the pane beside the lanes, where its title, priority, estimate, person
## and words are changed; the menu key or the pad's view button offers what
## can be done to it. Type to search; pick a person, or turn labels on, to
## see only their cards - all of it the floor's one filter model (filters.gd). This file declares the actions and their keys,
## makes the models, and arranges the shell.

## The typing into the person picker, which its own narrowing answers.
const NARROWS_PEOPLE := &"narrows_the_people"
const OPENS_PEOPLE := &"opens_the_people"
const OPENS_ASSIGNING := &"opens_the_assigning"
const FOLDS_CARD := &"folds_the_card"
## The words standing for no person picked, which pick nobody out.
const ANYONE := "Anyone"
## The look the board opens in unless another is asked for.
const LOOK := &"neo_brutalist"

var board: KanbanBoard
var filters: GdChime.Filters
var people: GdChime.Narrowing
var server: KanbanServer
var provisional: GdChime.Provisional
var panels: GdChime.Panels
var menu: GdChime.OpenMenu
var lanes: Array = []
var _people: Desc  # the person filter's combo
var _assigning: Desc  # the card open's person's combo
var _view: KanbanView  # held while the app stands: the cards are built from its template


## The look asked for at launch - placeholder for the floor's neutral one -
## or the board's own, neo-brutalist.
func look() -> Theme:
	return Looks.make(Looks.asked(LOOK))


func probe() -> RefCounted:
	return KanbanProbe.new(self)


## Every action with its words, and the key and pad button it is on to begin with.
func declare(register: Actions) -> void:
	register.declare_all({
		KanbanBoard.MOVES: ["Move"],
		KanbanBoard.MOVES_ON: ["Move to the next lane"],
		KanbanBoard.MOVES_BACK: ["Move to the lane before"],
		KanbanBoard.OPENS: ["Open"],
		KanbanBoard.RENAMES: ["Rename"],
		KanbanBoard.RETITLES: ["Rename"],
		KanbanBoard.STOPS_RENAMING: ["Stop renaming", Actions.keys(KEY_ESCAPE)],
		KanbanBoard.WRITES_ABOUT: ["Write about it"],
		KanbanBoard.SETS_PRIORITY: ["Set the priority"],
		KanbanBoard.RAISES: ["Raise the priority"],
		KanbanBoard.LOWERS: ["Lower the priority"],
		KanbanBoard.SETS_ESTIMATE: ["Set the estimate"],
		KanbanBoard.ASSIGNS: ["Assign"],
		GdChime.Filters.SEARCHES: ["Search"],
		GdChime.Filters.PICKS: ["Pick"],
		NARROWS_PEOPLE: ["Find a person"],
		GdChime.Filters.TOGGLES: ["Pick out a label"],
		GdChime.Filters.CLEARS: ["Clear the filters"],
		OPENS_PEOPLE: ["Pick a person"],
		OPENS_ASSIGNING: ["Choose who"],
		FOLDS_CARD: ["Card pane", Actions.keys(KEY_D, KEY_MASK_CTRL)],
		GdChime.Panels.RESIZES: ["Resize"],
		Notifications.DISMISSES: ["Dismiss"],
		GdChime.OpenMenu.OPENS: ["More", Actions.keys(KEY_MENU), Actions.pad(JOY_BUTTON_BACK)],
		GdChime.OpenMenu.PICKS: ["Pick"],
	})


## The models made - each standing itself up, answering what it answers from
## anywhere - then the shell described.
func describe() -> Desc:
	filters = model(GdChime.Filters.new(chimes, {search = [&"id", &"title", &"person", &"labels"], one_of = &"person", any_of = &"labels"}))
	people = model(GdChime.Narrowing.new(chimes, GdChime.Bound.constant([{"value": "", "words": ANYONE}] + Array(KanbanData.PEOPLE).map(func(named: String) -> Dictionary: return {"value": named, "words": named})), 8, NARROWS_PEOPLE))
	server = KanbanServer.new()
	ui.also(server)
	panels = model(GdChime.Panels.new(chimes, {&"board": 0.72}, {&"lanes": [&"board", GdChime.Panels.FIRST], &"detail": [&"board", GdChime.Panels.SECOND]}, {FOLDS_CARD: &"detail"}, {}, {KanbanBoard.SHOWS_DETAIL: &"detail"}))
	# the card pane folded away until a card is opened
	panels.fold(&"detail")
	# a card in doubt after a refusal is read back from the server, and the board put where it says
	provisional = model(GdChime.Provisional.new(chimes, server.send, notifications, server.reads, func(id: Variant, card: Variant) -> void: board.settle(id, card)))
	board = model(KanbanBoard.new(chimes, filters, provisional, panels))
	menu = model(GdChime.OpenMenu.new(chimes, commands, actions))
	lanes = Array(KanbanData.LANE_WORDS).map(func(named: String) -> GdChime.Lane: return model(GdChime.Lane.new(chimes, ui.carried, board.lane(named), ui.bound(filters.get_keeps), named, func(card: Dictionary) -> int: return card["id"])))
	var whom: GdChime.Bound = ui.bound(func() -> String: return filters.get_chosen(&"person")).map(func(one: String) -> String: return ANYONE if one == "" else one)
	_people = GdChime.Combo.long(ui, GdChime.Filters.PICKS, OPENS_PEOPLE, whom, {narrowing = people, types = NARROWS_PEOPLE, title = GdChime.Phrase.of("Show the cards of"), payload = {"column": &"person"}})
	var everyone := GdChime.Bound.constant([{"value": "", "words": GdChime.Phrase.of("Nobody")}] + Array(KanbanData.PEOPLE).map(func(named: String) -> Dictionary: return {"value": named, "words": named}))
	var whose: GdChime.Bound = ui.bound(board.get_open_card).map(func(card: Variant) -> String: return "" if card == null or card["person"] == null else card["person"])
	_assigning = GdChime.Combo.short(ui, KanbanBoard.ASSIGNS, OPENS_ASSIGNING, {offers = everyone, chosen = whose, title = GdChime.Phrase.of("Assign the card to")})
	# the cards' menu, which every card opens
	GdChime.ContextMenu.make(ui, menu)
	return _shell()


## The shell: the bar over the labels and the lanes, the card pane beside
## them - under them on a window on its end - and the status in the foot.
func _shell() -> Desc:
	_view = KanbanView.new(ui, board, filters, lanes)
	var view := _view
	var standing: GdChime.Bound = ui.shape.portrait.map(func(down: Variant) -> int: return GdChime.Layout.COLUMN if down else GdChime.Layout.ROW)
	var side := ui.column([view.labels(), view.lanes().grow()], &"PaneColumn")
	var work: GdChime.Desc = GdChime.Panes.split(ui, side, view.detail(_assigning), {panels = panels, named = &"board", runs = standing, folds = FOLDS_CARD})
	var status: GdChime.Bound = ui.bound(provisional.get_pending).map(func(pending: Dictionary) -> GdChime.Phrase: return GdChime.Phrase.counted("%d card has a change on its way to the server", "%d cards have changes on their way to the server", pending.size(), "Every change is kept"))
	return ui.app(&"kanban", [GdChime.Shell.make(ui, view.bar(_people, FOLDS_CARD, panels.shown(&"detail")), work, {status = status, notifications = notifications})])
