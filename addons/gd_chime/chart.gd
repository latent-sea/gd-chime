extends RefCounted

const Paths := preload("paths.gd")
const Events := preload("events.gd")
const Phrase := preload("phrase.gd")

## The statechart of the interface, as a pure function: where the reader is
## and has been, and what happened, to where they are now and what to do
## about it, in order.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE INTERFACE IS A STATECHART. Places are states; a screen's tabs are its
## child states, and siblings are exclusive - one child of a state is active.
## Entering a state with children enters THE CHILD IT WAS LAST ON, or its
## first child before it was ever on one, and so on down: a place is
## RESOLVED to where a move to it lands, and a place named itself is where
## the move goes. A state left remembers the child it was on. The regions
## are parallel: the app, whose active path is the reader's; the overlays,
## a stack of pop-ups of which the top takes input and blocks everything
## beneath, keyboard, pad and mouse; and the panel, the developer's
## console, which blocks nothing. A container that is no state - a strip,
## a tab row - is never touched.
##
## A CHART is a plain value: the app root's name, each state's child states
## in order (the first is the initial one), each state's parent, and the
## kind of every root beside the app, OVERLAY or PANEL. A STATE is one plain
## value with nothing live in it: the app's resolved path, the overlay stack
## (each a resolved path), the panel's path, the child each state was last
## on, and THE HISTORY - the paths the reader landed on in the app, oldest
## first. transition() IS THE ONLY THING THAT KNOWS WHAT A MOVE DOES. An
## EVENT and an EFFECT are typed (events.gd): GO to a place, BACK, LOWER a
## root, FORGET the way back; it hands back {state, effects, refusal} - a
## refusal is a phrase and nothing else changes; else the effects, each
## what it does and the state it does it to, are what the shell carries
## out, in THE FIXED ORDER, always:
##
##   1. NOTE_FOCUS in each state being left, and NOTE_OPENER as a root is
##      raised, before input is switched off, since the switch drops it;
##   2. EMPTY each state being left, innermost first - overlays top first,
##      then the app's path below the split;
##   3. RECONCILE: what is shown and which layer takes input are FACTS OF
##      THE STATE, not steps - every state shown if the state names it and
##      hidden if not, every root live if it is on top and switched off if
##      not - set to what the new state says, never toggled;
##   4. FILL each state entered, outermost first, down to the initial
##      children, each shown already;
##   5. FOCUS: the control one state remembers - its OWN, the focus it had
##      as it was left, or its OPENER - else the default of another;
##   6. NOTIFY, once.
##
## GO IS THE ONE KIND OF MOVE. A place in the app: every overlay lowered,
## top first, before the app's path changes, and the panel left alone; where
## the reader already is, the overlays lowered and nothing moved. A place in
## the root on top, or in the panel: a move WITHIN that layer - a tab inside
## a pop-up - touching nothing beneath. A place in a pop-up not up, or in
## the panel down: the root raised, landing on that place - so a link to a
## tab inside a pop-up opens the pop-up on that tab. Refused: a place that
## is no state, a pop-up up but not on top, or the place the reader is at
## with nothing up. THE HISTORY IS THE APP'S, AND RETRACES EXACTLY, as a
## browser's does: every arrival in the app adds an entry - the path landed
## on, the parameters on it, and a serial of its own, so two visits to one
## view are two entries - unless it is the same view as the newest, which
## adds nothing; past HISTORY_CAP entries the oldest is dropped. So home,
## ledger, home by a link and Back is the ledger. BACK lowers the top
## overlay, else takes the newest entry off and arrives at the one beneath
## with its parameters, else is refused. FORGET keeps the newest entry
## alone. Where
## the reader is is remembered BEFORE the landing is worked out, so a move
## to the screen the reader is on lands on the tab they are on, never one
## left long ago. Nothing above the split - the states the old and new path
## share - is touched. Nothing here touches the engine or holds anything: the
## questions asked of a path are paths.gd's, the effects of leaving and
## entering are events.gd's, and the applier carries them out.

const OVERLAY := &"overlay"
const PANEL := &"panel"
## How many entries the history holds before the oldest is dropped. A placeholder.
const HISTORY_CAP := 50


