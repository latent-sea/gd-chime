extends RefCounted

## Rows held column by column: a hundred thousand rows are a dozen packed
## arrays, never a hundred thousand dictionaries.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A column is one of three kinds. A NUMBER is a float per row. A DATE is a
## number too - the day, counted from the first of January 1970 - so it
## sorts and compares as one, and is written as a date only when shown.
## WORDS are a code per row into the column's own list of the words it
## holds, each word listed once: a column of a hundred thousand towns is a
## hundred thousand small numbers and the sixty town names. A word is data,
## never a phrase: it is shown as it is.
##
## What a query needs is handed out as the arrays themselves (numbers(),
## codes(), words(), ranks()), and a query reads nothing else, so it can run
## on another thread over a SNAPSHOT: the rows as they stand at a VERSION,
## which every row added and every value written moves on by one. A
## snapshot holds the arrays themselves, copying none; the column written
## next is copied then, before the write, so the snapshot reads on as it was
## taken (copy on write - the engine's packed arrays are shared, not copied,
## when a dictionary holding them is, so the copy is this file's to make).
## With nothing written since the last, a snapshot is the last one again.
## Taken and written on the main thread; a snapshot is never written to.
##
## A row is its index, from 0 in the order the rows were added: its
## identity, which no sort or filter changes. row_at() makes one row a
## dictionary - {"id", and a value per column} - for whatever shows it, and
## is the only place a dictionary per row is made, a page at a time; so no
## column may be called "id", nor "at", which a view adds (queried_rows.gd),
## and one that is, is said out loud as this is made.
##
## A value written is checked against nothing here: what may be written is
## the model's that holds this (queried_rows.gd).
##
## Deliberately absent: removing a row, which would renumber every row
## after it; a column added once rows are held; and any other kind.

const NUMBER := &"number"
const DATE := &"date"
const WORDS := &"words"
## The seconds in a day, for the engine's dates, which count seconds.
const DAY_SECONDS := 86400

var _kinds: Dictionary = {}  # column -> its kind, in the order the columns were given
var _numbers: Dictionary = {}  # a number or date column -> PackedFloat64Array, a value per row
var _codes: Dictionary = {}  # a words column -> PackedInt32Array, a code per row
var _words: Dictionary = {}  # a words column -> PackedStringArray, the word of each code
var _coded: Dictionary = {}  # a words column -> {word: its code}
var _count: int = 0
var _version: int = 0  # moved on by every row added and every value written
var _shared: Dictionary = {}  # the columns whose arrays the last snapshot holds, used as a set
var _snapshot: RefCounted = null  # the last snapshot, and the version it was taken at
var _snapshot_version: int = -1
var _copied: int = 0  # arrays copied before a write, for a test to read


## The columns and their kinds, {name: kind}, in the order they read across.
func _init(kinds: Dictionary) -> void:
	# a column called as a row's identity is would be written over it in every row made a dictionary, silently
	for taken: StringName in [&"id", &"at"]:
		if kinds.has(taken):
			push_error("a column may not be called %s: a row made a dictionary holds its own %s under that name" % [taken, taken])
	_kinds = kinds
	# every column, an empty array of its kind
	for column: StringName in kinds:
		if kinds[column] == WORDS:
			_codes[column] = PackedInt32Array()
			_words[column] = PackedStringArray()
			_coded[column] = {}
		else:
			_numbers[column] = PackedFloat64Array()


## One more row, its values in the columns' order: a number, a day, or a word.
func add(values: Array) -> void:
	var at := 0
	# every column in order, its own, the value for it put at the end of its array
	for column: StringName in _kinds:
		_own(column)
		if _kinds[column] == WORDS:
			_codes[column].append(_code_for(column, values[at]))
		else:
			_numbers[column].append(values[at])
		at += 1
	_count += 1
	_version += 1


func count() -> int:
	return _count


## Where the rows stand: moved on by every row added and every value written.
func get_version() -> int:
	return _version


## How many arrays have been copied before a write, since these rows were made.
func get_copied() -> int:
	return _copied


## The column names, in the order they read across.
func get_columns() -> Array:
	return _kinds.keys()


func kind_of(column: StringName) -> StringName:
	return _kinds[column]


## One value: a float, or a word.
func value_at(row: int, column: StringName) -> Variant:
	if _kinds[column] == WORDS:
		return _words[column][_codes[column][row]]
	return _numbers[column][row]


