extends SceneTree

## What must be true of the startup check.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_startup_check.gd
##
## A tree whose places declare every action in the register, each going to
## a place or Back or nowhere, every place named once, reports nothing. An
## action no place declares is reported; a declared name that is no action
## is reported; a declaration to no place is reported, and one Back never
## is; two places of one name are reported; a place named after a reserved
## region is reported; a declaration of the driver's own command is
## reported. The check asks the index, so a pop-up's declarations count.
## And every broken thing is reported, one sentence each.
##
## The tree is real and small: an app holding a home and a ledger with a
## coins tab, a strip in the app; the stand-in buttons write their
## declarations into the place they enter. The check reads the
## declarations alone, never a button.

const Belfry := preload("res://addons/gd_chime/belfry.gd")
const Chimes := preload("res://addons/gd_chime/chimes.gd")
const Actions := preload("res://addons/gd_chime/actions.gd")
const Commands := preload("res://addons/gd_chime/commands.gd")
const Driver := preload("res://addons/gd_chime/driver.gd")
const Place := preload("res://addons/gd_chime/place.gd")
const StartupCheck := preload("res://addons/gd_chime/startup_check.gd")
const Verdict := preload("res://tests/verdict.gd")

var _verdict := Verdict.new()


## A control that performs an action and may take the reader somewhere.
class Link extends "res://tests/stand_in.gd":
	pass


func _init() -> void:
	# the tree starts on the first frame, and until it has nothing is in it
	await process_frame
	await _verdict.states(_a_tree_that_stands_reports_nothing)
	await _verdict.states(_an_action_nobody_performs_is_reported)
	await _verdict.states(_a_declared_name_that_is_no_action_is_reported)
	await _verdict.states(_a_declaration_to_no_place_is_reported_and_one_back_never)
	await _verdict.states(_a_pop_up_s_declarations_count_from_the_window)
	await _verdict.states(_two_places_of_one_name_are_reported)
	await _verdict.states(_every_broken_thing_is_reported)
	await _verdict.states(_a_place_named_after_a_reserved_region_is_reported)
	await _verdict.states(_a_declaration_of_one_of_the_driver_s_own_commands_is_reported)
	quit(_verdict.deliver(get_script()))


## The register of the actions the tree performs, and the tree: an app with
## a strip holding Back and a ledger link, a home with a save, a ledger with
## a coins tab holding a count. As {actions, root, chimes, places}.
func _made() -> Dictionary:
	var chimes := Chimes.new(Belfry.new())
	var driver := Driver.new(chimes)
	var commands := Commands.new(chimes, driver)
	var actions := Actions.new()
	var table: Dictionary = {}
	# every action the tree performs, declared with the words of its name
	for action: StringName in [&"goes_back", &"opens_the_ledger", &"saves_the_day", &"counts_a_coin"]:
		table[action] = [String(action)]
	actions.declare_all(table)
	var places: Dictionary = {}
	for named: StringName in [&"app", &"home", &"ledger", &"coins"]:
		places[named] = Place.new(chimes, named, driver)
	var strip := Control.new()
	places[&"app"].add_child(strip)
	strip.add_child(Link.new(chimes, commands, places[&"app"], &"goes_back", Driver.BACK))
	strip.add_child(Link.new(chimes, commands, places[&"app"], &"opens_the_ledger", &"ledger"))
	places[&"app"].add_child(places[&"home"])
	places[&"home"].add_child(Link.new(chimes, commands, places[&"home"], &"saves_the_day"))
	places[&"app"].add_child(places[&"ledger"])
	places[&"ledger"].add_child(places[&"coins"])
	places[&"coins"].add_child(Link.new(chimes, commands, places[&"coins"], &"counts_a_coin"))
	driver.index.app = places[&"app"]
	var window := Control.new()
	window.add_child(places[&"app"])
	root.add_child(window)
	return {"actions": actions, "root": window, "chimes": chimes, "places": places, "driver": driver, "commands": commands}


