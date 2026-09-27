extends RefCounted

const Themes := preload("../../theme.gd")
const Ui := preload("../primitives/ui.gd")
const Options := preload("../primitives/options.gd")
const Layout := preload("../primitives/layout.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Hint := preload("hint.gd")
const Panels := preload("../../panels.gd")

## The panes of an application shell over its panels (panels.gd): a split
## of two panes the model shares the room of, a titled pane, and the presses
## that fold a pane away and bring it back or expand one over the rest -
## each showing the key it is on and whether its pane shows.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE PANELS HOLD IT ALL: a split's share and fold are the model's, a
## grip's move and a fold are its commands, so a layout dragged, folded or
## expanded is one model's state, kept between runs (settings_file.gd).
## This names the model's reads and commands for a split, so an
## application says which split and which two panes and nothing else.
##
## A PRESS THAT FOLDS A PANE IS A TOGGLE: it wears the look's toggle on
## while the pane shows and off while it is folded - a mark, never a hue
## alone - with its words and the key it is on, so a rail of them is the
## collapsible navigation of a desktop application, walked by the keys and
## the pad like any other presses.

## A press's look while its pane shows, and while it does not.
const SHOWN := &"ToggleOn"
const FOLDED := &"ToggleOff"


## Two panes, the grip between them moving the model's split. Its options:
## panels, the model holding the splits, and named, which of its splits
## this is; runs, Layout.COLUMN for one pane over the other, or a bound
## value reading one of the two; and folds, the action the grip folds the
## pane by as accept or a double press asks.
const SPLIT_OPTIONS: Array[String] = ["panels", "named", Options.RUNS, Options.FOLDS]

static func split(ui: Ui, first: Desc, second: Desc, options: Dictionary = {}) -> Desc:
	Options.checked("a split of panes", options, SPLIT_OPTIONS)
	var panels: Panels = options["panels"]
	var named: StringName = options["named"]
	return ui.split(first, second, panels.share(named), {"resizes": Panels.RESIZES, "carries": {"split": String(named)}, "folded": panels.folded(named), Options.RUNS: options.get(Options.RUNS, Layout.ROW), Options.FOLDS: options.get(Options.FOLDS, &"")})


## A pane: its title over what it holds, the rest of the room its.
static func titled(ui: Ui, title: Variant, content: Desc, style: StringName = &"Pane") -> Desc:
	return ui.surface(style, [ui.column([ui.text(title, Themes.FACE), content.grow()], &"PaneColumn")])


## A press of an action folding or expanding a pane, its words and the key
## it is on, wearing the toggle's look on while the pane shows.
static func toggle(ui: Ui, action: StringName, shown: Bound) -> Desc:
	var worn: Bound = shown.map(func(is_shown: Variant) -> StringName: return SHOWN if is_shown else FOLDED)
	return ui.pressable(action, {}, [ui.row([ui.text(ui.words(action), Themes.FACE).grow(), Hint.make(ui, action)])], worn)
