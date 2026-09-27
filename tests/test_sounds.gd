extends SceneTree

## What must be true of the interface's sounds.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_sounds.gd
##
## Nothing here listens to a speaker. The controller records what it ASKED to
## play, as [moment, the style the sound was found under], and that record is
## what every property is stated over: headless there is no audio device, and
## a property about what a look says should sound would be a property about
## the machine it ran on.
##
## The streams are built in code, a few samples each, so no file is needed and
## each moment's is its own object.
##
## Proved here: a hand's press plays the look's press sound and a press the
## door refused, or the model refused once told, plays the refused sound and
## not the press sound; a mouse press on a control that takes no focus plays
## its own style's sound, the focus being on another control; a local press,
## which runs no command, plays the same press sound; NO COMMAND is a press -
## the application's first move at startup is silent, and so is a dispatch no
## hand made; the pointer arriving and focus moving each play theirs, the
## style's where it has one and the look's default where it has not; a move, a
## pop-up raised and a pop-up lowered each play theirs, the first move
## excepted; a glow starting plays once and not again while it stays; the
## bus is the game's, read as it stands and followed whoever moves it; muted,
## nothing plays and the bus is muted, and the volume is set on the bus; ten
## presses in one frame are one sound; the volume takes the payload a
## settings choice carries, so a choice of levels sets it through the door;
## and a notification arriving plays its sound, taking the focus from
## nothing, and leaving plays none.

