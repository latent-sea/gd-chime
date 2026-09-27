extends RefCounted
const Actions := preload("res://addons/gd_chime/actions.gd")

const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Motion := preload("res://addons/gd_chime/motion.gd")
const Language := preload("res://addons/gd_chime/language.gd")
const Sounds := preload("res://addons/gd_chime/sounds.gd")
const Inputs := preload("res://addons/gd_chime/input_map.gd")
const Extra := preload("res://demo/gallery/extra_models.gd")
const ExtraPieces := preload("res://demo/gallery/extra_pieces.gd")
const Carried := preload("res://addons/gd_chime/carried.gd")
const Draggable := preload("res://addons/gd_chime/components/primitives/draggable.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Hands := preload("res://tests/hands.gd")

## The gallery's own three screens walked and reported, as the stall's probe
## (probe.gd) walks what every stall does: run by the gallery started with
## --probe, once the rest is walked and before every place is looked at.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Motion: the pulse and the breathe on their way, then reduced motion
## switched on by its own toggle - both at rest at once - and off again,
## moving again; a value eased - on its way a quarter into the look's own
## easing, on the clock held by hand, since a look may ease in less time
## than any fixed step, and off both ends rather than between them, since a
## look's curve may overshoot - then there, and at once while reduced;
## a crate put on, the shelf turned round and one taken off, the pieces
## standing in that order; a push between two places, both on the move and
## then one. Options: French chosen through its pop-up and every word
## following, then the pseudo-locale, then English; the volume's slider
## stepped down by the keyboard's arrow and the pad's d-pad, its words
## following, and the mute turned on and off; a key bound through the
## binding, saved, the defaults restored, loaded - the key back - and
## pressed as a shortcut. Carrying: a crate lifted by the pad, walked to a
## basket that takes it and to one that refuses it, refused there and
## dropped on the other; one dropped by the mouse, one the mouse's target
## refuses, and one put back by cancel with the focus home. Every key goes
## in at the window through the shared hands (tests/hands.gd), as a person presses it.
##
## EVERYTHING IS PUT BACK AS IT WAS - English, full volume, motion not
## reduced and its clock running, the default keys, the baskets empty -
## since the stall's probe looks at every place after this, and judges what is there.

var _stall: SceneTree
var _hands: Hands
var _said: Dictionary = {}


func _init(stall: SceneTree) -> void:
	_stall = stall
	_hands = Hands.new(stall)


## Every claim, walked in turn and handed back by name.
func run() -> Dictionary:
	await _motion()
	await _options()
	await _carrying()
	return _said


func _go(place: StringName, parameter: Variant = null) -> void:
	_stall.commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": place, "parameter": parameter})


func _frames(count: int = 3) -> void:
	# frames enough for a move to be laid out and a press to be drawn
	for waited: int in count:
		await _stall.process_frame


## Every set of words drawn in this place, in the order they stand across and down.
func _texts(place: StringName) -> Array:
	var drawn: Array = _hands.place(place).find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Text and (part as Control).is_visible_in_tree())
	drawn.sort_custom(func(a: Control, b: Control) -> bool: return a.global_position.x < b.global_position.x if a.global_position.y == b.global_position.y else a.global_position.y < b.global_position.y)
	return drawn.map(func(part: Text) -> String: return part.get_text())


