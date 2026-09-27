extends RefCounted

const Themes := preload("../../theme.gd")
const Chimes := preload("../../chimes.gd")
const Driver := preload("../../driver.gd")
const Inputs := preload("../../input_map.gd")
const Ui := preload("../primitives/ui.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const Hint := preload("hint.gd")
const Sheet := preload("sheet.gd")
const TypeAhead := preload("type_ahead.gd")
const CommandSearch := preload("../../command_search.gd")
const Fields := preload("../../theme_fields.gd")

## The command palette: a pop-up over everything, with a line to type in,
## how many entries match, and the entries themselves - commands, datasets,
## files - each reading what it is, what sort of thing, the key it is on and
## why it cannot be used, if it cannot.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## WHAT IT SEARCHES AND WHAT A PICK DOES ARE THE SEARCH'S (command_search.gd):
## this describes the line - every keystroke narrowing, Enter picking the
## first - the count, and a pressable per entry picking it. A picked entry
## is the press it stands for, refused as that press would be, so its reason
## stands on the entry before it is picked. The line shows what is typed, so
## it is empty each time the palette opens: the palette's place begins the
## search as it fills.
##
## IT IS OPENED LIKE ANY POP-UP, by a button opening it - with its hint, and
## the key the application puts that action on (Ctrl+K) - and is closed by
## the way out every pop-up has, a press beside the line with its key. It is
## walked without a pointer: the line takes the focus as it opens, the arrows
## and the pad move down through the entries, and Enter or the pad's accept
## presses one.
##
## Its look is the Palette sheet over the shade (sheet.gd) and PaletteEntry
## for each entry, the look's own.

## The sheet the palette stands on, and one entry's look.
const SHEET := &"Palette"
const ENTRY := &"PaletteEntry"
## What the palette's pop-up is of, in its name.
const KIND := &"palette"


## The palette's pop-up: its search answers the typing, the picks and Enter,
## and its way out goes back. A button opens it (describe_places.gd), and the
## key the application puts that button's action on.
static func make(ui: Ui, search: CommandSearch) -> Desc:
	var line := ui.field(CommandSearch.RUNS_FIRST, Fields.FIELD, {"changes": CommandSearch.TYPES, "shows": ui.bound(search.get_typed)})
	var close := ui.pressable(ui.CLOSES, {}, [ui.row([ui.text(ui.words(ui.CLOSES), Themes.FACE), Hint.make(ui, ui.CLOSES)])], ENTRY).goes_to(Driver.BACK)
	var count := ui.text(ui.bound(search.get_count).map(func(matched: Variant) -> Variant: return TypeAhead.counted(matched)), Themes.REASON)
	var entries := ui.each(ui.bound(search.get_options), func(entry: Bound) -> Desc: return _entry(ui, entry), func(entry: Dictionary) -> Variant: return entry["value"])
	# the entries at the height they take - never more than the search's limit, so the sheet stands as tall as they are
	var palette := ui.pop_up(KIND, func(_which: Bound) -> Desc: return Sheet.over(ui, [ui.row([line.grow(), close]), count, entries], SHEET), search)
	# the line emptied as the palette opens, by its place as it fills, and its entries let go as it empties
	palette.props["on_fill"] = func(_token: Object) -> void: search.begin()
	palette.props["on_empty"] = search.end
	return palette


## One entry: its words, what sort of thing it is and the key its command is
## on, over why it cannot be picked, if it cannot - pressed, it is picked.
static func _entry(ui: Ui, entry: Bound) -> Desc:
	# the entry's value, or none for one on its way out, which the search refuses
	var carried: Bound = entry.map(func(one: Variant) -> Dictionary: return {"value": null if one == null else one["value"]})
	# the key a command is on, read again as keys are bound and devices change; nothing for a dataset or a file
	var hint := Bound.new(func() -> Variant: var one: Variant = entry.read(); return null if one == null or not one["payload"].is_empty() else ui.inputs.get_hint(one["action"]))
	var said := ui.row([ui.text(entry.field("words"), Themes.FACE).grow(), ui.text(entry.field("kind"), Themes.REASON), ui.text(hint, Themes.REASON).hides_empty()])
	return ui.pressable(CommandSearch.PICKS, carried, [ui.column([said, ui.reason(Themes.REASON)])], ENTRY)
