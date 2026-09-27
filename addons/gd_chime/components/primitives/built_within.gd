extends "built_names.gd"

## Where the builder stands as it builds: the place, the pressable and the
## look what is built now stands inside, which a piece asks as it is made -
## its region, the place its press declares in, the answers its content
## reads, the look a place lifts its pop-ups in (place_builder.gd).
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The builder (ui.gd) extends this and moves it as it builds: a place or a
## pressable made is the one built into for what it holds, a piece wearing a
## look of its own is the look it is built under, and the one before is
## stood in again once that is built. It stands apart because it is the
## builder's position and nothing else - it never builds, and never outlives
## the build it describes; a piece that builds again later keeps what it was
## built inside and says so as it builds (each.gd, when.gd).
##
## THE LOOK IS CARRIED, NEVER READ OFF THE TREE: a when builds the side it
## first shows as it is made, before it stands in anything, so what it
## builds has no way up to the root yet. A when keeps the look beside the
## place, since either side may hold a place lifting pop-ups; a template's
## pieces keep none, since a pop-up is never described inside a template.

var _place: Node = null  # the place being built into
var _pressable: Node = null  # the pressable being built into
var _look: Theme = null  # the look being built under: a themed piece's, a pop-up's, or none and the root's


## The place being built into now, for a piece that will build again later.
func current_place() -> Node:
	return _place


## The pressable being built into now, whose answers its content may read.
func current_pressable() -> Node:
	return _pressable


## The look what is built now is built under: none, and it wears the
## root's, which it follows as the root's changes.
func current_look() -> Theme:
	return _look


## The region what is built now belongs to: the place's name.
func region() -> StringName:
	return _place.name if _place != null else Chimes.GLOBAL
