extends "controller.gd"

## Whether the far side can be reached: a connection, said by whoever can
## tell - the device's network, a socket's reader - and read by anything
## that waits on it or says it.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## ONE OF FOUR STATES, the words a stream's source says its link in
## (stream.gd): CONNECTING, CONNECTED, RECONNECTING, LOST. Only CONNECTED is
## online. set_state() is told by the one who knows, and sets the value
## STATE once per change, never for the same state again; get_online() is
## what an outbox (outbox.gd) waits on, and STATE what a status line says.
##
## Built, it is LOST until told otherwise: nothing is sent on a connection
## nobody has said is there.
##
## Deliberately absent: how good the connection is, and finding out by
## itself - asking the network is the teller's.

const CONNECTING := &"connecting"
const CONNECTED := &"connected"
const RECONNECTING := &"reconnecting"
const LOST := &"lost"

## How it stands: one of the four, set by whoever can tell.
var state := value(LOST)


func _init(chimes: Chimes) -> void:
	super(chimes)


## Whether the far side can be reached now.
func get_online() -> bool:
	return state.read() == CONNECTED


## The one who knows says how it stands: set once per change.
func set_state(to: StringName) -> void:
	if to != state.read():
		state.set_value(to)
