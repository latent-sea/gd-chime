extends "controller.gd"

## What is being carried: the one thing a reader has picked up to drop
## somewhere else, what it carries, and where it would land now.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## ONE THING IS CARRIED AT A TIME, so there is one of these beside the app
## and every draggable and every drop target is handed it, the way a picker
## is handed its narrowing. A draggable lifts the payload it was described
## with, read as the lift lands.
##
## A THING CARRIED IS ITS PAYLOAD: every draggable holding the same payload
## is that thing, wherever it is drawn. So a list that builds the piece
## carrying it again - in another column, as a carry crosses the board -
## finds the new piece carried still, and nothing holds a control.
##
## WHERE IT WOULD LAND is OVER: {into, at} - the list a target stands for and
## the place among what that list shows - or nothing while it is over no
## list. A list target moves it as a pointer crosses it, and the keys and
## the pad step it; a list (lane.gd) reads it to show the thing where it
## would land.
##
## A target PUTS IT DOWN when the drop happened; anything that gives up PUTS
## IT BACK. Both end the carry, and they are told apart because a cancel
## sends the focus home to the draggable and a drop does not. The engine's
## end of a drag reaches this too, so a mouse carry is put back though the
## piece that began it has since been built again elsewhere.
##
## THE TARGETS READ IT, THEY DO NOT POLL IT: every fact here is a value
## (value.gd), so a target or a list that reads one follows this model and
## asks the door again as it moves. One model rings one bell, so what asks
## only whether it is carried is woken as the carry moves over another
## place too - once a place, never a pixel - and a draggable answers that by
## drawing only when whether it is the one carried changed (draggable.gd).
##
## Deliberately absent: where the carry is on the screen, which is the
## pointer's and the engine's; a second carry; and any memory of an earlier
## one beyond the last put back, which the focus goes home to.

var _payload := value({})  # what is carried, none while nothing is
var _carrying := value(false)
var _over := value({})  # {into, at}: where it would land, or none
var _by_keys := value(false)  # whether the keys or the pad lifted it, so its piece keeps the focus
var _put_back := value(false)  # whether the last thing set down was given up rather than dropped
var _returned := value({})  # the payload last put back, for its piece to take the focus home


func _init(chimes: Chimes) -> void:
	super(chimes, [], Chimes.GLOBAL)


## What is being carried, for a target to ask the door about; nothing while
## nothing is.
func get_payload() -> Dictionary:
	return _payload.read()


## Where it would land: {into, at}, or nothing while it is over no list.
func get_over() -> Dictionary:
	return _over.read()


## Whether anything is being carried at all.
func is_carrying() -> bool:
	return _carrying.read()


## Whether this payload is the thing being carried now.
func is_lifted(payload: Dictionary) -> bool:
	return _carrying.read() and _payload.read() == payload


## Whether the keys or the pad lifted what is carried.
func is_by_keys() -> bool:
	return _by_keys.read()


## Whether the last thing set down was given up rather than dropped.
func get_put_back() -> bool:
	return _put_back.read()


## The payload last put back: its piece takes the focus home.
func get_returned() -> Dictionary:
	return _returned.read()


## Picked up: what it carries, where it would land to begin with - where it
## was, for a piece of a list - and whether the keys or the pad lifted it.
func lift(payload: Dictionary, over: Dictionary, by_keys: bool) -> void:
	_payload.set_value(payload)
	_carrying.set_value(true)
	_over.set_value(over)
	_by_keys.set_value(by_keys)
	_put_back.set_value(false)
	_returned.set_value({})


## Moved over another place to land; set only when it is another.
func move_over(into: Variant, at: int) -> void:
	var over: Dictionary = _over.read()
	if over.get("into") != into or over.get("at") != at:
		_over.set_value({"into": into, "at": at})


## Dropped: the carry is over, and whoever took it dispatched.
func put_down() -> void:
	_set_down(false)


## Given up: the carry is over and nothing was dropped.
func put_back() -> void:
	_returned.set_value(_payload.read())
	_set_down(true)


func _set_down(given_up: bool) -> void:
	_payload.set_value({})
	_carrying.set_value(false)
	_over.set_value({})
	_put_back.set_value(given_up)


## The engine ended a drag with the carry still on - a release over nothing,
## or Escape - and the piece that began it may have been built again since.
## The engine tells every script in the chain, so the controller's own runs
## as well.
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and _carrying.read() and not _by_keys.read():
		put_back()
