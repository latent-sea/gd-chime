extends Container

## A line of parts, sized and placed by the flexbox algorithm.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The rules are not ours: this follows CSS Flexible Box Layout Level 1, § 9, so
## a question about what it does has a section number for an answer. Resolving
## one line's lengths is § 9.7, in flex_line.gd with where a part sits, and which
## parts are on which line § 9.3, in flex_lines.gd; this file decides which way
## the line runs, how wide the gaps are, and where each part ends up.
##
## A part's length starts at its basis, a fraction of this layout, or at its
## own smallest size. Lengths are fractions because pixels are a size on one
## screen and a mistake on the next; the gap alone arrives in pixels, from
## whoever knows the window and its scale.
##
## It extends the engine's Container, told - with nothing connected - when a
## part's smallest size changes, when this is resized, and when a part is
## added, hidden or freed; a Container's own smallest size reaches whatever
## holds it, so a change in a leaf re-places every layout above it. No engine
## Container lays anything out here.
##
## A window resize reaches it through its rect: a layout anchored to the
## window is resized by the engine when the window is, and every layout
## nested under it by the one above - one placing each, nothing watching.
##
## BETWEEN TWO PARTS IT LEAVES AT LEAST WHAT EACH DRAWS PAST ITS EDGE toward
## the other - a box's shadow (drawn_reach.gd) - and never less than its gap,
## so nothing is drawn over its neighbour; nothing across the line. What it
## draws past its own edges it answers for (get_reach), from where it placed
## its parts; that changed, the line holding it places its parts again.
##
## What room the layout itself needs is what its parts need between them;
## whoever builds it may hold open more with the engine's own custom minimum.
##
## A part knows nothing about being laid out. Its facts are held here
## against the part, so one control can sit in another layout under other
## facts.
##
## They are held for as long as the part is here; taken out, freed or moved
## to another parent, it is forgotten. Measured on 4.6.2: a node is told its children changed on every
## add, removal, free and move to another parent, in the tree or out of it, and
## the part that left is already not its child when it is told.
##
## Deliberately absent, each a pure addition: the reverse directions; packing
## the lines across the layout; margins; baseline alignment; and what GIVES
## when the parts cannot fit, which belongs above this with what they mean.

const FlexLine := preload("flex_line.gd")
const FlexLines := preload("flex_lines.gd")
const DrawnReach := preload("drawn_reach.gd")
const Shift := preload("shift.gd")

const ROW := 0
const COLUMN := 1
const START := FlexLine.START
const CENTER := FlexLine.CENTER
const END := FlexLine.END
const BETWEEN := FlexLine.BETWEEN
const AROUND := FlexLine.AROUND
const EVENLY := FlexLine.EVENLY
const STRETCH := FlexLine.STRETCH

## What may be said about a part. Anything else is a mistake, not a request.
const FACTS := ["order", "basis", "grow", "shrink", "max", "align"]

var justify: int = START
var align: int = STRETCH

## How many times the parts have been placed, so that the engine coalescing two
## changes into one is something a test can read rather than something it argues.
var arrange_count: int = 0

var _direction: int
var _wrap: bool
var _gap: float
var _facts: Dictionary = {}  # part -> what was given for it
var _wrapped: float = 0.0  # how thick its lines came to as last placed, wrapping
var _reach: Array[float] = [0.0, 0.0, 0.0, 0.0]  # how far what it holds draws past each of its edges, as last placed
var _placed_from: Array = []  # what its parts were last placed from: its size, the parts, their least sizes, reaches and facts, and its settings


func _init(direction: int, wrapping: bool, gap: float) -> void:
	_direction = direction
	_wrap = wrapping
	_gap = gap


## Put a part in, with the facts that size it. A fact this layout has no meaning
## for, or a fraction outside the line, leaves the part unplaced and says so:
## laying it out on a guess would be a wrong screen nobody was told about.
func place(part: Control, facts: Dictionary = {}) -> void:
	# every fact given, refusing one that means nothing here
	for given: String in facts:
		if not FACTS.has(given):
			push_error("a flex part has no %s; it has %s" % [given, FACTS])
			return
	# basis and max are fractions of this layout, so neither reaches past it
	for fraction: String in ["basis", "max"]:
		if facts.has(fraction) and (facts[fraction] < 0.0 or facts[fraction] > 1.0):
			push_error("a flex %s is a fraction of the line, not %s" % [fraction, facts[fraction]])
			return
	_facts[part] = facts
	add_child(part)


## The gap between parts, in pixels, from whoever knows the window's scale.
func set_gap(gap: float) -> void:
	_gap = gap
	queue_sort()


## Whether the line wraps onto more lines where its parts do not fit.
func set_wrap(wrapping: bool) -> void:
	_wrap = wrapping
	queue_sort()


## What was given for this part, as a copy - or nothing, for a part that is not
## in this layout.
func get_facts(part: Control) -> Dictionary:
	return _facts[part].duplicate() if _facts.has(part) else {}


