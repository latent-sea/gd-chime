extends SceneTree

## What must be true of a status wall of five hundred tiles: one item
## changing draws that tile's mark again and no other, places nothing -
## neither the wall nor any tile moves - and the focus on a tile survives
## every change, its own included; the legend's counts changing never
## change the room it needs.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_wall.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const KeyedItems := preload("res://addons/gd_chime/keyed_items.gd")
const Status := preload("res://addons/gd_chime/components/recipes/status.gd")
const Wall := preload("res://addons/gd_chime/components/recipes/wall.gd")
const Verdict := preload("res://tests/verdict.gd")

const COUNT := 500
const INSPECTS := &"inspects_a_unit"
const STATES := {"up": Status.WELL, "slow": Status.NOTICE, "down": Status.FAULT}

var _verdict := Verdict.new()


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	root.size = Vector2i(1280, 800)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await _verdict.states(_one_item_changing_draws_one_mark_and_places_nothing)
	quit(_verdict.deliver(get_script()))


## Every canvas under this node, in tree order.
static func _canvases(node: Node, into: Array) -> Array:
	# every child, kept if a canvas, searched within either way
	for child: Node in node.get_children():
		if child.get_script() != null and child.get_script().resource_path.ends_with("canvas.gd"):
			into.append(child)
		_canvases(child, into)
	return into


func _one_item_changing_draws_one_mark_and_places_nothing() -> void:
	var made := Fixture.new(root, {INSPECTS: "inspect"})
	var items := KeyedItems.new(made.chimes, range(COUNT).map(func(at: int) -> Dictionary: return {"id": at, "state": "up"}), &"id", [&"state"])
	root.add_child(items)
	var ui := made.ui
	var tile := func(key: int) -> RefCounted: return Wall.tile(ui, INSPECTS, {"unit": key}, items.item(key).field("state").map(func(state: Variant) -> Variant: return null if state == null else STATES[state]), {name = "U-%03d" % key}).named(StringName("tile %d" % key))
	var counted := func(state: String) -> Callable: return func(many: int) -> Phrase: return Phrase.with("%d " + state, [many])
	var legend := Wall.legend(ui, items, &"state", ["up", "slow", "down"].map(func(state: String) -> Dictionary: return {"value": state, "state": STATES[state], "counted": counted.call(state)})).named(&"legend")
	made.answer([INSPECTS])
	ui.start(ui.app(&"app", [ui.screen(&"units", [ui.column([legend, Wall.make(ui, items, tile).grow()])])]))
	# frames for the tiles to be placed and the legend's first count
	for frame: int in 4:
		await process_frame
	var wall: Control = ui.node_named(&"tile 0").get_parent()
	var marks: Array = _canvases(wall, [])
	var drawn: Array = marks.map(func(mark: Control) -> int: return mark.refresh_count)
	var placed: int = wall.arrange_count
	var rects: Array = items.get_keys().map(func(key: int) -> Rect2: return (ui.node_named(StringName("tile %d" % key)) as Control).get_global_rect())
	var legend_needs: Vector2 = (ui.node_named(&"legend") as Control).get_combined_minimum_size()
	(ui.node_named(&"tile 10") as Control).grab_focus()
	items.set_field(10, &"state", "down")
	await process_frame
	await process_frame
	var again: Array = range(marks.size()).filter(func(at: int) -> bool: return marks[at].refresh_count != drawn[at])
	_verdict.check(marks.size() == COUNT and again == [10], "one item changing draws its tile's mark again and no other: %s of %d" % [again, marks.size()])
	var moved: Array = items.get_keys().filter(func(key: int) -> bool: return (ui.node_named(StringName("tile %d" % key)) as Control).get_global_rect() != rects[key])
	_verdict.check(wall.arrange_count == placed and moved.is_empty(), "nothing is placed again and no tile moves: placed %d times since, %d moved" % [wall.arrange_count - placed, moved.size()])
	# ninety-nine more change, over several frames, some of them twice
	for turn: int in 99:
		items.set_field((turn * 37) % COUNT, &"state", ["slow", "down", "up"][turn % 3])
		if turn % 20 == 0:
			await process_frame
	# past the look's cadence, so the tallies are told, and the frames for the legend to draw them
	await create_timer(0.5).timeout
	await process_frame
	await process_frame
	_verdict.check(root.gui_get_focus_owner() == ui.node_named(&"tile 10"), "the focus on a tile survives every change, its own included: %s" % root.gui_get_focus_owner())
	var said: Array = []
	_words(ui.node_named(&"legend"), said)
	var downs: int = items.tallied(&"state").read().get("down", 0)
	_verdict.check(downs >= 10 and said.has("%d down" % downs) and (ui.node_named(&"legend") as Control).get_combined_minimum_size() == legend_needs and wall.arrange_count == placed, "the legend's counts changing - to %s - change none of the room it needs, and the wall is still not placed again" % [said])
	made.done()


## Every label's words under this node.
static func _words(node: Node, into: Array) -> void:
	# every child, its words taken and searched within
	for child: Node in node.get_children():
		if child is Label:
			into.append((child as Label).text)
		_words(child, into)
