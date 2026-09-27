extends "by_shape.gd"

const Shape := preload("../../shape.gd")

## The same parts arranged by the width THIS has, not the width the window
## has: a card that stacks itself when it is put in a narrow column, beside
## another of the same card that stays a row because its column is wide.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Everything about the parts is by_shape.gd's - built once, only their
## arrangement changes, and the new one arrives whole - and all that differs
## is what chooses. The window's size class cannot answer this: two cards
## side by side on one wide window have very different room, and a card does
## not know what it was put in. The engine tells a Control its own rect
## changed, so nothing is connected and nothing is published, and the answer
## comes on the frame the layout above sized it.
##
## A BREAKPOINT IS THE LEAST WIDTH AN ARRANGEMENT NEEDS, one per
## arrangement: a share of the base width, as a number, or the name of a
## constant the look holds under the type Shape, in base pixels. Never a
## pixel count written in a recipe - that is a size on one screen and a
## mistake on the next. The widest breakpoint the width meets wins, so one
## of them is 0.0: the arrangement for a width that meets nothing else.

var _breakpoints: Dictionary
var _sized: bool = false  # whether it has ever been given a width


func _init(ui: RefCounted, names: Array, arrangements: Dictionary, breakpoints: Dictionary, asked: StringName) -> void:
	# no bound value and no bells: its own width is what it answers, and the engine tells it that
	super(ui, names, arrangements, Bound.constant(&""), asked)
	_breakpoints = breakpoints


## The arrangement for the width it has: the widest breakpoint that width
## meets. Before it has been sized that is the one at nothing.
func key_now() -> StringName:
	var best: StringName = &""
	var most := -1.0
	# every breakpoint the width meets, keeping the widest of them
	for named: StringName in _breakpoints:
		var least := _least_width(_breakpoints[named])
		if size.x >= least and least > most:
			most = least
			best = named
	if best == &"":
		push_error("nothing is arranged for a width of %s; the breakpoints are %s" % [size.x, _breakpoints])
	return best


## A breakpoint in the canvas's own pixels: a share of the base width, or a
## constant the look holds.
func _least_width(given: Variant) -> float:
	if given is StringName:
		return float(get_theme_constant(given, Shape.TYPE))
	return given * get_viewport().get_visible_rect().size.x


## Resized, it answers its new width. The width it is FIRST given is the
## width it was built for, so that arrangement is simply there; every later
## one is seen to arrive. The engine tells every script in the chain, so
## by_shape's own notification runs as well without a call here.
func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _gathered:
		var first := not _sized
		_sized = true
		_begun = not first
		_take_up(key_now())
		_begun = true


## The builder's door: the parts described are its contents, arranged by
## the width this has.
static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(desc.kind).new(ui, desc.props["names"], desc.props["arrangements"], desc.props["breakpoints"], desc.props.get("transition", &""))
	ui.attach(made, parent, desc.facts)
	return made
