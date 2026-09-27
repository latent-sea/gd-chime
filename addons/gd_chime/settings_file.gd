extends "controller.gd"

## An application's settings kept between runs: one file of plain data, a
## section per model that keeps something - how the panels stand, which
## documents are open, what keys are bound - read as the application starts
## and written again as any of them moves.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A MODEL KEEPS ITSELF, THIS KEEPS THE FILE. A model that is kept answers
## saved() with plain data and takes it back with restore(), refusing a
## save that is not its own out loud (panels.gd, documents.gd, input_map.gd);
## it never opens a file. This opens the one file: keep(section, model)
## hands the model back what the file held for it, then follows what its
## save reads (reads.gd) and writes the whole file once at the end of a frame in
## which any of them moved - so a pane dragged across a hundred frames writes
## at most once a frame, and a frame with nothing moved writes nothing.
##
## A WRITE NEVER LOSES WHAT IT DID NOT MAKE. The file written is what was
## read, with every section kept this run written over its own: a section no
## model kept this run - a model registered later, a build without that
## feature - goes back out exactly as it came in.
##
## WHAT COMES BACK OFF A DISK IS NOT OURS. A file that is not a dictionary of
## sections - hand-edited, half written - is moved aside to <file>.unreadable
## (.unreadable.2 and on when that is taken), said out loud once, and read as
## empty, every model keeping what it has; if it cannot be moved it is left
## where it is and nothing is written over it this run. A section is only
## ever handed to its model, which checks it (saved_inputs.gd's rule, the
## same here).
##
## WHAT A WRITE GUARANTEES. The file is written whole to <file>.writing
## beside it, then renamed over it with the engine's DirAccess.rename, which
## replaces an existing file on Windows (checked on 4.6.2): a write that stops
## part way - the process killed, the disk full, the rename refused - leaves
## the file as it was, and one that fails is said out loud, its .writing
## removed, and the run goes on. What is NOT guaranteed: whether the engine
## replaces the file in one step is the engine's, not ours; and nothing is
## forced to the disk before the rename, so after a power cut the file holds
## either write only as far as the operating system's own journal keeps it.
##
## The file is JSON, since every section is already strings, numbers, lists
## and dictionaries - no format of its own. Where it lives is the
## application's to say: under user://, which the engine keeps per
## application and per player.
##
## Deliberately absent: a version, a migration, more than one file, and a
## write as the application is freed - the models may be gone by then, so
## a change in the very frame the window closes is the one thing not kept.

var _path: String
var _held: Dictionary = {}  # what the file holds, section by section: as read, then as last written
var _kept: Dictionary = {}  # section -> the model that keeps it
var _due: bool = false  # whether a section moved since the file was last written
var _left: bool = false  # whether an unreadable file could not be moved aside, so nothing may be written over it


func _init(chimes: Chimes, path: String) -> void:
	super(chimes, [], Chimes.GLOBAL)
	_path = path
	set_process(false)
	if not FileAccess.file_exists(path):
		return
	var read := JSON.new()
	if read.parse(FileAccess.get_file_as_string(path)) == OK and read.data is Dictionary:
		_held = read.data
		return
	var aside := path + ".unreadable"
	var tried := 1
	# the first name beside it that no earlier unreadable file already holds
	while FileAccess.file_exists(aside):
		tried += 1
		aside = "%s.unreadable.%d" % [path, tried]
	if DirAccess.rename_absolute(path, aside) == OK:
		push_error("%s is not a file of settings; it is kept as %s and every setting starts as it is" % [path, aside])
		return
	_left = true
	push_error("%s is not a file of settings and could not be moved aside; every setting starts as it is and nothing is written over it this run" % path)


## The file the settings are kept in.
func get_file_path() -> String:
	return _path


## A model kept under this section: handed back what the file held for it,
## if anything, and followed from now on on whatever its save reads.
func keep(section: String, model: Object) -> void:
	if _held.has(section) and _held[section] is Dictionary:
		model.restore(_held[section])
	elif _held.has(section):
		push_error("what %s holds for %s is not settings; it starts as it is" % [_path, section])
	follow(StringName(section), func() -> void: _saved_moved(section, model))
	_kept[section] = model


## A kept model's save read, so what it read is followed; moved once it is
## kept, the file is written once this frame is over.
func _saved_moved(section: String, model: Object) -> void:
	model.saved()
	if _kept.has(section):
		_due = true
		set_process(true)


func _process(_delta: float) -> void:
	write()
	set_process(false)


## The file written now, what it held with every kept section over its own,
## if anything moved since it was last written.
func write() -> void:
	if not _due or _left:
		return
	_due = false
	# every model kept, its section as it saves it, over what the file held
	for section: String in _kept:
		_held[section] = _kept[section].saved()
	var writing := _path + ".writing"
	var file := FileAccess.open(writing, FileAccess.WRITE)
	if file == null:
		push_error("the settings could not be written to %s: %s; it holds what it held" % [writing, error_string(FileAccess.get_open_error())])
		return
	var whole := file.store_string(JSON.stringify(_held, "\t"))
	file.close()
	var error := DirAccess.rename_absolute(writing, _path) if whole else ERR_FILE_CANT_WRITE
	if error == OK:
		return
	DirAccess.remove_absolute(writing)
	push_error("the settings could not be written to %s: %s; it holds what it held" % [_path, error_string(error)])
