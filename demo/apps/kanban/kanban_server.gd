extends Node

const GdChime := preload("res://addons/gd_chime/gd_chime.gd")

## The team's tracker server, standing in: every change the board makes is
## sent here and answered later - kept, or refused with a reason.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## What provisional.gd is handed as the far side, send(request, answer): a
## request goes on a queue with the moment it falls due, DELAY_MS from now,
## and is answered from _process once that moment has passed - on the main
## thread, never within the call that asked. It refuses a move of a card
## labelled blocked past In progress, always, and any change at random at
## the rate it is set to - none unless asked - so the board is seen to
## roll back a change the reader made. It keeps its own record of every
## card, the changes it said yes to written into it, and reads(id, answer)
## answers with a card as the record has it, on the same queue - so a read
## asked after a change is answered after it.
##
## Deliberately absent: a delay that varies, a server that never answers,
## and the order of cards within a lane - the board's own.

const KanbanData := preload("res://demo/apps/kanban/kanban_data.gd")
const DELAY_MS := 700
## The lanes a blocked card may not move into.
const PAST_IN_PROGRESS: Array[String] = ["Review", "Testing", "Done"]

## How often a change is refused at random, from 0 to 1.
var refuses_at_random: float = 0.0
## Whether answers wait until answer_all() is called: a probe holds them, so what it reads between is certain.
var held: bool = false
var _queue: Array[Dictionary] = []  # the requests and reads not yet answered, oldest first
var _draws := RandomNumberGenerator.new()
var _record: Dictionary = {}  # id -> the card as the server keeps it


func _init() -> void:
	_draws.seed = 77
	# every card, as the board begins with it
	for card: Dictionary in KanbanData.made():
		_record[card["id"]] = card
	set_process(false)


## A change sent: answered DELAY_MS from now.
func send(request: Dictionary, answer: Callable) -> void:
	_queue.append({"due": Time.get_ticks_msec() + DELAY_MS, "request": request, "answer": answer})
	set_process(true)


## A card read: answered DELAY_MS from now with the card as the record has it then.
func reads(id: int, answer: Callable) -> void:
	_queue.append({"due": Time.get_ticks_msec() + DELAY_MS, "read": id, "answer": answer})
	set_process(true)


## A card as the record has it, for a probe to hold the board against.
func get_card(id: int) -> Dictionary:
	return _record[id]


## How many changes are waiting for an answer.
func get_waiting() -> int:
	return _queue.size()


## Every request queued answered now, whatever the time and whether held: for a probe and a measure.
func answer_all() -> void:
	# every request queued, answered as if its moment had come
	for request: Dictionary in _queue:
		request["due"] = 0
	_answer()


func _process(_delta: float) -> void:
	if not held:
		_answer()


## Every request and read whose moment has passed answered, oldest first:
## a read with the card as the record has it, a change kept written into it.
func _answer() -> void:
	var now := Time.get_ticks_msec()
	# every request and read whose moment has passed, oldest first
	while not _queue.is_empty() and _queue[0]["due"] <= now:
		var sent: Dictionary = _queue.pop_front()
		if sent.has("read"):
			sent["answer"].call(_record[sent["read"]].duplicate())
			continue
		var refusal: Variant = _refusal(sent["request"])
		if refusal == null:
			_keep(sent["request"])
		sent["answer"].call(refusal)
	if _queue.is_empty():
		set_process(false)


## A change kept: every value it carries written into the card's record, a move's lane among them.
func _keep(request: Dictionary) -> void:
	var card: Dictionary = _record[request["id"]]
	# every value the change carries but the card it is about
	for field: String in request:
		if field != "id":
			card["lane" if field == "into" else field] = request[field]


## Why the server will not keep a change, or nothing.
func _refusal(request: Dictionary) -> Variant:
	if request.has("into") and (request["labels"] as Array).has("blocked") and PAST_IN_PROGRESS.has(request["into"]):
		return GdChime.Phrase.with("#%d is blocked by another card", [request["id"]])
	if _draws.randf() < refuses_at_random:
		return GdChime.Phrase.of("The server was busy; try again")
	return null
