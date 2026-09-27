extends RefCounted

const Themes := preload("../../theme.gd")
const Driver := preload("../../driver.gd")
const Ui := preload("../primitives/ui.gd")
const Options := preload("../primitives/options.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Setting := preload("setting.gd")
const TypeAhead := preload("type_ahead.gd")
const Sheet := preload("sheet.gd")
const Fields := preload("../../theme_fields.gd")

## A combo: a closed field showing the current choice. Pressed, it opens
## the choosing in an overlay - a choice's short list (setting.gd), or a
## type-ahead for a long one - and picking closes the overlay, the field
## showing the new value.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## NEVER A DROPDOWN: a list that unrolls under a field is reached by the
## pointer and lost to a pad, so the choosing always stands in an overlay,
## where the keys and the pad reach every option and nothing beneath can be
## walked to while it is up. The overlay is a place beside the app, not a
## piece of a screen: it travels on the closed field (Desc.opens), and the
## builder lifts it there, so each form answers the one field.
##
## IT HOLDS NOTHING. What is chosen is the model's: the short list reads the
## options and the chosen value, the long one the words of what is chosen
## and a narrowing (narrowing.gd) over the options. A pick is the caller's
## action carrying {"value"}, through the door, going back as it is made -
## so a pick the door refuses leaves the overlay up, saying why on the
## option. Opening is a press that only goes somewhere, and needs no
## handler.
##
## It composes the pieces that exist and adds only its look: the closed
## field wears the combo's style, a variation of a pressable.

## What a long combo's pop-up is of, in its name.
const KIND := &"combo"


## A combo over a short list: a choice whose control wears the combo's
## look. Its options: offers, the bound list a reader picks from; chosen,
## a bound value reading which is picked; title, the words over the list;
## and style.
const OPTIONS: Array[String] = ["offers", "chosen", "title", Options.STYLE]

static func short(ui: Ui, action: StringName, opens: StringName, options: Dictionary = {}) -> Desc:
	Options.checked("a short combo", options, OPTIONS)
	var control := Setting.choice(ui, action, opens, {offers = options["offers"], chosen = options["chosen"], title = options["title"]})
	# the choice's control worn as a closed field, said on its description as a binding's rebinds is
	control.props["style"] = options.get(Options.STYLE, Fields.COMBO)
	return control


## A combo over a long list: the closed field wearing the chosen words, and
## an overlay of the title and a type-ahead over the narrowing, a pick going
## back. The type-ahead's options scroll, and a scroll needs no room of its
## own, so a sheet only as tall as what it holds would show none of them:
## this sheet is as tall as the look's share of the window (TALL, under
## COMBO), stood in the middle of it, the options taking what the title and
## the line leave. The share is read from the look on the window as the
## overlay is described.
## Its options: narrowing, the model the type-ahead narrows; types, the
## action a keystroke in it goes to; title, the words over the list;
## payload, what a pick carries beside its value; and style.
const LONG_OPTIONS: Array[String] = ["narrowing", "types", "title", Options.PAYLOAD, Options.STYLE]

static func long(ui: Ui, action: StringName, opens: StringName, shown: Bound, options: Dictionary = {}) -> Desc:
	Options.checked("a long combo", options, LONG_OPTIONS)
	var title: Variant = options["title"]
	var picker := TypeAhead.make(ui, options["narrowing"], options["types"], action, {then = Driver.BACK, payload = options.get(Options.PAYLOAD, {})})
	var tall: float = ui.root.get_theme_constant(Fields.TALL, Fields.COMBO) / 1000.0
	# the sheet the look's share of the window tall, as wide as a sheet is
	var overlay := ui.pop_up(KIND, func(_which: Bound) -> Desc: return Sheet.tall(ui, [ui.text(title, Themes.FACE), picker.grow()], Setting.SHEET, {wide = Sheet.SHARE, high = tall}))
	return ui.pressable(opens, {}, [ui.text(shown, Themes.FACE)], options.get(Options.STYLE, Fields.COMBO)).opens(overlay)
