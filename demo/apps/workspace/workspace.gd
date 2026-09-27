extends "res://addons/gd_chime/application.gd"

const GdChime := preload("res://addons/gd_chime/gd_chime.gd")
const Looks := preload("res://demo/gallery/looks/looks.gd")
const Workbench := preload("res://demo/apps/workspace/workbench.gd")
const PanesView := preload("res://demo/apps/workspace/panes_view.gd")
const Probe := preload("res://demo/apps/workspace/probe.gd")

## Application 7, the desktop-style command centre: a data-engineering
## workspace - the project explorer on the left, the SQL editor in the
## centre under the tabs of the queries open, the rows a run answered below
## it, the schema of a dataset on the right - built on the floor's
## application shell and nothing of its own.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --path <this folder> --script res://demo/apps/workspace/workspace.gd
## It wears its own look, the HUD, unless another is asked for with
## -- --look=<name> (one of the gallery's; placeholder is the floor's
## neutral one); a settings file of
## its own: -- --settings=user://<file>.json; walked and judged: -- --probe.
##
## THE SHELL IS THE FLOOR'S: the panes are splits over the panels model
## (panels.gd, panes.gd) - dragged by their grips, stepped by the keys and
## the pad, folded and expanded by toggles on keys of their own; the tabs are
## the documents open (documents.gd, tab_bar.gd); Ctrl+K raises the command
## palette over every command on the screen, the warehouse's 2,400 datasets
## and the project's queries (command_search.gd, command_palette.gd); a
## right press, the menu key or the pad's view button opens a context menu
## of a row's or the editor's actions (open_menu.gd, context_menu.gd); and
## the panels, the queries open, their words and the keys bound are kept in
## one settings file between runs (settings_file.gd). This file declares the
## actions and their keys, makes the models, and arranges the panes.

## The app, and the region the results' table answers in.
const APP := &"workspace"
## How many result rows show at once, before the pane's height says otherwise.
const RESULT_ROWS := 12
const OPENS_PALETTE := &"opens_the_palette"
const FOLDS_EXPLORER := &"folds_the_explorer"
const FOLDS_RESULTS := &"folds_the_results"
const FOLDS_SCHEMA := &"folds_the_schema"
const EXPANDS_EDITOR := &"expands_the_editor"
const EXPANDS_RESULTS := &"expands_the_results"
## Where the layout is kept: the workspace's own file, and the probe's, which is begun empty.
const KEPT := "user://workspace_settings.json"
const PROBED := "user://workspace_probe.json"

var bench: Workbench
var documents: GdChime.Documents
var panels: GdChime.Panels
var search: GdChime.CommandSearch
## The command palette, opened from the bar.
var palette: Desc
var menu: GdChime.OpenMenu
var settings: GdChime.SettingsFile


func look() -> Theme:
	return Looks.make(Looks.asked(&"hud"))


func probe() -> RefCounted:
	return Probe.new(self)


## Every action with its words, and the key and pad button it is on to begin with.
func declare(register: Actions) -> void:
	register.declare_all({
		OPENS_PALETTE: ["Search or run a command", Actions.keys(KEY_K, KEY_MASK_CTRL), Actions.pad(JOY_BUTTON_Y)],
		Workbench.MAKES: ["New query", Actions.keys(KEY_N, KEY_MASK_CTRL)],
		Workbench.RUNS: ["Run", Actions.keys(KEY_F5), Actions.pad(JOY_BUTTON_X)],
		Workbench.WRITES: ["Write the query"],
		Workbench.COPIES: ["Make a copy"],
		Workbench.SHOWS: ["Show its columns"],
		Workbench.PREVIEWS: ["Preview its rows"],
		Workbench.PUTS_IN: ["Put its name in the query"],
		Workbench.SHOWS_RESULTS: ["Show the results"],
		Notifications.DISMISSES: ["Dismiss"],
		GdChime.Documents.OPENS: ["Open"],
		GdChime.Documents.CLOSES: ["Close"],
		GdChime.Documents.CLOSES_FRONT: ["Close the query", Actions.keys(KEY_W, KEY_MASK_CTRL)],
		GdChime.Documents.SHOWS_NEXT: ["Next", Actions.keys(KEY_TAB, KEY_MASK_CTRL), Actions.pad(JOY_BUTTON_RIGHT_SHOULDER)],
		GdChime.Documents.SHOWS_PREVIOUS: ["Previous", Actions.keys(KEY_TAB, KEY_MASK_CTRL | KEY_MASK_SHIFT), Actions.pad(JOY_BUTTON_LEFT_SHOULDER)],
		FOLDS_EXPLORER: ["Explorer", Actions.keys(KEY_B, KEY_MASK_CTRL)],
		FOLDS_RESULTS: ["Results", Actions.keys(KEY_J, KEY_MASK_CTRL)],
		FOLDS_SCHEMA: ["Schema", Actions.keys(KEY_B, KEY_MASK_CTRL | KEY_MASK_ALT)],
		EXPANDS_EDITOR: ["Query alone", Actions.keys(KEY_F11)],
		EXPANDS_RESULTS: ["Results alone", Actions.keys(KEY_F11, KEY_MASK_SHIFT)],
		GdChime.Panels.RESIZES: ["Resize"],
		GdChime.CommandSearch.TYPES: ["Search"],
		GdChime.CommandSearch.PICKS: ["Pick"],
		GdChime.CommandSearch.RUNS_FIRST: ["Run the first found"],
		GdChime.OpenMenu.OPENS: ["More", Actions.keys(KEY_MENU), Actions.pad(JOY_BUTTON_BACK)],
		GdChime.OpenMenu.PICKS: ["Pick"],
	})
	# the results' table: the floor's long table, in the grid's words
	GdChime.DataGrid.declare_table(register)


