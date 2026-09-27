extends "controller.gd"

## The developer's log: everything the app and the engine say while the app
## runs - prints, warnings and errors - kept for a screen to read, and written
## to files on disk.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Nothing writes to it. It adds a catcher to the engine, and the engine hands
## the catcher every print, every push_warning and push_error, and every error
## it raises itself, such as a call on nothing. So code says what it has to say
## with the engine's own calls and never holds the log. Where an entry came from
## is the top frame of the call's script backtrace when there is one - for a
## push_error the engine names only its own site - and the engine's site when
## there is not.
##
## The catcher runs on whatever thread raised the message; measured on 4.6.2, a
## worker's error reaches it on that worker. Under a lock it writes the line to
## the current file and flushes it inside the call, so the line is on disk before
## anything else can go wrong, and keeps the entry for the main thread. When the
## first entry is waiting it hands over one deferred call, and entries arriving
## before that call runs join it. On the main thread this takes what arrived,
## keeps the most recent, and sets the entries - a value (value.gd) - once.
## Nothing polls.
##
## There is one log and it outlives every screen, so it stands in the global
## region rather than in one its builder chooses: closing a screen never
## takes it away.
##
## Two limits, for two jobs, and all three numbers come from whoever builds it.
## In memory, the most recent entries, oldest first, for a screen to read. On
## disk, files named by number: a new one begins whenever this is built - a new
## run - and whenever a line would take the current one past its cap, and files
## beyond the count are deleted, oldest first. A line longer than the cap gets a
## file of its own, so the folder holds at most the cap times the count, give or
## take such a line.
##
## It never prints or reports anything itself: whatever it said would come
## straight back through the catcher. A message raised while a line is being
## written - a disk error, say - is kept but not written, and a file it cannot
## open is noted as an entry in memory.
##
## Freed, it takes its catcher out of the engine. Nothing else holds the
## catcher, so it goes too, and its file closes with it; left in, it would go on
## catching and writing. Quitting with the catcher still added is harmless -
## measured.
##
## Deliberately absent: searching, filtering and clearing, which belong to the
## screen that reads this; commands; turning off the engine's own log file; what
## a release build does.

## The kinds an entry can be, in the engine's own terms.
const MESSAGE := &"message"
const ERROR_MESSAGE := &"error_message"
const ERROR := &"error"
const WARNING := &"warning"
const SCRIPT_ERROR := &"script_error"
const SHADER_ERROR := &"shader_error"

## How many times the catcher has handed over to the main thread, so that one
## hand-over for a burst is something a test can read rather than something it
## argues.
var hand_over_count: int = 0

var _entries_kept: int
var _entries := value([])  # the most recent entries, oldest first
var _catcher: Catcher


func _init(chimes: Chimes, folder: String, file_cap: int, files_kept: int, entries_kept: int) -> void:
	super(chimes, [], Chimes.GLOBAL)
	_entries_kept = entries_kept
	_catcher = Catcher.new(folder, file_cap, files_kept, _arrived)
	OS.add_logger(_catcher)


## How many entries are kept.
func count() -> int:
	return _entries.read().size()


## The entry at this position, oldest first: at, kind, text, file, line and
## function - a copy, so nothing outside can change what was kept.
func get_entry(index: int) -> Dictionary:
	return _entries.read()[index].duplicate()


## On the main thread, when the catcher hands over: what arrived kept, and
## the oldest let go past the limit, set once.
func _arrived() -> void:
	hand_over_count += 1
	var arrived := _catcher.take()
	# an earlier hand-over already took them
	if arrived.is_empty():
		return
	var entries: Array = _entries.read() + arrived
	_entries.set_value(entries.slice(maxi(0, entries.size() - _entries_kept)))


## Freed: the catcher taken out of the engine. Nothing else holds it, so it goes
## too, and its file closes with it.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		OS.remove_logger(_catcher)


