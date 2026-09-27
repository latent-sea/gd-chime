extends RefCounted

const Themes := preload("../../theme.gd")
const Ui := preload("../primitives/ui.gd")
const Options := preload("../primitives/options.gd")
const Desc := preload("../primitives/desc.gd")
const Notifications := preload("../../notifications.gd")
const NotificationTray := preload("notification_tray.gd")
const Navigation := preload("../../theme_navigation.gd")

## The frame of an application shell: the bar of its commands along the
## top, the work in the middle - its panes (panes.gd) - and its foot: what
## the application says about itself, and the tray its notifications stand
## in (notification_tray.gd).
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## EVERY SHELL HOLDS THE ONE TRAY, so an application built on it has
## somewhere its notifications show without asking for one. The tray stands
## in the foot beside the status, in room the frame leaves it - never over
## the panes - and HOLDS THAT ROOM whether any notification stands or not
## (notification_tray.gd), as was ruled (2026-09-19): room for one, the
## rest waiting their turn, and the work above locked - a notification
## arriving, waiting or leaving never moves it.
## The foot stands on a ground of its own, FOOT, a surface where a look
## gives it none, so the room held empty reads as the frame's foot and
## never as a gap. Its offers are the application's: each action a
## notification may offer, and where its press goes.
##
## THE BAR IS A ROW THAT BREAKS onto more lines where its presses do not
## fit, so a window on its end keeps every command reachable; every press
## in it is the caller's, with its words and its key. The frame stands on
## the look's Pane ground.
##
## THE STATUS IS WORDS, OR A DESCRIPTION placed as it is given: a status
## that is a shape beside its words - a connection's - is never hue alone,
## so the line holds whatever the application says it with.

## How much of the foot's width the tray is given; the status has the rest.
const TRAY_SHARE := 0.4
## The foot's ground: a surface's, where a look gives it none of its own.
const FOOT := &"ShellFoot"


## The frame: the bar of presses over the work, over the status and the tray on the foot's ground.
## Its options: status, the words on the foot; notifications, the model
## the tray shows; and offers, what a notification may offer.
const OPTIONS: Array[String] = ["status", "notifications", "offers"]

static func make(ui: Ui, bar: Array, work: Desc, options: Dictionary = {}) -> Desc:
	Options.checked("a shell", options, OPTIONS)
	var status: Variant = options["status"]
	var notifications: Notifications = options["notifications"]
	var offers: Dictionary = options.get("offers", {})
	var said: Desc = status if status is Desc else ui.text(status, Navigation.STATUS).wraps()
	var foot := ui.surface(FOOT, [ui.row([said.grow(), NotificationTray.make(ui, notifications, offers).basis(TRAY_SHARE)])])
	return ui.surface(&"Pane", [ui.column([ui.row(bar, Themes.TILES), work.grow(), foot])])
