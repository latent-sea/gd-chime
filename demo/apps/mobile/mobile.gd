extends "res://addons/gd_chime/application.gd"

const GdChime := preload("res://addons/gd_chime/gd_chime.gd")
const Looks := preload("res://demo/gallery/looks/looks.gd")
const MobileDepot := preload("res://demo/apps/mobile/mobile_depot.gd")
const MobileRoute := preload("res://demo/apps/mobile/mobile_route.gd")
const MobileView := preload("res://demo/apps/mobile/mobile_view.gd")
const MobileProbe := preload("res://demo/apps/mobile/mobile_probe.gd")

## Application 8, the mobile-first application: a parcel carrier's driver
## and today's stops - swiped right as delivered, left to report a problem,
## tapped open, their actions in a sheet from the foot - working on with no
## signal, every change kept on the phone and marked Awaiting sync until it
## is back.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --path <this folder> --script res://demo/apps/mobile/mobile.gd
##       [-- --look=<a gallery look; material unless asked>] [-- --probe]
##
## EVERYTHING A PHONE NEEDS IS THE FLOOR'S: a finger's taps and gestures
## (touch.gd) - a row swiped (swipe_row.gd), a list scrolled and pulled to
## refresh (pull_to_refresh.gd) - touch targets sized for a finger on a
## phone's window, the navigation a bar at a phone's foot and a rail beside
## a wider window (adaptive_nav.gd), the loading shapes (loading.gd), the
## signal and what waits for it (connection.gd, outbox.gd), changes made at
## once and rolled back with their reason (provisional.gd). The keys, the pad
## and the pointer reach everything too: a row's menu offers its swipes.
## This file declares the actions and their keys, makes the models and
## arranges the places.

## The mobile app's own look, worn unless another is asked for: every application its own.
const OWN_LOOK := &"material"
const GOES_TODAY := &"goes_to_today"
const GOES_WAITING := &"goes_to_what_waits"
const GOES_SETTINGS := &"goes_to_the_settings"

var depot: MobileDepot
var outbox: GdChime.Outbox
var provisional: GdChime.Provisional
var route: MobileRoute
var menu: GdChime.OpenMenu
## The screens, held while the app stands: the rows are built from its template, and a probe finds the stop's sheet on it.
var view: MobileView


## The look asked for at launch, or the app's own - material.
func look() -> Theme:
	return Looks.make(Looks.asked(OWN_LOOK))


func probe() -> RefCounted:
	return MobileProbe.new(self)


## Every action with its words, and the key and pad button it is on to begin with.
func declare(register: Actions) -> void:
	register.declare_all({
		MobileView.OPENS: ["Open"],
		MobileView.BACKS: ["Back", Actions.keys(KEY_ESCAPE), Actions.pad(JOY_BUTTON_B)],
		MobileRoute.DELIVERS: ["Delivered"],
		MobileRoute.REPORTS: ["Report a problem"],
		MobileRoute.UNDOES: ["Undo"],
		MobileView.SHOWS_DELIVERY_ACTIONS: ["Delivery actions", Actions.keys(KEY_A), Actions.pad(JOY_BUTTON_X)],
		GdChime.Fetched.ASKS_AGAIN: ["Refresh", Actions.keys(KEY_F5), Actions.pad(JOY_BUTTON_Y)],
		GOES_TODAY: ["Today"],
		GOES_WAITING: ["Sync"],
		GOES_SETTINGS: ["Settings"],
		MobileDepot.SETS_SIGNAL: ["Signal"],
		Motion.REDUCES: ["Reduce motion"],
		Notifications.DISMISSES: ["Dismiss"],
		GdChime.OpenMenu.OPENS: ["More", Actions.keys(KEY_MENU), Actions.pad(JOY_BUTTON_BACK)],
		GdChime.OpenMenu.PICKS: ["Pick"],
	})


## The models made and their commands answered from anywhere; then the places.
func describe() -> Desc:
	depot = model(MobileDepot.new(chimes))
	outbox = model(GdChime.Outbox.new(chimes, depot.connection, depot.send))
	provisional = model(GdChime.Provisional.new(chimes, outbox.send, notifications))
	route = model(MobileRoute.new(chimes, provisional, depot.fetch, notifications))
	menu = model(GdChime.OpenMenu.new(chimes, commands, actions))
	view = MobileView.new(ui, route, depot, outbox, provisional)
	# the rows' menu, which every stop's row opens
	GdChime.ContextMenu.make(ui, menu)
	var places := ui.tabs(&"route", [view.today(), view.stop(), view.waiting(), view.settings()])
	var destinations := [{"action": GOES_TODAY, "goes_to": MobileView.TODAY}, {"action": GOES_WAITING, "goes_to": MobileView.WAITING}, {"action": GOES_SETTINGS, "goes_to": MobileView.SETTINGS}]
	var screen := ui.surface(GdChime.Navigation.SCREEN, [ui.column([places.grow(), GdChime.NotificationTray.make(ui, notifications)])])
	return ui.app(&"app", [GdChime.AdaptiveNav.make(ui, destinations, screen)])
