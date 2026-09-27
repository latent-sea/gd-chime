extends "controller.gd"

const Actions := preload("actions.gd")
const Driver := preload("driver.gd")
const Saved := preload("saved_inputs.gd")
const SaveShape := preload("save_shape.gd")
const Conflicts := preload("input_conflicts.gd")

## The map from inputs to actions: which key or pad button presses which
## action, which device the player is on, and what a rebinding changed.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## AN INPUT IS A KEY OR A PAD BUTTON, AND IT SAYS WHICH IT IS: {"key": KEY_S}
## or {"pad": JOY_BUTTON_Y}, made by the register's keys() and pad()
## (actions.gd), where an action is declared with the inputs it is on; a key
## held with its modifiers is one input, the engine's one number for them -
## so K and Ctrl+K press two actions, and one reads "Ctrl+K". The numberings
## overlap - JOY_BUTTON_Y is 3, and so is KEY_TAB - so an integer on its own
## cannot be told apart, and a map that guessed from the number would put a
## pad button on a key's action in silence.
##
## THE DEFAULTS ARE THE REGISTER'S (actions.gd), read as this is built and
## again whenever they are restored: what presses an action is one fact about
## the action, said once beside its words. What is bound NOW is this and
## nothing else, and nobody reads a live binding off the register. An action
## holds at most one input per device, so binding a key replaces the key it
## was on and leaves its pad button alone.
##
## THE DEVICE is whichever the player last used, moved by whoever sees input
## (shortcuts.gd) and read by a hint, so a control shows the key on a keyboard
## and the button on a pad, and never both.
##
## TWO VALUES (value.gd): what is bound, which moves with a binding, a
## restore of the defaults or a save read back; and the device, which moves
## when the player changes device. A hint reads both, so whatever shows one
## follows both, and whatever keeps the settings follows what is bound as
## it reads the save. Two commands, BINDS {action, event} and RESTORES_DEFAULTS, so the
## player changes a binding through the same door as everything else, and a
## binding that names no action is refused where the press happened. A
## binding control asks the door AT REST, before any key has arrived, with
## the action alone (key_capture.gd), so the event is checked only where one
## is carried.
##
## SAVING IS THE GAME'S: saved() hands out plain data and restore() takes it
## back (saved_inputs.gd), so whatever keeps settings writes and reads a
## Dictionary and this never opens a file.
##
## A CONFLICT IS REPORTED, NOT PREVENTED (input_conflicts.gd): asked whenever a
## binding lands, and once at startup for the defaults, by whoever is in the
## tree to know that the places are there.
##
## Deliberately absent: which control an input presses, which is the shortcut
## node's (shortcuts.gd); two keys one after another; and writing to disk.

## The two this is told, which whoever composes the application registers.
const BINDS := &"binds_an_input"
const RESTORES_DEFAULTS := &"restores_the_default_inputs"
const COMMANDS: Array[StringName] = [BINDS, RESTORES_DEFAULTS]
## The two devices, which are also the one key an input carries.
const KEY := Saved.KEY
const PAD := Saved.PAD
## What a pad button is called, until a look hands back its glyphs.
const PAD_NAMES := {
	JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_START: "Start", JOY_BUTTON_BACK: "Select",
	JOY_BUTTON_DPAD_UP: "Up", JOY_BUTTON_DPAD_DOWN: "Down",
	JOY_BUTTON_DPAD_LEFT: "Left", JOY_BUTTON_DPAD_RIGHT: "Right",
}

var _actions: Actions
var _driver: Driver
var _bound := value({})  # action -> the inputs it is on now, at most one per device
var _device := value(KEY)  # the device the player last used


func _init(chimes: Chimes, register: Actions, moves: Driver) -> void:
	super(chimes, [], Chimes.GLOBAL)
	_actions = register
	_driver = moves
	_take_defaults()


## --- what an input is ---

