extends RefCounted

const Bound := preload("components/primitives/bound.gd")
const Language := preload("language.gd")
const Phrase := preload("phrase.gd")

## Numbers, money, dates and stretches of time, written as the language on writes them: as
## phrases a text says as it draws (phrase.gd) - the value carried as it is,
## written only at that moment, and again whenever the language changes - and
## as the writing itself, for a painter drawing its own numbers.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## HOW A LANGUAGE WRITES IS ITS CATALOGUE'S (language.gd): the mark between
## thousands, the mark before a fraction, where money's mark stands, the
## order of a date, the months' names and how the first of a month is
## written, each an entry under its context, the English's being the key. So
## a language is one file, and nothing here knows one. The engine writes
## none of it: its format_number changes only which digits are used, and
## would leave a French number with an English point.
##
## A number is rounded where it is written, to as many places as it is asked
## for, so a model hands over the value it holds and never a string. The
## writing is called by the text as it draws, or by a painter as it paints:
## never while a screen is described.

## What each way of writing is kept under in a catalogue.
const THOUSANDS := "numbers: the mark between thousands"
const FRACTION := "numbers: the mark before a fraction"
const MONEY := "money: where the amount and its mark stand"
const DATE := "dates: the order of the day, the month and the year"
const FIRST := "dates: the first day of a month"
## The months, whose names are words the reader reads, kept under their own context.
const MONTH := "dates: a month"
const MONTHS: Array[String] = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
## How many parts a stretch of time is written in: the minutes and the seconds, or the hours as well.
const MINUTES := 2
const HOURS := 3


## A number as a bound value, written to so many places as it is drawn; nothing for nothing.
static func number(value: Bound, places: int = 0) -> Bound:
	return value.map(func(amount: Variant) -> Variant: return null if amount == null else Phrase.written(func() -> String: return written_number(float(amount), places)))


## An amount of money as a bound value, its mark where the language puts it as it is drawn.
static func money(value: Bound, mark: String, places: int = 0) -> Bound:
	return value.map(func(amount: Variant) -> Variant: return null if amount == null else Phrase.written(func() -> String: return written_money(float(amount), mark, places)))


## A quantity as a bound value: the number written to so many places, put
## into its unit's phrase - a function of the written number, so the unit's
## words and where the number stands in them are the language's:
## func(amount): return Phrase.with("%s customers", [amount]). Nothing for nothing.
static func quantity(value: Bound, unit: Callable, places: int = 0) -> Bound:
	return number(value, places).map(func(written: Variant) -> Variant: return null if written == null else unit.call(written))


## A date as a bound value, from a time in seconds since the start of 1970, written as it is drawn.
static func date(value: Bound) -> Bound:
	return value.map(func(at: Variant) -> Variant: return null if at == null else Phrase.written(func() -> String: return written_date(int(at))))


## A stretch of time written as a clock face reads it: so many parts - the
## minutes and the seconds, or the hours as well - the first written plainly
## and every one after it to two digits, and the seconds to so many places.
## The marks between the parts are data, the same in every language, as the
## digits of a clock are; how long something took is not a date.
static func written_elapsed(seconds: float, parts: int = MINUTES, places: int = 0) -> String:
	# rounded to the places it will be written to first, so a second rounding up carries into the minute
	var left := snappedf(absf(seconds), pow(0.1, places))
	var written: PackedStringArray = []
	# every part before the seconds, the biggest first: how many whole ones of it, and what it leaves
	for part: int in parts - 1:
		var size := pow(60.0, parts - 1 - part)
		written.append(("%d" if part == 0 else "%02d") % floori(left / size))
		left = fmod(left, size)
	var last := String.num(left, places)
	# a single digit of seconds is written with its leading zero, as every part after the first is
	written.append(last if last.split(".")[0].length() > 1 else "0" + last)
	return ":".join(written)


## A number written: rounded to so many places, its whole part grouped in
## thousands, and a minus only where what is written is not nothing.
static func written_number(value: float, places: int = 0) -> String:
	var digits: PackedStringArray = ("%.*f" % [places, absf(value)]).split(".")
	var thousands := Language.written(",", THOUSANDS)
	var grouped := ""
	# the whole part's digits, a thousands mark before every third from the right
	for index: int in range(digits[0].length()):
		if index > 0 and (digits[0].length() - index) % 3 == 0:
			grouped += thousands
		grouped += digits[0][index]
	var sign := "-" if value < 0.0 and ".".join(digits).to_float() != 0.0 else ""
	return sign + grouped + ("" if places == 0 else Language.written(".", FRACTION) + digits[1])


## An amount of money written, its mark where the language puts it.
static func written_money(amount: float, mark: String, places: int = 0) -> String:
	return Language.written("{mark}{amount}", MONEY).format({"mark": mark, "amount": written_number(amount, places)})


## A date written - the day, the month's name and the year in the language's
## order - from a time in seconds since the start of 1970.
static func written_date(at: int) -> String:
	var day := Time.get_date_dict_from_unix_time(at)
	# the first of a month as the language writes it - French's "1er" - and every other day as its number
	var shown := Language.written("1", FIRST) if day["day"] == 1 else str(day["day"])
	return Language.written("{day} {month} {year}", DATE).format({"day": shown, "month": Language.word(MONTHS[day["month"] - 1], MONTH), "year": str(day["year"])})
