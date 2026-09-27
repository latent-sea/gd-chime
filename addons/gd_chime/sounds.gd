extends "controller.gd"

const Driver := preload("driver.gd")
const Prompts := preload("prompts.gd")
const Interaction := preload("interaction.gd")
const ActionControl := preload("action_control.gd")
const LookSounds := preload("look_sounds.gd")
const Look := preload("look.gd")
const Notifications := preload("notifications.gd")
const SoundBus := preload("sound_bus.gd")

## The interface's sounds: a look's sound for each moment, played by hearing
## the bells that already ring.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## IT IS TOLD NOTHING. It listens, and on every wake it READS: the control a
## press landed on and that control's answer to it, the driver for where the
## reader is, the prompts for what glows, the viewport for the focused control.
##
## THE SOUNDS BELONG TO THE LOOK, kept on its Theme (look_sounds.gd), read
## from the root every time, so a palette brings its sounds with it.
##
## A MOVE IS ONE SOUND. Whatever the driver rang in a frame is heard as one
## move, decided at the frame's end: the app's path moved is MOVED, even when
## a pop-up came down on the way - a question confirmed lowers itself and
## then makes the move it held, and only the move sounds - else a pop-up up
## or down, else another layer taking input.
##
## A PRESS SOUND IS A HAND'S PRESS, NEVER A COMMAND. A command running is not a
## moment: the application's own first move would click, and so would every
## console line and every dispatch a model makes for itself. The press moment is
## the one the interaction layer rings, and whether it was refused is that
## press's own answer - the door refusing a control that cannot be used, or the
## refusal the model gave once told - so a refused press plays the refused sound
## and no other. Ten presses in a frame are one: one per moment per frame.
##
## WHAT IT ASKED TO PLAY IS THE OBSERVABLE: get_played(), every [moment, style]
## it asked for, newest last and bounded, the style being the one the sound was
## FOUND under. An audio device is neither its business nor a test's.
##
## IT HANGS THE MOMENTS OF A PERSON'S HAND. HOVERED, FOCUS_MOVED and PRESSED
## are rung by every face there is (face.gd), and a face cannot hang them: there
## are many, they come and go with a screen, and the belfry refuses a second
## hanging out loud. There is one of these per application, built before any
## screen, so it hangs them once; a face rings them hung or not, since striking
## an address nobody hung is quiet by design, so an application with no sounds
## rings safely and costs nothing. The builder hanging them for every one is the
## other way - a line in ui.gd.
##
## A NOTIFICATION ARRIVING is a moment of its own, NOTIFIED, heard on the bell
## of the notifications (notifications.gd), which are built before this.
##
## THEY PLAY ON THE GAME'S BUS, the one the project names (sound_bus.gd), whose
## volume and mute are the game's and a player's choice. Muted is the bus
## muted AND nothing asked to play: either alone leaves sounds to arrive the
## moment they are turned back on.
##
## Deliberately absent: music, a sound carried across a move, ducking, and a
## sound per control rather than per style.

## How many can sound at once: a press over a move over a glow, and room to spare.
const VOICES := 6
const KEPT := 64  # how many asked-for sounds are kept for reading back

## The moments a look has a sound for; the three a hand makes are interaction.gd's bells.
const HOVERED := Interaction.HOVERED
const FOCUS_MOVED := Interaction.FOCUS_MOVED
const PRESSED := Interaction.PRESSED
const REFUSED := &"refused"
const GLOW_STARTED := &"glow_started"
const RAISED := &"raised"
const LOWERED := &"lowered"
const MOVED := &"moved"
const NOTIFIED := &"notified"

var _driver: Driver
var _bus: SoundBus
var _prompts: Prompts
var _root: Node  # where the look is: the Theme on it, read again every time
var _voices: Array[AudioStreamPlayer] = []
var _next: int = 0  # the voice the next sound is asked of, round by round
var _played: Array = []
var _sounded: Dictionary = {}  # moment -> the frame it last sounded on
var _glowing: StringName = &""  # the action that glowed when the prompts last moved
var _top: Array[StringName] = []  # the layer that took input when the driver last moved
var _path: Array = []  # the app's path when the driver last moved
var _moving: bool = false  # whether this frame's moves are waiting to be heard as one
var _raised: bool = false
var _arrived: bool = false  # whether the reader has been moved at all yet: until then nothing sounds, not even the focus it opens on


