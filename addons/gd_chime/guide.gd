extends "controller.gd"

const Commands := preload("commands.gd")
const Actions := preload("actions.gd")
const Prompts := preload("prompts.gd")
const Driver := preload("driver.gd")

## The guided steps: one action at a time, pointed at from wherever the
## player is, and moved on when they take it.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## It is one source of the prompts - named first when the prompts were built,
## so a step wins over a reminder - built with the commands, the register of
## actions, the prompts, the name of its source, its STEPS and the driver. The steps are content handed in: an array of actions, in
## order, each an action in the register - a name that is no action is
## refused out loud and left out, so a step can never point at nothing.
## Whether some control performs each is the startup check's, over the tree.
##
## The current step is raised as the way to it from everything the player
## can reach, which is asked of the index, the chart and the driver's state
## (queries.gd), by making the moves on copies of the state: the step's action itself when a control that can be reached
## performs it, else the first action on the shortest way there over the
## links, Back among them - the player is led back to the path from wherever
## they wandered, and out of a pop-up. Whatever is raised, the step or a hop
## on the way, is read in the register's words for that action, so the bar
## says what the glowing control does. When no way exists from where they
## are, nothing is raised until they arrive somewhere a way exists from. It
##
## It hears the commands: the step's action, done, moves it on to the next
## step - a value (value.gd); a refused command, or any other action,
## changes nothing. It FOLLOWS WHAT THE WAY READ (reads.gd) - where the
## reader is, and the game's refusals asked on the way - so the screen
## changing, or a game fact a refusal reads moving, raises the way again
## from there, and nothing is listed. Past the last step it withdraws and is
## finished, and stays so.
##
## get_step() is the step it is on, for whatever saves the player's place;
## start_at(step) resumes there. The player is
## never blocked: a step is a prompt, and nothing here gates a command.
##
## Deliberately absent: a step that waits for an outcome rather than a
## command, and the rhythm of a glow.

var _commands: Commands
var _prompts: Prompts
var _source: StringName
var _steps: Array[StringName] = []  # the actions, in order, each in the register
var _driver: Driver
var _step := value(0)


func _init(chimes: Chimes, commands: Commands, actions: Actions, prompts: Prompts, source: StringName, steps: Array, driver: Driver) -> void:
	super(chimes, [[Chimes.GLOBAL, Commands.COMMAND_RAN]], Chimes.GLOBAL)
	_commands = commands
	_prompts = prompts
	_source = source
	_driver = driver
	# every step handed in, kept if it is an action, refused out loud if not
	for step: StringName in steps:
		if actions.has(step):
			_steps.append(step)
		else:
			push_error("the guide's step %s is no action, so it is left out" % step)


## The first step is pointed at as this arrives, once everything is in the index.
func _ready() -> void:
	follow(&"way", _point)


## The step it is on: 0 for the first, the number of steps once finished.
func get_step() -> int:
	return _step.read()


func is_finished() -> bool:
	return _step.read() >= _steps.size()


## Resume at a saved step, pointing at it.
func start_at(step: int) -> void:
	_step.set_value(step)
	follow(&"way", _point)


## A command ran: the step's action done moves on and points the way to the
## next; any other command changes nothing.
func heard(_what: StringName) -> void:
	var ran := _commands.get_last()
	if is_finished() or ran["action"] != _steps[_step.read()] or ran["answer"] != null:
		return
	_step.set_value(_step.read() + 1)
	follow(&"way", _point)


## The way to the current step from everything that can be reached raised -
## its first action - or nothing when finished or no way exists.
func _point() -> void:
	if is_finished():
		_prompts.withdraw(_source)
		return
	var the_way := _driver.route(_steps[_step.read()])
	if the_way.is_empty():
		_prompts.withdraw(_source)
		return
	_driver.check_drawn(the_way[0])
	_prompts.raise(_source, the_way[0])
