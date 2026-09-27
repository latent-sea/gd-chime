extends "res://demo/gallery/boxes.gd"

const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Motion := preload("res://addons/gd_chime/motion.gd")
const Language := preload("res://addons/gd_chime/language.gd")
const Sounds := preload("res://addons/gd_chime/sounds.gd")
const Inputs := preload("res://addons/gd_chime/input_map.gd")
const NavControl := preload("res://addons/gd_chime/components/recipes/nav_control.gd")
const CellReadout := preload("res://addons/gd_chime/components/recipes/cell_readout.gd")
const Countdown := preload("res://addons/gd_chime/components/recipes/countdown.gd")
const Attention := preload("res://addons/gd_chime/components/recipes/attention.gd")
const Setting := preload("res://addons/gd_chime/components/recipes/setting.gd")
const Extra := preload("res://demo/gallery/extra_models.gd")

## The gallery's own three screens, which no other stall shows: MOTION -
## every way the kit moves, with reduced motion switched where they are
## seen; OPTIONS - the language, the sound and the keys, as a settings
## screen; CARRYING - a crate picked up and dropped, by mouse and by pad.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## They are the gallery's and not the stall's, so the ten other stalls never
## have to arrange them: the gallery adds their flaps and their places to
## what it hands the stall (gallery.gd). Each is its boxes in
## two columns on a wide window and one column on a window on its end
## (by_shape.gd), scrolling where they are taller than the room (boxes.gd):
## in one column on a window on its end, a roomy look makes a screen taller
## than the window, and it scrolls rather than pushing the instruction bar at
## the foot off it. Words cut at an edge the scroll can still move toward are
## brought in by it; words cut where it cannot are cut, and the probe says
## so (clipped_text.gd). No words here say where anything stands: a
## layout that turns would make them wrong.
##
## The pop-up is the language choice's, travelling on it as every
## overlay is (more_pieces.gd). The volume is a slider, over the sounds' own
## volume, set through the door.

## The places: the three screens, and the two places a push goes between.
const MOTION := &"motion"
const OPTIONS := &"options"
const CARRYING := &"carrying"
const FRONT := &"front_of_the_stall"
const BACK_ROOM := &"back_room"
## The actions that show the places, and the one that opens the pop-up.
const SHOWS_MOTION := &"shows_the_motion"
const SHOWS_OPTIONS := &"shows_the_options"
const SHOWS_CARRYING := &"shows_the_carrying"
const SHOWS_FRONT := &"shows_the_front_of_the_stall"
const SHOWS_BACK_ROOM := &"shows_the_back_room"
const OPENS_LANGUAGES := &"opens_the_languages"

var _screens: Array = []


func _init(stall: SceneTree) -> void:
	super(stall)
	_screens = [_motion(), _options(), _carrying()]


## The three screens, to stand in the gallery's stack with the rest.
func screens() -> Array:
	return _screens


