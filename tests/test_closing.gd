extends SceneTree

## What must be true of closing a place.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_closing.gd
##
## Closed, a place's bells, its listeners' connections and its handlers are
## gone from both the chimes and the commands. Every place beneath it, at any
## depth, goes with it, and a place above or beside it stays. A place holding
## no place drops only itself. The subtree leaves the tree at once - the
## closed place is no place to the driver - and is freed at the end of the
## frame. And a place built again under a closed name hangs its bell,
## registers its handler and is found, without a word.
##
## The tree is real: an app holding a home, a ledger with a details place
## behind a panel, and settings, in the tree with the driver.
## A refusal is heard through a logger that counts only what is pushed as an
## error.

const Belfry := preload("res://addons/gd_chime/belfry.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Commands := preload("res://addons/gd_chime/commands.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Place := preload("res://addons/gd_chime/place.gd")
const Closing := preload("res://addons/gd_chime/closing.gd")
const Verdict := preload("res://tests/verdict.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")

const PLACES: Array[StringName] = [&"app", &"home", &"ledger", &"details", &"settings"]

var _verdict := Verdict.new()
var _hearing := Hearing.new()


## Counts what is pushed as an error, which is how the chimes, the commands
## and the driver say no.
class Hearing extends Logger:
	var refusals: int = 0

	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_ERROR:
			refusals += 1


## A listener belonging to a region, as a place's parts do.
class Ear extends RefCounted:
	var region: StringName

	func _init(home: StringName) -> void:
		region = home

	func heard(_what: StringName) -> void:
		pass


## Stands in for a model built with a place.
class Model extends RefCounted:
	func told(_action: StringName, _payload: Dictionary) -> Phrase:
		return null


func _init() -> void:
	OS.add_logger(_hearing)
	# the tree starts on the first frame, and until it has nothing is in it
	await process_frame
	await _verdict.states(_closed_a_place_s_bells_listeners_and_handlers_are_gone_from_both_places)
	await _verdict.states(_every_place_beneath_it_goes_with_it_and_one_above_or_beside_stays)
	await _verdict.states(_a_place_holding_no_place_drops_only_itself)
	await _verdict.states(_the_subtree_leaves_the_tree_at_once_and_is_freed_at_frame_end)
	await _verdict.states(_built_again_under_a_closed_name_a_place_is_taken_without_a_word)
	OS.remove_logger(_hearing)
	quit(_verdict.deliver(get_script()))


## The tree, and for every place in it a bell hung, a listener belonging to
## it on that bell, and a handler registered in it, as {belfry, chimes,
## commands, driver, places, ears}.
func _opened() -> Dictionary:
	var belfry := Belfry.new()
	var chimes := Chimes.new(belfry)
	var driver := Driver.new(chimes)
	var commands := Commands.new(chimes, driver)
	root.add_child(commands)
	root.add_child(driver)
	var places: Dictionary = {}
	for named: StringName in PLACES:
		places[named] = Place.new(chimes, named, driver)
	places[&"app"].add_child(places[&"home"])
	places[&"app"].add_child(places[&"ledger"])
	var panel := Control.new()
	places[&"ledger"].add_child(panel)
	panel.add_child(places[&"details"])
	places[&"app"].add_child(places[&"settings"])
	driver.index.app = places[&"app"]
	root.add_child(places[&"app"])
	var ears: Array = []
	# every place: its bell hung, a listener of its own connected, a handler registered
	for named: StringName in PLACES:
		_furnish(chimes, commands, named, ears)
	return {"belfry": belfry, "chimes": chimes, "commands": commands, "driver": driver, "places": places, "ears": ears}


## A place's bell hung, a listener of its own on it, and a handler registered in it.
func _furnish(chimes: Chimes, commands: Commands, named: StringName, ears: Array) -> void:
	chimes.register(named, &"shown")
	var ear := Ear.new(named)
	chimes.listen(ear, named, &"shown")
	ears.append(ear)
	commands.register(named, &"scroll_page_down", Model.new())


## Whether everything of this place is still there: its bell, a listener on it, its handler.
func _open(made: Dictionary, named: StringName) -> bool:
	var chimes: Chimes = made["chimes"]
	return (made["belfry"] as Belfry).has(named, &"shown") \
		and chimes.listeners_of(named, &"shown").size() == 1 \
		and (made["commands"] as Commands).handles(named, &"scroll_page_down")


## Whether nothing of this place is left: no bell, no listener, no handler.
func _closed(made: Dictionary, named: StringName) -> bool:
	var chimes: Chimes = made["chimes"]
	return not (made["belfry"] as Belfry).has(named, &"shown") \
		and chimes.listeners_of(named, &"shown").is_empty() \
		and not (made["commands"] as Commands).handles(named, &"scroll_page_down")


func _done(made: Dictionary) -> void:
	(made["places"][&"app"] as Node).free()
	(made["driver"] as Node).free()
	(made["commands"] as Node).free()


func _close(made: Dictionary, named: StringName) -> void:
	Closing.close(made["chimes"], made["commands"], (made["driver"] as Driver).index, made["places"][named])


func _closed_a_place_s_bells_listeners_and_handlers_are_gone_from_both_places() -> void:
	var made := _opened()
	_verdict.check(_open(made, &"settings"), "open, the settings place has its bell, its listener and its handler")

	_close(made, &"settings")
	_verdict.check(_closed(made, &"settings"), "closed, none of them is left")
	_done(made)


func _every_place_beneath_it_goes_with_it_and_one_above_or_beside_stays() -> void:
	var made := _opened()

	_close(made, &"ledger")
	_verdict.check(_closed(made, &"ledger") and _closed(made, &"details"), "the ledger and the details place behind its panel are both gone")
	_verdict.check(_open(made, &"app") and _open(made, &"home") and _open(made, &"settings"), "the place above and the ones beside are untouched")
	_done(made)


func _a_place_holding_no_place_drops_only_itself() -> void:
	var made := _opened()

	_close(made, &"details")
	_verdict.check(_closed(made, &"details"), "the details place is gone")
	_verdict.check(_open(made, &"ledger") and _open(made, &"app") and _open(made, &"home") and _open(made, &"settings"), "and every other place stands")
	_done(made)


func _the_subtree_leaves_the_tree_at_once_and_is_freed_at_frame_end() -> void:
	var made := _opened()
	var driver: Driver = made["driver"]
	var ledger: Node = made["places"][&"ledger"]
	var details: Node = made["places"][&"details"]
	var before := _hearing.refusals

	_close(made, &"ledger")
	_verdict.check(not ledger.is_inside_tree() and not details.is_inside_tree(), "closed, the ledger and the details are out of the tree at once")
	_verdict.check(driver.index.place_named(&"ledger") == null and _hearing.refusals == before + 1, "and the ledger is no place to the driver")
	_verdict.check(is_instance_valid(ledger), "but not freed yet, being closed from inside whatever asked")
	await process_frame
	_verdict.check(not is_instance_valid(ledger) and not is_instance_valid(details), "at the end of the frame, both are freed")
	_done(made)


## A ledger built again under the closed name - its details inside it, with
## the same region names - hangs its bells, registers its handlers and is
## found, without a word, since closing dropped every region beneath.
func _built_again_under_a_closed_name_a_place_is_taken_without_a_word() -> void:
	var made := _opened()
	var chimes: Chimes = made["chimes"]
	var driver: Driver = made["driver"]
	_close(made, &"ledger")
	await process_frame
	var before := _hearing.refusals

	var ledger := Place.new(chimes, &"ledger", driver)
	var details := Place.new(chimes, &"details", driver)
	ledger.add_child(details)
	(made["places"][&"app"] as Node).add_child(ledger)
	_furnish(chimes, made["commands"], &"ledger", made["ears"])
	_furnish(chimes, made["commands"], &"details", made["ears"])
	_verdict.check(_hearing.refusals == before, "built again, the ledger and the details inside it hang their bells and register their handlers without a word")
	_verdict.check(driver.index.place_named(&"ledger") == ledger and driver.index.place_named(&"details") == details, "and are found afresh")
	_done(made)
