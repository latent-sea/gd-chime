extends SceneTree

## What must be true of apps hosted beside a game: the game owns what is
## global, and each app owns its rectangle and its drawing (ruled
## 2026-09-27, "the middle path").
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_hosting.gd
##
## THE HOST IS A GAME'S SCENE OF ITS OWN, not a demo: before any app exists
## it puts the engine in French and gives its own label French words, it
## owns a bus named UI at a volume and a mute of its own with a player of
## its own on it, and it counts every Space and Escape that reaches its own
## unhandled input. Beside that it holds two apps, each in its own rect, its
## own shape and its own look: a stall down the left, portrait, and a yard
## across the rest in a panel of the host's.
##
## Proved here: nothing the host set - the locale, its label's words, its
## bus and its player, the project settings, the input map, the clear
## colour, the window - is changed by an app entering, building, leaving or
## coming back; an app coming back, or moved under another parent, is one
## app and not two, and one gone from the tree holds nothing; a rect of no
## width or no height fits nothing and says nothing, and the app fits the
## rect once it has one; a key an app takes never reaches the host, one no
## app takes does, and a key goes to the app holding the window's one focus
## (the engine keeps one, across every viewport in the window) and to no
## other, whose open pop-up it never closes - and a click on an app's bare
## ground leaves that focus where it was; a keyboard carry walks the targets of its own app and its own
## layer, never the other app's and never those under an open pop-up; the
## locale is the game's, followed by every app whoever sets it; and the bus
## is the game's, read by both apps, a player's choice in one heard in both.