const Fixture := preload("res://tests/fixture.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Prompts := preload("res://addons/gd_chime/prompts.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Sounds := preload("res://addons/gd_chime/sounds.gd")
const SoundBus := preload("res://addons/gd_chime/sound_bus.gd")
const Notifications := preload("res://addons/gd_chime/notifications.gd")
const NotificationTray := preload("res://addons/gd_chime/components/recipes/notification_tray.gd")
const LookSounds := preload("res://addons/gd_chime/look_sounds.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Setting := preload("res://addons/gd_chime/components/recipes/setting.gd")
const PressLocal := preload("res://addons/gd_chime/components/primitives/press_local.gd")
const Local := preload("res://addons/gd_chime/components/primitives/local.gd")
const Verdict := preload("res://tests/verdict.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")

## A style of its own, a variation of a pressable, with its own press sound.
const LOUD := &"Loud"
const PRESS := &"presses"
const QUIET := &"stays_put"
const LATE := &"tries_anyway"


var _verdict := Verdict.new()
var _over: StringName  # the pop-up raised and lowered, named by the builder



## The fixture's model, with one action it refuses AS IT IS TOLD rather than
## before: the door lets that press through, and the answer comes back a
## refusal - which is the only way the order of the two bells one press rings
## can be seen.
class Grudging extends Fixture.Model:
	var refuses_when_told: StringName = &""

	func told(action: StringName, payload: Dictionary) -> Phrase:
		return Phrase.of("not like that") if action == refuses_when_told else super(action, payload)


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(400, 400)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_a_press_plays_the_look_s_press_sound_and_a_refused_press_its_refused_one)
	await _verdict.states(_a_mouse_press_on_a_control_that_takes_no_focus_plays_its_own_style_s_sound)
	await _verdict.states(_nothing_a_hand_did_not_press_plays_a_press_sound)
	await _verdict.states(_a_local_press_plays_the_same_press_sound_though_no_command_ran)
	await _verdict.states(_the_pointer_and_the_focus_play_theirs_under_the_style_that_has_one)
	await _verdict.states(_a_move_and_a_pop_up_raised_and_lowered_each_play_theirs)
	await _verdict.states(_a_glow_starting_plays_once_and_not_again_while_it_stays)
	await _verdict.states(_the_sounds_play_on_the_game_s_bus_read_as_it_stands_and_follow_it_whoever_moves_it)
	await _verdict.states(_muted_nothing_plays_and_the_bus_is_muted_and_the_volume_is_set_on_it)
	await _verdict.states(_ten_presses_in_one_frame_are_one_sound)
	await _verdict.states(_a_choice_of_volume_levels_sets_the_volume_through_the_door)
	await _verdict.states(_a_notification_arriving_plays_the_look_s_sound_and_leaving_plays_none)
	await _verdict.states(_a_look_that_sets_none_chimes_with_the_floor_s_placeholder)
	root.theme = null
	# frames for the mixer to let go of the last playback it was handed, which it holds on a thread of its own and would otherwise still hold as the process ends
	for settling: int in 10:
		await process_frame
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## A stream of its own, a handful of samples, so that no file is needed and
## two moments never share one object.
func _wav(pitch: int) -> AudioStreamWAV:
	var made := AudioStreamWAV.new()
	made.format = AudioStreamWAV.FORMAT_16_BITS
	made.mix_rate = 22050
	made.data = PackedByteArray([0, 0, pitch, 1, 0, 0, pitch, 2])
	return made


## A look with a sound for every moment, and one style of its own whose press
## sounds differently, as {"look", "streams"}.
func _look() -> Dictionary:
	var look := Themes.new(Themes.NEUTRAL)
	look.set_type_variation(LOUD, Themes.PRESSABLE)
	var streams: Dictionary = {}
	# every moment a look can speak for, given a stream nothing else has
	for moment: StringName in [Sounds.HOVERED, Sounds.FOCUS_MOVED, Sounds.PRESSED, Sounds.REFUSED, Sounds.GLOW_STARTED, Sounds.RAISED, Sounds.LOWERED, Sounds.MOVED, Sounds.NOTIFIED]:
		streams[moment] = _wav(streams.size() + 1)
		LookSounds.set_sound(look, moment, streams[moment])
	# the one style with sounds of its own: a press and a focus, and nothing else
	for moment: StringName in [Sounds.PRESSED, Sounds.FOCUS_MOVED]:
		streams[[LOUD, moment]] = _wav(90 + streams.size())
		LookSounds.set_sound(look, moment, streams[[LOUD, moment]], LOUD)
	return {"look": look, "streams": streams}


## A fixture over the actions this property draws - the startup check quits an
## application that declares one nothing performs - that look on the root, a
## model told each action from anywhere, and the sounds listening, as
## {made, model, sounds, look, streams}.
func _heard(declared: Dictionary) -> Dictionary:
	var made := Fixture.new(root, declared)
	var dressed := _look()
	root.theme = dressed["look"]
	var model := Grudging.new(made.chimes)
	for action: StringName in declared:
		made.commands.register(Chimes.GLOBAL, action, model)
	# the notifications first, as an application builds them: the sounds hear one arrive; out of the tree, so they outlive a tray the fixture frees
	var notifications := Notifications.new(made.chimes, made.commands, root)
	made.commands.register(Chimes.GLOBAL, Notifications.DISMISSES, notifications)
	# the game's bus, answering a player's volume and mute from anywhere, and the sounds playing on it
	var bus := SoundBus.new(made.chimes)
	for action: StringName in SoundBus.COMMANDS:
		made.commands.register(Chimes.GLOBAL, action, bus)
	root.add_child(bus)
	var sounds := Sounds.new(made.chimes, made.driver, made.prompts, root, bus)
	root.add_child(sounds)
	return {"made": made, "model": model, "sounds": sounds, "bus": bus, "notifications": notifications, "look": dressed["look"], "streams": dressed["streams"]}


func _done(heard: Dictionary) -> void:
	(heard["model"] as Fixture.Model).free()
	(heard["made"] as Fixture).done()
	(heard["notifications"] as Notifications).free()
	root.theme = null


## The moments asked for since a mark, without the styles.
func _since(heard: Dictionary, mark: int) -> Array:
	var played: Array = (heard["sounds"] as Sounds).get_played().slice(mark)
	return played.map(func(one: Array) -> StringName: return one[0])


func _how_many(heard: Dictionary) -> int:
	return (heard["sounds"] as Sounds).get_played().size()


## Enter pressed and let go on whatever has the focus.
func _accept() -> void:
	# the key going down, which is the press, and then up
	for down: bool in [true, false]:
		var key := InputEventKey.new()
		key.keycode = KEY_ENTER
		key.physical_keycode = KEY_ENTER
		key.pressed = down
		root.push_input(key)


## The left button pressed and let go where the pointer is put first, since a
## press is routed by where it landed.
func _click(at: Vector2) -> void:
	_point_at(at)
	for down: bool in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = down
		click.position = at
		root.push_input(click)


func _point_at(at: Vector2) -> void:
	var move := InputEventMouseMotion.new()
	move.position = at
	root.push_input(move)


func _button(does: StringName) -> Pressable:
	return root.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable and (part as Pressable).action == does)[0]


