extends SceneTree

## What must be true of the documents open and their tabs: opening puts a
## document after the one in front and brings it forward, opening it again
## only brings it forward; closing the one in front brings the one after it,
## else the one before; next and previous go round; each refuses what it
## cannot do; a tab's words follow the catalogue; a save goes out and in, and
## one naming what is not there is said out loud; and the tabs are a flap
## per document, the one in front current in the look's current box and
## kept in view, a press bringing one forward and its mark closing it.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_documents.gd

const Fixture := preload("res://tests/fixture.gd")
const Belfry := preload("res://addons/gd_chime/belfry.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Documents := preload("res://addons/gd_chime/documents.gd")
const Tabs := preload("res://addons/gd_chime/components/recipes/tab_bar.gd")
const Pressable := preload("res://addons/gd_chime/components/primitives/pressable.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")
const Verdict := preload("res://tests/verdict.gd")
const Navigation := preload("res://addons/gd_chime/theme_navigation.gd")

const SAVE := "user://test_documents.json"
const WORDS := {Documents.OPENS: "open", Documents.CLOSES: "close", Documents.CLOSES_FRONT: "close this", Documents.SHOWS_NEXT: "next", Documents.SHOWS_PREVIOUS: "previous"}

var _verdict := Verdict.new()
var _hearing := Hearing.new()


## Keeps every sentence pushed as an error.
class Hearing extends Logger:
	var said: Array[String] = []

	func _log_error(_function: String, _file: String, _line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_ERROR:
			said.append(code + rationale)


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(400, 300)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	OS.add_logger(_hearing)
	await _verdict.states(_opening_and_closing_keep_the_order_and_the_front_and_refuse_what_cannot_be_done)
	await _verdict.states(_a_tab_s_words_follow_the_catalogue_and_a_save_goes_out_and_in_whole)
	await _verdict.states(_the_tabs_are_a_flap_per_document_the_front_one_current_and_in_view)
	OS.remove_logger(_hearing)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## A catalogue of files held by a model, and the documents over it.
func _documents(made: Fixture, count: int = 4) -> Array:
	var files := Fixture.Model.new(made.chimes, Chimes.GLOBAL)
	var all: Array = []
	# every file of the catalogue, its value and its words
	for at: int in count:
		all.append({"value": "f%d" % at, "words": "file %d" % at})
	files.set_value(&"items", all)
	var documents := Documents.new(made.chimes, files.of(&"items"))
	root.add_child(files)
	root.add_child(documents)
	return [files, documents]


## The documents answering their commands from anywhere.
func _registered(made: Fixture, documents: Documents) -> void:
	# every command of the documents
	for action: StringName in WORDS:
		made.commands.register(Chimes.GLOBAL, action, documents)


func _values(documents: Documents) -> Array:
	return documents.get_open().map(func(entry: Dictionary) -> String: return entry["value"])


func _opening_and_closing_keep_the_order_and_the_front_and_refuse_what_cannot_be_done() -> void:
	var made := Fixture.new(root, WORDS)
	var both := _documents(made)
	var documents: Documents = both[1]
	_registered(made, documents)
	_verdict.check(documents.would(Documents.CLOSES_FRONT, {}) != null and documents.would(Documents.SHOWS_NEXT, {}) != null, "with nothing open, closing and going on are refused")
	# f0, then f1 after it, then f0 again, then f2 opened while f0 is in front goes between them
	for value: String in ["f0", "f1", "f0", "f2"]:
		made.commands.dispatch(Chimes.GLOBAL, Documents.OPENS, {"value": value})
	_verdict.check(_values(documents) == ["f0", "f2", "f1"] and documents.get_front() == "f2", "a document opens after the one in front and comes forward; one open already only comes forward: %s %s" % [_values(documents), documents.get_front()])
	made.commands.dispatch(Chimes.GLOBAL, Documents.SHOWS_NEXT, {})
	made.commands.dispatch(Chimes.GLOBAL, Documents.SHOWS_NEXT, {})
	_verdict.check(documents.get_front() == "f0", "next goes on, and round from the last to the first: %s" % documents.get_front())
	made.commands.dispatch(Chimes.GLOBAL, Documents.SHOWS_PREVIOUS, {})
	_verdict.check(documents.get_front() == "f1", "previous goes back round: %s" % documents.get_front())
	made.commands.dispatch(Chimes.GLOBAL, Documents.CLOSES_FRONT, {})
	_verdict.check(_values(documents) == ["f0", "f2"] and documents.get_front() == "f2", "the last one closed in front, the one before it comes forward: %s %s" % [_values(documents), documents.get_front()])
	made.commands.dispatch(Chimes.GLOBAL, Documents.OPENS, {"value": "f0"})
	made.commands.dispatch(Chimes.GLOBAL, Documents.CLOSES, {"value": "f0"})
	_verdict.check(_values(documents) == ["f2"] and documents.get_front() == "f2", "one closed in front, the one after it comes forward: %s" % documents.get_front())
	_verdict.check(str(made.commands.dispatch(Chimes.GLOBAL, Documents.OPENS, {"value": "nine"})) == "There is no nine to open" and made.commands.dispatch(Chimes.GLOBAL, Documents.CLOSES, {"value": "f1"}) != null and documents.would(Documents.SHOWS_NEXT, {}) != null, "a document there is none of, one not open, and going on from the only one are refused in words")
	# f3 then f1 opened after f2, so f1 stands between them; closed in front, f3 after it comes forward
	made.commands.dispatch(Chimes.GLOBAL, Documents.OPENS, {"value": "f3"})
	made.commands.dispatch(Chimes.GLOBAL, Documents.OPENS, {"value": "f2"})
	made.commands.dispatch(Chimes.GLOBAL, Documents.OPENS, {"value": "f1"})
	made.commands.dispatch(Chimes.GLOBAL, Documents.CLOSES_FRONT, {})
	_verdict.check(_values(documents) == ["f2", "f3"] and documents.get_front() == "f3", "one closed in front between two, the one after it comes forward, not the one before: %s %s" % [_values(documents), documents.get_front()])
	made.commands.dispatch(Chimes.GLOBAL, Documents.CLOSES, {"value": "f3"})
	made.commands.dispatch(Chimes.GLOBAL, Documents.CLOSES, {"value": "f2"})
	_verdict.check(_values(documents).is_empty() and documents.get_front() == null, "the last one closed, nothing is open or in front")
	for model: Node in both:
		model.free()
	made.done()


func _a_tab_s_words_follow_the_catalogue_and_a_save_goes_out_and_in_whole() -> void:
	var made := Fixture.new(root, WORDS)
	var both := _documents(made)
	var files: Fixture.Model = both[0]
	var documents: Documents = both[1]
	documents.open("f1")
	documents.open("f3")
	var renamed: Array = files.of(&"items").read().duplicate(true)
	renamed[1]["words"] = "renamed"
	files.set_value(&"items", renamed)
	_verdict.check(documents.get_open()[0]["words"] == "renamed", "a document renamed in the catalogue reads its new words: %s" % [documents.get_open()])
	var file := FileAccess.open(SAVE, FileAccess.WRITE)
	file.store_string(JSON.stringify(documents.saved()))
	file.close()
	var read: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	DirAccess.remove_absolute(SAVE)
	var files_again := Fixture.Model.new(Chimes.new(Belfry.new()), Chimes.GLOBAL)
	files_again.set_value(&"items", files.of(&"items").read())
	var again: Array = [files_again, Documents.new(files_again._chimes, files_again.of(&"items"))]
	again[1].restore(read)
	_verdict.check(_values(again[1]) == ["f1", "f3"] and again[1].get_front() == "f3", "read back through a file, the same open and the same in front: %s" % [again[1].saved()])
	var before: int = _hearing.said.size()
	again[1].restore({"open": ["f1", "gone"], "front": "f1"})
	_verdict.check(_hearing.said.size() == before + 1 and _values(again[1]) == ["f1", "f3"], "a save naming a document there is none of is said out loud, and nothing moves")
	for model: Node in both + again:
		model.free()
	made.done()


func _the_tabs_are_a_flap_per_document_the_front_one_current_and_in_view() -> void:
	# the flaps' two actions alone: the startup check refuses one declared that nothing performs
	var made := Fixture.new(root, {Documents.OPENS: "open", Documents.CLOSES: "close"})
	var both := _documents(made, 12)
	var documents: Documents = both[1]
	_registered(made, documents)
	var ui := made.ui
	ui.start(ui.app(&"app", [ui.column([Tabs.documents(ui, documents).named(&"strip"), ui.surface(Themes.SURFACE).grow()])]))
	await _a_frame_passes()
	_verdict.check(_flaps(ui).is_empty(), "with nothing open there are no flaps")
	# every file opened in turn, the last in front
	for at: int in 12:
		documents.open("f%d" % at)
	await _a_frame_passes()
	await _a_frame_passes()
	var flaps := _flaps(ui)
	_verdict.check(flaps.size() == 12 and _words(flaps[0]) == "file 0" and _words(flaps[11]) == "file 11", "a flap per document open, in order, each the document's words: %s" % [flaps.map(func(flap: Node) -> String: return _words(flap))])
	var strip: Control = ui.node_named(&"strip")
	var last: Pressable = flaps[11].get_child(0)
	_verdict.check(last.is_current() and last._last_box == root.theme.get_stylebox(&"current", Navigation.TAB) and not (flaps[0].get_child(0) as Pressable).is_current(), "the one in front stands current, in the look's current box, and no other")
	_verdict.check(strip.get_global_rect().encloses(last.get_global_rect()), "and it is in view at the end of a strip too long for the window: %s in %s" % [last.get_global_rect(), strip.get_global_rect()])
	(flaps[11].get_child(1) as Pressable).pressed()
	await _a_frame_passes()
	_verdict.check(documents.get_open().size() == 11 and documents.get_front() == "f10", "its mark closes it, the one before coming forward: %s" % documents.get_front())
	(_flaps(ui)[2].get_child(0) as Pressable).pressed()
	await _a_frame_passes()
	await _a_frame_passes()
	_verdict.check(documents.get_front() == "f2" and (_flaps(ui)[2].get_child(0) as Pressable).is_current() and not (_flaps(ui)[10].get_child(0) as Pressable).is_current(), "a flap pressed brings its document forward, and the current look goes with it: %s" % documents.get_front())
	_verdict.check(strip.get_global_rect().encloses((_flaps(ui)[2].get_child(0) as Control).get_global_rect()), "and that flap is brought into view")
	var files: Fixture.Model = both[0]
	var renamed: Array = files.of(&"items").read().duplicate(true)
	renamed[2]["words"] = "renamed"
	files.set_value(&"items", renamed)
	await _a_frame_passes()
	_verdict.check(_words(_flaps(ui)[2]) == "renamed", "a document renamed in the catalogue, its flap says the new words in place: %s" % _words(_flaps(ui)[2]))
	for model: Node in both:
		model.free()
	made.done()


## The flaps standing now, in order.
func _flaps(ui: RefCounted) -> Array:
	var strip: Node = ui.node_named(&"strip")
	var row: Node = strip.get_child(0)
	return row.get_children().filter(func(flap: Node) -> bool: return flap is Control and (flap as Control).visible and not flap.is_in_group(&"going"))


func _words(flap: Node) -> String:
	return (flap.get_child(0).get_child(0) as Text).get_text()
