extends "res://demo/gallery/stall.gd"

const Shape := preload("res://addons/gd_chime/shape.gd")
const Catalogues := preload("res://addons/gd_chime/catalogues.gd")
const Extra := preload("res://demo/gallery/extra_models.gd")
const ExtraPieces := preload("res://demo/gallery/extra_pieces.gd")
const ExtraProbe := preload("res://demo/gallery/extra_probe.gd")
const Values := preload("res://demo/gallery/values_models.gd")
const ValuesPieces := preload("res://demo/gallery/values_pieces.gd")
const ValuesProbe := preload("res://demo/gallery/values_probe.gd")
const Marks := preload("res://demo/gallery/marks_models.gd")
const MarksPieces := preload("res://demo/gallery/marks_pieces.gd")
const MarksProbe := preload("res://demo/gallery/marks_probe.gd")
const Arrivals := preload("res://demo/gallery/arrivals_models.gd")
const ArrivalsPieces := preload("res://demo/gallery/arrivals_pieces.gd")
const ArrivalsProbe := preload("res://demo/gallery/arrivals_probe.gd")

## The component gallery: every component of the kit, in every variant
## and state, on one described app - tabs over a panel, an instruction bar,
## and a screen per family of components, each in a captioned box.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --path <this folder> --script res://demo/gallery/gallery.gd
## Any look: add -- --look=<name>; the other stall demos under demo/stalls/
## are this functionality in each design language's own arrangement.
##
## This is the PLACEHOLDER arrangement. The functionality and the models
## are the stall's (stall.gd) and every component is a piece (pieces.gd);
## this file only places them: ABOUT explains the window, READOUTS the six
## cell readouts, NAVIGATION the controls, cards, amount field and
## disposition, SETS the collection as rows and tiles and the board, GRAPH
## the suppliers, MATRIX the crates against themselves, DETAIL one crate
## with its note kept with the entry.
##
## ON A WINDOW ON ITS END the same pieces stand otherwise, and are never
## built again (by_shape.gd): back and the clock are a strip over the flaps
## instead of a column beside them, the act's two buttons go under the
## instruction instead of beside it, READOUTS and SETS set their two
## columns one over the other, NAVIGATION's rows of four are two rows of
## two - every row of it a pair, as its last already is - and what to try
## in each box breaks onto more lines. So a note half typed on DETAIL is
## still half typed, and still has the focus, when the window turns.
##
## THE GALLERY HAS SCREENS NO OTHER STALL HAS - MOTION, OPTIONS and
## CARRYING (extra_pieces.gd); VALUES, the controls that set a value
## (values_pieces.gd); MARKS, running words with links, chips and dividers
## (marks_pieces.gd); and ARRIVALS, a text area, loading and the
## application's notifications (arrivals_pieces.gd) - with their flaps,
## their places, their pop-ups, their models and their actions added here
## and nowhere else, so the ten stalls never arrange them; and it reads the
## demos' own words (demo/words) beside the floor's, so its language choice
## has French to choose.

## The demos' catalogues, read beside the floor's.
const WORDS_FOLDER := "res://demo/words"

## The gallery's own actions: each one's words, and for the shelf's three the
## key and pad button it is on to begin with.
static func extra_actions() -> Dictionary:
	return {ExtraPieces.SHOWS_MOTION: ["Motion"], ExtraPieces.SHOWS_OPTIONS: ["Language, sound, keys"], ExtraPieces.SHOWS_CARRYING: ["Drag and drop"], ExtraPieces.SHOWS_FRONT: ["To the front of the stall"], ExtraPieces.SHOWS_BACK_ROOM: ["To the back room"], ExtraPieces.OPENS_LANGUAGES: ["Choose a language"], Language.CHANGES_LANGUAGE: ["This language"], SoundBus.SETS_VOLUME: ["Set the volume"], SoundBus.MUTES_SOUND: ["Mute"], Motion.REDUCES: ["Reduce motion"], Inputs.BINDS: ["Bind"], Inputs.RESTORES_DEFAULTS: ["Restore the defaults"], Extra.Keys.SAVES: ["Save the keys"], Extra.Keys.LOADS: ["Load the keys"], Extra.Shelf.PUTS_ON_SHELF: ["Put a crate on", Actions.keys(KEY_N), Actions.pad(JOY_BUTTON_X)], Extra.Shelf.TAKES: ["Take one off", Actions.keys(KEY_R), Actions.pad(JOY_BUTTON_Y)], Extra.Shelf.TURNS: ["Turn the shelf round", Actions.keys(KEY_T), Actions.pad(JOY_BUTTON_RIGHT_SHOULDER)], Extra.Shelf.RIPENS: ["Ripen"], Extra.Shelf.FILLS: ["Fill"], Extra.Baskets.PUTS_IN: ["Put in the basket"], Extra.Baskets.PUTS_IN_FIGS: ["Put in the fig basket"], Extra.Baskets.EMPTIES: ["Empty the baskets"]}

