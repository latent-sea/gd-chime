extends "presentation.gd"

const Token := preload("token.gd")
const Going := preload("components/primitives/going.gd")

## A place: a node that competes with its siblings for the screen - a
## screen, a tab, a pop-up - a state of the statechart the driver runs, and
## the declaration of what it performs.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THERE IS ONE TREE, AND THE NODES ARE IT. Nesting is parent and child: a
## tab is a place because it was built inside its screen, and a card in the
## tab is not a place, it sits in one. A place's NAME is its identity,
## unique across the whole application - the engine's unique names hold
## within one scene, so this is our rule: every place puts itself in the
## index (index.gd) as it enters the tree, which refuses a second of one
## name out loud, and takes itself out as it leaves - and its name is its
## region: every bell hung and every command registered by what is inside
## it belongs to that name, and closing the place drops them.
##
## A PLACE DECLARES WHAT IT PERFORMS: performs maps each action a press in
## it dispatches to where that press goes - a place name, the driver's BACK
## or ONWARD, or nothing for an action that goes nowhere - set as the place
## is built, and there whether the place is filled or not. A button in the
## place draws one of its actions and reads where it goes from here; a button
## built as the place fills works the same way, as long as the action is
## declared, and one built for an action not declared is reported out loud
## as it enters. Routing asks the declarations and the state, never a
## button (queries.gd). It holds the model that answers for it, and may
## name a pop-up that asks before the reader leaves it, which the leave
## guard raises while that model refuses the leaving (leave_guard.gd).
##
## A PLACE IS PASSIVE. It listens to nothing, works nothing out and never
## reads whether it is shown: the driver (driver.gd) runs the statechart
## (chart.gd) and its applier (applier.gd) shows, fills, empties and hides
## each place in the one fixed order, whichever way anything was built. It
## is built hidden, and nothing is shown before the first arrival.
##
## STRUCTURE EXISTS FROM STARTUP; DATA LOADS WHEN SHOWN. Every place, its
## tabs, its links and its lists are built at startup, empty and cheap, so
## a way can be found to any declared action before the reader has ever
## opened its place. What is fetched - records, rows, meshes, views - is
## loaded as the place is entered, in fill(), and freed as it is left, in
## empty(): a subclass overrides both, and the base does nothing. Entering
## issues a TOKEN and leaving cancels it (token.gd): what fill() sets
## loading is handed the token and asks it before its result lands, so
## nothing lands on a place the reader has left. A screen is filled before
## its tabs and its tabs emptied before it. A place leaving the tree while
## the path names it is emptied and its token cancelled by the driver as it
## goes, and one entering while the path names it is shown and filled as it
## enters.
##
## A PLACE TAKES THE ROOM WHAT IT HOLDS NEEDS. It needs as much as any piece
## inside it - hidden ones too, since a screen says the room it needs when it
## is FULL (presentation.gd), so switching its tabs never moves what holds it
## - and gives every piece the whole of itself as it is placed, telling a
## shift riding on one (shift.gd); a piece going (going.gd) is neither
## measured nor placed. So a screen needing more than it is given pushes what
## lies below it on, and is never drawn over it.
##
## Child places are the nearest places beneath this one, in tree order,
## through any container that is not a place - a tab row between a screen
## and its tabs changes nothing - and the first child is the one a move
## here enters before it was ever on one. A root place beside the app is an
## overlay, blocking everything beneath while it is up, unless it says it
## blocks nothing, as the developer's console does.
##
## Its contents are described and built by the builder (ui.gd), which
## declares what it performs from the pressables inside it.
##
## Deliberately absent: closing, which is the subtree going away (closing.gd).

## What a press here performs, and where it goes: action -> a place name,
## the driver's BACK or ONWARD, or nothing. Set as the place is built.
var performs: Dictionary = {}
## The model that answers for this place - told its actions, and asked
## whether it may be left - or none. Set as the place is built.
var handled_by: Object = null
## The pop-up that asks before the reader leaves this, while handled_by
## refuses the leaving - would(Driver.LEAVES, {}) the words it asks; none,
## and this is left without asking. Set as the place is built.
var asks_before_leaving: StringName = &""
## Whether this root blocks everything beneath while it is up. Read as the
## index reads the chart; a panel that blocks nothing sets it false.
var blocks: bool = true
## The token of the reader's stay here: issued as this is entered, cancelled
## as it is left; none before the first entering.
var token: Token = null
## Which one of its kind this is entered as - the item, the round - set
## by the driver as this fills; nothing for a place of one.
var parameter: Variant = null
## The driver this place is in, and its index; a button inside reaches both
## through this.
var driver: Node
var index: RefCounted


func _init(chimes: Chimes, named: StringName, runs: Node) -> void:
	super(chimes, [], named)
	name = named
	driver = runs
	index = runs.index
	visible = false


## What inside it arrives by a transition of its own each time this is shown: [the node, the transition].
var arriving: Array = []
var _gone: bool = false  # whether it has given up its name and its stay


## Entering the tree, indexed by name and, when the path names it, filled;
## leaving it, taken out and, when the path names it, emptied.
func _enter_tree() -> void:
	_gone = false
	index.add_place(self)
	driver.entered(self)


func _exit_tree() -> void:
	_give_up()


## Told that something over it is set going (going.gd): no longer a place
## the reader can be at, from this moment and not from when it is at last
## freed - so what arrives in its stead may have the name while this is
## still drawn. The name is given up as a node's too: two children of one
## holder cannot share one, and the engine would rename the one arriving.
func going() -> void:
	_give_up()
	name = StringName("%s, going" % name)


## Its stay ended and its name taken out of the index, once.
func _give_up() -> void:
	if _gone:
		return
	_gone = true
	driver.left(self)
	index.remove_place(self)


## What a place described rather than subclassed does as it fills and
## empties: given the token of the stay, and nothing. Left unset, nothing.
var on_fill: Callable
var on_empty: Callable


## Load what this place shows, as it is entered. The base loads nothing but
## what it was told to.
func fill() -> void:
	if on_fill.is_valid():
		on_fill.call(token)


## Free what this place loaded, as it is left.
func empty() -> void:
	if on_empty.is_valid():
		on_empty.call()


## As much room as any piece inside needs, hidden or shown, but a piece going.
func _get_minimum_size() -> Vector2:
	var least := Vector2.ZERO
	# every piece held, but one on its way out, for the room it needs
	for child: Node in get_children():
		if child is Control and not Going.is_going(child):
			least = least.max((child as Control).get_combined_minimum_size())
	return least


## Placed again: every piece but one going given the whole of this, at the
## scale it had reached - fitting sets a piece's scale back, and one
## arriving by a scale of its own (transition.gd) is part way in - and a
## shift riding on one told (shift.gd).
func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		# every piece held, but one on its way out, fitted to the whole of this and left at its scale
		for child: Node in get_children():
			if child is Control and not Going.is_going(child):
				var reached := (child as Control).scale
				fit_child_in_rect(child, Rect2(Vector2.ZERO, size))
				(child as Control).scale = reached
				if child.has_node(^"Shift"):
					child.get_node(^"Shift").placed()


## The nearest places beneath this one, in tree order, through any container
## that is not a place.
func places() -> Array:
	var found: Array = []
	_gather(self, found)
	return found


## Every place under this node into found, in tree order, stopping at each.
func _gather(node: Node, found: Array) -> void:
	# every child in order, a place itself or searched for places
	for child: Node in node.get_children():
		if index.is_place(child):
			found.append(child)
		else:
			_gather(child, found)
