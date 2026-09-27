extends SceneTree

## A place (place.gd) as the passive node it is: built hidden, indexed by
## name as it enters the tree and taken out as it leaves, its child places
## found through any container, told to fill and empty by the driver and
## never working anything out for itself, holding the token of a stay; the
## index holding places alone, by name; and a place taking the room its
## content needs, pushing on what lies below it rather than hanging over it.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_place.gd
##
## The order places are filled and emptied in is the driver's, proved on the
## chart (test_chart.gd) and on the tree (test_driver.gd); nothing here
## arrives anywhere.

const Belfry := preload("res://addons/gd_chime/belfry.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Commands := preload("res://addons/gd_chime/commands.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Place := preload("res://addons/gd_chime/place.gd")
const Verdict := preload("res://tests/verdict.gd")
const Actions := preload("res://addons/gd_chime/actions.gd")
const Prompts := preload("res://addons/gd_chime/prompts.gd")
const Fixture := preload("res://tests/fixture.gd")
const Desc := preload("res://addons/gd_chime/components/primitives/desc.gd")
const Clipped := preload("res://addons/gd_chime/clipped_text.gd")

var _verdict := Verdict.new()


## A piece needing a fixed least size, built as any primitive is: content of a known height.
class Block extends Control:
	static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
		var made := Block.new()
		made.custom_minimum_size = desc.props["least"]
		ui.attach(made, parent, desc.facts)
		return made


## A place that says whether it has been told anything.
class Told extends "res://addons/gd_chime/place.gd":
	var filled: int = 0
	var emptied: int = 0

	func fill() -> void:
		filled += 1

	func empty() -> void:
		emptied += 1


func _init() -> void:
	# the tree starts on the first frame, and until it has nothing is in it
	await process_frame
	await _verdict.states(_built_it_is_hidden_and_holds_no_token_and_is_told_nothing_until_the_driver_says)
	await _verdict.states(_it_is_indexed_as_it_enters_the_tree_and_taken_out_as_it_leaves)
	await _verdict.states(_its_child_places_are_the_nearest_beneath_through_any_container_in_tree_order)
	await _verdict.states(_the_index_holds_places_alone_by_name_and_the_place_above_a_node)
	await _verdict.states(_a_place_takes_the_room_its_content_needs_and_pushes_what_lies_below_it_on)
	quit(_verdict.deliver(get_script()))


## The commands and the driver in the tree, as {chimes, driver, commands}.
func _made() -> Dictionary:
	var chimes := Chimes.new(Belfry.new())
	var driver := Driver.new(chimes)
	var commands := Commands.new(chimes, driver)
	root.add_child(commands)
	root.add_child(driver)
	return {"chimes": chimes, "driver": driver, "commands": commands}


func _done(made: Dictionary) -> void:
	(made["driver"] as Node).free()
	(made["commands"] as Node).free()


func _built_it_is_hidden_and_holds_no_token_and_is_told_nothing_until_the_driver_says() -> void:
	var made := _made()
	var place := Told.new(made["chimes"], &"home", made["driver"])
	_verdict.check(not place.visible and place.token == null, "built, a place is hidden and holds no token")
	root.add_child(place)
	await process_frame
	_verdict.check(not place.visible and place.filled == 0 and place.emptied == 0 and place.listening_to().is_empty(), "in the tree and a frame on, still hidden, told nothing, listening to nothing")
	_verdict.check(place.blocks, "and a root, it would block what is beneath it unless told otherwise")
	place.free()
	_done(made)


func _it_is_indexed_as_it_enters_the_tree_and_taken_out_as_it_leaves() -> void:
	var made := _made()
	var driver: Driver = made["driver"]
	var place := Place.new(made["chimes"], &"ledger", driver)
	root.add_child(place)
	_verdict.check(driver.index.place_named(&"ledger") == place, "entered, it is found by its name")
	root.remove_child(place)
	var hearing := Hearing.new()
	OS.add_logger(hearing)
	_verdict.check(driver.index.place_named(&"ledger") == null and hearing.refusals == 1, "left, it is no place, out loud")
	OS.remove_logger(hearing)
	place.free()
	_done(made)


func _its_child_places_are_the_nearest_beneath_through_any_container_in_tree_order() -> void:
	var made := _made()
	var chimes: Chimes = made["chimes"]
	var driver: Driver = made["driver"]
	var ledger := Place.new(chimes, &"ledger", driver)
	var row := Control.new()
	ledger.add_child(row)
	var coins := Place.new(chimes, &"coins", driver)
	row.add_child(coins)
	var detail := Place.new(chimes, &"detail", driver)
	coins.add_child(detail)
	var notes := Place.new(chimes, &"notes", driver)
	ledger.add_child(notes)
	root.add_child(ledger)
	_verdict.check(ledger.places() == [coins, notes], "the ledger's places are the coins, through the row, and the notes, in tree order, not the detail inside the coins: %s" % [ledger.places()])
	_verdict.check(coins.places() == [detail] and notes.places().is_empty(), "the coins hold the detail, the notes nothing")
	ledger.free()
	_done(made)


func _the_index_holds_places_alone_by_name_and_the_place_above_a_node() -> void:
	var made := _made()
	var driver: Driver = made["driver"]
	var told := Told.new(made["chimes"], &"home", driver)
	var button := Button.new()
	told.add_child(button)
	root.add_child(told)
	_verdict.check(driver.index.is_place(told) and not driver.index.is_place(button) and driver.index.place_named(&"home") == told, "a place is a place to the index, found by name; a plain button is no place")
	_verdict.check(driver.index.place_above(button) == told and driver.index.place_above(told) == null, "the place above a button is the one it sits in, and a root has none")
	told.free()
	_done(made)


## A screen whose content needs 700 tall, above a bar 100 tall with words in
## it, in a window 400 tall: the screen takes the room its content needs -
## its content ends where the bar begins, never drawn over it - and the bar
## is pushed on past the window, where the words cut off there are reported.
func _a_place_takes_the_room_its_content_needs_and_pushes_what_lies_below_it_on() -> void:
	root.size = Vector2i(400, 400)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var made := Fixture.new(root, {})
	var ui := made.ui
	ui.register(&"block", Block)
	var tall := ui.screen(&"tall", [Desc.new(&"block", {"least": Vector2(40.0, 700.0)}).named(&"content")])
	var bar := ui.column([Desc.new(&"block", {"least": Vector2(40.0, 100.0)}), ui.text("the tray")]).named(&"bar")
	ui.build(ui.app(&"app", [ui.column([tall, bar])]), root)
	made.commands.dispatch(Chimes.GLOBAL, Driver.GO, {"place": &"app"})
	await process_frame
	await process_frame
	var content: Control = ui.node_named(&"content")
	var below: Control = ui.node_named(&"bar")
	var screen: Control = made.driver.index.place_named(&"tall")
	_verdict.check(screen.size.y >= 700.0 and content.get_global_rect().end.y <= below.get_global_rect().position.y + 0.5, "the screen takes the room its content needs, which ends where the bar begins: content to %s, bar from %s" % [content.get_global_rect().end.y, below.get_global_rect().position.y])
	var cut := Clipped.clipped(root, root.get_visible_rect())
	_verdict.check(below.get_global_rect().position.y >= 400.0 and cut.size() == 1 and cut[0].contains("the tray"), "and the bar is pushed on past the window, its words reported cut off there: %s" % [cut])
	made.done()


## Counts the refusals pushed as errors.
class Hearing extends Logger:
	var refusals: int = 0

	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array) -> void:
		if error_type == ERROR_TYPE_ERROR:
			refusals += 1
