extends RefCounted

## The shape a save must have, declared once, and what makes plain data read
## back not that shape, in words - for every model that keeps itself between
## runs (settings_file.gd): the panels, the documents open, the key
## bindings, an application's own.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## WHAT COMES BACK OFF A DISK IS NOT OURS. A save may be hand-edited, half
## written or from another build, so a model takes one back only WHOLE:
## checked against its shape before any of it is used, and refused out loud
## - what stands kept - at the first thing that is not so. A model declares
## its shape from the pieces here and asks refused() once, at the top of its
## restore(); it never writes the checks by hand.
##
## A SHAPE IS A FUNCTION from a value to why it is not that shape - words
## for the developer's stream, naming where in the save - or nothing when it
## is. The pieces are the plain data a text holds: WORDS, a NUMBER (a whole
## one read back from text is a float), a FRACTION, ONE_OF some values; a
## thing or null (MAYBE); a LIST of one shape; a map whose every key and
## value has a shape each (KEYED); a RECORD of named fields, no more and no
## fewer; EITHER of some shapes; and SUCH_THAT, a shape and a rule over the
## whole of it - an open document that must be one the catalogue has.
##
## It holds nothing and reads no file; what a value means once it fits is
## the model's.


## Words: a string.
static func words() -> Callable:
	return func(value: Variant) -> String: return "" if value is String else "%s is not words" % [value]


## A number: a whole one or a fraction, as a text gives either back.
static func number() -> Callable:
	return func(value: Variant) -> String: return "" if value is int or value is float else "%s is not a number" % [value]


## A number from nothing to all: a share.
static func fraction() -> Callable:
	return func(value: Variant) -> String: return "" if (value is int or value is float) and value >= 0.0 and value <= 1.0 else "%s is no fraction" % [value]


## One of these values.
static func one_of(values: Array) -> Callable:
	return func(value: Variant) -> String: return "" if values.has(value) else "%s is none of %s" % [value, values]


## Null, or a value of this shape.
static func maybe(shape: Callable) -> Callable:
	return func(value: Variant) -> String: return "" if value == null else shape.call(value)


## A list, every item of this shape.
static func list_of(shape: Callable) -> Callable:
	return func(value: Variant) -> String:
		if not value is Array:
			return "%s is not a list" % [value]
		# every item, for the first that is not the shape
		for at: int in (value as Array).size():
			var why: String = shape.call(value[at])
			if why != "":
				return "item %d: %s" % [at, why]
		return ""


## A map: every key of the one shape and every value of the other.
static func keyed(key: Callable, each: Callable) -> Callable:
	return func(value: Variant) -> String:
		if not value is Dictionary:
			return "%s is not a map" % [value]
		# every entry, its key and then its value
		for named: Variant in value:
			var why: String = key.call(named)
			if why == "":
				why = each.call(value[named])
			if why != "":
				return "%s: %s" % [named, why]
		return ""


## A record: these fields and no others, each of its own shape.
static func record(fields: Dictionary) -> Callable:
	return func(value: Variant) -> String:
		if not value is Dictionary:
			return "%s is not a record" % [value]
		if (value as Dictionary).size() != fields.size():
			return "%s are not the fields %s" % [(value as Dictionary).keys(), fields.keys()]
		# every field declared, there and of its shape
		for field: String in fields:
			if not (value as Dictionary).has(field):
				return "it has no %s" % field
			var why: String = fields[field].call(value[field])
			if why != "":
				return "%s: %s" % [field, why]
		return ""


## Of one of these shapes: the first that fits.
static func either(shapes: Array) -> Callable:
	return func(value: Variant) -> String: return "" if shapes.any(func(shape: Callable) -> bool: return shape.call(value) == "") else "%s is of none of the shapes it may be" % [value]


## Of this shape, and true of this rule, which is asked only of a value
## that fits - said in these words where it is not.
static func such_that(shape: Callable, rule: Callable, why_not: String) -> Callable:
	return func(value: Variant) -> String:
		var why: String = shape.call(value)
		if why != "":
			return why
		return "" if rule.call(value) else why_not


## Whether a save read back is refused: not of this shape, it is said out
## loud - not what, and why - for whoever restores it to keep what stands.
static func refused(shape: Callable, save: Dictionary, what: String) -> bool:
	var why: String = shape.call(save)
	if why != "":
		push_error("what was saved is not %s (%s); what stands is kept" % [what, why])
	return why != ""
