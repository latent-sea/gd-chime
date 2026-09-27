extends "controller.gd"

const Motion := preload("motion.gd")
const Throttle := preload("throttle.gd")
const QueriedRows := preload("queried_rows.gd")

## The pace a query is asked at while a reader types: a filter's line
## changes on every keystroke, and the view's query (queried_rows.gd) goes
## only once the typing settles.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## ASKED SOON, a query waits on the floor's one pacing mechanism, settling
## (throttle.gd): the look's SETTLES token, in milliseconds, on the one
## clock (motion.gd) - so a test steps the wait by hand as it steps every
## other timed thing - from the last time it was asked, each keystroke
## starting the wait again, so ten letters typed quickly ask one query, of
## the line as it stood at the last. ASKED NOW - Enter, a pick from the
## filter builder, a chip turned or removed - it goes at once, and whatever
## was waiting goes with it, never after it. A query that goes is the view's
## to run: one out at a time, a stale answer let go.
##
## While one waits, get_waiting() says so, beside the view's own busy, so a
## grid shows it is busy from the first keystroke to the landing.
## get_sent() counts the queries that went, for a test to read.
##
## Deliberately absent: a wait that grows with the rows, and a query sent
## at the start of the typing as well as at its end. No wait of its own: the
## settling is the throttle's, so there is one debounce in the framework.

## The look's token: how long typing must rest before its query goes, in milliseconds.
const SETTLES := &"typing_settles"

var _view: QueriedRows
var _settling: Throttle
var _waiting := value(false)  # whether clauses were asked soon and not yet sent
var _clauses: Array = []  # the clauses waiting, while any are
var _sent: int = 0


func _init(chimes: Chimes, view: QueriedRows, motion: Motion) -> void:
	super(chimes)
	_view = view
	_settling = Throttle.new(_settled, {settles_by = SETTLES, on = motion})
	add_child(_settling)


func get_waiting() -> bool:
	return _waiting.read()


func get_sent() -> int:
	return _sent


## These clauses asked once the typing settles: the wait begun again.
func ask_soon(clauses: Array) -> void:
	_clauses = clauses
	_settling.ask()
	if not _waiting.read():
		_waiting.set_value(true)


## These clauses asked at once, and nothing left waiting.
func ask_now(clauses: Array) -> void:
	forget()
	_sent += 1
	_view.ask(clauses)


## Whatever waits let go, never asked: the rows it was typed against are gone.
func forget() -> void:
	_clauses = []
	_settling.forget()
	if _waiting.read():
		_waiting.set_value(false)


## The typing has rested for the look's token: what waited goes.
func _settled() -> void:
	ask_now(_clauses)
