extends RefCounted

const Token := preload("token.gd")
const Events := preload("events.gd")
const Motion := preload("motion.gd")
const PlaceMotion := preload("place_motion.gd")
const KeptFocus := preload("kept_focus.gd")
const Kept := preload("kept.gd")

## The effects of a transition carried out on the engine, in the order
## given.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The statechart (chart.gd) decides and hands back a list; this is the thin
## shell that does each item on the tree and nothing else, one function per
## kind, with no order of its own. It is built once by the driver and handed
## every place by name, the state, the app root and the window's viewport,
## where the focus is, each time.
##
## SHOWN AND LIVE ARE RECONCILED, NEVER TOGGLED. RECONCILE sets every place
## to what the state says - shown if the app's path, an overlay or the panel
## names it, hidden if not - and every root's input to what the state says:
## the app live with no overlay up, each overlay live only on top, the panel
## always. So a root switched off under another can never be left so, and a
## place rebuilt under the player is shown as the next move reconciles.
##
## WITH A CLOCK, THE SAME RECONCILING IS SEEN (place_motion.gd): a place
## arriving is shown at once and enters; a place leaving is out of reach at
## once and stays drawn until it has been seen out, and only then hidden -
## and switched back on, hidden: a place not shown is not a place switched
## off. What is first shown is simply there.
## Input and the focus never wait for it - they are switched exactly as
## without - and with no clock handed in, nothing here moves.
##
## THE FOCUS each state remembers is kept, noted and given back by
## kept_focus.gd, as the chart's effects say when: NOTE_FOCUS and NOTE_OPENER
## remember, FOCUS gives back, and a reconcile that lowers a pop-up or the
## panel forgets what it remembered of its own. An app view's own focus is
## noted into the history entry being left and given back from the one
## arrived at, both handed in by the driver with the store they live in.
##
## A root's input is the engine's own switch: its focus and mouse behaviour
## for its whole subtree, so a control added while a pop-up is up is as dead
## as the rest. FILL issues the place's token and fills it; EMPTY cancels
## the token and empties, so a result already on its way lands on nothing.

## The one clock, handed in by whoever built the driver; none, and places switch.
var motion: Motion = null

var _focus := KeptFocus.new()
var _places: Dictionary = {}  # the places as last reconciled, for settling once one has been seen out
var _active: Array = []  # the names of the places the state names, as last reconciled
var _seeing_out: Dictionary = {}  # the names of the places still drawn while they are seen out
var _rooms: Dictionary = {}  # a room a push is going through -> [whether it clipped before the first, the place the latest push pushed out]


## Every effect carried out, in order, on these places; NOTIFY calls what it
## is handed. kept is the history's store, and leaving the entry the move
## leaves.
func apply(effects: Array[Events.Effect], places: Dictionary, state: Dictionary, app: Control, viewport: Viewport, notify: Callable, kinds: Dictionary, back: bool, kept: Kept, leaving: String) -> void:
	# each effect in the order the chart gave, by what it does
	for effect: Events.Effect in effects:
		match effect.doing:
			Events.Doing.NOTE_FOCUS:
				if _in_app(places[effect.state], app):
					_focus.note_view(places[effect.state], viewport, kept, leaving)
				else:
					_focus.note(places[effect.state], viewport, Events.Memory.OWN)
			Events.Doing.NOTE_OPENER:
				_focus.note(places[effect.state], viewport, Events.Memory.OPENER)
			Events.Doing.EMPTY:
				empty(places[effect.state])
			Events.Doing.RECONCILE:
				# with no clock, or nothing yet on the screen to come from, places are simply switched
				if motion == null or _places.is_empty():
					_places = places
					reconcile(places, state, app)
				else:
					_reconcile_seen(places, state, app, kinds, back)
				_focus.forget_lowered(places, active_in(state), kinds)
			Events.Doing.FILL:
				places[effect.state].parameter = state["params"].get(effect.state)
				fill(places[effect.state])
			Events.Doing.FOCUS:
				if effect.memory == Events.Memory.OWN and _in_app(places[effect.state], app):
					_focus.give_back_view(kept, Kept.entry_of(state), places[effect.fallback])
				else:
					_focus.give_back(effect.state, effect.memory, places[effect.fallback])
			Events.Doing.NOTIFY:
				notify.call()


## Whether a place is one of the app's views - the app or inside it - and
## not a root beside it.
static func _in_app(place: Node, app: Control) -> bool:
	return place == app or app.is_ancestor_of(place)