func _motion() -> void:
	var ui: RefCounted = _stall.ui
	var motion: Motion = ui.motion
	_go(ExtraPieces.MOTION)
	await _frames()
	var pulse: Control = ui.node_named(&"pulse")
	var breathe: Control = ui.node_named(&"breathe")
	motion.step(0.3)
	var moving: bool = pulse.modulate.a < 1.0 and breathe.scale.x > 1.0
	ui.node_named(&"reduces").pressed()
	await _frames()
	var rested: bool = motion.get_reduced()
	# a moment at a time across a whole period: at rest at every one of them, never passing through
	for moment: int in 12:
		motion.step(0.1)
		rested = rested and pulse.modulate.a == 1.0 and breathe.scale == Vector2.ONE
	ui.node_named(&"reduces").pressed()
	await _frames()
	motion.step(0.3)
	_said["reduced_live"] = moving and rested and not motion.get_reduced() and pulse.modulate.a < 1.0 and breathe.scale.x > 1.0
	# the figure the eased value shows, read off its words
	var figure := func() -> int: return _texts(ExtraPieces.MOTION).filter(func(words: String) -> bool: return words.contains("per cent"))[0].to_int()
	# the clock held by hand while the value goes, so a quarter of the look's own easing finds it on its way in every look
	motion.by_hand = true
	_stall.commands.dispatch(Chimes.GLOBAL, Extra.Shelf.FILLS, {})
	await _frames(1)
	motion.step(motion.lasts(Motion.MOVE) / 4.0)
	await _frames(1)
	var between: int = figure.call()
	motion.step(2.0)
	await _frames(1)
	var there: int = figure.call()
	motion.by_hand = false
	_stall.commands.dispatch(Chimes.GLOBAL, Motion.REDUCES, {"on": true})
	_stall.commands.dispatch(Chimes.GLOBAL, Extra.Shelf.FILLS, {})
	await _frames(2)
	_said["eased"] = between != Extra.Shelf.LOW and between != Extra.Shelf.HIGH and there == Extra.Shelf.HIGH and figure.call() == Extra.Shelf.LOW
	_stall.commands.dispatch(Chimes.GLOBAL, Motion.REDUCES, {"on": false})
	# the crates on the shelf, as they stand in a row
	var shelved := func() -> Array: return _texts(ExtraPieces.MOTION).filter(func(words: String) -> bool: return Extra.Shelf.NAMES.has(words))
	var orders: Array = []
	# a crate put on, the shelf turned round, one taken off: each seen once everything on its way has arrived
	for action: StringName in [Extra.Shelf.PUTS_ON_SHELF, Extra.Shelf.TURNS, Extra.Shelf.TAKES]:
		_stall.commands.dispatch(Chimes.GLOBAL, action, {})
		await _frames()
		motion.step(2.0)
		await _frames()
		orders.append(shelved.call())
	_said["listed"] = orders == [["pear", "apple", "fig", "date"], ["date", "fig", "apple", "pear"], ["fig", "apple", "pear"]]
	var front: Control = _hands.place(ExtraPieces.FRONT)
	_stall.commands.dispatch(ExtraPieces.FRONT, ExtraPieces.SHOWS_BACK_ROOM, {})
	await _frames(1)
	var both: bool = _stall.driver.get_top().has(ExtraPieces.BACK_ROOM) and front.visible and motion.get_running() > 0
	motion.step(2.0)
	await _frames()
	_said["pushed"] = both and not front.visible and _hands.place(ExtraPieces.BACK_ROOM).visible


func _options() -> void:
	var ui: RefCounted = _stall.ui
	var sounds: Sounds = _stall.sounds
	_go(ExtraPieces.OPTIONS)
	await _frames()
	_go(_stall.driver.goes_to(ExtraPieces.OPTIONS, ExtraPieces.OPENS_LANGUAGES))
	await _frames()
	_stall.commands.dispatch(_stall.driver.goes_to(ExtraPieces.OPTIONS, ExtraPieces.OPENS_LANGUAGES), Language.CHANGES_LANGUAGE, {"value": &"fr"})
	await _frames()
	var french: Array = _texts(ExtraPieces.OPTIONS)
	_stall.commands.dispatch(Chimes.GLOBAL, Language.CHANGES_LANGUAGE, {"value": Language.PSEUDO})
	await _frames()
	var pseudo: Array = _texts(ExtraPieces.OPTIONS)
	_stall.commands.dispatch(Chimes.GLOBAL, Language.CHANGES_LANGUAGE, {"value": Language.SOURCE})
	await _frames()
	_said["language_followed"] = french.has("Langue") and french.has("Français") and not french.has("Language") and not _stall.driver.is_raised() and pseudo.has(TranslationServer.pseudolocalize("Language")) and _texts(ExtraPieces.OPTIONS).has("Language")
	ui.node_named(&"volume").grab_focus()
	# the keyboard's left three times, a tenth down each
	for step: int in 3:
		await _hands.key(KEY_LEFT)
	await _hands.pad(JOY_BUTTON_DPAD_LEFT)
	await _hands.pad(JOY_BUTTON_DPAD_LEFT)
	var halved: bool = is_equal_approx(sounds.get_volume(), 0.5) and _texts(ExtraPieces.OPTIONS).has("0.5")
	ui.node_named(&"mutes").pressed()
	await _frames()
	var muted: bool = sounds.get_muted()
	ui.node_named(&"mutes").pressed()
	_stall.commands.dispatch(Chimes.GLOBAL, Sounds.SETS_VOLUME, {"value": 1.0})
	_said["volume_and_mute"] = halved and muted and not sounds.get_muted()
	await keys()


