extends "controller.gd"

const Reads := preload("reads.gd")

## The one door every command goes through: a control says what it wants
## done, the model registered for that action does it, and the answer comes
## back on the same call.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A command is an intent, and a bell is a fact. A bell carries nothing and any
## number may listen; a command carries a payload, has exactly one handler, and
## can be refused. So the two never share a mechanism: a model rings a bell when
## a fact changes, and is told a command when the player wants something done.
##
## A model is registered for an action at an address, region and action, and
## a control dispatches at its own region:
##
##     commands.register(&"a_screen", &"scroll_page_down", list)
##     var answer := commands.dispatch(&"a_screen", &"scroll_page_down", {})
##
## The handler is looked for at [region, action] and then at [GLOBAL, action],
## so a model built with a screen answers that screen's commands and a model of
## the application answers from anywhere. Two screens open at once each reach
## their own. A handler is always a model, never a control: a control only
## draws, so nothing here ever holds one.
##
## The handler is told(action, payload) and answers a String: empty when it did
## it, otherwise the reason it refused, for the control to show where the press
## happened. A refusal is a rule saying no, not a failure, and travels as an
## ordinary return value. An action nobody registered is a mistake, refused out
## loud, and the sentence is returned so it shows too.
##
## Every command that ran is kept as the last one - its address, its
## payload, its answer and whether it was paused into a question - and
## COMMAND_RAN rings, in the global region, once it is kept. Whatever
## watches what the player does hears that bell and reads get_last(): the
## interface map, to record an action taken; guidance, to see a step done. The record is one place, so what changed a model is a question
## with an answer.
##
## A COMMAND THAT MOVES THE READER MAY BE STOPPED TO ASK FIRST. One of the
## mover's own, or a press whose place says it goes somewhere, is put to the
## mover past its refusal and BEFORE ITS HANDLER IS TOLD: a move that would
## leave a place asking before it is left is stopped there and a question
## raised in its stead (leave_guard.gd), and the words asked are the answer
## - so a press that would change something and leave has changed nothing.
## The refusal never asks it: a button whose press would be stopped is
## pressable, and pressing it asks. A command so stopped is PAUSED, not
## refused: its answer says it was not done, for whatever tracks what the
## player did, and its record says it was paused, so the control pressed
## shows no refusal of it - the question says why.
##
## A COMMAND DISPATCHED WHILE ANY BELL RINGS IS REFUSED OUT LOUD. A ring runs
## every listener in turn, and a listener of COMMAND_RAN that dispatched would
## overwrite the last command before the listeners after it read it - the map
## would then record the wrong action, silently. The rule is the same
## whichever bell is ringing, so it cannot depend on how a heard() came to
## run: nothing dispatches from heard(). A listener that must act on what it
## heard - a guided step moving on - defers its dispatch until the ring is over
## with call_deferred, which runs at the end of the current frame. Flux's
## dispatcher refuses the same thing for the same reason.
##
## A region's handlers are forgotten with drop_region(), which whatever closes
## a screen calls beside the chimes' own; a model of the application is never
## dropped. A handler under a region goes with the region, and a model in the
## global region outlives every screen.
##
## A MODEL FREED ANSWERS NOTHING, whoever freed it and whenever: the door
## finds it gone - or waiting at the end of the frame to go - as it looks for
## a handler, lets it go there, and answers as though nobody were
## registered; so a model standing in its place is registered without a
## word, at once, even while the one it replaces waits to be freed. Looked
## up rather than told, because the door and its models are taken down
## together in whatever order the engine frees them.
##
## Deliberately absent: a record longer than the last command, a payload with
## a shape, and an answer richer than a sentence.

const COMMAND_RAN := &"command_ran"

## Whoever moves the reader, given as this is built: registered for its
## own commands, asked whether a press that goes somewhere would be refused,
## asked whether a command that moves the reader stops to ask first, and
## handed the move once the action's own handler has run.
var mover: Object = null

var _handlers: Dictionary = {}  # region -> {action -> the model told}
var _last: Dictionary = {}  # the last command that ran: region, action, payload, answer, whether it was paused


func _init(chimes: Chimes, moves: Object = null) -> void:
	super(chimes, [], Chimes.GLOBAL)
	register_bell(COMMAND_RAN)
	mover = moves
	# the mover's own commands, answered by it from anywhere; and it told this is its door
	if mover != null:
		mover.door = self
		for action: StringName in mover.COMMANDS:
			register(Chimes.GLOBAL, action, mover)


