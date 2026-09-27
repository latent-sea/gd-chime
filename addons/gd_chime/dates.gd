extends RefCounted

const Language := preload("language.gd")
const Formats := preload("formats.gd")
const Phrase := preload("phrase.gd")

## Days as a reader types them and reads them back: a day written as a typed
## line in the language's order, a typed line read back as a day, and the
## sums a calendar needs - how long a month is, which day of the week it
## starts on.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A DAY IS A WHOLE NUMBER: days since the first of January 1970, the unit a
## table's date column holds (packed_rows.gd). A day has no time and no zone,
## so nothing here ever reads a clock but today(), and today() is asked only
## where a rule is about now.
##
## THE ORDER IS THE LANGUAGE'S ONE WRITING OF A DATE (formats.gd, DATE): where
## the day, the month and the year stand in it is the order they are typed
## in, so a language that writes "{month} {day}, {year}" types 09/19/2026
## and one that writes "{day} {month} {year}" types 19/09/2026 - one entry
## in a catalogue, never a second saying the same thing. The mark between
## them is the catalogue's too (TYPED_MARK), a slash in English.
##
## A LINE IS READ BACK STRICTLY: three runs of digits, anything that is not a
## digit between them, the year written whole - a two-figure year is
## refused rather than guessed at a century - and a day that the month has.
## Anything else is no day, and the caller decides what that means: a form
## keeps the line and says why, a filter refuses it.
##
## Deliberately absent: times of day, zones, a week starting on any day but
## Monday, and calendars other than the Gregorian.

## What the typed mark between a day, a month and a year is kept under in a catalogue.
const TYPED_MARK := "dates: the mark between a typed day, month and year"
## What each part's letters in a typed date's shape are kept under - DD/MM/YYYY.
const SHAPE := "dates: the letters standing for a typed day, month or year"
const DAY_SECONDS := 86400
## The parts of a date, as the language's writing names them.
const PARTS: Array[String] = ["day", "month", "year"]
## Each part's letters in a typed date's shape, in English.
const SHAPE_LETTERS := {"day": "DD", "month": "MM", "year": "YYYY"}
## The first year a typed line may name: a year written whole.
const FIRST_YEAR := 1000


## The parts of a date in the order the language on writes them.
static func order() -> Array[String]:
	var writing := Language.written("{day} {month} {year}", Formats.DATE)
	var placed: Array[String] = PARTS.duplicate()
	# the parts sorted by where each stands in the writing: {day} before {month} in English
	placed.sort_custom(func(a: String, b: String) -> bool: return writing.find("{%s}" % a) < writing.find("{%s}" % b))
	return placed


## A day as a line typed in the language's order: the day and the month in two figures, the year in four.
static func typed(day: int) -> String:
	var parts := parts_of(day)
	var written: Array[String] = []
	# every part in the language's order, in its figures
	for part: String in order():
		written.append(("%04d" if part == "year" else "%02d") % parts[part])
	return Language.written("/", TYPED_MARK).join(written)


## A typed line read back as a day, or null where it names none.
static func parsed(line: String) -> Variant:
	# three runs of digits with anything but digits between them: 19/09/2026, 19.9.2026
	var runs := RegEx.create_from_string("^\\s*(\\d+)\\D+(\\d+)\\D+(\\d+)\\s*$").search(line)
	if runs == null:
		return null
	var given: Dictionary = {}
	# every run, the part standing there in the language's order
	for at: int in 3:
		given[order()[at]] = runs.get_string(at + 1).to_int()
	if given["year"] < FIRST_YEAR or given["month"] < 1 or given["month"] > 12 or given["day"] < 1 or given["day"] > days_in(given["year"], given["month"]):
		return null
	return day_of(given["year"], given["month"], given["day"])


## The shape a typed line takes, as a phrase written as it is said: DD/MM/YYYY.
static func shape() -> Phrase:
	# each part's letters in the language's order, the typed mark between them
	return Phrase.written(func() -> String: return Language.written("/", TYPED_MARK).join(order().map(func(part: String) -> String: return Language.word(SHAPE_LETTERS[part], SHAPE))))


## A day written in words, the language's way, as a phrase: 19 September 2026.
static func written(day: int) -> Phrase:
	return Phrase.written(func() -> String: return Formats.written_date(day * DAY_SECONDS))


## The day of a year, a month and a day of that month.
static func day_of(year: int, month: int, day: int) -> int:
	return int(Time.get_unix_time_from_datetime_dict({"year": year, "month": month, "day": day, "hour": 0, "minute": 0, "second": 0})) / DAY_SECONDS


## A day's year, month and day of the month, and its day of the week from Monday, 0, to Sunday, 6.
static func parts_of(day: int) -> Dictionary:
	var date := Time.get_date_dict_from_unix_time(day * DAY_SECONDS)
	return {"year": date["year"], "month": date["month"], "day": date["day"], "weekday": (date["weekday"] + 6) % 7}


## How many days a month of a year has.
static func days_in(year: int, month: int) -> int:
	var next := [year + 1, 1] if month == 12 else [year, month + 1]
	return day_of(next[0], next[1], 1) - day_of(year, month, 1)


## The day it is now, where the machine is.
static func today() -> int:
	var now := Time.get_date_dict_from_system()
	return day_of(now["year"], now["month"], now["day"])
