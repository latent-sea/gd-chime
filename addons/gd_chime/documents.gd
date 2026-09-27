extends "controller.gd"

const SaveShape := preload("save_shape.gd")

## The documents open in an application: which are open, in the order their
## tabs stand, and which one is in front - the open files of an editor, the
## queries of a workspace - saved as plain data between runs.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## WHAT CAN BE OPENED IS A CATALOGUE handed in - a bound value reading every
## document there is, each {value, words} - never a list written here, so a
## file made or renamed is read again by whatever read the catalogue through
## this, and the tab of an open one says its words as they are now. This
## holds only which values are open and which is in front, each a value.
##
## Every change is a command through the door. OPENS {value} opens it after
## the one in front, or brings it to the front where it is open already - the
## payload a pick carries, so a picker, a palette and an explorer's row all
## open one the same way. CLOSES {value} closes it, the one beside it coming
## to the front if it was; CLOSES_FRONT, SHOWS_NEXT and SHOWS_PREVIOUS carry
## nothing, so a key or the pad presses them (shortcuts.gd). Each refuses
## what it cannot do, in words: a value the catalogue lacks, one not open,
## nothing open to close, nothing else to go to.
##
## A document in front is a FACT OF THIS MODEL, not a place: its tab is
## current while it is in front (pressable.gd's current_while), and Back
## never walks the files.
##
## SAVING IS PLAIN DATA: saved() is the open values and the front one;
## restore() takes one back only whole - a value the catalogue lacks, and
## all of it is refused out loud and what stands is kept, by the shape it
## must have (save_shape.gd).
##
## Deliberately absent: a document changed and not saved, a tab dragged to
## another place in the order, and two views of one document.

const OPENS := &"opens_a_document"
const CLOSES := &"closes_a_document"
const CLOSES_FRONT := &"closes_the_front_document"
const SHOWS_NEXT := &"shows_the_next_document"
const SHOWS_PREVIOUS := &"shows_the_previous_document"
## Every action this is told.
const COMMANDS: Array[StringName] = [OPENS, CLOSES, CLOSES_FRONT, SHOWS_NEXT, SHOWS_PREVIOUS]

var _catalogue: Bound
var _open := value([])  # the values open, in the order their tabs stand
var _front := value(null)  # the value in front, or none while nothing is open


func _init(chimes: Chimes, catalogue: Bound) -> void:
	super(chimes, [], Chimes.GLOBAL)
	_catalogue = catalogue


## The documents open, in the order their tabs stand, each {value, words} as the catalogue says it now.
func get_open() -> Array:
	return _open.read().map(func(value: Variant) -> Dictionary: return _entry(value))


## The value in front, or none.
func get_front() -> Variant:
	return _front.read()


## Whether this value is the one in front, bound: what its tab reads to stand current.
func is_front(document: Bound) -> Bound:
	return Bound.both(document, _front, func(entry: Variant, front: Variant) -> bool: return entry != null and front != null and entry["value"] == front)


## A document opened after the one in front, or brought to the front where
## it is open already: what a pick of it does, and what whoever makes one does.
func open(value: Variant) -> void:
	var open: Array = _open.read().duplicate()
	if not open.has(value):
		open.insert(open.find(_front.read()) + 1, value)
	_open.set_value(open)
	_front.set_value(value)


func would(action: StringName, payload: Dictionary) -> Phrase:
	match action:
		OPENS:
			return null if _entry(payload["value"]) != null else Phrase.with("There is no %s to open", [payload["value"]])
		CLOSES:
			return null if _open.read().has(payload["value"]) else Phrase.with("%s is not open", [payload["value"]])
		CLOSES_FRONT:
			return null if _front.read() != null else Phrase.of("Nothing is open")
	return null if _open.read().size() > 1 else Phrase.of("No other document is open")


func told(action: StringName, payload: Dictionary) -> Phrase:
	match action:
		OPENS:
			open(_entry(payload["value"])["value"])
		CLOSES:
			_close(payload["value"])
		CLOSES_FRONT:
			_close(_front.read())
		SHOWS_NEXT, SHOWS_PREVIOUS:
			var open: Array = _open.read()
			var at := open.find(_front.read()) + (1 if action == SHOWS_NEXT else -1)
			_front.set_value(open[posmod(at, open.size())])
	return null


## A document closed; in front, the one after it comes to the front, else the one before, else none.
func _close(value: Variant) -> void:
	var open: Array = _open.read().duplicate()
	var at := open.find(value)
	open.remove_at(at)
	_open.set_value(open)
	if _front.read() == value:
		_front.set_value(null if open.is_empty() else open[mini(at, open.size() - 1)])


## The catalogue's entry for a value, or none - a value read back from text
## is matched as equal, so a number that came back a fraction still finds it.
func _entry(value: Variant) -> Variant:
	# every document there is, for the one of this value
	for entry: Dictionary in _catalogue.read():
		if entry["value"] == value:
			return entry
	return null


## --- saving, which is plain data ---

## The values open and the one in front.
func saved() -> Dictionary:
	return {"open": _open.read().duplicate(), "front": _front.read()}


## Documents read back from a save, whole, each value as the catalogue has
## it; what names a document the catalogue lacks is said out loud and what
## stands is kept.
func restore(save: Dictionary) -> void:
	# a value the catalogue has, as a piece of a save's shape
	var known := func(value: Variant) -> String: return "" if _entry(value) != null else "%s is no document there is" % [value]
	var shape := SaveShape.such_that(SaveShape.record({"open": SaveShape.list_of(known), "front": SaveShape.maybe(known)}), func(whole: Dictionary) -> bool: return whole["front"] == null or whole["open"].has(whole["front"]), "the one in front is not open")
	if SaveShape.refused(shape, save, "documents there are"):
		return
	_open.set_value(save["open"].map(func(value: Variant) -> Variant: return _entry(value)["value"]))
	_front.set_value(null if save["front"] == null else _entry(save["front"])["value"])


## Every action this model is told.
func answers() -> Array[StringName]:
	return COMMANDS