## The state before any move: nowhere, nothing up, nothing walked, no serial issued.
static func blank() -> Dictionary:
	return {"path": [], "overlays": [], "panel": [], "last": {}, "history": [], "params": {}, "history_params": [], "history_ids": [], "serial": 0}


## Whether Back can act on this state: an overlay up, or a path behind.
static func can_go_back(state: Dictionary) -> bool:
	return not state["overlays"].is_empty() or state["history"].size() > 1


## Where the reader is now and what to do, for this event; or a refusal.
static func transition(chart: Dictionary, state: Dictionary, event: Events.Event) -> Dictionary:
	match event.kind:
		Events.Kind.GO: return _go(chart, state, event.place, event.parameter)
		Events.Kind.BACK:
			if not (state["overlays"] as Array).is_empty():
				return _lower(chart, state, state["overlays"].back()[0])
			if state["history"].size() < 2:
				return Events.refused(state, Phrase.of("There is nothing to go back to"))
			# the entry behind, with a copy of the parameters it was walked with: the record is never written
			var behind := state.duplicate()
			behind["history"] = state["history"].slice(0, -1)
			behind["history_params"] = state["history_params"].slice(0, -1)
			behind["history_ids"] = state["history_ids"].slice(0, -1)
			behind["params"] = behind["history_params"].back().duplicate()
			return _arrive(chart, behind, behind["history"].back())
		Events.Kind.LOWER: return _lower(chart, state, event.place)
	return _forget(state)


## A move to a place, with the parameter it is entered with - which one of
## its kind: in the app, an arrival; in the root on top or the panel, within
## it; in a root not up, that root raised onto it. The parameter is set on
## the way, so the same place with another parameter is a move, not a stay.
static func _go(chart: Dictionary, state: Dictionary, place: StringName, parameter: Variant) -> Dictionary:
	if not chart["parent"].has(place):
		return Events.refused(state, Phrase.with("%s is no state", [place]))
	var with := state.duplicate()
	with["params"] = state["params"].duplicate()
	if parameter == null:
		with["params"].erase(place)
	else:
		with["params"][place] = parameter
	var path := Paths.path_to(chart, place)
	if path[0] == chart["app"]:
		return _arrive(chart, with, path, state["params"])
	if path[0] == Paths.top(chart, state)[0] or (not state["panel"].is_empty() and state["panel"][0] == path[0]):
		return _within(chart, with, path, state["params"])
	if Paths.is_up(state, path[0]):
		return Events.refused(state, Phrase.with("%s is not on top", [path[0]]))
	return _raise(chart, with, path)


## An arrival in the app: the overlays lowered top first and the app's path
## below the split left, innermost first, the new path below the split
## entered and the history moved.
static func _arrive(chart: Dictionary, state: Dictionary, path: Array, params_before: Dictionary = {}) -> Dictionary:
	# where the reader is remembered first, so the landing is worked out from it and never from a tab left long ago
	var last: Dictionary = Paths.remembering(state["last"], state["path"])
	var left: Array = []
	# every overlay top first, its states innermost first, each root remembering its tab
	for index: int in range(state["overlays"].size() - 1, -1, -1):
		left.append_array(Paths.innermost_first(state["overlays"][index]))
		last = Paths.remembering(last, state["overlays"][index])
	var landing := Paths.resolved(chart, {"last": last}, path)
	var split := Paths.parting(state["path"], landing, state["params"], params_before)
	if landing == state["path"] and split == landing.size() and state["overlays"].is_empty():
		return Events.refused(state, Phrase.with("Already at %s", [landing.back()]))
	left.append_array(Paths.innermost_first(state["path"].slice(split)))
	var effects := Events.leaving(left)
	effects.append_array(Events.entering(landing.slice(split)))
	effects.append(Events.Effect.new(Events.Doing.FOCUS, landing.back(), Events.Memory.OWN, landing.back()))
	effects.append(Events.Effect.new(Events.Doing.NOTIFY))
	# a place left lets its parameter go; the entry keeps what it was walked with
	for named: StringName in left:
		if not landing.has(named):
			state["params"].erase(named)
	var walked := Paths.walked(state, landing, state["params"], HISTORY_CAP)
	return Events.outcome({"path": landing, "overlays": [], "panel": state["panel"], "last": last, "params": state["params"], "history": walked["history"], "history_params": walked["history_params"], "history_ids": walked["history_ids"], "serial": walked["serial"]}, effects)


