extends RefCounted

const Themes := preload("../../theme.gd")
const Ui := preload("../primitives/ui.gd")
const Options := preload("../primitives/options.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Fields := preload("../../theme_fields.gd")

## A number stepper: a number with a minus before it and a plus after it,
## typed or stepped, between a minimum and a maximum by a step.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## PLAIN NUMBERS ONLY: an amount of money being committed is amount_field's,
## and stays so.
##
## IT HOLDS NOTHING OF ITS OWN. The number is the model's, a bound value the field
## shows; every change is the action carrying {"value"} through the door -
## the payload the slider and a choice carry, so one model answers all
## three. The minus and the plus carry the number a step down and a step up,
## and Enter in the field carries the number typed (field.gd's carries);
## each is snapped to the step from the minimum and held between the ends,
## so the door is never asked for a number past either - at an end, the
## press carries the end. A line that is no number carries the number as it
## stands. The door may refuse any of them, and the model's answer is what
## the field shows, to as many places as the step has - written plainly,
## with the point typing reads back, since it is the line being edited.
##
## Three controls in a row, walked by the keys and the pad as any row is.
## The marks are data, the same in every language.
##
## THE STEPS ARE THE PIECE, and the number's field is what this puts between
## them: steps() is the pair on its own, for a basket line taking one more
## and a day stepped on, which wrote the minus and the plus out by hand.
##
## Deliberately absent: a press that repeats while held, whose wait and
## pace no look has decided yet.

const DOWN := "−"
const UP := "+"


## THE STEPS ALONE: a step down and a step up, around whatever stands
## between them, each press carrying what a press worth that much carries -
## the number a step away here, a basket line's id and one more elsewhere.
## Its options: shows, the description between the two - none, and they
## stand side by side; carries, a function of how far this press moves,
## answering what it carries, a dictionary or a bound value; step, how much
## one press is worth; and style.
const STEPS_OPTIONS: Array[String] = ["shows", "carries", "step", Options.STYLE]

static func steps(ui: Ui, action: StringName, options: Dictionary = {}) -> Desc:
	Options.checked("a stepper's steps", options, STEPS_OPTIONS)
	var carries: Callable = options["carries"]
	var step: float = options.get("step", 1.0)
	var between: Array = [options["shows"]] if options.has("shows") else []
	return ui.row([ui.pressable(action, carries.call(-step), [ui.text(DOWN, Themes.FACE)])] + between + [ui.pressable(action, carries.call(step), [ui.text(UP, Themes.FACE)])], options.get(Options.STYLE, Fields.STEPPER))


## The row: the minus, the number's field and the plus, each changing the number through the door.
## Its options are the track - minimum, maximum and step - and style.
const OPTIONS: Array[String] = ["minimum", "maximum", "step", Options.STYLE]

static func make(ui: Ui, action: StringName, value: Bound, options: Dictionary = {}) -> Desc:
	Options.checked("a stepper", options, OPTIONS)
	var minimum: float = options["minimum"]
	var maximum: float = options["maximum"]
	var step: float = options["step"]
	var typed := func(line: String) -> Dictionary: return {"value": held(line.to_float(), minimum, maximum, step) if line.is_valid_float() else value.read()}
	var shown: Bound = value.map(func(now: Variant) -> String: return String.num(float(now), step_decimals(step)))
	var number := ui.field(action, Fields.FIELD, {"shows": shown, "carries": typed})
	var away := func(by: float) -> Bound: return value.map(func(now: Variant) -> Dictionary: return {"value": held(float(now) + by, minimum, maximum, step)})
	return steps(ui, action, {shows = number.grow(), carries = away, step = step, style = options.get(Options.STYLE, Fields.STEPPER)})


## A number snapped to the step from the minimum, and held between the ends.
static func held(number: float, minimum: float, maximum: float, step: float) -> float:
	return clampf(minimum + snappedf(number - minimum, step), minimum, maximum)
