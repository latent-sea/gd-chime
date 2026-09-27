extends SceneTree

## What must be true of a date field, the one calendar every date field
## opens, and an amount field given what its model holds (date_field.gd,
## calendar.gd, calendar_sheet.gd, amount_field.gd): a day typed carries the
## day and the line on every keystroke, and a model holding days shows its
## day typed in the language's order; a line naming no day carries none, a
## model of days refusing it says why under the line, and a model keeping
## lines keeps the half-typed one and shows it again as it stands; the
## opener raises the calendar as that field, on the month of its day with
## the focus on the day; the keys and the pad turn the month and the arrows
## walk the days; a pick lowers the calendar and is the field's own press,
## the focus back on the opener; a day the field's model refuses is inert on
## the calendar, saying why, before it is picked; with no day held it opens
## on today's month, today ringed with its number inside the ring; Escape
## closes it having picked nothing; and an amount
## field is as it was without what the model holds, shows the model's amount
## with it, and keeps a half-typed amount.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_date_field.gd

const Fixture := preload("res://tests/fixture.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Fields := preload("res://addons/gd_chime/theme_fields.gd")
const Dates := preload("res://addons/gd_chime/dates.gd")
const Calendar := preload("res://addons/gd_chime/calendar.gd")
const DateField := preload("res://addons/gd_chime/components/recipes/date_field.gd")
const CalendarSheet := preload("res://addons/gd_chime/components/recipes/calendar_sheet.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const AmountField := preload("res://addons/gd_chime/components/recipes/amount_field.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Verdict := preload("res://tests/verdict.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")

const SETS_DAY := &"sets_the_day"
const KEEPS_LINE := &"keeps_the_line"
const SETS_SUM := &"sets_the_sum"
const COMMITS := &"commits"

var _verdict := Verdict.new()
var _sheet: Desc  # the calendar's pop-up, described once for every field to open

var _made: Fixture
var _held: Held
var _calendar: Calendar


## A model of the answers: a day, refusing none and any day after the last it
## allows; a line kept as typed; a sum kept as typed; and every payload told.
class Held extends Fixture.Model:
	var told_payloads: Array = []
	var last_day: int = 0  # the last day taken; any later is refused

	func would(action: StringName, payload: Dictionary) -> Phrase:
		if action == SETS_DAY and payload["value"] == null:
			return Phrase.of("that is no date")
		if action == SETS_DAY and payload["value"] > last_day:
			return Phrase.of("too late")
		return null

	func told(action: StringName, payload: Dictionary) -> Phrase:
		told_payloads.append(payload)
		match action:
			SETS_DAY: set_value(&"day", payload["value"])
			KEEPS_LINE: set_value(&"line", payload["line"])
			SETS_SUM: set_value(&"sum", payload["line"])
		return null

	func get_day() -> Variant:
		return of(&"day").read()

	func get_line() -> Variant:
		return of(&"line").read()

	func get_sum() -> Variant:
		return of(&"sum").read()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(1280, 800)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_a_day_typed_carries_the_day_and_the_line_and_a_held_day_is_shown_typed)
	await _verdict.states(_a_line_naming_no_day_is_refused_by_a_model_of_days_and_kept_by_a_model_of_lines)
	await _verdict.states(_the_opener_raises_the_calendar_on_the_fields_month_with_the_focus_on_its_day)
	await _verdict.states(_the_keys_and_the_pad_turn_the_month_and_the_arrows_walk_the_days)
	await _verdict.states(_a_pick_lowers_the_calendar_and_is_the_fields_own_press)
	await _verdict.states(_a_day_the_fields_model_refuses_is_inert_on_the_calendar_before_it_is_picked)
	await _verdict.states(_with_no_day_held_it_opens_on_todays_month_and_escape_closes_it)
	await _verdict.states(_an_amount_field_is_as_it_was_without_the_model_and_keeps_its_amount_with_it)
	quit(_verdict.deliver(get_script()))


func _frames() -> void:
	await process_frame
	await process_frame
	await process_frame


## A screen of a date field over the model's day, one over its kept line, an
## amount field over its sum and one given nothing; the calendar beside.
func _built(day: Variant = null) -> void:
	_made = Fixture.new(root, {SETS_DAY: "set the day", KEEPS_LINE: "keep the line", SETS_SUM: "set the sum", COMMITS: "commit"})
	_held = Held.new(_made.chimes)
	_held.last_day = Dates.day_of(2030, 1, 1)
	_held.set_value(&"day", day)
	_held.set_value(&"line", null)
	_held.set_value(&"sum", null)
	_calendar = Calendar.new(_made.chimes, _made.commands)
	_calendar.declare(_made.actions)
	# the calendar's keys and pad buttons taken as the map's own, as an application declaring them first has them
	_made.inputs.restore_defaults()
	for action: StringName in [SETS_DAY, KEEPS_LINE, SETS_SUM, COMMITS]:
		_made.commands.register(Chimes.GLOBAL, action, _held)
	var ui := _made.ui
	_sheet = CalendarSheet.make(ui, _calendar)
	var fields := [DateField.make(ui, SETS_DAY, Bound.new(_held.get_day), _sheet).named(&"days"), DateField.make(ui, KEEPS_LINE, Bound.new(_held.get_line), _sheet).named(&"lines"), AmountField.make(ui, SETS_SUM, "£", {style = &"AmountField", holds = Bound.new(_held.get_sum)}).named(&"sum"), AmountField.make(ui, COMMITS, "£").named(&"bare")]
	ui.build(ui.app(&"app", [ui.screen(&"desk", [ui.column(fields)])]), root)
	ui.build(_sheet, root)
	_made.commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": &"desk"})
	await _frames()


func _done() -> void:
	_calendar.free()
	_held.free()
	_made.done()


## The line of the field named so.
func _line(named: StringName) -> LineEdit:
	return _made.ui.node_named(named).find_children("*", "LineEdit", true, false)[0]


## Keys typed into the line of the field named so, one at a time, as a hand would.
func _type(named: StringName, words: String) -> void:
	_line(named).grab_focus()
	# every letter, pressed and let go
	for letter: String in words:
		_press_key(KEY_NONE, letter.unicode_at(0))
	await _frames()


func _press_key(code: Key, letter: int = 0) -> void:
	var key := InputEventKey.new()
	key.keycode = code
	key.unicode = letter
	key.pressed = true
	root.push_input(key)
	var up: InputEventKey = key.duplicate()
	up.pressed = false
	root.push_input(up)


func _press_pad(button: JoyButton) -> void:
	var press := InputEventJoypadButton.new()
	press.button_index = button
	press.pressed = true
	root.push_input(press)
	var up: InputEventJoypadButton = press.duplicate()
	up.pressed = false
	root.push_input(up)


## The press of this action under this node.
func _press_of(under: Node, action: StringName) -> Pressable:
	return under.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable and (part as Pressable).action == action)[0]