## A key bound through the binding, saved, the defaults restored and the save
## loaded, and the key it was bound to pressed as the shortcut it now is.
func keys() -> void:
	var inputs: Inputs = _stall.inputs
	var adds := Extra.Shelf.PUTS_ON_SHELF
	_stall.ui.node_named(StringName("binds %s" % adds)).pressed()
	await _hands.key(KEY_M)
	var bound: bool = inputs.get_inputs(adds).has(Actions.keys(KEY_M))
	_stall.commands.dispatch(Chimes.GLOBAL, Extra.Keys.SAVES, {})
	_stall.commands.dispatch(Chimes.GLOBAL, Inputs.RESTORES_DEFAULTS, {})
	var restored: bool = inputs.get_inputs(adds).has(Actions.keys(KEY_N))
	_stall.commands.dispatch(Chimes.GLOBAL, Extra.Keys.LOADS, {})
	var loaded: bool = inputs.get_inputs(adds).has(Actions.keys(KEY_M)) and _stall.keys.get_said() != null and str(_stall.keys.get_said()) == "The saved keys are loaded"
	_go(ExtraPieces.MOTION)
	await _frames()
	var before: int = _stall.shelf.get_crates().size()
	await _hands.key(KEY_M)
	var pressed: bool = _stall.shelf.get_crates().size() == before + 1
	_stall.commands.dispatch(Chimes.GLOBAL, Inputs.RESTORES_DEFAULTS, {})
	_said["keys_kept"] = bound and restored and loaded and pressed


func _carrying() -> void:
	var baskets: Extra.Baskets = _stall.baskets
	var carried: Carried = _stall.ui.carried
	_go(ExtraPieces.CARRYING)
	await _frames()
	var crates := {}
	# every crate on the counter, by the name it shows
	for crate: Node in _hands.place(ExtraPieces.CARRYING).find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Draggable):
		crates[(crate.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Text)[0] as Text).get_text()] = crate
	var basket: Control = _stall.ui.node_named(&"basket")
	var figs: Control = _stall.ui.node_named(&"fig basket")
	(crates["pear"] as Control).grab_focus()
	await _frames()
	await _hands.key(KEY_ENTER)
	var lifted: bool = carried.is_carrying()
	await _hands.key(KEY_DOWN)
	var taking: bool = basket.has_focus() and basket.get_state() == &"accepting"
	await _hands.key(KEY_RIGHT)
	var refusing: bool = figs.has_focus() and figs.get_state() == &"refusing"
	await _hands.key(KEY_ENTER)
	_said["refused_by_pad"] = lifted and refusing and carried.is_carrying() and baskets.get_figs().is_empty()
	await _hands.key(KEY_LEFT)
	await _hands.key(KEY_ENTER)
	_said["dropped_by_pad"] = taking and not carried.is_carrying() and baskets.get_basket().map(func(one: Dictionary) -> String: return one["name"]) == ["pear"]
	var fig: Variant = crates["fig"]._get_drag_data(Vector2.ZERO)
	var takes: bool = figs._can_drop_data(Vector2.ZERO, fig)
	figs._drop_data(Vector2.ZERO, fig)
	await _frames()
	var apple: Control = crates["apple"]
	var not_a_fig: Variant = apple._get_drag_data(Vector2.ZERO)
	var refused: bool = not figs._can_drop_data(Vector2.ZERO, not_a_fig)
	apple.notification(Control.NOTIFICATION_DRAG_END)
	await _frames()
	_said["dropped_by_mouse"] = takes and refused and not carried.is_carrying() and baskets.get_figs().map(func(one: Dictionary) -> String: return one["name"]) == ["fig"]
	apple.grab_focus()
	await _frames()
	await _hands.key(KEY_ENTER)
	var held: bool = carried.is_carrying()
	await _hands.key(KEY_ESCAPE)
	_said["put_back_by_pad"] = held and not carried.is_carrying() and apple.has_focus() and baskets.get_counter().size() == 1
	_stall.commands.dispatch(Chimes.GLOBAL, Extra.Baskets.EMPTIES, {})
	await _frames()
