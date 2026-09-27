extends "controller.gd"

const Taken := preload("taken.gd")
const Prompts := preload("prompts.gd")
const Driver := preload("driver.gd")
const Commands := preload("commands.gd")
const Reads := preload("reads.gd")

## Reminds the player of an action they have never taken, by prompting it
## while a control they can reach performs it.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## It is one source of the prompts, built with the record of what is taken,
## the prompts, the name of the source it raises under - which the prompts
## must have been built with - the random source it chooses with, and the
## driver. IT FOLLOWS WHAT ITS CHOICE READ (reads.gd): where the reader is,
## the game's refusals of the actions it asked about, and what is taken - so
## the screen changing, a game fact a refusal reads moving, and the reminded
## action being taken all remind, and nothing is listed: there is no clock. Reminding gathers every action tracked and never
## taken that some control the player can reach performs, and raises one of
## them at random - the words are the register's; with none, it withdraws.
## Only an action with a control that can be reached is ever chosen, so a
## reminder never lands on nothing while another could have been shown, and
## never beneath a pop-up. The random source is handed in so whoever builds
## this sets the seed, and a test can fix it.
##
## Whether an action can be reached is the driver's word: a place on the
## screen declares it and the game does not refuse it (queries.gd); no
## button is asked.
##
## Taking an action from any control retires it. The record is set the first
## time an action is taken, and when that is the action being reminded of,
## the next is reminded of at once - or nothing, when none is left that can
## be reached. A reminder standing is KEPT while some control performing
## it can still be reached, whatever changed, so it does not swap under the
## player's eyes; remind() picks afresh. It calls the record, the prompts, the driver and the random
## source, each of which holds something it depends on, and nothing that
## depends on it.
##
## Deliberately absent: a clock; muting, which is the prompts'; and a weight
## on the choice, such as the actions the player is nearest to needing.

var _taken: Taken
var _prompts: Prompts
var _source: StringName
var _random: RandomNumberGenerator
var _driver: Driver
var _reminding: StringName = &""  # the action being reminded of, or an empty name for none
var _afresh: bool = false  # whether the next choice is made whatever stands


func _init(chimes: Chimes, taken: Taken, prompts: Prompts, source: StringName, random: RandomNumberGenerator, driver: Driver) -> void:
	super(chimes, [], Chimes.GLOBAL)
	_taken = taken
	_prompts = prompts
	_source = source
	_random = random
	_driver = driver
	follow(&"reachable", _moved)


## Prompt an action never taken that a control the player can reach performs,
## chosen at random among those, or withdraw when there is none - chosen as
## followed work, so what the new choice stands on is what is followed.
func remind() -> void:
	_afresh = true
	follow(&"reachable", _moved)


## What the reminder stands on read, so it is followed: the reminder is kept
## while it is untaken and can still be reached, else - or asked afresh -
## another is chosen, reading every action it might be.
func _moved() -> void:
	if not _afresh and _still_reachable():
		return
	_afresh = false
	var here: Array[StringName] = []  # each untaken action that can be reached, in the order tracked
	# every tracked action never taken, kept if it can be reached
	for action: StringName in _taken.untaken():
		if _driver.is_reachable(action):
			here.append(action)
	_reminding = &"" if here.is_empty() else here[_random.randi_range(0, here.size() - 1)]
	Reads.apart(_shown)


## The choice shown: raised under this source, or withdrawn with none.
func _shown() -> void:
	if _reminding == &"":
		_prompts.withdraw(_source)
		return
	_driver.check_drawn(_reminding)
	_prompts.raise(_source, _reminding)


## Whether the action reminded of is still untaken with a control that can be reached.
func _still_reachable() -> bool:
	return _reminding != &"" and _taken.untaken().has(_reminding) and _driver.is_reachable(_reminding)
