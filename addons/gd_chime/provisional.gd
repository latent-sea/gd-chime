extends "controller.gd"

const Notifications := preload("notifications.gd")

## Provisional changes: what a model has changed AT ONCE, before whoever
## keeps the record - a server, a far side - has said yes; and, told no,
## each change undone, its reason kept on the thing and said in a
## notification. The recipe for optimistic updates, for any model.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE MODEL CHANGES FIRST, in its own told(), exactly as it would with
## nobody to ask, and then hands this the change: begin(key, words,
## request, undo) - which thing it is about, the words a reader knows it
## by, the request the far side is sent, and how to undo it. So the reader
## sees the change as their hand lands, never a wait: a card dropped stays
## where it was dropped.
##
## THE FAR SIDE IS HANDED IN, as sends(request, answer): it answers later,
## on the main thread and never within the call that asked - the contract
## a long list's source keeps (slow_source.gd) - with null for yes, or a
## phrase saying why not. A yes changes nothing on the screen: the change
## was shown already, so nothing moves a second time.
##
## A NO UNDOES THE CHANGE AND EVERY LATER ONE ON THE SAME THING, newest
## first, since those were made on top of it. The undoing happens in one
## call, so the thing is seen to go back once, to where it stood before the
## refused change. The reason is kept against the thing - get_refused(),
## for the thing to say why on itself - until the thing is changed again,
## and said in the application's notifications with the words it is known by.
##
## NOTHING ENDS SILENTLY DIFFERENT FROM THE FAR SIDE. The later changes a
## no undid were sent already, and the far side may yet keep one: so a
## thing whose later changes were undone is in doubt, and once no request
## of it is on its way - every answer in, a yes to an undone change among
## them - its true state is read back through the far side, reads(key,
## answer), and the model settles on it, settles(key, state): what the far
## side says wins over whatever the screen held. A read overtaken by a new
## change of the thing is let go, and the thing read again once that change
## is answered. A model that hands in no way to read back is told instead,
## in a notification, that the thing may not be as the far side has it.
##
## Which things have a change or a read on its way is get_pending(), for
## the thing to say it is not yet kept. It and the refusals are values
## (value.gd), set again as either changes.
##
## Deliberately absent: sending again after a refusal, merging changes, and
## a far side that never answers - a request with no answer stays pending.

var _reads: Callable  # the far side's record read back: reads(key, answer), answer(state) called later
var _settles: Callable  # the model put where the far side says: settles(key, state)
var _sends: Callable  # the far side: sends(request, answer), answer(refusal) called later
var _notices: Notifications
var _open: Array[Dictionary] = []  # every change not yet answered, {ticket, key, words, undo}, oldest first
var _refused: Dictionary = {}  # key -> why the far side refused its last change, until it is changed again
var _let_go: Dictionary = {}  # ticket -> key, of every change undone whose answer has not come
var _doubted: Dictionary = {}  # key -> the words it is known by, for every thing that may differ from the far side
var _reading: Dictionary = {}  # key -> the ticket of the read of it on its way
var _last_ticket: int = 0
var _pending := value({})  # key -> how many changes and reads of it are on their way, as last set
var _refusals := value({})  # key -> why its last change was refused, as last set


## The far side and the model's own way back from it, all of it given here:
## what a change is sent through, where a notification goes, how a thing's
## true state is read back, and how the model settles on what comes back -
## none, and a thing in doubt is said in a notification instead.
func _init(chimes: Chimes, sends: Callable, notices: Notifications, reads := Callable(), settles := Callable()) -> void:
	super(chimes)
	_sends = sends
	_notices = notices
	_reads = reads
	_settles = settles


## Every thing with a change or a read on its way: key -> how many.
func get_pending() -> Dictionary:
	return _pending.read()


## Every thing whose last change the far side refused: key -> why.
func get_refused() -> Dictionary:
	return _refusals.read()


## The changes, the reads or the refusals moved: what is pending and what
## was refused set again, for whatever reads them.
func _moved() -> void:
	var pending: Dictionary = {}
	# every change not yet answered and every read, counted against its thing
	for key: Variant in _open.map(func(change: Dictionary) -> Variant: return change["key"]) + _reading.keys():
		pending[key] = pending.get(key, 0) + 1
	_pending.set_value(pending)
	_refusals.set_value(_refused.duplicate())


## A change the model has made already, sent: the thing it is about, the
## words it is known by, the request, and how to undo it.
func begin(key: Variant, words: Phrase, request: Dictionary, undo: Callable) -> void:
	_last_ticket += 1
	_open.append({"ticket": _last_ticket, "key": key, "words": words, "undo": undo})
	_refused.erase(key)
	# a read of the thing on its way now answers for before this change, so it is let go when it comes
	_reading.erase(key)
	_moved()
	_sends.call(request, _answered.bind(_last_ticket))


## The far side's answer to one change: yes, and it is kept; no, and it and
## every later change on the same thing are undone, newest first. An answer
## to a change undone already leaves the thing in doubt, read back once quiet.
func _answered(refusal: Variant, ticket: int) -> void:
	if _let_go.has(ticket):
		var was: Variant = _let_go[ticket]
		_let_go.erase(ticket)
		_read_back(was)
		return
	var at := _open.find_custom(func(change: Dictionary) -> bool: return change["ticket"] == ticket)
	var key: Variant = _open[at]["key"]
	if refusal == null:
		_open.remove_at(at)
		_moved()
		_read_back(key)
		return
	var undone: Array = _open.slice(at).filter(func(change: Dictionary) -> bool: return change["key"] == key)
	undone.reverse()
	# every change on the thing from the refused one on, newest first; the later ones' requests still on their way
	for change: Dictionary in undone:
		change["undo"].call()
		_open.erase(change)
		if change["ticket"] != ticket:
			_let_go[change["ticket"]] = key
			_doubted[key] = change["words"]
	_refused[key] = refusal
	_moved()
	# said by the words of the change refused: the oldest undone, last now they run newest first
	_notices.notify(Phrase.with("%s was not kept: %s", [undone.back()["words"], refusal]))
	_read_back(key)


## A thing in doubt read back from the far side, once no request of it is
## on its way and none is being read; or, with no way to read back, the
## reader told it may differ.
func _read_back(key: Variant) -> void:
	var busy: bool = _open.any(func(change: Dictionary) -> bool: return change["key"] == key) or _let_go.values().has(key) or _reading.has(key)
	if not _doubted.has(key) or busy:
		return
	if not _reads.is_valid():
		_notices.notify(Phrase.with("%s may not be as the server has it", [_doubted[key]]))
		_doubted.erase(key)
		return
	_last_ticket += 1
	_reading[key] = _last_ticket
	_moved()
	_reads.call(key, _read.bind(key, _last_ticket))


## The far side's record of a thing: the model settles on it, unless a
## change of the thing began since it was asked - then it is let go, and the
## thing read again once that change is answered.
func _read(state: Variant, key: Variant, ticket: int) -> void:
	if _reading.get(key) != ticket:
		return
	_reading.erase(key)
	_doubted.erase(key)
	_settles.call(key, state)
	_moved()