## Every place shown or hidden as the state names it or not, and every root's
## input live or off as it is on top or not.
static func reconcile(places: Dictionary, state: Dictionary, app: Control) -> void:
	var active := active_in(state)
	# every place, shown as the state says
	for place: Control in places.values():
		place.visible = active.has(place.name)
	_switch_roots(places, state, app)


## The names of the places the state names: the app's path, the panel's, and every overlay's.
static func active_in(state: Dictionary) -> Array:
	var active: Array = state["path"] + state["panel"]
	# every overlay's path, active too
	for overlay: Array in state["overlays"]:
		active.append_array(overlay)
	return active


## Whether the state shows this node: every place it stands in is one the state names.
static func shows(state: Dictionary, node: Node, index: RefCounted) -> bool:
	var active := active_in(state)
	var above := node.get_parent()
	# every place the node stands in, up to the root, for one the state does not name
	while above != null:
		if index.is_place(above) and not active.has(above.name):
			return false
		above = above.get_parent()
	return true


## Every root's input live or off as it is on top or not.
static func _switch_roots(places: Dictionary, state: Dictionary, app: Control) -> void:
	_switch(app, state["overlays"].is_empty())
	# every overlay root, live only on top
	for index: int in state["overlays"].size():
		_switch(places[state["overlays"][index][0]], index == state["overlays"].size() - 1)
	if not state["panel"].is_empty():
		_switch(places[state["panel"][0]], true)


## The same reconciling, seen: what arrives is shown and enters, what leaves
## is switched off and seen out before it is hidden. kinds is the chart's,
## place -> its kind, for the roots that stand over the rest.
func _reconcile_seen(places: Dictionary, state: Dictionary, app: Control, kinds: Dictionary, back: bool) -> void:
	_places = places
	_active = active_in(state)
	var arriving: Array = []
	var leaving: Array = []
	# every place, against what the state says of it now
	for place: Control in places.values():
		if _active.has(place.name) and (not place.visible or _seeing_out.has(place.name)):
			arriving.append(place)
		elif not _active.has(place.name) and place.visible:
			leaving.append(place)
	for place: Control in arriving:
		place.visible = true
		_seeing_out.erase(place.name)
		_switch(place, true)
	for place: Control in leaving:
		_seeing_out[place.name] = true
		_switch(place, false)
	var push := PlaceMotion.push_of(arriving, leaving, kinds)
	var room: Control = push[0].get_parent() if not push.is_empty() else null
	# the room clips what is pushed through it until the latest push through it rests; how it was is kept from before the first
	if room != null:
		_rooms[room] = [_rooms[room][0] if _rooms.has(room) else room.clip_contents, push[1]]
		room.clip_contents = true
	PlaceMotion.change(arriving, leaving, kinds, back, motion, _settle, _pushed)
	_switch_roots(places, state, app)


## A push has come to rest: the place it pushed out is settled, and when it
## is the latest push through its room, the room clips as it did before -
## an earlier push resting leaves the room to the one still on its way.
func _pushed(pushed_out: Control) -> void:
	var room: Control = pushed_out.get_parent()
	if _rooms.has(room) and _rooms[room][1] == pushed_out:
		room.clip_contents = _rooms[room][0]
		_rooms.erase(room)
	_settle(pushed_out)


## A place has been seen out: it, and every place inside it, hidden and
## switched back on unless the state names it again - and nothing another
## move is still seeing out.
func _settle(seen_out: Control) -> void:
	# every place, for the one seen out and those inside it the state no longer names
	for place: Control in _places.values():
		if is_instance_valid(place) and (place == seen_out or seen_out.is_ancestor_of(place)) and not _active.has(place.name):
			place.visible = false
			_seeing_out.erase(place.name)
			_switch(place, true)


## A place emptied, its token cancelled first so a result on its way lands
## on nothing. The driver calls it too, for a place leaving the tree.
static func empty(place: Node) -> void:
	(place.token as Token).cancel()
	place.empty()


## A place filled under a fresh token. The driver calls it too, for a place
## entering the tree where the path names it.
static func fill(place: Node) -> void:
	place.token = Token.new()
	place.fill()


static func _switch(root: Control, live: bool) -> void:
	root.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_INHERITED if live else Control.FOCUS_BEHAVIOR_DISABLED
	root.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_INHERITED if live else Control.MOUSE_BEHAVIOR_DISABLED