var shelf: Extra.Shelf
var keys: Extra.Keys
var baskets: Extra.Baskets
var order: Values.Order
var labels: Marks.Labels
var draft: Arrivals.Draft
var stock: Arrivals.Stock
var sales: Arrivals.Sales
## The gallery's own screens and their pop-ups.
var extra: ExtraPieces
var values: ValuesPieces
var marks: MarksPieces
var arrivals: ArrivalsPieces


## The stall's actions, and the gallery's own, the shelf's three on keys.
func declare(register: Actions) -> void:
	super(register)
	register.declare_all(extra_actions())
	register.declare_all(ValuesPieces.ACTIONS)
	register.declare_all(MarksPieces.ACTIONS)
	register.declare_all(ArrivalsPieces.ACTIONS)


## The gallery's own models made, answering their actions from anywhere,
## and the demos' words read; then the stall's.
func describe() -> Desc:
	Catalogues.read(WORDS_FOLDER)
	shelf = Extra.Shelf.new(chimes)
	keys = Extra.Keys.new(chimes, inputs)
	baskets = Extra.Baskets.new(chimes)
	order = Values.Order.new(chimes)
	labels = Marks.Labels.new(chimes)
	draft = Arrivals.Draft.new(chimes)
	stock = Arrivals.Stock.new(chimes, notifications)
	sales = Arrivals.Sales.new(chimes, notifications)
	# every model of the gallery's own, answering its own actions from anywhere
	for made: Node in [shelf, keys, baskets, order, order.narrowing, labels, draft, stock, sales]:
		model(made)
	return super()


func places() -> Array:
	return PLACES + [ExtraPieces.MOTION, ExtraPieces.OPTIONS, ExtraPieces.CARRYING, ValuesPieces.VALUES, MarksPieces.MARKS, ArrivalsPieces.ARRIVALS]


func tabs() -> Array:
	return TABS + [[ExtraPieces.SHOWS_MOTION, ExtraPieces.MOTION], [ExtraPieces.SHOWS_OPTIONS, ExtraPieces.OPTIONS], [ExtraPieces.SHOWS_CARRYING, ExtraPieces.CARRYING], [ValuesPieces.SHOWS_VALUES, ValuesPieces.VALUES], [MarksPieces.SHOWS_MARKS, MarksPieces.MARKS], [ArrivalsPieces.SHOWS_ARRIVALS, ArrivalsPieces.ARRIVALS]]


func pop_ups() -> Array:
	return super() + [[driver.goes_to(ExtraPieces.OPTIONS, ExtraPieces.OPENS_LANGUAGES), null], [driver.goes_to(ValuesPieces.VALUES, ValuesPieces.OPENS_SIZES), null], [driver.goes_to(ValuesPieces.VALUES, ValuesPieces.OPENS_FRUIT), null]]


## The gallery's own screens walked, once the rest of the stall is.
func claims() -> Dictionary:
	# walked in a window of the base the project is written at, whatever window the engine opened with, so the pad's walks are the ones a reader there makes
	root.size = Vector2i(1920, 1080)
	var said: Dictionary = await ExtraProbe.new(self).run()
	said.merge(await ValuesProbe.new(self).run())
	said.merge(await MarksProbe.new(self).run())
	said.merge(await ArrivalsProbe.new(self).run())
	return said