## The engine's side: called on whatever thread raised a message, so everything
## it touches is behind one lock.
class Catcher extends Logger:
	var _folder: String
	var _file_cap: int
	var _files_kept: int
	var _hand_over: Callable
	var _lock := Mutex.new()
	var _file: FileAccess
	var _waiting: Array[Dictionary] = []  # caught, and not yet taken by the main thread
	var _writing := false  # a line is being written, so a message raised meanwhile is not written

	func _init(folder: String, file_cap: int, files_kept: int, hand_over: Callable) -> void:
		_folder = folder
		_file_cap = file_cap
		_files_kept = files_kept
		_hand_over = hand_over
		DirAccess.make_dir_recursive_absolute(folder)
		_start_file()
		if not _waiting.is_empty():
			_hand_over.call_deferred()

	func _log_message(message: String, error: bool) -> void:
		_catch(ERROR_MESSAGE if error else MESSAGE, message.strip_edges(false, true), "", 0, "")

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, script_backtraces: Array[ScriptBacktrace]) -> void:
		var kind := ERROR
		match error_type:
			ERROR_TYPE_WARNING: kind = WARNING
			ERROR_TYPE_SCRIPT: kind = SCRIPT_ERROR
			ERROR_TYPE_SHADER: kind = SHADER_ERROR
		var text := code if rationale.is_empty() else rationale
		# the first backtrace with a frame names where the script raised it; the engine's own site otherwise
		for trace: ScriptBacktrace in script_backtraces:
			if trace.get_frame_count() > 0:
				_catch(kind, text, trace.get_frame_file(0), trace.get_frame_line(0), trace.get_frame_function(0))
				return
		_catch(kind, text, file, line, function)

	## One entry: written unless a line is being written already, kept for the
	## main thread, and handed over if nothing was waiting.
	func _catch(kind: StringName, text: String, file: String, line: int, function: String) -> void:
		var entry := {"at": Time.get_ticks_msec(), "kind": kind, "text": text, "file": file, "line": line, "function": function}
		_lock.lock()
		var first := _waiting.is_empty()
		if not _writing:
			_writing = true
			_write(entry)
			_writing = false
		_waiting.append(entry)
		_lock.unlock()
		if first:
			_hand_over.call_deferred()

	## Everything waiting, for the main thread, and forgotten here.
	func take() -> Array[Dictionary]:
		_lock.lock()
		var taken := _waiting
		_waiting = []
		_lock.unlock()
		return taken

	## A new file, numbered after the newest there is; then the files beyond the
	## count deleted, oldest first.
	func _start_file() -> void:
		var numbers: Array[int] = []
		# every file in the folder named for its number
		for name: String in DirAccess.get_files_at(_folder):
			if name.get_extension() == "log" and name.get_basename().is_valid_int():
				numbers.append(name.get_basename().to_int())
		numbers.sort()
		var next := 1 if numbers.is_empty() else numbers[numbers.size() - 1] + 1
		var path := _folder.path_join("%08d.log" % next)
		_file = FileAccess.open(path, FileAccess.WRITE)
		if _file == null:
			_waiting.append({"at": Time.get_ticks_msec(), "kind": ERROR, "text": "the log could not open %s: %s" % [path, error_string(FileAccess.get_open_error())], "file": "", "line": 0, "function": ""})
			return
		numbers.append(next)
		# the oldest files, until no more than the count remain
		while numbers.size() > _files_kept:
			DirAccess.remove_absolute(_folder.path_join("%08d.log" % numbers.pop_front()))

	## The entry as one line of the current file, flushed at once; a new file
	## first if the line would take this one past its cap.
	func _write(entry: Dictionary) -> void:
		if _file == null:
			return
		var where: String = "" if entry["file"] == "" else "  (%s:%d in %s)" % [entry["file"], entry["line"], entry["function"]]
		var line := "%d  %s  %s%s" % [entry["at"], entry["kind"], entry["text"], where]
		# past the cap with this line, unless the file is still empty: a line longer than the cap gets a file of its own
		if _file.get_position() > 0 and _file.get_position() + line.to_utf8_buffer().size() + 1 > _file_cap:
			_file.close()
			_start_file()
			if _file == null:
				return
		_file.store_line(line)
		_file.flush()
