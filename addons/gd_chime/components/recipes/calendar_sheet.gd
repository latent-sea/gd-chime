extends RefCounted

const Themes := preload("../../theme.gd")
const Fields := preload("../../theme_fields.gd")
const Calendar := preload("../../calendar.gd")
const Phrase := preload("../../phrase.gd")
const Ui := preload("../primitives/ui.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Sheet := preload("sheet.gd")
const Setting := preload("setting.gd")

## The calendar's pop-up: the month shown between the presses turning it,
## the days of the week, six weeks of days to pick from, and a way out.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## ONE POP-UP BESIDE THE APP serves every date field (calendar.gd): the
## caller describes it once and hands it to each field, which opens it, and
## the builder lifts it. It stands on a sheet over the window, as a choice's
## options do, so nothing beneath is reached while it is up; its way out is
## every pop-up's.
##
## EVERY WAY OF HAND WORKS IT. The days are pressables in a grid of seven
## columns, so the arrows and the pad walk them by where they stand; the
## month turns by its two presses and by their keys and pad buttons, held
## by the register (Calendar.SHOWS_MONTH_BEFORE, LATER); Escape and the pad's B close
## it. As it opens the focus lands on the field's day, or the month's first
## (arrival_focus.gd). A day the field's model would refuse is drawn inert,
## saying why, as any press is.
##
## THE DAYS ARE KEPT BY THEIR PLACE IN THE GRID, not by the day: a month
## turned re-reads the same forty-two presses, each wearing its day's look -
## chosen, today, of another month, or plain - so nothing is built again and
## the grid never changes shape.

## A day's look by its state, as the calendar answers it.
const WORN := {&"chosen": Fields.DAY_CHOSEN, &"today": Fields.DAY_TODAY, &"outside": Fields.DAY_OUTSIDE, &"in": Fields.DAY}
## The marks on the presses turning the month: data, the same in every language.
const BEFORE := "<"
const AFTER := ">"
## What the calendar's pop-up is of, in its name.
const KIND := &"calendar"


## The pop-up over this calendar, for every date field to open.
static func make(ui: Ui, calendar: Calendar, style: StringName = Setting.SHEET) -> Desc:
	return ui.pop_up(KIND, func(opened: Bound) -> Desc: return _sheet(ui, calendar, opened, style))


## The month over its days, for the field it is opened as.
static func _sheet(ui: Ui, calendar: Calendar, opened: Bound, style: StringName) -> Desc:
	var head := ui.row([ui.pressable(Calendar.SHOWS_MONTH_BEFORE, {}, [ui.text(BEFORE, Themes.FACE)]), ui.text(ui.bound(calendar.get_title), Themes.FACE).grow(), ui.pressable(Calendar.SHOWS_MONTH_AFTER, {}, [ui.text(AFTER, Themes.FACE)])])
	var weekdays := ui.row(Calendar.WEEKDAY_WORDS.map(func(day: String) -> Desc: return ui.text(Phrase.of(day), Themes.REASON).basis(1.0 / 7.0)), Fields.WEEK)
	# the forty-two days cut into six weeks of seven
	var weeks: Bound = ui.bound(calendar.get_days).map(func(days: Array) -> Array: return range(6).map(func(week: int) -> Array: return days.slice(week * 7, week * 7 + 7)))
	var week := func(days: Bound) -> Desc: return ui.each_across(days, func(day: Bound) -> Desc: return _day(ui, calendar, opened, day), func(day: Dictionary) -> Variant: return day["at"], Fields.WEEK)
	var grid := ui.each(weeks, week, func(days: Array) -> Variant: return days[0]["at"])
	return Sheet.over(ui, [head, weekdays, grid, Sheet.close(ui)], style)


## One day: its number, pressed to pick it for the field the calendar is
## opened as, worn as its state says, taking the focus as the calendar
## opens where it is the day to land on.
static func _day(ui: Ui, calendar: Calendar, opened: Bound, day: Bound) -> Desc:
	var picks: Bound = Bound.both(day, opened, func(one: Variant, up: Variant) -> Dictionary: return {} if one == null else {"value": one["value"], "for": up})
	var worn: Bound = day.map(func(one: Variant) -> StringName: return Fields.DAY if one == null else WORN[one["state"]])
	var lands: Bound = Bound.both(day, ui.bound(calendar.get_focused), func(one: Variant, focused: Variant) -> bool: return one != null and one["value"] == focused)
	return ui.arrival_focus(lands, [ui.pressable(Calendar.PICKS, picks, [ui.text(day.field("words"), Themes.FACE)], worn)]).basis(1.0 / 7.0)