## A press through the door sounds the look's press sound, under the style of
## the control pressed; a press the door would refuse never dispatches, and
## sounds the refused one instead of it.
func _a_press_plays_the_look_s_press_sound_and_a_refused_press_its_refused_one() -> void:
	var heard := _heard({PRESS: "presses it", QUIET: "stays put", LATE: "tries anyway"})
	var ui: Variant = heard["made"].ui
	(heard["model"] as Grudging).refuse(QUIET, Phrase.of("not now"))
	(heard["model"] as Grudging).refuses_when_told = LATE
	ui.start(ui.app(&"app", [ui.pressable(PRESS, {}, [ui.text("go")], LOUD), ui.pressable(QUIET, {}, [ui.text("no")]), ui.pressable(LATE, {}, [ui.text("try")])]))
	await _a_frame_passes()

	_button(PRESS).grab_focus()
	await _a_frame_passes()
	var mark := _how_many(heard)
	_accept()
	await _a_frame_passes()
	_verdict.check(_since(heard, mark) == [Sounds.PRESSED], "a press plays the press sound, once: %s" % [_since(heard, mark)])
	_verdict.check((heard["sounds"] as Sounds).get_played().back() == [Sounds.PRESSED, LOUD], "under the style of the control pressed, which has its own: %s" % [(heard["sounds"] as Sounds).get_played().back()])
	_verdict.check((heard["model"] as Fixture.Model).told_actions == [PRESS], "and the press is the ordinary one that ran the command: %s" % [(heard["model"] as Fixture.Model).told_actions])

	_button(QUIET).grab_focus()
	await _a_frame_passes()
	mark = _how_many(heard)
	_accept()
	await _a_frame_passes()
	_verdict.check(_since(heard, mark) == [Sounds.REFUSED], "a press the door refuses plays the refused sound and not the press sound: %s" % [_since(heard, mark)])
	_verdict.check((heard["sounds"] as Sounds).get_played().back() == [Sounds.REFUSED, &""], "in the look's own, no style having one of its own: %s" % [(heard["sounds"] as Sounds).get_played().back()])

	_button(LATE).grab_focus()
	await _a_frame_passes()
	mark = _how_many(heard)
	_accept()
	await _a_frame_passes()
	_verdict.check(_since(heard, mark) == [Sounds.REFUSED], "a press the door allowed and the model then refused plays the refused sound alone, the press moment sounding after the command was answered: %s" % [_since(heard, mark)])
	_done(heard)


## A local press dispatches nothing, so no command ever runs; it is a press
## all the same and sounds like one.
func _a_local_press_plays_the_same_press_sound_though_no_command_ran() -> void:
	var heard := _heard({})
	var ui: Variant = heard["made"].ui
	var out: Local = ui.local(false)
	ui.start(ui.app(&"app", [ui.press_local(out, func(now: bool) -> bool: return not now, [ui.text("more")]).named(&"more")]))
	await _a_frame_passes()

	var more: PressLocal = ui.node_named(&"more")
	more.grab_focus()
	await _a_frame_passes()
	var ran: Dictionary = (heard["made"] as Fixture).commands.get_last()
	var mark := _how_many(heard)
	_accept()
	await _a_frame_passes()
	_verdict.check(out.read() == true, "the local press set its local: %s" % out.read())
	_verdict.check((heard["made"] as Fixture).commands.get_last() == ran, "and no command ran: %s" % [(heard["made"] as Fixture).commands.get_last()])
	_verdict.check(_since(heard, mark) == [Sounds.PRESSED], "and it plays the same press sound as a press through the door: %s" % [_since(heard, mark)])
	_done(heard)


