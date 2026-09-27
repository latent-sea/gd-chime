extends RefCounted

const Chart := preload("chart.gd")
const Events := preload("events.gd")
const Paths := preload("paths.gd")

## The questions every navigation feature asks, over the chart, what each
## place declares it performs, a state and the game's refusals: what can be
## reached, and the way to an action. Pure: no tree, no button.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## ROUTING ASKS THE PLACES AND THE STATE, NEVER THE BUTTONS. Every place
## declares what it performs (place.gd): each action, and where a press of it
## goes - a place, BACK, or nowhere. A declaration exists whether the place
## is filled or not, so an action drawn by a button built only as the place
## fills is routed to like any other. What the game refuses is asked of the
## door as a function, would(place, action), which only ever asks about
## actions and never reads navigation - game facts are the same on every
## screen - so it holds on the imagined states of a search as on the real
## one.
##
## A PLACE ASKING FIRST IS REFUSED TO LEAVE. Which places ask before they
## are left, now, is handed in - guarded, each by name with the words it
## would ask (leave_guard.gd) - and a move whose outcome EMPTIES one of them,
## a place deeper than the one left included, is stopping(): the door stops
## it for a question, and the questions here treat it as refused, so the
## guidance never points the reader out of one. The same answer holds on
## the imagined states of a search as on the real one, as the game's does.
##
## REACHABLE: a place on the state's screen - the path of the layer that
## takes input - declares the action, the game does not refuse it, and a
## press of it there leaves no place asking first. The glow is that
## question in the reader's own state, and so are the reminders.
##
## ROUTE is a breadth-first search: from the state given, the first state in
## which the action is reachable ends it, with the actions pressed to get
## there and the action itself; else every declared action with a goes_to,
## on the places on that state's screen, that the game does not refuse is
## made a move - GO to the place, or BACK - through the one transition on a
## copy, and the states reached that the chart did not refuse and no place
## asking first stopped are searched next. A SIMULATED PRESS KEEPS THE
## PARAMETER the place already has in the state being searched, and a place
## with none yet stays with none: routing goes to a place as a kind, never
## to one of it, and never imagines a state no press could make - a link
## pressed with nothing would let the entity go. A state is searched once,
## THE WHOLE VALUE being the key, so two states that differ only in a
## remembered tab are both searched; and the search stops at a depth, so a
## loop of places is walked once and a way that does not exist is answered
## with nothing. Of two ways the shorter wins, and of two of one length the
## one through the place earlier on the screen and the action declared
## earlier there.

## How many moves deep a way is looked for.
const DEPTH := 8


## The move a declared goes_to means: BACK, or GO to the place named.
static func move_of(goes_to: StringName, back: StringName, parameter: Variant = null) -> Events.Event:
	return Events.Event.back() if goes_to == back else Events.Event.go(goes_to, parameter)


## A press simulated in this state: the move its goes_to means, with the
## parameter the place already has there - none when it has none.
static func pressed(chart: Dictionary, state: Dictionary, goes_to: StringName, back: StringName) -> Dictionary:
	return Chart.transition(chart, state, move_of(goes_to, back, state["params"].get(goes_to)))


## The first place the outcome of a move empties, innermost first, that asks
## before it is left - guarded holds each by name - or nothing.
static func stopping(out: Dictionary, guarded: Dictionary) -> StringName:
	# every effect in the chart's order, for a place emptied that asks first
	for effect: Events.Effect in out["effects"]:
		if effect.doing == Events.Doing.EMPTY and guarded.has(effect.state):
			return effect.state
	return &""


## Whether the action can be reached in this state: a place on its screen
## declares it, the game does not refuse it there, and pressing it there
## empties no place asking first.
static func reachable(chart: Dictionary, performs: Dictionary, state: Dictionary, action: StringName, would: Callable, back: StringName, guarded: Dictionary) -> bool:
	# every place on the screen, for one declaring the action the game allows, whose press stops for no question
	for named: StringName in Paths.top(chart, state):
		var declared: Dictionary = performs.get(named, {})
		if declared.has(action) and would.call(named, action) == null and stopping(pressed(chart, state, declared[action], back), guarded) == &"":
			return true
	return false


## The actions to take, first to last, from this state to one where the
## action can be reached, ending with the action, never out of a place
## asking first; empty when no way exists within DEPTH moves.
static func route(chart: Dictionary, performs: Dictionary, state: Dictionary, action: StringName, would: Callable, back: StringName, guarded: Dictionary) -> Array[StringName]:
	var found: Array[StringName] = []
	var seen: Dictionary = {_where(state): true}  # every state searched, as the search tells them apart, used as a set
	var waiting: Array = [[state, []]]  # [state, the actions taken to reach it], nearest first
	# every state reached, nearest first, until one where the action can be reached
	while not waiting.is_empty():
		var here: Array = waiting.pop_front()
		var at: Dictionary = here[0]
		var so_far: Array = here[1]
		if reachable(chart, performs, at, action, would, back, guarded):
			found.assign(so_far + [action])
			return found
		if so_far.size() >= DEPTH:
			continue
		# every declared action going somewhere, on every place on this screen, that the game allows: pressed on a copy
		for named: StringName in Paths.top(chart, at):
			var declared: Dictionary = performs.get(named, {})
			for pressed: StringName in declared:
				if declared[pressed] == &"" or would.call(named, pressed) != null:
					continue
				var out: Dictionary = pressed(chart, at, declared[pressed], back)
				if out["refusal"] != null or seen.has(_where(out["state"])) or stopping(out, guarded) != &"":
					continue
				seen[_where(out["state"])] = true
				waiting.append([out["state"], so_far + [pressed]])
	return found


## A state as the search tells one from another: where the reader is, what
## stands over it, what each place last showed and with what - never the
## history behind, which every move lengthens: with it, no state reached
## would be one already searched, and the search would be every order of
## every move, to its depth.
static func _where(state: Dictionary) -> Array:
	return [state["path"], state["overlays"], state["panel"], state["last"], state["params"]]
