extends SceneTree

## What must be true of thresholds: a number rising past its limit is one
## alert, in the rule's words, offering the rule's press; staying over it
## is no more; falling back and rising again is another; a number not there
## yet is under every limit; and each rule is its own.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_thresholds.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Notifications := preload("res://addons/gd_chime/notifications.gd")
const Thresholds := preload("res://addons/gd_chime/thresholds.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Verdict := preload("res://tests/verdict.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")

const PICKS := &"picks_a_region"

var _verdict := Verdict.new()


## Two numbers a dashboard keeps: customers out in two regions.
class Out extends Fixture.Model:
	func get_wales() -> Variant:
		return of(&"wales").read()

	func get_east() -> Variant:
		return of(&"east").read()


## A tray standing for the notifications to be told to: every words fit it,
## as a tray must answer (tray_stand.gd).
class Tray extends Node:
	func fits(_words: Variant) -> bool:
		return true


func _init() -> void:
	root.theme = Themes.new(Themes.NEUTRAL)
	await process_frame
	await _verdict.states(_a_number_rising_past_its_limit_is_one_alert_and_again_only_after_falling_back)
	quit(_verdict.deliver(get_script()))


func _a_number_rising_past_its_limit_is_one_alert_and_again_only_after_falling_back() -> void:
	var made := Fixture.new(root)
	var notifications := Notifications.new(made.chimes, made.commands, root)
	notifications.by_hand = true
	var tray := Tray.new()
	root.add_child(notifications)
	root.add_child(tray)
	notifications.add_tray(tray)
	var out := Out.new(made.chimes)
	out.set_value(&"wales", null)
	out.set_value(&"east", 10.0)
	root.add_child(out)
	var says := func(number: float) -> Phrase: return Phrase.with("%d customers without service", [int(number)])
	var rules := [{"reads": Bound.new(out.get_wales), "over": 1000.0, "says": says, "offer": PICKS, "payload": {"picked": "Wales"}}, {"reads": Bound.new(out.get_east), "over": 1000.0, "says": says, "offer": PICKS, "payload": {"picked": "East"}}]
	var watching := Thresholds.new(made.chimes, notifications, rules)
	root.add_child(watching)
	out.set_value(&"wales", null)
	await process_frame
	_verdict.check(notifications.get_standing().is_empty() and watching.get_over() == [false, false], "a number not there yet is under its limit: no alert")
	out.set_value(&"wales", 1500.0)
	await process_frame
	var standing: Array = notifications.get_standing()
	_verdict.check(standing.size() == 1 and str(standing[0]["words"]) == "1500 customers without service" and standing[0]["offer"] == PICKS and standing[0]["payload"] == {"picked": "Wales"}, "Wales rising past its limit is one alert, in the rule's words, offering its press: %s" % [standing])
	out.set_value(&"wales", 1800.0)
	await process_frame
	_verdict.check(notifications.get_standing().size() == 1, "staying over, it says nothing more")
	out.set_value(&"wales", 900.0)
	await process_frame
	out.set_value(&"wales", 1200.0)
	await process_frame
	_verdict.check(notifications.get_standing().size() == 2, "fallen back under and risen past again, it is a second alert")
	_verdict.check(watching.get_over() == [true, false], "and each rule is its own: the East, under all along, never alerted")
	for node: Node in [watching, out]:
		node.free()
	notifications.remove_tray(tray)
	made.done()
