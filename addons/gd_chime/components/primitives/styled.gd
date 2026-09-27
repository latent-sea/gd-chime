extends RefCounted

const Bound := preload("bound.gd")

## A style given to a primitive: a Theme name, or a BOUND VALUE reading
## one, so a look that follows a value - a cell past a threshold, a toggle
## turned on - is a name re-read as the value moves and worn in place,
## never a piece built again.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A text, a surface and a pressable take either. The one question they ask
## of what they were given is the name it says now, asked as they draw, so
## what a bound style read is followed with the rest of the draw.


## The Theme name this style says now; none for a bound value reading nothing.
static func name_of(style: Variant) -> StringName:
	if style is Bound:
		var said: Variant = (style as Bound).read()
		return &"" if said == null else StringName(said)
	return style
