extends "res://addons/gd_chime/application.gd"

const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const NavControl := preload("res://addons/gd_chime/components/recipes/nav_control.gd")
const Card := preload("res://addons/gd_chime/components/recipes/card.gd")
const Collection := preload("res://addons/gd_chime/components/recipes/collection.gd")
const CellReadout := preload("res://addons/gd_chime/components/recipes/cell_readout.gd")
const Tabs := preload("res://addons/gd_chime/components/recipes/tab_bar.gd")
const FilterSet := preload("res://addons/gd_chime/components/recipes/filter_set.gd")
const Countdown := preload("res://addons/gd_chime/components/recipes/countdown.gd")
const AmountField := preload("res://addons/gd_chime/components/recipes/amount_field.gd")
const Board := preload("res://addons/gd_chime/components/recipes/board.gd")
const Attention := preload("res://addons/gd_chime/components/recipes/attention.gd")
const Guide := preload("res://addons/gd_chime/guide.gd")
const Looks := preload("res://demo/gallery/looks/looks.gd")
const Sight := preload("res://demo/gallery/looks/sight.gd")
const SimulatedSight := preload("res://addons/gd_chime/components/primitives/simulated_sight.gd")
const DevCommands := preload("res://addons/gd_chime/dev_commands.gd")
const Matrix := preload("res://addons/gd_chime/components/recipes/matrix.gd")
const InstructionBar := preload("res://addons/gd_chime/components/recipes/instruction_bar.gd")
const Graph := preload("res://addons/gd_chime/components/recipes/relationship_graph.gd")
const Disposition := preload("res://addons/gd_chime/components/recipes/disposition.gd")
const Moment := preload("res://addons/gd_chime/components/recipes/moment.gd")
const Models := preload("res://demo/gallery/gallery_models.gd")
const Notes := preload("res://demo/gallery/drafts.gd")
const Dial := preload("res://demo/clock/dial.gd")
const DemoTheme := preload("res://demo/demo_theme.gd")
const Pieces := preload("res://demo/gallery/pieces.gd")
const More := preload("res://demo/gallery/more_models.gd")
const MorePieces := preload("res://demo/gallery/more_pieces.gd")
const Probe := preload("res://demo/gallery/probe.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")

## The stall: everything a stall demo does, so that ten demos in ten
## design languages differ in their arrangement alone. This wires the
## models, the actions and their words, the guide over the restocking
## act, and the look; a demo extending it answers arrange() with the
## description of its screens.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE FUNCTIONALITY IS FIXED, THE ARRANGEMENT IS THE DEMO'S. Every stall
## demo has the same places - ABOUT, READOUTS, NAVIGATION, SETS, GRAPH,
## MATRIX, DETAIL - reached by the same actions, over the same models: the
## crates (Things), the filters over them, the restocking act, an item
## with a disposition, the family of suppliers, and a note kept with the
## detail's history entry - and SETTINGS, LEDGER, KNOCKOUT, TAKINGS, the
## second family's four screens, the same in every stall (more_pieces.gd),
## which a demo adds to its stack as `more.screens()`. EVERY COMPONENT IS A PIECE (pieces.gd), built
## once over the models: a demo asks `pieces` for one by name and places
## it. What differs is how a demo lays those out: flaps on a panel or a
## rail, one screen or seven, boxes or whitespace - the design language's
## own answer. Run with --probe and a demo walks
## its functionality and reports, so every arrangement is proved the same.

