extends RefCounted

const Themes := preload("../../theme.gd")
const Fields := preload("../../theme_fields.gd")
const Dates := preload("../../dates.gd")
const Calendar := preload("../../calendar.gd")
const Ui := preload("../primitives/ui.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Pressables := preload("../../theme_pressables.gd")

## A date field: a day typed in the language's order, beside a press that
## opens the calendar to pick one.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## IT HOLDS NOTHING. The day is the model's, a bound value reading a day -
## days since the first of January 1970 (dates.gd) - or none; or a line the
## model holds as typed, not yet a day, which the field shows as it stands,
## so a half-typed date is never lost. What the field shows of a day is the
## day typed in the language's order: 19/09/2026 in English.
##
## ONE PAYLOAD FOR TYPING AND FOR PICKING: every change of the line, and a
## day picked from the calendar, dispatches the caller's action with
## {"value": the day, or null where the line names none, "line": the line}.
## A model holding days reads "value" and may refuse null, the field saying
## why under its line; a form reads "line" and keeps it.
##
## THE CALENDAR IS ONE POP-UP beside the app (calendar.gd,
## calendar_sheet.gd), described once and handed to every field: the opener
## opens it carrying this field's action and the day held as the pop-up's
## parameter, and a pick is this field's own press, sent on through the door.


## The field over the model's day, typing and picking through this action,
## opening this calendar (calendar_sheet.gd).
static func make(ui: Ui, action: StringName, shows: Bound, calendar: Desc) -> Desc:
	var style := Fields.DATE_FIELD
	var line: Bound = shows.map(func(held: Variant) -> String: return "" if held == null else held if held is String else Dates.typed(held))
	var carries := func(typed: String) -> Dictionary: return {"value": Dates.parsed(typed), "line": typed}
	var typed := ui.field(action, Fields.FIELD, {"shows": line, "changes": action, "carries": carries})
	# the calendar opened as this field: its action, and the day it holds - a typed line read as one, where it is
	var opened: Bound = shows.map(func(held: Variant) -> Dictionary: return {"parameter": {"action": action, "day": Dates.parsed(held) if held is String else held}})
	var opener := ui.pressable(Calendar.OPENS, opened, [ui.text(ui.words(Calendar.OPENS), Themes.FACE)], Pressables.BUTTON).opens(calendar)
	return ui.row([typed.grow(), opener], style)
