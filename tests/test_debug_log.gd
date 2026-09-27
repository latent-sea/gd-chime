extends SceneTree

## What must be true of the debug log.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_debug_log.gd
##
## Proved here: our own push_error, push_warning and print are all kept, in
## order, each with its kind, the error and the warning with the script file and
## line they came from; an error raised on a worker thread is kept too, with the
## function that raised it, and its entries move on the main thread; several
## entries in one frame are handed over once and ring once; past the limit in
## memory the oldest entries are let go; every entry is in the file the moment it is logged, before the
## next frame; when a line would take a file past its cap a new file starts,
## files beyond the count are deleted oldest first, and none is over its cap; a
## new log, as a new run would make, starts a new file; a freed log catches
## nothing more; and the log stands in the global region, its entries heard by
## whatever reads them.
##
## Errors the engine raises itself reach it too - measured - and are not raised
## here, because the test harness rightly fails any suite in which the engine
## complains. The errors and warnings raised here are the suite's own, which the
## harness tells apart.
##
## Each property logs into a folder of its own under user://, emptied first, and
## frees its log before the next begins.

const Belfry := preload("res://addons/gd_chime/belfry.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const DebugLog := preload("res://addons/gd_chime/debug_log.gd")
const Verdict := preload("res://tests/verdict.gd")

const ROOT := "user://test_debug_log"

var _verdict := Verdict.new()


## Follows the log's entries as a reader does, and notes which thread each
## move reached it on.
class Ear extends RefCounted:
	var threads: Array[int] = []
	var _chimes: Chimes
	var _read: Callable

	func _init(chimes: Chimes, read: Callable) -> void:
		_chimes = chimes
		_read = read
		chimes.follow(self, &"heard", read, _moved)

	func _moved() -> void:
		threads.append(OS.get_thread_caller_id())
		_chimes.follow(self, &"heard", _read, _moved)


func _init() -> void:
	# the first frame's signal comes before any node has been processed; after it, one await is one processed frame
	await process_frame
	await _verdict.states(_our_errors_warnings_and_prints_are_kept_in_order_with_their_kind_and_where_they_came_from)
	await _verdict.states(_an_error_raised_on_a_worker_is_kept_and_the_bell_rings_on_the_main_thread)
	await _verdict.states(_several_entries_in_one_frame_ring_once)
	await _verdict.states(_past_the_limit_in_memory_the_oldest_entries_are_let_go)
	await _verdict.states(_every_entry_is_in_the_file_the_moment_it_is_logged)
	await _verdict.states(_a_full_file_starts_a_new_one_and_files_beyond_the_count_go_oldest_first)
	await _verdict.states(_a_new_log_starts_a_new_file)
	await _verdict.states(_a_freed_log_catches_nothing_more)
	await _verdict.states(_the_log_rings_in_the_global_region)
	await _verdict.states(_an_entry_handed_out_is_a_copy)
	quit(_verdict.deliver(get_script()))


## A log writing into a folder of its own, emptied first, with an ear on its
## bell, as [debug log, ear, folder]. This test hangs the belfry by hand,
## standing in for whatever composes an application.
func _made(folder_name: String, file_cap: int, files_kept: int, entries_kept: int) -> Array:
	var folder := ROOT.path_join(folder_name)
	_empty(folder)
	var chimes := Chimes.new(Belfry.new())
	var debug_log := DebugLog.new(chimes, folder, file_cap, files_kept, entries_kept)
	var ear := Ear.new(chimes, debug_log.count)
	return [debug_log, ear, folder]


## A folder made if it is missing, and every file left in it deleted.
func _empty(folder: String) -> void:
	DirAccess.make_dir_recursive_absolute(folder)
	# every file an earlier run left here
	for name: String in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(name))


## The log files in a folder, oldest first.
func _files_in(folder: String) -> Array[String]:
	var names: Array[String] = []
	# every log file in the folder
	for name: String in DirAccess.get_files_at(folder):
		if name.get_extension() == "log":
			names.append(name)
	names.sort()
	return names


