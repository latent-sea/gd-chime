extends "res://addons/gd_chime/controller.gd"

const Commands := preload("res://addons/gd_chime/commands.gd")

## A source of rows for the long list: made up as they are asked for, as many
## as asked for, and answered later on purpose.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## What the long list is handed as fetch(first, count, answer). A request goes
## on a queue with the moment it falls due, DELAY_MS from now, and is answered
## from _process once that moment has passed - on the main thread, never within
## the call that asked, which is the whole of the contract. A row is its own
## number, first + 1 to first + count, cut at the length, so nothing is stored:
## a hundred thousand rows cost what a hundred do. The delay is there to be
## seen: a page on its way is dots on the screen, and a reset is every slot
## going to dots at once and filling back in.
##
## It is the rows' own model. Its length is a value (value.gd), set as it
## changes, which is what the long list is built following; and it
## is registered for GROW_ROWS_TENFOLD and SHRINK_ROWS_TENFOLD, for a button
## to dispatch, and takes the length up or down a power of ten between
## SHORTEST and LONGEST. A request still queued when the length changes is
## answered against the new length, and the list drops it: it was asked under
## an earlier generation.
##
## Deliberately absent: a source that can fail (an answer of null), rows with
## anything in them but a number, and a delay that varies.

const GROW_ROWS_TENFOLD := &"grow_rows_tenfold"
const SHRINK_ROWS_TENFOLD := &"shrink_rows_tenfold"
## Every action this is told.
const COMMANDS: Array[StringName] = [GROW_ROWS_TENFOLD, SHRINK_ROWS_TENFOLD]
const DELAY_MS := 600
const SHORTEST := 100
const LONGEST := 100000

var _length := value(0)  # how many rows there are; replaced, whatever reads the rows follows it
var _queue: Array[Dictionary] = []  # the requests not yet answered, oldest first


func _init(chimes: Chimes, length: int) -> void:
	super(chimes)
	_length.set_value(length)


func count() -> int:
	return _length.read()


## How many requests are queued and not yet answered.
func get_waiting() -> int:
	return _queue.size()


## What the long list calls. Answered DELAY_MS from now, from _process.
func fetch(first: int, count: int, answer: Callable) -> void:
	_queue.append({"due": Time.get_ticks_msec() + DELAY_MS, "first": first, "count": count, "answer": answer})
	set_process(true)


## Growing at the most rows, or shrinking at the fewest, is refused.
func would(action: StringName, _payload: Dictionary) -> Phrase:
	if action == GROW_ROWS_TENFOLD and count() == LONGEST:
		return Phrase.of("Already the most rows")
	if action == SHRINK_ROWS_TENFOLD and count() == SHORTEST:
		return Phrase.of("Already the fewest rows")
	return null


func told(action: StringName, _payload: Dictionary) -> Phrase:
	match action:
		GROW_ROWS_TENFOLD: _length.set_value(mini(count() * 10, LONGEST))
		SHRINK_ROWS_TENFOLD: _length.set_value(maxi(floori(float(count()) / 10.0), SHORTEST))
	return null


func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec()
	# every request whose moment has passed, oldest first, answered with its rows cut at the length
	while not _queue.is_empty() and _queue[0]["due"] <= now:
		var request: Dictionary = _queue.pop_front()
		var first: int = request["first"]
		var count: int = request["count"]
		var rows: Array[int] = []
		# the row numbers from first + 1, as many as were asked for and none past the length
		for index: int in range(first, mini(first + count, _length.read())):
			rows.append(index + 1)
		request["answer"].call(rows, _length.read())
	if _queue.is_empty():
		set_process(false)


## Every action this model is told.
func answers() -> Array[StringName]:
	return COMMANDS
