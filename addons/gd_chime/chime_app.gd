extends "easel.gd"
class_name ChimeApp

const Belfry := preload("belfry.gd")
const Chimes := preload("chimes.gd")
const Driver := preload("driver.gd")
const Commands := preload("commands.gd")
const Actions := preload("actions.gd")
const Prompts := preload("prompts.gd")
const Inputs := preload("input_map.gd")
const Language := preload("language.gd")
const Motion := preload("motion.gd")
const Look := preload("look.gd")
const Shortcuts := preload("shortcuts.gd")
const Notifications := preload("notifications.gd")
const Sounds := preload("sounds.gd")
const SoundBus := preload("sound_bus.gd")
const FrameBudget := preload("frame_budget.gd")
const Jobs := preload("jobs.gd")
const Ui := preload("components/primitives/ui.gd")
const Controller := preload("controller.gd")
const Desc := preload("components/primitives/desc.gd")
const NeededSettings := preload("needed_settings.gd")

## An application as a node: added anywhere in a scene, it builds the whole
## application under itself, on its own easel, and takes it away when it
## leaves. The standard wiring every application does, done once.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## IT IS THE ONE NAME BESIDE GdChime. An application is a script that
## `extends ChimeApp`, and a class cannot extend a name it reads through
## the facade, so this one is global: what an application may use is
## exactly what gd_chime.gd re-exports, plus this (CONSTITUTION.md).
##
## ENTERING THE TREE, it puts the look on its canvas - the ground painted
## from it, where nothing draws - makes the chimes, the driver, the door,
## the register and the prompts - the prompts registered for their own two
## commands from anywhere - and the builder over all of them, the look
## dressed for the language on once there is one (look.gd); then it asks
## for the application's description and starts it. An application extends
## this and answers five questions, each with a default: look(), the Theme
## the canvas wears; sources(), the prompts' sources; declare(actions), the
## register's actions and their words, in one table (actions.gd);
## describe(), the app's description, where it also makes its models and
## describes each pop-up where it is used - the builder lifts it beside the
## app (ui.gd); and probe(), the walk that stands in for a reader. It
## composes and never listens. The notifications (notifications.gd) are
## made before the sounds that hear one arrive; describe() notifies through
## them and draws them where its layout leaves room (notification_tray.gd).
##
## IT OWNS EXACTLY ITS OWN SUBTREE. It never writes a project setting, the
## window's stretch mode or base size, the clear colour or the input map:
## it reads the settings it relies on as it enters and says once what is
## missing (needed_settings.gd), and GdChime.apply_project_settings() is the
## one explicit way to set them. So a game hosts one beside its own scenes,
## and two in one window have nothing to fight over - each on its own
## easel, in its own shape, wearing its own look.
##
## ITS LIFE IS THE NODE'S. It is built as it enters the tree, and leaving
## the tree takes down everything it built - the job pool's tasks waited
## out, and everything under the canvas freed; nothing outside was touched,
## so nothing outside is undone. Coming back, or moved under another
## parent, it is built afresh, once. A broken description is said out loud
## and the app stands empty: it never quits the game.
##
## THE QUESTIONS MAY BE ANSWERED BY ANOTHER: `asked` is whoever answers the
## five, this node unless something stands in - the demos' main loop
## (application.gd), a SceneTree whose script is the application, so that
## one implementation serves an app node in a scene and a script run with
## --script alike. Whoever stands in is told wired() as the pieces come
## up, before each question that needs them, and broken(faults) where the
## description's tree is broken.
##
## WHAT EVERY APPLICATION HAD A COPY OF IS A DEFAULT HERE: the frame's
## budget, measured against the display's own rate (frame_budget.gd); one
## job pool reading that budget (jobs.gd); and the probe, made and begun
## once the interface stands, so it walks what a reader would find rather
## than what describe() was half way through making.

## How much of a frame the application's own work may take, and how many
## frames in a row decide it has gone over that or come back within it.
const FRAME_SHARE := 0.9
const FRAME_RUN := 3
## The rate the budget is measured against where the display does not say its own.
const FRAME_RATE := 60.0
## How many jobs of the application's pool run at once, and how many wait
## behind them: enough for the heaviest of them - a page of pictures painted
## as a collection is scrolled - since the budget gates what starts anyway.
const JOBS_AT_ONCE := 3
const JOBS_WAITING := 64
## What may be asked for at launch: a walk in place of a reader.
const PROBE_SWITCH := "--probe"

## Whoever answers the five questions: this node, or the main loop standing in for it.
var asked: Object = self
var chimes: Chimes
var driver: Driver
var commands: Commands
var actions: Actions
var prompts: Prompts
var inputs: Inputs
var notifications: Notifications
var sound_bus: SoundBus
var sounds: Sounds
var budget: FrameBudget
var jobs: Jobs
var ui: Ui
var _probe: RefCounted  # held while it walks: a walk waiting on a frame is dropped with whatever was holding it


