extends "res://demo/gallery/boxes.gd"

const Fetched := preload("res://addons/gd_chime/fetched.gd")
const TextArea := preload("res://addons/gd_chime/components/recipes/text_area.gd")
const Loading := preload("res://addons/gd_chime/components/recipes/loading.gd")
const NotificationTray := preload("res://addons/gd_chime/components/recipes/notification_tray.gd")
const Notifications := preload("res://addons/gd_chime/notifications.gd")
const Arrivals := preload("res://demo/gallery/arrivals_models.gd")

## What arrives, on a screen of the gallery's own (ARRIVALS): words a reader
## writes at length, the stock loading as the screen is shown, and the
## application's notifications arriving, staying and leaving.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The note is a text area over the draft (arrivals_models.gd), a few lines
## and one long enough to break; sending it is refused while it is empty.
## THE SCREEN'S HANDLER IS THE STOCK: entering the screen asks for it under
## the stay's token, and until it lands the stock's shapes stand where its
## lines will, and counting it says "Still loading" on the button's face; a
## press lands it and another asks again. The notifications are the
## application's own (application.gd): two presses send one with an offer
## and one without, and they stand in THE TRAY'S OWN ROOM, never over
## anything, the pad walking to them as to any press.
##
## THE TRAY STANDS STRAIGHT UNDER THE PRESSES THAT SEND TO IT, across the
## whole width, taking the room the rest leave: the note beside the stock on
## a wide window and over it on one on its end, then the presses, then the
## tray. The engine walks the pad to the nearest control that way, wherever
## across the screen it stands, so a tray off to one side would be walked
## past - to the note, or to the instruction bar under the whole screen; a
## notification straight under the press is the nearest.
##
## The tray scrolls in its room, and no row here wraps: the screens stand in
## one stack that asks the least of every screen, shown or not, and a
## wrapping row keeps a thickness it came to before the screen had a width.

## The screen, and the action that shows it.
const ARRIVALS := &"arrivals"
const SHOWS_ARRIVALS := &"shows_the_arrivals"
## The words of this screen's actions, for the gallery's register: the notifications' dismissal among them, since the tray is composed here.
const ACTIONS := {SHOWS_ARRIVALS: ["Writing, loading, notices"], Arrivals.Draft.WRITES: ["Write"], Arrivals.Draft.SENDS: ["Send the note"], Arrivals.Stock.COUNTS: ["Count the stock"], Arrivals.Stock.LANDS: ["The delivery arrives"], Fetched.ASKS_AGAIN: ["Ask for it again"], Arrivals.Sales.NOTIFIES: ["Notify"], Arrivals.Sales.NOTIFIES_WITH_OFFER: ["Notify with an offer"], Arrivals.Sales.VIEWS: ["View the sales"], Notifications.DISMISSES: ["Dismiss"]}

var _screen: Desc


func _init(stall: SceneTree) -> void:
	super(stall)
	_screen = _arrivals()


func screen() -> Desc:
	return _screen


func _arrivals() -> Desc:
	var ui: RefCounted = _stall.ui
	var draft: Arrivals.Draft = _stall.draft
	var stock: Arrivals.Stock = _stall.stock
	var writing: Desc = ui.column([TextArea.make(ui, Arrivals.Draft.WRITES, Arrivals.Draft.SENDS, {label = Phrase.of("A note to the grower"), holds = ui.bound(draft.get_words)}), ui.text(ui.bound(draft.get_sent), DemoTheme.READOUT)], DemoTheme.TIGHT)
	var stocked: Desc = ui.column([ui.text(Phrase.of("Forty crates of plums"), DemoTheme.READOUT), ui.text(Phrase.of("Twelve crates of figs"), DemoTheme.READOUT), ui.text(Phrase.of("Nine crates of pears"), DemoTheme.READOUT)], DemoTheme.TIGHT)
	var presses: Desc = ui.row([ui.button(Arrivals.Stock.COUNTS), ui.button(Arrivals.Stock.LANDS), ui.button(Fetched.ASKS_AGAIN)])
	var loading: Desc = ui.column([ui.loading(stock.delivery, stocked, 3), presses, ui.text(ui.bound(stock.get_counted), DemoTheme.READOUT)], DemoTheme.TIGHT)
	# the tray scrolled in the room it is given, so however many stand it asks the screen for none more
	var tray: Desc = ui.scroll(NotificationTray.make(ui, _stall.notifications, {Arrivals.Sales.VIEWS: &""}).named(&"tray")).grow()
	# the presses that send, what was last viewed, and the tray straight under them taking the rest
	var notifying: Desc = ui.column([ui.row([ui.button(Arrivals.Sales.NOTIFIES), ui.button(Arrivals.Sales.NOTIFIES_WITH_OFFER)]), ui.text(ui.bound(_stall.sales.get_viewed), DemoTheme.READOUT), tray], DemoTheme.TIGHT)
	var parts := {&"writing": _shown(Phrase.of("Text area"), Phrase.of("Enter breaks a line; only the button sends it, and never empty"), writing), &"loading": _shown(Phrase.of("Loading"), Phrase.of("Shapes stand in until it lands; counting waits"), loading)}
	var halves := {&"writing": {"grow": 1.0}, &"loading": {"grow": 1.0}}
	# the note beside the stock on a wide window; on a window on its end, over it
	var work: Desc = ui.by_shape(parts, {Shape.LANDSCAPE: ui.row_of(parts.keys(), halves), Shape.PORTRAIT: ui.column_of(parts.keys())})
	# the work, and the notifications under it taking the room it leaves
	var arranged: Desc = ui.column([work, _shown(Phrase.of("Notifications"), Phrase.of("Each stands in the tray below, never over anything, sounds, and leaves"), notifying.grow()).grow()])
	# the stock and what it fills with both answer here; the screen filling asks for the delivery
	return ui.screen(ARRIVALS, [arranged], [stock, stock.delivery], {on_fill = stock.delivery.fill})
