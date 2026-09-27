extends SceneTree
const Actions := preload("res://addons/gd_chime/actions.gd")

## What must be true of a press that picks a file (file_pick.gd): its place
## declares its action; a file picked goes through the door as its name, its
## size and its kind, never its bytes; a file the model refuses keeps the
## refusal on the press, said by the reason its content reads, and the next
## file taken clears it; pressed, it opens a dialog offering the kinds given,
## the platform's where there is one but never while the reader is on a pad;
## and a refused press opens nothing.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_file_pick.gd

const Fixture := preload("res://tests/fixture.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Inputs := preload("res://addons/gd_chime/input_map.gd")
const FilePick := preload("res://addons/gd_chime/components/primitives/file_pick.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Verdict := preload("res://tests/verdict.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")

const ATTACHES := &"attaches"
const ACCOUNTS := "user://test_file_pick_accounts.PDF"
const PHOTO := "user://test_file_pick_photo.PNG"

var _verdict := Verdict.new()
var _made: Fixture
var _papers: Papers


## A model taking PDFs alone, holding what it was told, or refusing every file while shut.
class Papers extends Fixture.Model:
	var held: Variant = null
	var shut := value(false)

	func would(_action: StringName, payload: Dictionary) -> Phrase:
		if shut.read():
			return Phrase.of("the papers are shut")
		if payload.has("value") and payload["value"]["kind"] != "pdf":
			return Phrase.of("only pdf files are taken")
		return null

	func told(_action: StringName, payload: Dictionary) -> Phrase:
		held = payload["value"]
		return null


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(800, 600)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	_write(ACCOUNTS, 3000)
	_write(PHOTO, 120)
	await _verdict.states(_a_file_picked_goes_through_the_door_as_its_name_size_and_kind)
	await _verdict.states(_a_refused_file_is_said_on_the_press_and_the_next_taken_clears_it)
	await _verdict.states(_pressed_it_opens_a_dialog_of_the_kinds_the_platforms_but_never_on_a_pad)
	DirAccess.remove_absolute(ACCOUNTS)
	DirAccess.remove_absolute(PHOTO)
	quit(_verdict.deliver(get_script()))


## A file of so many bytes, written where a pick can find it.
func _write(path: String, bytes: int) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(_filled(bytes))
	file.close()


func _filled(bytes: int) -> PackedByteArray:
	var filled := PackedByteArray()
	filled.resize(bytes)
	filled.fill(7)
	return filled


func _built() -> void:
	_made = Fixture.new(root, {ATTACHES: "attach the papers"})
	_papers = Papers.new(_made.chimes)
	_made.commands.register(Chimes.GLOBAL, ATTACHES, _papers)
	var ui := _made.ui
	var pick := ui.file_pick(ATTACHES, ["pdf"], [ui.column([ui.text("choose a file"), ui.reason()])]).named(&"pick")
	ui.build(ui.app(&"app", [ui.screen(&"desk", [pick])]), root)
	_made.commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": &"desk"})
	await process_frame
	await process_frame


func _done() -> void:
	_papers.free()
	_made.done()


func _pick() -> FilePick:
	return _made.ui.node_named(&"pick")


## The words the press shows, every one standing.
func _said() -> Array:
	return _pick().find_children("*", "Control", true, false).filter(func(part: Node) -> bool: return part is Text and (part as Text).is_visible_in_tree()).map(func(part: Text) -> String: return part.get_text())


func _a_file_picked_goes_through_the_door_as_its_name_size_and_kind() -> void:
	await _built()
	_verdict.check(_made.driver.index.place_named(&"desk").performs.get(ATTACHES, &"x") == &"", "its place declares its action, going nowhere")
	_pick().picked(ProjectSettings.globalize_path(ACCOUNTS))
	_verdict.check(_papers.held == {"name": "test_file_pick_accounts.PDF", "size": 3000, "kind": "pdf"}, "the file picked reaches the model as its name, size and kind - its ending in small letters - and nothing else: %s" % [_papers.held])
	_done()


func _a_refused_file_is_said_on_the_press_and_the_next_taken_clears_it() -> void:
	await _built()
	_pick().picked(ProjectSettings.globalize_path(PHOTO))
	await process_frame
	await process_frame
	_verdict.check(_papers.held == null and str(_pick().get_refusal()) == "only pdf files are taken" and _said().has("only pdf files are taken"), "a PNG is refused, its kind read in small letters, nothing held, and the press says why: %s" % [_said()])
	_pick().picked(ProjectSettings.globalize_path(ACCOUNTS))
	await process_frame
	await process_frame
	_verdict.check(_papers.held != null and _pick().get_refusal() == null and not _said().has("only pdf files are taken"), "the next file taken clears it: %s" % [_said()])
	_done()


func _pressed_it_opens_a_dialog_of_the_kinds_the_platforms_but_never_on_a_pad() -> void:
	await _built()
	var dialog: FileDialog = _pick().get_children(true).filter(func(part: Node) -> bool: return part is FileDialog)[0]
	_verdict.check(dialog.filters == PackedStringArray(["*.pdf"]) and dialog.file_mode == FileDialog.FILE_MODE_OPEN_FILE, "its dialog opens one file, offering the kinds given: %s" % [dialog.filters])
	_pick().pressed()
	var on_keys := _pick().is_native()
	var opened := _pick().is_picking()
	dialog.hide()
	_made.inputs.used(Actions.pad(JOY_BUTTON_A))
	_pick().pressed()
	_verdict.check(opened and on_keys == DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE) and _pick().is_picking() and not _pick().is_native(), "pressed, the dialog opens - the platform's where it has one - and on a pad the engine's own")
	_verdict.check(FilePick.is_native_for(Inputs.KEY, true) and not FilePick.is_native_for(Inputs.PAD, true) and not FilePick.is_native_for(Inputs.KEY, false), "on a platform with a dialog of its own, the keys get it and a pad never does; on one without, nobody does")
	dialog.hide()
	_papers.shut.set_value(true)
	_pick().pressed()
	_verdict.check(not _pick().is_picking(), "refused, a press opens nothing")
	_done()
