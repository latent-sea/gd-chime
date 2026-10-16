extends RefCounted

const Ui := preload("../primitives/ui.gd")
const Desc := preload("../primitives/desc.gd")
const NavControl := preload("nav_control.gd")
const Navigation := preload("../../theme_navigation.gd")

## Navigation that follows its own room: a bar of destinations at the foot
## of a narrow frame, under what they open; a rail down the side of a wide
## one, beside it - the SAME destinations, built once, only re-flowed
## (by_shape.gd), so the focus, a scroll and a typed line survive the frame
## narrowing or widening.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A DESTINATION IS A PLACE: each is a menu item to it (nav_control.gd), so
## it is in the history, Back returns to the one before, the one the reader
## is at is drawn CURRENT, and the move between two is the look's push
## (place_motion.gd). On a touched window a destination is at least the
## look's least touch size, as anything pressed is (pressable.gd).
##
## WHICH IS ITS OWN WIDTH'S, NEVER THE WINDOW'S OR THE DEVICE'S: the rail
## stands beside from the look's compact_below under Shape, in base pixels,
## measured on the frame itself (by_width.gd), so a frame in a side panel of
## a wide window gets the bar. The destinations are a bar wherever their
## row fits the width they are given, else a rail (by_room.gd): beside what
## they open they are given only their least, which is the rail's, and
## under it the frame's whole width.
##
## Its looks are NavBar, NavRail and NavItem, in a NavFrame
## (theme_feedback.gd).


## The destinations - each {action, goes_to} - at the foot of what they open, or down its side.
static func make(ui: Ui, destinations: Array, content: Desc) -> Desc:
	var items: Dictionary = {}
	var shares: Dictionary = {}
	# every destination, a menu item to its place: an equal share of a bar, the room it needs on a rail
	for one: Dictionary in destinations:
		items[one["goes_to"]] = NavControl.menu(ui, one["action"], one["goes_to"], Navigation.NAV_ITEM)
		shares[one["goes_to"]] = {"grow": 1.0}
	var line := ui.by_room(items, [ui.row_of(items.keys(), shares, Navigation.NAV_BAR), ui.column_of(items.keys(), {}, Navigation.NAV_RAIL)])
	var foot := ui.column_of([&"content", &"nav"], {&"content": {"grow": 1.0}}, Navigation.NAV_FRAME)
	var side := ui.row_of([&"nav", &"content"], {&"nav": {"basis": 0.0}, &"content": {"grow": 1.0}}, Navigation.NAV_FRAME)
	return ui.by_width({&"nav": line, &"content": content}, {&"foot": foot, &"side": side}, {&"foot": 0.0, &"side": &"compact_below"})