## The pointer arriving plays the look's hover sound; focus starting to show
## plays the focus sound of the style it landed on, and the look's default
## where that style names none.
func _the_pointer_and_the_focus_play_theirs_under_the_style_that_has_one() -> void:
	var heard := _heard({PRESS: "presses it", QUIET: "stays put"})
	var ui: Variant = heard["made"].ui
	ui.start(ui.app(&"app", [ui.pressable(PRESS, {}, [ui.text("go")], LOUD), ui.pressable(QUIET, {}, [ui.text("no")])]))
	await _a_frame_passes()

	# the app opens with the focus on its first control, which is the styled one
	var mark := _how_many(heard)
	_button(QUIET).grab_focus()
	await _a_frame_passes()
	_verdict.check(_since(heard, mark) == [Sounds.FOCUS_MOVED], "focus moving plays the focus sound: %s" % [_since(heard, mark)])
	_verdict.check((heard["sounds"] as Sounds).get_played().back() == [Sounds.FOCUS_MOVED, &""], "in the look's default, the style it landed on naming none of its own: %s" % [(heard["sounds"] as Sounds).get_played().back()])

	mark = _how_many(heard)
	_button(PRESS).grab_focus()
	await _a_frame_passes()
	_verdict.check((heard["sounds"] as Sounds).get_played().slice(mark) == [[Sounds.FOCUS_MOVED, LOUD]], "and a style with a focus sound of its own overrides the default: %s" % [(heard["sounds"] as Sounds).get_played().slice(mark)])

	mark = _how_many(heard)
	var over: Pressable = _button(QUIET)
	_point_at(over.get_global_rect().get_center())
	await _a_frame_passes()
	_verdict.check(_since(heard, mark) == [Sounds.HOVERED], "the pointer arriving at a control plays the hover sound, once: %s" % [_since(heard, mark)])
	_done(heard)


## Where the reader is taken is read off the driver: a pop-up raised, the same
## one lowered, and a plain move to another layer each have their own sound.
func _a_move_and_a_pop_up_raised_and_lowered_each_play_theirs() -> void:
	var heard := _heard({})
	var ui: Variant = heard["made"].ui
	var over: Desc = ui.pop_up(&"over", func(_which: Bound) -> Desc: return ui.text("over"))
	_over = over.get_place()
	ui.start(ui.app(&"app", [ui.screen(&"one", [ui.text("one")]), ui.screen(&"two", [ui.text("two")]), over]))
	await _a_frame_passes()
	var commands: Variant = (heard["made"] as Fixture).commands

	# the reader is already on the first screen, which the app enters as it starts
	var mark := _how_many(heard)
	commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": &"two"})
	await _a_frame_passes()
	_verdict.check(_since(heard, mark) == [Sounds.MOVED], "a move plays the move sound, and the command that made it, no hand having pressed one, plays none: %s" % [_since(heard, mark)])

	mark = _how_many(heard)
	commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": _over})
	await _a_frame_passes()
	_verdict.check(_since(heard, mark) == [Sounds.RAISED], "a pop-up raised plays the raised sound, not the move sound: %s" % [_since(heard, mark)])

	mark = _how_many(heard)
	commands.dispatch(Chimes.GLOBAL, Driver.GOES_BACK, {})
	await _a_frame_passes()
	_verdict.check(_since(heard, mark) == [Sounds.LOWERED], "and lowered again plays the lowered sound: %s" % [_since(heard, mark)])

	# a question confirmed: the pop-up lowered and the move it held made, in one go
	commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": _over})
	await _a_frame_passes()
	mark = _how_many(heard)
	commands.dispatch(Chimes.GLOBAL, Driver.GOES_BACK, {})
	commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": &"one"})
	await _a_frame_passes()
	_verdict.check(_since(heard, mark) == [Sounds.MOVED], "a pop-up lowered and a move made in one go sound only the move: %s" % [_since(heard, mark)])
	_done(heard)


## A prompt raised is a glow starting. The prompts ringing again while the
## same action still glows is not, so it sounds nothing.
func _a_glow_starting_plays_once_and_not_again_while_it_stays() -> void:
	var heard := _heard({PRESS: "presses it"})
	var ui: Variant = heard["made"].ui
	ui.start(ui.app(&"app", [ui.pressable(PRESS, {}, [ui.text("go")])]))
	await _a_frame_passes()
	var prompts: Prompts = (heard["made"] as Fixture).prompts

	var mark := _how_many(heard)
	prompts.raise(&"guide", PRESS)
	await _a_frame_passes()
	_verdict.check(_since(heard, mark) == [Sounds.GLOW_STARTED], "a prompt raised plays the glow sound: %s" % [_since(heard, mark)])

	mark = _how_many(heard)
	(heard["made"] as Fixture).chimes.strike(Chimes.GLOBAL, Prompts.PROMPT_MOVED)
	await _a_frame_passes()
	_verdict.check(_since(heard, mark) == [], "the prompts ringing while the same action glows plays nothing: %s" % [_since(heard, mark)])

	mark = _how_many(heard)
	prompts.withdraw(&"guide")
	prompts.raise(&"guide", PRESS)
	await _a_frame_passes()
	_verdict.check(_since(heard, mark) == [Sounds.GLOW_STARTED], "and a glow that went and came back is a glow starting again: %s" % [_since(heard, mark)])
	_done(heard)


