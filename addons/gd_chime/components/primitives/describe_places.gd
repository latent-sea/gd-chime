extends "describe_shell.gd"

const Pressables := preload("../../theme_pressables.gd")

## The descriptions of the places: the app, a screen, a set of tabs, a
## pop-up - and the panel, a pop-up that blocks nothing - and the button,
## which may open a pop-up as one of its kind.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The rest of the vocabulary is describe.gd's, describe_inputs.gd's,
## describe_forms.gd's and describe_shell.gd's, which this extends and the builder (ui.gd) extends in
## turn; the places stand apart because they are
## the one kind of description that is also somewhere the reader can BE:
## each becomes a place (place.gd) with a name the chart knows, declaring
## what the pressables inside it perform (place_builder.gd). PLACES is how
## anything walking a description knows to stop at one.
##
## A POP-UP IS DESCRIBED WHERE IT IS USED - beside the button opening it,
## inside the screen asking it, among what it stands over - and the builder
## lifts it beside the app by itself (ui.gd), so no application carries its
## pop-ups anywhere. ITS NAME IS THE BUILDER'S: its kind and how many of
## that kind were described before it, so two of one kind never collide and
## no application names one. ITS CONTENT IS A FUNCTION of which one of its
## kind it is entered as - its parameter, handed in as a bound value - so
## nothing reads the driver by hand to know; it is CALLED AS THE POP-UP IS
## LIFTED, not as it is described, in the pop-up's own place wearing the
## look it was described inside (place_builder.gd), so what the content
## reads of the look - a share of the window - is that place's (current_place()).
## EVERY POP-UP OWNS ITS WAY OUT:
## CLOSES, declared by the builder once with its words and its inputs, and
## declared by every pop-up's place going back (place_builder.gd). One
## described inside a template would be described again for every item, and
## is refused out loud: a pop-up is described once and opened with the item.

const APP := &"app"
const SCREEN := &"screen"
const TABS := &"tabs"
const POP_UP := &"pop_up"
const PLACES: Array[StringName] = [APP, SCREEN, TABS, POP_UP]
## The press every pop-up is closed by, going back: its words and its inputs are the builder's.
const CLOSES := &"closes_the_overlay"
## What a button may be told, each a key of its options (options.gd): the
## pop-up it opens and which one of that pop-up's kind, the place it goes
## to, what it carries there, what stands on its face over its words, and
## the style it wears.
const BUTTON_OPTIONS: Array[String] = [Options.OPENS, Options.WITH, Options.GOES_TO, Options.PAYLOAD, "content", Options.STYLE]

var _issued: Dictionary = {}  # a pop-up's kind -> how many of it were described
var _templates_running: int = 0  # how many templates are being described now, one inside another


## The one place every other stands inside, its actions answered by this
## model - or by each of these models, as a screen's are.
func app(named: StringName, content: Array, handled_by: Variant = null) -> Desc:
	return Desc.new(APP, {"name": named, "handled_by": handled_by, "blocks": true}, content)


## A place that takes its siblings' place, its actions answered by this
## model - or by each of these models, the first of them answering for the
## place itself. Its options: on_fill, done as it fills, given the token of
## the stay; on_empty, done as it empties; and asks_before_leaving, a pop-up
## put to the reader before they go, while the model refuses the leaving
## (leave_guard.gd) - none, and it never asks.
const SCREEN_OPTIONS: Array[String] = ["on_fill", "on_empty", "asks_before_leaving"]

func screen(named: StringName, content: Array, handled_by: Variant = null, options: Dictionary = {}) -> Desc:
	Options.checked("a screen", options, SCREEN_OPTIONS)
	return Desc.new(SCREEN, {"name": named, "handled_by": handled_by, "blocks": true, "on_fill": options.get("on_fill", Callable()), "on_empty": options.get("on_empty", Callable()), "overlay": options.get("asks_before_leaving")}, content)


## A screen whose content holds screens that take each other's place.
func tabs(named: StringName, content: Array, handled_by: Variant = null) -> Desc:
	return Desc.new(TABS, {"name": named, "handled_by": handled_by, "blocks": true}, content)


## WHAT A PLACE IS ENTERED AS, as a bound value: the parameter the reader
## arrived by, nothing while they are not there, read again on every move. A
## pop-up's content is handed its own and needs none of this; a screen, and
## anything reading which one of a kind is open, asks for it by name.
func parameter(place: StringName) -> Bound:
	return Bound.new(func() -> Variant: return driver.get_parameter(place))


## A place beside the app, raised over it, of this kind: what content
## answers for the parameter it is entered as - a bound value reading it,
## nothing while it is down - its actions answered by this model. It blocks
## everything beneath; chain blocks_nothing for a panel, which the reader
## may keep open while working under it (desc.gd).
func pop_up(kind: StringName, content: Callable, handled_by: Variant = null) -> Desc:
	if _templates_running > 0:
		push_error("a %s was described inside a template; describe it once, outside, and open it with the item" % kind)
	_issued[kind] = _issued.get(kind, 0) + 1
	# its name: the kind, and how many of that kind were described before it, so two of one kind never collide
	var named := StringName("%s %d" % [kind, _issued[kind]])
	return Desc.new(POP_UP, {"name": named, "handled_by": handled_by, "blocks": true, "content": content})


## What a template describes for a handle, the handle guarded meanwhile and
## the template counted running, so a pop-up described inside it is refused.
func describe_with(template: Callable, handle: Bound) -> Desc:
	handle.set_template_running(true)
	_templates_running += 1
	var desc: Desc = template.call(handle)
	_templates_running -= 1
	handle.set_template_running(false)
	if desc == null:
		push_error("a template described nothing for %s; a template must cope with an empty handle" % [handle.read()])
	return desc


## THE COMMON BUTTON: a press of this action, saying the register's words
## for it over why it cannot be used - on its face rather than in a
## tooltip, since a tooltip needs a pointer and a d-pad never hovers. A
## press wanting content of its own is a pressable, not this. Its options:
## the pop-up it opens and which one of that pop-up's kind, a value or a
## bound value read as the press lands; or the place it goes to and what it
## carries there; content standing over its words; and its style.
func button(action: StringName, options: Dictionary = {}) -> Desc:
	Options.checked("a button", options, BUTTON_OPTIONS)
	var with: Variant = options.get(Options.WITH)
	# which one of the pop-up's kind it opens, carried as the press's parameter: read as the press lands where it is a bound value
	var opening: Variant = with.map(func(which: Variant) -> Dictionary: return {} if which == null else {"parameter": which}) if with is Bound else {} if with == null else {"parameter": with}
	var carried: Variant = options.get(Options.PAYLOAD, opening)
	var inside: Array = options.get("content", []) + [text(words(action), Themes.FACE), reason(Themes.REASON)]
	var made := pressable(action, carried, [column(inside, Themes.COLUMN)], options.get(Options.STYLE, Pressables.BUTTON))
	if options.has(Options.GOES_TO):
		made.goes_to(options[Options.GOES_TO])
	return made.opens(options[Options.OPENS]) if options.has(Options.OPENS) else made
