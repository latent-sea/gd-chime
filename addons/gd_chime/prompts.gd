extends "controller.gd"

const Actions := preload("actions.gd")
const Reads := preload("reads.gd")

## Which action is being prompted, and the words that go with it: one at a
## time, chosen from every source that has something to say.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A source is whatever wants an action noticed - a guided step, or a reminder
## that an action has never been taken. It raises a prompt at the action and
## withdraws it when it has nothing more to say; the words that say what the
## action does are the register's, declared once with the action, so every source
## reads the same. A source holds one prompt at a time: raising again replaces what it
## had. A prompt names the action and never one control performing it: what
## matters is where the player is being pointed, not which of several ways
## there they take, so every control performing the action glows.
##
## The sources are named as this is built, in the order they win: of every
## prompt raised and not muted, the one whose source comes first is current.
## Which source matters more belongs to the application, so it is an argument
## rather than a rule here, and the list is copied as it is handed in.
##
## Two mistakes would each leave words beside nothing with nothing to say why,
## so each is refused out loud: a source this was not built with, and a name
## that is no action in the register it was handed (actions.gd). A source named twice is
## refused as this is built, and counted once.
##
## It never asks where the player is. A source raises only an action the
## player can take from where they are - a guided step the next action on the
## way back to it, a reminder among the actions with a control here - so what
## is current can glow. Knowing what is on screen is each source's own.
##
## A source can be muted - a player turning reminders off. A muted source's
## prompt is kept but is not current, so unmuting brings it back. A prompt
## carries its source, read with get_source(), so whatever shows the words can
## offer the way to turn that source off: a control dispatches MUTES or
## UNMUTES with the source, and this is registered for both, globally, by
## whoever composes the application. A source this was not built with is
## refused, out loud and as the answer.
##
## Two bells, both in the global region, since there is one of these per
## application and it outlives every screen. PROMPT_MOVED sounds whenever the
## current prompt changes - a different action, a different source, or none -
## and never for a change that leaves it as it was.
## MUTE_CHANGED sounds whenever a source is muted or unmuted, whether or not the
## current prompt moved, so a switch showing it follows a change made anywhere.
## Every read notes the two (reads.gd), so whatever shows the words or a
## switch follows them and lists nothing.
##
## It decides and rings; it calls nothing. A control that performs an action
## is handed this, reads get_glowing() as it arrives and again when the bell
## sounds, and glows while the action is its own. Whatever shows the words
## reads get_words() the same way. Calls go one way, toward what holds the fact.
##
## Deliberately absent: how a glowing control flashes, which is the control's
## own drawing; which untaken action to remind the player of, which reads the
## map; finding the way back to a step, which is routing; and where the words
## are drawn.

const PROMPT_MOVED := &"prompt_moved"
const MUTE_CHANGED := &"mute_changed"
## The two commands this is told, each carrying the source as {source}.
const MUTES := &"mutes"
const UNMUTES := &"unmutes"

var _actions: Actions
var _sources: Array[StringName] = []
var _raised: Dictionary = {}  # source -> action, for every source with a prompt raised
var _muted: Dictionary = {}  # the sources muted, used as a set
var _source: StringName = &""
var _glowing: StringName = &""


func _init(chimes: Chimes, actions: Actions, sources: Array[StringName]) -> void:
	super(chimes, [], Chimes.GLOBAL)
	_actions = actions
	# each source named, keeping the first of one named twice and refusing the repeat
	for source: StringName in sources:
		if _sources.has(source):
			push_error("the prompts' source %s is named twice" % source)
		else:
			_sources.append(source)
	register_bell(PROMPT_MOVED)
	register_bell(MUTE_CHANGED)


## Ask for this action to be noticed. Whatever this source had raised before
## is replaced.
func raise(source: StringName, action: StringName) -> void:
	if not _knows(source):
		return
	if not _actions.has(action):
		push_error("the prompts cannot raise %s: it is no action" % action)
		return
	_raised[source] = action
	_choose()


## This source has nothing more to say.
func withdraw(source: StringName) -> void:
	if not _knows(source):
		return
	_raised.erase(source)
	_choose()


## Mute this source, or unmute it. Its prompt, if it has one, is kept either way.
func set_muted(source: StringName, muted: bool) -> void:
	if not _knows(source) or muted == _muted.has(source):
		return
	if muted:
		_muted[source] = true
	else:
		_muted.erase(source)
	_choose()
	strike(region, MUTE_CHANGED)


func is_muted(source: StringName) -> bool:
	_noted()
	return _muted.has(source)


## A mute or an unmute was dispatched for a source: done, or refused for a
## source this was not built with.
func told(action: StringName, payload: Dictionary) -> Phrase:
	var source: StringName = payload["source"]
	if not _knows(source):
		return Phrase.with("The prompts have no source called %s", [source])
	set_muted(source, action == MUTES)
	return null


## The action whose controls should glow, or an empty name for none.
func get_glowing() -> StringName:
	_noted()
	return _glowing


## The words saying what it does, the register's, or nothing.
func get_words() -> String:
	_noted()
	return _actions.get_words(_glowing) if _glowing != &"" else ""


## The source the current prompt came from, or an empty name for none.
func get_source() -> StringName:
	_noted()
	return _source


## A read of the prompts moves as a prompt moves or a muting changes: both noted for whoever reads.
func _noted() -> void:
	Reads.note(region, PROMPT_MOVED)
	Reads.note(region, MUTE_CHANGED)


## Whether this was built with the source; one it was not is refused out loud.
func _knows(source: StringName) -> bool:
	if _sources.has(source):
		return true
	push_error("the prompts have no source called %s; they have %s" % [source, _sources])
	return false


## The current prompt worked out again, and the bell struck if it is not what it was.
func _choose() -> void:
	var source := &""
	var glowing := &""
	# the sources in the order they win, for the first with a prompt raised and not muted
	for named: StringName in _sources:
		if _raised.has(named) and not _muted.has(named):
			source = named
			glowing = _raised[named]
			break
	if source == _source and glowing == _glowing:
		return
	_source = source
	_glowing = glowing
	strike(region, PROMPT_MOVED)
