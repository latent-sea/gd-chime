extends "whereabouts.gd"

const Events := preload("events.gd")
const Motion := preload("motion.gd")
const Applier := preload("applier.gd")
const Queries := preload("queries.gd")
const Place := preload("place.gd")
const LeaveGuard := preload("leave_guard.gd")
const Paths := preload("paths.gd")

## The driver: the moves - the door's four commands and its presses that go
## somewhere, each made through the chart and carried out by the applier -
## with one bell when a move is done.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## NAVIGATION GOES THROUGH THE COMMAND DOOR. The door is built with this as
## its mover: it registers the four COMMANDS - GO {place}, GOES_BACK, LOWERS
## {place}, FORGETS - which are for code and the console, asks this whether
## a press that goes somewhere would be refused, asks this whether a command
## that moves the reader stops to ask first before any handler is told, and
## hands this the move once the action's own handler has run (commands.gd).
## A BUTTON NAVIGATES BY WHERE ITS PLACE SAYS ITS ACTION GOES, under an
## action of its own; the startup check reports a button whose action is one
## of the four.
##
## WHERE THE READER IS - the index, the state and every read of them, and
## what is kept with each history entry - is whereabouts.gd's, which this
## extends; this is the one thing that changes the state. THE INDEX
## (index.gd) is what exists, kept by the tree; THE STATE is one plain value
## - the app's path, the overlays, the panel, the remembered tabs and the
## history - changed only by the chart (chart.gd), whose transition is the
## one thing that knows what a move does; THE APPLIER (applier.gd) carries
## the effects out on the tree and keeps the focus each state remembers.
## NAVIGATED rings once, after every effect. Every other feature is a
## question over the chart, the declarations and a state (queries.gd), the
## game's refusals asked of the door: whether an action can be reached, and
## the way to it, are asked here of this state.
##
## A PLACE THAT ASKS BEFORE IT IS LEFT is the leave guard's (leave_guard.gd):
## a move that would empty it while its model refuses the leaving is stopped
## and its question raised instead, a press going ONWARD from the question
## goes on with the move, and routing treats the place as refused to leave.
##
## A MOMENT GOES THROUGH THE CHART like everything standing over the screen:
## a pop-up PRESENTED while a fact of a model holds (moment.gd) is raised as
## the fact comes to hold and lowered as it stops, by settle(), which the door
## calls at the end of every dispatch - so the move is made inside the
## command that moved the fact, never by anything hearing it move.
##
## A place leaving the tree while the path names it is emptied and its
## token cancelled as it goes, and one entering while the path names it - a
## screen rebuilt under the player - is reconciled and filled as it enters,
## so nothing lands in a freed node and nothing is left dark.

const GO := &"go"
const GOES_BACK := &"go_back"
const LOWERS := &"lower"
const FORGETS := &"forget_the_way_back"
## The four, which the door registers this for as it is built.
const COMMANDS: Array[StringName] = [GO, GOES_BACK, LOWERS, FORGETS]
## Where a press goes when it takes the reader back to where they were.
const BACK := &"where_they_were"
## Where a press goes when it takes the reader on where they were going: the
## move a place's question stopped, carried as the press's parameter.
const ONWARD := &"where_they_were_going"
## What a place asking before it is left asks the model answering for it,
## would(LEAVES, {}): the words of its question, or nothing while it may go.
const LEAVES := &"leave_the_place"

## The door, which tells this it is the mover as it is built; asked for the
## game's refusals.
var door: Object

var _applier := Applier.new()
## The one clock, handed on to the applier so places are seen to come and go; none, and they switch.
var motion: Motion = null:
	set(given):
		motion = given
		_applier.motion = given
var _guard: LeaveGuard  # made with this, as this is made
var _presented: Dictionary = {}  # a presented pop-up's name -> the bound fact it is up while


func _init(chimes: Chimes) -> void:
	super(chimes, [], Chimes.GLOBAL)
	register_bell(NAVIGATED)
	_guard = LeaveGuard.new(self)


## Whether one of the four would be refused now, without doing it.
func would(action: StringName, payload: Dictionary) -> Phrase:
	return Chart.transition(index.chart(), where(), event_of(action, payload))["refusal"]


## One of the four: done, and NAVIGATED rung.
func told(action: StringName, payload: Dictionary) -> Phrase:
	return _run(event_of(action, payload))


