extends "res://addons/gd_chime/controller.gd"

const GdChime := preload("res://addons/gd_chime/gd_chime.gd")

## A shopper's basket: the pieces they mean to buy, how many of each, and
## what it all comes to.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## ADDS {id} puts one more of a piece in - refused for a piece sold out -
## and says so in a notification; CHANGES {id, by} takes one more or one
## fewer, one fewer than one taking the piece out; REMOVES {id} takes it
## out; CHECKS_OUT - refused while the basket is empty - empties it and
## says the order is placed. The lines are read by whoever draws the
## basket: {id, name, price, count, cost}; the count of pieces and the
## total are reads of their own.
##
## Deliberately absent: paying, delivery, and a basket kept between runs.

const ADDS := &"adds_to_basket"
const CHANGES := &"changes_how_many"
const REMOVES := &"removes_from_basket"
const CHECKS_OUT := &"checks_out"
const COMMANDS: Array[StringName] = [ADDS, CHANGES, REMOVES, CHECKS_OUT]
const SOLD_OUT := "sold out"

var _rows: GdChime.PackedRows
var _notifications: GdChime.Notifications
var _lines := value([])  # {id, count}, in the order first added


func _init(chimes: Chimes, rows: GdChime.PackedRows, notifications: GdChime.Notifications) -> void:
	super(chimes)
	_rows = rows
	_notifications = notifications


## Every line: {id, name, price, count, cost}.
func get_lines() -> Array:
	return _lines.read().map(func(line: Dictionary) -> Dictionary: return {"id": line["id"], "name": _rows.value_at(line["id"], &"name"), "price": _rows.value_at(line["id"], &"price"), "count": line["count"], "cost": _rows.value_at(line["id"], &"price") * line["count"]})


## How many pieces the basket holds, every line's count together.
func get_count() -> int:
	return _lines.read().reduce(func(sum: int, line: Dictionary) -> int: return sum + line["count"], 0)


func get_total() -> float:
	return get_lines().reduce(func(sum: float, line: Dictionary) -> float: return sum + line["cost"], 0.0)


func get_empty() -> bool:
	return _lines.read().is_empty()


func would(action: StringName, payload: Dictionary) -> Phrase:
	if action == ADDS and payload.has("id") and _rows.value_at(payload["id"], &"stock") == SOLD_OUT:
		return Phrase.of("Sold out")
	if action == CHECKS_OUT and _lines.read().is_empty():
		return Phrase.of("The basket is empty")
	return null


func told(action: StringName, payload: Dictionary) -> Phrase:
	match action:
		ADDS:
			_change(payload["id"], 1)
			_notifications.notify(Phrase.with("%s is in your basket", [_rows.value_at(payload["id"], &"name")]))
		CHANGES: _change(payload["id"], payload["by"])
		REMOVES: _lines.set_value(_lines.read().filter(func(line: Dictionary) -> bool: return line["id"] != payload["id"]))
		CHECKS_OUT:
			var paid := Phrase.written(func() -> String: return GdChime.Formats.written_number(get_total()))
			_lines.read().clear()
			_notifications.notify(Phrase.with("Your order of £%s is placed", [paid]))
	# the lines, changed in place, set again for whatever reads them
	_lines.set_value(_lines.read())
	return null


## A piece's line taking this many more - a new line if it had none, gone if it comes to none.
func _change(id: int, by: int) -> void:
	var found: Array = _lines.read().filter(func(line: Dictionary) -> bool: return line["id"] == id)
	if found.is_empty():
		_lines.read().append({"id": id, "count": by})
		return
	found[0]["count"] += by
	if found[0]["count"] <= 0:
		_lines.read().erase(found[0])


## Every action this model is told.
func answers() -> Array[StringName]:
	return COMMANDS