const ChimeApp := preload("res://addons/gd_chime/chime_app.gd")
const Fixture := preload("res://tests/fixture.gd")
const Verdict := preload("res://tests/verdict.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Actions := preload("res://addons/gd_chime/actions.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Language := preload("res://addons/gd_chime/language.gd")
const SoundBus := preload("res://addons/gd_chime/sound_bus.gd")
const Shape := preload("res://addons/gd_chime/shape.gd")
const Place := preload("res://addons/gd_chime/place.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")

const PRESSES := &"presses"
const PUTS := &"puts_it_here"
## The host's bus, and the volume and the mute it keeps it at.
const BUS := &"UI"
const HOST_DB := -12.0
## The host's own words, and the apps' words, in the French the host gives them.
const OPENING := "Open the market"
const FRENCH := {"Open the market": "Ouvrir le marché", "press": "appuyer", "crate": "caisse", "shelf": "étagère", "yard": "cour", "put it here": "le poser ici"}
## How much of the host's width the stall takes, from the left; the yard's panel takes the rest.
const STALL := 0.4


## The game: a label of its own, a button of its own that takes the focus,
## a player on its own bus, and its own count of the two keys, heard only
## where nothing took them first.
class Host extends Control:
	var label := Label.new()
	var button := Button.new()
	var player := AudioStreamPlayer.new()
	var panel := Control.new()
	var spaces: int = 0
	var escapes: int = 0

	func _init() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		label.text = OPENING
		player.bus = BUS
		# the yard's panel, over the rest of the host's width
		panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		panel.anchor_left = STALL
		for part: Node in [label, button, player, panel]:
			add_child(part)

	func _unhandled_input(event: InputEvent) -> void:
		var key := event as InputEventKey
		if key == null or not key.pressed:
			return
		if key.keycode == KEY_SPACE:
			spaces += 1
		elif key.keycode == KEY_ESCAPE:
			escapes += 1


## An app of one screen: a press its model counts, and a crate and a shelf
## laid out as it is told; and a pop-up holding a crate of its own - the
## stall's a panel over the screen, the yard's blocking it.
class Stall extends ChimeApp:
	var worn: Theme
	var counter: Fixture.Model
	var over: StringName  # the pop-up's place
	var builds: int = 0  # how many times it was described
	var _yard: bool  # laid out as the yard: its shelf at the top right; else the stall's, its shelf at the foot

	func _init(look_worn: Theme, yard: bool) -> void:
		super()
		worn = look_worn
		_yard = yard

	func look() -> Theme:
		return worn

	func declare(register: Actions) -> void:
		register.declare_all({PRESSES: ["press", Actions.keys(KEY_P)], PUTS: ["put it here"]})

	func describe() -> Desc:
		builds += 1
		counter = Fixture.Model.new(chimes, &"home")
		counter.answering = [PRESSES, PUTS]
		var crates: Desc = ui.pop_up(&"crates", func(_which: Bound) -> Desc: return ui.column([ui.draggable({"id": 2}, [ui.text(Phrase.of("crate"))]).named(&"crate up")]))
		# the stall's a panel the reader may keep open while working under it, so nothing but its layer keeps a carry in it; the yard's blocks, as a question does
		if not _yard:
			crates.blocks_nothing()
		over = crates.get_place()
		var press := ui.pressable(PRESSES, {}, [ui.text(Phrase.of("press")).named(&"press words")]).named(&"press")
		var shelf := ui.drop_target(PUTS, [ui.text(Phrase.of("shelf"))]).named(&"shelf")
		var laid := [ui.row([ui.text(Phrase.of("yard")).grow(), shelf]), press] if _yard else [press, ui.draggable({"id": 1}, [ui.text(Phrase.of("crate"))]).named(&"crate"), ui.stack([]).grow(), shelf]
		return ui.app(&"app", [ui.screen(&"home", [ui.column(laid).grow()], counter), crates])


## Hears everything said out loud as an error or a warning.
class Hearing extends Logger:
	var said: Array[String] = []

	func _log_error(_function: String, _file: String, _line: int, code: String, rationale: String, _editor_notify: bool, _error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		said.append("%s %s" % [code, rationale])


var _verdict := Verdict.new()
var _hearing := Hearing.new()
var _host: Host
var _stall: Stall
var _yard: Stall
var _french := Translation.new()


func _init() -> void:
	OS.add_logger(_hearing)
	await process_frame
	# a desk's window, set once the window stands: set before its first frame, a headless window keeps its own size (measured on 4.6.2)
	root.size = Vector2i(1920, 1080)
	_french.locale = "fr"
	# the host's words and the apps', in the French a game hosting them gives them
	for english: String in FRENCH:
		_french.add_message(english, FRENCH[english])
	TranslationServer.add_translation(_french)
	await _verdict.states(_nothing_the_host_set_is_changed_by_an_app_entering_building_leaving_or_coming_back)
	await _verdict.states(_an_app_coming_back_or_moved_is_one_app_not_two_and_one_gone_holds_nothing)
	await _verdict.states(_a_rect_of_no_width_or_no_height_fits_nothing_and_says_nothing)
	await _verdict.states(_a_key_an_app_takes_never_reaches_the_host_one_no_app_takes_does_and_only_the_focused_app_hears_it)
	await _verdict.states(_a_keyboard_carry_never_lands_in_the_other_app_or_under_an_open_pop_up)
	await _verdict.states(_the_locale_is_the_game_s_and_every_app_follows_it_whoever_sets_it)
	await _verdict.states(_the_bus_is_the_game_s_read_by_both_apps_and_a_choice_in_one_is_heard_in_both)
	TranslationServer.remove_translation(_french)
	OS.remove_logger(_hearing)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## The host stood up as a game stands itself up - the locale French, its bus
## at its own volume and muted - and then the two apps added beside it.
func _hosting() -> void:
	TranslationServer.set_locale("fr")
	TranslationServer.pseudolocalization_enabled = false
	if AudioServer.get_bus_index(BUS) == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, BUS)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS), HOST_DB)
	AudioServer.set_bus_mute(AudioServer.get_bus_index(BUS), true)
	_host = Host.new()
	root.add_child(_host)
	await _a_frame_passes()


## The stall down the left, and the yard across the host's panel.
func _apps() -> void:
	_stall = Stall.new(Themes.new(Themes.NEUTRAL), false)
	_stall.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stall.anchor_right = STALL
	_yard = Stall.new(Themes.new(Themes.NEUTRAL), true)
	_yard.set_anchors_preset(Control.PRESET_FULL_RECT)
	_host.add_child(_stall)
	_host.panel.add_child(_yard)
	await _a_frame_passes()
	await _a_frame_passes()


