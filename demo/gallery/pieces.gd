extends RefCounted

const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
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
const Matrix := preload("res://addons/gd_chime/components/recipes/matrix.gd")
const InstructionBar := preload("res://addons/gd_chime/components/recipes/instruction_bar.gd")
const Graph := preload("res://addons/gd_chime/components/recipes/relationship_graph.gd")
const Disposition := preload("res://addons/gd_chime/components/recipes/disposition.gd")
const Moment := preload("res://addons/gd_chime/components/recipes/moment.gd")
const Models := preload("res://demo/gallery/gallery_models.gd")
const Notes := preload("res://demo/gallery/drafts.gd")
const DemoTheme := preload("res://demo/demo_theme.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")

## The stall's pieces: every component the stall shows, built once here
## over the stall's models, for a demo to arrange. A demo asks for a piece
## by name and puts it where its design language would; no demo builds a
## component itself, so ten arrangements differ in placement alone.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Each function gives a description, or a dictionary of them by name for
## a family, in the order the placeholder shows them. A piece is made
## fresh on every call, so a demo may ask twice and place both.

var _stall: SceneTree  # the stall, for its models, its ui and its driver


func _init(stall: SceneTree) -> void:
	_stall = stall


## The flaps for every place of the stall over this content; the strip
## alone given none.
func tabs(content: Array = []) -> Desc:
	var flaps: Array = []
	for tab: Array in _stall.tabs():
		flaps.append({"action": tab[0], "goes_to": tab[1]})
	return Tabs.make(_stall.ui, flaps, content)


func back() -> Desc:
	return NavControl.back(_stall.ui, _stall.GOES_BACK)


## The time until the stall closes, counting down from a minute and a half.
func clock() -> Desc:
	return Countdown.make(_stall.ui, _stall._time.map(func(now: float) -> float: return 90.0 - fmod(now, 90.0)))


## The instruction bar, and the two actions of the act named start and step
## - the bubble points at step.
func instruction() -> Desc:
	return InstructionBar.make(_stall.ui, _stall.act, Models.Act.CANCELS)


func start() -> Desc:
	return _stall.ui.button(Models.Act.STARTS).named(&"start")


func step() -> Desc:
	return _stall.ui.button(Models.Act.TAKES_A_STEP).named(&"step")


func bubble() -> Desc:
	return Attention.bubble(_stall.ui, &"step", Models.Act.TAKES_A_STEP)


## Words kept to one line on a wide window, never narrower than the base
## the project is written at, and broken onto more at the width they are
## given on a window on its end, which one line of them can be wider than.
## Both are built at once and one is shown, so turning the window builds
## nothing.
func prose(words: Variant, style: StringName) -> Desc:
	var ui: RefCounted = _stall.ui
	# whether the window is on its end, read again each time it turns
	var turned: Bound = ui.shape.portrait
	# wrapping while it is on its end, one line otherwise, both kept built
	return ui.when(turned, ui.text(words, style).wraps(), ui.text(words, style)).keeps()


## The moment the act presents when done, with these words under its title.
func moment(words: Phrase = Phrase.of("Carry on dismisses this moment")) -> Desc:
	return Moment.make(_stall.ui, Bound.new(_stall.act.get_presented), [_stall.ui.text(Phrase.of("Restocked: three crates picked."), Themes.TITLE), prose(words, DemoTheme.READOUT)], Models.Act.CARRIES_ON)


## Every look by name, a press wearing it; and with the one worn said, the
## sight it is dressed for - plain, or one of three eyes - a press each.
func looks() -> Dictionary:
	var picks: Array = []
	for named: StringName in _stall.Looks.NAMES:
		picks.append(_stall.ui.pressable(_stall.Looks.PICKS, {"look": named}, [_stall.ui.text(String(named).replace("_", " "), Themes.FACE)]))
	var sights: Array = [_stall.ui.text(Bound.new(_stall._sight.get_sight).map(func(named: Variant) -> Phrase: return Phrase.with("Seeing: %s", [named])), DemoTheme.READOUT)]
	# every sight, a press dressing the look now worn for that eye
	for named: StringName in _stall.Sight.NAMES:
		sights.append(_stall.ui.pressable(_stall.Sight.PICKS, {"sight": named}, [_stall.ui.text(String(named), Themes.FACE)]))
	var wearing: Desc = _stall.ui.text(Bound.new(_stall._looks.get_current).map(func(named: Variant) -> Phrase: return Phrase.with("Wearing: %s", [named])), DemoTheme.READOUT)
	return {"picks": picks, "worn": _stall.ui.column([wearing, _stall.ui.row(sights, Themes.TILES)], DemoTheme.TIGHT)}


