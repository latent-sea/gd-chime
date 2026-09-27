extends RefCounted

## Paths over the chart and the state: where an arrival lands, what a state
## was last on, where two paths part, which layer is on top.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A PATH is state names from a root down. The statechart (chart.gd) turns
## events into effects; these are the pure questions it asks of a path along
## the way, each a function over the chart and the state it is handed,
## holding nothing. RESOLVING extends a path down to where an arrival lands:
## through the child each state was last on, while that is still a child of
## it, else its first - so a screen entered again opens on the tab it was
## left on, and one whose tab has gone opens on its first. REMEMBERING is
## the other half: every state on a path being left remembers the one
## beneath it. WALKED is the history moved by an arrival: an entry added,
## with a serial of its own, unless it is the view the newest entry already
## is; the oldest dropped past the cap.

## A path extended down to where an arrival lands.
static func resolved(chart: Dictionary, state: Dictionary, path: Array) -> Array:
	var landing: Array = path.duplicate()
	# down through remembered or first children, as far as one goes
	while not (chart["children"].get(landing.back(), []) as Array).is_empty():
		var children: Array = chart["children"][landing.back()]
		var last: StringName = state["last"].get(landing.back(), children[0])
		landing.append(last if children.has(last) else children[0])
	return landing


## What each state was last on, with every state on this path remembering
## the one beneath it.
static func remembering(last: Dictionary, path: Array) -> Dictionary:
	var next := last.duplicate()
	# every state on the path, remembering the next
	for step: int in range(1, path.size()):
		next[path[step - 1]] = path[step]
	return next


## The history after landing on this path with these parameters: as it is
## when the newest entry is the same view - the path with the same
## parameters on it - so pressing the tab the reader is on, or arriving
## where they are, piles nothing up; else with an entry added under the next
## serial, and the oldest dropped while there are more than cap. As
## {history, history_params, history_ids, serial}.
static func walked(state: Dictionary, landing: Array, params: Dictionary, cap: int) -> Dictionary:
	var history: Array = state["history"]
	if not history.is_empty() and history.back() == landing and _on(state["history_params"].back(), landing) == _on(params, landing):
		return {"history": history, "history_params": state["history_params"], "history_ids": state["history_ids"], "serial": state["serial"]}
	var serial: int = state["serial"] + 1
	# the first entry kept, so no more than cap are
	var from := maxi(0, history.size() + 1 - cap)
	return {"history": (history + [landing]).slice(from), "history_params": (state["history_params"] + [params.duplicate()]).slice(from), "history_ids": (state["history_ids"] + [serial]).slice(from), "serial": serial}


## The parameters of the places on this path alone.
static func _on(params: Dictionary, path: Array) -> Dictionary:
	var on: Dictionary = {}
	for named: StringName in path:
		if params.has(named):
			on[named] = params[named]
	return on


## The names from the root of a layer down to this state, by the chart's parents.
static func path_to(chart: Dictionary, place: StringName) -> Array:
	var path: Array = []
	var named: StringName = place
	# up from the state through its parents
	while named != &"":
		path.push_front(named)
		named = chart["parent"][named]
	return path


## The path with its innermost state first, as states are left.
static func innermost_first(path: Array) -> Array:
	var reversed := path.duplicate()
	reversed.reverse()
	return reversed


## Where a landing parts from the path the reader is on, the parameters
## counted: the first place whose parameter moved when the paths are one -
## the landing's whole length when nothing moved, so the move is nowhere.
static func parting(current: Array, landing: Array, params: Dictionary, before: Dictionary) -> int:
	if landing != current:
		return split(current, landing)
	for index: int in range(landing.size()):
		if params.get(landing[index]) != before.get(landing[index]):
			return index
	return landing.size()


## How many names two paths share from the root: where they part.
static func split(before: Array, after: Array) -> int:
	var shared := 0
	# each name in turn, while both paths agree
	while shared < before.size() and shared < after.size() and before[shared] == after[shared]:
		shared += 1
	return shared


## Whether this root is up: the panel, or an overlay in the stack.
static func is_up(state: Dictionary, root: StringName) -> bool:
	if not state["panel"].is_empty() and state["panel"][0] == root:
		return true
	# every overlay up, for this root
	for overlay: Array in state["overlays"]:
		if overlay[0] == root:
			return true
	return false


## The path of the layer that takes input: the top overlay's, else the app's
## - the app root alone before any arrival.
static func top(chart: Dictionary, state: Dictionary) -> Array:
	if not state["overlays"].is_empty():
		return state["overlays"].back()
	return state["path"] if not state["path"].is_empty() else [chart["app"]]
