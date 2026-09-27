extends "controller.gd"

## Whether the application is busy, and what is keeping it so.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Whatever the player is waiting on takes a hold, by name, where the wait begins,
## and releases that name where the wait ends. While any name is held the
## application is busy. The names held are the count.
##
## Busy means the player is waiting, and nothing else. Work nobody is waiting on -
## done ahead of need, or warming what may be wanted next - takes no hold, however
## heavy it is: it must neither pause the drain nor tell the player that something
## is not ready.
##
## Two bells, one for each crossing. BUSY_BEGAN sounds when the first hold goes on
## and BUSY_ENDED when the last comes off; nothing sounds in between, because a
## second hold or a first release changes nothing anyone could read. A listener
## that cares about one direction listens to that one, and a listener that
## cares about both can tell them apart without reading anything.
##
## There is one gate and it outlives every screen, so its bells hang in the global
## region rather than in one its builder chooses: whatever listens reaches them at
## an address nobody has to be told, and closing a screen never takes them away.
##
## A name is held once. Holding a name already held is refused, and so is
## releasing one that is not: both come from our own code, so both are bugs at
## the call site, and the refusal names the name. Nothing is counted down on
## the way past, so a doubled release cannot reopen the application under live
## work. Two things that can be busy at the same time name themselves apart.
##
## No release is ever inferred - not from a destructor, not from an engine
## notification. A holder that forgets to release leaves the application busy,
## and get_holds() names it, oldest first. That is the safe way round:
## downtime work waits until the leak is released rather than running under
## live activity.
##
## It decides nothing about what busy means. Whether a drain stops, a screen
## shows itself or a cache is left alone is the listener's business.
##
## Deliberately absent, a pure addition the day something needs it: a watchdog
## that names a hold held too long, and the hold timings that would feed it.

const BUSY_BEGAN := &"busy_began"
const BUSY_ENDED := &"busy_ended"

var _holds: Dictionary = {}  # the names held, used as a set; kept in the order taken


func _init(chimes: Chimes) -> void:
	super(chimes, [], Chimes.GLOBAL)
	register_bell(BUSY_BEGAN)
	register_bell(BUSY_ENDED)


## Take a hold under this name. The first hold sounds BUSY_BEGAN.
func hold(name: StringName) -> void:
	if _holds.has(name):
		push_error("%s is already held" % name)
		return
	var was_idle := _holds.is_empty()
	_holds[name] = true
	if was_idle:
		strike(region, BUSY_BEGAN)


## Let go of a hold. The last release sounds BUSY_ENDED.
func release(name: StringName) -> void:
	if not _holds.has(name):
		push_error("%s is not held" % name)
		return
	_holds.erase(name)
	if _holds.is_empty():
		strike(region, BUSY_ENDED)


func is_busy() -> bool:
	return not _holds.is_empty()


## What is keeping it busy, oldest first.
func get_holds() -> Array[StringName]:
	var names: Array[StringName] = []
	# every name held, in the order taken
	for name: StringName in _holds:
		names.append(name)
	return names
