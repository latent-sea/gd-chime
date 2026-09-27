extends "res://addons/gd_chime/application.gd"

const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Things := preload("res://demo/collection/things.gd")
const DemoTheme := preload("res://demo/demo_theme.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")

## A collection: a list of things that starts empty, with a button in every
## row, a sort and a filter, a detail screen a row opens, and a row that
## shows two shapes.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --path <this folder> --script res://demo/collection/collection.gd
##
## Press ADD THREE THINGS and rows appear; the list began empty, and the
## actions its rows perform were declared all the same, since the builder
## asked the row's template once with an empty handle as the list was
## built. SORT BY NAME reorders the rows and SHOW ONLY THE FLIPPED shortens
## them: the rows are kept by their thing's id, so the one with the focus
## keeps it through both. FLIP on a row turns its shape - a when inside the
## row - and OPEN on a row goes to the detail of that thing; BACK TO THE
## LIST returns, the focus back on the row's OPEN, since the row was never
## rebuilt. SORT and the filter are refused while there is nothing to sort
## or filter, and ADD once every thing has been added. The standard wiring
## is application.gd's; this file answers its questions and never listens.

const APP := &"app"
const CONTENT := &"content"
const LIST := &"list"
const DETAIL := &"detail"


func look() -> Theme:
	return DemoTheme.new()


func declare(register: Actions) -> void:
	register.declare_all(Things.ACTIONS)


func describe() -> Desc:
	var things := Things.new(chimes)
	var strip := ui.row([ui.button(Things.ADDS).grow(), ui.button(Things.SORTS).grow(), ui.button(Things.SHOWS_ONLY_FLIPPED).grow()])
	var rows := ui.screen(LIST, [ui.scroll(ui.each(ui.bound(things.get_things), func(thing: Bound) -> Desc: return _row(thing), func(thing: Dictionary) -> int: return thing["id"]))], things)
	var picked: Bound = ui.bound(things.get_picked).map(func(thing: Variant) -> Phrase: return Phrase.of("Nothing picked") if thing == null else Phrase.with("%s, %s", [thing["name"], Phrase.of("Flipped") if thing["flipped"] else Phrase.of("Plain")]))
	var detail := ui.screen(DETAIL, [ui.column([ui.text(picked, Themes.TITLE), ui.button(Things.RETURNS, {goes_to = Driver.BACK})])])
	# the things answer in the app's region, where the strip's three buttons are described
	return ui.app(APP, [ui.column([strip.basis(0.12), ui.screen(CONTENT, [ui.stack([rows, detail])]).grow()])], things)


## A row: the thing's name, its shape, and its two buttons, each carrying
## the thing's id as the press lands.
func _row(thing: Bound) -> Desc:
	var id: Bound = thing.map(func(item: Variant) -> Dictionary: return {"id": item["id"] if item != null else -1})
	var shape := ui.when(thing.field("flipped"), ui.text(Phrase.of("Flipped"), DemoTheme.READOUT), ui.text(Phrase.of("Plain"), DemoTheme.READOUT))
	return ui.surface(Themes.CARD, [ui.row([ui.text(thing.field("name"), Themes.TITLE).grow(2.0), shape.grow(), ui.button(Things.FLIPS, {payload = id}).grow(), ui.button(Things.OPENS, {payload = id, goes_to = DETAIL}).grow()])])