## The texts of the kept entries, oldest first.
func _texts(debug_log: DebugLog) -> Array[String]:
	var texts: Array[String] = []
	# every entry the log keeps
	for index: int in range(debug_log.count()):
		texts.append(debug_log.get_entry(index)["text"])
	return texts


## process_frame is emitted BEFORE nodes are processed, so the effect of a frame
## is only visible once the next one has come round.
func _a_frame_passes() -> void:
	await process_frame
	await process_frame


func _raise_on_a_worker() -> void:
	push_error("raised on a worker")


func _our_errors_warnings_and_prints_are_kept_in_order_with_their_kind_and_where_they_came_from() -> void:
	var made := _made("kept", 100000, 3, 50)
	var debug_log: DebugLog = made[0]

	push_error("first, an error")
	push_warning("then a warning")
	print("and last, a print")
	await _a_frame_passes()

	_verdict.check(_texts(debug_log) == ["first, an error", "then a warning", "and last, a print"], "all three kept, in the order they were said")
	var error := debug_log.get_entry(0)
	var warning := debug_log.get_entry(1)
	var printed := debug_log.get_entry(2)
	_verdict.check(error["kind"] == DebugLog.ERROR and warning["kind"] == DebugLog.WARNING and printed["kind"] == DebugLog.MESSAGE, "each with its kind")
	_verdict.check(str(error["file"]).ends_with("test_debug_log.gd") and warning["line"] == error["line"] + 1, "the error and the warning named by this suite's own lines, not the engine's")
	_verdict.check(printed["file"] == "", "and a print, which has no line of its own, names none")
	debug_log.free()


func _an_error_raised_on_a_worker_is_kept_and_the_bell_rings_on_the_main_thread() -> void:
	var made := _made("worker", 100000, 3, 50)
	var debug_log: DebugLog = made[0]
	var ear: Ear = made[1]
	var main := OS.get_thread_caller_id()

	var task := WorkerThreadPool.add_task(_raise_on_a_worker)
	WorkerThreadPool.wait_for_task_completion(task)
	await _a_frame_passes()

	_verdict.check(_texts(debug_log) == ["raised on a worker"], "the worker's error is kept")
	_verdict.check(debug_log.count() == 1 and debug_log.get_entry(0)["function"] == "_raise_on_a_worker", "with the function that raised it")
	_verdict.check(not ear.threads.is_empty() and ear.threads.all(func(thread: int) -> bool: return thread == main), "and its entries moved on the main thread")
	debug_log.free()


func _several_entries_in_one_frame_ring_once() -> void:
	var made := _made("once", 100000, 3, 50)
	var debug_log: DebugLog = made[0]
	var ear: Ear = made[1]

	push_warning("one")
	push_warning("two")
	push_warning("three")
	await _a_frame_passes()

	_verdict.check(debug_log.count() == 3, "three kept")
	_verdict.check(ear.threads.size() == 1, "and one ring for all three")
	_verdict.check(debug_log.hand_over_count == 1, "handed over to the main thread once, not three times")
	debug_log.free()


func _past_the_limit_in_memory_the_oldest_entries_are_let_go() -> void:
	var made := _made("limit", 100000, 3, 3)
	var debug_log: DebugLog = made[0]

	# five prints, two more than this log keeps
	for word: String in ["one", "two", "three", "four", "five"]:
		print(word)
	await _a_frame_passes()

	_verdict.check(_texts(debug_log) == ["three", "four", "five"], "the three most recent are kept, oldest first")
	debug_log.free()


## Read back before a single frame has passed, so nothing could have written it
## later.
func _every_entry_is_in_the_file_the_moment_it_is_logged() -> void:
	var made := _made("at_once", 100000, 3, 50)
	var debug_log: DebugLog = made[0]
	var folder: String = made[2]

	push_error("on disk at once")

	var names := _files_in(folder)
	_verdict.check(names.size() == 1, "one file for this run")
	_verdict.check(names.size() == 1 and FileAccess.get_file_as_string(folder.path_join(names[0])).contains("on disk at once"), "and the line is in it before the next frame")
	debug_log.free()