## The six cell readouts over the first crate: quantity, bar, label, trace,
## mark, relative.
func readouts(crate: Bound = Bound.new(_stall.things.get_things).field(0)) -> Dictionary:
	var ui: RefCounted = _stall.ui
	var closeness: Bound = crate.field("won").map(func(won: Variant) -> float: return 0.0 if won == null else float(won) / 20000.0)
	return {"quantity": CellReadout.quantity(ui, crate.field("won"), "c"), "bar": CellReadout.bar(ui, crate.field("won"), 100000.0), "label": CellReadout.label(ui, crate.field("name")), "trace": CellReadout.trace(ui, crate.field("recent")), "mark": CellReadout.mark(ui, crate.field("marks"), &"diamond"), "relative": CellReadout.relative(ui, Models.Things.COMPARES, closeness, Phrase.of("Closeness"))}


## The four navigation controls: menu, inline, back, play.
func navigation() -> Dictionary:
	var ui: RefCounted = _stall.ui
	var crate: Bound = ui.bound(_stall.things.get_things).field(1)
	return {"menu": NavControl.menu(ui, _stall.SHOWS_SETS, _stall.SETS), "inline": NavControl.inline(ui, Models.Things.OPENS, crate, {goes_to = _stall.DETAIL}), "back": back(), "play": NavControl.play(ui, Models.Things.OPENS, ui.bound(_stall.things.get_own), _stall.DETAIL)}


## The four cards over the second crate: list, tile, dense, empty.
func cards() -> Dictionary:
	var ui: RefCounted = _stall.ui
	var crate: Bound = ui.bound(_stall.things.get_things).field(1)
	var reserved: Bound = ui.bound(_stall.item.get_chosen).map(func(chosen: Variant) -> Variant: return null if chosen == null else Phrase.with("A %s", [String(chosen).split("_")[0]]))
	return {
		"list": Card.list(ui, Models.Things.OPENS, crate, [ui.text(crate.field("name")), CellReadout.quantity(ui, crate.field("won"), "c")], {goes_to = _stall.DETAIL}),
		"tile": Card.tile(ui, Models.Things.OPENS, crate, [ui.text(crate.field("name")), CellReadout.trace(ui, crate.field("recent")), Card.more(ui, ui.text(crate.field("won").map(func(won: Variant) -> Phrase: return Phrase.with("Sold %s so far this week", [won])), Themes.REASON))], {goes_to = _stall.DETAIL}),
		"dense": Card.dense(ui, Models.Things.OPENS, crate, [CellReadout.quantity(ui, crate.field("won"), "c")], {goes_to = _stall.DETAIL, view = ui.surface(Themes.CARD, [ui.text(Phrase.of("Live view"))]), controls = [ui.button(Models.Item.ENTERS)]}),
		"empty": Card.empty(ui, [ui.button(Models.Item.ENTERS)], reserved),
	}


## The amount field and the disposition.
func acting() -> Dictionary:
	var ui: RefCounted = _stall.ui
	return {"amount": AmountField.make(ui, Models.Item.SETS_PRICE, "c"), "disposition": Disposition.make(ui, _stall.item, {Models.Item.ENTERS: ui.text(Phrase.of("Which stall: the corner one")), Models.Item.LISTS: AmountField.make(ui, Models.Item.SETS_PRICE, "c"), Models.Item.RELEASES: null})}


