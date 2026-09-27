extends SceneTree

## What must be true of the settings file: nothing is written until a kept
## model moves, and then once, as the frame ends, however often it moved,
## with nothing half written left beside it; a second run hands every model
## back what the first left - the panels, and the keys bound; a section no
## model kept this run goes back out as it came in, while a kept one is
## written over its own; a write that fails before its rename leaves the
## file as it was and nothing beside it; a file that is not settings is
## moved aside, under a numbered name if one is taken, said out loud once,
## and never written over - left where it is if it cannot be moved - while
## every model starts as it is; and a section that is not a model's is said.
##
## A write made to fail holds the file open, which refuses its replacement on
## Windows - the platform this is run on.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_settings_file.gd

const Belfry := preload("res://addons/gd_chime/belfry.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Actions := preload("res://addons/gd_chime/actions.gd")
const Inputs := preload("res://addons/gd_chime/input_map.gd")
const Panels := preload("res://addons/gd_chime/panels.gd")
const SettingsFile := preload("res://addons/gd_chime/settings_file.gd")
const Verdict := preload("res://tests/verdict.gd")

const PATH := "user://test_settings_file.json"
const WRITING := PATH + ".writing"
const ASIDE := PATH + ".unreadable"
const ASIDE_AGAIN := PATH + ".unreadable.2"
const UNREADABLE := "[\"half a list\""

var _verdict := Verdict.new()
var _hearing := Hearing.new()


## Keeps every sentence pushed as an error.
class Hearing extends Logger:
	var said: Array[String] = []

	func _log_error(_function: String, _file: String, _line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_ERROR:
			said.append(code + rationale)


## One run of an application's keeping: its panels and its map of inputs,
## kept in the file under two sections.
class Run:
	var chimes := Chimes.new(Belfry.new())
	var panels: Panels
	var inputs: Inputs
	var driver: Driver
	var file: SettingsFile

	func _init(root: Node) -> void:
		panels = Panels.new(chimes, {&"outer": 0.25}, {&"list": [&"outer", Panels.FIRST], &"page": [&"outer", Panels.SECOND]}, {&"folds_the_list": &"list"})
		var actions := Actions.new()
		actions.declare_all({&"runs": ["run", Actions.keys(KEY_F5)]})
		driver = Driver.new(chimes)
		inputs = Inputs.new(chimes, actions, driver)
		file = SettingsFile.new(chimes, PATH)
		for node: Node in [panels, inputs, driver, file]:
			root.add_child(node)
		file.keep("panels", panels)
		file.keep("keys", inputs)

	func done() -> void:
		for node: Node in [file, panels, inputs, driver]:
			node.free()


func _init() -> void:
	OS.add_logger(_hearing)
	_clear()
	await _verdict.states(_nothing_is_written_until_a_model_moves_and_then_once_as_the_frame_ends)
	await _verdict.states(_a_second_run_finds_every_model_as_the_first_left_it)
	await _verdict.states(_a_section_no_model_kept_goes_back_out_as_it_came_in)
	await _verdict.states(_a_write_that_fails_before_its_rename_leaves_the_file_as_it_was)
	_clear()
	await _verdict.states(_a_file_that_is_not_settings_is_moved_aside_said_and_never_written_over)
	_clear()
	OS.remove_logger(_hearing)
	quit(_verdict.deliver(get_script()))


## Every file this test may leave beside the settings, removed.
func _clear() -> void:
	# the file, what is written before its rename, and what was moved aside
	for path: String in [PATH, WRITING, ASIDE, ASIDE_AGAIN]:
		DirAccess.remove_absolute(path)


## A file holding exactly this text.
func _put(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _nothing_is_written_until_a_model_moves_and_then_once_as_the_frame_ends() -> void:
	var run := Run.new(root)
	await process_frame
	_verdict.check(not FileAccess.file_exists(PATH), "with nothing moved, nothing is written")
	# the pane dragged across five moves in one frame
	for step: int in 5:
		run.panels.told(Panels.RESIZES, {"split": "outer", "by": 0.02, "to": 0.3 + 0.02 * step})
	_verdict.check(not FileAccess.file_exists(PATH), "moved, it is not written while the frame is still going")
	await process_frame
	await process_frame
	var written: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	_verdict.check(written is Dictionary and is_equal_approx(written["panels"]["splits"]["outer"]["share"], 0.38) and written.has("keys"), "the frame over, it is written once, whole, every section as its model saves it: %s" % [written])
	_verdict.check(not FileAccess.file_exists(WRITING), "and nothing half written is left beside it")
	run.done()


func _a_second_run_finds_every_model_as_the_first_left_it() -> void:
	var first := Run.new(root)
	first.panels.told(&"folds_the_list", {})
	# bound as a save read back binds, since this run has no places for a conflict to be asked over
	first.inputs.restore({"runs": [Actions.keys(KEY_R, KEY_MASK_CTRL)]})
	await process_frame
	await process_frame
	first.done()
	var second := Run.new(root)
	_verdict.check(second.panels.folded(&"outer").read() == Panels.FIRST and is_equal_approx(second.panels.share(&"outer").read(), 0.38), "a second run's panels stand as the first left them: %s" % [second.panels.saved()])
	_verdict.check(second.inputs.get_inputs(&"runs") == [Actions.keys(KEY_R, KEY_MASK_CTRL)], "and its keys are bound as the first bound them, a chord and all: %s" % [second.inputs.get_inputs(&"runs")])
	second.done()


func _a_section_no_model_kept_goes_back_out_as_it_came_in() -> void:
	var held: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	var later := {"columns": ["name", "price"], "wide": 0.5}
	held["later"] = later
	_put(PATH, JSON.stringify(held, "\t"))
	var run := Run.new(root)
	run.panels.told(&"folds_the_list", {})
	await process_frame
	await process_frame
	var written: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	_verdict.check(written is Dictionary and written.get("later") == later, "a section no model kept this run is written back exactly as it was read: %s" % [written])
	_verdict.check(written is Dictionary and written["panels"]["splits"]["outer"]["folded"] == "" and written["panels"] != held["panels"], "while a kept section is written over its own, as its model now saves it: %s" % [written])
	run.done()


func _a_write_that_fails_before_its_rename_leaves_the_file_as_it_was() -> void:
	var before := FileAccess.get_file_as_string(PATH)
	var run := Run.new(root)
	# held open, the file refuses to be replaced, so the write stops after .writing is written and before the rename
	var holding := FileAccess.open(PATH, FileAccess.READ)
	var said := _hearing.said.size()
	run.panels.told(&"folds_the_list", {})
	await process_frame
	await process_frame
	holding.close()
	var now := FileAccess.get_file_as_string(PATH)
	_verdict.check(now == before and JSON.parse_string(now) is Dictionary, "a write refused its rename leaves the file exactly as it was, and still settings: %s" % [now])
	_verdict.check(not FileAccess.file_exists(WRITING), "and nothing half written beside it")
	_verdict.check(_hearing.said.size() == said + 1, "and the failure is said out loud: %s" % [_hearing.said.slice(said)])
	run.done()
	var again := Run.new(root)
	_verdict.check(again.panels.folded(&"outer").read() == Panels.NEITHER, "the next run finds the file as it last stood whole: %s" % [again.panels.saved()])
	again.done()


func _a_file_that_is_not_settings_is_moved_aside_said_and_never_written_over() -> void:
	_put(ASIDE, "moved aside by an earlier run")
	_put(PATH, UNREADABLE)
	var said := _hearing.said.size()
	var run := Run.new(root)
	_verdict.check(_hearing.said.size() == said + 1 and _hearing.said[-1].contains(ASIDE_AGAIN) and is_equal_approx(run.panels.share(&"outer").read(), 0.25) and run.inputs.get_inputs(&"runs") == [Actions.keys(KEY_F5)], "a file that is not settings is said out loud once, naming where it was moved, and every model starts as it is: %s" % [_hearing.said.slice(said)])
	_verdict.check(not FileAccess.file_exists(PATH) and FileAccess.get_file_as_string(ASIDE_AGAIN) == UNREADABLE and FileAccess.get_file_as_string(ASIDE) == "moved aside by an earlier run", "it is moved aside whole under the next free number, the earlier one untouched")
	run.panels.told(&"folds_the_list", {})
	await process_frame
	await process_frame
	var written: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	_verdict.check(written is Dictionary and written["panels"]["splits"]["outer"]["folded"] == "first" and FileAccess.get_file_as_string(ASIDE_AGAIN) == UNREADABLE, "at the next move the file is written whole again, and what was moved aside stays as it was")
	_verdict.check(_hearing.said.size() == said + 1, "and it is said only the once: %s" % [_hearing.said.slice(said)])
	run.done()
	_put(PATH, UNREADABLE)
	# held open, the unreadable file cannot be moved aside
	var holding := FileAccess.open(PATH, FileAccess.READ)
	said = _hearing.said.size()
	run = Run.new(root)
	run.panels.told(&"folds_the_list", {})
	await process_frame
	await process_frame
	holding.close()
	_verdict.check(_hearing.said.size() == said + 1 and FileAccess.get_file_as_string(PATH) == UNREADABLE and not FileAccess.file_exists(WRITING), "one that cannot be moved aside is said once and never written over: %s" % [_hearing.said.slice(said)])
	run.done()
	_put(PATH, JSON.stringify({"panels": "wide", "keys": {}}))
	said = _hearing.said.size()
	run = Run.new(root)
	_verdict.check(_hearing.said.size() == said + 1 and run.panels.folded(&"outer").read() == Panels.NEITHER, "a section that is no model's settings is said, and that model starts as it is: %s" % [_hearing.said.slice(said)])
	run.done()
