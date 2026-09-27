extends RefCounted

const Themes := preload("../../theme.gd")
const Ui := preload("../primitives/ui.gd")
const Options := preload("../primitives/options.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Phrase := preload("../../phrase.gd")
const Fields := preload("../../theme_fields.gd")

## A chip: short words that are toggled on their body, and - given a remove -
## removed on the x beside them.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Both are pressables, carrying the one payload given - which chip, as a
## dictionary or a bound value read as the press lands - through the door,
## so whether a chip can be toggled or removed is the model's refusal and
## the face shows it. Whether it is on is the model's too, read through a
## bound value: a chip that is off says its words in brackets, so which
## chips are on is read in the words themselves and never in a colour
## alone. The words are a phrase, data, or a bound value reading either,
## said as a text says them; the x is a mark, the same in every language.
##
## It holds nothing of its own: toggling and removing are the model's
## commands, and the chip is drawn again as the model moves.


## A chip of these words, on while the bound value holds, carrying this
## payload: its body toggles it, and its x - where a remove is given -
## removes it.
## Its options: toggles, the action its body presses; removes, the action
## its x presses, none and it has no x; and style.
const OPTIONS: Array[String] = ["toggles", "removes", Options.STYLE]

static func make(ui: Ui, words: Variant, on: Bound, payload: Variant, options: Dictionary = {}) -> Desc:
	Options.checked("a chip", options, OPTIONS)
	var toggles: StringName = options["toggles"]
	var removes: StringName = options.get("removes", &"")
	var style: StringName = options.get(Options.STYLE, Fields.CHIP)
	var worded: Bound = words if words is Bound else Bound.new(func() -> Variant: return words)
	# the words as they are while it is on, in brackets while it is off
	var said := Bound.all([worded, on], func(shown: Variant, is_on: Variant) -> Variant: return null if shown == null else shown if is_on else Phrase.joined(["(", shown, ")"]))
	var parts: Array = [ui.pressable(toggles, payload, [ui.text(said, Themes.REASON)], style)]
	if removes != &"":
		parts.append(ui.pressable(removes, payload, [ui.text("x", Themes.REASON)], style))
	return ui.row(parts)
