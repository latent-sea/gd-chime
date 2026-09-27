extends SceneTree

const ChimeApp := preload("chime_app.gd")
const Belfry := preload("belfry.gd")
const Language := preload("language.gd")
const Motion := preload("motion.gd")
const Look := preload("look.gd")
const Shortcuts := preload("shortcuts.gd")
const Chimes := preload("chimes.gd")
const Driver := preload("driver.gd")
const Commands := preload("commands.gd")
const Actions := preload("actions.gd")
const Prompts := preload("prompts.gd")
const Inputs := preload("input_map.gd")
const Notifications := preload("notifications.gd")
const Sounds := preload("sounds.gd")
const FrameBudget := preload("frame_budget.gd")
const Jobs := preload("jobs.gd")
const Ui := preload("components/primitives/ui.gd")
const Controller := preload("controller.gd")
const Desc := preload("components/primitives/desc.gd")
const Themes := preload("theme.gd")
const NeededSettings := preload("needed_settings.gd")

## An application run with --script: the main loop that puts one app node
## (chime_app.gd) over the whole window and stands in for it. The demos and
## the probes are this; a game hosts the node in a scene instead.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THERE IS ONE IMPLEMENTATION, and it is the node's. This makes a ChimeApp
## as it starts, names itself as the one `asked` the five questions - look(),
## sources(), declare(actions), describe(), probe(), each answered here with
## the node's own default - and puts it under the root across the whole
## window. The node builds everything and tells this wired() as the pieces
## come up, so an application extending this reads `chimes`, `commands`,
## `ui` and the rest exactly as it did when the wiring was here.
##
## THE WINDOW IS RUN THE FRAMEWORK'S WAY: this is the one caller of
## GdChime.apply_project_settings(), before the node enters, so the window
## is not stretched and the easel scales at real pixels - the choice a
## project makes by running its application this way.
##
## What is this main loop's alone: the settings file asked for at launch,
## settings_path(), which reads the command line, as a node never does.

## What may be asked for at launch: a settings file of the reader's own.
const SETTINGS_SWITCH := "--settings="
## The walk in place of a reader, which the node begins (chime_app.gd).
const PROBE_SWITCH := ChimeApp.PROBE_SWITCH

var app: ChimeApp
var chimes: Chimes
var driver: Driver
var commands: Commands
var actions: Actions
var prompts: Prompts
var inputs: Inputs
var notifications: Notifications
var sounds: Sounds
var budget: FrameBudget
var jobs: Jobs
var ui: Ui


func _init() -> void:
	NeededSettings.apply(root)
	app = ChimeApp.new()
	app.asked = self
	app.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(app)


## The node's pieces as they come up, held here so an application's own
## declare() and describe() read them by the names they always had.
func wired(node: ChimeApp) -> void:
	chimes = node.chimes
	driver = node.driver
	commands = node.commands
	actions = node.actions
	prompts = node.prompts
	inputs = node.inputs
	notifications = node.notifications
	sounds = node.sounds
	budget = node.budget
	jobs = node.jobs
	ui = node.ui


## A model of the application, stood up beside the app (chime_app.gd).
func model(made: Controller) -> Controller:
	return app.model(made)


## The look on the canvas: the node's default unless the application says.
func look() -> Theme:
	return app.look()


## The prompts' sources: none unless the application says.
func sources() -> Array[StringName]:
	return app.sources()


## The register's actions and their words: none unless the application says.
func declare(register: Actions) -> void:
	app.declare(register)


## The app's description, its models made on the way, and its pop-ups
## described where they are used.
func describe() -> Desc:
	return app.describe()


## The walk that stands in for a reader: none unless the application says.
func probe() -> RefCounted:
	return app.probe()


## The settings file asked for at launch, else the application's own - or,
## probing, the probe's own, begun empty, so a reader's is never touched.
func settings_path(own: String, probed: String) -> String:
	# every argument after the engine's, for the settings file named
	for given: String in OS.get_cmdline_user_args():
		if given.begins_with(SETTINGS_SWITCH):
			return given.trim_prefix(SETTINGS_SWITCH)
	if OS.get_cmdline_user_args().has(PROBE_SWITCH):
		DirAccess.remove_absolute(probed)
		return probed
	return own
