extends "controller.gd"

const Commands := preload("commands.gd")
const Actions := preload("actions.gd")

## Which of the interface's actions the player has ever taken, and which of
## them are worth asking about.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Whether the player has ever TAKEN an action is a flag, one per action and
## never per part: three parts that all start the same thing are one fact, so
## taking it from any of them takes it. The actions are the register's
## (actions.gd) - it is built with the register, and a name that is no action
## cannot be tracked or taken. Whether any control performs an action is the
## startup check's, over the tree.
##
## Only tracked actions are asked about, which keeps what has never been done
## a short chosen list rather than every action there is. An action is
## tracked once however many parts perform it; what it does is the register's, in
## the words the action was declared with, so this holds none. Tracking a
## name that is no action is refused out loud, so a misspelt action cannot
## sit untaken forever with nothing to point at. Tracking chooses what is asked about and
## nothing more: an action taken before it was tracked has still been taken.
##
## An action is taken on the command stream, not inside a control: this hears
## the commands' COMMAND_RAN and takes the action of the command that ran if
## the model did it and some part performs it. A refused command, or a wheel's
## scroll no part performs, records nothing. No control tells this anything.
##
## The flags are the only thing here that changes while the application runs:
## a value (value.gd), handed what the database held, and set again the first
## time an action is taken - the only time a flag changes - so whatever keeps
## the database follows get_taken() and writes it, and whatever reminds
## follows untaken(). The database itself is outside this folder, which
## never reads or writes one.
##
## There is one of these and it outlives every screen, so it stands in the
## global region: closing a screen never takes it away.

var _actions: Actions
var _commands: Commands
var _tracked: Dictionary = {}  # the actions worth asking about, used as a set that keeps the order tracked
var _taken := value({})  # actions the player has ever taken, used as a set


func _init(chimes: Chimes, actions: Actions, commands: Commands) -> void:
	super(chimes, [[Chimes.GLOBAL, Commands.COMMAND_RAN]], Chimes.GLOBAL)
	_actions = actions
	_commands = commands


## Mark an action as one worth asking whether it has ever been taken -
## refused out loud when it is no action.
func track(action: StringName) -> void:
	if not _actions.has(action):
		push_error("%s is no action, so it cannot be tracked" % action)
		return
	_tracked[action] = true


## Every action the player has ever taken, as the database held them. They
## replace whatever was held.
func set_taken(actions: Array[StringName]) -> void:
	var taken: Dictionary = {}
	# every action the database held as taken
	for action: StringName in actions:
		taken[action] = true
	_taken.set_value(taken)


## A command ran: if the model did it and a part performs it, its action is taken.
func heard(_what: StringName) -> void:
	var ran := _commands.get_last()
	if ran["answer"] == null and _actions.has(ran["action"]):
		take(ran["action"])


## Record that the player has taken an action, set the first time they do.
func take(action: StringName) -> void:
	var taken: Dictionary = _taken.read()
	if not taken.has(action):
		_taken.set_value(taken.merged({action: true}))


## The tracked actions the player has never taken, in the order they were tracked.
func untaken() -> Array[StringName]:
	var never: Array[StringName] = []
	var taken: Dictionary = _taken.read()
	# every tracked action, keeping the ones never taken
	for action: StringName in _tracked:
		if not taken.has(action):
			never.append(action)
	return never


## Every action the player has ever taken, each once, for whatever keeps the database.
func get_taken() -> Array[StringName]:
	var taken: Array[StringName] = []
	# the set's members, as the typed list the database is written from
	taken.assign(_taken.read().keys())
	return taken
