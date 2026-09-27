extends RefCounted

const Themes := preload("../../theme.gd")
const Driver := preload("../../driver.gd")
const Sheet := preload("sheet.gd")
const Ui := preload("../primitives/ui.gd")
const Options := preload("../primitives/options.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Phrase := preload("../../phrase.gd")

## The settings controls: the ROW a setting is stated in - its name, the one
## line saying what it does, and the control at the end - and the three
## controls a setting is changed by: a TOGGLE, a CHOICE over the options
## there are, and a BINDING that takes the next key or button.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Nothing here holds a setting: what is on, what is chosen and what is
## bound are the MODEL's reads, and every control is a press of the model's
## action carrying the new value - {"on": ...}, {"value": ...}, and the
## key_capture's {"action", "event", "words"}. The state is never hue alone: a toggle
## wears a mark and its word, and the chosen option wears a marked style in
## the list - a bound style, the option's value against the setting's, so
## the one chosen shows as chosen as the overlay opens.
##
## A choice is a LIST IN AN OVERLAY, never a dropdown: a d-pad and a
## handheld must reach every option, and the engine moves focus between
## pressables with the arrows. It answers the control alone: the overlay
## travels on it (Desc.opens), and the builder lifts it beside the app.
##
## A setting's name, what it does, a choice's title, the toggle's two words
## and what a binding asks go to the text in English, said in the language
## on as it draws; an option's words are the model's.

const ON := "On"
const OFF := "Off"
## The toggle's two looks, chosen by a bound style as the value turns.
const TOGGLE_ON := &"ToggleOn"
const TOGGLE_OFF := &"ToggleOff"
## The sheet the options stand on, over everything (sheet.gd).
const SHEET := &"Confirm"
## An option's two looks: the one whose value is the setting's, and the rest.
const OPTION := &"Choice"
const CHOSEN := &"ChoiceChosen"
## What a choice's pop-up is of, in its name.
const KIND := &"choice"


## One setting stated: a column of its name and the line saying what it
## does, and its control at the end of the row.
static func row(ui: Ui, name: Variant, says: Variant, control: Desc) -> Desc:
	var stated := ui.column([ui.text(name, Themes.FACE), ui.text(says, Themes.REASON)])
	return ui.row([stated.grow(), control], &"SettingRow")


## A toggle: one pressable that turns the setting the other way, wearing
## the mark and the word for the way it is now. Its options: on_style and
## off_style, the looks it wears each way.
const TOGGLE_OPTIONS: Array[String] = ["on_style", "off_style"]

static func toggle(ui: Ui, action: StringName, on: Bound, options: Dictionary = {}) -> Desc:
	Options.checked("a toggle", options, TOGGLE_OPTIONS)
	var on_style: StringName = options.get("on_style", TOGGLE_ON)
	var off_style: StringName = options.get("off_style", TOGGLE_OFF)
	var other: Bound = on.map(func(state: Variant) -> Dictionary: return {"on": not state})
	var words: Bound = on.map(func(state: Variant) -> Variant: return Phrase.of(ON if state else OFF))
	var worn: Bound = on.map(func(state: Variant) -> StringName: return on_style if state else off_style)
	return ui.pressable(action, other, [ui.text(words, Themes.FACE)], worn)


## A choice: the control wearing the chosen option's words, which opens the
## overlay - a title and one pressable per option, each picking its value
## and going back, so picking closes it. Its options: offers, the bound
## list picked from; chosen, a bound value reading which is picked; title,
## the words over the list; style; and chosen_style, worn by the one
## picked.
const CHOICE_OPTIONS: Array[String] = ["offers", "chosen", "title", Options.STYLE, "chosen_style"]

static func choice(ui: Ui, action: StringName, opens: StringName, options: Dictionary = {}) -> Desc:
	Options.checked("a choice", options, CHOICE_OPTIONS)
	var offers: Bound = options["offers"]
	var chosen: Bound = options["chosen"]
	var style: StringName = options.get(Options.STYLE, OPTION)
	var chosen_style: StringName = options.get("chosen_style", CHOSEN)
	var shown: Bound = Bound.both(offers, chosen, func(all: Variant, picked: Variant) -> Variant: return _words_of(all, picked))
	var option := func(item: Bound) -> Desc: return _option(ui, action, item, chosen, style, chosen_style)
	var listed := ui.each(offers, option, func(item: Dictionary) -> Variant: return item["value"])
	var title: Variant = options["title"]
	var overlay := ui.pop_up(KIND, func(_which: Bound) -> Desc: return Sheet.over(ui, [ui.text(title, Themes.FACE), listed], SHEET))
	return ui.pressable(opens, {}, [ui.text(shown, Themes.FACE)], style).opens(overlay)


## A binding: at rest the words of what is bound now, pressed it waits for
## the next key or button and hands it to the action, saying which action the
## key is being put on - the input map answers for every binding there is, so
## the press has to name one (input_map.gd). A model that holds one setting of
## its own needs no name and is given none.
## Its options: rebinds, which action's input the press puts on, and style.
const BINDING_OPTIONS: Array[String] = ["rebinds", Options.STYLE]

static func binding(ui: Ui, action: StringName, bound_to: Bound, options: Dictionary = {}) -> Desc:
	Options.checked("a binding", options, BINDING_OPTIONS)
	var made := ui.key_capture(action, bound_to, Phrase.of("Press a key or button..."), options.get(Options.STYLE, &"Binding"))
	# said on the description, as a pressable is told to repeat: it is what this control is for, not a piece of it
	made.props["rebinds"] = options.get("rebinds", &"")
	return made


## One option in the overlay: its words, in the chosen look while its value
## is the setting's, picking its value and going back.
static func _option(ui: Ui, action: StringName, item: Bound, chosen: Bound, style: StringName, chosen_style: StringName) -> Desc:
	var value: Bound = item.map(func(one: Variant) -> Dictionary: return {} if one == null else {"value": one["value"]})
	var worn: Bound = Bound.both(item, chosen, func(one: Variant, picked: Variant) -> StringName: return chosen_style if one != null and one["value"] == picked else style)
	return ui.pressable(action, value, [ui.text(item.field("words"), Themes.FACE)], worn).goes_to(Driver.BACK)


## The words of the option whose value is the chosen one.
static func _words_of(all: Variant, picked: Variant) -> Variant:
	for one: Dictionary in all:
		if one["value"] == picked:
			return one["words"]
	return ""
