extends RefCounted

## A bound value: a read, which knows what it read.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A primitive given one reads it as it draws, and IS DRAWN AGAIN WHEN
## ANYTHING IT READ MOVES: every model value read on the way notes its bell
## (reads.gd), and the reader listens to exactly those (chimes.gd, follow).
## Nobody lists what to listen to. A model's value is one itself
## (value.gd); a value worked out from others is a function (ui.bound), and
## reads whatever the function read, however it came to read it.
##
## map(format) is for presentation formatting only: the value passed
## through a function on the way, on whatever the value read. A handle, the
## item an each or a virtual list hands its template, is a bound value too:
## a read of the item, and field(key) reads one key of the item it holds. A
## template must read through the handle, not from it: while the template
## function itself runs, a read of the handle is the item's value being
## copied into a description, which would go stale with nobody told, and is
## reported. A read from what the template described, made after, is the
## right one.
##
## A bound value a control answers for itself - a pressable's reason - is
## re-read when that control draws, as well as on what it read.

const Bound := preload("bound.gd")
const Reads := preload("../../reads.gd")

var _read: Callable
var _answerer: Object = null
var _template_running: bool = false


func _init(read: Callable, answerer: Object = null) -> void:
	_read = read
	_answerer = answerer


## The value as it is now.
func read() -> Variant:
	if _template_running:
		push_error("a template read its handle while describing; bind the handle instead, so the description re-reads it")
	return _read.call()


## The control this is the answer of, if any: told a reader of it, so the
## reader is drawn again when the control is.
func answerer() -> Object:
	return _answerer


## Whether the template this is the handle of is running now: set around
## the template's call alone, by the builder.
func set_template_running(running: bool) -> void:
	_template_running = running


## The same value through a formatting function.
func map(format: Callable) -> Bound:
	return Bound.new(func() -> Variant: return format.call(read()), _answerer)


## One key of the dictionary or one index of the array this reads.
func field(key: Variant) -> Bound:
	return map(func(item: Variant) -> Variant: return item[key] if item != null else null)


## A value that never moves: the one a primitive wanting a bound value is
## given where the thing it shows is settled - one column, one word, a
## choice's fixed offers. It reads nothing, so nothing is listened to.
static func constant(value: Variant) -> Bound:
	return Bound.new(func() -> Variant: return value)


## A value read from any number of bound values at once: the blend is
## handed their values in order, and moves on whatever any of them read.
static func all(sources: Array, blend: Callable) -> Bound:
	return Bound.new(func() -> Variant: return blend.callv(sources.map(func(source: Bound) -> Variant: return source.read())))


## The two-source case of all().
static func both(a: Bound, b: Bound, blend: Callable) -> Bound:
	return all([a, b], blend)


## A value read by this function that moves on the bell at this address
## and on nothing else: the handle a list hands its template, rung by the
## list as that one item changes. What the function reads on the way - the
## whole list - is not followed, so a piece whose item stayed reads nothing.
## The address is one name found now, so no read of the handle makes one.
static func on_bell(read: Callable, region: StringName, bell: StringName) -> Bound:
	var at := Reads.hung(region, bell)
	return Bound.new(func() -> Variant: return Reads.apart_at(read, at))