func _done(made: Dictionary) -> void:
	(made["root"] as Node).free()
	(made["driver"] as Node).free()
	(made["commands"] as Node).free()


func _broken(made: Dictionary) -> Array[String]:
	return StartupCheck.broken((made["driver"] as Driver).index, made["actions"])


func _a_tree_that_stands_reports_nothing() -> void:
	var made := _made()
	_verdict.check(_broken(made).is_empty(), "a tree that stands reports nothing: %s" % [_broken(made)])
	_done(made)


func _an_action_nobody_performs_is_reported() -> void:
	var made := _made()
	(made["actions"] as Actions).declare_all({&"flies": ["fly"]})

	_verdict.check(_broken(made) == ["nobody performs flies"], "an action in the register nobody performs is reported: %s" % [_broken(made)])
	_done(made)


func _a_declared_name_that_is_no_action_is_reported() -> void:
	var made := _made()
	(made["places"][&"home"] as Place).performs[&"jumps"] = &""

	_verdict.check(_broken(made) == ["home declares jumps, which is no action"], "a declared name that is no action is reported: %s" % [_broken(made)])
	_done(made)


func _a_declaration_to_no_place_is_reported_and_one_back_never() -> void:
	var made := _made()
	(made["places"][&"home"] as Place).performs[&"saves_the_day"] = &"nowhere"

	_verdict.check(_broken(made) == ["home sends saves_the_day to nowhere, which is no place"], "a declaration to no place is reported, and the strip's Back is not: %s" % [_broken(made)])
	_done(made)


## A zoom beside the app declares the closing; the index holds it with the
## app, so it counts.
func _a_pop_up_s_declarations_count_from_the_window() -> void:
	var made := _made()
	(made["actions"] as Actions).declare_all({&"closes_the_zoom": ["close the zoom"]})
	var zoom := Place.new(made["chimes"], &"zoom", made["driver"])
	zoom.add_child(Link.new(made["chimes"], made["commands"], zoom, &"closes_the_zoom", Driver.BACK))
	(made["root"] as Node).add_child(zoom)

	_verdict.check(_broken(made).is_empty(), "the zoom declares the closing, the index holding the pop-up with the app: %s" % [_broken(made)])
	_done(made)


func _two_places_of_one_name_are_reported() -> void:
	var made := _made()
	var twin := Place.new(made["chimes"], &"home", made["driver"])
	(made["places"][&"ledger"] as Node).add_child(twin)

	_verdict.check(_broken(made) == ["two places are named home"], "two places of one name are reported: %s" % [_broken(made)])
	_done(made)


func _every_broken_thing_is_reported() -> void:
	var made := _made()
	(made["actions"] as Actions).declare_all({&"flies": ["fly"]})
	(made["places"][&"home"] as Place).performs[&"jumps"] = &"nowhere"

	_verdict.check(_broken(made) == ["home declares jumps, which is no action", "home sends jumps to nowhere, which is no place", "nobody performs flies"], "each broken thing, one sentence: %s" % [_broken(made)])
	_done(made)


func _a_place_named_after_a_reserved_region_is_reported() -> void:
	var made := _made()
	var wrong := Place.new(made["chimes"], Chimes.GLOBAL, made["driver"])
	(made["places"][&"home"] as Node).add_child(wrong)
	_verdict.check(_broken(made) == ["global is a reserved region, and no place may be named after it"], "a place named global is reported: %s" % [_broken(made)])
	_done(made)


func _a_declaration_of_one_of_the_driver_s_own_commands_is_reported() -> void:
	var made := _made()
	(made["actions"] as Actions).declare_all({Driver.GOES_BACK: ["go back, by the driver"]})
	(made["places"][&"home"] as Place).performs[Driver.GOES_BACK] = Driver.BACK
	_verdict.check(_broken(made) == ["home declares go_back, the driver's own; a button navigates by where its action goes"], "a place declaring the driver's own Back is reported: %s" % [_broken(made)])
	_done(made)
