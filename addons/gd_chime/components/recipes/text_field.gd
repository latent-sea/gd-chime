extends RefCounted

const Themes := preload("../../theme.gd")
const Ui := preload("../primitives/ui.gd")
const Options := preload("../primitives/options.gd")
const Desc := preload("../primitives/desc.gd")
const Phrase := preload("../../phrase.gd")

## A text field: a named line of words - what a thing is called - under its
## label, beside amount_field.gd, which is the same shape for a sum. The
## line always shows the words the model holds, so Enter leaves it as it
## stands and the model's answer is what is read back.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The MODEL holds the words, decides whether a line is acceptable, and
## keeps the last refusal; the RECIPE shows the label, what the field is
## for, the held words, and the refusal under the line. A model that says
## no answers would() with a sentence and offers that sentence as a read
## the caller binds in as the refusal option - a refusal is words about the
## line just typed, not a fact about a pressable, so it is shown here
## rather than through a reason. The label and what the field is for go to
## the text in English; the refusal is the door's answer the model keeps,
## words too - a sentence the door made, or a key - and all are said in the
## language on as the text draws.

## Its options: holds, the bound value the line shows; says, a line under
## the label saying what the field is for; changes, the action every
## keystroke goes to; takes_focus, for a field typed into as it is built;
## refusal, the model's last refusal, shown under the line; and style.
const OPTIONS: Array[String] = ["holds", "says", "changes", "takes_focus", "refusal", Options.STYLE]


## The field: the label, the line saying what it is for when there is one,
## the line itself showing the words held, and the last refusal beneath.
static func make(ui: Ui, action: StringName, label: Variant, options: Dictionary = {}) -> Desc:
	Options.checked("a text field", options, OPTIONS)
	var parts: Array = [ui.text(label, Themes.FACE)]
	if options.get("says") != null:
		parts.append(ui.text(options["says"], Themes.REASON))
	var line: Desc = ui.field(action, &"Field", {"shows": options.get("holds"), "changes": options.get("changes", &"")})
	parts.append(line.takes_focus() if options.get("takes_focus", false) else line)
	if options.get("refusal") != null:
		parts.append(ui.text(options["refusal"], Themes.REASON).hides_empty())
	return ui.column(parts, options.get(Options.STYLE, &"TextFieldRow"))