func _done() -> void:
	_host.free()


## Everything the host set that an app could reach, read now.
func _host_state() -> Dictionary:
	var settings := {}
	# every project setting there is, by name
	for property: Dictionary in ProjectSettings.get_property_list():
		settings[property["name"]] = ProjectSettings.get_setting(property["name"])
	var inputs := {}
	# every action of the input map, and every event on it
	for action: StringName in InputMap.get_actions():
		inputs[action] = InputMap.action_get_events(action).map(func(event: InputEvent) -> String: return event.as_text())
	var bus := AudioServer.get_bus_index(BUS)
	return {
		"locale": [TranslationServer.get_locale(), TranslationServer.pseudolocalization_enabled],
		"label": _host.label.tr(_host.label.text),
		"bus": [AudioServer.bus_count, bus, AudioServer.get_bus_volume_db(bus), AudioServer.is_bus_mute(bus), _host.player.bus],
		"settings": settings,
		"inputs": inputs,
		"clear": RenderingServer.get_default_clear_color(),
		"window": [root.size, root.content_scale_mode, root.content_scale_size, root.content_scale_aspect, root.content_scale_factor, root.theme],
	}


## What moved between two readings of the host: each part that did, and the settings by name.
func _moved(before: Dictionary, after: Dictionary) -> Array:
	var moved: Array = []
	# every part of the host's state, for one that is not as it was
	for part: String in before:
		if before[part] == after[part]:
			continue
		if part != "settings":
			moved.append("%s %s -> %s" % [part, before[part], after[part]])
			continue
		# every setting, for the ones that moved
		for setting: String in before[part]:
			if before[part][setting] != after[part].get(setting):
				moved.append("setting %s" % setting)
	return moved


## A key pushed at the window, down then up, as a player presses it.
func _key(code: Key) -> void:
	# the key going down, then up
	for down: bool in [true, false]:
		var press := InputEventKey.new()
		press.keycode = code
		press.physical_keycode = code
		press.pressed = down
		root.push_input(press)
	await _a_frame_passes()


## The left button pressed and let go at a point of the window, the pointer put there first.
func _click(at: Vector2) -> void:
	var move := InputEventMouseMotion.new()
	move.position = at
	root.push_input(move)
	# the button going down, then up
	for down: bool in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = down
		click.position = at
		root.push_input(click)
	await _a_frame_passes()


## The places standing under an app's canvas, by name: one app built once is one of each.
func _places(app: Stall) -> Array:
	return app.canvas.get_children().filter(func(built: Node) -> bool: return built is Place).map(func(place: Node) -> StringName: return place.name)


## What a named text of an app says.
func _says(app: Stall, id: StringName) -> String:
	return (app.ui.node_named(id) as Text).get_text()


func _nothing_the_host_set_is_changed_by_an_app_entering_building_leaving_or_coming_back() -> void:
	await _hosting()
	var before := _host_state()
	_verdict.check(before["locale"][0] == "fr" and before["label"] == FRENCH[OPENING] and before["bus"][2] == HOST_DB and before["bus"][3], "the host set its own: French, its label's words, its bus at its volume and muted: %s %s %s" % [before["locale"], before["label"], before["bus"]])
	await _apps()
	_verdict.check(_stall.ui.shape.orientation.read() == Shape.PORTRAIT and _yard.ui.shape.orientation.read() == Shape.LANDSCAPE and _stall.canvas.theme != _yard.canvas.theme, "the two apps stand side by side, each in its own shape and its own look: %s %s" % [_stall.ui.shape.orientation.read(), _yard.ui.shape.orientation.read()])
	_verdict.check(_moved(before, _host_state()).is_empty(), "two apps entering and building changed nothing the host set: %s" % [_moved(before, _host_state())])
	_host.remove_child(_stall)
	await _a_frame_passes()
	_verdict.check(_moved(before, _host_state()).is_empty(), "one leaving changed nothing the host set: %s" % [_moved(before, _host_state())])
	_host.add_child(_stall)
	await _a_frame_passes()
	_verdict.check(_moved(before, _host_state()).is_empty(), "it coming back changed nothing the host set: %s" % [_moved(before, _host_state())])
	_yard.reparent(_host)
	await _a_frame_passes()
	_verdict.check(_moved(before, _host_state()).is_empty(), "the other moved under another parent changed nothing the host set: %s" % [_moved(before, _host_state())])
	_host.remove_child(_stall)
	_stall.free()
	_yard.free()
	await _a_frame_passes()
	_verdict.check(_moved(before, _host_state()).is_empty(), "and both gone, nothing the host set is changed: %s" % [_moved(before, _host_state())])
	_done()