## One value written over the one there: a word never held before is listed.
func set_value(row: int, column: StringName, value: Variant) -> void:
	_own(column)
	_version += 1
	if _kinds[column] == WORDS:
		_codes[column][row] = _code_for(column, value)
	else:
		_numbers[column][row] = value


## One row as a dictionary - its id, and every column's value.
func row_at(row: int) -> Dictionary:
	var made := {"id": row}
	# every column, its value for this row
	for column: StringName in _kinds:
		made[column] = value_at(row, column)
	return made


## A number or date column's values, a float per row.
func numbers(column: StringName) -> PackedFloat64Array:
	return _numbers[column]


## A words column's codes, one per row.
func codes(column: StringName) -> PackedInt32Array:
	return _codes[column]


## A words column's words, each once, at its code.
func words(column: StringName) -> PackedStringArray:
	return _words[column]


## Where each code's word stands in the column's words put in order - code
## to place - so rows sort by their words without comparing one. The order
## is a reader's: whatever the case, and a number within a word by its value.
func ranks(column: StringName) -> PackedInt32Array:
	var sorted: Array = Array(_words[column])
	sorted.sort_custom(func(a: String, b: String) -> bool: return a.naturalnocasecmp_to(b) < 0)
	var placed := PackedInt32Array()
	placed.resize(sorted.size())
	# every word, its code given the place it has in the sorted words
	for place: int in sorted.size():
		placed[_coded[column][sorted[place]]] = place
	return placed


## The rows as they stand now, to read on another thread while these go on
## being written: holding these arrays, copying none; the last one again
## while nothing has been written since.
func snapshot() -> RefCounted:
	if _snapshot_version == _version:
		return _snapshot
	_snapshot = get_script().new(_kinds)
	_snapshot._hold(_numbers, _codes, _words, _coded, _count, _version)
	_snapshot_version = _version
	# every column, its arrays now the snapshot's as well, to be copied before they are next written
	for column: StringName in _kinds:
		_shared[column] = true
	return _snapshot


## The arrays themselves, the count and the version, held by a snapshot.
func _hold(numbers: Dictionary, codes: Dictionary, words: Dictionary, coded: Dictionary, count: int, version: int) -> void:
	# every column, its arrays held as they are
	for column: StringName in _kinds:
		if _kinds[column] == WORDS:
			_codes[column] = codes[column]
			_words[column] = words[column]
			_coded[column] = coded[column]
		else:
			_numbers[column] = numbers[column]
	_count = count
	_version = version


## A column made this one's own before it is written: while a snapshot
## holds its arrays, they are copied first, so the snapshot reads on as it was.
func _own(column: StringName) -> void:
	if not _shared.has(column):
		return
	_shared.erase(column)
	if _kinds[column] == WORDS:
		_codes[column] = _codes[column].duplicate()
		_words[column] = _words[column].duplicate()
		_coded[column] = _coded[column].duplicate()
		_copied += 3
	else:
		_numbers[column] = _numbers[column].duplicate()
		_copied += 1


## The code of a word in a column, listing it first if it is new there.
func _code_for(column: StringName, word: String) -> int:
	if not _coded[column].has(word):
		_coded[column][word] = _words[column].size()
		_words[column].append(word)
	return _coded[column][word]


## A day - the count from the first of January 1970 - from a date written
## year-month-day, or a year alone as its first day.
static func day_of(written: String) -> float:
	var whole := written + "-01-01" if written.is_valid_int() else written
	return floorf(Time.get_unix_time_from_datetime_string(whole) / DAY_SECONDS)


## Whether a line is a date day_of() reads - a year alone, or year-month-day
## of a day there is - asked without the engine's reading, which cries out
## at every line on the way to a date: 1970-0 as much as 1970-02-30.
static func is_date(written: String) -> bool:
	if written.is_valid_int():
		return true
	var parts := written.split("-")
	# four, two and two digits between the dashes: 1964-03-12
	if parts.size() != 3 or parts[0].length() != 4 or parts[1].length() != 2 or parts[2].length() != 2 or not "".join(parts).is_valid_int():
		return false
	var month := parts[1].to_int()
	var day := parts[2].to_int()
	if month < 1 or month > 12 or day < 1:
		return false
	# the month's first day and the next month's: its days are the days between
	var next := "%s-%02d-01" % [parts[0], month + 1] if month < 12 else "%04d-01-01" % (parts[0].to_int() + 1)
	return day <= day_of(next) - day_of("%s-%s-01" % [parts[0], parts[1]])


## A day written year-month-day.
static func date_of(day: float) -> String:
	return Time.get_date_string_from_unix_time(int(day) * DAY_SECONDS)
