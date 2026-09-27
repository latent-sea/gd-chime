extends RefCounted

const Themes := preload("../../theme.gd")
const Ui := preload("../primitives/ui.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Phrase := preload("../../phrase.gd")

## The instruction bar: a bar across the top of the work, in the second
## person, saying what the surface is asking for and how far through it the
## reader is - IDLE, a message or nothing; ASKING, mid-act; DONE, what just
## resolved. It carries three things and no more: the ask, the progress as
## a count against its ceiling, and the way out. And it is where guidance
## speaks: idle, it says the prompts' words.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The act is a model's: it reads asking (whether mid-act), words (the ask,
## or what resolved), progress ({count, ceiling} or nothing) and answers the
## cancel; the prompts are the builder's. The prompts' words are the
## register's English, a key the text says in the language on; the act's
## are its own - a phrase to say, or data shown as it is.


static func make(ui: Ui, act: Object, cancels: StringName, style: StringName = &"InstructionBar") -> Desc:
	# the act's words as the act made them, else the prompts', a key: read on both their bells
	var words := Bound.new(func() -> Variant: var said: Variant = act.get_words(); return Phrase.of(ui.prompts.get_words()) if said == null or (said is String and said == "") else said)
	var progress: Bound = ui.bound(act.get_progress).map(func(count: Variant) -> Variant: return "" if count == null else Phrase.with("%d of %d", [count["count"], count["ceiling"]]) if count.has("ceiling") else str(count["count"]))
	var way_out := ui.when(ui.bound(act.get_asking), ui.button(cancels))
	return ui.row([ui.text(words, Themes.WORDS).grow(4.0), ui.text(progress, Themes.REASON).hides_empty().grow(), way_out.grow()], style)
