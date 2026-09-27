extends SceneTree

## What must be true of rows held column by column: every value read back
## as it went in, a word listed once however many rows hold it, words
## placed in their order by code, a snapshot that a later write never
## reaches and that copies nothing until a column is written, a date that
## is a day and written as one, and a line that is a date only when it is one.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_packed_rows.gd

const PackedRows := preload("res://addons/gd_chime/packed_rows.gd")
const Verdict := preload("res://tests/verdict.gd")

var _verdict := Verdict.new()


func _init() -> void:
	await _verdict.states(_every_value_reads_back_as_it_went_in)
	await _verdict.states(_a_word_is_listed_once_and_placed_in_order)
	await _verdict.states(_a_snapshot_is_untouched_by_a_write_to_the_original)
	await _verdict.states(_a_snapshot_copies_nothing_until_a_column_is_written)
	await _verdict.states(_a_date_is_a_day_written_as_a_date)
	quit(_verdict.deliver(get_script()))


## Three rows of a number, a date and a word.
func _three() -> PackedRows:
	var rows := PackedRows.new({&"size": PackedRows.NUMBER, &"laid": PackedRows.DATE, &"town": PackedRows.WORDS})
	rows.add([150.0, PackedRows.day_of("1964-03-12"), "ashby"])
	rows.add([90.0, PackedRows.day_of("1990"), "cole"])
	rows.add([300.0, PackedRows.day_of("1971-07-01"), "ashby"])
	return rows


func _every_value_reads_back_as_it_went_in() -> void:
	var rows := _three()
	_verdict.check(rows.count() == 3 and rows.get_columns() == [&"size", &"laid", &"town"], "three rows, the columns in the order given: %s" % [rows.get_columns()])
	_verdict.check(rows.value_at(1, &"size") == 90.0 and rows.value_at(2, &"town") == "ashby", "a number and a word read back at their row: %s, %s" % [rows.value_at(1, &"size"), rows.value_at(2, &"town")])
	_verdict.check(rows.row_at(0) == {"id": 0, &"size": 150.0, &"laid": PackedRows.day_of("1964-03-12"), &"town": "ashby"}, "a row as a dictionary: its id and every column: %s" % [rows.row_at(0)])
	rows.set_value(1, &"town", "dale")
	rows.set_value(0, &"size", 175.0)
	_verdict.check(rows.value_at(1, &"town") == "dale" and rows.value_at(0, &"size") == 175.0 and rows.value_at(2, &"town") == "ashby", "a value written reads back, and no other row moves: %s" % [[rows.value_at(1, &"town"), rows.value_at(0, &"size"), rows.value_at(2, &"town")]])


func _a_word_is_listed_once_and_placed_in_order() -> void:
	var rows := _three()
	rows.add([120.0, 0.0, "baxter"])
	_verdict.check(rows.words(&"town") == PackedStringArray(["ashby", "cole", "baxter"]) and rows.codes(&"town") == PackedInt32Array([0, 1, 0, 2]), "a word held by two rows is listed once, each row a code into the list: %s %s" % [rows.words(&"town"), rows.codes(&"town")])
	_verdict.check(rows.ranks(&"town") == PackedInt32Array([0, 2, 1]), "each code placed where its word stands in order - ashby, baxter, cole: %s" % [rows.ranks(&"town")])


func _a_snapshot_is_untouched_by_a_write_to_the_original() -> void:
	var rows := _three()
	var taken: PackedRows = rows.snapshot()
	rows.set_value(0, &"size", 1.0)
	rows.set_value(0, &"town", "elm")
	rows.add([5.0, 0.0, "fen"])
	_verdict.check(taken.value_at(0, &"size") == 150.0 and taken.value_at(0, &"town") == "ashby" and taken.count() == 3 and taken.words(&"town").size() == 2, "writes and a row added to the rows never reach a snapshot taken before them: %s" % [taken.row_at(0)])
	_verdict.check(rows.value_at(0, &"size") == 1.0 and rows.value_at(0, &"town") == "elm" and rows.count() == 4, "and the rows hold what was written: %s" % [rows.row_at(0)])


func _a_snapshot_copies_nothing_until_a_column_is_written() -> void:
	var rows := _three()
	var version := rows.get_version()
	var first: PackedRows = rows.snapshot()
	var again: PackedRows = rows.snapshot()
	_verdict.check(again == first and rows.get_copied() == 0, "nothing written since, the snapshot is the last one again, and nothing was copied: %d" % rows.get_copied())
	rows.set_value(1, &"size", 2.0)
	var after: PackedRows = rows.snapshot()
	_verdict.check(rows.get_version() == version + 1 and after != first and rows.get_copied() == 1, "one number written: the version moves on, a new snapshot is taken, and only that column's array was copied: %d" % rows.get_copied())
	rows.set_value(2, &"size", 3.0)
	rows.set_value(0, &"size", 4.0)
	_verdict.check(rows.get_copied() == 2 and after.value_at(2, &"size") == 300.0, "written twice after the next snapshot, the column is copied once, and that snapshot reads on as it was: %d" % rows.get_copied())


func _a_date_is_a_day_written_as_a_date() -> void:
	_verdict.check(PackedRows.day_of("1970-01-02") == 1.0 and PackedRows.day_of("1969-12-31") == -1.0, "a day is counted from the first of January 1970, before it too: %s %s" % [PackedRows.day_of("1970-01-02"), PackedRows.day_of("1969-12-31")])
	_verdict.check(PackedRows.day_of("1970") == 0.0 and PackedRows.date_of(PackedRows.day_of("1964-03-12")) == "1964-03-12", "a year alone is its first day, and a day is written back as its date: %s" % PackedRows.date_of(PackedRows.day_of("1964-03-12")))
	var dates: Array = ["1970", "1964-03-12", "2000-02-29", "1999-12-31"].filter(func(line: String) -> bool: return PackedRows.is_date(line))
	var not_dates: Array = ["1970-", "1970-0", "1970-01-0", "1970-00-01", "1970-13-01", "1970-02-29", "1970-04-31", "1970-1-01", "high"].filter(func(line: String) -> bool: return not PackedRows.is_date(line))
	_verdict.check(dates.size() == 4 and not_dates.size() == 9, "a year alone and a day there is are dates; a line on the way to one, a month or day out of range, and words are not: %s %s" % [dates, not_dates])