## How far what this holds draws past its edge on this side, as last placed.
func get_reach(side: int) -> float:
	return _reach[side]


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SORT_CHILDREN:
			_arrange()
		NOTIFICATION_CHILD_ORDER_CHANGED:
			# every part given facts, forgetting one that is no longer a child here
			for part: Control in _facts.keys():
				if part.get_parent() != self:
					_facts.erase(part)


## The smallest this can be and still hold its parts, which is what whatever
## holds it asks for. Wrapping, along the line it is the largest part, and
## across it as thick as its lines came to when last placed - the engine asks
## with no width - asked again as that changes, as its flowing containers do.
func _get_minimum_size() -> Vector2:
	var parts := _in_order()
	var along := 0.0
	var across := 0.0
	# every part, gathering the length of the line and the thickness of it
	for part: Control in parts:
		var smallest := part.get_combined_minimum_size()
		along = maxf(along, _main(smallest)) if _wrap else along + _main(smallest)
		across = maxf(across, _cross(smallest))
	if _wrap:
		across = maxf(across, _wrapped)
	if not _wrap:
		# every gap between the parts, each as wide as the shadows either side need
		for gap: float in DrawnReach.gaps(parts, DrawnReach.of_each(parts), _gap, _direction == ROW):
			along += gap
	return _vector(along, across)


func _arrange() -> void:
	var parts := _in_order()
	var smallest: Array[Vector2] = []
	# every part's least size, asked once
	for part: Control in parts:
		smallest.append(part.get_combined_minimum_size())
	var reaches := DrawnReach.of_each(parts)
	# placed from all the same as last time - shown again, or told of a change that moved nothing here - every part stands where it was put
	var from := [size, parts, smallest, reaches, parts.map(func(part: Control) -> Dictionary: return _facts[part]), _gap, justify, align, _wrap]
	if from == _placed_from:
		return
	_placed_from = from
	arrange_count += 1
	if parts.is_empty():
		return
	var room := _main(size)
	var numbers: Array = []
	var wants: Array = []
	# every part's five numbers - where it starts, its limits, and how it flexes - and what it wants of the line
	for at: int in parts.size():
		numbers.append(FlexLine.numbers(_facts[parts[at]], _main(smallest[at]), room))
		wants.append(FlexLine.held(numbers[-1]["base"], numbers[-1]))
	var before := DrawnReach.gaps(parts, reaches, _gap, _direction == ROW)
	var lines := FlexLines.collect(wants, before, room, _wrap)

	var across := 0.0
	var needed := 0.0
	# every line, its parts named by where they stand: how long they are, then where each one sits along and across it
	for placing: Array in lines:
		var gaps := 0.0
		var each: Array = []
		var thickest := 0.0
		# every part on this line, for the gap before it after the first, the numbers that size it and the thickest of them
		for at: int in placing:
			gaps += before[at] if at != placing[0] else 0.0
			each.append(numbers[at])
			thickest = maxf(thickest, _cross(smallest[at]))
		var length := FlexLine.lengths(each, room, gaps)
		var used := gaps
		# every length, for how much of the line the parts and the gaps take
		for at: int in length.size():
			used += length[at]
		# one line alone is as thick as this layout, so a lone part can fill it
		var thickness: float = _cross(size) if lines.size() == 1 else thickest
		var spread := FlexLine.spread(justify, room - used, placing.size(), _gap)
		var along := spread.x
		var between := spread.y
		needed += thickest + (_gap if placing != lines[0] else 0.0)
		# each part in turn, placed along the line and set across it at its scale and turn, its shift left to an each (shift.gd)
		for on: int in placing.size():
			var part: Control = parts[placing[on]]
			var sits: int = _facts[part]["align"] if _facts[part].has("align") else align
			var thick: float = thickness if sits == STRETCH else _cross(smallest[placing[on]])
			Shift.fit(self, part, Rect2(_vector(along, across + FlexLine.aligned(sits, thickness, thick)), _vector(length[on], thick)), false)
			along += length[on] + between - _gap + (before[placing[on + 1]] if on + 1 < placing.size() else 0.0)
		across += thickness + _gap
	# wrapping, the thickness its lines came to is the least it needs: changed, whatever holds it is told
	if _wrap and needed != _wrapped:
		_wrapped = needed
		update_minimum_size()
	var reach := DrawnReach.past(self, parts, reaches)
	if reach != _reach:
		_reach = reach
		DrawnReach.tell_holder(self)


## The parts as a line takes them: by the order given, then as they were placed.
## A part that is not shown takes no room and is not one of them.
func _in_order() -> Array[Control]:
	return FlexLines.ordered(get_children(), _facts)


func _main(of: Vector2) -> float:
	return of.x if _direction == ROW else of.y


func _cross(of: Vector2) -> float:
	return of.y if _direction == ROW else of.x


func _vector(main: float, cross: float) -> Vector2:
	return Vector2(main, cross) if _direction == ROW else Vector2(cross, main)
