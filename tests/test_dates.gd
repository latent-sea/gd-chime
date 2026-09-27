extends SceneTree

## What must be true of days typed and read back (dates.gd): a day is typed
## in the order the language writes a date, its mark between the parts, and
## read back as the very day; every day of a span, leap days included, goes
## there and back unchanged; a line naming no day - a day the month lacks, a
## year cut to two figures, words, too few or too many parts - is none, and
## a line with other marks between its figures is still read; a language
## that writes the month first types and reads the month first and refuses
## the other order, and its shape says so; and a month's length and a day's
## day of the week are the calendar's.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_dates.gd

const Dates := preload("res://addons/gd_chime/dates.gd")
const Formats := preload("res://addons/gd_chime/formats.gd")
const Verdict := preload("res://tests/verdict.gd")

## A language writing the month first, for the one property about order.
const MONTH_FIRST := "en_US"

var _verdict := Verdict.new()


func _init() -> void:
	TranslationServer.set_locale("en")
	await _verdict.states(_english_types_the_day_first_and_reads_the_line_back_as_the_same_day)
	await _verdict.states(_every_day_of_a_span_is_typed_and_read_back_unchanged)
	await _verdict.states(_a_line_naming_no_day_is_none_and_other_marks_between_the_figures_are_read)
	await _verdict.states(_a_language_writing_the_month_first_types_and_reads_the_month_first)
	await _verdict.states(_a_month_has_the_days_the_calendar_gives_it_and_a_day_its_weekday)
	quit(_verdict.deliver(get_script()))


func _english_types_the_day_first_and_reads_the_line_back_as_the_same_day() -> void:
	var day := Dates.day_of(2026, 9, 19)
	_verdict.check(Dates.order() == ["day", "month", "year"], "English writes the day, the month, then the year: %s" % [Dates.order()])
	_verdict.check(Dates.typed(day) == "19/09/2026", "the day is typed in that order, slashes between, two figures for the day and month: %s" % Dates.typed(day))
	_verdict.check(Dates.parsed("19/09/2026") == day and Dates.parsed("19/9/2026") == day, "and the line, with or without a leading nought, is read back as that very day: %s" % [Dates.parsed("19/09/2026")])
	_verdict.check(str(Dates.shape()) == "DD/MM/YYYY", "its shape says so: %s" % Dates.shape())
	_verdict.check(str(Dates.written(day)) == "19 September 2026", "and in words it is the language's writing of the date: %s" % Dates.written(day))


func _every_day_of_a_span_is_typed_and_read_back_unchanged() -> void:
	var first := Dates.day_of(2023, 12, 25)
	var wrong: Array = []
	# every day of two and a half years, a leap day among them, there and back
	for day: int in range(first, first + 900):
		if Dates.parsed(Dates.typed(day)) != day:
			wrong.append(Dates.typed(day))
	_verdict.check(wrong.is_empty() and Dates.typed(Dates.day_of(2024, 2, 29)) == "29/02/2024", "every day of the span, 29 February 2024 among them, is read back as the day it was typed from: %s" % [wrong])


func _a_line_naming_no_day_is_none_and_other_marks_between_the_figures_are_read() -> void:
	var none: Array = ["31/02/2026", "29/02/2025", "00/01/2026", "12/13/2026", "19/09/26", "nineteenth", "19/09", "19/09/2026/1", "", "19/09/2026 at noon"]
	var read: Array = none.filter(func(line: String) -> bool: return Dates.parsed(line) != null)
	_verdict.check(read.is_empty(), "a day the month lacks, month 13, a two-figure year, words, too few or too many parts are no day: %s" % [read])
	var day := Dates.day_of(2026, 1, 1)
	_verdict.check(Dates.parsed("1.1.2026") == day and Dates.parsed(" 01-01-2026 ") == day and Dates.parsed("1 1 2026") == day, "points, dashes, spaces and space around the line are read as the slash is")


func _a_language_writing_the_month_first_types_and_reads_the_month_first() -> void:
	var catalogue := Translation.new()
	catalogue.locale = MONTH_FIRST
	catalogue.add_message("{day} {month} {year}", "{month} {day}, {year}", Formats.DATE)
	catalogue.add_message("/", "/", Dates.TYPED_MARK)
	# every part's letters, as the language's catalogue holds them
	for part: String in Dates.SHAPE_LETTERS:
		catalogue.add_message(Dates.SHAPE_LETTERS[part], Dates.SHAPE_LETTERS[part], Dates.SHAPE)
	TranslationServer.add_translation(catalogue)
	TranslationServer.set_locale(MONTH_FIRST)
	var day := Dates.day_of(2026, 9, 19)
	_verdict.check(Dates.order() == ["month", "day", "year"] and Dates.typed(day) == "09/19/2026", "writing the month first, the month is typed first: %s" % Dates.typed(day))
	_verdict.check(Dates.parsed("09/19/2026") == day and Dates.parsed("19/09/2026") == null, "and read first, the day-first line naming no month 19: %s" % [Dates.parsed("19/09/2026")])
	_verdict.check(str(Dates.shape()) == "MM/DD/YYYY", "and the shape says so: %s" % Dates.shape())
	TranslationServer.remove_translation(catalogue)
	TranslationServer.set_locale("en")


func _a_month_has_the_days_the_calendar_gives_it_and_a_day_its_weekday() -> void:
	_verdict.check(Dates.days_in(2024, 2) == 29 and Dates.days_in(2025, 2) == 28 and Dates.days_in(2026, 12) == 31 and Dates.days_in(2026, 9) == 30, "February has 29 days in a leap year and 28 otherwise, December 31, September 30")
	var saturday := Dates.parts_of(Dates.day_of(2026, 9, 19))
	var monday := Dates.parts_of(Dates.day_of(2026, 9, 14))
	_verdict.check(saturday["weekday"] == 5 and monday["weekday"] == 0 and saturday["month"] == 9 and saturday["day"] == 19 and saturday["year"] == 2026, "19 September 2026 is a Saturday, 5 counting from Monday's 0, and its parts are its own: %s" % [saturday])