## The models made - each standing itself up - kept in the settings file;
## then the shell described.
func describe() -> Desc:
	bench = model(Workbench.new(chimes, notifications, _results_table()))
	documents = model(bench.documents)
	var panes := {&"explorer": [&"outer", GdChime.Panels.FIRST], &"rest": [&"outer", GdChime.Panels.SECOND], &"centre": [&"rest", GdChime.Panels.FIRST], &"schema": [&"rest", GdChime.Panels.SECOND], &"editor": [&"centre", GdChime.Panels.FIRST], &"results": [&"centre", GdChime.Panels.SECOND]}
	panels = model(GdChime.Panels.new(chimes, {&"outer": 0.2, &"rest": 0.76, &"centre": 0.58}, panes, {FOLDS_EXPLORER: &"explorer", FOLDS_RESULTS: &"results", FOLDS_SCHEMA: &"schema"}, {EXPANDS_EDITOR: &"editor", EXPANDS_RESULTS: &"results"}, {Workbench.SHOWS_RESULTS: &"results"}))
	search = model(GdChime.CommandSearch.new(chimes, commands, driver, actions, [{"kind": GdChime.Phrase.of("Dataset"), "entries": ui.bound(bench.get_datasets), "picks": Workbench.SHOWS}, {"kind": GdChime.Phrase.of("Query"), "entries": ui.bound(bench.get_queries), "picks": GdChime.Documents.OPENS}]))
	menu = model(GdChime.OpenMenu.new(chimes, commands, actions))
	settings = model(GdChime.SettingsFile.new(chimes, settings_path(KEPT, PROBED)))
	# every model that keeps something, in the order each reads the one before: the queries, then which are open
	for kept: Array in [["queries", bench], ["documents", documents], ["panels", panels], ["keys", inputs]]:
		settings.keep(kept[0], kept[1])
	return _shell()


## The results' table, empty until a run, its rows looked at from the start -
## the app fills once. Its models answer in the app's region, where the
## table is described.
func _results_table() -> GdChime.TableModels:
	var table := GdChime.TableModels.new(ui, GdChime.PackedRows.new({}), [], {}, jobs, RESULT_ROWS)
	table.long.look(null)
	return table


## The shell: the bar of commands and toggles over the panes, the status
## under them. On a window on its end every split stands one pane over the
## other; the query and its results always do.
func _shell() -> Desc:
	var view := PanesView.new(ui, bench, documents)
	var standing: GdChime.Bound = ui.shape.portrait.map(func(down: Variant) -> int: return GdChime.Layout.COLUMN if down else GdChime.Layout.ROW)
	var centre: GdChime.Desc = GdChime.Panes.split(ui, view.editor(EXPANDS_EDITOR), view.results(EXPANDS_RESULTS, FOLDS_RESULTS), {panels = panels, named = &"centre", runs = GdChime.Layout.COLUMN, folds = FOLDS_RESULTS})
	var rest: GdChime.Desc = GdChime.Panes.split(ui, centre, view.schema(), {panels = panels, named = &"rest", runs = standing, folds = FOLDS_SCHEMA})
	var body: GdChime.Desc = GdChime.Panes.split(ui, view.explorer(), rest, {panels = panels, named = &"outer", runs = standing, folds = FOLDS_EXPLORER})
	# the palette opened from the bar, and the panes' menu every target opens
	palette = GdChime.CommandPalette.make(ui, search)
	GdChime.ContextMenu.make(ui, menu)
	var search_press: Desc = ui.pressable(OPENS_PALETTE, {}, [ui.row([ui.text(ui.words(OPENS_PALETTE), Themes.FACE).grow(), GdChime.Hint.make(ui, OPENS_PALETTE)])], GdChime.Pressables.BUTTON).opens(palette).grow()
	var toggles: Array = [[FOLDS_EXPLORER, &"explorer"], [FOLDS_SCHEMA, &"schema"], [FOLDS_RESULTS, &"results"]].map(func(one: Array) -> Desc: return GdChime.Panes.toggle(ui, one[0], panels.shown(one[1])))
	var bar: Array = [search_press, _pressed(Workbench.MAKES), _pressed(Workbench.RUNS), _pressed(GdChime.Documents.CLOSES_FRONT)] + toggles
	# the shell's frame, its tray offering a finished run's results
	# the results' table's models answer in the app's region, where the table is described
	return ui.app(APP, [GdChime.Shell.make(ui, bar, body, {status = _status(), notifications = notifications, offers = {Workbench.SHOWS_RESULTS: &""}})], bench.table.all())


## A press of an action with its words and its key beside them, and why it cannot be used under them.
func _pressed(action: StringName) -> Desc:
	var said := ui.row([ui.text(ui.words(action), Themes.FACE), GdChime.Hint.make(ui, action)])
	return ui.pressable(action, {}, [ui.column([said, ui.reason(Themes.REASON)])], GdChime.Pressables.BUTTON)


## The status line: how many queries are open, and where the layout is kept.
func _status() -> GdChime.Bound:
	return ui.bound(documents.get_open).map(func(open: Array) -> Variant: return GdChime.Phrase.with("%d queries open. The layout, the queries open and the keys are kept in %s", [open.size(), settings.get_file_path()]))