## The placeholder arrangement: flaps on the panel of screens, the
## instruction bar and the act's two buttons with it, the moment over all.
## The gallery's own screens are made first, over the models the stall has made.
func arrange() -> Desc:
	extra = ExtraPieces.new(self)
	values = ValuesPieces.new(self)
	marks = MarksPieces.new(self)
	arrivals = ArrivalsPieces.new(self)
	# back over the clock; on a window on its end, the two side by side as a strip
	# the clock's numbers stand on this ground rather than on the bare window, which a look paints in whatever it likes
	var side := ui.surface(Themes.SURFACE, [ui.by_shape({&"back": pieces.back(), &"clock": pieces.clock()}, {Shape.LANDSCAPE: _arranged(true, [&"back", &"clock"]), Shape.PORTRAIT: _arranged(false, [&"back", &"clock"], {&"back": {"grow": 1.0}, &"clock": {"grow": 1.0}})})])
	# the flaps on their panel with that beside them; on a window on its end, that strip over them
	var top := ui.by_shape({&"tabs": pieces.tabs([_screens()]), &"side": side}, {Shape.LANDSCAPE: _arranged(false, [&"tabs", &"side"], {&"tabs": {"grow": 6.0}, &"side": {"grow": 1.0}}), Shape.PORTRAIT: _arranged(true, [&"side", &"tabs"], {&"tabs": {"grow": 1.0}})})
	var acts := ui.row([pieces.start().grow(), pieces.step().grow()])
	# the instruction with the act's two buttons beside it; on a window on its end, the buttons under it
	var said := ui.by_shape({&"words": pieces.instruction(), &"acts": acts}, {Shape.LANDSCAPE: _arranged(false, [&"words", &"acts"], {&"words": {"grow": 4.0}, &"acts": {"grow": 2.0}}), Shape.PORTRAIT: _arranged(true, [&"words", &"acts"], {&"acts": {"grow": 1.0}})})
	# the bar stands on a ground of its own, as every piece in this gallery does: words on the bare window are read against whatever the look paints it, which is a dark desk in one of them (faint_words.gd)
	var bar := ui.surface(Themes.SURFACE, [said])
	return ui.app(STALL, [ui.stack([ui.column([top.grow(), bar.basis(0.08)]), pieces.moment(Phrase.of("This is a MOMENT: it appears once when something worth marking has happened, and one button dismisses it.")), pieces.bubble()])])


## One arrangement of named parts, as by_shape takes it: down a column or
## along a row, in this order, each under the facts given here or none.
func _arranged(down: bool, order: Array, facts: Dictionary = {}) -> Dictionary:
	var given: Dictionary = {}
	# every part in its order, under the facts given for it or none
	for part: StringName in order:
		given[part] = facts.get(part, {})
	return ui.column_of(order, given) if down else ui.row_of(order, given)


## Every screen, one taking another's place inside the tabs' panel.
func _screens() -> Desc:
	return ui.screen(&"content", [ui.stack([_about(), _readouts(), _navigation(), _sets(), _graph(), _matrix(), _detail()] + more.screens() + extra.screens() + [values.screen(), marks.screen(), arrivals.screen()])])


## One component shown: its name, what to try - if there is anything - and
## the thing itself on a ground.
func _shown(title: Variant, hint: Phrase, content: Desc) -> Desc:
	# the name, what to try when there is anything, and the thing taking the rest
	var lines: Array = [ui.text(title, Themes.TITLE)] + ([] if hint == null else [pieces.prose(hint, DemoTheme.READOUT)]) + [content.grow()]
	return ui.surface(Themes.RAISED, [ui.column(lines, DemoTheme.TIGHT)])


