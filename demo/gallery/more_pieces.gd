extends RefCounted

const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const NavControl := preload("res://addons/gd_chime/components/recipes/nav_control.gd")
const CellReadout := preload("res://addons/gd_chime/components/recipes/cell_readout.gd")
const Setting := preload("res://addons/gd_chime/components/recipes/setting.gd")
const TypeAhead := preload("res://addons/gd_chime/components/recipes/type_ahead.gd")
const Table := preload("res://addons/gd_chime/components/recipes/table.gd")
const Sections := preload("res://addons/gd_chime/components/recipes/sections.gd")
const Confirm := preload("res://addons/gd_chime/components/recipes/confirm.gd")
const TextField := preload("res://addons/gd_chime/components/recipes/text_field.gd")
const Bracket := preload("res://addons/gd_chime/components/recipes/bracket.gd")
const LineChart := preload("res://addons/gd_chime/components/recipes/line_chart.gd")
const More := preload("res://demo/gallery/more_models.gd")
const DemoTheme := preload("res://demo/demo_theme.gd")
const Shape := preload("res://addons/gd_chime/shape.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")

## The stall's second family of pieces - settings, a picker, a table,
## sections, a confirm, a named field, a bracket and a chart - and the four
## screens that show them, the same in every stall, each piece in a
## captioned box, so a look is seen on every one of them. The ledger's
## table stands beside its other two boxes on a wide window and over them,
## side by side, on a window on its end (by_shape.gd); each other screen is
## one box. What to try in every box breaks onto more lines on its end.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Three of them open an overlay - the choice of a pace, the question
## before the day is cleared, and the one question every kept day's delete
## shares - each travelling on the press opening it, lifted over the app by
## the builder.

## The two questions, for the stall's probe to raise.
var clearing: Desc
var dropping: Desc
var _stall: SceneTree
var _screens: Array = []


func _init(stall: SceneTree) -> void:
	_stall = stall
	_screens = [_settings(), ledger(), knockout(), takings()]


## The four screens, to stand in the stall's stack with the rest.
func screens() -> Array:
	return _screens


## One piece shown: its name, what to try - one line on a wide window and
## broken onto more on one on its end (pieces.gd) - and the thing itself on
## a ground.
func _shown(title: Phrase, hint: Phrase, content: Desc) -> Desc:
	var ui: RefCounted = _stall.ui
	return ui.surface(Themes.RAISED, [ui.column([ui.text(title, Themes.TITLE), _stall.pieces.prose(hint, DemoTheme.READOUT), content.grow()], DemoTheme.TIGHT)])


## The settings: rows in two groups - a toggle, a choice that opens an
## overlay, a binding, a named field - and the confirm before a day is cleared.
func _settings() -> Desc:
	var ui: RefCounted = _stall.ui
	var prefs: More.Prefs = _stall.prefs
	var pace := Setting.choice(ui, More.Prefs.PICKS_PACE, More.Prefs.OPENS_PACES, {offers = ui.bound(prefs.get_paces), chosen = ui.bound(prefs.get_pace), title = Phrase.of("How fast the day runs")})
	clearing = Confirm.make(ui, Phrase.of("The day's takings will be thrown away. This cannot be undone."), More.Prefs.CLEARS_DAY)
	# one question serves every kept day: each row's button opens it as that row
	var kept: More.Kept = _stall.kept
	dropping = Confirm.make(ui, func(day: Bound) -> Bound: return day.map(func(id: Variant) -> Variant: return null if id == null else Phrase.with("Throw away the day called %s? This cannot be undone.", [kept.name_of(id)])), More.Kept.DROPS)
	var day_row := func(day: Bound) -> Desc: return ui.row([ui.text(day.field("name"), Themes.FACE).grow(), ui.button(More.Kept.ASKS_TO_DROP, {opens = dropping, with = day.field("id")})], &"SettingRow")
	var groups := [
		{"heading": Phrase.of("The stall"), "content": [
			Setting.row(ui, Phrase.of("Sound"), Phrase.of("The bell when a crate sells"), Setting.toggle(ui, More.Prefs.TURNS_SOUND, ui.bound(prefs.get_sound))),
			Setting.row(ui, Phrase.of("Pace"), Phrase.of("Opens a list to choose from, never a dropdown"), pace),
			Setting.row(ui, Phrase.of("Call key"), Phrase.of("Press it, then press the key or button to bind"), Setting.binding(ui, More.Prefs.BINDS_CALL, ui.bound(prefs.get_call_key))),
		]},
		{"heading": Phrase.of("The day"), "content": [
			TextField.make(ui, More.Prefs.NAMES_STALL, Phrase.of("The stall's name"), {holds = ui.bound(prefs.get_title), says = Phrase.of("Type a name and press Enter; an empty name is refused"), refusal = ui.bound(prefs.get_refusal)}),
			Setting.row(ui, Phrase.of("Clear the day"), Phrase.of("Asks first: it cannot be undone"), ui.button(More.Prefs.ASKS_TO_CLEAR, {opens = clearing})),
			ui.text(ui.bound(prefs.get_day), DemoTheme.READOUT),
		]},
		{"heading": Phrase.of("Days kept"), "content": [ui.each(ui.bound(kept.get_days), day_row, func(day: Dictionary) -> int: return day["id"])]},
	]
	return ui.screen(_stall.SETTINGS, [_shown(Phrase.of("Settings"), Phrase.of("Rows in groups: a toggle, a choice, a binding, a named field, a confirm"), Sections.static_groups(ui, groups))])


