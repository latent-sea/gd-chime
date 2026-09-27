extends "describe_escapes.gd"

## The descriptions that arrange the same parts differently: by the shape of
## the window, and by the width the thing itself has - and the two ways an
## arrangement is said, a row of these parts or a column of them.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The rest of the vocabulary is describe.gd's, which this extends and the
## builder (ui.gd) extends in turn. These stand apart because they are the
## one kind of description that does not say what a thing IS: the parts are
## described once, and these say only where each stands while the window is
## this shape or that.
##
## AN ARRANGEMENT IS NEVER WRITTEN AS A DICTIONARY. row_of and column_of are
## the only two things that make one, so nothing outside has to know that
## "down" means a column, nor name every part in "order" and again in
## "facts" - the order is the parts named, and a part with no facts is
## simply left out of them. What comes back is the arrangement by_shape and
## by_width take; it is not a shape anything writes by hand. The facts
## themselves are the line layout's own - order, basis, grow, shrink, max,
## align (flex.gd) - and a word it has no meaning for is said out loud as
## the arrangement is worn (by_shape.gd).


## The parts named, in the order they stand along a row, and the line
## layout's facts for the ones that have any - a part left out of them
## takes its own length.
func row_of(order: Array, facts: Dictionary = {}, style: StringName = &"Row") -> Dictionary:
	return _arrangement(false, order, facts, style)


## The same, standing one under another down a column.
func column_of(order: Array, facts: Dictionary = {}, style: StringName = &"Column") -> Dictionary:
	return _arrangement(true, order, facts, style)


## One arrangement as by_shape wears it: which way the line runs, its style,
## the order, and a fact dictionary with an entry for every part named.
func _arrangement(down: bool, order: Array, facts: Dictionary, style: StringName) -> Dictionary:
	var given: Dictionary = {}
	# every part named in the order, given its facts or none
	for part: StringName in order:
		given[part] = facts.get(part, {})
	return {"down": down, "style": style, "order": order, "facts": given}


## The same parts, built once, arranged differently by the shape of the
## window: {name: description}, and one arrangement - row_of or column_of -
## per value read: portrait and landscape, the window's orientation, unless
## another bound value is given - shape.size_class.
## Only the arrangement ever changes, so state and focus are kept.
func by_shape(parts: Dictionary, arrangements: Dictionary, reads: Bound = null) -> Desc:
	return Desc.new(&"by_shape", {"names": parts.keys(), "arrangements": arrangements, "reads": shape.orientation if reads == null else reads}, parts.values())


## The same, by the width THIS has rather than the window's: one breakpoint
## per arrangement, a share of the base width or a look's constant under
## Shape, one of them 0.0.
func by_width(parts: Dictionary, arrangements: Dictionary, breakpoints: Dictionary) -> Desc:
	return Desc.new(&"by_width", {"names": parts.keys(), "arrangements": arrangements, "breakpoints": breakpoints}, parts.values())