## Whether a press going here would be refused now: a name that is no
## place, or the chart's refusal of the move in the reader's own state; one
## going ONWARD, while no move was stopped for it to go on with.
func would_move(goes_to: StringName, parameter: Variant = null) -> Phrase:
	if goes_to == ONWARD:
		return null if parameter != null else Phrase.of("No move was stopped to go on with")
	if goes_to != BACK and not index.has_place(goes_to):
		return Phrase.with("%s is no place to go to", [goes_to])
	return Chart.transition(index.chart(), where(), Queries.move_of(goes_to, BACK, parameter))["refusal"]


## Where a press of this action in this place goes, as the place declares -
## nothing for a place that is none, or an action it does not declare.
func goes_to(place: StringName, action: StringName) -> StringName:
	return index.place_named(place).performs.get(action, &"") if index.has_place(place) else &""


## A press that goes somewhere, handed on by the door: the move it means,
## with the parameter the press carried - which one of the place's kind; one
## going ONWARD carries the move its question stopped, and goes on with it.
func move(goes_to: StringName, parameter: Variant = null) -> Phrase:
	if goes_to == ONWARD:
		return _guard.goes_on(parameter)
	return _run(Queries.move_of(goes_to, BACK, parameter))


## Asked by the door past a command's refusal, before any handler is told:
## the words of the question raised in its stead when its move would leave a
## place asking first, else nothing (leave_guard.gd).
func stops_to_ask(in_region: StringName, action: StringName, payload: Dictionary) -> Phrase:
	return _guard.stops_to_ask(in_region, action, payload)


## Whether the action can be reached now: a place on the screen declares it,
## the game does not refuse it, and pressing it leaves no place asking first.
func is_reachable(action: StringName) -> bool:
	return Queries.reachable(index.chart(), index.performs(), where(), action, _game, BACK, _guard.guarded())


## The way to the action from here, first action to last, never out of a
## place asking first; empty when none.
func route(action: StringName) -> Array[StringName]:
	return Queries.route(index.chart(), index.performs(), where(), action, _game, BACK, _guard.guarded())


## Reported out loud when a place on the screen declares this action, the
## game allows it, and no control under that place draws it: a prompt
## naming it would have nothing to press. Asked as a prompt is raised. A
## place still loading refuses through its handler, and is not reported.
func check_drawn(action: StringName) -> void:
	for named: StringName in get_top():
		var place: Node = index.place_named(named)
		if place.performs.has(action) and _game(named, action) == null and not index.draws(place, action):
			push_error("%s declares %s and nothing under it draws it" % [named, action])


## A place entering the tree while the path names it - a screen rebuilt
## under the player - reconciled and filled at once.
func entered(place: Node) -> void:
	if _is_active(place.name):
		Applier.reconcile(index.by_name(), _state, index.app)
		Applier.fill(place)


## A place leaving the tree while the path names it, emptied as it goes.
func left(place: Node) -> void:
	if _is_active(place.name):
		Applier.empty(place)


## A pop-up up while this bound fact holds - something rather than nothing
## or false - raised and lowered as the door settles.
func present(place: StringName, fact: Bound) -> void:
	_presented[place] = fact


## Every presented pop-up brought in line with its fact, as the door's last
## step: raised where the fact holds and it is down, lowered where the fact
## has stopped and it is up. A lowering refused - another pop-up over it -
## waits for the next command.
func settle() -> void:
	# every presented pop-up, moved where its fact and the state disagree
	for place: StringName in _presented:
		var fact: Variant = _presented[place].read()
		var holds: bool = fact != null and fact != false
		if holds != Paths.is_up(_state, place):
			_run(Events.Event.go(place) if holds else Events.Event.lower(place))


## The move one of the four means.
func event_of(action: StringName, payload: Dictionary) -> Events.Event:
	match action:
		GO: return Events.Event.go(payload["place"], payload.get("parameter"))
		GOES_BACK: return Events.Event.back()
		LOWERS: return Events.Event.lower(payload["place"])
	return Events.Event.forget()


func _run(event: Events.Event) -> Phrase:
	var out: Dictionary = Chart.transition(index.chart(), _state, event)
	if out["refusal"] != null:
		return out["refusal"]
	# the entry left, named before the state moves on, so what is noted as the reader goes is kept with it
	var leaving := Kept.entry_of(_state)
	_state = out["state"]
	_applier.apply(out["effects"], index.by_name(), _state, index.app, get_viewport(), strike.bind(region, NAVIGATED), index.chart()["kind"], event.kind == Events.Kind.BACK, _kept, leaving)
	# only once the move is carried out, so nothing noted into an entry the history has dropped outlives it
	_kept.let_go(_state)
	return null


## The game's refusal of an action in a place, asked of the door with no
## payload: whether any press of it could go through.
func _game(place: StringName, action: StringName) -> Phrase:
	return door.game_refusal(place, action, {})