func _an_app_coming_back_or_moved_is_one_app_not_two_and_one_gone_holds_nothing() -> void:
	await _hosting()
	await _apps()
	var standing := _stall.canvas.get_child_count()
	var first := _stall.counter
	_verdict.check(_stall.builds == 1 and _places(_stall).count(&"app") == 1, "built once, the stall is one app: %d %s" % [_stall.builds, _places(_stall)])
	_host.remove_child(_stall)
	_verdict.check(_stall.canvas.get_child_count() == 0 and not is_instance_valid(first), "gone from the tree, it holds nothing: its models, its places and its pop-ups gone with it: %d" % _stall.canvas.get_child_count())
	_host.add_child(_stall)
	await _a_frame_passes()
	_verdict.check(_stall.builds == 2 and _stall.canvas.get_child_count() == standing and _places(_stall).count(&"app") == 1, "coming back, it is built again once - one app, not two: %d %d of %d %s" % [_stall.builds, _stall.canvas.get_child_count(), standing, _places(_stall)])
	(_stall.ui.node_named(&"press") as Pressable).pressed()
	await _a_frame_passes()
	_verdict.check(_stall.counter.told_actions == [PRESSES], "and a press there is told once, to the one model it has: %s" % [_stall.counter.told_actions])
	var yard_standing := _yard.canvas.get_child_count()
	_yard.reparent(_host)
	await _a_frame_passes()
	_verdict.check(_yard.builds == 2 and _yard.canvas.get_child_count() == yard_standing and _places(_yard).count(&"app") == 1, "moved under another parent, the yard is built again once - one app, not two: %d %d of %d" % [_yard.builds, _yard.canvas.get_child_count(), yard_standing])
	_done()


func _a_rect_of_no_width_or_no_height_fits_nothing_and_says_nothing() -> void:
	await _hosting()
	_host.panel.anchor_left = 1.0
	await _apps()
	var said := _hearing.said.size()
	_verdict.check(_yard.size.x == 0.0 and _yard.viewport.size_2d_override == _yard.get_base(), "in a panel of no width, the yard fits nothing: its canvas stays at its base: %s %s" % [_yard.size, _yard.viewport.size_2d_override])
	# the panel's width animated from nothing, a step a frame
	for left: float in [0.999, 0.9, 0.6, STALL]:
		_host.panel.anchor_left = left
		await _a_frame_passes()
	var scale := minf(_yard.size.x / _yard.get_base().x, _yard.size.y / _yard.get_base().y)
	_verdict.check(_yard.viewport.size_2d_override == Vector2i((_yard.size / scale).round()) and _yard.ui.shape.orientation.read() == Shape.LANDSCAPE, "given a width, it fits the rect it now has: %s in %s" % [_yard.viewport.size_2d_override, _yard.size])
	var fitted := _yard.viewport.size_2d_override
	_yard.anchor_bottom = 0.0
	await _a_frame_passes()
	_verdict.check(_yard.size.y == 0.0 and _yard.viewport.size_2d_override == fitted, "and a rect of no height fits nothing either, the canvas left as it was: %s %s" % [_yard.size, _yard.viewport.size_2d_override])
	_yard.anchor_bottom = 1.0
	await _a_frame_passes()
	(_yard.ui.node_named(&"press") as Pressable).pressed()
	await _a_frame_passes()
	_verdict.check(_yard.counter.told_actions == [PRESSES], "and it works as ever once it has its rect: %s" % [_yard.counter.told_actions])
	_verdict.check(_hearing.said.size() == said, "nothing was said out loud on the way - no error, no warning: %s" % [_hearing.said.slice(said)])
	_done()


