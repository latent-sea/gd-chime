extends SceneTree

## What must be true of a value worked out once per change (ui.kept): its
## function runs once however often the value is read, and again only once
## something it read has moved; whoever reads it is drawn again when what
## the function read moves, and not when anything else does (the speed
## audit, 22 Nov: a list every piece of a page read, worked out on every
## read, cost each piece's draw the whole list).
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_kept_bound.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Verdict := preload("res://tests/verdict.gd")
const Text := preload("res://addons/gd_chime/components/primitives/text.gd")

## How many pieces read the one kept value, as a page's blocks read their list.
const READERS := 30
## How many times it may be worked out while the screen is built: the model stood up in its place moves once.
const BUILT := 2

var _verdict := Verdict.new()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	await _verdict.states(_worked_out_once_however_often_read_and_again_once_what_it_read_moves)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


func _worked_out_once_however_often_read_and_again_once_what_it_read_moves() -> void:
	var made := Fixture.new(root, {})
	var ui := made.ui
	var model := Fixture.Model.new(made.chimes, &"app")
	model.set_value(&"count", 1)
	# a value of another model, which rings a bell of its own
	var elsewhere := Fixture.Model.new(made.chimes, &"elsewhere")
	elsewhere.set_value(&"other", 0)
	var worked := [0]
	# the list: worked out from the count, and counted each time it is
	var list := ui.kept(func() -> Array:
		worked[0] += 1
		return range(model.of(&"count").read()))
	var pieces: Array = []
	# each reader: a line of words saying how long the list is
	for at: int in READERS:
		pieces.append(ui.text(list.map(func(all: Array) -> String: return "%d" % all.size())).named(StringName("reads_%d" % at)))
	ui.start(ui.app(&"app", [ui.screen(&"first", [ui.column(pieces)], model)]))
	await _a_frame_passes()
	var first: int = worked[0]
	_verdict.check(first <= BUILT, "read by %d pieces as they first draw, it is worked out as the screen is built, not once a piece: %d times" % [READERS, first])
	elsewhere.set_value(&"other", 1)
	await _a_frame_passes()
	_verdict.check(worked[0] == first, "something it did not read moves: it is not worked out again: %d times" % worked[0])
	model.set_value(&"count", 4)
	await _a_frame_passes()
	var said: Array = range(READERS).map(func(at: int) -> String: return (ui.node_named(StringName("reads_%d" % at)) as Text).get_text())
	_verdict.check(worked[0] == first + 1 and said.all(func(words: String) -> bool: return words == "4"),
		"what it read moves: worked out once more, and every piece reading it is drawn again with the new list: %d times, %s" % [worked[0], said.slice(0, 3)])
	model.free()
	elsewhere.free()
	made.done()