## The first screen: what this is and how the regions of the window relate.
func _about() -> Desc:
	var boxes := [
		[Phrase.of("What this is"), [Phrase.of("A gallery of the interface kit, one component at a time,"), Phrase.within("told as a market stall with crates of fruit."), Phrase.of("Every screen is a tab: a flap on the panel it opens."), Phrase.of("Every component sits in a box with its name and what to try.")]],
		[Phrase.of("The tabs"), [Phrase.of("One flap per screen, on the panel it reveals; the one you are on is joined to it."), Phrase.of("BACK returns to the screen you came from,"), Phrase.within("and the clock is a COUNTDOWN: time until the stall closes.")]],
		[Phrase.of("The instruction bar"), [Phrase.of("The INSTRUCTION BAR: its words say what to do next."), Phrase.of("Its two buttons are the actions you can take now."), Phrase.of("The glowing one is the one the guide means.")]],
		[Phrase.of("Try this"), [Phrase.of("Press start restocking: the bar asks for crates, 0 of 3, and a stop button appears."), Phrase.of("The glow moves to pick a crate, with a bubble pointing at it. Press it three times."), Phrase.of("A moment appears saying you are done; carry on dismisses it.")]],
		[Phrase.of("Words you will see"), [Phrase.of("A crate is one item on the stall. c is the coin."), Phrase.of("Takings is how much it has made. Recent is the last four days' takings."), Phrase.of("Marks is how many complaints it has had.")]],
	]
	var rows: Array = []
	for box: Array in boxes:
		var lines: Array = []
		for line: Phrase in box[1]:
			lines.append(ui.text(line, DemoTheme.READOUT))
		rows.append(_shown(box[0], null, ui.column(lines, DemoTheme.TIGHT)))
	var looks := pieces.looks()
	rows.append(_shown(Phrase.of("The look"), Phrase.of("The same gallery in each design language; press one"), ui.column([looks["worn"], ui.row(looks["picks"], Themes.TILES)], DemoTheme.TIGHT)))
	# more than a window's worth on a small screen: it scrolls rather than spilling over the bar at the foot
	return ui.screen(ABOUT, [ui.scroll(ui.column(rows))])


func _readouts() -> Desc:
	var read := pieces.readouts()
	var left := ui.column([_shown(Phrase.of("Quantity"), Phrase.of("The pear crate's takings"), read["quantity"]).grow(), _shown(Phrase.of("Bar"), Phrase.of("The same, as a fill; full is 100,000"), read["bar"]).grow(), _shown(Phrase.of("Label"), Phrase.of("The crate's name, read live"), read["label"]).grow(), _shown(Phrase.of("Mark"), Phrase.of("Complaints, a diamond each; pear has none"), read["mark"]).grow()])
	var right := ui.column([_shown(Phrase.of("Trace"), Phrase.of("The last four days' takings"), read["trace"]).grow(), _shown(Phrase.of("Relative"), Phrase.of("Closeness to another crate; press to compare"), read["relative"]).grow(), _shown(Phrase.of("Countdown"), Phrase.of("The clock BACK stands with"), ui.text(Phrase.of("Time until the stall closes"), DemoTheme.READOUT)).grow()])
	# on a window on its end the two columns are one over the other, each box about as tall as the next
	return ui.screen(READOUTS, [ui.by_shape({&"left": left, &"right": right}, {Shape.LANDSCAPE: _arranged(false, [&"left", &"right"], {&"left": {"grow": 1.0}, &"right": {"grow": 1.0}}), Shape.PORTRAIT: _arranged(true, [&"left", &"right"], {&"left": {"grow": 4.0}, &"right": {"grow": 3.0}})})])


