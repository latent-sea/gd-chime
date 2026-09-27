extends RefCounted

const Themes := preload("../../theme.gd")
const Ui := preload("../primitives/ui.gd")
const Options := preload("../primitives/options.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Phrase := preload("../../phrase.gd")

## A type-ahead picker: a line to type in, how many options match, and the
## ones that do, each pressable. A picker is this and never a drop-down,
## because there can be sixty options, or six hundred.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## What is typed and what it leaves are the NARROWING model's (narrowing.gd):
## it reads TYPED, OPTIONS - {value, words} entries, as many as its limit
## allows - and COUNT, how many match in all, and it answers the typing
## action with {"line"}. This holds none of that: it describes the field
## that types, the count, and one pressable per option carrying {"value"}.
##
## Every keystroke narrows, so the field's CHANGES is the typing action as
## well as its Enter; nothing waits for the reader to finish a word. The
## count is said in words rather than shown as a length, so a reader who
## sees eight rows knows there are ninety.
##
## Picking is the caller's action, not the narrowing's: the pressables
## dispatch it with the option's value, and whoever registered it decides
## what picking means. A picker over one of several columns - the one filter
## model's people (filters.gd) - is given the rest of the payload, which
## every option's press carries beside its value. A picker standing in an
## overlay - a combo's - is given where a pick then goes: back, so picking
## closes it.
##
## It is walked without a pointer: the field and the options are focusable
## controls in a column, so the arrows and a pad move from the line down
## through the options and the engine does the moving.


## The picker over this narrowing: the line, the count, and the options
## under it, each pressing the caller's action with its value, and going
## where it is told a pick then goes, if anywhere.
## Its options: style; then, where a pick goes afterwards; and payload,
## what every option's press carries beside its value.
const OPTIONS: Array[String] = [Options.STYLE, "then", Options.PAYLOAD]

static func make(ui: Ui, narrowing: Object, types: StringName, picks: StringName, options: Dictionary = {}) -> Desc:
	Options.checked("a type-ahead", options, OPTIONS)
	var then: StringName = options.get("then", &"")
	var beside: Dictionary = options.get(Options.PAYLOAD, {})
	var style: StringName = options.get(Options.STYLE, &"TypeAhead")
	var line := ui.field(types, &"Field", {"changes": types})
	var count := ui.text(ui.bound(narrowing.get_count).map(func(matched: Variant) -> Variant: return counted(matched)), Themes.REASON)
	var listed := ui.each(ui.bound(narrowing.get_options), func(option: Bound) -> Desc: return _option(ui, picks, option, then, beside), func(option: Dictionary) -> Variant: return option["value"])
	return ui.column([line, count, ui.scroll(listed).grow()], style)


## One option: its words, pressing the caller's action with its value read
## through the handle as the press lands, and whatever else it carries.
static func _option(ui: Ui, picks: StringName, option: Bound, then: StringName, beside: Dictionary) -> Desc:
	var carried: Bound = option.map(func(item: Variant) -> Dictionary: return {} if item == null else beside.merged({"value": item["value"]}, true))
	return ui.pressable(picks, carried, [ui.text(option.field("words"), Themes.FACE)], &"TypeAheadOption").goes_to(then)


## How many match, as a phrase the text says as it draws: "No matches" for
## none, else the catalogue's plural for the count, each language's by its
## own rule. The one place the wording lives.
static func counted(matched: int) -> RefCounted:
	return Phrase.counted("%d match", "%d matches", matched, "No matches")