## The calendar's press of this day.
func _day_press(day: int) -> Pressable:
	var calendar := _made.driver.index.place_named(_sheet.get_place())
	return calendar.find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Pressable and (part as Pressable).action == Calendar.PICKS and (part as Pressable).payload().get("value") == day)[0]


func _opens(named: StringName) -> void:
	_press_of(_made.ui.node_named(named), Calendar.OPENS).pressed()
	await _frames()


func _a_day_typed_carries_the_day_and_the_line_and_a_held_day_is_shown_typed() -> void:
	await _built(Dates.day_of(2026, 9, 19))
	_verdict.check(_line(&"days").text == "19/09/2026", "the model's day is shown typed in the language's order: %s" % _line(&"days").text)
	_line(&"days").clear()
	await _type(&"days", "1/2/2025")
	# the last payload told, or nothing where the door told none
	var last: Variant = null if _held.told_payloads.is_empty() else _held.told_payloads.back()
	_verdict.check(last == {"value": Dates.day_of(2025, 2, 1), "line": "1/2/2025"} and _held.get_day() == Dates.day_of(2025, 2, 1), "typed, the last keystroke carries the day and the line: %s" % [last])
	_verdict.check(_line(&"days").text == "01/02/2025", "a model of days shows the day it took typed in the language's order: %s" % _line(&"days").text)
	await _type(&"lines", "1/2/2025")
	_verdict.check(_line(&"lines").text == "1/2/2025" and _line(&"lines").caret_column == 8 and _held.told_payloads.back() == {"value": Dates.day_of(2025, 2, 1), "line": "1/2/2025"}, "a model of lines, told the day and the line, holds the line as typed; it stands as typed, the caret at its end: %s" % [_held.told_payloads.back()])
	_done()