## The bus is the game's: where the project names none and has one called UI,
## the sounds play on UI; made, nothing is added or set, and the volume and
## the mute are the bus's as the game left it; the game moving its bus
## itself is followed within the frame; and a bus the project names is the
## one played on.
func _the_sounds_play_on_the_game_s_bus_read_as_it_stands_and_follow_it_whoever_moves_it() -> void:
	AudioServer.add_bus()
	var at := AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(at, SoundBus.UI)
	AudioServer.set_bus_volume_db(at, -6.0)
	AudioServer.set_bus_mute(at, true)
	var heard := _heard({PRESS: "presses it"})
	var sound_bus: SoundBus = heard["bus"]
	var voices: Array = (heard["sounds"] as Sounds).get_children().map(func(voice: Node) -> StringName: return (voice as AudioStreamPlayer).bus)
	await _a_frame_passes()
	_verdict.check(sound_bus.named == SoundBus.UI and not voices.is_empty() and voices.all(func(named: StringName) -> bool: return named == SoundBus.UI), "a project naming no bus but having one called UI, the sounds play on UI: %s %s" % [sound_bus.named, voices])
	_verdict.check(AudioServer.bus_count == at + 1 and AudioServer.is_bus_mute(at) and AudioServer.get_bus_volume_db(at) == -6.0, "made and a frame on, the bus is as the game left it - no bus added, muted, at -6 dB: %d %s %f" % [AudioServer.bus_count, AudioServer.is_bus_mute(at), AudioServer.get_bus_volume_db(at)])
	_verdict.check(sound_bus.muted.read() and is_equal_approx(sound_bus.volume.read(), db_to_linear(-6.0)), "and the values read it as it stands: %s %f" % [sound_bus.muted.read(), sound_bus.volume.read()])
	AudioServer.set_bus_mute(at, false)
	AudioServer.set_bus_volume_db(at, linear_to_db(0.25))
	await _a_frame_passes()
	_verdict.check(not sound_bus.muted.read() and is_equal_approx(sound_bus.volume.read(), 0.25), "the game moving its bus itself, the values follow within the frame: %s %f" % [sound_bus.muted.read(), sound_bus.volume.read()])
	ProjectSettings.set_setting(SoundBus.SETTING, "Master")
	var named := SoundBus.new((heard["made"] as Fixture).chimes)
	_verdict.check(named.named == &"Master", "a bus the project names is the one, over a bus called UI: %s" % named.named)
	named.free()
	ProjectSettings.set_setting(SoundBus.SETTING, null)
	_done(heard)
	AudioServer.remove_bus(at)


## Muted is the bus muted AND nothing asked to play; the volume is the bus's
## volume, and both arrive as ordinary commands.
func _muted_nothing_plays_and_the_bus_is_muted_and_the_volume_is_set_on_it() -> void:
	var heard := _heard({PRESS: "presses it"})
	var ui: Variant = heard["made"].ui
	ui.start(ui.app(&"app", [ui.pressable(PRESS, {}, [ui.text("go")])]))
	await _a_frame_passes()
	var commands: Variant = (heard["made"] as Fixture).commands
	var sound_bus: SoundBus = heard["bus"]
	var bus := AudioServer.get_bus_index(sound_bus.named)

	commands.dispatch(Chimes.GLOBAL, SoundBus.SETS_VOLUME, {"value": 0.5})
	await _a_frame_passes()
	_verdict.check(sound_bus.volume.read() == 0.5 and is_equal_approx(AudioServer.get_bus_volume_db(bus), linear_to_db(0.5)), "the volume command sets the volume on the bus, and the volume keeps the figure it was told: %f %f" % [sound_bus.volume.read(), AudioServer.get_bus_volume_db(bus)])

	commands.dispatch(Chimes.GLOBAL, SoundBus.MUTES_SOUND, {"on": true})
	await _a_frame_passes()
	var mark := _how_many(heard)
	_button(PRESS).grab_focus()
	await _a_frame_passes()
	_accept()
	await _a_frame_passes()
	_verdict.check(AudioServer.is_bus_mute(bus) and sound_bus.muted.read(), "the mute command mutes the bus: %s" % AudioServer.is_bus_mute(bus))
	_verdict.check(_since(heard, mark) == [], "and muted, a focus and a press ask for nothing at all: %s" % [_since(heard, mark)])

	commands.dispatch(Chimes.GLOBAL, SoundBus.MUTES_SOUND, {"on": false})
	await _a_frame_passes()
	mark = _how_many(heard)
	_accept()
	await _a_frame_passes()
	_verdict.check(not AudioServer.is_bus_mute(bus) and _since(heard, mark) == [Sounds.PRESSED], "unmuted, a press sounds again: %s" % [_since(heard, mark)])
	_done(heard)