func _a_full_file_starts_a_new_one_and_files_beyond_the_count_go_oldest_first() -> void:
	var made := _made("rolling", 400, 3, 100)
	var debug_log: DebugLog = made[0]
	var folder: String = made[2]

	# forty warnings, each written with where it came from: far more than three files of four hundred bytes hold
	for number: int in range(40):
		push_warning("warning %02d of forty" % number)

	var names := _files_in(folder)
	_verdict.check(names.size() == 3, "three files kept, however many were started")
	var sizes: Array[int] = []
	# how many bytes each kept file holds
	for name: String in names:
		sizes.append(FileAccess.get_file_as_string(folder.path_join(name)).to_utf8_buffer().size())
	_verdict.check(sizes.all(func(size: int) -> bool: return size <= 400), "none past its cap: %s" % [sizes])
	_verdict.check(names.size() == 3 and FileAccess.get_file_as_string(folder.path_join(names[2])).contains("warning 39 of forty"), "the newest holds the last line")
	_verdict.check(names.size() == 3 and names[0].get_basename().to_int() > 1, "and the files deleted were the first ones")
	debug_log.free()


func _a_new_log_starts_a_new_file() -> void:
	var made := _made("runs", 100000, 3, 50)
	var first: DebugLog = made[0]
	var folder: String = made[2]
	push_error("said in the first run")
	first.free()

	var second := DebugLog.new(Chimes.new(Belfry.new()), folder, 100000, 3, 50)
	push_error("said in the second run")
	var names := _files_in(folder)
	second.free()

	_verdict.check(names.size() == 2, "two runs, two files")
	_verdict.check(names.size() == 2 and FileAccess.get_file_as_string(folder.path_join(names[0])).contains("first run") and not FileAccess.get_file_as_string(folder.path_join(names[0])).contains("second run"), "the first run's line in the older file, and only that")
	_verdict.check(names.size() == 2 and FileAccess.get_file_as_string(folder.path_join(names[1])).contains("second run"), "the second run's in the newer")


func _a_freed_log_catches_nothing_more() -> void:
	var made := _made("freed", 100000, 3, 50)
	var debug_log: DebugLog = made[0]
	var folder: String = made[2]
	push_warning("before it was freed")
	debug_log.free()

	push_warning("after it was freed")
	await _a_frame_passes()

	var names := _files_in(folder)
	var written := "" if names.is_empty() else FileAccess.get_file_as_string(folder.path_join(names[0]))
	_verdict.check(written.contains("before it was freed"), "what came before is in its file")
	_verdict.check(not written.contains("after it was freed"), "and nothing said after it was freed reached it")


## There is one log and it outlives every screen, so it stands in the global
## region, with nothing said about a region when it was made, and a reader of
## its entries hears them move.
func _the_log_rings_in_the_global_region() -> void:
	var made := _made("global", 100000, 3, 50)
	var debug_log: DebugLog = made[0]
	var ear: Ear = made[1]

	print("said to be heard")
	await _a_frame_passes()

	_verdict.check(debug_log.region == Chimes.GLOBAL, "the log is in the global region: %s" % debug_log.region)
	_verdict.check(ear.threads.size() == 1, "and its bell is heard there: %d" % ear.threads.size())
	debug_log.free()


## An entry is read, never reached into: whatever a reader does to the entry it
## was handed, the log still holds what was said.
func _an_entry_handed_out_is_a_copy() -> void:
	var made := _made("copied", 100000, 3, 50)
	var debug_log: DebugLog = made[0]

	print("as it was said")
	await _a_frame_passes()

	var last := debug_log.count() - 1
	var entry := debug_log.get_entry(last)
	entry["text"] = "changed by a reader"
	_verdict.check(debug_log.get_entry(last)["text"] == "as it was said", "the log still holds what was said: %s" % debug_log.get_entry(last)["text"])
	debug_log.free()
