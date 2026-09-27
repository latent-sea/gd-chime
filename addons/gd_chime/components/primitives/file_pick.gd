extends "pressable.gd"

const Inputs := preload("../../input_map.gd")

## A press that picks a file: pressed, it opens the engine's own file dialog
## - the platform's, where it has one - and the file picked goes through the
## door as its action, {"value": {name, size, kind}}.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A FILE IS ITS NAME, ITS SIZE AND ITS KIND, NEVER ITS BYTES: the file is
## opened only to learn its length, and nothing it holds is read or carried,
## so a model deciding whether to take it - by kind and by size - decides on
## what the reader chose and holds only that. The kinds the dialog offers
## are the caller's, as file endings; the door is still what refuses, and a
## refusal is kept and shown as any refused press's is, by the reason its
## content reads.
##
## THE DIALOG IS THE PLATFORM'S where the platform has one, since that is
## the one a reader knows - but not while the reader is on a pad, which a
## platform's dialog does not answer: then it is the engine's own, drawn in
## the application's look and walked by the pad as everything else is. The
## device is the map of inputs' (input_map.gd), read as the press lands.
##
## picked(path) is what the dialog calls, and a test or a probe calls it
## with a path of its own, so a pick is proved without a dialog on screen.
##
## Deliberately absent: more than one file at a time, a folder, and dropping
## a file from outside the window.

var _dialog := FileDialog.new()
var _inputs: Inputs


func _init(chimes: Chimes, commands: Commands, place: Node, does: StringName, kinds: Array, inputs: Inputs, style: Variant) -> void:
	super(chimes, commands, place, does, {}, style)
	_inputs = inputs
	_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_dialog.access = FileDialog.ACCESS_FILESYSTEM
	# every kind taken, as the dialog's filter of file endings: *.pdf
	_dialog.filters = PackedStringArray(kinds.map(func(kind: String) -> String: return "*.%s" % kind))
	add_child(_dialog)
	_dialog.file_selected.connect(picked)


## Pressed while it can be used: the dialog opened - the platform's, unless the reader is on a pad.
func pressed() -> void:
	if not is_usable():
		return
	_dialog.use_native_dialog = is_native_for(_inputs.get_device(), DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE))
	_dialog.popup_centered_ratio()


## Whether the platform's dialog is the one opened, for a reader on this
## device on a platform that has one or not: never on a pad.
static func is_native_for(device: String, platform_has: bool) -> bool:
	return platform_has and device != Inputs.PAD


## Whether the dialog is open now, and whether it is the platform's.
func is_picking() -> bool:
	return _dialog.visible


func is_native() -> bool:
	return _dialog.use_native_dialog


## A file picked: its name, its size and its kind through the door, the answer kept for the face to show.
func picked(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	var chosen := {"name": path.get_file(), "size": file.get_length(), "kind": path.get_extension().to_lower()}
	file.close()
	var answer := _commands.dispatch(region, action, {"value": chosen})
	_keep_refusal(null if _commands.get_last()["paused"] else answer)
	needs_refresh()


static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"file_pick").new(ui.chimes, ui.commands, ui.current_place(), desc.props["action"], desc.props["kinds"], ui.inputs, desc.props["style"])
	made.prompts = ui.prompts
	ui.attach(made, parent, desc.facts)
	return made