## The input a key press or a pad press is - a key with the modifiers held
## as it went down; nothing for any other event.
static func of_event(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		return {KEY: (event as InputEventKey).get_keycode_with_modifiers()}
	if event is InputEventJoypadButton:
		return {PAD: (event as InputEventJoypadButton).button_index}
	return {}


## What an input is called, as a phrase the text says in the language on: a
## key's name as the engine writes it and a pad button's as we do, each a
## name; and a button no pad we know of has, words with its number as data.
static func words_of(input: Dictionary) -> Phrase:
	if input.has(KEY):
		return Phrase.named(OS.get_keycode_string(input[KEY]))
	return Phrase.named(PAD_NAMES[input[PAD]]) if PAD_NAMES.has(input[PAD]) else Phrase.with("Button %d", [input[PAD]])


## --- what is bound ---

## The actions this input presses, in the order declared: none, one, or
## several that are never reached at once - every pop-up's way out and an
## app's own Back on one key - a conflict between two that are having been
## said out loud.
func get_actions(input: Dictionary) -> Array[StringName]:
	var bound: Dictionary = _bound.read()
	var on: Array[StringName] = []
	# every action whose inputs hold this one
	for action: StringName in bound:
		if (bound[action] as Array).has(input):
			on.append(action)
	return on


## The inputs an action is on now.
func get_inputs(action: StringName) -> Array:
	return _bound.read()[action]


## An input bound to an action, replacing whatever that action was on for the
## same device and leaving the other device alone.
func bind(action: StringName, input: Dictionary) -> void:
	var bound: Dictionary = _bound.read()
	var kept: Array = []
	# the action's inputs, keeping those of the other device
	for other: Dictionary in bound[action]:
		if not other.has(input.keys()[0]):
			kept.append(other)
	kept.append(input)
	bound[action] = kept
	_bound.set_value(bound)
	report_conflicts()


## Every action back on the inputs it was declared with.
func restore_defaults() -> void:
	_take_defaults()


## Every pair of actions on one input that can be reached at once, said out
## loud. Asked as a binding lands, and once by whoever is in the tree at
## startup, when the places the question is asked over are all there.
func report_conflicts() -> void:
	Conflicts.report(_bound.read(), _driver.index.chart(), _driver.index.performs(), words_of)


## --- the device the player is on ---

## An input the player used, seen by whoever watches input: the device moves
## with it, and the hints follow.
func used(input: Dictionary) -> void:
	var device: String = input.keys()[0]
	if device != _device.read():
		_device.set_value(device)


func get_device() -> String:
	return _device.read()


## What an action is pressed by on the device the player is on, a phrase, or
## nothing when it is on none.
func get_hint(action: StringName) -> Phrase:
	# the action's inputs, for the one of the device in use
	for input: Dictionary in get_inputs(action):
		if input.has(_device.read()):
			return words_of(input)
	return null


## A hint as a bound value: it reads what is bound and the device, so
## whatever shows it follows both in place.
func hint(action: StringName) -> Bound:
	return Bound.new(func() -> Phrase: return get_hint(action))


## --- the commands ---

## A binding that names no action of the register, or an event that is neither
## a key nor a pad button, is refused where the press happened; asked at rest,
## with no event yet, only the action is.
func would(action: StringName, payload: Dictionary) -> Phrase:
	if action != BINDS:
		return null
	if not _actions.has(payload["action"]):
		return Phrase.with("%s is no action to bind", [payload["action"]])
	if payload.has("event") and of_event(payload["event"]).is_empty():
		return Phrase.of("That is neither a key nor a pad button")
	return null


func told(action: StringName, payload: Dictionary) -> Phrase:
	if action == BINDS:
		bind(payload["action"], of_event(payload["event"]))
	else:
		restore_defaults()
	return null


## --- saving, which is the game's ---

## Every action that is on an input, as plain data for whatever keeps settings.
func saved() -> Dictionary:
	return Saved.written(_bound.read())


## Bindings read back from a save: every action it names put back on what it
## was saved on, every action it does not left on its default. What is not a
## set of bindings at all is said out loud and the defaults kept whole.
func restore(save: Dictionary) -> void:
	_take_defaults()
	var bound: Dictionary = _bound.read()
	if not SaveShape.refused(Saved.shape(bound), save, "a set of bindings"):
		# every action the save names, back on what it was saved on
		for named: String in save:
			bound[StringName(named)] = Saved.inputs_of(save[named])
	_bound.set_value(bound)


func _take_defaults() -> void:
	var bound: Dictionary = {}
	# every action declared, on the inputs it was declared with
	for action: StringName in _actions.get_all():
		bound[action] = _actions.get_inputs(action).duplicate(true)
	_bound.set_value(bound)