## A frame in which everything happens at once is not a chord: one sound per
## moment, however many bells ring.
func _ten_presses_in_one_frame_are_one_sound() -> void:
	var heard := _heard({PRESS: "presses it"})
	var ui: Variant = heard["made"].ui
	ui.start(ui.app(&"app", [ui.pressable(PRESS, {}, [ui.text("go")])]))
	await _a_frame_passes()

	_button(PRESS).grab_focus()
	await _a_frame_passes()
	var mark := _how_many(heard)
	# ten presses with no frame between them: push_input is answered where it is pushed
	for press: int in 10:
		_accept()
	await _a_frame_passes()
	_verdict.check((heard["model"] as Fixture.Model).told_actions.size() == 10, "ten presses landed: %d" % (heard["model"] as Fixture.Model).told_actions.size())
	_verdict.check(_since(heard, mark) == [Sounds.PRESSED], "and they are one press sound: %s" % [_since(heard, mark)])
	_done(heard)


## A notification arriving is announced by the look's sound for it, taking
## the focus from nothing; one leaving is no moment and sounds nothing. The
## app stands a tray, as one made with none is reported (notifications.gd).
func _a_notification_arriving_plays_the_look_s_sound_and_leaving_plays_none() -> void:
	var heard := _heard({PRESS: "presses it"})
	var ui: Variant = heard["made"].ui
	var notifications: Notifications = heard["notifications"]
	(heard["made"] as Fixture).actions.declare_all({Notifications.DISMISSES: ["dismiss"]})
	ui.start(ui.app(&"app", [ui.pressable(PRESS, {}, [ui.text("go")]), NotificationTray.make(ui, notifications)]))
	await _a_frame_passes()
	var focused := root.gui_get_focus_owner()
	var mark := _how_many(heard)
	var id := notifications.notify(Phrase.of("the plums are in"))
	await _a_frame_passes()
	_verdict.check(_since(heard, mark) == [Sounds.NOTIFIED], "a notification arriving plays the notified sound, once: %s" % [_since(heard, mark)])
	_verdict.check(root.gui_get_focus_owner() == focused, "and the focus stays where the reader had it: %s" % [root.gui_get_focus_owner()])
	mark = _how_many(heard)
	(heard["made"] as Fixture).commands.dispatch(Chimes.GLOBAL, Notifications.DISMISSES, {"notice": id})
	await _a_frame_passes()
	_verdict.check(notifications.get_standing().is_empty() and _since(heard, mark) == [], "sent away, it is gone and sounds nothing: %s" % [_since(heard, mark)])
	_done(heard)


## A look that sets no sound of its own - the floor's, as it stands - still
## chimes as a notification arrives: the floor's placeholder chime, a real
## tone, is the one played.
func _a_look_that_sets_none_chimes_with_the_floor_s_placeholder() -> void:
	var heard := _heard({PRESS: "presses it"})
	var bare := Themes.new(Themes.NEUTRAL)
	root.theme = bare
	var ui: Variant = heard["made"].ui
	var notifications: Notifications = heard["notifications"]
	(heard["made"] as Fixture).actions.declare_all({Notifications.DISMISSES: ["dismiss"]})
	ui.start(ui.app(&"app", [ui.pressable(PRESS, {}, [ui.text("go")]), NotificationTray.make(ui, notifications)]))
	await _a_frame_passes()
	var mark := _how_many(heard)
	notifications.notify(Phrase.of("the plums are in"))
	await _a_frame_passes()
	var found := LookSounds.get_sound(bare, Sounds.NOTIFIED, &"")
	var chime: AudioStreamWAV = found.get("stream")
	_verdict.check(_since(heard, mark) == [Sounds.NOTIFIED], "in a look that sets none, a notification arriving plays the notified sound: %s" % [_since(heard, mark)])
	_verdict.check(chime != null and chime.data.size() > 1000 and Array(chime.data).any(func(byte: int) -> bool: return byte != 0), "and what plays is the floor's placeholder chime, a real tone: %s" % [found])
	_done(heard)


