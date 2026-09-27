extends RefCounted

## The final length of every part on one line of a flex layout.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## CSS Flexible Box Layout Level 1, § 9.7 Resolving Flexible Lengths, followed
## step for step: decide from the room whether the line grows or shrinks; settle
## the parts that cannot flex; share what is free by factor; clamp each part by
## what it needs and what it allows; settle whatever the clamp moved the way the
## line is out; and go round again with what those parts could not take. It ends
## because every pass settles at least one part.
##
## A single pass is the tempting version and it is wrong: a part that reaches
## its most must hand the surplus back to the others, and only the going round
## again does that.
##
## A part's factor is read two ways, and they are not the same number. Factors
## under one between them take only that fraction of what was free at the
## start, and that rule reads the factors as they were given. What is free is
## then shared out by weight, and shrink is weighed by where each part started.
## Reading the weights for the rule is the easy mistake: shrinking parts weigh
## far more than one, so the rule never applies and they give up all of the
## shortfall when they were asked to give up only some of it.
##
## This is arithmetic and nothing else - no control, no rect, no engine. A part
## arrives as five numbers: where it starts, the least and the most it may be,
## and its two factors. That is what lets the specification's own worked cases
## be asserted here as numbers, rather than read back out of rectangles.
##
## Deliberately absent: it knows nothing of lines, wrapping or axes, so the
## layout above it decides which parts are on a line and which way the line
## runs, and asks this only how long each of them is.

## The length of each part, in the order the parts were given. A part is where
## it starts (base), the least and most it may be, and its grow and shrink

## Where parts sit along a line and across it - words the layout above
## (flex.gd) takes as its own.
const START := 0
const CENTER := 1
const END := 2
const BETWEEN := 3
const AROUND := 4
const EVENLY := 5
const STRETCH := 6

## factors. The gaps are the room the parts cannot have.
static func lengths(parts: Array, room: float, gaps: float) -> Array[float]:
	var length: Array[float] = []
	var frozen: Array[bool] = []
	var wanted := gaps
	# every part starts where it is told to, held within what it needs and allows
	for part: Dictionary in parts:
		length.append(held(part["base"], part))
		frozen.append(false)
		wanted += length[length.size() - 1]
	var growing := wanted < room
	# a part with no factor, or already past its start the way the line is going, cannot flex
	for at: int in parts.size():
		var factor: float = parts[at]["grow"] if growing else parts[at]["shrink"]
		var past: bool = parts[at]["base"] > length[at] if growing else parts[at]["base"] < length[at]
		frozen[at] = factor == 0.0 or past

	var first := true
	var free_at_first := 0.0
	# rounds of sharing out what is free and settling the parts their limits held, until none is loose
	while true:
		var loose := 0
		var factors := 0.0
		var weights := 0.0
		var free := room - gaps
		# the settled parts keep what they have; the rest are back at their start, their factors and weights counted
		for at: int in parts.size():
			if frozen[at]:
				free -= length[at]
			else:
				loose += 1
				free -= parts[at]["base"]
				factors += parts[at]["grow"] if growing else parts[at]["shrink"]
				weights += _weight_of(parts[at], growing)
		if loose == 0:
			return length
		if first:
			free_at_first = free
			first = false
		# factors under one between them take only that much of the room - the factors as given, never their weights
		if factors < 1.0 and absf(free_at_first * factors) < absf(free):
			free = free_at_first * factors
		var violation := 0.0
		var moved: Array[float] = []
		moved.resize(parts.size())
		# each loose part takes its share of what is free by its weight, then is held to its own limits
		for at: int in parts.size():
			if frozen[at]:
				continue
			var share: float = free * _weight_of(parts[at], growing) / weights if weights > 0.0 else 0.0
			var asked: float = parts[at]["base"] + share
			length[at] = held(asked, parts[at])
			moved[at] = length[at] - asked
			violation += moved[at]
		# the total says which way the line is out; only the parts the clamp moved that way settle
		for at: int in parts.size():
			var out_that_way: bool = moved[at] > 0.0 if violation > 0.0 else moved[at] < 0.0
			if not frozen[at] and (is_zero_approx(violation) or out_that_way):
				frozen[at] = true
	return length


## What a part's share of what is free is weighed by: its grow as it was given,
## and its shrink weighted by where it started, so a long part gives back more
## than a short one asked to give the same.
static func _weight_of(part: Dictionary, growing: bool) -> float:
	if growing:
		return part["grow"]
	return part["shrink"] * part["base"]


## A part's five numbers from the facts given for it (flex.gd's), the
## least it needs along the line and the room: where it starts - its basis
## of the room, else its least - the least and most it may be, and its grow
## and shrink, each the specification's default where none was given.
static func numbers(facts: Dictionary, least: float, room: float) -> Dictionary:
	return {
		"least": least,
		"most": facts.get("max", 1.0) * room,
		"base": facts["basis"] * room if facts.has("basis") else least,
		"grow": facts.get("grow", 0.0),
		"shrink": facts.get("shrink", 1.0),
	}


## A length held within what a part needs and what it allows, with what it needs
## applied LAST so that it wins - which the layout above uses too, so that one
## rule holds wherever a length is worked out: a part allowed less than it needs still gets
## what it needs, and the line overflows rather than the part being unreadable.
static func held(length: float, part: Dictionary) -> float:
	return maxf(minf(length, part["most"]), part["least"])


## Where the first part on a line starts and how far apart each two stand,
## from the room left once every part has its length - § 9.5 step 12,
## justify: [where the first starts, the room between each two].
static func spread(justify: int, spare: float, count: int, gap: float) -> Vector2:
	match justify:
		CENTER: return Vector2(spare / 2.0, gap)
		END: return Vector2(spare, gap)
		BETWEEN: return Vector2(0.0, gap + spare / maxf(count - 1, 1.0))
		AROUND: return Vector2(spare / count / 2.0, gap + spare / count)
		EVENLY: return Vector2(spare / (count + 1), gap + spare / (count + 1))
	return Vector2(0.0, gap)


## How far across its line a part sits from the line's near edge, by how it
## is aligned, the line this thick and the part that thick - § 9.6 step 14.
static func aligned(align: int, thickness: float, thick: float) -> float:
	match align:
		CENTER: return (thickness - thick) / 2.0
		END: return thickness - thick
	return 0.0
