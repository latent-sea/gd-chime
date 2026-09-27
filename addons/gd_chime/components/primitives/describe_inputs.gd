extends "describe_values.gd"

const Formats := preload("../../formats.gd")
const Themes := preload("../../theme.gd")
const Pull := preload("pull.gd")
const Fields := preload("../../theme_fields.gd")

## The descriptions of what the reader puts in: a thing carried and where it
## drops, a typed line, words over many lines, a binding, a value along a
## track.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The rest of the vocabulary is describe.gd's and describe_values.gd's, which this extends;
## describe_forms.gd extends this, describe_shell.gd that, describe_places.gd
## that, and the builder (ui.gd) that in turn.
## These stand apart because each is more than a press: it holds what the
## reader is putting in - a carried payload, a line, an input, a value - and
## hands it to its action through the door, each an action its place
## declares (place_builder.gd).


## Something the reader can pick up and carry somewhere else, holding this
## payload - a dictionary, or a bound value read as the lift lands - and,
## given an action, dispatching it with the payload when clicked.
func draggable(payload: Variant, content: Array = [], style: Variant = &"Pressable", presses: StringName = &"") -> Desc:
	return Desc.new(&"draggable", {"carried": carried, "payload": payload, "style": style, "presses": presses}, content)


## Somewhere a carried thing can be dropped: a drop dispatches this action,
## one of its place's, with whatever was dropped on it - and, standing for
## the list into names, shown by the keyed each inside it, with {into, at}:
## where among that list it landed.
func drop_target(action: StringName, content: Array = [], style: Variant = &"Pressable", into: Variant = null) -> Desc:
	return Desc.new(&"drop_target", {"carried": carried, "action": action, "style": style, "into": into}, content)


## A line typed and dispatched as the action. Chain takes_focus for one
## that is typed into as it is built. Its options (field.gd): changes, the
## action every keystroke goes to; shows, a bound value it holds; carries,
## what a dispatch carries besides the line; leaves, the action a move away
## goes to; and refused, a local keeping its refusal in place of its reason
## under it.
const FIELD_OPTIONS: Array[String] = ["changes", "shows", "carries", "leaves", "refused"]

func field(action: StringName, style: StringName = &"", options: Dictionary = {}) -> Desc:
	Options.checked("a line", options, FIELD_OPTIONS)
	return Desc.new(&"field", {"action": action, "style": style, "takes_focus": false, "changes": options.get("changes", &""), "shows": options.get("shows"), "carries": options.get("carries", Callable()), "leaves": options.get("leaves", &""), "refused": options.get("refused")})


## Words typed over many lines, every change dispatched as the action, the
## area showing this bound value. Chain takes_focus to type into it at once.
func area(action: StringName, shows: Bound, style: StringName = &"TextArea") -> Desc:
	return Desc.new(&"area", {"action": action, "shows": shows, "style": style, "takes_focus": false})


## A binding: pressed, it listens for the next key or button and hands it
## to the action; at rest it shows this bound value, listening these words -
## a phrase.
func key_capture(action: StringName, shown: Bound, asks: Variant, style: StringName = &"Binding") -> Desc:
	return Desc.new(&"key_capture", {"action": action, "shown": shown, "asks": asks, "style": style})


## A value along a track (slider.gd), each change the action carrying
## {"value"}: the value's words beside it, written to as many places as the
## step has, and its reason under it. A drag holds the value under the
## pointer in a local of its own, and the words and the handle show that
## until the release sends it. Its options are the track: minimum, maximum
## and step, and style.
const TRACK_OPTIONS: Array[String] = ["minimum", "maximum", "step", Options.STYLE]

