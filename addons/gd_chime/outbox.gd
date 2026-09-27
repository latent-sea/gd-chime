extends "controller.gd"

const Connection := preload("connection.gd")

## An outbox: a far side that holds what is sent while the connection is
## down, and sends it, oldest first, the moment it is back - so a change made
## offline is made at once and kept, waiting, as provisional.gd keeps any
## change the far side has not yet said yes to.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## IT STANDS WHERE THE FAR SIDE DOES: send(request, answer) is the shape
## provisional.gd is handed, and it hands on to the real far side, sends -
## at once while online, and otherwise held. So a model's changes need
## nothing new to work offline: each is shown at once, pending, and its
## answer - a yes, or a refusal that rolls it back with its reason - comes
## when the far side has seen it, however long that is. A screen says a
## thing is AWAITING SYNC while it is pending and the connection is down.
##
## The connection (connection.gd) coming back sends everything held, in the
## order it was made, and nothing is held twice. get_held() counts what
## waits, a value's reading (value.gd), so what shows it follows it.
##
## Deliberately absent: sending again a request lost in flight - the far
## side's to answer, with a failure if it must - and merging two changes to
## one thing held together.

var _connection: Connection
var _sends: Callable  # the real far side: sends(request, answer)
var _held := value([])  # [request, answer] held while offline, oldest first


func _init(chimes: Chimes, connection: Connection, sends: Callable) -> void:
	super(chimes)
	_connection = connection
	_sends = sends
	follow(&"connection", _connection_moved)


## How many sends wait for the connection.
func get_held() -> int:
	return _held.read().size()


## Sent on at once while online; held, oldest first, while not.
func send(request: Dictionary, answer: Callable) -> void:
	if _connection.get_online():
		_sends.call(request, answer)
		return
	_held.set_value(_held.read() + [[request, answer]])


## The connection read, so it is followed; back online, everything held is
## sent, oldest first.
func _connection_moved() -> void:
	if not _connection.get_online() or _held.read().is_empty():
		return
	var sending: Array = _held.read()
	_held.set_value([])
	# every held send, in the order it was made
	for one: Array in sending:
		_sends.call(one[0], one[1])
