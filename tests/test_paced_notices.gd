extends SceneTree

## What must be true of paced notices: one alone stands as it was given; a
## burst arriving within the pace stands as one - the summary of how many,
## with its offer - never one each; nothing more stands until the pace is
## over, and what waited is then handed on, never lost.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --headless --path <this folder> --script res://tests/test_paced_notices.gd

const Fixture := preload("res://tests/fixture.gd")
const Themes := preload("res://addons/gd_chime/theme.gd")
const Motion := preload("res://addons/gd_chime/motion.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")
const Notifications := preload("res://addons/gd_chime/notifications.gd")
const PacedNotices := preload("res://addons/gd_chime/paced_notices.gd")
const Verdict := preload("res://tests/verdict.gd")

const PACE := 3000
const SEES_ALL := &"sees_every_alert"

var _verdict := Verdict.new()
var _now: int = 1000


## A stand-in for a tray standing: every notification's words fit it.
class Tray extends Node:
	func fits(_words: String) -> bool:
		return true


func _init() -> void:
	var look := Themes.new(Themes.NEUTRAL)
	look.set_constant(PacedNotices.PACE, Motion.TYPE, PACE)
	root.theme = look
	await process_frame
	await _verdict.states(_a_burst_stands_as_one_summary_and_nothing_more_until_the_pace_is_over)
	quit(_verdict.deliver(get_script()))


## The words of every notification standing, oldest first.
func _standing(notifications: Notifications) -> Array:
	return notifications.get_standing().map(func(one: Dictionary) -> String: return str(one["words"]))


func _a_burst_stands_as_one_summary_and_nothing_more_until_the_pace_is_over() -> void:
	var made := Fixture.new(root)
	var notifications := Notifications.new(made.chimes, made.commands, root)
	notifications.by_hand = true
	root.add_child(notifications)
	# a stand-in for the tray, so a notification has somewhere to be shown
	var tray := Tray.new()
	root.add_child(tray)
	notifications.add_tray(tray)
	var paced := PacedNotices.new(notifications, func(many: int) -> Phrase: return Phrase.with("%d alerts", [many]), SEES_ALL, {"all": true})
	root.add_child(paced)
	paced._pace.clock = func() -> int: return _now
	paced.notify(Phrase.of("a pump has stopped"), &"opens_it", {"pump": 3})
	await process_frame
	var first: Dictionary = notifications.get_standing()[0]
	_verdict.check(_standing(notifications) == ["a pump has stopped"] and first["offer"] == &"opens_it" and first["payload"] == {"pump": 3}, "one alone stands as it was given, its offer and all: %s" % [_standing(notifications)])
	# a burst of fifty inside the pace
	for at: int in 50:
		paced.notify(Phrase.with("unit %d is down", [at]))
	await process_frame
	await process_frame
	_verdict.check(_standing(notifications).size() == 1, "within the pace, nothing more stands: %s" % [_standing(notifications)])
	_now += PACE
	await process_frame
	await process_frame
	var summary: Dictionary = notifications.get_standing()[-1]
	_verdict.check(_standing(notifications) == ["a pump has stopped", "50 alerts"] and summary["offer"] == SEES_ALL and paced.folded_count == 50, "the pace over, the fifty stand as one summary with its offer: %s" % [_standing(notifications)])
	made.done()