## A move within the layer on top or the panel: its states below the split
## left and the new ones entered, nothing beneath touched.
static func _within(chart: Dictionary, state: Dictionary, path: Array, params_before: Dictionary = {}) -> Dictionary:
	var panel: bool = not state["panel"].is_empty() and state["panel"][0] == path[0]
	var current: Array = state["panel"] if panel else state["overlays"].back()
	var next := state.duplicate()
	next["last"] = Paths.remembering(state["last"], current)
	var landing := Paths.resolved(chart, next, path)
	var split := Paths.parting(current, landing, state["params"], params_before)
	if landing == current and split == landing.size():
		return Events.refused(state, Phrase.with("Already at %s", [landing.back()]))
	var effects := Events.leaving(Paths.innermost_first(current.slice(split)))
	effects.append_array(Events.entering(landing.slice(split)))
	effects.append(Events.Effect.new(Events.Doing.FOCUS, landing.back(), Events.Memory.OWN, landing.back()))
	effects.append(Events.Effect.new(Events.Doing.NOTIFY))
	if panel:
		next["panel"] = landing
	else:
		next["overlays"] = state["overlays"].slice(0, -1) + [landing]
	return Events.outcome(next, effects)


## A root raised onto this path: an overlay over the top, or the panel; its
## opener noted first, the layer beneath switched off by the reconciling.
static func _raise(chart: Dictionary, state: Dictionary, path: Array) -> Dictionary:
	var landing := Paths.resolved(chart, state, path)
	var effects: Array[Events.Effect] = [Events.Effect.new(Events.Doing.NOTE_OPENER, path[0])]
	var next := state.duplicate()
	if chart["kind"][path[0]] == OVERLAY:
		next["overlays"] = state["overlays"] + [landing]
	else:
		next["panel"] = landing
	effects.append_array(Events.entering(landing))
	effects.append(Events.Effect.new(Events.Doing.FOCUS, landing.back(), Events.Memory.OWN, landing.back()))
	effects.append(Events.Effect.new(Events.Doing.NOTIFY))
	return Events.outcome(next, effects)


## A root lowered: the top overlay, the layer beneath switched on and the
## focus back on its opener; or the panel. Its places let their parameters go.
static func _lower(chart: Dictionary, state: Dictionary, root: StringName) -> Dictionary:
	var overlay: bool = chart["kind"].get(root) == OVERLAY
	if overlay and (state["overlays"].is_empty() or state["overlays"].back()[0] != root):
		return Events.refused(state, Phrase.with("%s is not on top", [root]))
	if not overlay and (state["panel"].is_empty() or state["panel"][0] != root):
		return Events.refused(state, Phrase.with("%s is not up", [root]))
	var next := state.duplicate()
	var leaving: Array = state["overlays"].back() if overlay else state["panel"]
	next["last"] = Paths.remembering(state["last"], leaving)
	next["params"] = state["params"].duplicate()
	# every place of the root lowered lets its parameter go: a lowered pop-up has no view to be one of its kind in
	for named: StringName in leaving:
		next["params"].erase(named)
	var effects := Events.leaving(Paths.innermost_first(leaving))
	if overlay:
		next["overlays"] = state["overlays"].slice(0, -1)
	else:
		next["panel"] = []
	effects.append(Events.Effect.new(Events.Doing.RECONCILE))
	effects.append(Events.Effect.new(Events.Doing.FOCUS, root, Events.Memory.OPENER, Paths.top(chart, next).back()))
	effects.append(Events.Effect.new(Events.Doing.NOTIFY))
	return Events.outcome(next, effects)


## The way back forgotten: the path the reader is at kept alone, and said.
static func _forget(state: Dictionary) -> Dictionary:
	if state["history"].size() < 2:
		return Events.refused(state, Phrase.of("There is nothing behind to forget"))
	var next := state.duplicate()
	next["history"] = [state["history"].back()]
	next["history_params"] = [state["history_params"].back()]
	next["history_ids"] = [state["history_ids"].back()]
	return Events.outcome(next, [Events.Effect.new(Events.Doing.NOTIFY)])