func _navigation() -> Desc:
	var ways := pieces.navigation()
	var cards := pieces.cards()
	var acting := pieces.acting()
	var controls := _fours([_shown(Phrase.of("Menu link"), Phrase.of("A button to a screen"), ways["menu"]), _shown(Phrase.of("Inline link"), Phrase.of("A name; press to open it"), ways["inline"]), _shown(Phrase.of("Back"), Phrase.of("The screen you came from"), ways["back"]), _shown(Phrase.of("Play"), Phrase.of("Opens your own crate, the fig"), ways["play"])])
	var shown_cards := _fours([_shown(Phrase.of("Card, list"), Phrase.of("A crate as a row; press to open"), cards["list"]), _shown(Phrase.of("Card, tile"), Phrase.of("The same crate as a tile"), cards["tile"]), _shown(Phrase.of("Card, dense"), Phrase.of("Live picture, takings, a button"), cards["dense"]), _shown(Phrase.of("Card, empty"), Phrase.of("An empty slot and the ways to fill it"), cards["empty"])])
	var doing := ui.row([_shown(Phrase.of("Amount field"), Phrase.of("Type a number, Enter sets the price"), acting["amount"]).grow(), _shown(Phrase.of("Disposition"), Phrase.of("One of three; the chosen opens its second half"), acting["disposition"]).grow(2.0)])
	return ui.screen(NAVIGATION, [ui.column([controls.basis(0.2), shown_cards.basis(0.4), doing.basis(0.3)])])


## Four boxes of equal share along one row; on a window on its end, two
## rows of two.
func _fours(boxes: Array) -> Desc:
	var pairs := {&"first": ui.row([boxes[0].grow(), boxes[1].grow()]), &"second": ui.row([boxes[2].grow(), boxes[3].grow()])}
	# the two pairs along one row, halving it as the four quartered it; on a window on its end, one over the other
	return ui.by_shape(pairs, {Shape.LANDSCAPE: _arranged(false, [&"first", &"second"], {&"first": {"grow": 2.0}, &"second": {"grow": 2.0}}), Shape.PORTRAIT: _arranged(true, [&"first", &"second"], {&"first": {"grow": 1.0}, &"second": {"grow": 1.0}})})


func _sets() -> Desc:
	var lists := pieces.lists()
	var left := _shown(Phrase.of("Collection, rows"), Phrase.of("Add, sort, filter; press a row to open it"), lists["rows"])
	var right := ui.column([_shown(Phrase.of("Collection, tiles"), Phrase.of("The same crates as tiles"), lists["tiles"]).grow(), _shown(Phrase.of("Board"), Phrase.of("Ranked by takings; scrolled to keep your fig in view"), lists["board"]).grow()])
	# the rows beside the tiles and the board; on a window on its end, over them
	return ui.screen(SETS, [ui.by_shape({&"rows": left, &"others": right}, {Shape.LANDSCAPE: _arranged(false, [&"rows", &"others"], {&"rows": {"grow": 1.0}, &"others": {"grow": 1.0}}), Shape.PORTRAIT: _arranged(true, [&"rows", &"others"], {&"rows": {"grow": 1.0}, &"others": {"grow": 1.0}})})])


func _matrix() -> Desc:
	return ui.screen(MATRIX, [_shown(Phrase.of("Matrix"), Phrase.of("The gap in takings between each pair, in thousands; one triangle since a gap has no direction"), pieces.matrix(Phrase.of("Gap, thousands")))])


func _graph() -> Desc:
	var graph := pieces.graph()
	return ui.screen(GRAPH, [_shown(Phrase.of("Relationship graph"), Phrase.of("Who deals with whom; thicker is stronger. Drag, wheel, press a name"), ui.column([graph["graph"].grow(), graph["picked"].basis(0.08)]))])


## The detail of one thing, with a note kept with this entry: go elsewhere
## and come Back, and it is as it was; open another crate, and it is fresh.
func _detail() -> Desc:
	var note := pieces.note()
	var writing := _shown(Phrase.of("A note kept with this crate"), Phrase.of("Type a note and Enter, tick flags, go to suppliers, come back: still here"), ui.column([note["field"], note["words"], ui.row(note["flags"])], DemoTheme.TIGHT))
	# the detour goes to a screen not walked yet, and Back finds this note where it was left
	var ways := ui.row([note["back"], note["detour"]])
	# the crate's name on a ground of its own: on the panel behind it, it is read against whatever a look makes that panel
	return ui.screen(DETAIL, [ui.column([ui.surface(Themes.SURFACE, [note["title"]]), writing, ways.basis(0.06)])], null, {on_fill = drafts.begun})
