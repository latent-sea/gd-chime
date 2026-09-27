extends RefCounted

## The statechart's words: what can happen, and what is to be done about it,
## each typed so a misspelt kind or a swapped argument is a parse error.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## An EVENT is one of four kinds - GO to a place, BACK, LOWER a root, FORGET
## the way back - built by the static function named for it, so the fields
## an event carries are the ones its kind reads; BACK and FORGET carry
## nothing, since the history is in the state. GO is the one kind of move:
## the chart works out whether the place is in the app, in a pop-up not up,
## in the layer on top or in the panel. An EFFECT is one of seven things to
## do, to a named state: NOTE_FOCUS, NOTE_OPENER, EMPTY, RECONCILE, FILL,
## FOCUS, NOTIFY - and a FOCUS says which MEMORY of that state to give the
## focus to, its OWN or its OPENER, and whose default failing that. The
## chart (chart.gd) makes effects and the applier (applier.gd) carries them
## out; the driver (driver.gd) makes events from commands. The two effect
## sequences every move is made of are here - leaving states, entering
## states - and the two shapes a transition answers in, an outcome and a
## refusal. Nothing here does anything.

## What happened.
enum Kind { GO, BACK, LOWER, FORGET }
## What to do about it.
enum Doing { NOTE_FOCUS, NOTE_OPENER, EMPTY, RECONCILE, FILL, FOCUS, NOTIFY }
## The two things a state remembers of the focus.
enum Memory { OWN, OPENER }


## An event: its kind, the place it names, and for a GO the parameter the
## place is entered with - which one of its kind - or nothing.
class Event extends RefCounted:
	var kind: Kind
	var place: StringName = &""
	var parameter: Variant = null

	static func go(to: StringName, with: Variant = null) -> Event:
		var event := Event.new()
		event.kind = Kind.GO
		event.place = to
		event.parameter = with
		return event

	static func back() -> Event:
		var event := Event.new()
		event.kind = Kind.BACK
		return event

	static func lower(named: StringName) -> Event:
		var event := Event.new()
		event.kind = Kind.LOWER
		event.place = named
		return event

	static func forget() -> Event:
		var event := Event.new()
		event.kind = Kind.FORGET
		return event


## An effect: what to do, the state to do it to, and for FOCUS which memory
## of that state to give the focus to and whose default failing that.
class Effect extends RefCounted:
	var doing: Doing
	var state: StringName
	var memory: Memory
	var fallback: StringName

	func _init(does: Doing, named: StringName = &"", of: Memory = Memory.OWN, else_default_of: StringName = &"") -> void:
		doing = does
		state = named
		memory = of
		fallback = else_default_of

	## As an array, for a test to read: the doing and the state, and for a
	## FOCUS the memory and the fallback too.
	func to_array() -> Array:
		return [doing, state, memory, fallback] if doing == Doing.FOCUS else [doing, state]


## A transition's answer: the state moved to and the effects, no refusal.
static func outcome(state: Dictionary, effects: Array[Effect]) -> Dictionary:
	return {"state": state, "effects": effects, "refusal": null}


## A transition's refusal: its words, a phrase, the state untouched, no effects.
static func refused(state: Dictionary, why: RefCounted) -> Dictionary:
	return {"state": state, "effects": [], "refusal": why}


## The effects of leaving these states, given innermost first: every focus
## noted, then every state emptied.
static func leaving(left: Array) -> Array[Effect]:
	var effects: Array[Effect] = []
	# both kinds of leaving, over every state left, in the fixed order
	for doing: Doing in [Doing.NOTE_FOCUS, Doing.EMPTY]:
		for named: StringName in left:
			effects.append(Effect.new(doing, named))
	return effects


## The effects of entering these states, given outermost first: the state
## reconciled first, so each is shown as it is filled.
static func entering(entered: Array) -> Array[Effect]:
	var effects: Array[Effect] = [Effect.new(Doing.RECONCILE)]
	# every state entered, filled
	for named: StringName in entered:
		effects.append(Effect.new(Doing.FILL, named))
	return effects