## Register the model told an action in a region - refused out loud when the
## address has one standing, which keeps it; one freed, or waiting to be
## freed, is replaced.
func register(in_region: StringName, action: StringName, model: Object) -> void:
	if not _handlers.has(in_region):
		_handlers[in_region] = {}
	if _handler(in_region, action, false) != null:
		push_error("%s in %s already has a handler" % [action, in_region])
		return
	_handlers[in_region][action] = model


## A model stood up in a region: told every action it answers
## (controller.gd) there, and nothing else. This is how an application
## (application.gd) and a place (place_builder.gd) register one, so a model
## says what it answers in one place and no caller lists it again.
func stand(in_region: StringName, model: Object) -> void:
	# every action the model answers, registered in this region
	for action: StringName in model.answers():
		register(in_region, action, model)


## The refusal the press would meet: the model's own, if there is a model,
## else the mover's for a press that goes somewhere - where the region's
## declaration of the action says, never the payload, though the payload's
## parameter, which one of the place's kind, rides with the move. Nothing
## is done.
func refusal(in_region: StringName, action: StringName, payload: Dictionary) -> Phrase:
	var why := game_refusal(in_region, action, payload)
	if why != null:
		return why
	var goes_to: StringName = mover.goes_to(in_region, action) if mover != null else &""
	if goes_to != &"":
		return mover.would_move(goes_to, payload.get("parameter"))
	return null


## The model's own refusal of the press, and nothing of navigation: the
## game's answer, the same on every screen, which routing asks with no
## payload - whether any press of the action could go through.
func game_refusal(in_region: StringName, action: StringName, payload: Dictionary) -> Phrase:
	var model: Object = _handler(in_region, action)
	return model.would(action, payload) if model != null else null


## Dispatch: refused if the press would be; stopped if it moves the reader
## and the mover stops it to ask first; else the model told and then, for
## a press whose region declares it goes somewhere, the mover; the payload
## is the game's alone. The command is kept and COMMAND_RAN rung either way.
## A nested dispatch, or a press nobody handles that goes nowhere, is
## refused out loud.
func dispatch(in_region: StringName, action: StringName, payload: Dictionary) -> Phrase:
	if _chimes.is_striking():
		var nested := Phrase.with("%s was dispatched from inside heard(); defer it until the ring is over", [action])
		push_error(str(nested))
		return nested
	var model: Object = _handler(in_region, action)
	var goes_to: StringName = mover.goes_to(in_region, action) if mover != null else &""
	if model == null and goes_to == &"":
		var nobody := Phrase.with("Nothing handles %s in %s", [action, in_region])
		push_error(str(nobody))
		return nobody
	# the command kept before it runs, its answer empty, so whatever reads the last command meanwhile sees this one
	_last = {"region": in_region, "action": action, "payload": payload.duplicate(true), "answer": null, "paused": false}
	var record := _last
	var answer := refusal(in_region, action, payload)
	# a command that moves the reader - a press going somewhere, or one of the mover's own - put to the mover before any handler is told; stopped, it is paused
	if answer == null and (goes_to != &"" or model == mover):
		answer = mover.stops_to_ask(in_region, action, payload)
		record["paused"] = answer != null
	if answer == null and model != null:
		answer = model.told(action, payload)
	if answer == null and goes_to != &"":
		answer = mover.move(goes_to, payload.get("parameter"))
	# a command told from inside this one has run and been kept meanwhile; this one is the last again
	_last = record
	_last["answer"] = answer
	strike(region, COMMAND_RAN)
	return answer


## The last command that ran, as a copy: region, action, payload, answer, and
## whether it was paused into a question - not done, and refused by nobody.
## Read, it notes COMMAND_RAN for whoever is reading.
func get_last() -> Dictionary:
	Reads.note(region, COMMAND_RAN)
	return _last.duplicate(true)


## Whether some model is told this action in this region, or globally.
func handles(in_region: StringName, action: StringName) -> bool:
	return _handler(in_region, action) != null


## Forget every handler registered in a region, as the region closes.
func drop_region(in_region: StringName) -> void:
	_handlers.erase(in_region)


## The model told an action in a region: the region's own, else - unless
## asked of that region alone - the global one.
func _handler(in_region: StringName, action: StringName, or_global: bool = true) -> Object:
	var model: Object = _standing(in_region, action)
	if model == null and or_global:
		return _standing(Chimes.GLOBAL, action)
	return model


## The model registered at this address while it stands: one freed, or
## waiting to be freed, is let go here and answers nothing.
func _standing(in_region: StringName, action: StringName) -> Object:
	if not _handlers.has(in_region):
		return null
	var model: Variant = _handlers[in_region].get(action)
	if is_instance_valid(model) and not (model as Object).is_queued_for_deletion():
		return model
	_handlers[in_region].erase(action)
	return null