func _a_key_an_app_takes_never_reaches_the_host_one_no_app_takes_does_and_only_the_focused_app_hears_it() -> void:
	await _hosting()
	await _apps()
	_yard.commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": _yard.over})
	await _a_frame_passes()
	var press: Control = _stall.ui.node_named(&"press")
	press.grab_focus()
	await _a_frame_passes()
	_verdict.check(_yard.driver.is_raised() and _stall.viewport.gui_get_focus_owner() == press and _yard.viewport.gui_get_focus_owner() == null, "the yard's pop-up is open, and the stall's press holds the window's one focus: %s %s" % [_stall.viewport.gui_get_focus_owner(), _yard.viewport.gui_get_focus_owner()])
	await _click(Vector2(STALL * 0.5 * root.size.x, root.size.y * 0.6))
	_verdict.check(_stall.viewport.gui_get_focus_owner() == press, "a click on the stall's bare ground leaves the focus on its press, not on the easel: %s %s" % [_stall.viewport.gui_get_focus_owner(), root.gui_get_focus_owner()])
	await _key(KEY_SPACE)
	_verdict.check(_stall.counter.told_actions == [PRESSES], "Space, which the stall's focused press takes, presses it: %s" % [_stall.counter.told_actions])
	_verdict.check(_yard.counter.told_actions.is_empty(), "and the yard, which does not hold the focus, never hears it: %s" % [_yard.counter.told_actions])
	_verdict.check(_host.spaces == 0, "and the host's own handler never sees a key an app took: %d" % _host.spaces)
	await _key(KEY_ESCAPE)
	_verdict.check(_yard.driver.is_raised(), "Escape in the stall, which has nothing to close, never reaches the yard to close its pop-up: %s" % _yard.driver.is_raised())
	_verdict.check(_host.escapes == 1, "and it goes on to the host, since no app took it: %d" % _host.escapes)
	_yard.commands.dispatch(Chimes.GLOBAL, Driver.GOES_BACK, {})
	await _a_frame_passes()
	press.grab_focus()
	await _a_frame_passes()
	press.release_focus()
	await _key(KEY_P)
	_verdict.check(_stall.counter.told_actions == [PRESSES, PRESSES] and _yard.counter.told_actions.is_empty(), "the focus gone from the stall's press to nowhere, the stall, which held it last, still hears its own key, and the yard does not: %s %s" % [_stall.counter.told_actions, _yard.counter.told_actions])
	_host.button.grab_focus()
	await _key(KEY_P)
	_verdict.check(_stall.counter.told_actions == [PRESSES, PRESSES] and _yard.counter.told_actions.is_empty(), "the focus on the host's own button, neither app hears a key: %s %s" % [_stall.counter.told_actions, _yard.counter.told_actions])
	(_yard.ui.node_named(&"press") as Control).grab_focus()
	await _a_frame_passes()
	await _key(KEY_SPACE)
	_verdict.check(_yard.counter.told_actions == [PRESSES] and _stall.counter.told_actions == [PRESSES, PRESSES] and _host.spaces == 0, "the focus moved to the yard's press, Space presses it and nothing else: %s %s %d" % [_yard.counter.told_actions, _stall.counter.told_actions, _host.spaces])
	_done()


