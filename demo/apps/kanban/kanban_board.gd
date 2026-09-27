extends "res://addons/gd_chime/controller.gd"

const GdChime := preload("res://addons/gd_chime/gd_chime.gd")
const KanbanData := preload("res://demo/apps/kanban/kanban_data.gd")

## The board's work: every card, the lane each stands in and the order of
## each lane, and the card open in the detail pane - every change made at once and sent to the server provisionally.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A MOVE IS ONE COMMAND, MOVES {the card, into, at}: into a lane, at a place
## among the cards that lane shows under the filters (filters.gd), so
## it lands before the card the reader saw there - whatever the filters hide.
## MOVES_ON and MOVES_BACK move a card to the head of the next lane or the one
## before. A lane with a limit refuses a card past it, in words, before any
## drop: the lane says why while the card is over it.
##
## EVERY CHANGE IS PROVISIONAL (provisional.gd): it stands at once - the card
## in its new lane, the title changed - and is sent; the server's no undoes
## it, so the card goes back once to where it stood, saying why on itself
## and in a notification. A card the reader sees says whether a change of
## it is on its way and why the last one was refused: each shown card is
## the card with {pending, refused}.
##
## OPENS brings a card into the detail pane, shown by the panels' own
## action, where it is changed in place. RENAMES opens a card's title for
## typing in the card itself; RETITLES writes it - {id, title} typed in the
## card, {line} in the pane, for the card open - and STOPS_RENAMING gives the
## typing up. WRITES_ABOUT {text}, SETS_PRIORITY, SETS_ESTIMATE and ASSIGNS
## {value} change the card open; RAISES and LOWERS its priority by a step.

const MOVES := &"moves_a_card"
const MOVES_ON := &"moves_a_card_on"
const MOVES_BACK := &"moves_a_card_back"
const OPENS := &"opens_a_card"
const RENAMES := &"renames_a_card"
const RETITLES := &"retitles_a_card"
const STOPS_RENAMING := &"stops_renaming"
const WRITES_ABOUT := &"writes_about_a_card"
const SETS_PRIORITY := &"sets_a_priority"
const RAISES := &"raises_a_priority"
const LOWERS := &"lowers_a_priority"
const SETS_ESTIMATE := &"sets_an_estimate"
const ASSIGNS := &"assigns_a_card"
## The panels' action bringing the detail pane into view.
const SHOWS_DETAIL := &"shows_the_card"
## Every action this is told.
const COMMANDS: Array[StringName] = [MOVES, MOVES_ON, MOVES_BACK, OPENS, RENAMES, RETITLES, STOPS_RENAMING, WRITES_ABOUT, SETS_PRIORITY, RAISES, LOWERS, SETS_ESTIMATE, ASSIGNS]
## How many a lane holds at most, where it has a limit.
const LIMITS := {"Testing": 26}
const DONE := "Done"

var _panels: GdChime.Panels  # the panels the detail pane stands in
var _provisional: GdChime.Provisional
var _filters: GdChime.Filters
var _cards := value({})  # id -> the card
var _order := value({})  # lane -> the ids in it, in order
var _open := value(null)  # the id of the card in the detail pane, or none
var _editing := value(null)  # the id of the card whose title is open for typing in it, or none


func _init(chimes: Chimes, filters: GdChime.Filters, provisional: GdChime.Provisional, panels: GdChime.Panels) -> void:
	super(chimes)
	_filters = filters
	_provisional = provisional
	_panels = panels
	# every lane, empty, then every card into its own
	for lane: String in KanbanData.LANE_WORDS:
		_order.read()[lane] = []
	for card: Dictionary in KanbanData.made():
		_cards.read()[card["id"]] = card
		_order.read()[card["lane"]].append(card["id"])


## A lane's cards as the reader sees them, bound: a lane (lane.gd) reads
## this, and the filters' test for which are shown - so a search moves none.
func lane(named: String) -> Bound:
	return Bound.new(func() -> Array: return _order.read()[named].map(_shown))


## A card as shown: the card, whether a change of it is on its way, and why
## the last was refused.
func _shown(id: int) -> Dictionary:
	var card: Dictionary = _cards.read()[id].duplicate()
	card["pending"] = _provisional.get_pending().has(id)
	card["refused"] = _provisional.get_refused().get(id)
	return card


## The card of this id as the board holds it: its lane, its title, the rest.
func get_card(id: int) -> Dictionary:
	return _cards.read()[id]


## Every card the board holds, in no order of its own.
func get_cards() -> Array:
	return _cards.read().values()


## Where a card stands in its lane, from the head, whatever the filters hide.
func get_place_in_lane(id: int) -> int:
	return _order.read()[_cards.read()[id]["lane"]].find(id)


func get_done() -> int:
	return _order.read()[DONE].size()


func get_whole() -> int:
	return get_cards().size()


## How many cards the filters show, of them all.
func get_shown_count() -> int:
	return _cards.read().values().filter(_filters.keeps).size()


## The card in the detail pane, as shown, or none.
func get_open_card() -> Variant:
	return null if _open.read() == null else _shown(_open.read())


func get_editing() -> Variant:
	return _editing.read()