func slider(action: StringName, value: Bound, options: Dictionary = {}) -> Desc:
	Options.checked("a slider", options, TRACK_OPTIONS)
	var minimum: float = options["minimum"]
	var maximum: float = options["maximum"]
	var step: float = options["step"]
	var style: StringName = options.get(Options.STYLE, Fields.SLIDER)
	var held := local(null)
	# what it shows: the value a drag holds under the pointer, else the model's
	var shown: Bound = Bound.both(held, value, func(dragged: Variant, now: Variant) -> Variant: return now if dragged == null else dragged)
	var words := text(Formats.number(shown, step_decimals(step)), Themes.FACE)
	return Desc.new(&"slider", {"action": action, "value": value, "held": held, "shown": shown, "minimum": minimum, "maximum": maximum, "step": step, "style": style}, [words, reason(Themes.REASON)])


## A row a finger swipes (swipe.gd): tapped, a press of this action with
## this payload. Its options, the first two required, since a row swiped to
## nothing is a pressable: sides, {Swipe.RIGHT: action, Swipe.LEFT:
## action}, dispatched when the row is drawn across and let go past the
## look's share, with the same payload; reveals, {side: description} for
## every side, standing where the row slid from; style; and goes_to, where
## the tap goes. Its place declares every one of them.
const SWIPE_OPTIONS: Array[String] = ["sides", "reveals", Options.STYLE, Options.GOES_TO]

func swipe(action: StringName, payload: Variant, content: Desc, options: Dictionary) -> Desc:
	Options.checked("a swiped row", options, SWIPE_OPTIONS)
	var sides: Dictionary = options["sides"]
	var reveals: Dictionary = options["reveals"]
	var style: Variant = options.get(Options.STYLE, &"Pressable")
	var declares := {action: options.get(Options.GOES_TO, &"")}
	# every side's action, done where the row stands
	for side: StringName in sides:
		declares[sides[side]] = &""
	return Desc.new(&"swipe", {"action": action, "payload": payload, "sides": sides, "style": style, "declares": declares}, [content] + sides.keys().map(func(side: StringName) -> Desc: return reveals[side]))


## Pull to refresh (pull.gd): what it holds in a scroll running down, which a
## finger drawn down past its top opens over the indicator - described by
## the function given the pull's phase, a bound value - and let go far enough
## dispatches the action; open while the refresh is on its way, a bound value.
func pull(action: StringName, refreshing: Bound, indicator: Callable, content: Desc) -> Desc:
	var phase := local(Pull.RESTING)
	return Desc.new(&"pull", {"action": action, "phase": phase, "refreshing": refreshing, "declares": {action: &""}}, [indicator.call(phase), scroll(content, null, &"down")])


## A stretch between two ends along a track (range_slider.gd), each change
## the action carrying {"value": Vector2(least, most)}: the stretch's words
## beside it, as the caller's words function writes a Vector2, which end the
## keys move said under it, and its reason under that. A drag holds the
## stretch under the pointer in a local of its own until the release sends
## it. Its options are the slider's, and words.
const STRETCH_OPTIONS: Array[String] = ["minimum", "maximum", "step", "words", Options.STYLE]

func range_slider(action: StringName, value: Bound, options: Dictionary = {}) -> Desc:
	Options.checked("a stretch", options, STRETCH_OPTIONS)
	var minimum: float = options["minimum"]
	var maximum: float = options["maximum"]
	var step: float = options["step"]
	var words: Callable = options["words"]
	var style: StringName = options.get(Options.STYLE, Fields.SLIDER)
	var held := local(null)
	var moving := local(0)
	# what it shows: the stretch a drag holds under the pointer, else the model's
	var shown: Bound = Bound.both(held, value, func(dragged: Variant, now: Variant) -> Variant: return now if dragged == null else dragged)
	var says := text(moving.map(func(end: int) -> Phrase: return Phrase.of("The keys move the least" if end == 0 else "The keys move the most")), Themes.REASON)
	return Desc.new(&"range_slider", {"action": action, "value": value, "held": held, "moving": moving, "shown": shown, "minimum": minimum, "maximum": maximum, "step": step, "style": style}, [text(shown.map(words), Themes.FACE), says, reason(Themes.REASON)])
