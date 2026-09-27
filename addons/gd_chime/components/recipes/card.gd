extends RefCounted

const Themes := preload("../../theme.gd")
const Ui := preload("../primitives/ui.gd")
const Options := preload("../primitives/options.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Local := preload("../primitives/local.gd")
const Loading := preload("loading.gd")
const Phrase := preload("../../phrase.gd")

## A card: a tile that summarises one thing and opens it - the whole tile
## is the target. LIST style, a full-width row; TILE style, a grid cell;
## DENSE, a cell combining a live view, the numbers and the controls for
## acting on it; and EMPTY, a free position carrying the ways to fill it,
## RESERVED once one of them has claimed it.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A card is one pressable holding its readouts, so it has ONE primary
## action - opening the thing - and carries its thing as the parameter of
## the move. What it shows is passed in: the readouts are the caller's, so
## a card carries enough to choose without opening because its caller put
## it there. A dense card's acting controls are inside the tile but are
## pressables of their own, each its own region on the tile.
##
## A CARD HAS A LOADING FORM, loading(), for a position in a collection
## whose thing is still on its way: the card's own ground, whatever stands
## where its picture will, and the shapes of the lines to come, pulsing
## (loading.gd). It is the one loading look a card wears - never a stack of
## grounds built by hand at the call site, and never the word "..." - so a
## page arriving changes what a position holds and not the room it takes.
##
## MORE is a line of extra detail revealed in place, among a card's
## readouts: a press of its own on the tile that opens nothing and runs no
## command. Whether it shows is the interface's alone, so it is a local
## (local.gd) - and not kept: a card that comes back comes back closed.
## Its words, and a reservation's, go to the text in English - the claim in
## a reservation as it is - to be said in the language on (text.gd).

const MORE := "More"
const LESS := "Less"


## What every card takes by name: goes_to, the place a press opens;
## id_key, which key of the thing the press carries as its parameter; and
## style. A dense card takes two more: view, the live view across its top,
## and controls, the acting controls along its bottom.
const OPTIONS: Array[String] = [Options.GOES_TO, Options.ID_KEY, Options.STYLE]
const DENSE_OPTIONS: Array[String] = [Options.GOES_TO, Options.ID_KEY, Options.STYLE, "view", "controls"]


## A list card: across the row, the readouts along it.
static func list(ui: Ui, action: StringName, thing: Bound, readouts: Array, options: Dictionary = {}) -> Desc:
	Options.checked("a list card", options, OPTIONS)
	return _card(ui, action, thing, [ui.row(readouts)], options, &"CardList")


## A tile card: a cell, the readouts down it.
static func tile(ui: Ui, action: StringName, thing: Bound, readouts: Array, options: Dictionary = {}) -> Desc:
	Options.checked("a tile card", options, OPTIONS)
	return _card(ui, action, thing, [ui.column(readouts)], options, &"CardTile")


## A dense card: a live view across the top, the numbers under it, and the
## acting controls the surface supplies along the bottom.
static func dense(ui: Ui, action: StringName, thing: Bound, readouts: Array, options: Dictionary = {}) -> Desc:
	Options.checked("a dense card", options, DENSE_OPTIONS)
	var view: Desc = options["view"]
	var body := ui.column([view.grow(2.0), ui.row(readouts).grow(), ui.row(options["controls"]).grow()])
	return _card(ui, action, thing, [body], options, &"CardDense")


## The press a card is, carrying the thing's identity, going where the
## options say - nowhere, and it stays where it is.
static func _card(ui: Ui, action: StringName, thing: Bound, content: Array, options: Dictionary, base: StringName) -> Desc:
	var made := ui.pressable(action, _parameter(thing, options.get(Options.ID_KEY, "id")), content, options.get(Options.STYLE, base))
	return made.goes_to(options[Options.GOES_TO]) if options.has(Options.GOES_TO) else made


## A card standing in for a thing on its way: so many shapes where its
## readouts will land, pulsing. Its options: style, the card's ground -
## a tile's, given none - and above, what stands over the shapes where the
## card's picture will be, for a look that does not jump as it lands.
const LOADING_OPTIONS: Array[String] = [Options.STYLE, "above"]

static func loading(ui: Ui, lines: int, options: Dictionary = {}) -> Desc:
	Options.checked("a loading card", options, LOADING_OPTIONS)
	var over: Array = [options["above"]] if options.has("above") else []
	return ui.surface(options.get(Options.STYLE, &"CardTile"), [ui.column(over + [ui.pulse([Loading.shapes(ui, lines)])])])


## An empty position: the ways to fill it, or, reserved, what it is
## expecting - the reservation a bound value reading what claimed it, or
## nothing while free.
static func empty(ui: Ui, ways: Array, reserved: Bound, style: StringName = &"CardEmpty") -> Desc:
	var expecting: Bound = reserved.map(func(claim: Variant) -> Variant: return "" if claim == null else Phrase.with("Expecting %s", [claim]))
	return ui.surface(style, [ui.when(reserved, ui.text(expecting, Themes.FACE), ui.row(ways))])


## A line of detail shown and hidden in place: the press that says more or
## less, over the detail while it is asked for. Put among a card's readouts.
static func more(ui: Ui, detail: Desc, style: StringName = &"CardMore") -> Desc:
	var shown: Local = ui.local(false)
	var says := ui.text(shown.map(func(is_shown: bool) -> Variant: return Phrase.of(LESS if is_shown else MORE)), Themes.REASON)
	return ui.column([ui.press_local(shown, func(is_shown: bool) -> bool: return not is_shown, [says], style), ui.when(shown, detail)])


static func _parameter(thing: Bound, id_key: Variant) -> Bound:
	return thing.map(func(item: Variant) -> Dictionary: return {"parameter": item[id_key] if item != null else null})
