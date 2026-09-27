extends "res://demo/gallery/boxes.gd"

const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Chip := preload("res://addons/gd_chime/components/recipes/chip.gd")
const Divider := preload("res://addons/gd_chime/components/recipes/divider.gd")
const Models := preload("res://demo/gallery/gallery_models.gd")
const Marks := preload("res://demo/gallery/marks_models.gd")

## Running words and the marks between parts, on a screen of the gallery's
## own (MARKS): a paragraph naming two crates as links, with the stall's
## takings read into it; chips on a crate; and dividers - one across,
## between the two boxes, and one down, between the chips.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The paragraph is long enough to break across lines at every window shape,
## and its two links fall on different lines, so the pad is seen walking from
## the end of one line to the next link rather than by where they stand. A
## link opens its crate's detail, as a row does, carrying the crate's id. The
## chips are the labels on a crate (marks_models.gd): one on, one off - said
## in brackets, never by a colour alone - each with its x; and one, fresh
## today, with no x at all.
##
## One column at every shape: a divider across is a rule between the boxes
## above and below it, so the boxes stand one over the other.

## The screen, and the action that shows it.
const MARKS := &"marks"
const SHOWS_MARKS := &"shows_the_marks"
## The words of this screen's actions, for the gallery's register.
const ACTIONS := {SHOWS_MARKS: ["Words, links and chips"], Marks.Labels.TOGGLES: ["Turn the label on or off"], Marks.Labels.REMOVES: ["Take the label off"], Marks.Labels.PUTS_LABELS_BACK: ["Put the labels back"]}

var _screen: Desc


func _init(stall: SceneTree) -> void:
	super(stall)
	_screen = _marks()


func screen() -> Desc:
	return _screen


func _marks() -> Desc:
	var ui: RefCounted = _stall.ui
	var things: Bound = ui.bound(_stall.things.get_things)
	var labels: Marks.Labels = _stall.labels
	# a crate named in the running words: its name, opening its detail as its id
	var link := func(crate: Bound) -> Desc: return ui.link(Models.Things.OPENS, crate.field("id"), crate.field("name")).goes_to(_stall.DETAIL)
	var pear: Bound = things.field(0)
	var spans := [Phrase.of("This week the "), link.call(pear).named(&"first link"), Phrase.of(" crate sold best of all, taking "), pear.field("won"), Phrase.of(" coins before the market bell rang at noon, while every other crate on the stall, the apples and the dates and the plums and the limes, sold slowly all through a long and rainy afternoon; and the "), link.call(things.field(2)).named(&"second link"), Phrase.of(" crate, the stall's own, is always the last to be unpacked in the morning.")]
	var paragraph: Desc = ui.paragraph(spans).named(&"paragraph")
	# a label on the crate as a chip: on or off, and taken off by its x
	var label := func(one: Bound) -> Desc: return Chip.make(ui, one.field("words"), one.field("on"), one.map(func(item: Variant) -> Dictionary: return {"id": item["id"] if item != null else null}), {toggles = Marks.Labels.TOGGLES, removes = Marks.Labels.REMOVES})
	var removable: Desc = ui.each_across(ui.bound(labels.get_labels), label, func(one: Dictionary) -> int: return one["id"]).named(&"labels")
	var fresh: Desc = Chip.make(ui, Phrase.of("Fresh today"), ui.bound(labels.get_fresh), {"id": Marks.Labels.FRESH}, {toggles = Marks.Labels.TOGGLES}).named(&"fresh")
	var chips: Desc = ui.column([ui.row([removable, Divider.down(ui).named(&"between chips"), fresh]), ui.row([ui.button(Marks.Labels.PUTS_LABELS_BACK)])], DemoTheme.TIGHT)
	var words := _shown(Phrase.of("Paragraph with links"), Phrase.of("Two crates named in running words; press one to open it; the pad walks from one to the next"), paragraph).named(&"paragraph box")
	var marked := _shown(Phrase.of("Chips"), Phrase.of("Press a chip to turn it on or off - off is in brackets - and x to take it off; fresh today has no x"), chips).named(&"chips box")
	return ui.screen(MARKS, [ui.column([words, Divider.across(ui).named(&"between boxes"), marked])])
