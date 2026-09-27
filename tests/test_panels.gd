extends SceneTree

## What must be true of the panels model: a split's share moves with a
## resize and opens a folded side; a pane folds and unfolds by its action;
## expanding a pane folds every other side on the way down to it and brings
## the folds back after; a save goes out and in again, through a file too,
## and one that is not these panels is said out loud and nothing moves.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_panels.gd

const Belfry := preload("res://addons/gd_chime/belfry.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Panels := preload("res://addons/gd_chime/panels.gd")
const Verdict := preload("res://tests/verdict.gd")
const Reads := preload("res://addons/gd_chime/reads.gd")

const SAVE := "user://test_panels.json"

var _verdict := Verdict.new()
var _hearing := Hearing.new()


## Keeps every sentence pushed as an error.
class Hearing extends Logger:
	var said: Array[String] = []

	func _log_error(_function: String, _file: String, _line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_ERROR:
			said.append(code + rationale)


func _init() -> void:
	OS.add_logger(_hearing)
	await _verdict.states(_a_resize_moves_the_share_and_opens_a_folded_side)
	await _verdict.states(_a_pane_folds_and_unfolds_by_its_action_and_says_whether_it_shows)
	await _verdict.states(_expanding_a_pane_folds_every_other_side_on_the_way_to_it_and_the_folds_come_back)
	await _verdict.states(_a_save_goes_out_and_in_again_and_one_that_is_not_these_panels_changes_nothing)
	OS.remove_logger(_hearing)
	quit(_verdict.deliver(get_script()))


## The shell of a workspace: the explorer beside the rest, the rest the
## centre beside the schema, the centre the editor over the results.
func _panels() -> Panels:
	var panels := Panels.new(Chimes.new(Belfry.new()), {&"outer": 0.2, &"rest": 0.75, &"centre": 0.6}, {
		&"explorer": [&"outer", Panels.FIRST], &"rest": [&"outer", Panels.SECOND],
		&"centre": [&"rest", Panels.FIRST], &"schema": [&"rest", Panels.SECOND],
		&"editor": [&"centre", Panels.FIRST], &"results": [&"centre", Panels.SECOND],
	}, {&"folds_explorer": &"explorer", &"folds_results": &"results"}, {&"expands_results": &"results"}, {&"shows_results": &"results"})
	root.add_child(panels)
	return panels


func _a_resize_moves_the_share_and_opens_a_folded_side() -> void:
	var panels := _panels()
	var share := panels.share(&"outer")
	panels.told(Panels.RESIZES, {"split": "outer", "by": 0.15, "to": 0.35})
	_verdict.check(is_equal_approx(share.read(), 0.35), "a resize sets the split's first share: %s" % share.read())
	panels.told(&"folds_explorer", {})
	_verdict.check(panels.folded(&"outer").read() == Panels.FIRST, "folded, the explorer's side is folded: %s" % panels.folded(&"outer").read())
	panels.told(Panels.RESIZES, {"split": "outer", "by": 0.1, "to": 0.1})
	_verdict.check(panels.folded(&"outer").read() == Panels.NEITHER and is_equal_approx(share.read(), 0.1), "a sash dragged out of the edge opens the folded side, at the share it was dragged to: %s %s" % [panels.folded(&"outer").read(), share.read()])
	panels.told(Panels.RESIZES, {"split": "outer", "by": 0.25})
	_verdict.check(is_equal_approx(share.read(), 0.35), "from a grip whose holder says no share, the share moves on by what it was moved: %s" % share.read())
	panels.told(Panels.RESIZES, {"split": "outer", "by": 0.5, "to": 1.4})
	_verdict.check(is_equal_approx(share.read(), 1.0), "and a share is never past all of the room: %s" % share.read())
	_verdict.check(panels.would(Panels.RESIZES, {"split": "nowhere", "by": 0.1}) != null and panels.would(Panels.RESIZES, {"split": "outer"}) == null, "a split there is none of is refused; the grip asked at rest is not")
	panels.free()


func _a_pane_folds_and_unfolds_by_its_action_and_says_whether_it_shows() -> void:
	var panels := _panels()
	var shown := panels.shown(&"results")
	Reads.begin()
	var showing: bool = shown.read()
	var read: Array = Reads.end().keys()
	_verdict.check(showing and read == [Reads.hung(panels._values.get_address(), panels._values.get_address())], "a pane shows to begin with, bound on the panels' own values: %s" % [read])
	panels.told(&"folds_results", {})
	_verdict.check(shown.read() == false and panels.folded(&"centre").read() == Panels.SECOND, "its action folds it, on the side it stands: %s" % panels.folded(&"centre").read())
	panels.told(&"folds_results", {})
	_verdict.check(shown.read() == true and panels.folded(&"centre").read() == Panels.NEITHER, "and again unfolds it")
	panels.told(&"folds_explorer", {})
	_verdict.check(not panels.is_shown(&"explorer") and panels.is_shown(&"editor"), "a folded pane hides nothing on the other side")
	panels.told(&"folds_results", {})
	panels.told(&"shows_results", {})
	_verdict.check(panels.is_shown(&"results") and not panels.is_shown(&"explorer"), "brought into view, the folded results show, and the explorer folded elsewhere stays folded")
	panels.told(&"shows_results", {})
	_verdict.check(panels.is_shown(&"results"), "and brought into view again, they stay shown - it never folds")
	panels.free()


func _expanding_a_pane_folds_every_other_side_on_the_way_to_it_and_the_folds_come_back() -> void:
	var panels := _panels()
	panels.told(&"folds_explorer", {})
	panels.told(&"expands_results", {})
	var folds: Array = [&"outer", &"rest", &"centre"].map(func(split: StringName) -> StringName: return panels.folded(split).read())
	_verdict.check(folds == [Panels.FIRST, Panels.SECOND, Panels.FIRST] and panels.get_expanded() == &"results", "expanded, every split on the way down folds the side the results are not on: %s" % [folds])
	_verdict.check(panels.is_shown(&"results") and not panels.is_shown(&"editor") and not panels.is_shown(&"schema") and not panels.is_shown(&"explorer"), "so the results alone show")
	panels.told(&"expands_results", {})
	folds = [&"outer", &"rest", &"centre"].map(func(split: StringName) -> StringName: return panels.folded(split).read())
	_verdict.check(folds == [Panels.FIRST, Panels.NEITHER, Panels.NEITHER] and panels.get_expanded() == &"", "expanded again, the folds it had before come back - the explorer still folded: %s" % [folds])
	panels.told(&"expands_results", {})
	panels.told(&"folds_explorer", {})
	_verdict.check(panels.get_expanded() == &"" and panels.is_shown(&"explorer"), "a fold by hand ends the expansion")
	panels.free()


func _a_save_goes_out_and_in_again_and_one_that_is_not_these_panels_changes_nothing() -> void:
	var panels := _panels()
	panels.told(Panels.RESIZES, {"split": "centre", "by": -0.15, "to": 0.45})
	panels.told(&"expands_results", {})
	var file := FileAccess.open(SAVE, FileAccess.WRITE)
	file.store_string(JSON.stringify(panels.saved()))
	file.close()
	var read: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	DirAccess.remove_absolute(SAVE)
	var again := _panels()
	again.restore(read)
	_verdict.check(is_equal_approx(again.share(&"centre").read(), 0.45) and again.get_expanded() == &"results" and not again.is_shown(&"editor"), "read back through a file, the shares, the folds and the expansion are what was saved: %s" % [again.saved()])
	again.told(&"expands_results", {})
	_verdict.check(again.is_shown(&"editor") and again.is_shown(&"explorer"), "and the folds from before the expansion came with it: expanded again, they are back")
	var before := again.saved()
	# every save that is not these panels, each refused whole and said
	for wrong: Dictionary in [{"splits": {"elsewhere": {"share": 0.5, "folded": ""}}, "expanded": "", "before": {}}, {"splits": {"outer": {"share": 2.0, "folded": ""}}, "expanded": "", "before": {}}, {"splits": {"outer": {"share": 0.5, "folded": "sideways"}}, "expanded": "", "before": {}}, {"splits": {}}]:
		var said := _hearing.said.size()
		again.restore(wrong)
		_verdict.check(_hearing.said.size() == said + 1 and again.saved() == before, "a save that is not these panels is said out loud and nothing moves: %s" % [wrong])
	panels.free()
	again.free()