func _a_keyboard_carry_never_lands_in_the_other_app_or_under_an_open_pop_up() -> void:
	await _hosting()
	await _apps()
	var crate: Control = _stall.ui.node_named(&"crate")
	crate.grab_focus()
	await _a_frame_passes()
	await _key(KEY_ENTER)
	_verdict.check(_stall.ui.carried.is_lifted({"id": 1}) and crate.has_focus(), "Enter on the stall's crate lifts it by the keys")
	await _key(KEY_RIGHT)
	var theirs: Control = _yard.ui.node_named(&"shelf")
	_verdict.check(crate.has_focus() and not theirs.has_focus() and _stall.ui.carried.is_carrying(), "right, where only the yard has a shelf, finds nothing: the carry stays on the crate, and never lands in the other app: %s" % [_yard.viewport.gui_get_focus_owner()])
	_stall.ui.carried.put_back()
	await _a_frame_passes()
	_stall.commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": _stall.over})
	await _a_frame_passes()
	var up: Control = _stall.ui.node_named(&"crate up")
	up.grab_focus()
	await _a_frame_passes()
	await _key(KEY_ENTER)
	_verdict.check(_stall.ui.carried.is_lifted({"id": 2}) and up.has_focus(), "the pop-up's crate lifted by the keys")
	var under: Control = _stall.ui.node_named(&"shelf")
	await _key(KEY_DOWN)
	_verdict.check(up.has_focus() and not under.has_focus(), "down, where the only shelf is the stall's under the open pop-up, finds nothing: the pop-up is a layer of its own: %s at %s, the shelf at %s" % [_stall.viewport.gui_get_focus_owner(), up.get_global_rect(), under.get_global_rect()])
	_done()


func _the_locale_is_the_game_s_and_every_app_follows_it_whoever_sets_it() -> void:
	await _hosting()
	await _apps()
	_verdict.check(_says(_stall, &"press words") == FRENCH["press"] and _says(_yard, &"press words") == FRENCH["press"], "the host put the engine in French before either app stood, and both apps speak it: %s %s" % [_says(_stall, &"press words"), _says(_yard, &"press words")])
	TranslationServer.set_locale("en")
	await _a_frame_passes()
	_verdict.check(_says(_stall, &"press words") == "press" and _says(_yard, &"press words") == "press" and _stall.ui.language.get_language() == Language.SOURCE, "the host setting English, both apps follow it: %s %s %s" % [_says(_stall, &"press words"), _says(_yard, &"press words"), _stall.ui.language.get_language()])
	_stall.commands.dispatch(Chimes.GLOBAL, Language.CHANGES_LANGUAGE, {"value": &"fr"})
	await _a_frame_passes()
	_verdict.check(TranslationServer.get_locale() == "fr" and _host.label.tr(OPENING) == FRENCH[OPENING] and _says(_yard, &"press words") == FRENCH["press"], "a player choosing French in one app sets the game's locale, which the game and the other app follow: %s %s %s" % [TranslationServer.get_locale(), _host.label.tr(OPENING), _says(_yard, &"press words")])
	_done()


func _the_bus_is_the_game_s_read_by_both_apps_and_a_choice_in_one_is_heard_in_both() -> void:
	await _hosting()
	await _apps()
	var bus := AudioServer.get_bus_index(BUS)
	_verdict.check(_stall.sound_bus.muted.read() and _yard.sound_bus.muted.read() and is_equal_approx(_stall.sound_bus.volume.read(), db_to_linear(HOST_DB)), "both apps read the host's bus as they find it: muted, at its volume: %s %s %f" % [_stall.sound_bus.muted.read(), _yard.sound_bus.muted.read(), _stall.sound_bus.volume.read()])
	_stall.commands.dispatch(Chimes.GLOBAL, SoundBus.MUTES_SOUND, {"on": false})
	_stall.commands.dispatch(Chimes.GLOBAL, SoundBus.SETS_VOLUME, {"value": 0.5})
	await _a_frame_passes()
	_verdict.check(not AudioServer.is_bus_mute(bus) and is_equal_approx(AudioServer.get_bus_volume_db(bus), linear_to_db(0.5)), "a player's choice in the stall sets the game's bus: %s %f" % [AudioServer.is_bus_mute(bus), AudioServer.get_bus_volume_db(bus)])
	_verdict.check(not _yard.sound_bus.muted.read() and is_equal_approx(_yard.sound_bus.volume.read(), 0.5), "and the yard, reading the one bus, says so too: %s %f" % [_yard.sound_bus.muted.read(), _yard.sound_bus.volume.read()])
	AudioServer.set_bus_mute(bus, true)
	await _a_frame_passes()
	_verdict.check(_stall.sound_bus.muted.read() and _yard.sound_bus.muted.read(), "the game muting its own bus, both apps say so: %s %s" % [_stall.sound_bus.muted.read(), _yard.sound_bus.muted.read()])
	_done()
