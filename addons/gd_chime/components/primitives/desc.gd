extends RefCounted

## A description of a piece of interface: what kind of primitive, what it is
## given, and what it holds. A recipe returns one; the builder (ui.gd) turns
## one into nodes, top-down, and does not keep it.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The facts are how a layout above it treats it - grow, basis, span - the
## same words flex.gd and grid.gd take, set by chaining: ui.text("a").grow().
## A description carries no node and no engine call; it is data a UI builder
## writes, and the primitives are the only readers of it. A pop-up a press
## opens travels on the press (opens), so every description is one value:
## never a pair of a piece and the pop-up it needs.
##
## A MARK ON A DESCRIPTION IS A CHAINED NAME, never a boolean parameter -
## wraps, hides_empty, keeps, fits, takes_focus, blocks_nothing - because
## what a bare true at a call site marks cannot be read off the call
## (options.gd). A mark not said is simply a name not chained.

var kind: StringName
var props: Dictionary
var children: Array = []  # of Desc
var facts: Dictionary = {}


func _init(of_kind: StringName, given: Dictionary = {}, holding: Array = []) -> void:
	kind = of_kind
	props = given
	children = holding


## How much of the room left this takes, in a row or a column.
func grow(by: float = 1.0) -> RefCounted:
	facts["grow"] = by
	return self


## Its starting share of the row or column, a fraction of the layout.
func basis(share: float) -> RefCounted:
	facts["basis"] = share
	return self


## The most of the row or column it may take, a fraction of the layout.
func at_most(share: float) -> RefCounted:
	facts["max"] = share
	return self


## How many columns of a grid it spans.
func span(columns: int) -> RefCounted:
	facts["span"] = columns
	return self


## Words broken onto more lines at the width they are given: words longer
## than their room wrap rather than widen what holds them.
func wraps() -> RefCounted:
	props["wraps"] = true
	return self


## Words gone from the screen while they are empty, rather than standing as
## a blank line of their own height.
func hides_empty() -> RefCounted:
	props["hides_empty"] = true
	return self


## A when whose side not showing is kept hidden rather than freed, so what
## it holds - a half-typed line - survives being turned away from.
func keeps() -> RefCounted:
	props["keeps"] = true
	return self


## A long list showing as many rows as its own height holds, rather than
## asking for the height of all of them.
func fits() -> RefCounted:
	props["fits"] = true
	return self


## A line or an area that takes the focus as it is built, so the reader
## types into it without reaching for it.
func takes_focus() -> RefCounted:
	props["takes_focus"] = true
	return self


## A pop-up that blocks nothing beneath it - a panel, which the reader may
## keep open while working under it.
func blocks_nothing() -> RefCounted:
	props["blocks"] = false
	return self


## A pressable that is pressed again while held: after the wait, then
## every interval, in seconds.
func repeats(wait: float, interval: float) -> RefCounted:
	props["repeat"] = [wait, interval]
	return self


## A pressable that never takes the focus: a click presses it, and the keys
## walk past it - a page's tab beside a line being typed into.
func no_focus() -> RefCounted:
	props["no_focus"] = true
	return self


## A pressable gone from the screen, rather than inert, while the door
## would refuse it: a transport owed a decision, a way in that is not one.
func absent_when_refused() -> RefCounted:
	props["absent"] = true
	return self


## A pressable drawn current while this bound value holds, wherever its press
## goes: the flap of the file in front, which is a model's fact.
func current_while(held: RefCounted) -> RefCounted:
	props["current_while"] = held
	return self


## How it arrives and goes, for a thing that swaps - a when, an each: a
## transition's name (transition.gd), in place of the one the look names.
func transition(kind: StringName) -> RefCounted:
	props["transition"] = kind
	return self


## How it arrives each time the place it stands in is shown: a transition's
## name (transition.gd) - the sheet of a pop-up scaling in over its shade.
func arrives(kind: StringName) -> RefCounted:
	props["arrives"] = kind
	return self


## Where a press goes: the name of the place it moves the reader to, which
## that place's move carries the payload to.
func goes_to(place: StringName) -> RefCounted:
	props["goes_to"] = place
	return self


## A press that opens this pop-up: it goes there, and the pop-up - lifted
## beside the app by the builder wherever it was described - comes with it.
func opens(overlay: RefCounted) -> RefCounted:
	props["goes_to"] = overlay.get_place()
	props["overlay"] = overlay
	return self


## The name of the place this describes: a pop-up's, the builder's (describe_places.gd).
func get_place() -> StringName:
	return props["name"]


## A name whoever builds this can find the node by afterwards, as an anchored
## piece finds what it is attached to.
func named(id: StringName) -> RefCounted:
	props["id"] = id
	return self


## Every piece of an each named after its key, under this prefix.
func pieces_named(prefix: StringName) -> RefCounted:
	props["pieces_named"] = prefix
	return self