const STALL := &"gallery"
const ABOUT := &"about"
const READOUTS := &"readouts"
const NAVIGATION := &"navigation"
const SETS := &"sets"
const GRAPH := &"graph"
const MATRIX := &"matrix"
const DETAIL := &"detail"
const SETTINGS := &"settings"
const LEDGER := &"ledger"
const KNOCKOUT := &"knockout"
const TAKINGS := &"takings"
## Every place a stall must have, for the probe.
const PLACES := [ABOUT, READOUTS, NAVIGATION, SETS, GRAPH, MATRIX, DETAIL, SETTINGS, LEDGER, KNOCKOUT, TAKINGS]
const SHOWS_START := &"shows_the_start"
const SHOWS_READOUTS := &"shows_the_readouts"
const SHOWS_NAVIGATION := &"shows_the_navigation"
const SHOWS_SETS := &"shows_the_sets"
const SHOWS_GRAPH := &"shows_the_graph"
const SHOWS_MATRIX := &"shows_the_matrix"
const SHOWS_SETTINGS := &"shows_the_settings"
const SHOWS_LEDGER := &"shows_the_ledger"
const SHOWS_KNOCKOUT := &"shows_the_knockout"
const SHOWS_TAKINGS := &"shows_the_takings"
const GOES_BACK := &"goes_back"
## Every tab, in order: the action that shows it and the place it shows.
const TABS := [[SHOWS_START, ABOUT], [SHOWS_READOUTS, READOUTS], [SHOWS_NAVIGATION, NAVIGATION], [SHOWS_SETS, SETS], [SHOWS_GRAPH, GRAPH], [SHOWS_MATRIX, MATRIX], [SHOWS_SETTINGS, SETTINGS], [SHOWS_LEDGER, LEDGER], [SHOWS_KNOCKOUT, KNOCKOUT], [SHOWS_TAKINGS, TAKINGS]]
const ACTIONS := {SHOWS_START: ["Start here"], SHOWS_READOUTS: ["One crate, six ways"], SHOWS_NAVIGATION: ["Cards and links"], SHOWS_SETS: ["Lists of crates"], SHOWS_GRAPH: ["Suppliers"], SHOWS_MATRIX: ["Crate vs crate"], GOES_BACK: ["Back"], Models.Things.ADDS: ["Add a crate"], Models.Things.SORTS: ["Sort by name"], Models.Things.OPENS: ["Open"], Models.Things.COMPARES: ["Compare"], Models.Filters.NARROWS_PROPERTIES: ["Find a property"], Models.Filters.PICKS_PROPERTY: ["Property"], Models.Filters.PICKS_COMPARISON: ["Comparison"], Models.Filters.NARROWS_VALUES: ["Find a value"], Models.Filters.PICKS_VALUE: ["Pick the value"], Models.Filters.SETS_VALUE: ["Value"], Models.Filters.TOGGLES: ["Toggle"], Models.Filters.REMOVES: ["Remove"], Models.Act.STARTS: ["Start restocking"], Models.Act.TAKES_A_STEP: ["Pick a crate"], Models.Act.CANCELS: ["Stop restocking"], Models.Act.CARRIES_ON: ["Carry on"], Models.Item.ENTERS: ["Put on the stall"], Models.Item.LISTS: ["Put up for sale"], Models.Item.RELEASES: ["Give away"], Models.Item.SETS_PRICE: ["Set the price"], Models.Family.PANS: ["Pan"], Models.Family.ZOOMS: ["Zoom"], Models.Family.PICKS: ["Pick"], Models.Family.ZOOMS_IN: ["Zoom in"], Models.Family.ZOOMS_OUT: ["Zoom out"], Models.Family.EXPANDS: ["Who else they deal with"], Models.Family.OPENS: ["Open"], Notes.Drafts.WRITES: ["Note"], Notes.Drafts.TICKS: ["Tick"], Looks.PICKS: ["Look"], Sight.PICKS: ["Sight"], SHOWS_SETTINGS: ["Settings"], SHOWS_LEDGER: ["Ledger"], SHOWS_KNOCKOUT: ["Knockout"], SHOWS_TAKINGS: ["Takings"], More.Prefs.TURNS_SOUND: ["Sound"], More.Prefs.OPENS_PACES: ["Choose a pace"], More.Prefs.PICKS_PACE: ["This pace"], More.Prefs.BINDS_CALL: ["Bind"], More.Prefs.NAMES_STALL: ["Name the stall"], More.Prefs.ASKS_TO_CLEAR: ["Clear the day"], More.Prefs.CLEARS_DAY: ["Yes, clear it"], More.Ledger.SORTS: ["Sort"], More.Ledger.NARROWS_CRATES: ["Find a crate"], More.Ledger.PICKS_CRATE: ["This crate"], More.Knockout.DECIDES: ["Decide the next tie"], More.Takings.ADDS_DAY: ["Add a day"], More.Kept.ASKS_TO_DROP: ["Throw away"], More.Kept.DROPS: ["Yes, throw it away"]}
## The actions of the filter-set and the graph, by the names their recipes ask.
const FILTER_ACTIONS := {"types_property": Models.Filters.NARROWS_PROPERTIES, "picks_property": Models.Filters.PICKS_PROPERTY, "picks_comparison": Models.Filters.PICKS_COMPARISON, "types_value": Models.Filters.NARROWS_VALUES, "picks_value": Models.Filters.PICKS_VALUE, "sets_value": Models.Filters.SETS_VALUE, "toggles": Models.Filters.TOGGLES, "removes": Models.Filters.REMOVES}
const GRAPH_ACTIONS := {"pans": Models.Family.PANS, "zooms": Models.Family.ZOOMS, "picks": Models.Family.PICKS, "zooms_in": Models.Family.ZOOMS_IN, "zooms_out": Models.Family.ZOOMS_OUT, "expands": Models.Family.EXPANDS, "opens": Models.Family.OPENS}

