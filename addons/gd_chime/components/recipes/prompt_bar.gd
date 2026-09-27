extends RefCounted

const Themes := preload("../../theme.gd")
const Prompts := preload("../../prompts.gd")
const Ui := preload("../primitives/ui.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Phrase := preload("../../phrase.gd")
const Pressables := preload("../../theme_pressables.gd")

## Where a prompt's words are drawn, with the switch that turns its source
## off: a recipe, shown only while a prompt is current.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A prompt is an interruption, and one the player cannot stop is a defect,
## so the thing that interrupts is what offers the way to stop it: beside
## the words is one button that mutes the prompt's source - reminders, say -
## and leaves every other source alone. The button dispatches MUTES with
## the source, read from the prompts as the press lands, and the prompts,
## registered for it, do the muting. The place the bar sits in declares
## the mute like any other action, and the register gives its words; a step
## never points at it, being the bar's own part.
##
## No prompt, nothing on screen: the row is chosen while the prompts name
## an action, and freed while they do not - the builder hands the focus on
## first, so a pad player pressing mute is never left with nothing
## selected.
##
## Deliberately absent: the link into settings the ruling names, which needs
## a settings screen to link to; and how the words flash.


## The description of the bar over these prompts.
static func make(ui: Ui, prompts: Prompts, style: StringName = Pressables.PROMPT_BAR) -> Desc:
	var source: Bound = ui.bound(prompts.get_source).map(func(named: StringName) -> Dictionary: return {"source": named})
	var showing: Desc = ui.row([ui.text(ui.bound(prompts.get_words).map(func(words: Variant) -> Variant: return Phrase.of(words)), Themes.WORDS).grow(4.0), ui.button(Prompts.MUTES, {payload = source}).grow(1.0)], style)
	return ui.when(ui.bound(prompts.get_glowing), showing)
