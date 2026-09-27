extends "face.gd"

const Commands := preload("commands.gd")
const Prompts := preload("prompts.gd")
const Phrase := preload("phrase.gd")

## A control that draws one of its place's actions: pressed while the door
## would not refuse it, it dispatches the action, and it glows while the
## prompts name it and it can be reached.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## IT IS BUILT BY ITS PLACE (place.gd), for an action THE PLACE DECLARES:
## the place hands it the chimes, the door, itself and the action, and its
## region is the place's name - so a press, a refusal asked of the door and
## the closing of the place all find the same handler. A control for an
## action its place does not declare is reported out loud as it is built.
## Where a press goes is read from the place's declaration, never held here,
## so a button built at startup and one built as the place fills are alike.
## A usable press is one dispatch(region, action, payload()): the model
## registered for that action in this region, or globally, does it and
## answers, and the door moves the reader where the declaration says; the
## answer is kept for the face to show - nothing when done, the reason when
## refused, and nothing when the press was paused into a question, which
## nothing refused: the question says why it waits (commands.gd). What the
## action means is the model's business and never reaches this. It hangs no
## bell and strikes none: a press is a command, not a fact.
##
## payload() is what a press carries: the game's data, and nothing of
## navigation. It belongs to whatever extends this: a button carries
## nothing, a row carries which entry it shows.
##
## WHETHER IT CAN BE USED IS THE DOOR'S ANSWER: refusal(region, action,
## payload) - the model's own refusal, and the chart's if the press moves the
## reader - and the sentence to show while it cannot is that refusal. IT
## FOLLOWS WHAT THE REFUSAL READ: asked as it draws, the refusal's reads are
## noted with the draw's (presentation.gd), so the model values it read draw
## it again and nothing is listed; a press asks again as it lands, so a
## control that became unusable since its last draw still dispatches
## nothing. One whose action goes somewhere hears the driver too, so its
## look follows every move.
##
## Its prompts can be set after it is built; it then glows while they name
## its action, its place is on the screen, and the door would not refuse it -
## so a button behind a pop-up never glows while it is blocked. What the
## prompts name is a value it reads as it draws, so it follows it as it
## follows everything else it drew. Rebound to listen to something else, it
## goes on hearing the driver.
##
## Anything it hears is a draw. A PRESS REFUSED FOLLOWS WHAT THE REFUSAL
## READS, apart from the draw (key REFUSAL), and a ring there clears it: a
## "not enough credits" is not left standing after the credits arrive, while
## its own look moving - a slider's held value let go as the press lands -
## leaves it, and so does a prompt moving, which is only a draw. A bell it
## listens to clears it too.
##
## How it looks is the face's (face.gd), which this extends and which knows
## nothing of actions; the states the door and the prompts give it belong to
## whatever extends this, which reads is_usable(), get_reason(),
## get_refusal() and is_glowing() when it draws.
##
## Deliberately absent: a refusal richer than a sentence.

## The key what a standing refusal reads is followed under.
const REFUSAL := &"refusal"

## What it does when pressed: one of its place's actions. Set again only by
## a reused row, and draws again, since a face may say what it does.
var action: StringName = &"":
	set(named):
		action = named
		needs_refresh()

## The prompts it asks whether to glow, set after it is built. Set, it draws
## again, since whether it glows may have changed.
var prompts: Prompts = null:
	set(given):
		prompts = given
		needs_refresh()

var _commands: Commands
var _refusal: Phrase = null
var _place: Node  # the place this draws for, given as it is built


func _init(chimes: Chimes, commands: Commands, place: Node, does: StringName, style: Variant = &"") -> void:
	_commands = commands
	_place = place
	action = does
	if not place.performs.has(does):
		push_error("%s does not declare %s, which a control in it draws" % [place.name, does])
	super(chimes, place.name, style)


## Where a press takes the reader, as its place declares - or nothing.
func get_goes_to() -> StringName:
	return _place.performs.get(action, &"")


## Rebinding drops everything this listened to, so what it hears by itself
## is listened to again: the driver, when its press goes somewhere. What its
## draw and its refusal read it follows, apart from this.
func listen(listening: Array) -> void:
	super.listen(listening)
	if get_goes_to() != &"":
		listen_to(Chimes.GLOBAL, _place.driver.NAVIGATED)


## Whether it can be used right now: the door would not refuse the press.
func is_usable() -> bool:
	return get_reason() == null


## Why it cannot be used right now, or nothing while it can.
func get_reason() -> Phrase:
	return _commands.refusal(region, action, payload())


## Why the last press was refused, or nothing if it was done.
func get_refusal() -> Phrase:
	return _refusal


## Whether the prompts name its action now, its place is on the screen, and
## the door would not refuse it. A control with no action never matches
## nothing raised.
func is_glowing() -> bool:
	var named := prompts != null and prompts.get_glowing() != &"" and prompts.get_glowing() == action
	return named and _place.driver.get_top().has(_place.name) and is_usable()


## Something it listens to rang: a draw is due, and a refusal no longer stands.
func heard(_what: StringName) -> void:
	_keep_refusal(null)
	needs_refresh()


## A press answered: the refusal kept for the face - or none - and while one
## stands, what it reads followed, a move there clearing it.
func _keep_refusal(answer: Phrase) -> void:
	_refusal = answer
	if answer == null:
		_chimes.unfollow(self, REFUSAL)
		return
	_chimes.follow(self, REFUSAL, get_reason, func() -> void:
		_keep_refusal(null)
		needs_refresh())


## What a press carries: the game's data alone, nothing of navigation - the
## door reads where it goes from the place. Overridden by a subclass whose
## press says something.
func payload() -> Dictionary:
	return {}


## Dispatched only when, asked as the press lands, it can be used; the answer
## is kept, unless the press was paused into a question, and the face drawn
## again.
func pressed() -> void:
	if not is_usable():
		return
	var answer := _commands.dispatch(region, action, payload())
	_keep_refusal(null if _commands.get_last()["paused"] else answer)
	needs_refresh()
