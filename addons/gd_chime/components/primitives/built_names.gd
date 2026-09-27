extends "describe_loads.gd"

## The builder's names: the node each name was built under, for an anchored
## piece to find what it is anchored to, a scroll to find what to reveal,
## and a test to read what it built.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The builder (ui.gd) extends this, through built_within.gd; the descriptions it extends in turn are
## describe.gd's and the layers between. It stands apart because what it
## holds outlives what it names, and must never grow with a session:
##
## A NAME READ AFTER ITS NODE IS FREED IS NOTHING - never the freed node, on
## which even an `is` would fail - and is let go as it is read. A NAME LET GO
## BY WHAT BUILT UNDER IT goes at once (forget_named): a keyed list's piece,
## its key gone (each.gd). AND EVERY FREED NODE'S NAME IS SWEPT as the names
## held pass twice what stood at the last sweep, so what is held stays
## within twice what stands, whatever freed it and however long the session.
## The sweep is a walk of the names, paid once each time they double.

## How many names may stand past twice the last sweep's before the freed are swept again: a few, so a small app never sweeps.
const NAMES_BEFORE_A_SWEEP := 64

var _named: Dictionary = {}  # id -> the node built under that name
var _swept: int = 0  # how many names stood after the last sweep of the freed


## The node this name was built under, or nothing once it is freed.
func node_named(id: StringName) -> Node:
	var named: Variant = _named.get(id)
	if not is_instance_valid(named):
		_named.erase(id)
		return null
	return named


## A node built under this name; twice the names that stood at the last
## sweep, and every freed node's name is let go.
func name_piece(id: StringName, made: Node) -> void:
	_named[id] = made
	if _named.size() <= 2 * _swept + NAMES_BEFORE_A_SWEEP:
		return
	# every name held, let go where its node is freed
	for held: StringName in _named.keys():
		if not is_instance_valid(_named[held]):
			_named.erase(held)
	_swept = _named.size()


## A name let go by whatever built under it, its piece going (each.gd).
func forget_named(id: StringName) -> void:
	_named.erase(id)
