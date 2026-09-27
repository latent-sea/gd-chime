extends RefCounted

const Shape := preload("../../shape.gd")
const Ui := preload("../primitives/ui.gd")
const Desc := preload("../primitives/desc.gd")
const NavControl := preload("nav_control.gd")
const Navigation := preload("../../theme_navigation.gd")

## Navigation that follows the window: a bar of destinations at a phone's
## foot, under what they open; a rail down the side of a tablet's or a
## desktop's window, beside it - the SAME destinations, built once, only
## re-flowed (by_shape.gd), so the focus, a scroll and a typed line survive
## the window turning or widening.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A DESTINATION IS A PLACE: each is a menu item to it (nav_control.gd), so
## it is in the history, Back returns to the one before, the one the reader
## is at is drawn CURRENT, and the move between two is the look's push
## (place_motion.gd). The window's size class (shape.gd) says which: compact
## is the bar, each destination an equal share of it; regular and wide, the
## rail. On a compact window a destination is at least the look's least
## touch size, as anything pressed is (pressable.gd).
##
## Its looks are NavBar, NavRail and NavItem, in a NavFrame
## (theme_feedback.gd).


## The destinations - each {action, goes_to} - at the foot of what they open, or down its side.
static func make(ui: Ui, destinations: Array, content: Desc) -> Desc:
	var classed: RefCounted = ui.shape.size_class
	var items: Dictionary = {}
	var shares: Dictionary = {}
	var needs: Dictionary = {}
	# every destination, a menu item to its place: an equal share of a bar, the room it needs on a rail
	for one: Dictionary in destinations:
		items[one["goes_to"]] = NavControl.menu(ui, one["action"], one["goes_to"], Navigation.NAV_ITEM)
		shares[one["goes_to"]] = {"grow": 1.0}
		needs[one["goes_to"]] = {}
	var bar := ui.row_of(items.keys(), shares, Navigation.NAV_BAR)
	var rail := ui.column_of(items.keys(), needs, Navigation.NAV_RAIL)
	var line := ui.by_shape(items, {Shape.COMPACT: bar, Shape.REGULAR: rail, Shape.WIDE: rail}, classed)
	var foot := ui.column_of([&"content", &"nav"], {&"content": {"grow": 1.0}}, Navigation.NAV_FRAME)
	var side := ui.row_of([&"nav", &"content"], {&"content": {"grow": 1.0}}, Navigation.NAV_FRAME)
	return ui.by_shape({&"nav": line, &"content": content}, {Shape.COMPACT: foot, Shape.REGULAR: side, Shape.WIDE: side}, classed)
