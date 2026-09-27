extends RefCounted

const GdChime := preload("res://addons/gd_chime/gd_chime.gd")
const MobileRoute := preload("res://demo/apps/mobile/mobile_route.gd")
const MobileDepot := preload("res://demo/apps/mobile/mobile_depot.gd")

## The driver's screens, described: today's stops, a stop open and its
## delivery actions in a sheet from the foot, what waits for the signal,
## and the settings.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Description only: every piece is a recipe or a primitive over the app's
## models, every press a declared action. A stop is a swipe row
## (swipe_row.gd): right delivers it, left reports a problem, a tap opens
## it, and its menu offers the same; the list pulls to ask for the route
## again (pull_to_refresh.gd) and stands in loading's shapes until it has
## landed, a failed asking said there too; each stop says what it is
## waiting for (connection_status.gd).

## The places: the stops, one stop open, what waits, the settings.
const TODAY := &"today"
const STOP := &"stop"
const WAITING := &"waiting"
const SETTINGS := &"settings"
## A stop's status, drawn as a status mark.
const MARKS := {MobileRoute.TO_DELIVER: GdChime.Status.STILL, MobileRoute.DELIVERED: GdChime.Status.WELL, MobileRoute.PROBLEM: GdChime.Status.FAULT}
## The press opening a stop, and the one back to the list.
const OPENS := &"opens_a_stop"
const BACKS := &"back_to_the_list"
## The press raising the sheet of a stop's delivery actions.
const SHOWS_DELIVERY_ACTIONS := &"shows_the_delivery_actions"

## The sheet of a stop's delivery actions (drawer.gd), described with the stop.
var delivery: GdChime.Desc
var _ui: GdChime.Ui
var _route: MobileRoute
var _depot: MobileDepot
var _outbox: GdChime.Outbox
var _provisional: GdChime.Provisional


func _init(ui: GdChime.Ui, route: MobileRoute, depot: MobileDepot, outbox: GdChime.Outbox, provisional: GdChime.Provisional) -> void:
	_ui = ui
	_route = route
	_depot = depot
	_outbox = outbox
	_provisional = provisional


## Today's stops: how many are delivered, how the signal stands, and the
## list - pulled to refresh, loading until the route has landed.
func today() -> GdChime.Desc:
	var ui := _ui
	var head := ui.row([ui.text(GdChime.Phrase.of("Today's stops"), GdChime.Themes.WORDS).grow(), ui.button(GdChime.Fetched.ASKS_AGAIN)], GdChime.Themes.TILES)
	var done: GdChime.Desc = GdChime.Progress.make(ui, GdChime.Phrase.of("Delivered"), ui.bound(_route.get_delivered), ui.bound(_route.get_whole))
	var stops := ui.each(ui.bound(_route.get_stops), _stop_row, func(stop: Dictionary) -> int: return stop["id"])
	var listed := ui.loading(_route.stops, stops, 6)
	var body := ui.column([head, done, GdChime.ConnectionStatus.make(ui, _depot.connection, _outbox), GdChime.PullToRefresh.make(ui, _route.stops, listed).grow()])
	# the route's stops answer here, and the screen filling asks the depot for them
	return ui.screen(TODAY, [body], _route.stops, {on_fill = _route.stops.fill})


## One stop in the list: swiped right delivered, left a problem, tapped open.
func _stop_row(stop: GdChime.Bound) -> GdChime.Desc:
	var ui := _ui
	var carried: GdChime.Bound = stop.map(func(one: Variant) -> Dictionary: return {} if one == null else {"id": one["id"], "parameter": one["id"]})
	var sides := {GdChime.SwipeRow.RIGHT: {"action": MobileRoute.DELIVERS, "words": GdChime.Phrase.of("Delivered"), "state": GdChime.Status.WELL}, GdChime.SwipeRow.LEFT: {"action": MobileRoute.REPORTS, "words": GdChime.Phrase.of("Report a problem"), "state": GdChime.Status.FAULT}}
	return GdChime.SwipeRow.make(ui, OPENS, carried, ui.column(_facts(stop, false)), {sides = sides, goes_to = STOP})


