extends RefCounted

const Ui := preload("../primitives/ui.gd")
const Desc := preload("../primitives/desc.gd")
const Options := preload("../primitives/options.gd")

## A screen's page: what it shows, in the one scroll down a screen has, with
## at most a held line pinned above it and one below - the line holding the
## action the screen is for, which never scrolls out of reach.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## SCROLLING: a head, then the page scrolling down (page_scroll.gd) - the
## spill of a held bar first (app_bar.gd), then the body - then a foot. The
## page asks for no room across, so nothing on it widens the screen.
##
## HELD, for a list: the head and the foot stay where they are and the list
## scrolls itself, which needs the room to show the rows it must - its own
## least height, said where the list is described. Where the room between
## the head and the foot is too short for that, the page becomes a scrolling
## one, with the same list drawn whole in it (while_fits.gd): a list that
## scrolls never stands inside a page that scrolls, so neither is ever a
## strip too short to read.
##
## THE HELD ROW HOLDING THE ACTION IN HAND is named for its place
## (in_hand), so whatever proves it stays on the screen finds it by that
## name. Each held line is one line: the head and the foot are never
## scrolled, and so never grow past the room.
##
## A held page builds its spill twice, once beside each list, of which one
## stands at a time: so the spill is never a named piece, which would be
## two of a name.
##
## It is a description and nothing else: no node is made here.

## A page's options: spill, the held bar's lines folded to the head of the
## page; head and foot, the held lines pinned above and below it.
const SCROLLING_OPTIONS: Array[String] = ["spill", "head", "foot"]
## A held page's options, the first two required: body, the list scrolling
## itself, its least height the rows it must show; whole, the same list
## drawn whole; and spill, head and foot as a scrolling page's.
const HELD_OPTIONS: Array[String] = ["body", "whole", "spill", "head", "foot"]


## The name of the held line holding a place's action in hand.
static func in_hand(place: StringName) -> StringName:
	return StringName("%s in hand" % place)


## The head, the page scrolling down with the spill over the body, and the foot.
static func scrolling(ui: Ui, body: Desc, options: Dictionary = {}) -> Desc:
	Options.checked("a scrolling page", options, SCROLLING_OPTIONS)
	return ui.column(_held_lines(options, ui.page_scroll(ui.column(_spilled(options, body))).grow()))


## The head and the foot held, the list between them scrolling itself while
## the room shows its rows; where it does not, a scrolling page with the
## list drawn whole between the same head and foot.
static func held(ui: Ui, options: Dictionary) -> Desc:
	Options.checked("a held page", options, HELD_OPTIONS)
	var listed := ui.column(_spilled(options, options["body"].grow()))
	var drawn_whole := ui.page_scroll(ui.column(_spilled(options, options["whole"])))
	return ui.column(_held_lines(options, ui.while_fits(listed, drawn_whole).grow()))


## The spill, where there is one, over the body.
static func _spilled(options: Dictionary, body: Desc) -> Array:
	return [options["spill"], body] if options.has("spill") else [body]


## The head, where there is one, over the middle, over the foot, where there is one.
static func _held_lines(options: Dictionary, middle: Desc) -> Array:
	var lines: Array = [options["head"]] if options.has("head") else []
	lines.append(middle)
	if options.has("foot"):
		lines.append(options["foot"])
	return lines
