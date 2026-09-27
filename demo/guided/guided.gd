extends "res://addons/gd_chime/application.gd"

const Taken := preload("res://addons/gd_chime/taken.gd")
const Reminders := preload("res://addons/gd_chime/reminders.gd")
const Guide := preload("res://addons/gd_chime/guide.gd")
const PromptBar := preload("res://addons/gd_chime/components/recipes/prompt_bar.gd")
const Declared := preload("res://demo/guided/declared.gd")
const Ledger := preload("res://demo/guided/ledger.gd")
const Developer := preload("res://demo/guided/developer.gd")
const Readout := preload("res://demo/guided/readout.gd")
const DemoTheme := preload("res://demo/demo_theme.gd")
const Sheet := preload("res://addons/gd_chime/components/recipes/sheet.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")

## The command stream in one window, in the blueprint's shape on the one
## tree: a strip across the top that is always there, places beneath it that
## take each other's place, tabs inside one of them, cards inside a tab, and
## a pop-up that borrows the reader - DESCRIBED, not built by hand.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --path <this folder> --script res://demo/guided/guided.gd -- --console
##
## THE TREE IS THE STATECHART. The app is the root place; the strip sits in
## it, no place, holding the prompt bar, BACK and the LEDGER link - so it is
## always there and never touched. The content beneath is a place holding
## two places that take each other's place: THE HOME, three buttons, two
## SAVE THE DAY and WAVE; and THE LEDGER, with two tabs, COINS and NOTES,
## places inside it - arriving at the ledger enters the coins, its first,
## and a tab arrived at is shown in the other's place. The coins tab holds
## two CARDS, each with a COUNT A COIN, the first with a ZOOM as well; the
## notes tab one JOT A NOTE. THE ZOOM is a pop-up over the app, an
## overlay with a CLOSE inside it. All of it is one description handed to
## the builder (ui.gd): a place declares what it performs from the
## pressables inside it, and the model given as handled_by answers them in
## that place's region. The builder checks the tree once it has entered - a
## broken one is said and the demo does not run - and makes the first move.
##
## EVERY MOVE IS A COMMAND THROUGH THE DOOR: a button draws one of its
## place's actions, and the door hands the move to the driver once the
## action's handler, if any, has not refused - a pure link needs none. A
## button asks the door whether its press would be refused and is inert
## with that reason, so the ledger link, the tabs and Back disable
## themselves. The guide walks the steps in the order the player is meant
## to find them, pointing at the link that leads to the next; done, the
## reminders take over. The bar reads the register's words. The console is
## built with the launch switch (developer.gd), the panel beside it all.
## The bottom lines read the record, the prompt, the deeds and the last
## command, each a bound value. This file composes and never listens.

## A model that does the home screen's deeds: it keeps the last one done, a value.
class Deeds extends Controller:
	var _last := value(Phrase.of("Nothing yet"))

	func _init(chimes: Chimes) -> void:
		super(chimes, [], Chimes.GLOBAL)

	func get_last() -> Phrase:
		return _last.read()

	func told(action: StringName, _payload: Dictionary) -> Phrase:
		_last.set_value(Phrase.with("%s, done", [action]))
		return null


func look() -> Theme:
	return DemoTheme.new()


func sources() -> Array[StringName]:
	return [&"guide", &"reminder"]


func declare(register: Actions) -> void:
	Declared.declare(register)


## The models made and put beside the app, the console where the switch
## asks for it, and the app described.
func describe() -> Desc:
	var taken := Taken.new(chimes, actions, commands)
	# the actions worth reminding of: the deeds, never the doors
	for action: StringName in [Declared.SAVES, Declared.WAVES, Ledger.COUNTS, Ledger.JOTS]:
		taken.track(action)
	var deeds: Deeds = model(Deeds.new(chimes))
	var coins: Ledger.Coins = model(Ledger.Coins.new(chimes))
	var notes: Ledger.Notes = model(Ledger.Notes.new(chimes))
	var random := RandomNumberGenerator.new()
	random.randomize()
	# the reminders and the guide ask the driver what can be reached, and hear it as that changes
	model(Reminders.new(chimes, taken, prompts, &"reminder", random, driver))
	model(Guide.new(chimes, commands, actions, prompts, &"guide", Declared.STEPS, driver))
	model(taken)
	if Developer.asked_for():
		ui.also(Developer.console(ui))
	return _app(taken, deeds, coins, notes)


## The app: the strip across the top, the content beneath, the readout at
## the bottom.
func _app(taken: Taken, deeds: Deeds, coins: Ledger.Coins, notes: Ledger.Notes) -> Desc:
	var strip := ui.row([PromptBar.make(ui, prompts).grow(), ui.button(Ledger.GOES_BACK, {goes_to = Driver.BACK}).grow(), ui.button(Ledger.OPENS, {goes_to = Ledger.LEDGER}).grow()])
	var home := ui.screen(Ledger.HOME, [ui.column([ui.button(Declared.SAVES).grow(), ui.button(Declared.SAVES).grow(), ui.button(Declared.WAVES).grow()])], deeds)
	var content := ui.screen(Ledger.CONTENT, [ui.stack([home, _ledger(coins, notes)])])
	return ui.app(Ledger.APP, [ui.column([strip.basis(0.12), content.grow(), Readout.make(ui, taken, prompts, deeds, commands).basis(0.14)])])


## The ledger: two tabs across its top, and the tab arrived at beneath.
func _ledger(coins: Ledger.Coins, notes: Ledger.Notes) -> Desc:
	var tabs := ui.row([ui.button(Ledger.SHOWS_COINS, {goes_to = Ledger.COINS}).grow(), ui.button(Ledger.SHOWS_NOTES, {goes_to = Ledger.NOTES}).grow()])
	var card_with_zoom := ui.surface(Themes.CARD, [ui.column([ui.button(Ledger.COUNTS).grow(), ui.button(Ledger.ZOOMS, {opens = _zoom()}).grow()])])
	var card := ui.surface(Themes.CARD, [ui.column([ui.button(Ledger.COUNTS).grow()])])
	var coins_tab := ui.screen(Ledger.COINS, [ui.row([card_with_zoom.grow(), card.grow()])], coins)
	var notes_tab := ui.screen(Ledger.NOTES, [ui.column([ui.button(Ledger.JOTS).grow()])], notes)
	return ui.tabs(Ledger.LEDGER, [ui.surface(Themes.RAISED, [ui.column([tabs.basis(0.14), ui.stack([coins_tab, notes_tab]).grow()])])])


## The zoom the first card opens: a sheet over everything (sheet.gd), the
## panel with the close in it.
func _zoom() -> Desc:
	return ui.pop_up(&"zoom", func(_which: Bound) -> Desc: return Sheet.over(ui, [Sheet.close(ui).grow()], DemoTheme.PANEL))