## Every way the kit moves: reduced motion first, since everything with it
## follows it at once; the look's tokens and the one clock; a value eased; a
## style blended; a list entering, leaving and moving; a push between two
## places; and three tracks of keyframes.
func _motion() -> Desc:
	var ui: RefCounted = _stall.ui
	var shelf: Extra.Shelf = _stall.shelf
	var reduced: Desc = Setting.row(ui, Phrase.of("Reduced motion"), Phrase.of("On, nothing slides, grows or loops, and a fade is short"), Setting.toggle(ui, Motion.REDUCES, ui.bound(ui.motion.get_reduced)).named(&"reduces"))
	# the look's own numbers, read again whenever another look is worn
	var tokens: Bound = ui.bound(_stall._looks.get_current).map(func(_worn: Variant) -> Phrase: return Phrase.with("Quick %d ms, normal %d ms, slow %d ms; a stagger of %d ms, a beat of %d ms", [ui.motion.get_token(&"quick"), ui.motion.get_token(&"normal"), ui.motion.get_token(&"slow"), ui.motion.get_token(Motion.STAGGER), ui.motion.get_token(Motion.BEAT)]))
	# how many runs the one clock is stepping, read every tick
	var running: Bound = ui.every_frame(func() -> Phrase: return Phrase.counted("%d run on the one clock now", "%d runs on the one clock now", ui.motion.get_running()))
	var eased: Bound = ui.eased(ui.bound(shelf.get_fill))
	# the figure on its way, and the bar beside it as tall as its words
	var filling: Desc = ui.column([ui.row([ui.text(eased.map(func(fill: float) -> Phrase: return Phrase.with("%d per cent full", [roundi(fill)])), DemoTheme.READOUT).grow(), CellReadout.bar(ui, ui.bound(shelf.get_fill), 100.0).grow()]), ui.button(Extra.Shelf.FILLS)], DemoTheme.TIGHT)
	var ripe: Desc = Setting.row(ui, Phrase.of("Ripe"), Phrase.of("Its look blends to the other"), Setting.toggle(ui, Extra.Shelf.RIPENS, ui.bound(shelf.get_ripe)))
	var crate := func(one: Bound) -> Desc: return ui.surface(Themes.CARD, [ui.text(one.field("name"))])
	var listed: Desc = ui.each_across(ui.bound(shelf.get_crates), crate, func(one: Dictionary) -> int: return one["id"])
	var hints: Array = Extra.Shelf.KEYED.map(func(action: StringName) -> Bound: return ui.inputs.hint(action))
	var keys: Bound = Bound.all(hints, func(adds: Phrase, takes: Phrase, turns: Phrase) -> Phrase: return Phrase.with("Keys on this screen now: %s, %s and %s", [adds, takes, turns]))
	var buttons: Array = Extra.Shelf.KEYED.map(func(action: StringName) -> Desc: return ui.button(action).grow())
	var shelved: Desc = ui.column([listed, ui.row(buttons), ui.text(keys, DemoTheme.READOUT)], DemoTheme.TIGHT)
	var front: Desc = ui.screen(FRONT, [ui.column([ui.text(Phrase.of("The front of the stall"), DemoTheme.READOUT), NavControl.menu(ui, SHOWS_BACK_ROOM, BACK_ROOM)], DemoTheme.TIGHT)])
	var back_room: Desc = ui.screen(BACK_ROOM, [ui.column([ui.text(Phrase.of("The back room"), DemoTheme.READOUT), NavControl.menu(ui, SHOWS_FRONT, FRONT)], DemoTheme.TIGHT)])
	# the seconds to the next round ten, always within the look's last seconds that beat
	var beating: Bound = _stall._time.map(func(now: float) -> float: return 10.0 - fmod(now, 10.0))
	var tracks: Desc = ui.row([ui.pulse([ui.surface(Themes.CARD, [ui.text(Phrase.of("A pulse: look here"))])]).named(&"pulse").grow(), Attention.breathing(ui, [ui.surface(Themes.CARD, [ui.text(Phrase.of("A breathe: still waiting"))])]).named(&"breathe").grow(), Countdown.make(ui, beating).grow()])
	var first := [
		_shown(Phrase.of("Reduced motion"), Phrase.of("Switch it and watch everything on this screen follow"), reduced),
		_shown(Phrase.of("The look's motion"), Phrase.of("Every duration is the look's; everything runs on one clock"), ui.column([ui.text(tokens, DemoTheme.READOUT), ui.text(running, DemoTheme.READOUT)], DemoTheme.TIGHT)),
		_shown(Phrase.of("An eased value"), Phrase.of("Press fill: the number and the bar go there smoothly"), filling),
		_shown(Phrase.of("A change of style"), Phrase.of("Press it: on and off blend by the look's restyle easing"), ripe),
	]
	var second := [
		_shown(Phrase.of("Enter, exit and move"), Phrase.of("Put a crate on, take one off, turn the shelf round"), shelved),
		_shown(Phrase.of("A push between places"), Phrase.of("One place slides in as the other slides out"), ui.stack([front, back_room])),
		_shown(Phrase.of("Keyframes"), Phrase.of("A pulse, a breathe, and the countdown's beat in its last seconds"), tracks),
	]
	return _columns(MOTION, first, second)