var things: Models.Things
var filters: Models.Filters
var act: Models.Act
var item: Models.Item
var family: Models.Family
var drafts: Notes.Drafts
var _time: Bound  # the time, read every frame
var _looks: Looks
var _sight: Sight
var _dev: DevCommands  # held: registering a command does not keep what it was made of alive
var prefs: More.Prefs
var ledger: More.Ledger
var knockout: More.Knockout
var takings: More.Takings
var kept: More.Kept
## Every component of the stall, by name, for the arrangement to place.
var pieces: Pieces
## The second family: four screens the same in every stall, and their overlays.
var more: MorePieces


## The look this demo is drawn in, unless one is asked for at launch.
func worn() -> StringName:
	return &"placeholder"


func look() -> Theme:
	return Looks.make(_asked())


func sources() -> Array[StringName]:
	return [&"guide"]


func declare(register: Actions) -> void:
	register.declare_all(ACTIONS)


## The models made, every action answered, the guide set walking, and the
## arrangement asked of the demo.
func describe() -> Desc:
	# every model of the stall, answering its own actions from anywhere, whatever screen presses them
	things = model(Models.Things.new(chimes))
	filters = model(Models.Filters.new(chimes, Models.Things.NAMES))
	act = model(Models.Act.new(chimes))
	item = model(Models.Item.new(chimes))
	family = model(Models.Family.new(chimes))
	drafts = model(Notes.Drafts.new(chimes, driver))
	_sight = model(Sight.new(chimes))
	_looks = model(Looks.new(chimes, root, _sight))
	_dev = DevCommands.new()
	# the simulator: the screen as that eye receives it, over everything, pressing nothing
	_dev.register(&"sight", "shows the screen as a colour-blind eye receives it", SimulatedSight.simulate.bind(ui.root))
	commands.register(Chimes.GLOBAL, DevCommands.RUN_LINE, _dev)
	_looks.wear(_asked())
	_time = ui.every_frame(Dial.now)
	prefs = model(More.Prefs.new(chimes))
	ledger = model(More.Ledger.new(chimes, things))
	model(ledger.narrowing)
	knockout = model(More.Knockout.new(chimes))
	takings = model(More.Takings.new(chimes))
	kept = model(More.Kept.new(chimes))
	# the guide walks the act: start it, then three steps; the glow moves with it and goes when it is done
	model(Guide.new(chimes, commands, actions, prompts, &"guide", [Models.Act.STARTS, Models.Act.TAKES_A_STEP, Models.Act.TAKES_A_STEP, Models.Act.TAKES_A_STEP], driver))
	pieces = Pieces.new(self)
	more = MorePieces.new(self)
	return arrange()


## The walk that stands in for a reader at this stall.
func probe() -> RefCounted:
	return Probe.new(self)


## The demo's arrangement: its screens, described. Every stall says.
func arrange() -> Desc:
	push_error("a stall demo describes its arrangement")
	return null


## Every place this stall has, for the probe to find and look at: the ones
## every stall must have, unless a stall has places of its own besides.
func places() -> Array:
	return PLACES


## Every flap, in order, as [the action that shows it, the place it shows].
func tabs() -> Array:
	return TABS


## Every pop-up, as [its name, the parameter it is raised with], for the
## probe to raise over the rest and look at: the pace's choice where its
## press says it goes, and the two questions.
func pop_ups() -> Array:
	return [[driver.goes_to(SETTINGS, More.Prefs.OPENS_PACES), null], [more.clearing.get_place(), null], [more.dropping.get_place(), 1]]


## What a stall claims beyond what every stall does, walked by the probe
## once the rest is: nothing, unless a stall does more.
func claims() -> Dictionary:
	return {}


## The one bound to the crate the detail was entered as: re-read as the
## crates move and as the reader does, since which crate is the history's.
func picked() -> Bound:
	var crates: Bound = ui.bound(things.get_things)
	return ui.parameter(DETAIL).map(func(which: Variant) -> Variant: return null if which == null else crates.read()[int(which) - 1])


## The detail's title: which crate it was entered as.
func picked_words() -> Bound:
	return picked().map(func(crate: Variant) -> Phrase: return Phrase.of("No crate") if crate == null else Phrase.with("Crate: %s", [crate["name"]]))


## The look asked for at launch, else the demo's own.
func _asked() -> StringName:
	var asked := Looks.asked()
	return worn() if asked == &"placeholder" else asked