## The ledger: the crates as a sortable table, in sections, and a type-ahead picker.
func ledger() -> Desc:
	var ui: RefCounted = _stall.ui
	var ledger: More.Ledger = _stall.ledger
	var key := func(crate: Dictionary) -> int: return crate["id"]
	# takings over five thousand are marked in words and weight, never by colour alone
	var good := func(value: Variant) -> Dictionary: return {"mark": " +", "kind": Themes.FACE} if value != null and value > 5000 else {"mark": "", "kind": Themes.REASON}
	var columns := [{"name": "name", "words": Phrase.of("Crate"), "share": 2.0}, {"name": "won", "words": Phrase.of("Takings"), "share": 1.0, "format": good}, {"name": "marks", "words": Phrase.of("Complaints"), "share": 1.0}]
	var table := Table.make(ui, ui.bound(ledger.get_rows), columns, {key = key, sorts = More.Ledger.SORTS, sort = ui.bound(ledger.get_sort)})
	var grouped := Sections.make(ui, ui.bound(ledger.get_sections), func(crate: Bound) -> Desc: return ui.text(crate.field("name")), {key = key})
	var picker: Desc = ui.column([TypeAhead.make(ui, ledger.narrowing, More.Ledger.NARROWS_CRATES, More.Ledger.PICKS_CRATE).grow(), ui.text(ui.bound(ledger.get_picked), DemoTheme.READOUT)])
	# the sections and the picker, each in its box
	var two := {&"sections": _shown(Phrase.of("Sections"), Phrase.of("The same crates, grouped by complaints"), grouped), &"picker": _shown(Phrase.of("Type-ahead picker"), Phrase.of("Type to narrow, arrows to move, press to pick"), picker)}
	var halves := {&"sections": {"grow": 1.0}, &"picker": {"grow": 1.0}}
	# the sections over the picker on a wide window; on one on its end, the two side by side under the table
	var beside: Desc = ui.by_shape(two, {Shape.LANDSCAPE: ui.column_of(two.keys(), halves), Shape.PORTRAIT: ui.row_of(two.keys(), halves)})
	# the table in its box, and the other two to go with it
	var parts := {&"table": _shown(Phrase.of("Table"), Phrase.of("Press a heading to sort; + marks takings over 5,000"), table), &"beside": beside}
	# on a wide window the table beside the other two, twice as wide as they are
	var across: Dictionary = ui.row_of([&"table", &"beside"], {&"table": {"grow": 2.0}, &"beside": {"grow": 1.0}})
	# on a window on its end the table over them, the two halves of the room left
	var down: Dictionary = ui.column_of([&"table", &"beside"], {&"table": {"grow": 1.0}, &"beside": {"grow": 1.0}})
	return ui.screen(_stall.LEDGER, [ui.by_shape(parts, {Shape.LANDSCAPE: across, Shape.PORTRAIT: down})])


func knockout() -> Desc:
	var ui: RefCounted = _stall.ui
	var bracket := Bracket.make(ui, ui.bound(_stall.knockout.get_rounds), _stall.Models.Things.OPENS, {goes_to = _stall.DETAIL})
	return ui.screen(_stall.KNOCKOUT, [_shown(Phrase.of("Bracket"), Phrase.of("Ties across rounds; a name opens that crate; the winner is marked in words"), ui.column([bracket.grow(), ui.button(More.Knockout.DECIDES)]))])


func takings() -> Desc:
	var ui: RefCounted = _stall.ui
	return ui.screen(_stall.TAKINGS, [_shown(Phrase.of("Line chart"), Phrase.of("Two series told apart by dash and marker; add a day and it extends"), ui.column([LineChart.make(ui, ui.bound(_stall.takings.get_chart)).grow(), ui.button(More.Takings.ADDS_DAY)]))])
