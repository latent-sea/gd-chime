extends RefCounted

const Themes := preload("../../theme.gd")
const Ui := preload("../primitives/ui.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Phrase := preload("../../phrase.gd")
const Formats := preload("../../formats.gd")

## A cell readout: ONE value about one item, in the space of a cell. A
## QUANTITY in the product's unit of account - one mark, where the language
## puts it (formats.gd) - or drawn as a BAR on a logarithmic scale against an
## anchor; a LABEL; a TRACE of recent outcomes; a MARK with a count; and a
## RELATIVE value, which is a control as well as a readout and gets its own
## region.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Every one reads a bound value and states what is, never what will be; a
## figure and the relative's words go to the text as phrases, said in the
## language on as it draws. A bar and a trace are drawn on a canvas by this
## recipe's own painters, in the look's ink; a mark is a shape, never a
## colour, so it reads at a glance where the colour rules cannot.


## A quantity: the figure with its mark, grouped in thousands, as the
## language writes money, rolling up or down to a new figure rather than
## changing at once.
static func quantity(ui: Ui, value: Bound, mark: String, style: StringName = &"Quantity") -> Desc:
	var rolling: Bound = ui.eased(value.map(func(amount: Variant) -> Variant: return null if amount == null else float(amount)))
	return ui.text(Formats.money(rolling, mark), style)


## A quantity as a bar: its length the logarithm of the value against the
## logarithm of the anchor, the full end; it fills and empties to a new
## value rather than being there at once.
static func bar(ui: Ui, value: Bound, anchor: float, style: StringName = &"Bar") -> Desc:
	var share: Bound = value.map(func(amount: Variant) -> float: return 0.0 if amount == null or float(amount) <= 1.0 else clampf(log(float(amount)) / log(anchor), 0.0, 1.0))
	return ui.surface(style, [ui.canvas(_paint_bar, ui.eased(share), style)])


## A label: a short word marking what the item is.
static func label(ui: Ui, words: Bound, style: StringName = &"Label") -> Desc:
	return ui.text(words, style)


## A trace: a small line of recent outcomes, an array of numbers, so
## improving, declining or volatile reads at a glance.
static func trace(ui: Ui, outcomes: Bound, style: StringName = &"Trace") -> Desc:
	return ui.surface(style, [ui.canvas(_paint_trace, outcomes, style)])


## A mark with a count: that others have registered something, and how many.
static func mark(ui: Ui, count: Bound, shape: StringName = &"circle", style: StringName = &"Mark") -> Desc:
	var counted: Bound = Formats.number(count.map(func(number: Variant) -> Variant: return null if number == null or int(number) == 0 else number))
	return ui.row([ui.canvas(_paint_mark, count.map(func(number: Variant) -> Dictionary: return {"shape": shape, "any": number != null and int(number) > 0}), style).basis(0.3), ui.text(counted, Themes.REASON)], style)


## A relative value: the item against a selected subject, in words that
## say what it is the strength of, in a region of its own so the item's
## name still opens the item - a press of it is its own action.
static func relative(ui: Ui, action: StringName, strength: Bound, of_what: Variant) -> Desc:
	var style := &"Relative"
	return ui.pressable(action, {}, [ui.text(strength.map(func(value: Variant) -> Variant: return "" if value == null else Phrase.with("%s %d%%", [of_what, int(float(value) * 100.0)])), Themes.REASON)], style)


static func _paint_bar(control: Control, share: Variant) -> void:
	var width := control.size.x * float(share if share != null else 0.0)
	control.draw_rect(Rect2(Vector2.ZERO, Vector2(width, control.size.y)), control.get_theme_color(&"line"))


static func _paint_trace(control: Control, outcomes: Variant) -> void:
	if outcomes == null or outcomes.size() < 2:
		return
	var low: float = outcomes.min()
	var high: float = outcomes.max()
	var points := PackedVector2Array()
	for index: int in range(outcomes.size()):
		var x := control.size.x * float(index) / float(outcomes.size() - 1)
		var y := control.size.y * (1.0 - (float(outcomes[index]) - low) / maxf(high - low, 0.001))
		points.append(Vector2(x, y))
	control.draw_polyline(points, control.get_theme_color(&"line"), 2.0)


static func _paint_mark(control: Control, mark: Variant) -> void:
	if mark == null or not mark["any"]:
		return
	var centre := control.size / 2.0
	var radius := minf(control.size.x, control.size.y) * 0.4
	var ink := control.get_theme_color(&"line")
	match mark["shape"]:
		&"square": control.draw_rect(Rect2(centre - Vector2(radius, radius), Vector2(radius, radius) * 2.0), ink)
		&"diamond": control.draw_colored_polygon(PackedVector2Array([centre + Vector2(0, -radius), centre + Vector2(radius, 0), centre + Vector2(0, radius), centre + Vector2(-radius, 0)]), ink)
		_: control.draw_circle(centre, radius, ink)
