extends "res://demo/gallery/boxes.gd"

const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Stepper := preload("res://addons/gd_chime/components/recipes/stepper.gd")
const Combo := preload("res://addons/gd_chime/components/recipes/combo.gd")
const InlineChoice := preload("res://addons/gd_chime/components/recipes/inline_choice.gd")
const Values := preload("res://demo/gallery/values_models.gd")

## The controls that set a value, on a screen of the gallery's own (VALUES):
## a slider, a number stepper, a combo over a short list and one over a long
## list, a radio group and a segmented control - every one over the one order
## of crates (values_models.gd), and every one refused somewhere by the door.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The slider is how full a crate is, and a crate filled past eight tenths is
## refused, the reason under its track. The stepper is how many crates, and
## the stall never stacks thirteen, so its + is inert at twelve. The short
## combo and the radio group choose the same size - one model answering both,
## so each shows the other's choice - and there are no large crates today. The
## long combo narrows the fruit by typing. The segmented control switches the
## view under it between the order and its price, a local of the interface's
## own that no door is asked about.
##
## The combos' two overlays - the sizes and the fruit - travel on the combos
## and the builder lifts them over the app, as every overlay is. Nothing here
## opens under a field.

## The screen.
const VALUES := &"values"
## The action that shows the screen, and the two that open the overlays.
const SHOWS_VALUES := &"shows_the_values"
const OPENS_SIZES := &"opens_the_sizes"
const OPENS_FRUIT := &"opens_the_fruit"
## The two views the segmented control switches between.
const ORDER_VIEW := &"order"
const PRICE_VIEW := &"price"
## What a crate costs, in coins, for the price view.
const PRICE := 40
## The words of this screen's actions, for the gallery's register.
const ACTIONS := {SHOWS_VALUES: ["Numbers and choices"], OPENS_SIZES: ["Choose a size"], OPENS_FRUIT: ["Choose a fruit"], Values.Order.SETS_CRATES: ["Set the crates"], Values.Order.SETS_FILL: ["Fill the crate"], Values.Order.PICKS_SIZE: ["This size"], Values.Order.PICKS_FRUIT: ["This fruit"], Values.Order.TYPES_FRUIT: ["Find a fruit"]}

var _screen: Desc


func _init(stall: SceneTree) -> void:
	super(stall)
	_screen = _values()


func screen() -> Desc:
	return _screen


func _values() -> Desc:
	var ui: RefCounted = _stall.ui
	var order: Values.Order = _stall.order
	var slider: Desc = ui.slider(Values.Order.SETS_FILL, ui.bound(order.get_fill), {minimum = 0.0, maximum = 1.0, step = 0.1}).named(&"fill")
	var stepper: Desc = Stepper.make(ui, Values.Order.SETS_CRATES, ui.bound(order.get_crates), {minimum = 0.0, maximum = 20.0, step = 1.0}).named(&"crates")
	var short := Combo.short(ui, Values.Order.PICKS_SIZE, OPENS_SIZES, {offers = ui.bound(order.get_sizes), chosen = ui.bound(order.get_size), title = Phrase.of("Which size?")})
	var long := Combo.long(ui, Values.Order.PICKS_FRUIT, OPENS_FRUIT, ui.bound(order.get_fruit), {narrowing = order.narrowing, types = Values.Order.TYPES_FRUIT, title = Phrase.of("Which fruit?")})
	var radios: Desc = InlineChoice.radios(ui, Values.Order.PICKS_SIZE, ui.bound(order.get_sizes), ui.bound(order.get_size)).named(&"radios")
	var view: RefCounted = ui.local(ORDER_VIEW)
	var views := [{"value": ORDER_VIEW, "words": Phrase.of("The order")}, {"value": PRICE_VIEW, "words": Phrase.of("Its price")}]
	var segments: Desc = InlineChoice.segments(ui, view, Bound.new(func() -> Array: return views)).named(&"segments")
	var crates: Bound = ui.bound(order.get_crates)
	# the size's own words, from the options the size is chosen from
	var sized: Bound = ui.bound(order.get_size).map(func(size: StringName) -> Phrase: return order.get_sizes().filter(func(one: Dictionary) -> bool: return one["value"] == size)[0]["words"])
	# the order in words: how many crates of which fruit, what size and how full
	var ordered: Bound = Bound.all([crates, ui.bound(order.get_fruit), sized, ui.bound(order.get_fill)], func(many: float, fruit: String, size: Phrase, fill: float) -> Phrase: return Phrase.with("%d crates of %s, %s, each filled to %d per cent", [roundi(many), fruit, size, roundi(fill * 100.0)]))
	var priced: Bound = crates.map(func(many: float) -> Phrase: return Phrase.with("%d crates at %d coins: %d coins", [roundi(many), PRICE, roundi(many) * PRICE]))
	# the view the segments chose, re-read as the local moves
	var viewing: Desc = ui.when(view.map(func(now: StringName) -> bool: return now == ORDER_VIEW), ui.text(ordered, DemoTheme.READOUT).wraps(), ui.text(priced, DemoTheme.READOUT).wraps())
	var first := [
		_shown(Phrase.of("Slider"), Phrase.of("Drag it, or left and right; past eight tenths is refused"), slider),
		_shown(Phrase.of("Number stepper"), Phrase.of("− and +, or type and Enter; thirteen is refused"), stepper),
		_shown(Phrase.of("Combo, short list"), Phrase.of("The sizes open over everything; large is refused"), short.named(&"size combo")),
		_shown(Phrase.of("Combo, long list"), Phrase.of("Type to narrow the fruit, then pick one"), long.named(&"fruit combo")),
	]
	var second := [
		_shown(Phrase.of("Radio group"), Phrase.of("The same size, chosen in place; large is refused"), radios),
		_shown(Phrase.of("Segmented control"), Phrase.of("Switches the view between the order and its price"), ui.column([segments, viewing], DemoTheme.TIGHT)),
	]
	return _columns(VALUES, first, second)