func _a_line_naming_no_day_is_refused_by_a_model_of_days_and_kept_by_a_model_of_lines() -> void:
	await _built(Dates.day_of(2026, 9, 19))
	_line(&"days").clear()
	await _type(&"days", "31/02/2026")
	var words: Array = _made.ui.node_named(&"days").find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Text and (part as Text).is_visible_in_tree()).map(func(part: Text) -> String: return part.get_text())
	_verdict.check(words.has("that is no date") and _held.get_day() == Dates.day_of(2026, 9, 19), "a model of days refuses a line naming none, and says why under the line, its day kept: %s" % [words])
	await _type(&"lines", "19/0")
	_verdict.check(_held.get_line() == "19/0" and _held.told_payloads.back() == {"value": null, "line": "19/0"}, "a model of lines keeps the half-typed line, carried with no day: %s" % [_held.told_payloads.back()])
	var desk := _made.driver.index.place_named(&"desk")
	_made.ui.build(DateField.make(_made.ui, KEEPS_LINE, Bound.new(_held.get_line), _sheet).named(&"again"), desk, desk)
	await _frames()
	_verdict.check(_line(&"again").text == "19/0", "and a field built again over it shows it as it stands: %s" % _line(&"again").text)
	_done()


func _the_opener_raises_the_calendar_on_the_fields_month_with_the_focus_on_its_day() -> void:
	var day := Dates.day_of(2026, 9, 19)
	await _built(day)
	await _opens(&"days")
	_verdict.check(_made.driver.get_top() == [_sheet.get_place()] and _made.driver.get_parameter(_sheet.get_place()) == {"action": SETS_DAY, "day": day}, "the opener raises the calendar as this field, its action and its day: %s" % [_made.driver.get_parameter(_sheet.get_place())])
	_verdict.check(str(_calendar.get_title()) == "September 2026" and _calendar.get_days()[0]["value"] == Dates.day_of(2026, 8, 31), "on the month of its day, six weeks from the Monday before the first: %s" % _calendar.get_title())
	_verdict.check(root.gui_get_focus_owner() == _day_press(day) and _day_press(day).theme_type_variation == &"CalendarDayChosen", "the focus lands on its day, worn chosen")
	_done()


func _the_keys_and_the_pad_turn_the_month_and_the_arrows_walk_the_days() -> void:
	var day := Dates.day_of(2026, 9, 19)
	await _built(day)
	await _opens(&"days")
	_press_key(KEY_RIGHT)
	await _frames()
	_verdict.check(root.gui_get_focus_owner() == _day_press(day + 1), "the right arrow walks to the next day")
	_press_key(KEY_PAGEDOWN)
	await _frames()
	var after := str(_calendar.get_title())
	_press_pad(JOY_BUTTON_LEFT_SHOULDER)
	_press_pad(JOY_BUTTON_LEFT_SHOULDER)
	await _frames()
	_verdict.check(after == "October 2026" and str(_calendar.get_title()) == "August 2026", "Page Down turns to October; the pad's left shoulder twice back to August: %s, %s" % [after, _calendar.get_title()])
	for turned: int in 5:
		_made.commands.dispatch(Chimes.GLOBAL, Calendar.SHOWS_MONTH_AFTER, {})
	_verdict.check(str(_calendar.get_title()) == "January 2027", "turned on past December, the year turns with it: %s" % _calendar.get_title())
	_done()


func _a_pick_lowers_the_calendar_and_is_the_fields_own_press() -> void:
	await _built(Dates.day_of(2026, 9, 19))
	var opener := _press_of(_made.ui.node_named(&"days"), Calendar.OPENS)
	# the focus on the opener as a hand pressing it leaves it
	opener.grab_focus()
	await _opens(&"days")
	_day_press(Dates.day_of(2026, 9, 3)).pressed()
	await _frames()
	_verdict.check(not _made.driver.is_raised() and _held.told_payloads.back() == {"value": Dates.day_of(2026, 9, 3), "line": "03/09/2026"}, "picked, the calendar is lowered and the field's action carries the day and its line: %s" % [_held.told_payloads.back()])
	_verdict.check(_line(&"days").text == "03/09/2026" and root.gui_get_focus_owner() == opener, "the field shows the day, and the focus is back on the opener")
	_done()


