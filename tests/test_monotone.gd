extends SceneTree

## What must be true of every primitive's least, the premise that makes a
## few rooms stand for every room: a piece needs across, given rooms 400,
## 800 and 2000 wide, the same or less as the room widens - never more -
## and in none of them are words that wrap set narrower than their widest
## word or in more lines than they have words.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_monotone.gd
##
## Each primitive is built once, holding words that wrap where it can hold
## anything, into a host 600 tall whose width is set to each room in turn,
## in the floor's look; nothing moves. A primitive's least growing with its
## room is a fault in that primitive, whatever screen it was found on.

const Fixture := preload("res://tests/fixture.gd")
const Verdict := preload("res://tests/verdict.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const OutsideSafe := preload("res://addons/gd_chime/outside_safe.gd")

## The rooms each piece is given, narrowest first.
const ROOMS: Array[float] = [400.0, 800.0, 2000.0]
## Words that wrap, one of them far wider than the rest.
const SAID := "a crate of the sweetest pears and one unbelievably long word"
## A grid's two columns, half the width each.
const HALVES: Array[float] = [0.5, 0.5]

var _verdict := Verdict.new()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(2400, 800)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_no_primitive_needs_more_across_as_its_room_widens_and_none_breaks_a_word)
	quit(_verdict.deliver(get_script()))


func _a_frame_passes() -> void:
	await process_frame
	await process_frame


## Words that wrap, as many primitives hold.
func _words(ui: RefCounted) -> Desc:
	return ui.text(SAID, Themes.WORDS).wraps()


## Every primitive that holds or is words, by name, each holding words that wrap where it holds anything.
func _primitives(ui: RefCounted) -> Dictionary:
	var model := Fixture.Model.new(ui.chimes)
	model.set_value(&"flag", true)
	model.set_value(&"items", ["one", "two", "three"])
	ui.also(model)
	return {
		"words": ui.text(SAID, Themes.WORDS),
		"words that wrap": _words(ui),
		"words fitted on one line": ui.text("the name of a stall", Themes.WORDS).fits_by_size(Themes.REASON),
		"words fitted in two lines": ui.text(SAID, Themes.WORDS).fits_by_size(Themes.REASON, 2),
		"a row": ui.row([ui.text("label"), _words(ui), ui.text("figure")]),
		"a row that grows its words": ui.row([ui.text("label"), _words(ui).grow()]),
		"a column": ui.column([_words(ui), ui.text("under it")]),
		"tiles": ui.row([ui.text("one"), _words(ui), ui.text("three")], Themes.TILES),
		"a grid": ui.grid([_words(ui), ui.text("two"), ui.text("three")], HALVES),
		"a stack": ui.stack([_words(ui), ui.text("over it")]),
		"a surface": ui.surface(Themes.SURFACE, [_words(ui)]),
		"a when": ui.when(model.of(&"flag"), _words(ui)),
		"an each": ui.each(model.of(&"items"), func(item: Variant) -> Desc: return ui.text(item.map(func(said: Variant) -> String: return "%s %s" % [said, SAID]), Themes.WORDS).wraps()),
		"a page": ui.page_scroll(ui.column([_words(ui)])),
		"a scroll across": ui.scroll(ui.row([_words(ui), ui.text("beside")]), null, &"across"),
		"by the room": ui.by_room({&"one": ui.text("the label of it", Themes.WORDS), &"two": _words(ui)}, [ui.row_of([&"one", &"two"]), ui.column_of([&"one", &"two"])]),
		"a row that stacks": ui.row([ui.text("label", Themes.WORDS), _words(ui).grow()]).stacks(),
		"by the width": Desc.new(&"by_width", {"names": [&"one", &"two"], "arrangements": {&"across": ui.row_of([&"one", &"two"]), &"stacked": ui.column_of([&"one", &"two"])}, "breakpoints": {&"stacked": 0.0, &"across": 0.5}}, [ui.text("the label of it", Themes.WORDS), _words(ui)]),
		"areas": ui.areas({&"one": ui.text("the label of it", Themes.WORDS), &"two": _words(ui)}, {&"wide": {"least": 0.5, "columns": [0.5, 0.5], "rows": [0.0], "areas": ["one two"]}, &"narrow": {"least": 0.0, "columns": [1.0], "rows": [0.0, 0.0], "areas": ["one", "two"]}}),
	}


func _no_primitive_needs_more_across_as_its_room_widens_and_none_breaks_a_word() -> void:
	var made := Fixture.new(root)
	var primitives := _primitives(made.ui)
	var leasts: Dictionary = {}
	var squeezed: Array[String] = []
	var hosts: Dictionary = {}
	# every primitive, built into a host of its own
	for named: String in primitives:
		var host := Control.new()
		host.size = Vector2(ROOMS[0], 600.0)
		root.add_child(host)
		made.ui.build(primitives[named], host)
		hosts[named] = host
		leasts[named] = []
	# every room, narrowest first: each host given it, and each primitive's least read and its words judged
	for room: float in ROOMS:
		for named: String in hosts:
			hosts[named].size.x = room
		await _a_frame_passes()
		await _a_frame_passes()
		# every primitive in this room
		for named: String in hosts:
			leasts[named].append(hosts[named].get_child(0).get_combined_minimum_size().x)
			squeezed.append_array(OutsideSafe.squeezed(hosts[named]).map(func(sentence: String) -> String: return "%s in %d: %s" % [named, room, sentence]))
	var grew: Array = leasts.keys().filter(func(named: String) -> bool: return leasts[named][1] > leasts[named][0] + 0.5 or leasts[named][2] > leasts[named][1] + 0.5)
	_verdict.check(grew.is_empty() and leasts.size() == primitives.size(), "no primitive needs more across as its room widens from 400 to 800 to 2000: %s" % [grew.map(func(named: String) -> String: return "%s %s" % [named, leasts[named]])])
	_verdict.check(squeezed.is_empty(), "and in no room are words that wrap set narrower than their widest word, or in more lines than they have words: %s" % [squeezed])
	# every host, gone with what it holds
	for named: String in hosts:
		hosts[named].free()
	made.done()
