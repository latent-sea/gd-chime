extends "describe_forms.gd"

const OpenMenu := preload("../../open_menu.gd")

## The descriptions of an application shell's own pieces: a grip the reader
## resizes something by, a split of two panes with a grip between them, a
## context menu's target, and a piece set down beside a rect.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The rest of the vocabulary is describe.gd's, describe_inputs.gd's and
## describe_forms.gd's, which this extends; describe_places.gd extends this, and the builder
## (ui.gd) that in turn. These stand apart because they are what makes an
## application behave like desktop software rather than a page: panes the
## reader shares the room between, each piece's model holding what it shows.

## A grip's look, unless another is named.
const GRIP := &"Grip"

## The application's one context menu (context_menu.gd), which every menu
## target opens: described once, as the pointer is one, and said here as it
## is described, so a target anywhere - a row of a recipe's - finds it
## without being handed it. The description is let go once the tree stands
## (ui.gd), since a description held by the builder and holding it back
## would keep both for ever; the name stays, for a place built later.
var context_menu: Desc = null
var menu_place: StringName = &""


## A thin edge the reader drags or steps to resize something (grip.gd): each
## move dispatches the action with what carries names and {"by": the share
## of its holder's length it moved} - and {"to"}, in a holder that says its
## share. Its options: runs, Layout.COLUMN for an edge that moves up and
## down rather than side to side; folds, which accept and a double press
## dispatch with what carries names; and style.
const GRIP_OPTIONS: Array[String] = [Options.RUNS, Options.FOLDS, Options.STYLE]

func grip(resizes: StringName, carries: Dictionary, options: Dictionary = {}) -> Desc:
	Options.checked("a grip", options, GRIP_OPTIONS)
	return Desc.new(&"grip", {"action": resizes, "carries": carries, "down": options.get(Options.RUNS, Layout.ROW) == Layout.COLUMN, "folds": options.get(Options.FOLDS, &""), "style": options.get(Options.STYLE, GRIP)})


## Two panes and a grip between them (split.gd): the first taking the share
## a bound value reads. Its options: resizes, the action the grip dispatches
## as the reader moves it, and carries, what that carries; folded, a bound
## value whose reading folds that side away; runs, Layout.COLUMN for panes
## standing one over the other - or a bound value reading one of the two,
## the grip turning with them; folds, dispatched as the reader presses the
## grip; and style.
const SPLIT_OPTIONS: Array[String] = ["resizes", "carries", "folded", Options.RUNS, Options.FOLDS, Options.STYLE]

func split(first: Desc, second: Desc, share: Bound, options: Dictionary = {}) -> Desc:
	Options.checked("a split", options, SPLIT_OPTIONS)
	var runs: Variant = options.get(Options.RUNS, Layout.ROW)
	# which way the panes stand: read as the bound value moves, else settled here
	var down: Variant = runs.map(func(way: Variant) -> bool: return way == Layout.COLUMN) if runs is Bound else runs == Layout.COLUMN
	var between := grip(options["resizes"], options["carries"], {Options.FOLDS: options.get(Options.FOLDS, &""), Options.STYLE: options.get(Options.STYLE, GRIP)})
	return Desc.new(&"split", {"share": share, "folded": options["folded"], "down": down}, [first, between, second])


## What it holds, given a context menu of these declared actions, each press
## of them carrying this payload - a dictionary, or a bound value read as the
## menu opens (menu_target.gd): opened by a right press over it, or the input
## on the opening action while the focus is inside it, going to the app's
## context menu (context_menu). Its place declares every one of them.
func menu_target(offers: Array, payload: Variant, content: Array, opens: StringName = OpenMenu.OPENS) -> Desc:
	return Desc.new(&"menu_target", {"actions": offers, "payload": payload, "opens": opens}, content)


## The same parts, built once, laid into named areas re-flowing with the
## width this has (areas.gd): {name: description}, and the layouts {name:
## {least, columns, rows, areas}} - a line of words a row, each naming the
## part in that cell - the widest least the width meets worn.
func areas(parts: Dictionary, layouts: Dictionary, style: StringName = &"Grid") -> Desc:
	return Desc.new(&"areas", {"names": parts.keys(), "layouts": layouts, "style": style}, parts.values())


## What it holds set down beside the rect a bound value reads, a press past
## it the action given - a pop-up's way back (anchored_at.gd).
func anchored_at(rect: Bound, sends_away: StringName, content: Array) -> Desc:
	return Desc.new(&"anchored_at", {"rect": rect, "sends_away": sends_away}, content)