func _init(chimes: Chimes, driver: Driver, prompts: Prompts, under: Node, bus: SoundBus) -> void:
	super(chimes, [], Chimes.GLOBAL)
	_driver = driver
	_prompts = prompts
	_root = under
	_bus = bus
	# the moments of a person's hand, hung here because the faces that ring them cannot
	for moment: StringName in [HOVERED, FOCUS_MOVED, PRESSED]:
		register_bell(moment)
	listen([[Chimes.GLOBAL, Driver.NAVIGATED], [Chimes.GLOBAL, Prompts.PROMPT_MOVED], [Chimes.GLOBAL, HOVERED], [Chimes.GLOBAL, FOCUS_MOVED], [Chimes.GLOBAL, PRESSED], [Chimes.GLOBAL, Notifications.ARRIVED]])
	# a voice for each sound that may overlap, built here so nothing is connected and nothing is found by name
	for voice: int in VOICES:
		var player := AudioStreamPlayer.new()
		player.bus = bus.named
		_voices.append(player)
		add_child(player)


## A bell rang: the moment it means, read from whoever rang it.
func heard(what: StringName) -> void:
	match what:
		PRESSED: _pressed()
		FOCUS_MOVED when _arrived: _play(FOCUS_MOVED, _style_now())
		HOVERED: _play(HOVERED, &"")
		Driver.NAVIGATED: _moved()
		Prompts.PROMPT_MOVED: _glowed()
		Notifications.ARRIVED: _play(NOTIFIED, &"")


## Every sound it asked for, as [moment, style], newest last.
func get_played() -> Array:
	return _played.duplicate()


## A press landing, read off the control it landed on: the door refusing it, or
## the refusal the model gave once told, is the refused sound, and anything
## else the press sound. A local press asks no door and is never refused.
func _pressed() -> void:
	var on := Interaction.get_pressed()
	var refused: bool = on is ActionControl and (not (on as ActionControl).is_usable() or (on as ActionControl).get_refusal() != null)
	_play(REFUSED if refused else PRESSED, on.theme_type_variation)


## The reader moved: heard once, at the frame's end, however many moves rang.
func _moved() -> void:
	if not _moving:
		_moving = true
		_sound_the_move.call_deferred()


## The frame's moves as one: the app's path moved, else a pop-up up or down,
## else another layer taking input. The first is the application opening and
## sounds nothing: what is first shown is simply there, and nobody moved to it.
func _sound_the_move() -> void:
	_moving = false
	var path: Array = _driver.get_state()["path"]
	var top := _driver.get_top()
	var raised := _driver.is_raised()
	if _arrived and path != _path:
		_play(MOVED, &"")
	elif _arrived and raised != _raised:
		_play(RAISED if raised else LOWERED, &"")
	elif _arrived and top != _top:
		_play(MOVED, &"")
	_arrived = true
	_path = path
	_raised = raised
	_top = top


## The prompts moved: a glow STARTED where there was none or another, and
## nothing while it stays where it is.
func _glowed() -> void:
	var glowing := _prompts.get_glowing()
	if glowing != &"" and glowing != _glowing:
		_play(GLOW_STARTED, &"")
	_glowing = glowing


## One sound asked for: nothing while muted, nothing twice in a frame for one
## moment, and nothing where the look has none for it.
func _play(moment: StringName, style: StringName) -> void:
	var frame := Engine.get_process_frames()
	if _bus.muted.read() or _sounded.get(moment) == frame:
		return
	var found := LookSounds.get_sound(Look.worn_by(_root), moment, style)
	if found.is_empty():
		return
	_sounded[moment] = frame
	_played.append([moment, found["style"]])
	if _played.size() > KEPT:
		_played.pop_front()
	var voice := _voices[_next]
	_next = (_next + 1) % VOICES
	voice.stream = found["stream"]
	voice.play()


## The style worn by the control the focus is on - the engine's answer to
## which control a press or a walk was for - and nothing where none is.
func _style_now() -> StringName:
	var on := get_viewport().gui_get_focus_owner()
	return on.theme_type_variation if on != null else &""


## Leaving the tree, every voice stopped and emptied: the mixer holds a playback
## of its own, and a stop once a player is out of the tree does nothing.
func _notification(what: int) -> void:
	if what == NOTIFICATION_EXIT_TREE:
		# every voice, stopped and emptied whether it is sounding or not
		for voice: AudioStreamPlayer in _voices:
			voice.stop()
			voice.stream = null