## The language, the sound and the keys: a choice of language named in
## itself, the volume along a slider and a mute, and every key
## the shelf is pressed by, rebound, kept, read back and put back.
func _options() -> Desc:
	var ui: RefCounted = _stall.ui
	# every language there are words for, each named in its own words: data, never translated
	var names := {Language.SOURCE: "English", &"fr": "Français", Language.PSEUDO: TranslationServer.pseudolocalize("English")}
	var languages: Array = names.keys().map(func(language: StringName) -> Dictionary: return {"value": language, "words": names[language]})
	var language := Setting.choice(ui, Language.CHANGES_LANGUAGE, OPENS_LANGUAGES, {offers = Bound.new(func() -> Array: return languages), chosen = ui.bound(ui.language.get_language), title = Phrase.of("The language words are said in")})
	var volume: Desc = ui.slider(Sounds.SETS_VOLUME, ui.bound(_stall.sounds.get_volume), {minimum = 0.0, maximum = 1.0, step = 0.1}).named(&"volume").grow()
	var sound: Desc = ui.column([Setting.row(ui, Phrase.of("Volume"), Phrase.of("How loud the stall's sounds are: drag it, or left and right"), volume), Setting.row(ui, Phrase.of("Mute"), Phrase.of("On, nothing sounds at all"), Setting.toggle(ui, Sounds.MUTES_SOUND, ui.bound(_stall.sounds.get_muted)).named(&"mutes"))], DemoTheme.TIGHT)
	var rows: Array = []
	# every action a key presses, a binding that writes the map
	for action: StringName in Extra.Shelf.KEYED:
		rows.append(Setting.row(ui, ui.words(action), Phrase.of("Press it, then the key or button to bind"), Setting.binding(ui, Inputs.BINDS, ui.inputs.hint(action), {rebinds = action}).named(StringName("binds %s" % action))))
	var keeping: Desc = ui.row([ui.button(Extra.Keys.SAVES).grow(), ui.button(Extra.Keys.LOADS).grow(), ui.button(Inputs.RESTORES_DEFAULTS).grow()])
	var keys: Desc = ui.column(rows + [keeping, ui.text(ui.bound(_stall.keys.get_said), DemoTheme.READOUT)], DemoTheme.TIGHT)
	var first := [
		_shown(Phrase.of("Language"), Phrase.of("Choose one: every word on every screen follows at once"), Setting.row(ui, Phrase.of("Language"), Phrase.of("Each named in its own words"), language)),
		_shown(Phrase.of("Sound"), Phrase.of("The volume and the mute of the stall's own sounds"), sound),
	]
	var second := [_shown(Phrase.of("Keys"), Phrase.of("Rebind a key, save, restore the defaults, load: yours are back"), keys)]
	return _columns(OPTIONS, first, second)


## Crates on the counter to carry, and two baskets to carry them to - the
## fig basket refusing anything else, in words.
func _carrying() -> Desc:
	var ui: RefCounted = _stall.ui
	var baskets: Extra.Baskets = _stall.baskets
	# a crate as the thing carried: its id, read as it is lifted
	var crate := func(one: Bound) -> Desc: return ui.draggable(one.map(func(item: Variant) -> Dictionary: return {} if item == null else {"id": item["id"]}), [ui.text(one.field("name"))])
	var counter: Desc = ui.each_across(ui.bound(baskets.get_counter), crate, func(one: Dictionary) -> int: return one["id"])
	# what a basket holds, as the names of its crates: data
	var holding := func(held: Bound) -> Bound: return held.map(func(crates: Array) -> String: return ", ".join(crates.map(func(one: Dictionary) -> String: return one["name"])))
	var basket: Desc = ui.drop_target(Extra.Baskets.PUTS_IN, [ui.text(Phrase.of("The basket")), ui.text(holding.call(ui.bound(baskets.get_basket)), DemoTheme.READOUT), ui.reason()]).named(&"basket")
	var figs: Desc = ui.drop_target(Extra.Baskets.PUTS_IN_FIGS, [ui.text(Phrase.of("The fig basket")), ui.text(holding.call(ui.bound(baskets.get_figs)), DemoTheme.READOUT), ui.reason()]).named(&"fig basket")
	var carrying: Desc = ui.column([ui.text(Phrase.of("On the counter"), DemoTheme.READOUT), counter, ui.row([basket.grow(), figs.grow()]), ui.button(Extra.Baskets.EMPTIES)], DemoTheme.TIGHT)
	var mouse := _shown(Phrase.of("Drag and drop"), Phrase.of("Drag a crate onto a basket"), ui.column([ui.text(Phrase.of("The fig basket takes figs alone, and says why"), DemoTheme.READOUT), carrying], DemoTheme.TIGHT))
	var steps: Array = [Phrase.of("On a crate, accept lifts it"), Phrase.of("The arrows walk the baskets alone"), Phrase.of("Accept drops it; cancel puts it back"), Phrase.of("A refused drop takes nothing: the crate is still carried")]
	var pad := _shown(Phrase.of("By pad or keys"), Phrase.of("The same crates, carried without a mouse"), ui.column(steps.map(func(step: Phrase) -> Desc: return ui.text(step, DemoTheme.READOUT)), DemoTheme.TIGHT))
	return _columns(CARRYING, [mouse], [pad])
