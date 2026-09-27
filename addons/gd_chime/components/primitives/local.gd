extends "value.gd"

const Chimes := preload("../../chimes.gd")
const Driver := preload("../../driver.gd")

## A local: a value that belongs to what was built, and to nothing else.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## FOR STATE THAT IS THE INTERFACE'S ALONE - a node of a graph opened out,
## a picker open, which option is highlighted - AND NEVER FOR A FACT OF THE
## GAME. Setting it is not a command: it goes through no door, so it is
## never refused, taken, guided or recorded, and a thing that must be any
## of those is a model's. It is a value (value.gd) with a bell of its own
## (own_bell.gd): handed to what shows it as it is, read, and set with
## set_value(), which rings that bell, so what read it is drawn again and
## nothing else hears a thing.
##
## IT IS FREED WITH WHAT WAS BUILT FROM IT: nothing holds it but the nodes
## that read and press it, so when they go it goes, and it takes its bell
## with it.
##
## KEPT, the value lives with the history entry instead (driver.keep): each
## view has its own, a detour and Back find it as it was left, and it is
## let go with the entry. Reading a kept one reads where the reader is,
## which the driver notes, so it moves when the reader does too.
##
## Deliberately absent: a name. Two locals never meet, so nothing asks for one.

## The value a kept local keeps with a view: the driver keeps a RefCounted.
class Held extends RefCounted:
	var value: Variant

	func _init(held: Variant) -> void:
		value = held


var _driver: Driver
var _kept: bool


func _init(chimes: Chimes, driver: Driver, initial: Variant) -> void:
	var own := OwnBell.new("local")
	own.hang(chimes)
	super(own, initial)
	_driver = driver
	_kept = false


## This local kept with the history entry instead of with what was built:
## chained where it is made, since nothing has read it yet.
func kept() -> RefCounted:
	_kept = true
	return self


## The value as it is now: a kept one the view's own, or the first value where the view has none yet.
func read() -> Variant:
	var first: Variant = super.read()
	if not _kept:
		return first
	var held: Held = _driver.kept(_bell.get_address())
	return first if held == null else held.value


## Change it, and ring for whatever reads it.
func set_value(to: Variant) -> void:
	if not _kept:
		super.set_value(to)
		return
	_driver.keep(_bell.get_address(), Held.new(to))
	_bell.moved()
