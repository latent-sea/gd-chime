extends RefCounted

const Events := preload("events.gd")
const Kept := preload("kept.gd")

## Where the focus was, remembered for each state, and given back.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## FOCUS SCOPES. Every state remembers a control of its own and has a
## default, and a root remembers its opener as well. THE MEMORY IS HELD
## HERE, keyed by the state's name: it holds live controls, which the state
## value never does, so the state stays a plain value with nothing shared.
## The applier (applier.gd) says when, as the chart's effects come: NOTE
## remembers the control holding the focus as a state's own, if it is inside
## it, or as a root's opener, whatever it is - before input is switched off,
## since a click gives a button the focus and raises the pop-up in the same
## frame and the switch drops the focus at once, measured on 4.6.2. GIVE
## BACK gives the focus to what one state remembers, its own or its opener,
## if it still exists, is shown and can take it, else to the DEFAULT of
## another: the first control in that place, in tree order, that is shown
## and can take the focus - THE ONE DEFINITION FOR THE FLOOR. A place with
## nothing to focus gets nothing.
##
## AN APP VIEW'S OWN FOCUS IS KEPT WITH ITS HISTORY ENTRY (kept.gd), as
## where its scroll stood is: noted into the entry being left, given back
## from the entry arrived at. Back finds it exactly where it was in that
## entry; a fresh visit is a new entry and lands on the default, never where
## the reader was last time; the same screen with other parameters is
## another entry, and so is a second visit to it; an entry the history
## drops lets it go. It
## is held weakly: a kept thing is a RefCounted, and outlives no control.
##
## A POP-UP OR THE PANEL IS NO HISTORY ENTRY: what it remembers of its own
## focus lasts only while it is up - moving between tabs inside it keeps it
## - and is forgotten as it is lowered, so the next raise lands on its
## default. What OPENED it is remembered apart and is untouched.
##
## FOCUS GIVEN BACK LANDS WHOLE, WHERE THE READER STOOD. A scroll follows
## the focus as the reader moves it, and puts back where it stood on a view
## as it is next placed after the move (scroll.gd): after the focus is given
## here, and before anything is drawn - and then moves only as far as shows
## the focused row whole, as was ruled (2026-09-19), so no frame the reader
## sees has it anywhere else.

## The name an app view's focus is kept under with its entry.
const FOCUS := &"the focus"

var _remembered: Dictionary = {}  # state name -> {Memory: the control}


## The control holding the focus remembered by this place as this - its
## opener, whatever the control; its own, only one inside the place.
func note(place: Node, viewport: Viewport, as_what: Events.Memory) -> void:
	var focused := viewport.gui_get_focus_owner()
	if as_what == Events.Memory.OWN and (focused == null or not place.is_ancestor_of(focused)):
		return
	if not _remembered.has(place.name):
		_remembered[place.name] = {}
	_remembered[place.name][as_what] = focused


## The control holding the focus, if it is inside this app view, kept with
## the entry being left.
func note_view(place: Node, viewport: Viewport, kept: Kept, entry: String) -> void:
	var focused := viewport.gui_get_focus_owner()
	if focused != null and place.is_ancestor_of(focused):
		kept.keep(entry, FOCUS, weakref(focused))


## The focus given back to what this state remembers as this, else to the
## default of this place.
func give_back(state: StringName, memory: Events.Memory, fallback: Node) -> void:
	_give(_remembered.get(state, {}).get(memory), fallback)


## The focus given back to what the entry the reader is on kept - nothing,
## on a fresh visit - else to the default of this place.
func give_back_view(kept: Kept, entry: String, fallback: Node) -> void:
	var held: WeakRef = kept.kept(entry, FOCUS)
	_give(held.get_ref() if held != null else null, fallback)


## The focus given to this control if it still stands, is shown and can
## take it - not one under a layer switched off - else to the default of
## this place.
func _give(had: Variant, fallback: Node) -> void:
	var to: Control = null
	if is_instance_valid(had) and (had as Control).is_visible_in_tree() and (had as Control).get_focus_mode_with_override() != Control.FOCUS_NONE:
		to = had
	else:
		to = default_focus(fallback)
	if to != null:
		to.grab_focus()


## Every root that stands over the rest and is not up now forgets the focus
## of its own and of every place inside it - not what opened it. kinds is
## the chart's: every root beside the app, by its kind.
func forget_lowered(places: Dictionary, up: Array, kinds: Dictionary) -> void:
	# every root beside the app that is not up, against every place something was remembered of
	for root: StringName in kinds:
		if up.has(root):
			continue
		for named: StringName in _remembered.keys():
			if named == root or (places.has(named) and (places[root] as Node).is_ancestor_of(places[named])):
				_remembered[named].erase(Events.Memory.OWN)


## The first control under this place, in tree order, that is shown and can
## take the focus - none, when nothing there can.
static func default_focus(under: Node) -> Control:
	# every child in order, itself or the first beneath it
	for child: Node in under.get_children():
		if child is Control and (child as Control).is_visible_in_tree() and (child as Control).get_focus_mode_with_override() != Control.FOCUS_NONE:
			return child
		var beneath := default_focus(child)
		if beneath != null:
			return beneath
	return null