## Where the focus is is not the answer to which control a press landed on: a
## control described to take no focus never holds it, and the pointer reaches
## one the focus is nowhere near.
func _a_mouse_press_on_a_control_that_takes_no_focus_plays_its_own_style_s_sound() -> void:
	var heard := _heard({PRESS: "presses it", QUIET: "stays put"})
	var ui: Variant = heard["made"].ui
	ui.start(ui.app(&"app", [ui.pressable(QUIET, {}, [ui.text("no")]), ui.pressable(PRESS, {}, [ui.text("go")], LOUD).no_focus()]))
	await _a_frame_passes()

	var loud := _button(PRESS)
	_button(QUIET).grab_focus()
	await _a_frame_passes()
	var mark := _how_many(heard)
	_click(loud.get_global_rect().get_center())
	await _a_frame_passes()
	_verdict.check(root.gui_get_focus_owner() == _button(QUIET), "the press left the focus where it was, on the other control: %s" % [root.gui_get_focus_owner()])
	_verdict.check((heard["model"] as Grudging).told_actions == [PRESS], "and the press landed on the control that takes no focus: %s" % [(heard["model"] as Grudging).told_actions])
	# the pointer has to arrive before it can press, so the hover sounds first
	_verdict.check((heard["sounds"] as Sounds).get_played().slice(mark) == [[Sounds.HOVERED, &""], [Sounds.PRESSED, LOUD]], "and the press sounded under THAT control's style, not the focused one's: %s" % [(heard["sounds"] as Sounds).get_played().slice(mark)])
	_done(heard)


## A command is not a moment. The application's own first move, and a dispatch
## made by a model or a console with no hand anywhere near it, sound no press.
func _nothing_a_hand_did_not_press_plays_a_press_sound() -> void:
	var heard := _heard({PRESS: "presses it"})
	var ui: Variant = heard["made"].ui
	ui.start(ui.app(&"app", [ui.pressable(PRESS, {}, [ui.text("go")])]))
	await _a_frame_passes()
	_verdict.check(_since(heard, 0) == [], "the application opening plays nothing at all - no press, no move, not the focus it opens on: what is first shown is simply there: %s" % [_since(heard, 0)])

	var mark := _how_many(heard)
	(heard["made"] as Fixture).commands.dispatch(Chimes.GLOBAL, PRESS, {})
	await _a_frame_passes()
	_verdict.check((heard["model"] as Grudging).told_actions == [PRESS], "a command dispatched with no hand ran: %s" % [(heard["model"] as Grudging).told_actions])
	_verdict.check(_since(heard, mark) == [], "and sounded nothing: %s" % [_since(heard, mark)])
	_done(heard)


## The volume is set by what a settings choice carries: a few levels offered
## in the choice's overlay, and the one pressed is the volume, through the door.
func _a_choice_of_volume_levels_sets_the_volume_through_the_door() -> void:
	var heard := _heard({&"opens_the_levels": "how loud"})
	var made: Fixture = heard["made"]
	var ui: Variant = made.ui
	var sound_bus: SoundBus = heard["bus"]
	made.actions.declare_all({SoundBus.SETS_VOLUME: ["set the volume"]})
	var levels := [{"value": 1.0, "words": "full"}, {"value": 0.5, "words": "half"}, {"value": 0.0, "words": "silent"}]
	var control := Setting.choice(ui, SoundBus.SETS_VOLUME, &"opens_the_levels", {offers = Bound.new(func() -> Array: return levels), chosen = sound_bus.volume, title = "how loud"})
	ui.start(ui.app(&"app", [control]))
	await _a_frame_passes()
	_button(&"opens_the_levels").pressed()
	await _a_frame_passes()
	var half: Pressable = root.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable and (part as Pressable).action == SoundBus.SETS_VOLUME)[1]
	half.pressed()
	await _a_frame_passes()
	_verdict.check(sound_bus.volume.read() == 0.5 and made.commands.get_last()["payload"] == {"value": 0.5}, "the half level pressed, the volume is a half, carried as the choice carries it: %s %s" % [sound_bus.volume.read(), made.commands.get_last()["payload"]])
	_verdict.check(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(sound_bus.named)), linear_to_db(0.5)) and not made.driver.is_raised(), "on the bus, and the levels lowered by the picking")
	_done(heard)