func _a_day_the_fields_model_refuses_is_inert_on_the_calendar_before_it_is_picked() -> void:
	await _built(Dates.day_of(2029, 12, 20))
	await _opens(&"days")
	var late := _day_press(Dates.day_of(2030, 1, 2))
	var fine := _day_press(Dates.day_of(2029, 12, 31))
	_verdict.check(not late.is_usable() and str(late.get_reason()) == "too late" and fine.is_usable(), "a day after the last the model takes is inert, saying why, and the last is not: %s" % late.get_reason())
	_verdict.check(late.get_state() == &"inert" and fine.get_state() != &"inert", "and each is drawn so as the calendar opens on their month: %s, %s" % [late.get_state(), fine.get_state()])
	late.pressed()
	_verdict.check(_made.driver.is_raised() and _held.get_day() == Dates.day_of(2029, 12, 20), "pressed anyway, nothing is picked and the calendar stays")
	_made.commands.dispatch(Chimes.GLOBAL, Driver.LOWERS, {"place": _sheet.get_place()})
	await _frames()
	var drawn := fine.refresh_count
	# keystrokes typed into a field beneath, each a command run
	for line: String in ["1", "12", "12/"]:
		_made.commands.dispatch(Chimes.GLOBAL, KEEPS_LINE, {"value": null, "line": line})
		await _frames()
	_verdict.check(fine.refresh_count == drawn, "the calendar lowered, keystrokes typed beneath draw none of its forty-two days again: %d draws" % (fine.refresh_count - drawn))
	_done()


func _with_no_day_held_it_opens_on_todays_month_and_escape_closes_it() -> void:
	await _built()
	await _opens(&"lines")
	var today := Dates.parts_of(Dates.today())
	_verdict.check(_made.driver.get_parameter(_sheet.get_place())["day"] == null and _calendar.get_focused() == Dates.day_of(today["year"], today["month"], 1) and root.gui_get_focus_owner() == _day_press(_calendar.get_focused()), "with no day held, it opens on today's month, the focus on its first")
	var ringed := _day_press(Dates.today())
	var inside := ringed.get_global_rect().grow(-Fields.MARK)
	var words: Rect2 = (ringed.find_children("*", "Label", true, false)[0] as Label).get_global_rect()
	_verdict.check(ringed.theme_type_variation == Fields.DAY_TODAY and inside.encloses(words), "today is ringed, and its number stands inside the ring, never drawn over it: %s inside %s" % [words, inside])
	var told := _held.told_payloads.size()
	_press_key(KEY_ESCAPE)
	await _frames()
	_verdict.check(not _made.driver.is_raised() and _held.told_payloads.size() == told, "Escape closes it, having picked nothing")
	_done()


func _an_amount_field_is_as_it_was_without_the_model_and_keeps_its_amount_with_it() -> void:
	await _built()
	_held.set_value(&"sum", "12,500")
	await _frames()
	_verdict.check(_line(&"sum").text == "12,500", "given what the model holds, the amount field shows it: %s" % _line(&"sum").text)
	_line(&"sum").clear()
	await _type(&"sum", "3,4x")
	_verdict.check(_held.get_sum() == "3,4x" and _held.told_payloads.back() == {"value": null, "line": "3,4x"} and _line(&"sum").text == "3,4x", "a half-typed amount is carried with no value and kept as typed: %s" % [_held.told_payloads.back()])
	await _type(&"bare", "75")
	var before := _held.told_payloads.size()
	_press_key(KEY_ENTER)
	await _frames()
	_verdict.check(_held.told_payloads.size() == before + 1 and _held.told_payloads.back() == {"line": "75"} and _line(&"bare").text == "", "given nothing, only Enter commits, the line alone, and the field is cleared: %s" % [_held.told_payloads.back()])
	_done()
