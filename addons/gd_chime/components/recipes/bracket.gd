extends RefCounted

const Themes := preload("../../theme.gd")
const Ui := preload("../primitives/ui.gd")
const Options := preload("../primitives/options.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const NavControl := preload("nav_control.gd")
const Phrase := preload("../../phrase.gd")

## A bracket: the ties of a knockout and the rounds they run in - a tree
## read left to right, one column per round, one cell per tie, and inside a
## cell the two entrants as links to whatever their place is.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The MODEL owns the tree: which rounds there are, which ties are in each,
## who is in a tie and who won it. The recipe only reads it, so a result
## arriving is a model change and its bell, never a rebuild here - the ties
## are kept by their identity, so the cell that was showing the pairing is
## the cell that shows the winner. A round's ties are spread down its
## column by the look, which is what puts a later round's tie beside the
## gap between the two ties that feed it; the recipe names the column and
## sets no numbers. The winner is marked with a WORD beside the name, never
## by colour alone, and a slot with nobody in it yet says so instead of
## offering a link to nothing - both words handed to the text in English,
## to be said in the language on as it draws (text.gd).

const WON := "Won"
const UNDECIDED := "To be decided"


## The bracket: the rounds across, each an equal share of the width, its
## name over its ties, each tie a cell of two entrant lines.
## Its options: goes_to, the place a tie opens, and style.
const OPTIONS: Array[String] = [Options.GOES_TO, Options.STYLE]

static func make(ui: Ui, rounds: Bound, opens: StringName, options: Dictionary = {}) -> Desc:
	Options.checked("a bracket", options, OPTIONS)
	var goes_to: StringName = options[Options.GOES_TO]
	var style: StringName = options.get(Options.STYLE, &"Bracket")
	var by_id := func(item: Dictionary) -> Variant: return item["id"]
	var column := func(one_round: Bound) -> Desc:
		var cells := func(one_tie: Bound) -> Desc: return _tie(ui, one_tie, opens, goes_to)
		return ui.column([
			ui.text(one_round.field("name"), Themes.FACE),
			ui.each(one_round.field("ties"), cells, by_id, &"BracketRound").grow(),
		]).grow()
	return ui.scroll(ui.each_across(rounds, column, by_id, style))


## One tie: a cell holding its two entrant lines.
static func _tie(ui: Ui, tie: Bound, opens: StringName, goes_to: StringName) -> Desc:
	return ui.surface(&"Tie", [ui.column([
		_entrant(ui, tie, "a", opens, goes_to),
		_entrant(ui, tie, "b", opens, goes_to),
	])])


## One entrant line: a link to the entrant's place, or the placeholder
## while the slot is undecided, and the winner's mark beside it.
static func _entrant(ui: Ui, tie: Bound, side: String, opens: StringName, goes_to: StringName) -> Desc:
	var entrant: Bound = tie.field(side)
	# the mark is empty for everyone but the winner, and empty words hide
	var mark: Bound = tie.map(func(held: Variant) -> Variant: return Phrase.of(WON) if held != null and held[side] != null and held["winner"] == held[side]["id"] else "")
	var named := NavControl.inline(ui, opens, entrant, {goes_to = goes_to})
	return ui.row([
		ui.when(entrant, named, ui.text(Phrase.of(UNDECIDED), Themes.FACE)),
		ui.text(mark, Themes.FACE).hides_empty(),
	])
