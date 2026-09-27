extends RefCounted

const Belfry := preload("res://addons/gd_chime/belfry.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Commands := preload("res://addons/gd_chime/commands.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Actions := preload("res://addons/gd_chime/actions.gd")
const Prompts := preload("res://addons/gd_chime/prompts.gd")
const Inputs := preload("res://addons/gd_chime/input_map.gd")
const Language := preload("res://addons/gd_chime/language.gd")
const Motion := preload("res://addons/gd_chime/motion.gd")
const Shortcuts := preload("res://addons/gd_chime/shortcuts.gd")
const Controller := preload("res://addons/gd_chime/controller.gd")
const Ui := preload("res://addons/gd_chime/components/primitives/ui.gd")
const Easel := preload("res://addons/gd_chime/easel.gd")

## A builder for the tests: the chimes, the door, the driver, the prompts
## and a register, wired as an application wires them, and freed together.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## IT BUILDS ON THE ROOT IT IS GIVEN - the window, for nearly every test,
## so what a test adds beside the fixture's nodes stands where they do and
## the look set on the window is read by all of it. A test that asserts the
## base turning, or a phone's canvas, hands it an easel's canvas instead
## (easel.gd), as an application builds on, and the window's own pixels are
## then the easel's rect.

## What a headless window measures, unasked: after its first frame, and before it.
const HEADLESS := Vector2i(64, 64)
const UNMEASURED := Vector2i(100, 100)

var chimes: Chimes
var commands: Commands
var driver: Driver
var actions: Actions
var prompts: Prompts
var inputs: Inputs
var ui: Ui


## A model that does what it is told, refuses what it was set to, and
## holds whatever values it is given, each by a name.
class Model extends Controller:
	var told_actions: Array[StringName] = []
	## Every action this is told: what the test said it answers, so a place
	## handed several models stands this up for its own (place_builder.gd).
	var answering: Array[StringName] = []
	var _refused := value({})  # action -> the refusal
	var _named: Dictionary = {}  # name -> the value held under it

	func _init(chimes: Chimes, in_region: StringName = Chimes.GLOBAL) -> void:
		super(chimes, [], in_region)

	func answers() -> Array[StringName]:
		return answering

	func would(action: StringName, _payload: Dictionary) -> Phrase:
		return _refused.read().get(action)

	## A press of this action refused from now on, for this reason - or, given none, no longer.
	func refuse(action: StringName, why: Variant) -> void:
		var refused: Dictionary = _refused.read()
		refused[action] = why
		_refused.set_value(refused)

	func told(action: StringName, _payload: Dictionary) -> Phrase:
		told_actions.append(action)
		return null

	## The value held under this name, declared holding this the first time it is asked for.
	func of(name: StringName, first: Variant = null) -> Value:
		if not _named.has(name):
			_named[name] = value(first)
		return _named[name]

	## The three values most tests hold, read by name.
	func get_items() -> Variant:
		return of(&"items").read()

	func get_flag() -> Variant:
		return of(&"flag").read()

	func get_words() -> Variant:
		return of(&"words").read()

	## Nothing refused any more.
	func refuse_nothing() -> void:
		_refused.set_value({})

	## The value under this name set.
	func set_value(name: StringName, to: Variant) -> void:
		of(name).set_value(to)


## Counts how often what a read reads moves: it follows the read, and each
## ring after the first reading is one - so a model's values moving, or an
## event bell the read notes, is something a test can count.
class Heard extends Controller:
	var rung: int = -1

	func _init(chimes: Chimes, read: Callable) -> void:
		super(chimes)
		follow(&"heard", func() -> void:
			read.call()
			rung += 1)


func _init(root: Node, declared: Dictionary = {}) -> void:
	# the root window answers get_window() with nothing before its first frame (measured on 4.6.2), so the window is the root itself where the root is one
	var window: Window = root if root is Window else root.get_window()
	# a headless window is 100 by 100 before its first frame and 64 by 64 after, neither a test's, and is no longer stretched to a base, so a test stands in a window of the project's size unless it gave the window one
	if window.size == HEADLESS or window.size == UNMEASURED:
		window.size = Vector2i(ProjectSettings.get_setting(Easel.WIDTH), ProjectSettings.get_setting(Easel.HEIGHT))
	chimes = Chimes.new(Belfry.new())
	driver = Driver.new(chimes)
	commands = Commands.new(chimes, driver)
	actions = Actions.new()
	var table: Dictionary = {}
	# every action the test declared, its words alone
	for action: StringName in declared:
		table[action] = [declared[action]]
	actions.declare_all(table)
	prompts = Prompts.new(chimes, actions, [&"guide"])
	# the builder before the map of inputs, which reads the register the builder declares every pop-up's way out in
	ui = Ui.new(root, chimes, commands, driver, prompts, actions)
	inputs = Inputs.new(chimes, actions, driver)
	for action: StringName in Inputs.COMMANDS:
		commands.register(Chimes.GLOBAL, action, inputs)
	ui.inputs = inputs
	commands.register(Chimes.GLOBAL, Language.CHANGES_LANGUAGE, ui.language)
	commands.register(Chimes.GLOBAL, Motion.REDUCES, ui.motion)
	# nothing moves unless a test is about motion, and says so: what is read straight after a change is what is there
	ui.motion.still = true
	for node: Node in [driver, commands, prompts, inputs, Shortcuts.new(inputs, driver, commands)]:
		root.add_child(node)


func done() -> void:
	# everything under the root, newest first, so what was built over a model goes before the model it tells
	var children := ui.root.get_children()
	children.reverse()
	for child: Node in children:
		if child != driver and child != commands and child != prompts and child != inputs:
			child.free()
	inputs.free()
	prompts.free()
	driver.free()
	commands.free()