## The collection as rows with its controls and filter-set, as tiles, and
## the board keeping the reader's own crate in view.
func lists() -> Dictionary:
	var ui: RefCounted = _stall.ui
	var key := func(crate: Dictionary) -> int: return crate["id"]
	var row := func(crate: Bound) -> Desc: return Card.list(ui, Models.Things.OPENS, crate, [ui.text(crate.field("name")), CellReadout.quantity(ui, crate.field("won"), "c"), CellReadout.mark(ui, crate.field("marks"))], {goes_to = _stall.DETAIL})
	var tile := func(crate: Bound) -> Desc: return Card.tile(ui, Models.Things.OPENS, crate, [ui.text(crate.field("name"))], {goes_to = _stall.DETAIL}).basis(0.3)
	var crates: Bound = ui.bound(_stall.things.get_things)
	return {
		"rows": Collection.make(ui, crates, row, {key = key, shape = Collection.ROWS, controls = [ui.button(Models.Things.ADDS), ui.button(Models.Things.SORTS)], filters = FilterSet.make(ui, _stall.filters, _stall.FILTER_ACTIONS)}),
		"tiles": Collection.make(ui, crates, tile, {key = key, shape = Collection.TILES}),
		"board": Board.make(ui, crates, func(crate: Bound) -> Desc: return ui.row([ui.text(crate.field("name")), CellReadout.quantity(ui, crate.field("won"), "c")]), {key = key, own = ui.bound(_stall.things.get_own)}),
	}


## The crates against themselves: the gap in takings, in thousands, one triangle.
func matrix(corner: Phrase = Phrase.of("Crate vs crate")) -> Desc:
	var ui: RefCounted = _stall.ui
	var key := func(crate: Dictionary) -> int: return crate["id"]
	var crates: Bound = ui.bound(_stall.things.get_things)
	var cell := func(a: Bound, b: Bound) -> Desc: return ui.text(a.map(func(one: Variant) -> String: return "" if one == null or b.read() == null else str(absi(one["won"] - b.read()["won"]) / 1000)))
	var label := func(crate: Bound) -> Desc: return NavControl.inline(ui, Models.Things.OPENS, crate, {goes_to = _stall.DETAIL})
	return Matrix.make(ui, crates, crates, {cell = cell, row_label = label, column_label = label, key = key, corner = ui.text(corner), symmetric = true})


## The suppliers' graph, and the line saying who was picked - in the kind
## of words the stall asks for, since a stall that pins the graph to cork
## reads that line on cork and not on a page (demo/stalls/skeuomorphic.gd).
func graph(said: StringName = DemoTheme.READOUT) -> Dictionary:
	var ui: RefCounted = _stall.ui
	return {"graph": Graph.make(ui, _stall.family, _stall.GRAPH_ACTIONS, _stall.DETAIL), "picked": ui.text(ui.bound(_stall.family.get_picked).map(func(who: Variant) -> Phrase: return Phrase.of("No supplier picked yet") if who == null else Phrase.with("Picked supplier: %s", [who])), said)}


## The detail's note: the field, the words so far, the three flags, and the
## ways on - back, and the detour to the graph.
func note() -> Dictionary:
	var ui: RefCounted = _stall.ui
	var draft: Bound = ui.bound(_stall.drafts.get_draft)
	var flags: Array = []
	for flag: String in Notes.Drafts.FLAG_WORDS:
		var ticked: Bound = draft.map(func(one: Variant) -> Variant: return null if one == null else Phrase.joined(["[x] " if one.flags.has(flag) else "[ ] ", Phrase.of(Notes.Drafts.FLAG_WORDS[flag])]))
		flags.append(ui.pressable(Notes.Drafts.TICKS, {"flag": flag}, [ui.text(ticked, Themes.FACE)]))
	return {"title": ui.text(_stall.picked_words(), Themes.TITLE), "field": ui.field(Notes.Drafts.WRITES, &"Field"), "words": ui.text(draft.map(func(one: Variant) -> Variant: return null if one == null else Phrase.with("Note so far: %s", [one.words])), DemoTheme.READOUT), "flags": flags, "back": back(), "detour": NavControl.menu(ui, _stall.SHOWS_GRAPH, _stall.GRAPH)}