## Entering the tree, the whole application built under the canvas; leaving
## it, all of it taken down. In _notification, which every script in the
## chain is called for, where an application's own _enter_tree would
## replace the build. Nothing built here stands outside the canvas, so
## freeing what stands under it takes the models and their registrations
## with the door, the places and the pop-ups, and the bells with the chimes.
func _notification(what: int) -> void:
	if what == NOTIFICATION_EXIT_TREE:
		# the pool's tasks waited out first, since a task done and never waited brings the game down at its end
		jobs.stop()
		var built := canvas.get_children()
		built.reverse()
		# everything built, newest first, so what was built over a model goes before the model it tells
		for node: Node in built:
			node.free()
		_probe = null
		ui = null
		chimes = null
		return
	if what != NOTIFICATION_ENTER_TREE:
		return
	NeededSettings.report()
	canvas.theme = asked.look()
	chimes = Chimes.new(Belfry.new())
	driver = Driver.new(chimes)
	commands = Commands.new(chimes, driver)
	actions = Actions.new()
	# the notifications before the application is asked anything, so a model it makes as it declares can be given them
	notifications = Notifications.new(chimes, commands, canvas)
	commands.register(Chimes.GLOBAL, Notifications.DISMISSES, notifications)
	asked.wired(self)
	asked.declare(actions)
	prompts = Prompts.new(chimes, actions, asked.sources())
	# the prompts answer their own muting from anywhere
	commands.register(Chimes.GLOBAL, Prompts.MUTES, prompts)
	commands.register(Chimes.GLOBAL, Prompts.UNMUTES, prompts)
	# the builder before the map of inputs, which reads the register: the builder declares every pop-up's way out
	ui = Ui.new(canvas, chimes, commands, driver, prompts, actions)
	inputs = Inputs.new(chimes, actions, driver)
	# the map of inputs answers its own two commands from anywhere
	for action: StringName in Inputs.COMMANDS:
		commands.register(Chimes.GLOBAL, action, inputs)
	# the game's bus answers a player's volume and muting from anywhere
	sound_bus = SoundBus.new(chimes)
	for action: StringName in SoundBus.COMMANDS:
		commands.register(Chimes.GLOBAL, action, sound_bus)
	# the sounds after the notifications, whose arriving rings the look's sound
	sounds = Sounds.new(chimes, driver, prompts, canvas, sound_bus)
	ui.inputs = inputs
	# the look put on dressed for the language on, now there is one: its font for that language's script
	Look.dress(canvas.theme, Language.written_in())
	# the language answers its own change from anywhere
	commands.register(Chimes.GLOBAL, Language.CHANGES_LANGUAGE, ui.language)
	# the clock answers reduced motion from anywhere, so a settings row turns it
	commands.register(Chimes.GLOBAL, Motion.REDUCES, ui.motion)
	var rate := DisplayServer.screen_get_refresh_rate()
	# the frame measured against the display's own rate, or sixty where it does not say - headless, and some virtual displays
	budget = FrameBudget.new(chimes, 1000.0 / (rate if rate > 0.0 else FRAME_RATE), FRAME_SHARE, FRAME_RUN)
	jobs = Jobs.new(chimes, budget, JOBS_AT_ONCE, JOBS_WAITING, false)
	for node: Node in [driver, commands, prompts, inputs, notifications, sound_bus, sounds, budget, jobs, Shortcuts.new(inputs, driver, commands)]:
		ui.also(node)
	asked.wired(self)
	ui.start(asked.describe(), asked.broken)
	# the walk begun once everything stands; it waits its own frames, so it is simply begun
	if OS.get_cmdline_user_args().has(PROBE_SWITCH):
		_probe = asked.probe()
		_probe.run()


## A model of the application: put in the tree beside it, and told every
## action it answers (controller.gd) from anywhere. A model that answers for
## ONE PLACE is handed to that place instead - ui.screen(named, content,
## model) - and is told its actions there, so a region is never written here.
## The model comes back, for the application to hold. Something that is not
## a model - a far side the application stands in for, the developer's
## console - goes beside the app with ui.also instead.
func model(made: Controller) -> Controller:
	ui.also(made)
	commands.stand(Chimes.GLOBAL, made)
	return made


## The pieces so far, for whoever stands in for this node to hold: nothing, when nobody does.
func wired(_app: Node) -> void:
	pass


## The look on the canvas: the floor's neutral one unless the application says.
func look() -> Theme:
	return Themes.new(Themes.NEUTRAL)


## The prompts' sources: none unless the application says.
func sources() -> Array[StringName]:
	return []


## The register's actions and their words: none unless the application says.
func declare(_actions: Actions) -> void:
	pass


## The app's description, its models made on the way, and its pop-ups
## described where they are used.
func describe() -> Desc:
	return ui.app(&"app", [])


## The walk that stands in for a reader, made once the interface stands and
## begun where --probe was asked for: none unless the application says.
func probe() -> RefCounted:
	return null


## The description's tree is broken, each fault said out loud already: the
## app stands empty, and nothing more unless whoever stands in says - the
## demos' main loop quits (application.gd). An app never quits the game.
func broken(_faults: Array) -> void:
	pass