func would(action: StringName, payload: Dictionary) -> Phrase:
	match action:
		MOVES:
			return _over_limit(payload["id"], payload["into"])
		MOVES_ON, MOVES_BACK:
			var next := _next(payload["id"], 1 if action == MOVES_ON else -1)
			if next == "":
				return Phrase.of("It is in the last lane already") if action == MOVES_ON else Phrase.of("It is in the first lane already")
			return _over_limit(payload["id"], next)
		RAISES:
			return Phrase.of("It is urgent already") if _cards.read()[payload["id"]]["priority"] == 3 else null
		LOWERS:
			return Phrase.of("It is low already") if _cards.read()[payload["id"]]["priority"] == 0 else null
		WRITES_ABOUT, SETS_PRIORITY, SETS_ESTIMATE, ASSIGNS:
			return Phrase.of("No card is open") if _open.read() == null else null
		RETITLES:
			return Phrase.of("A title needs words") if String(payload.get("title", payload.get("line"))).strip_edges() == "" else null
		STOPS_RENAMING:
			return Phrase.of("No title is being typed") if _editing.read() == null else null
	return null


func told(action: StringName, payload: Dictionary) -> Phrase:
	match action:
		MOVES:
			_move(payload["id"], payload["into"], _before(payload["into"], payload["id"], payload["at"]))
		MOVES_ON, MOVES_BACK:
			var into := _next(payload["id"], 1 if action == MOVES_ON else -1)
			_move(payload["id"], into, null if _order.read()[into].is_empty() else _order.read()[into][0])
		OPENS:
			_open.set_value(payload["id"])
			_panels.bring_into_view(&"detail")
		RENAMES:
			_editing.set_value(payload["id"])
		STOPS_RENAMING:
			_editing.set_value(null)
		RETITLES:
			_editing.set_value(null)
			# typed in the card, {id, title}; or in the pane, {line}, the card open's
			_change(payload.get("id", _open.read()), "title", String(payload.get("title", payload.get("line"))).strip_edges())
		WRITES_ABOUT:
			_change(_open.read(), "about", payload["text"])
		SETS_PRIORITY:
			_change(_open.read(), "priority", int(payload["value"]))
		RAISES, LOWERS:
			_change(payload["id"], "priority", _cards.read()[payload["id"]]["priority"] + (1 if action == RAISES else -1))
		SETS_ESTIMATE:
			_change(_open.read(), "estimate", int(payload["value"]))
		ASSIGNS:
			_change(_open.read(), "person", null if payload["value"] == "" else payload["value"])
	return null


## The lane this many steps along from the card's, or none past either end.
func _next(id: int, step: int) -> String:
	var at := KanbanData.LANE_WORDS.find(_cards.read()[id]["lane"]) + step
	return KanbanData.LANE_WORDS[at] if at >= 0 and at < KanbanData.LANE_WORDS.size() else ""


## Why a lane will not take the card: it holds as many as its limit, the card not among them.
func _over_limit(id: int, into: String) -> Phrase:
	if LIMITS.has(into) and _cards.read()[id]["lane"] != into and _order.read()[into].size() >= LIMITS[into]:
		return Phrase.with("%s holds %d at most", [into, LIMITS[into]])
	return null


## The card a card let go at this place among what a lane shows lands
## before: the one shown there, else the one after the last shown, else none - the end.
func _before(into: String, id: int, at: int) -> Variant:
	var others: Array = _order.read()[into].filter(func(one: int) -> bool: return one != id)
	var shown: Array = others.filter(func(one: int) -> bool: return _filters.keeps(_cards.read()[one]))
	if at < shown.size():
		return shown[at]
	var after := 0 if shown.is_empty() else others.find(shown.back()) + 1
	return others[after] if not shown.is_empty() and after < others.size() else null


## A card moved into a lane before another, or to its end; sent provisionally, undone back to where it stood.
func _move(id: int, into: String, before: Variant) -> void:
	var from: String = _cards.read()[id]["lane"]
	var was: int = _order.read()[from].find(id)
	_put(id, into, _order.read()[into].size() if before == null else _order.read()[into].find(before))
	_provisional.begin(id, Phrase.with("#%d to %s", [id, into]), {"id": id, "into": into, "labels": _cards.read()[id]["labels"]}, _put.bind(id, from, was))


## A card put in a lane at this place, out of the one it was in.
func _put(id: int, into: String, at: int) -> void:
	_order.read()[_cards.read()[id]["lane"]].erase(id)
	_order.read()[into].insert(clampi(at, 0, _order.read()[into].size()), id)
	_cards.read()[id]["lane"] = into
	_moved()


## One of a card's own values changed, sent provisionally, and undone back to what it was.
func _change(id: int, field: String, value: Variant) -> void:
	var was: Variant = _cards.read()[id][field]
	_write(id, field, value)
	_provisional.begin(id, Phrase.with("#%d, its %s", [id, field]), {"id": id, field: value, "labels": _cards.read()[id]["labels"]}, _write.bind(id, field, was))


func _write(id: int, field: String, value: Variant) -> void:
	_cards.read()[id][field] = value
	_moved()


## A card put where the server has it, read back after a refusal
## (provisional.gd): its values the server's, and in the server's lane - at
## its end if that is another lane, since the server keeps no order.
func settle(id: int, card: Dictionary) -> void:
	if card["lane"] != _cards.read()[id]["lane"]:
		_put(id, card["lane"], _order.read()[card["lane"]].size())
	_cards.read()[id].merge(card, true)
	_moved()


## The cards and the lanes, changed in place, set again for whatever reads them.
func _moved() -> void:
	_cards.set_value(_cards.read())
	_order.set_value(_order.read())


## Every action this model is told.
func answers() -> Array[StringName]:
	return COMMANDS
