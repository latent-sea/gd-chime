extends "controller.gd"

const Notifications := preload("notifications.gd")

## Thresholds: numbers watched against a limit each, and a notification
## (notifications.gd) as one crosses above its limit - an alert, standing in
## the shell's tray, offering the press that goes to what crossed.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A RULE is {reads, over, says, offer, payload}: a bound value reading a
## number - a figure of a dashboard's measures (measures.gd), a count a live
## model keeps - the limit it may not pass, a function of the number to the
## words of the alert, and the offer and its payload. This follows what
## every rule read (reads.gd) and reads every rule again as any moves - a
## read each, no pass of any rows - and notifies ONCE as a number rises past its limit: it stays
## quiet while the number stays over, and is ready again once the number
## has fallen back to its limit or under. A number not there yet - null,
## before a figure lands - is under every limit.
##
## It says nothing of its own: an alert's words and offer are the rule's,
## and how long one stands and how it is dismissed are the notifications'.
##
## Deliberately absent: a limit under, a limit that moves, and a quiet time
## between two alerts of one rule - each a field of a rule, added when one is wanted.

var _notifications: Notifications
var _rules: Array  # each {reads, over, says, offer, payload}
var _over: Array[bool] = []  # whether each rule's number is over its limit now
var _begun: bool = false  # whether the rules have been read once: the first read only follows them


func _init(chimes: Chimes, notifications: Notifications, rules: Array) -> void:
	super(chimes, [], Chimes.GLOBAL)
	_notifications = notifications
	_rules = rules
	# every rule, its number not over until read
	for rule: Dictionary in rules:
		_over.append(false)
	follow(&"rules", _rules_moved)
	_begun = true


## Whether each rule's number is over its limit now, in the order given.
func get_over() -> Array[bool]:
	return _over


## Every rule read, so what they read is followed; a number moved, an alert
## for each that has just risen past its limit.
func _rules_moved() -> void:
	# every rule, its number against its limit
	for at: int in _rules.size():
		var rule: Dictionary = _rules[at]
		var number: Variant = (rule["reads"] as Bound).read()
		if not _begun:
			continue
		var over: bool = number != null and number > rule["over"]
		if over and not _over[at]:
			_notifications.notify(rule["says"].call(number), rule["offer"], rule["payload"])
		_over[at] = over
