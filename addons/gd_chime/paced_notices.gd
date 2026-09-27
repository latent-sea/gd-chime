extends Node

const Throttle := preload("throttle.gd")
const Notifications := preload("notifications.gd")
const Phrase := preload("phrase.gd")

## Notifications at a pace a reader can take: at most one stands a pace,
## and what arrives together is gathered into one - how many, and one offer
## to see them all - so a hundred alerts in a second never bury what the
## reader was doing.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## IT STANDS BETWEEN WHAT NOTIFIES AND THE NOTIFICATIONS (notifications.gd),
## which it hands at most one notification a PACE - a Motion token in
## milliseconds read from the window's look - by a throttle paced by it
## (throttle.gd). A notification alone in its pace is handed on as it was
## given, its words and its offer; two or more gathered in one pace are
## handed on as the summary: the words the application gives for how many
## there were, and its offer - the list they all went to - so nothing is
## lost, only folded. The notifications then stand, stay and leave as any
## do, and the tray draws them.
##
## A child of whatever makes it, as a throttle is; it holds what is waiting
## and nothing else.
##
## Deliberately absent: telling one kind of notification from another -
## an alert that must stand alone is handed to the notifications straight.

## How long, in milliseconds, before another notification may stand: a Motion token, read from the window's look.
const PACE := &"notice_pace"

## How many notifications were folded into summaries, for a reader measuring.
var folded_count: int = 0

var _notifications: Notifications
var _summary: Callable  # how many were gathered -> the words saying so
var _offer: StringName  # the summary's offer, or none
var _payload: Dictionary  # what the summary's offer carries
var _waiting: Array = []  # the notifications gathered in this pace, each [words, offer, payload]
var _pace: Throttle


func _init(notifications: Notifications, summary: Callable, offer: StringName = &"", payload: Dictionary = {}) -> void:
	_notifications = notifications
	_summary = summary
	_offer = offer
	_payload = payload
	_pace = Throttle.new(_hand_on, {paced_by = PACE})
	add_child(_pace)


## One more to notify: standing at once if the pace allows, else gathered.
func notify(words: Phrase, offer: StringName = &"", payload: Dictionary = {}) -> void:
	_waiting.append([words, offer, payload])
	_pace.ask()


## What was gathered in the pace, handed on: alone as it was, or many as the summary.
func _hand_on() -> void:
	var gathered := _waiting
	_waiting = []
	if gathered.size() == 1:
		_notifications.notify(gathered[0][0], gathered[0][1], gathered[0][2])
		return
	folded_count += gathered.size()
	_notifications.notify(_summary.call(gathered.size()), _offer, _payload)