## What a stop says: where, what has happened there, and what it waits for;
## and, in full, who it is for, its parcels, its window and its note.
func _facts(stop: GdChime.Bound, full: bool) -> Array:
	var ui := _ui
	var where: GdChime.Bound = stop.map(func(one: Variant) -> Variant: return "" if one == null else GdChime.Phrase.with("%d. %s", [one["id"], one["address"]]))
	var happened: GdChime.Bound = stop.map(func(one: Variant) -> Variant: return "" if one == null else GdChime.Phrase.of(MobileRoute.STATUS_WORDS[one["status"]]) if one["why"] == &"" else GdChime.Phrase.with("%s: %s", [GdChime.Phrase.of(MobileRoute.STATUS_WORDS[one["status"]]), GdChime.Phrase.of(MobileRoute.PROBLEM_WORDS[one["why"]])]))
	var mark: GdChime.Bound = stop.map(func(one: Variant) -> Variant: return null if one == null else MARKS[one["status"]])
	var waits: GdChime.Bound = GdChime.ConnectionStatus.of(_depot.connection, _provisional, stop.field("id"))
	var lines: Array = [ui.text(where, GdChime.Themes.FACE).wraps(), ui.row([GdChime.Status.make(ui, mark, happened), ui.text(waits, GdChime.Themes.REASON).hides_empty()], GdChime.Themes.TILES)]
	if full:
		var details: GdChime.Bound = stop.map(func(one: Variant) -> Variant: return "" if one == null else GdChime.Phrase.with("For %s, %s, due %s", [one["for"], GdChime.Phrase.counted("%d parcel", "%d parcels", one["parcels"]), one["window"]]))
		lines.append(ui.text(details, GdChime.Themes.REASON).wraps())
		lines.append(ui.text(stop.field("note"), GdChime.Themes.REASON).hides_empty().wraps())
	return lines


## A stop open - the one the screen is entered as - back to the list,
## everything about it, and its delivery actions in a sheet from the foot.
func stop() -> GdChime.Desc:
	var ui := _ui
	var open: GdChime.Bound = _route.stop(ui.parameter(STOP))
	delivery = GdChime.Drawer.over(ui, func(id: GdChime.Bound) -> GdChime.Bound: return id.map(func(which: Variant) -> Variant: return "" if which == null else GdChime.Phrase.with("Stop %d", [which])), _delivery, {foot = null, from = GdChime.Drawer.FROM_BOTTOM})
	var body := ui.column([ui.row([GdChime.NavControl.back(ui, BACKS)], GdChime.Themes.TILES)] + _facts(open, true) + [ui.button(SHOWS_DELIVERY_ACTIONS, {opens = delivery, with = open.field("id")})])
	return ui.screen(STOP, [ui.scroll(body, null, &"down")])


## The delivery actions for the stop the sheet is opened as: each a press
## about that stop, done and the sheet let go at once.
func _delivery(id: GdChime.Bound) -> GdChime.Desc:
	var ui := _ui
	var about := func(why: StringName) -> GdChime.Bound: return id.map(func(which: Variant) -> Dictionary: return {} if which == null else ({"id": which} if why == &"" else {"id": which, "why": why}))
	var does := func(action: StringName, why: StringName, words: GdChime.Phrase, state: StringName) -> GdChime.Desc: return ui.pressable(action, about.call(why), [GdChime.Status.make(ui, state, words, {kind = GdChime.Themes.FACE})], GdChime.Pressables.BUTTON).goes_to(GdChime.Driver.BACK)
	var offered: Array = [does.call(MobileRoute.DELIVERS, &"", GdChime.Phrase.of("Mark delivered"), GdChime.Status.WELL)]
	# every problem there may be, a press reporting it
	for why: StringName in MobileRoute.PROBLEM_WORDS:
		offered.append(does.call(MobileRoute.REPORTS, why, GdChime.Phrase.of(MobileRoute.PROBLEM_WORDS[why]), GdChime.Status.FAULT))
	offered.append(does.call(MobileRoute.UNDOES, &"", GdChime.Phrase.of("Back to still to deliver"), GdChime.Status.STILL))
	return ui.column(offered)


## What waits for the signal, and the signal itself - a switch that says it is simulated.
func waiting() -> GdChime.Desc:
	var ui := _ui
	var signal_row: GdChime.Desc = GdChime.Setting.row(ui, GdChime.Phrase.of("Signal"), GdChime.Phrase.of("Simulated: there is no phone here to lose one"), GdChime.Setting.toggle(ui, MobileDepot.SETS_SIGNAL, ui.bound(_depot.get_signal)))
	var told := ui.text(GdChime.Phrase.of("A change made without a signal is kept on the phone and marked Awaiting sync; it is sent the moment the signal is back, and one the depot refuses is put back, saying why."), GdChime.Themes.REASON).wraps()
	return ui.screen(WAITING, [ui.column([ui.text(GdChime.Phrase.of("Sync"), GdChime.Themes.WORDS), GdChime.ConnectionStatus.make(ui, _depot.connection, _outbox), signal_row, told])])


## The settings: motion reduced or not.
func settings() -> GdChime.Desc:
	var ui := _ui
	var reduced: GdChime.Desc = GdChime.Setting.row(ui, GdChime.Phrase.of("Reduce motion"), GdChime.Phrase.of("Rows, lists and screens stop gliding"), GdChime.Setting.toggle(ui, GdChime.Motion.REDUCES, ui.bound(ui.motion.get_reduced)))
	return ui.screen(SETTINGS, [ui.column([ui.text(GdChime.Phrase.of("Settings"), GdChime.Themes.WORDS), reduced])])
